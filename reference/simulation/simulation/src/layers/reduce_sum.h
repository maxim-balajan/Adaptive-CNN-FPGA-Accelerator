#pragma once

#include "layer.h"
#include "../data/matrix.h"
#include <span>

using namespace std;

template<typename T, typename ACC>
class ReduceSum: public Layer<T, ACC> {
private:
    Matrix<T> output_buffer;
    const vector<size_t> new_dimensions;
    const size_t dimension;

    const float s_x;
    const float s_y;

    const uint8_t s_x_shift;


    ReduceSum(vector<size_t> new_dimensions, size_t dimension, float s_x, float s_y, Matrix<T> output_buffer);

public:
    // zero points are left out because they will always be 0
    ReduceSum(vector<size_t> new_dimensions, size_t dimension, float s_x, float s_y, size_t batching, size_t x, size_t y, size_t output_channel);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
    virtual const char* name() const override;
    virtual LayerType type() const override;
    virtual unsigned serialize(ostream& stream) const override;
    static ReduceSum deserialize(span<char>& data);
};

#include "reduce_sum.tpp"
