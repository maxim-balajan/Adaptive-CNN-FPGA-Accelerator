#pragma once
#include "../matrix.h"

using namespace std;

class Convolution {
private:
    matrix_4d output_buffer;
    matrix_2d kernel;

public:
    Convolution(matrix_2d kernel, size_t batching, size_t x, size_t y, size_t layers);

    matrix_4d calc(matrix_4d input);
};