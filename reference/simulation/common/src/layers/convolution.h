#pragma once
#include "data/matrix.h"
#include "layer.h"

using namespace std;

template<typename T, typename ACC>
class Convolution: public Layer<T, ACC> {
private:
    Matrix<T> output_buffer;
    const Matrix<T> kernel;
    const Matrix<T> bias;

public:
    Convolution(Matrix<T> kernel, Matrix<T> bias, size_t batching, size_t x, size_t y, size_t output_channel);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
};

#include "convolution.tpp"
