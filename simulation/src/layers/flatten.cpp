#include "flatten.h"
#include "../assert.h"

#include <ranges>

Flatten::Flatten(size_t batching, size_t x) : output_buffer({batching * x}) {}

Matrix Flatten::calc(Matrix input) {
    assertm(output_buffer.total_size() == input.total_size(), "Dimensions must match");

    output_buffer.reinterpret_dimensions(input.shape());
    output_buffer = input;
    output_buffer.flatten();
    return output_buffer;
}
