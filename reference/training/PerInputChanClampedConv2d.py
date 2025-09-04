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

    def int8_sum(self, x, dim=1):
        """
        Perform saturating int8 accumulation along given dimension.
        """
        values = torch.unbind(x, dim=dim)
        acc = values[0].clone()
        for v in values[1:]:
            acc = torch.clamp(acc.to(torch.int32) + v.to(torch.int32), -2**15, 2**15 - 1).to(torch.int16)
        return acc



    def forward(self, x):
        # Partial grouped conv (QuantTensor)
        p = self.partial(x)

        N, Cg, H, W = p.shape  # Cg = out_ch * groups

        p = self.partial_clamp(p)

        p = p.view(N, self.groups, self.out_ch, H, W)
        out = self.int8_sum(p.tensor, dim=1)
        return out
