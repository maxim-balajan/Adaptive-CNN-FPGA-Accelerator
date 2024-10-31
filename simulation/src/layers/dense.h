#pragma once
#include "../matrix.h"

using namespace std;

class Dense {
private:
    Matrix output_buffer;
    Matrix weights;
    Matrix bias;

public:
    Dense(Matrix weights, Matrix bias, size_t batching, size_t x);

    Matrix softmax(Matrix input);
    
    Matrix calc(Matrix input);
};