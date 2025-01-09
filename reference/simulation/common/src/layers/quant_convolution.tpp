// #include "quant_convolution.h"
// #include "data/data_converter.h"
// #include "common_util.h"

#include <iostream>

template<typename T, typename ACC>
QuantConvolution<T, ACC>::QuantConvolution(Matrix<T> kernel, Matrix<T> bias, size_t batching, size_t x, size_t y, size_t output_channel, float s_b, float s_x, float s_w, float s_y)
    : kernel(kernel)
    , bias(bias)
    , output_buffer({batching, output_channel, x, y})
    , s_b(s_b)
    , s_x(s_x)
    , s_w(s_w)
    , s_y(s_y) {}

namespace {
    template<typename ACC>
    inline ACC relu_ACC(ACC val) {
        return val < convert_data<float, ACC>(0.0f) ? convert_data<float, ACC>(0.0f) : val;
    }
}

template<typename T, typename ACC>
const Matrix<T>& QuantConvolution<T, ACC>::calc(const Matrix<T>& input) {

    Matrix<ACC> t(output_buffer.shape());

    for (size_t batch_id = 0; batch_id < input.shape()[0]; batch_id++)
    {
        // Compute Convolution of quantized input, quantized bias and quantized weight matrix
        for (size_t inch_id = 0; inch_id < input.shape()[1]; inch_id++)
        {
            for (size_t outch_id = 0; outch_id < kernel.shape()[0]; outch_id++)
            {
                for (size_t x_id = 0; x_id <= input.shape()[2] - kernel.shape()[2]; x_id++)
                {
                    for (size_t y_id = 0; y_id <= input.shape()[3] - kernel.shape()[3]; y_id++)
                    {
                        ACC tmp = convert_data<float, ACC>(0.0f);
                        // Do computation of kernel matrices over input matrices
                        for (size_t kx_id = 0; kx_id < kernel.shape()[2]; kx_id++)
                        {
                            for (size_t ky_id = 0; ky_id < kernel.shape()[3]; ky_id++)
                            {
                                tmp += convert_data<T, ACC>(input[{batch_id, inch_id, x_id + kx_id, y_id + ky_id}]) * convert_data<T, ACC>(kernel[{outch_id, inch_id, kx_id, ky_id}]);
                            }
                        }

                        t[{batch_id, outch_id, x_id, y_id}] += tmp;
                    }
                }
            }
        }
        // Quantize result with new factor and add new bias
        for (size_t x_id = 0; x_id < output_buffer.shape()[2]; x_id++)
        {
            for (size_t y_id = 0; y_id < output_buffer.shape()[3]; y_id++)
            {
                for (size_t outch_id = 0; outch_id < output_buffer.shape()[1]; outch_id++)
                {
                    ACC res = relu_ACC(t[{batch_id, outch_id, x_id, y_id}] / convert_data<float, ACC>(s_y / (s_x * s_w)) + convert_data<T, ACC>(bias[outch_id]) / convert_data<float, ACC>(s_y / s_b));

                    // Addition of Bias and Activation (ReLU)
                    output_buffer[{batch_id, outch_id, x_id, y_id}] = convert_data<ACC, T>(res);
                }
            }
        }
    }

    return output_buffer;
}
