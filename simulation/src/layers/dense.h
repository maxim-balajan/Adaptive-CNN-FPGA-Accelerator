#pragma once
#include "../matrix.h"

using namespace std;

class Dense {
private:
    Matrix output_buffer;
    Matrix weights;

public:
    Dense(Matrix weights, size_t batching, size_t x);

    Matrix calc(Matrix input);
};