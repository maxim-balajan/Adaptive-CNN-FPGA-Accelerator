#include "convolution.h"

#include <iostream>

Convolution::Convolution(matrix_2d kernel, size_t batching, size_t x, size_t y, size_t layers) : kernel(kernel), output_buffer(init_matrix_4d(batching, x, y, layers)) {}

matrix_4d Convolution::calc(matrix_4d input) {
    // TODO

    return output_buffer;
}
