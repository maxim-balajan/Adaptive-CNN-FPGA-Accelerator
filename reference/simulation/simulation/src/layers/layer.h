#pragma once

#include "../data/matrix.h"
#include <ostream>

enum class LayerType {
    Convolution = 0,
    Dense = 1,
    Flatten = 2,
    MaxPooling = 3,
    QuantConvolution = 4,
    QuantDense = 5,
    Quant = 6
};

template<typename T, typename ACC>
class Layer {
public:
    virtual ~Layer() {}
    virtual const Matrix<T>& calc(const Matrix<T>& input) = 0;
    virtual const char* name() const = 0;
    virtual LayerType type() const = 0;
    virtual unsigned serialize(ostream& stream) const = 0;
};
