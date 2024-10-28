#include "max_polling.h"

#include <iostream>

MaxPolling::MaxPolling(size_t pooling_size, size_t batching, size_t x, size_t y, size_t layers) : pooling_size(pooling_size), output_buffer(init_matrix_4d(batching, x, y, layers)) {}

matrix_4d MaxPolling::calc(matrix_4d input) {
    // TODO

    return output_buffer;
}
