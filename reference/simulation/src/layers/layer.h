#pragma once

#include "../matrix.h"

template<typename T>
class Layer {
public:
    virtual ~Layer() {}
    virtual Matrix<T>& calc(Matrix<T>& input) = 0;

};
