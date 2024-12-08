#pragma once
#include "../data/matrix.h"
#include "layer.h"

using namespace std;

template<typename T, typename ACC>
class Dense: public Layer<T, ACC> {
private:
    Matrix<T> output_buffer;
    const Matrix<T> weights;
    const Matrix<T> bias;
    bool enable_softmax;

public:
    Dense(Matrix<T> weights, Matrix<T> bias, bool enable_softmax, size_t batching, size_t x);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
};

#include "dense.tpp"
