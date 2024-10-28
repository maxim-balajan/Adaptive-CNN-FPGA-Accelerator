#pragma once
#include "../matrix.h"

using namespace std;

class Flatten {
private:
    matrix_2d output_buffer;

public:
    Flatten(size_t batching, size_t x);

    matrix_2d calc(matrix_4d input);
};