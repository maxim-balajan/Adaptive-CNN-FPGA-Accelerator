#include "convolution.h"

#include <iostream>

Convolution::Convolution(Matrix kernel, size_t batching, size_t x, size_t y, size_t layers) : kernel(kernel), output_buffer({batching, x, y, layers}) {}

Matrix Convolution::calc(Matrix input) {
    // TODO

    return output_buffer;
}
