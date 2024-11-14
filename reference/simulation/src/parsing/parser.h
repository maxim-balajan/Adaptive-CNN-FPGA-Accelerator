#pragma once
#include <string>
#include <memory>
#include "../layers/layer.h"

using namespace std;

template<typename T>
vector<unique_ptr<Layer<T>>> parse(const string &filename, unsigned int batching = 1);

#include "parser.tpp"
