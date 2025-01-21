#pragma once

#include <simulation.h>

template<typename FROM, typename TO>
Matrix<TO> parse_matrix(const string& filename);

template<typename FROM, typename TO>
Matrix<TO> parse_matrix(std::istream& stream);

template<typename FROM, typename TO>
Matrix<TO> parse_quantized_matrix(const string& filename, float scale, float zero_point);

template<typename FROM, typename TO>
Matrix<TO> parse_quantized_matrix(std::istream& stream, float scale, float zero_point);


#include "../src/npy_parser.tpp"
