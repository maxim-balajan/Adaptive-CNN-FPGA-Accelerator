#pragma once

#include <simulation.h>

template<typename FROM, typename TO>
Matrix<TO> parse_matrix(string path);

template<typename FROM, typename TO>
Matrix<TO> parse_quantized_matrix(string path, float scale, float zero_point);

#include "../src/npy_parser.tpp"
