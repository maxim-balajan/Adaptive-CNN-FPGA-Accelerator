#pragma once
#include "../matrix.h"

using namespace std;

class Flatten {
private:
    Matrix output_buffer;

public:
    Flatten(size_t batching, size_t x);

    Matrix calc(Matrix input);
};