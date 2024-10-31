#pragma once
#include "../matrix.h"
#include "layer.h"

using namespace std;

class Flatten: public Layer {
private:
    Matrix output_buffer;

public:
    Flatten(size_t batching, size_t x);

    virtual Matrix calc(Matrix input) override;
};