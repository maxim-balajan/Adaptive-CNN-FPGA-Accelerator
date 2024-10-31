#pragma once
#include "../matrix.h"
#include "layer.h"

using namespace std;

class Dense: public Layer {
private:
    Matrix output_buffer;
    Matrix weights;
    Matrix bias;
    bool enable_softmax;

public:
    Dense(Matrix weights, Matrix bias, bool enable_softmax, size_t batching, size_t x);

    Matrix softmax(Matrix input);
    virtual Matrix calc(Matrix input) override;
};