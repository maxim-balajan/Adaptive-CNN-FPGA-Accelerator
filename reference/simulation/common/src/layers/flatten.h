#pragma once
#include "data/matrix.h"
#include "layer.h"

using namespace std;

template<typename T, typename ACC>
class Flatten: public Layer<T, ACC> {
private:
    Matrix<T> output_buffer;

public:
    Flatten(size_t batching, size_t x);

    virtual const Matrix<T>& calc(const Matrix<T>& input) override;
};

#include "flatten.tpp"
