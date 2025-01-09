#pragma once

#include <simulation.h>

template<typename FROM, typename TO>
Matrix<TO> parse_matrix(string path);

#include "npy_parser.tpp"
