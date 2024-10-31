#pragma once
#include "../matrix.h"
#include "layer.h"

using namespace std;

class MaxPolling: public Layer {
private:
    Matrix output_buffer;
    size_t pooling_size;

public:
    // pooling is defined here to be quadratically all the time
    MaxPolling(size_t pooling_size, size_t batching, size_t x, size_t y, size_t output_channel);

    virtual Matrix& calc(Matrix& input) override;
};
