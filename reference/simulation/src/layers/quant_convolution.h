#pragma once
#include "../data/matrix.h"
#include "layer.h"

using namespace std;

template<typename T, typename ACC>
class QuantConvolution: public Layer<T, ACC> {
private:
    Matrix<T> output_buffer;
    const Matrix<T> kernel;
    const Matrix<T> bias;
    const float s_b;
    const float s_x;
    const float s_w;
    const float s_y;

public:
    // zero points are left out because they will always be 0
    QuantConvolution(Matrix<T> kernel, Matrix<T> bias, size_t batching, size_t x, size_t y, size_t output_channel, float s_b, float s_x, float s_w, float s_y);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
};

#include "quant_convolution.tpp"
