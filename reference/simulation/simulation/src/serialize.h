#pragma once

#include "layers/layer.h"
#include <ostream>
#include <memory>

#include <span>

using namespace std;

template<typename T, typename ACC>
unsigned serialize_layers(const vector<unique_ptr<Layer<T, ACC>>>& layers, ostream& stream);

template<typename T, typename ACC>
vector<unique_ptr<Layer<T, ACC>>> deserialize_layers(span<char>& data);

#include "serialize.tpp"
