import torch
from torch import nn
import brevitas.nn as qnn
from brevitas.quant import Int8ActPerTensorFixedPoint, Int8WeightPerTensorFixedPoint

class PerInChanClampedQuantConv2d(nn.Module):
    """
    Grouped QuantConv2d that produces (out_ch * in_ch) maps,
    a QuantIdentity to clamp per-partial result, and a sum over the in_ch axis.
    """
    def __init__(self,
                 in_channels, out_channels, kernel_size,
                 stride=1, padding=0, dilation=1, groups=1, bias=False,
                 act_bit_width=8, weight_bit_width=8):
        super().__init__()
        self.in_ch = in_channels
        self.out_ch = out_channels
        self.groups = groups

        # Partial convs per input channel (groups=in_channels).
        # Weight quantization is handled here by passing the quantizer CLASS.
        self.partial = qnn.QuantConv2d(
            in_channels, out_channels * groups, kernel_size,
            stride=stride, padding=padding, dilation=dilation, groups=groups,
            bias=False,
            weight_quant=Int8WeightPerTensorFixedPoint,
            weight_bit_width=weight_bit_width,
            return_quant_tensor=True  # keep QT so we know it came from a quantized op
        )

        # Clamp each partial result to Int8 activation (per-tensor fixed point).
        self.partial_clamp = qnn.QuantIdentity(
            act_quant=Int8ActPerTensorFixedPoint,
            bit_width=act_bit_width,
            return_quant_tensor=True
        )


    def forward(self, x):
        # Partial grouped conv (QuantTensor)
        y_qt = self.partial(x)
        # Convert QuantTensor to plain Tensor for reshaping & summing
        y = getattr(y_qt, "tensor", y_qt)  # works across Brevitas versions

        N, Cg, H, W = y.shape  # Cg = out_ch * in_ch
        # Reshape to [N, in_ch, out_ch, H, W] so each [*, c, o, :, :] is a single partial
        y = y.view(N, self.groups, self.out_ch, H, W)
        # Flatten (c,o) back to channel axis to clamp each partial map independently
        y = y.view(N, self.groups * self.out_ch, H, W)

        # Clamp each partial with Int8 activation quantization
        y_partial_qt = self.partial_clamp(y)
        y_partial = getattr(y_partial_qt, "tensor", y_partial_qt)

        # Reshape back and sum over input channels to finish accumulation
        y_partial = y_partial.view(N, self.groups, self.out_ch, H, W)
        out = y_partial.sum(dim=1)  # [N, out_ch, H, W]
        return out
