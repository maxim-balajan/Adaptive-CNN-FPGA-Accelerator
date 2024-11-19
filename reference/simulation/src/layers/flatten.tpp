#include "flatten.h"
#include "../assert.h"

#include <ranges>

template<typename T>
Flatten<T>::Flatten(size_t batching, size_t x) : output_buffer({batching, x}) {}

template<typename T>
const Matrix<T>& Flatten<T>::calc(const Matrix<T>& input) {
    assertm(output_buffer.total_size() == input.total_size(), "Dimensions must match");

    for (auto i = 0; i < output_buffer.total_size(); i++) {
        output_buffer[i] = input[i];
    }

    return output_buffer;
}
