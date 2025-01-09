#pragma once
// #include "data/matrix.h"

template<typename T, typename ACC>
class Layer {
public:
    virtual ~Layer() {}
    virtual const Matrix<T>& calc(const Matrix<T>& input) = 0;

};
