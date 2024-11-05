#pragma once

#include "../matrix.h"

class Layer {
public:
    virtual ~Layer() {}
    virtual Matrix& calc(Matrix& input) = 0;

};
