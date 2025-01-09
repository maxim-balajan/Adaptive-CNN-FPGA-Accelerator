#pragma once
#include <string>
#include <memory>
#include <common.h>

using namespace std;

struct QuantArguments {
    float scale;
    float zero_point;
};

template<typename T, typename ACC>
tuple<vector<unique_ptr<Layer<T, ACC>>>, QuantArguments> parse_quantized(const string &filename, unsigned int batching = 1);

#include "quant_parser.tpp"
