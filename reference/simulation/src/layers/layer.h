#pragma once

#include "../matrix.h"

template<typename T>
class Layer {
public:
    virtual ~Layer() {}
    virtual const Matrix<T>& calc(const Matrix<T>& input) = 0;

};
