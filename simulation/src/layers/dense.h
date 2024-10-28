#pragma once
#include "layer.h"

using namespace std;

class Dense: public Layer {
private:
    matrix weights;

public:
    Dense(matrix weights, size_t);

    virtual matrix calc(matrix input) override;
};