#pragma once
#include "../data/matrix.h"
#include "layer.h"

template<typename T>
class Quant: public Layer<T> {
private:
    Matrix<T> output_buffer;
    T zero_point;
    T inv_scale;

public:
    Quant(vector<size_t> dimensions, T zero_point, T scale);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
};

#include "quant.tpp"
