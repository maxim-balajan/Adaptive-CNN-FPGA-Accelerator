#pragma once
#include "quant_dense.h"
#include "../data/data_converter.h"

template<typename T, typename ACC>
QuantDense<T, ACC>::QuantDense(Matrix<T> weights, Matrix<T> bias, bool enable_softmax, Matrix<T> output_buffer, float s_b, float s_x, float s_w, float s_y)
    : weights(weights)
    , bias(bias)
    , enable_softmax(enable_softmax)
    , output_buffer(output_buffer)
    , s_b(s_b)
    , s_x(s_x)
    , s_w(s_w)
    , s_y(s_y) {}


template<typename T, typename ACC>
QuantDense<T, ACC>::QuantDense(Matrix<T> weights, Matrix<T> bias, bool enable_softmax, size_t batching, size_t x, float s_b, float s_x, float s_w, float s_y)
    : QuantDense(weights, bias, enable_softmax, Matrix<T>({batching, x}), s_b, s_x, s_w, s_y) {}


template<typename T, typename ACC>
const Matrix<T>& QuantDense<T, ACC>::calc(const Matrix<T>& input)
{
    for (size_t batch_id = 0; batch_id < input.shape()[0]; batch_id++)
    {
        for (size_t wy_id = 0; wy_id < weights.shape()[1]; wy_id++)
        {
            ACC tmp = convert_data<float, ACC>(0.0f);

            for (size_t x_id = 0; x_id < input.shape()[1]; x_id++)
            {
                tmp += convert_data<T, ACC>(weights[{x_id, wy_id}]) * convert_data<T, ACC>(input[{batch_id, x_id}]);
            }

            ACC res = tmp / convert_data<float, ACC>(s_y / (s_x * s_w)) + convert_data<T, ACC>(bias[{wy_id}]) / convert_data<float, ACC>(s_y / s_b);
            output_buffer[{batch_id, wy_id}] = convert_data<ACC, T>(res);
        }
    }

    if (enable_softmax) {
        softmax(output_buffer);
    }

    return output_buffer;
}

template<typename T, typename ACC>
const char* QuantDense<T, ACC>::name() const {
    return "QuantDense";
}

template<typename T, typename ACC>
LayerType QuantDense<T, ACC>::type() const {
    return LayerType::QuantDense;
}

template<typename T, typename ACC>
unsigned QuantDense<T, ACC>::serialize(ostream& stream) const {
    unsigned bytes = 0; 

    bytes += weights.serialize(stream);
    bytes += bias.serialize(stream);

    bytes += serialize_number(s_b, stream);
    bytes += serialize_number(s_x, stream);
    bytes += serialize_number(s_w, stream);
    bytes += serialize_number(s_y, stream);
    bytes += serialize_number(static_cast<int>(enable_softmax), stream);
    bytes += serialize_vector(output_buffer.shape(), stream);

    return bytes;
}


template<typename T, typename ACC>
QuantDense<T, ACC> QuantDense<T, ACC>::deserialize(span<char>& data) {
    Matrix<T> weights = Matrix<T>::deserialize(data);
    Matrix<T> bias = Matrix<T>::deserialize(data);

    float s_b = deserialize_number<float>(data);
    float s_x = deserialize_number<float>(data);
    float s_w = deserialize_number<float>(data);
    float s_y = deserialize_number<float>(data);

    bool enable_softmax = deserialize_number<int>(data) != 0;

    vector<size_t> out_shape = deserialize_vector<size_t>(data);
    Matrix<T> output_buffer(out_shape);

    return QuantDense(weights, bias, enable_softmax, output_buffer, s_b, s_x, s_w, s_y);
}
