#include "convolution.h"

#include <iostream>

Convolution::Convolution(matrix_4d kernel, matrix_1d bias, size_t batching, size_t x, size_t y, size_t output_channel) : kernel(kernel), bias(bias), output_buffer(init_matrix_4d(batching, x, y, output_channel)) {}

matrix_4d Convolution::calc(matrix_4d input)
{
    for (size_t batch_id = 0; batch_id < input.size(); batch_id++)
    {
        for (size_t inch_id = 0; inch_id < input[0][0][0].size(); inch_id++)
        {
            for (size_t outch_id = 0; outch_id < kernel.size(); outch_id++)
            {
                for (size_t x_id = kernel[0][0].size(); x_id < input[0].size() - kernel[0][0].size(); x_id++)
                {
                    for (size_t y_id = kernel[0][0][0].size(); y_id < input[0][0].size() - kernel[0][0][0].size(); y_id++)
                    {
                        int64_t tmp = 0;
                        // Do computation of kernel matrices over input matrices
                        for (size_t kx_id = 0; kx_id < kernel[0][0].size(); kx_id++)
                        {
                            for (size_t ky_id = 0; ky_id < kernel[0][0][0].size(); ky_id++)
                            {
                                tmp += input[batch_id][x_id + kx_id - 1][y_id + ky_id - 1][inch_id] * kernel[inch_id][outch_id][kx_id][ky_id];
                            }
                        }

                        output_buffer[batch_id][x_id - kernel[0][0].size() / 2][y_id - kernel[0][0][0].size() / 2][outch_id] += tmp;
                    }
                }
            }
        }
        // Add bias to every value of every output channel and do activation (ReLU)
        for (size_t x_id = 0; x_id < output_buffer[0].size(); x_id++)
        {
            for (size_t y_id = 0; y_id < output_buffer[0][0].size(); y_id++)
            {
                for (size_t outch_id = 0; outch_id < output_buffer[0][0][0].size(); outch_id++)
                {
                    output_buffer[batch_id][x_id][y_id][outch_id] += bias[outch_id];
                    // Activation (ReLU)
                    output_buffer[batch_id][x_id][y_id][outch_id] = output_buffer[batch_id][x_id][y_id][outch_id] > 0 ? output_buffer[batch_id][x_id][y_id][outch_id] : 0;
                }
            }
        }
    }

    return output_buffer;
}
