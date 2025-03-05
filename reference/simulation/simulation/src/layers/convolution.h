#pragma once

#include "layer.h"
#include "../data/matrix.h"
#include <span>

using namespace std;

template<typename T, typename ACC>
class Convolution: public Layer<T, ACC> {
private:
    Matrix<T> output_buffer;
    const Matrix<T> kernel;
    const Matrix<T> bias;

    Convolution(Matrix<T> kernel, Matrix<T> bias, Matrix<T> output_buffer);

public:
    Convolution(Matrix<T> kernel, Matrix<T> bias, size_t batching, size_t x, size_t y, size_t output_channel);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
    virtual const char* name() const override;
    virtual LayerType type() const override;
    virtual unsigned serialize(ostream& stream) const override;
    static Convolution deserialize(span<char>& data);
};

#include "convolution.tpp"
