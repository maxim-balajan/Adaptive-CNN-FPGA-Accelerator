#pragma once

template<typename T, typename ACC>
class Quant: public Layer<T, ACC> {
private:
    Matrix<T> output_buffer;
    T zero_point;
    T inv_scale;

public:
    Quant(vector<size_t> dimensions, T inv_scale, T zero_point);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
    virtual const char* name() const override;
};

#include "quant.tpp"
