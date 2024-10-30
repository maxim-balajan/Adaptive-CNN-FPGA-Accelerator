#include "max_polling.h"

#include <iostream>

MaxPolling::MaxPolling(size_t pooling_size, size_t batching, size_t x, size_t y, size_t layers) : pooling_size(pooling_size), output_buffer({batching, x, y, layers}) {}

Matrix MaxPolling::calc(Matrix input) {
    // TODO

    return output_buffer;
}
