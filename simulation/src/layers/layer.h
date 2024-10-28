#pragma once

#include <vector>
#include <array>

using namespace std;

using matrix_2d = vector<vector<vector<vector<float>>>>;
using matrix_4d = vector<vector<vector<vector<float>>>>;

template<size_t DIMENSIONS, typename MATRIX>
class Layer {
protected:
    MATRIX output_buffer;

public:
    Layer(array<size_t, DIMENSIONS> dimensions);
    virtual MATRIX calc(MATRIX input) = 0;
};


class Layer2D : public Layer<2, matrix_2d> {
public:
    Layer2D(array<size_t, 2> dimensions) : output_buffer(dimensions[i], vector<vector<float>>(dimensions[0], vector<float>(dimensions[1]))) {

    }

};
