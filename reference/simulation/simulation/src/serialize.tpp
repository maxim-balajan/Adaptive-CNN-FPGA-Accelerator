#pragma once
#include "layers/convolution.h"
#include "layers/dense.h"
#include "layers/flatten.h"
#include "layers/layer.h"
#include "layers/max_pooling.h"
#include "layers/quant.h"
#include "layers/quant_dense.h"
#include "layers/quant_convolution.h"
#include "util.h"
#include <ostream>
#include <memory>
#include <vector>

using namespace std;

template<typename T, typename ACC>
unsigned serialize_layers(const vector<unique_ptr<Layer<T, ACC>>>& layers, ostream& stream) {
    unsigned bytes = 0;
    bytes += serialize_number(static_cast<unsigned>(layers.size()), stream);

    for (const auto& layer : layers) {
        unsigned layer_type = static_cast<unsigned>(layer.get()->type());
        bytes += serialize_number(layer_type, stream);
        bytes += layer.get()->serialize(stream);
    }

    return bytes;
}


template<typename T, typename ACC>
vector<unique_ptr<Layer<T, ACC>>> deserialize_layers(span<char>& data) {
    unsigned num_layers = deserialize_number<unsigned>(data);

    vector<unique_ptr<Layer<T, ACC>>> layers;

    for (unsigned i = 0; i < num_layers; i++) {
        unsigned layer_type = deserialize_number<unsigned>(data);
        switch (static_cast<LayerType>(layer_type)) {
            case LayerType::Convolution:
                layers.push_back(make_unique<Convolution<T, ACC>>(Convolution<T, ACC>::deserialize(data)));
                break;
            case LayerType::Dense:
                layers.push_back(make_unique<Dense<T, ACC>>(Dense<T, ACC>::deserialize(data)));
                break;
            case LayerType::Flatten:
                layers.push_back(make_unique<Flatten<T, ACC>>(Flatten<T, ACC>::deserialize(data)));
                break;
            case LayerType::MaxPooling:
                layers.push_back(make_unique<MaxPooling<T, ACC>>(MaxPooling<T, ACC>::deserialize(data)));
                break;
            case LayerType::QuantConvolution:
                layers.push_back(make_unique<QuantConvolution<T, ACC>>(QuantConvolution<T, ACC>::deserialize(data)));
                break;
            case LayerType::QuantDense:
                layers.push_back(make_unique<QuantDense<T, ACC>>(QuantDense<T, ACC>::deserialize(data)));
                break;
            case LayerType::Quant:
                layers.push_back(make_unique<Quant<T, ACC>>(Quant<T, ACC>::deserialize(data)));
                break;
            default:
                throw exception();
        }
    }
    
    return layers;    
}
