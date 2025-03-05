#pragma once

#include "layer.h"
#include "../data/matrix.h"
#include <span>
#include <vector>

using namespace std;

template<typename T, typename ACC>
class Quant: public Layer<T, ACC> {
private:
    Matrix<T> output_buffer;
    T zero_point;
    T inv_scale;

    Quant(Matrix<T> output_buffer, T inv_scale, T zero_point);

public:
    Quant(vector<size_t> dimensions, T inv_scale, T zero_point);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
    virtual const char* name() const override;
    virtual LayerType type() const override;
    virtual unsigned serialize(ostream& stream) const override;
    static Quant deserialize(span<char>& data);
};

#include "quant.tpp"
