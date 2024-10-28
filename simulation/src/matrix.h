#pragma once

#include <vector>
using namespace std;

using matrix_1d = vector<float>;
using matrix_2d = vector<vector<float>>;
using matrix_4d = vector<vector<vector<vector<float>>>>;

inline matrix_2d init_matrix_2d(size_t a, size_t b) {
    matrix_2d vec(a, vector<float>(b, 0));
    return vec;
}

inline matrix_4d init_matrix_4d(size_t a, size_t b, size_t c, size_t d) {
    matrix_4d vec(a, vector<vector<vector<float>>>(b, vector<vector<float>>(c, vector<float>(d))));
    return vec;
}
