#pragma once

#include "../data/matrix.h"
#include "npy_parser.tpp"

template<typename FROM, typename TO>
Matrix<TO> parse_matrix(string path);

