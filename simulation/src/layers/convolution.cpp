#include "convolution.h"

#include <iostream>

Convolution::Convolution(matrix kernel, size_t batching, size_t x, size_t y, size_t layers) : Layer(batching, x, y, layers), kernel(kernel) {
    // TODO
}

matrix Convolution::calc(matrix input) {
    // TODO
}
