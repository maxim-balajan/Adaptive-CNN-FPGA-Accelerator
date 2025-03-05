#pragma once

#include "layer.h"
#include "../data/matrix.h"
#include <span>

using namespace std;

template<typename T, typename ACC>
class Flatten: public Layer<T, ACC> {
private:
    Matrix<T> output_buffer;

    Flatten(Matrix<T> output_buffer);

public:
    Flatten(size_t batching, size_t x);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
    virtual const char* name() const override;
    virtual LayerType type() const override;
    virtual unsigned serialize(ostream& stream) const override;
    static Flatten deserialize(span<char>& data);
};

#include "flatten.tpp"
