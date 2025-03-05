#pragma once
#include "flatten.h"

template<typename T, typename ACC>
Flatten<T, ACC>::Flatten(Matrix<T> output_buffer) : output_buffer(output_buffer) {}

template<typename T, typename ACC>
Flatten<T, ACC>::Flatten(size_t batching, size_t x) : Flatten(Matrix<T>({batching, x})) {}

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

template<typename T, typename ACC>
LayerType Flatten<T, ACC>::type() const {
    return LayerType::Flatten;
}

template<typename T, typename ACC>
unsigned Flatten<T, ACC>::serialize(ostream& stream) const {
    return serialize_vector(output_buffer.shape(), stream);
}

template<typename T, typename ACC>
Flatten<T, ACC> Flatten<T, ACC>::deserialize(span<char>& data) {
    vector<size_t> out_shape = deserialize_vector<size_t>(data);
    Matrix<T> output_buffer(out_shape);

    return Flatten(output_buffer);
}

