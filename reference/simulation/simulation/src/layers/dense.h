#pragma once

#include "layer.h"
#include "../data/matrix.h"
#include <span>

using namespace std;

template<typename T, typename ACC>
class Dense: public Layer<T, ACC> {
private:
    Matrix<T> output_buffer;
    const Matrix<T> weights;
    const Matrix<T> bias;
    bool enable_softmax;

    Dense(Matrix<T> weights, Matrix<T> bias, Matrix<T> output_buffer, bool enable_softmax);

public:
    Dense(Matrix<T> weights, Matrix<T> bias, bool enable_softmax, size_t batching, size_t x);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
    virtual const char* name() const override;
    virtual LayerType type() const override;
    virtual unsigned serialize(ostream& stream) const override;
    static Dense deserialize(span<char>& data);
};

#include "dense.tpp"
