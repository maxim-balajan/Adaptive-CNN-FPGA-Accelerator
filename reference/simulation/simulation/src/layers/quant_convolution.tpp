#pragma once
#include "quant_convolution.h"
#include "../data/data_converter.h"

#include <cmath>
#include <cstdint>
#include <iostream>

template<typename T, typename ACC>
QuantConvolution<T, ACC>::QuantConvolution(Matrix<T> kernel, Matrix<T> bias, Matrix<T> output_buffer
    , size_t padding, size_t stride, float s_b, float s_x, float s_w, float s_y)
    : kernel(kernel)
    , bias(bias)
    , output_buffer(output_buffer)
    , s_b(s_b)
    , s_x(s_x)
    , s_w(s_w)
    , s_y(s_y)
    , padding(padding)
    , stride(stride)
    , s_x_shift(log2((s_y / (s_x * s_w))) == std::numeric_limits<float>::infinity() ? std::numeric_limits<uint8_t>::max() : static_cast<uint8_t>(log2(s_y / (s_x * s_w))))
    , s_b_shift(log2(s_y / s_b) == std::numeric_limits<float>::infinity() ? std::numeric_limits<uint8_t>::max() : static_cast<uint8_t>(log2(s_y / s_b))) {
        // make sure the values are really a power of 2
        assert(log2((s_y / (s_x * s_w))) == std::numeric_limits<float>::infinity() || log2(s_y / (s_x * s_w)) == static_cast<float>(s_x_shift));
        assert(log2(s_y / s_b) == std::numeric_limits<float>::infinity() || log2(s_y / s_b) == static_cast<float>(s_b_shift));
    }

template<typename T, typename ACC>
QuantConvolution<T, ACC>::QuantConvolution(Matrix<T> kernel, Matrix<T> bias, size_t batching, size_t x, size_t y, size_t output_channel
    , size_t padding, size_t stride, float s_b, float s_x, float s_w, float s_y)
    : QuantConvolution(kernel, bias, Matrix<T>({batching, output_channel, x, y}), padding, stride, s_b, s_x, s_w, s_y) {}

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
                size_t out_x_id = 0;
                size_t out_y_id = 0;

                for (int x_id = -padding; x_id <= (int) (input.shape()[2] - kernel.shape()[2] + padding); x_id+=stride)
                {
                    for (int y_id = -padding; y_id <= (int) (input.shape()[3] - kernel.shape()[3] + padding); y_id+=stride)
                    {
                        ACC tmp = convert_data<float, ACC>(0.0f);
                        // Do computation of kernel matrices over input matrices
                        for (size_t kx_id = 0; kx_id < kernel.shape()[2]; kx_id++)
                        {
                            for (size_t ky_id = 0; ky_id < kernel.shape()[3]; ky_id++)
                            {
                                // correctly deal with padding of input data
                                if ((x_id + kx_id < 0) || (y_id + ky_id < 0)) {
                                    tmp += convert_data<float, ACC>(0.0f);
                                } 
                                else if ((x_id + kx_id > input.shape()[2] - kernel.shape()[2] + padding) || (y_id + ky_id > input.shape()[3] - kernel.shape()[3] + padding)) {
                                    tmp += convert_data<float, ACC>(0.0f);
                                }
                                else {
                                    tmp += convert_data<T, ACC>(input[{batch_id, inch_id, x_id + kx_id, y_id + ky_id}]) * convert_data<T, ACC>(kernel[{outch_id, inch_id, kx_id, ky_id}]);
                                }
                            }
                        }
                        t[{batch_id, outch_id, out_x_id, out_y_id}] += tmp;

                        out_y_id++;
                    }

                    out_y_id = 0;
                    out_x_id++;
                }
            }
        }
        //cout << "Actual Matrix:\n";
        //cout << t;
        // Quantize result with new factor and add new bias
        for (size_t x_id = 0; x_id < output_buffer.shape()[2]; x_id++)
        {
            for (size_t y_id = 0; y_id < output_buffer.shape()[3]; y_id++)
            {
                for (size_t outch_id = 0; outch_id < output_buffer.shape()[1]; outch_id++)
                {
                    ACC res = (relu_ACC(t[{batch_id, outch_id, x_id, y_id}] >> s_x_shift) + (convert_data<T, ACC>(bias[outch_id]) >> s_b_shift));

                    // Addition of Bias and Activation (ReLU)
                    output_buffer[{batch_id, outch_id, x_id, y_id}] = convert_data<ACC, T>(res);
                }
            }
        }
    }

    return output_buffer;
}

template<typename T, typename ACC>
const char* QuantConvolution<T, ACC>::name() const {
    return "QuantConvolution";
}

template<typename T, typename ACC>
LayerType QuantConvolution<T, ACC>::type() const {
    return LayerType::QuantConvolution;
}

template<typename T, typename ACC>
unsigned QuantConvolution<T, ACC>::serialize(ostream& stream) const {
    unsigned bytes = 0; 

    bytes += kernel.serialize(stream);
    bytes += bias.serialize(stream);

    bytes += serialize_number(padding, stream);
    bytes += serialize_number(stride, stream);
    bytes += serialize_number(s_b, stream);
    bytes += serialize_number(s_x, stream);
    bytes += serialize_number(s_w, stream);
    bytes += serialize_number(s_y, stream);
    bytes += serialize_vector(output_buffer.shape(), stream);

    return bytes;
}

template<typename T, typename ACC>
QuantConvolution<T, ACC> QuantConvolution<T, ACC>::deserialize(span<char>& data) {
    Matrix<T> kernel = Matrix<T>::deserialize(data);
    Matrix<T> bias = Matrix<T>::deserialize(data);

    size_t padding = deserialize_number<size_t>(data);
    size_t stride = deserialize_number<size_t>(data);
    float s_b = deserialize_number<float>(data);
    float s_x = deserialize_number<float>(data);
    float s_w = deserialize_number<float>(data);
    float s_y = deserialize_number<float>(data);

    vector<size_t> out_shape = deserialize_vector<size_t>(data);
    Matrix<T> output_buffer(out_shape);

    return QuantConvolution(kernel, bias, out_shape, padding, stride, s_b, s_x, s_w, s_y);
}
