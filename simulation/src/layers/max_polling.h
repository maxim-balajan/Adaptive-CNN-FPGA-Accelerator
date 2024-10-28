#pragma once
#include "../matrix.h"

using namespace std;

class MaxPolling {
private:
    matrix_4d output_buffer;
    size_t pooling_size;

public:
    // pooling is defined here to be quadratically all the time
    MaxPolling(size_t pooling_size, size_t batching, size_t x, size_t y, size_t layers);

    matrix_4d calc(matrix_4d input);
};
