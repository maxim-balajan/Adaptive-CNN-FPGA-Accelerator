#pragma once
#include "../matrix.h"
#include "layer.h"

using namespace std;

template<typename T>
class Flatten: public Layer<T> {
private:
    Matrix<T> output_buffer;

public:
    Flatten(size_t batching, size_t x);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
};

#include "flatten.tpp"
