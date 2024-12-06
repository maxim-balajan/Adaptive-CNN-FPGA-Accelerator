#include "quant.h"
#include "../assert.h"

template<typename T>
Quant<T>::Quant(vector<size_t> dimensions, T inv_scale, T zero_point)
    : output_buffer(dimensions)
    , zero_point(zero_point)
    , inv_scale(inv_scale) {}

template<typename T>
const Matrix<T>& Quant<T>::calc(const Matrix<T>& input) {
    assertm(input.total_size() == output_buffer.total_size(), "sizes should match!");

    // clamp should happen automatically
    for (int i = 0; i < input.total_size(); i++) {
        // TODO check different precisions
        output_buffer[i] = input[i] * inv_scale + zero_point;
    }

    return output_buffer;
}

