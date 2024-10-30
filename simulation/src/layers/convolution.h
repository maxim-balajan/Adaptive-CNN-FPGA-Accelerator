#pragma once
#include "../matrix.h"

using namespace std;

class Convolution {
private:
    Matrix output_buffer;
    Matrix kernel;
    Matrix bias;

public:
    Convolution(Matrix kernel, Matrix bias, size_t batching, size_t x, size_t y, size_t output_channel);

    Matrix calc(Matrix input);
};