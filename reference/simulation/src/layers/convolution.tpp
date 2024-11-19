#include "convolution.h"

#include <iostream>

template<typename T>
Convolution<T>::Convolution(Matrix<T> kernel, Matrix<T> bias, size_t batching, size_t x, size_t y, size_t output_channel)
    : kernel(kernel)
    , bias(bias)
    , output_buffer({batching, x, y, output_channel}) {}

namespace {
    template<typename T>
    inline T relu(T val) {
        return val < 0 ? 0 : val;
    }
}

template<typename T>
const Matrix<T>& Convolution<T>::calc(const Matrix<T>& input) {
    for (size_t batch_id = 0; batch_id < input.shape()[0]; batch_id++)
    {
        for (size_t inch_id = 0; inch_id < input.shape()[3]; inch_id++)
        {
            for (size_t outch_id = 0; outch_id < kernel.shape()[0]; outch_id++)
            {
                for (size_t x_id = 0; x_id <= input.shape()[1] - kernel.shape()[2]; x_id++)
                {
                    for (size_t y_id = 0; y_id <= input.shape()[2] - kernel.shape()[3]; y_id++)
                    {
                        if (inch_id == 0)
                        {
                            output_buffer[{batch_id, x_id, y_id, outch_id}] = 0;
                        }

                        T tmp = 0;
                        // Do computation of kernel matrices over input matrices
                        for (size_t kx_id = 0; kx_id < kernel.shape()[2]; kx_id++)
                        {
                            for (size_t ky_id = 0; ky_id < kernel.shape()[3]; ky_id++)
                            {
                                tmp += input[{batch_id, x_id + kx_id, y_id + ky_id, inch_id}] * kernel[{outch_id, inch_id, kx_id, ky_id}];
                            }
                        }

                        output_buffer[{batch_id, x_id, y_id, outch_id}] += tmp;
                    }
                }
            }
        }
        // Add bias to every value of every output channel and do activation (ReLU)
        for (size_t x_id = 0; x_id < output_buffer.shape()[1]; x_id++)
        {
            for (size_t y_id = 0; y_id < output_buffer.shape()[2]; y_id++)
            {
                for (size_t outch_id = 0; outch_id < output_buffer.shape()[3]; outch_id++)
                {
                    // Addition of Bias and Activation (ReLU)
                    output_buffer[{batch_id, x_id, y_id, outch_id}] = relu(output_buffer[{batch_id, x_id, y_id, outch_id}] + bias[outch_id]);
                }
            }
        }
    }

    return output_buffer;
}
