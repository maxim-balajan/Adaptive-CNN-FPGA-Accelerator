#pragma once

#include "npy_parser.tpp"

template<typename FROM, typename TO>
Matrix<TO> parse_matrix(string path);

