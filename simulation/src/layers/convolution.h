#pragma once
#include "../matrix.h"

using namespace std;

class Convolution {
private:
    Matrix output_buffer;
    Matrix kernel;

public:
    Convolution(Matrix kernel, size_t batching, size_t x, size_t y, size_t layers);

    Matrix calc(Matrix input);
};