#include "dense.h"

Dense::Dense(Matrix weights, size_t batching, size_t x) : weights(weights), output_buffer({batching, x}) {}

Matrix Dense::calc(Matrix input) {
    // TODO

    return output_buffer;
}
