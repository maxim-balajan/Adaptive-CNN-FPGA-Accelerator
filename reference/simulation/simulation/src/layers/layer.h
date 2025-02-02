#pragma once

template<typename T, typename ACC>
class Layer {
public:
    virtual ~Layer() {}
    virtual const Matrix<T>& calc(const Matrix<T>& input) = 0;
    virtual const char* name() const = 0;
};
