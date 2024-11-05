#pragma once
#include <string>
#include <memory>
#include "../layers/layer.h"

using namespace std;

vector<unique_ptr<Layer>> parse(const string &filename, unsigned int batching = 1);
