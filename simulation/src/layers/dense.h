#pragma once
#include "../matrix.h"

using namespace std;

class Dense {
private:
    matrix_2d output_buffer;
    matrix_1d weights;

public:
    Dense(matrix_1d weights, size_t batching, size_t x);

    matrix_2d calc(matrix_2d input);
};