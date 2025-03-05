#pragma once

#include "layer.h"
#include "../data/matrix.h"
#include <span>

using namespace std;

template<typename T, typename ACC>
class MaxPooling: public Layer<T, ACC> {
private:
    Matrix<T> output_buffer;
    size_t pooling_size;

    MaxPooling(size_t pooling_size, Matrix<T> output_buffer);

public:
    // pooling is defined here to be quadratically all the time
    MaxPooling(size_t pooling_size, size_t batching, size_t x, size_t y, size_t output_channel);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
    virtual const char* name() const override;
    virtual LayerType type() const override;
    virtual unsigned serialize(ostream& stream) const override;
    static MaxPooling deserialize(span<char>& data);
};

#include "max_pooling.tpp"