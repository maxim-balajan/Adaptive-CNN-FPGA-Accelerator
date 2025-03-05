#pragma once

#include "layer.h"
#include "../data/matrix.h"
#include <span>

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

    QuantDense(Matrix<T> weights, Matrix<T> bias, bool enable_softmax, Matrix<T> output_buffer, float s_b, float s_x, float s_w, float s_y);

public:
    QuantDense(Matrix<T> weights, Matrix<T> bias, bool enable_softmax, size_t batching, size_t x, float s_b, float s_x, float s_w, float s_y);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
    virtual const char* name() const override;
    virtual LayerType type() const override;
    virtual unsigned serialize(ostream& stream) const override;
    static QuantDense deserialize(span<char>& data);
};

#include "quant_dense.tpp"
