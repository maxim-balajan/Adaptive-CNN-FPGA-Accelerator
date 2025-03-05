#pragma once
#include "max_pooling.h"

#include <iostream>
#include <algorithm>

template<typename T, typename ACC>
MaxPooling<T, ACC>::MaxPooling(size_t pooling_size, Matrix<T> output_buffer)
    : pooling_size(pooling_size)
    , output_buffer(output_buffer) {}

template<typename T, typename ACC>
MaxPooling<T, ACC>::MaxPooling(size_t pooling_size, size_t batching, size_t x, size_t y, size_t output_channel)
    : MaxPooling(pooling_size, Matrix<T>({batching, output_channel, x, y})) {}

template<typename T, typename ACC>
const Matrix<T>& MaxPooling<T, ACC>::calc(const Matrix<T>& input)
{
    for (size_t batch_id = 0; batch_id < input.shape()[0]; batch_id++)
    {
        for (size_t ch_id = 0; ch_id < input.shape()[1]; ch_id++)
        {
            size_t out_x_id = 0;
            size_t out_y_id = 0;

            for (size_t x_id = 0; x_id < input.shape()[2]; x_id += pooling_size)
            {
                for (size_t y_id = 0; y_id < input.shape()[3]; y_id += pooling_size)
                {
                    vector<T> tmp;
                    // Store all values of window in list
                    for (size_t kx_id = 0; kx_id < pooling_size; kx_id++)
                    {
                        for (size_t ky_id = 0; ky_id < pooling_size; ky_id++)
                        {
                            tmp.push_back(input[{batch_id, ch_id, x_id + kx_id, y_id + ky_id}]);
                        }
                    }
                    // return maximum of list to output buffer
                    output_buffer[{batch_id, ch_id, out_x_id, out_y_id}] = *std::max_element(tmp.begin(), tmp.end());

                    out_y_id++;
                }
                out_y_id = 0;
                out_x_id++;
            }
        }
    }

    return output_buffer;
}

template<typename T, typename ACC>
const char* MaxPooling<T, ACC>::name() const {
    return "MaxPooling";
}

template<typename T, typename ACC>
LayerType MaxPooling<T, ACC>::type() const {
    return LayerType::MaxPooling;
}

template<typename T, typename ACC>
unsigned MaxPooling<T, ACC>::serialize(ostream& stream) const {
    unsigned bytes = 0; 

    bytes += serialize_number(pooling_size, stream);
    bytes += serialize_vector(output_buffer.shape(), stream);

    return bytes;
}

template<typename T, typename ACC>
MaxPooling<T, ACC> MaxPooling<T, ACC>::deserialize(span<char>& data) {
    size_t pooling_size = deserialize_number<size_t>(data);

    vector<size_t> out_shape = deserialize_vector<size_t>(data);
    Matrix<T> output_buffer(out_shape);

    return MaxPooling(pooling_size, output_buffer);
}
