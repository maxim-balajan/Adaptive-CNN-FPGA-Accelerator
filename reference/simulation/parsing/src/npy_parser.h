#pragma once

#include <common.h>

template<typename FROM, typename TO>
Matrix<TO> parse_matrix(string path);

#include "npy_parser.tpp"
