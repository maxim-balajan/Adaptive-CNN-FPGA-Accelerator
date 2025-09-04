#pragma once
#include "reduce_sum.h"

#include <cmath>
#include <cstdint>
#include <iostream>
#include <algorithm>

template<typename T, typename ACC>
ReduceSum<T, ACC>::ReduceSum(vector<size_t> new_dimensions, size_t dimension, float s_x, float s_y, Matrix<T> output_buffer)
    : new_dimensions(new_dimensions)
    , dimension(dimension)
    , s_x(s_x)
    , s_y(s_y)
    , s_x_shift(log2(s_y / s_x) == std::numeric_limits<float>::infinity() ? std::numeric_limits<uint8_t>::max() : static_cast<uint8_t>(log2(s_y / s_x)))
    , output_buffer(output_buffer) {}

template<typename T, typename ACC>
ReduceSum<T, ACC>::ReduceSum(vector<size_t> new_dimensions, size_t dimension, float s_x, float s_y, size_t batching, size_t output_channel, size_t x, size_t y)
    : ReduceSum(new_dimensions, dimension, s_x, s_y, Matrix<T>({batching, output_channel, x, y})) {}

template<typename T, typename ACC>
const Matrix<T>& ReduceSum<T, ACC>::calc(const Matrix<T>& input)
{
    Matrix<T> new_input = input;
    Matrix<ACC> t(output_buffer.shape());
    new_input.reinterpret_dimensions(new_dimensions);

    for (size_t batch_id = 0; batch_id < new_input.shape()[0]; batch_id++)
    {
        for (size_t outch_id = 0; outch_id < new_input.shape()[2]; outch_id++)
        {

            for (size_t x_id = 0; x_id < new_input.shape()[3]; x_id++)
            {
                for (size_t y_id = 0; y_id < new_input.shape()[4]; y_id++)
                {
                    ACC res = convert_data<float, ACC>(.0f);

                    for (size_t dim_id = 0; dim_id < new_input.shape()[dimension]; dim_id++) {
                        res += convert_data<T, ACC>(new_input[{batch_id, dim_id, outch_id, x_id, y_id}]);
                    }

                    t[{batch_id, outch_id, x_id, y_id}] += res;
                    
                }
            }
        }

        // Quantize result with new factor
        for (size_t x_id = 0; x_id < output_buffer.shape()[2]; x_id++)
        {
            for (size_t y_id = 0; y_id < output_buffer.shape()[3]; y_id++)
            {
                for (size_t outch_id = 0; outch_id < output_buffer.shape()[1]; outch_id++)
                {
                    T quant_res = convert_data<ACC, T>(relu_ACC(t[{batch_id, outch_id, x_id, y_id}]) >> s_x_shift);

                    output_buffer[{batch_id, outch_id, x_id, y_id}] = quant_res;
                }
            }
        }
    }
    

    return output_buffer;
}

template<typename T, typename ACC>
const char* ReduceSum<T, ACC>::name() const {
    return "ReduceSum";
}

template<typename T, typename ACC>
LayerType ReduceSum<T, ACC>::type() const {
    return LayerType::ReduceSum;
}

template<typename T, typename ACC>
unsigned ReduceSum<T, ACC>::serialize(ostream& stream) const {
    unsigned bytes = 0; 

    bytes += serialize_vector(new_dimensions, stream);
    bytes += serialize_number(dimension, stream);
    bytes += serialize_number(s_x, stream);
    bytes += serialize_number(s_y, stream);
    bytes += serialize_vector(output_buffer.shape(), stream);

    return bytes;
}

template<typename T, typename ACC>
ReduceSum<T, ACC> ReduceSum<T, ACC>::deserialize(span<char>& data) {
    vector<size_t> new_dimensions = deserialize_vector<size_t>(data);

    size_t dimension = deserialize_number<size_t>(data);

    float s_x = deserialize_number<float>(data);
    float s_y = deserialize_number<float>(data);

    vector<size_t> out_shape = deserialize_vector<size_t>(data);
    Matrix<T> output_buffer(out_shape);

    return ReduceSum(new_dimensions, dimension, s_x, s_y, output_buffer);
}
