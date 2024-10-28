#pragma once
#include "layer.h"

using namespace std;

class MaxPolling: public Layer {
private:
    // TODO

public:
    MaxPolling(size_t batching, size_t x, size_t y, size_t layers);

    virtual matrix calc(matrix input) override;
};
