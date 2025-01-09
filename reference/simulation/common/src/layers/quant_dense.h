#pragma once
// #include "data/matrix.h"
// #include "layer.h"

using namespace std;

template<typename T, typename ACC>
class QuantDense: public Layer<T, ACC> {
private:
    Matrix<T> output_buffer;
    const Matrix<T> weights;
    const Matrix<T> bias;
    bool enable_softmax;
    float s_b;
    float s_x;
    float s_w;
    float s_y;

public:
    QuantDense(Matrix<T> weights, Matrix<T> bias, bool enable_softmax, size_t batching, size_t x, float s_b, float s_x, float s_w, float s_y);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
};

#include "quant_dense.tpp"
