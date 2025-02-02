#include "flatten.h"

#include <ranges>

template<typename T, typename ACC>
Flatten<T, ACC>::Flatten(size_t batching, size_t x) : output_buffer({batching, x}) {}

template<typename T, typename ACC>
const Matrix<T>& Flatten<T, ACC>::calc(const Matrix<T>& input) {
    assertm(output_buffer.total_size() == input.total_size(), "Dimensions must match");

    for (auto i = 0; i < output_buffer.total_size(); i++) {
        output_buffer[i] = input[i];
    }

    return output_buffer;
}

template<typename T, typename ACC>
const char* Flatten<T, ACC>::name() const {
    return "Flatten";
}
