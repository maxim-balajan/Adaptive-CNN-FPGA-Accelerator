#pragma once
#include "layer.h"

using namespace std;

class Convolution: public Layer {
private:
    matrix kernel;

public:
    Convolution(matrix kernel, size_t batching, size_t x, size_t y, size_t layers);

    virtual matrix calc(matrix input) override;
};