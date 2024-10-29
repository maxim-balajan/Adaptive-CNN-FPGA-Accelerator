#pragma once
#include "../matrix.h"

using namespace std;

class Convolution {
private:
    matrix_4d output_buffer;
    matrix_4d kernel;
    matrix_1d bias;

public:
    Convolution(matrix_4d kernel, matrix_1d bias, size_t batching, size_t x, size_t y, size_t output_channel);

    matrix_4d calc(matrix_4d input);
};