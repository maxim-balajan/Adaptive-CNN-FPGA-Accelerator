#include <string>
#include <fstream>
#include <iostream>
#include <cstdint>
#include <tuple>

// include our onnx proto model
#include <onnx.pb.h>

#include "util.h"

#include "parser.h"
#include "../layers/convolution.h"
#include "../layers/dense.h"
#include "../layers/flatten.h"
#include "../layers/max_pooling.h"
#include "data_converter.h"

using namespace std;

namespace {

    template<typename TYPE>
    inline bool _should_print(TYPE &val) {
        return true;
    }

    inline bool _should_print(string &val) {
        return val.length() != 0;
    }


    inline void _print_info_concat(const string &name) {}

    template<typename Arg, typename... Args>
    inline void _print_info_concat(const string &name, Arg arg, Args... args) {
        if (_should_print(arg)) {
            cout << " " << arg;
        }

        _print_info_concat(name, args...);
    }

    inline void print_info(const string &name) {}

    template<typename Arg, typename... Args>
    inline void print_info(const string &name, Arg arg, Args... args) {
        if (_should_print(arg)) {
            cout << name << ": " << arg;
            _print_info_concat(name, args...);
            cout << "\n";
        } else {
            print_info(name, args...);
        }
    }

    inline void print_value_info_proto(const string &name, onnx::ValueInfoProto val) {
        if (val.type().has_tensor_type()) {
            string dimensions = "[";
            for (auto dim: val.type().tensor_type().shape().dim()) {
                if (dimensions.length() != 1) {
                    dimensions.append(",");
                } else {
                }
                if (dim.has_dim_param()) {
                    dimensions.append(dim.dim_param());
                } else if (dim.has_dim_value()) {
                    dimensions.append(to_string(dim.dim_value()));
                }
            }
            dimensions.append("]");

            print_info(name, val.name(), val.doc_string(), dimensions);
        }
    }

    vector<size_t> parse_dimensions(const onnx::ValueInfoProto val) {
        vector<size_t> dimensions;
        if (val.type().has_tensor_type()) {
            for (auto dim: val.type().tensor_type().shape().dim()) {
                if (dim.has_dim_value()) {
                    dimensions.push_back(dim.dim_value());
                }
            }
        }

        return dimensions;
    }

    template<typename T>
    Matrix<T> parse_matrix(const onnx::TensorProto& tensor) {
        if (tensor.data_location() != onnx::TensorProto::DEFAULT) {
            throw ParsingException("External storage of data is not supported!");
        }

        vector<size_t> dimensions;
        for (auto dim : tensor.dims()) {
            dimensions.push_back(static_cast<size_t>(dim));
        }

        Matrix<T> matrix(dimensions);
        if (tensor.float_data().size() != 0) {
            if (tensor.data_type() != onnx::TensorProto::FLOAT) {
                throw ParsingException("Float data but data type is not float?!");
            }

            // cool, data is already stored as floats
            assertm(tensor.float_data().size() == matrix.total_size(), "Tensor data has to match its shape!");
            for (int i = 0; i < tensor.float_data().size(); i++) {
                float item = tensor.float_data()[i];
                matrix[i] = convert_data<float, T>(item);
            }

        } else if (tensor.int64_data().size() != 0) {
            if (tensor.data_type() != onnx::TensorProto::INT64) {
                throw ParsingException("Int64 data but data type is not int64?!");
            }

            // cool, data is already stored as ints
            assertm(tensor.int64_data().size() == matrix.total_size(), "Tensor data has to match its shape!");
            for (int i = 0; i < tensor.int64_data().size(); i++) {
                int64_t item = tensor.int64_data()[i];
                matrix[i] = convert_data<int64_t, T>(item);
            }
        } else if (tensor.raw_data().size() != 0) {
            // data is stored in as binary data, convert it now
            if (tensor.data_type() == onnx::TensorProto::FLOAT) {
                assertm(tensor.raw_data().size() == matrix.total_size() * 4, "Tensor data has to match its shape!");
                for (int i = 0; i < tensor.raw_data().size(); i += 4) {
                    const char *ptr = &(tensor.raw_data()[0]) + i;
                    const float *float_ptr = reinterpret_cast<const float*>(ptr);

                    matrix[i/4] = convert_data<float, T>(*float_ptr);
                }
            } else if (tensor.data_type() == onnx::TensorProto::INT64) {
                assertm(tensor.raw_data().size() == matrix.total_size() * 8, "Tensor data has to match its shape!");
                int8_t bytes[8];
                for (int i = 0; i < tensor.raw_data().size(); i += 8) {
                    for (int j = 0; j < 8; j++) {
                        bytes[j] = tensor.raw_data()[i + j];
                    }
                    int64_t *data = reinterpret_cast<int64_t*>(&bytes);
                    matrix[i/8] = convert_data<int64_t, T>(*data);
                }
            }
        } else {
            throw ParsingException("Matrix data not found!");
        }

        return matrix;
    }

