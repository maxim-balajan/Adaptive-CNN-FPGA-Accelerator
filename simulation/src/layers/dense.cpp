#include "dense.h"

Dense::Dense(matrix_1d weights, size_t batching, size_t x) : weights(weights), output_buffer(init_matrix_2d(batching, x)) {}

matrix_2d Dense::calc(matrix_2d input) {
    // TODO

    return output_buffer;
}
