#pragma once
#include "../matrix.h"
#include "layer.h"

using namespace std;

class Convolution: public Layer {
private:
    Matrix output_buffer;
    Matrix kernel;
    Matrix bias;

public:
    Convolution(Matrix kernel, Matrix bias, size_t batching, size_t x, size_t y, size_t output_channel);

    virtual Matrix calc(Matrix input) override;
    float relu(float val);
};