    template<typename T>
    Matrix<T> find_matrix(const google::protobuf::RepeatedPtrField<onnx::TensorProto>& tensors, const string& name) {
        for (const auto& tensor : tensors) {
            if (tensor.name() == name) {
                return parse_matrix<T>(tensor);
            }
        }

        throw new ParsingException("No initializer matched this name!");
    }

    const onnx::AttributeProto& find_attribute(const google::protobuf::RepeatedPtrField<onnx::AttributeProto>& attributes, const string& name) {
        for (auto& attribute : attributes) {
            if (attribute.name() == name) {
                return attribute;
            }
        }

        throw ParsingException("did not find value!");
    }

    template<size_t N>
    array<int64_t, N> parse_shape(const onnx::AttributeProto& shape) {
        if (shape.type() != onnx::AttributeProto::INTS) {
            throw ParsingException("Shape is expected to be ints!");
        }
        if (shape.ints().size() != N) {
            throw ParsingException("Shape has to be the same size as N!");
        }

        array<int64_t, N> arr;
        for (int i = 0; i < shape.ints().size(); i++) {
            arr[i] = shape.ints()[i];
        }

        return arr;
    }

    void print_dimensions(const vector<size_t>& dimensions) {
        for (int dim_i = 0; dim_i < dimensions.size(); dim_i++) {
            if (dim_i != 0) {
                cout << "x";
            }
            cout << dimensions[dim_i];
        }
    }

