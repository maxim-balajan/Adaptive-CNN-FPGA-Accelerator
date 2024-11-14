#pragma once
#include "../matrix.h"
#include "layer.h"

using namespace std;

template<typename T>
class MaxPooling: public Layer<T> {
private:
    Matrix<T> output_buffer;
    size_t pooling_size;

public:
    // pooling is defined here to be quadratically all the time
    MaxPooling(size_t pooling_size, size_t batching, size_t x, size_t y, size_t output_channel);

    virtual Matrix<T>& calc(Matrix<T>& input) override;
};

#include "max_pooling.tpp"