#pragma once
#include "convolution.h"
#include "../data/data_converter.h"

template<typename T, typename ACC>
Convolution<T, ACC>::Convolution(Matrix<T> kernel, Matrix<T> bias, size_t batching, size_t x, size_t y, size_t output_channel)
    : Convolution(kernel, bias, Matrix<T>({batching, output_channel, x, y})) {}

template<typename T, typename ACC>
Convolution<T, ACC>::Convolution(Matrix<T> kernel, Matrix<T> bias, Matrix<T> output_buffer)
    : kernel(kernel)
    , bias(bias)
    , output_buffer(output_buffer) {}

namespace {
    template<typename T>
    inline T relu(T val) {
        return val < convert_data<float, T>(0.0f) ? convert_data<float, T>(0.0f) : val;
    }
}

template<typename T, typename ACC>
const Matrix<T>& Convolution<T, ACC>::calc(const Matrix<T>& input) {
    for (size_t batch_id = 0; batch_id < input.shape()[0]; batch_id++)
    {
        for (size_t inch_id = 0; inch_id < input.shape()[1]; inch_id++)
        {
            for (size_t outch_id = 0; outch_id < kernel.shape()[0]; outch_id++)
            {
                for (size_t x_id = 0; x_id <= input.shape()[2] - kernel.shape()[2]; x_id++)
                {
                    for (size_t y_id = 0; y_id <= input.shape()[3] - kernel.shape()[3]; y_id++)
                    {
                        // This resets the value when a new convolution is performed with the same instance of Convolution<T>
                        if (inch_id == 0)
                        {
                            output_buffer[{batch_id, outch_id, x_id, y_id}] = convert_data<float, T>(0.0f);
                        }

                        T tmp = convert_data<float, T>(0.0f);
                        // Do computation of kernel matrices over input matrices
                        for (size_t kx_id = 0; kx_id < kernel.shape()[2]; kx_id++)
                        {
                            for (size_t ky_id = 0; ky_id < kernel.shape()[3]; ky_id++)
                            {
                                tmp += input[{batch_id, inch_id, x_id + kx_id, y_id + ky_id}] * kernel[{outch_id, inch_id, kx_id, ky_id}];
                            }
                        }

                        output_buffer[{batch_id, outch_id, x_id, y_id}] += tmp;
                    }
                }
            }
        }
        // Add bias to every value of every output channel and do activation (ReLU)
        for (size_t x_id = 0; x_id < output_buffer.shape()[2]; x_id++)
        {
            for (size_t y_id = 0; y_id < output_buffer.shape()[3]; y_id++)
            {
                for (size_t outch_id = 0; outch_id < output_buffer.shape()[1]; outch_id++)
                {
                    // Addition of Bias and Activation (ReLU)
                    output_buffer[{batch_id, outch_id, x_id, y_id}] = relu(output_buffer[{batch_id, outch_id, x_id, y_id}] + bias[outch_id]);
                }
            }
        }
    }

    return output_buffer;
}

template<typename T, typename ACC>
const char* Convolution<T, ACC>::name() const {
    return "Convolution";
}

template<typename T, typename ACC>
LayerType Convolution<T, ACC>::type() const {
    return LayerType::Convolution;
}

template<typename T, typename ACC>
unsigned Convolution<T, ACC>::serialize(ostream& stream) const {
    unsigned bytes = 0; 

    bytes += kernel.serialize(stream);
    bytes += bias.serialize(stream);
    bytes += serialize_vector(output_buffer.shape(), stream);

    return 0;
}

template<typename T, typename ACC>
Convolution<T, ACC> Convolution<T, ACC>::deserialize(span<char>& data) {
    Matrix<T> kernel = Matrix<T>::deserialize(data);
    Matrix<T> bias = Matrix<T>::deserialize(data);

    vector<size_t> out_shape = deserialize_vector<size_t>(data);
    Matrix<T> output_buffer(out_shape);

    return Convolution(kernel, bias, output_buffer);
}