    template<typename T>
    vector<unique_ptr<Layer<T>>> initialize_layers(onnx::ModelProto& model, unsigned int batching) {
        auto graph = model.graph();

        cout << "Parsing layers..." << endl;

        vector<unique_ptr<Layer<T>>> layers;
        vector<size_t> curr_dimensions = parse_dimensions(graph.input()[0]);
        for (int i = 0; i < graph.node().size(); i++) {
            auto curr_node = graph.node()[i];

            print_dimensions(curr_dimensions);
            cout << " --> ";

            if (curr_node.op_type() == "Conv") {
                if (i + 1 < graph.node().size() && graph.node()[i + 1].op_type() == "Relu") {
                    if (curr_node.input().size() != 3) {
                        throw new ParsingException("invalid amount of inputs!");
                    }

                    // lets hope that matrices are just stored this way...
                    // if the order changes here, we are fucked :)
                    Matrix<T> kernel = find_matrix<T>(graph.initializer(), curr_node.input()[1]);
                    assertm(kernel.shape().size() == 4, "Kernel has to be 4D!");
                    if (kernel.shape()[2] != kernel.shape()[3]) {
                        throw new ParsingException("We only support 2D filter in the conv layer!");
                    }

                    size_t channel_count = kernel.shape()[0];
                    size_t filter_size = kernel.shape()[2];

                    Matrix<T> bias = find_matrix<T>(graph.initializer(), curr_node.input()[2]);
                    assertm(bias.shape().size() == 1, "Bias has to be 1D!");

                    // update dimensions
                    curr_dimensions[0] -= filter_size - 1;
                    curr_dimensions[1] -= filter_size - 1;
                    curr_dimensions[2] = channel_count;

                    Convolution<T> convolution(kernel, bias, batching, curr_dimensions[0], curr_dimensions[1], curr_dimensions[2]);
                    layers.push_back(make_unique<Convolution<T>>(convolution));

                    cout << "Convolution(..., ..., " << batching << ", " << curr_dimensions[0] << ", ";
                    cout << curr_dimensions[1] << ", " << curr_dimensions[2] << ")";

                    // skip relu as we combine them into the convolution layer
                    i++;
                } else {
                    throw ParsingException("Relu needs to be placed after conv!");
                }
            } else if (curr_node.op_type() == "MaxPool") {
                const onnx::AttributeProto& kernel_shape = find_attribute(curr_node.attribute(), "kernel_shape");
                array<int64_t, 2> kernel_shape_parsed = parse_shape<2>(kernel_shape);
                if (kernel_shape_parsed[0] != kernel_shape_parsed[1]) {
                    throw ParsingException("We only support squared kernels for MaxPooling!");
                }

                int64_t pool_size = kernel_shape_parsed[0];

                // update dimensions
                curr_dimensions[0] /= pool_size;
                curr_dimensions[1] /= pool_size;

                MaxPooling<T> pooling(pool_size, batching, curr_dimensions[0], curr_dimensions[1], curr_dimensions[2]);
                layers.push_back(make_unique<MaxPooling<T>>(pooling));

                cout << "MaxPooling(" << pool_size << ", " << batching << ", ";
                cout << curr_dimensions[0] << ", " << curr_dimensions[1] << ")";

            } else if (curr_node.op_type() == "MatMul") {
                if (curr_dimensions.size() != 1) {
                    throw ParsingException("Dense requires a 1D input");
                }

                if (i + 1 < graph.node().size() && graph.node()[i + 1].op_type() == "Add") {
                    auto add_node = graph.node()[i + 1];

                    bool softmax;
                    if (i + 2 < graph.node().size() && graph.node()[i + 2].op_type() == "Softmax") {
                            softmax = true;
                        // skip Add and Softmax as we combine them into one dense layer
                        i += 2;
                    } else {
                            softmax = false;
                        // skip Add as we combine it into one dense layer
                        i++;
                    }

                    if (curr_node.input().size() != 2) {
                        throw new ParsingException("invalid amount of inputs!");
                    }

                    Matrix<T> weights = find_matrix<T>(graph.initializer(), curr_node.input()[1]);
                    assertm(weights.shape().size() == 2, "Weights have to be a 2D matrix!");
                    assertm(weights.shape()[0] == curr_dimensions[0],
                        "First dimension of weights have to match current dimensions!");
                    
                    Matrix<T> bias = find_matrix<T>(graph.initializer(), add_node.input()[1]);
                    
                    curr_dimensions[0] = weights.shape()[1];

                    Dense<T> dense(weights, bias, softmax, batching, curr_dimensions[0]);
                    layers.push_back(make_unique<Dense<T>>(dense));

                    cout << "Dense(..., " << softmax << ", " << batching << ", " << curr_dimensions[0] << ")";
                } else {
                    throw ParsingException("Add needs to be placed after MatMul!");
                }
            } else if (curr_node.op_type() == "Transpose") {
                cout << "Transpose[Ignored]";
            } else if (curr_node.op_type() == "Reshape") {
                if (curr_node.input().size() != 2) {
                    throw new ParsingException("invalid amount of inputs!");
                }

                Matrix<int64_t> dimensions = find_matrix<int64_t>(graph.initializer(), curr_node.input()[1]);
                if (dimensions.total_size() != 2) {
                    cout << "Reshape[ignored]";
                } else {
                    size_t size = 1;
                    for (auto& dim: curr_dimensions) {
                        size *= dim;
                    }
                    curr_dimensions.clear();
                    curr_dimensions.push_back(size);

                    Flatten<T> flatten(batching, size);
                    layers.push_back(make_unique<Flatten<T>>(flatten));

                    cout << "Flatten(" << batching << ", " << curr_dimensions[0] << ")";
                }

            } else if (curr_node.op_type() == "Relu") {
                throw ParsingException("Relu occurred in the wrong location!");    
            } else if (curr_node.op_type() == "Add") {
                throw ParsingException("Add occurred in the wrong location!");
            } else if (curr_node.op_type() == "Softmax") {
                throw ParsingException("Softmax occurred in the wrong location!");
            } else {
                throw ParsingException("Invalid op type: " + curr_node.op_type());
            }
            
            cout << " --> ";
            print_dimensions(curr_dimensions);
            cout << endl;
        }


        return layers;
    }
}

template<typename T>
vector<unique_ptr<Layer<T>>> parse(const string &filename, unsigned int batching) {
    fstream file;
    file.open(filename, fstream::in | fstream::binary);

    cout << "Parsing \"" << filename << "\"..." << endl;

    // parse model
    onnx::ModelProto model;
    if(!model.ParseFromIstream(&file))
        throw ParsingException("Parsing failed!");
    
    cout << "Loaded model!\n";

    // print some model infos
    print_info("Producer", model.producer_name(), model.producer_version());
    print_info("Documentation", model.doc_string());
    // for (auto x : model.opset_import()) {
    //     print_info("Opset Import", x.domain(), x.version());
    // }
    // print_info("Domain", model.domain());
    // for (auto x : model.metadata_props()) {
    //     print_info("Metadata Props", x.key(), x.value());
    // }
    // print_info("Graph name", model.graph().name());
    // print_info("Graph Documentation", model.graph().doc_string());
    // for (auto x : model.graph().metadata_props()) {
    //     print_info("Graph Metadata Props", x.key(), x.value());
    // }
    for (auto x : model.graph().input()) {
        print_value_info_proto("Graph Input", x);
    }
    for (auto x : model.graph().output()) {
        print_value_info_proto("Graph Output", x);
    }

    return initialize_layers<T>(model, batching);
}
