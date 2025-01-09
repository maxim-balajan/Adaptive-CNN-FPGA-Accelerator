#include <string>
#include <fstream>
#include <iostream>
#include <cstdint>
#include <tuple>
#include <vector>
#include <optional>
#include <tuple>

// include our onnx proto model
#include <onnx.pb.h>
#include <simulation.h>

using namespace std;
using namespace ParsingUtil;

namespace {

    template<typename T>
    Matrix<T> parse_quantized_initializer_matrix(const onnx::GraphProto& graph, const string& quant_node) {
        onnx::NodeProto node = find_node(graph, quant_node);

        // we just expect the inputs to be in that sequence... (if not then well...)
        Matrix<float> original_matrix = find_matrix<float>(graph.initializer(), node.input()[0]);
        float scale = find_scalar<float>(graph.initializer(), node.input()[1]);
        float offset = find_scalar<float>(graph.initializer(), node.input()[2]);

        original_matrix *= (1/scale);
        original_matrix += offset;
        
        // convert to target type
        Matrix<T> dest(original_matrix.shape());

        for (int i = 0; i < original_matrix.total_size(); i++) {
            dest[i] = convert_data<float, T>(original_matrix[i]);
        }

        return dest;
    }

    onnx::NodeProto get_root_node(const onnx::GraphProto& graph) {
        string input_name = graph.input()[0].name();

        for (auto& node : graph.node()) {
            for (auto& input : node.input()) {
                if (input == input_name) {
                    return node;
                }
            }
        }
        throw new ParsingException("Could not find the root node!");
    }

    vector<onnx::NodeProto> get_previous_nodes(const onnx::NodeProto& current_node, const onnx::GraphProto& graph) {
        vector<onnx::NodeProto> res;
        for (auto& input : current_node.input()) {
            for (auto node : graph.node()) {
                for (auto& output : node.output()) {
                    if (input == output) {
                        res.push_back(node);
                    }
                }
            }
        }

        return res;
    }

    optional<onnx::NodeProto> get_next_node(const onnx::NodeProto& current_node, const onnx::GraphProto& graph) {
        for (auto& output : current_node.output()) {
            for (auto node : graph.node()) {
                for (auto& input : node.input()) {
                    if (input == output) {
                        return node;
                    }
                }
            }
        }

        return {};
    }

    template<typename T, typename ACC>
    vector<unique_ptr<Layer<T, ACC>>> initialize_quant_layers(onnx::ModelProto& model, unsigned int batching, QuantArguments& quant_args) {
        auto graph = model.graph();

        cout << "Parsing layers..." << endl;

        vector<unique_ptr<Layer<T, ACC>>> layers;
        vector<size_t> curr_dimensions = parse_dimensions(graph.input()[0]);
        curr_dimensions[0] = batching;

        onnx::NodeProto curr_node = get_root_node(model.graph());
        onnx::NodeProto prev_node = curr_node;

        while (true) {
            print_dimensions(curr_dimensions);
            cout << " --> ";

            if (curr_node.op_type() == "Conv") {
                auto relu = get_next_node(curr_node, graph);
                if (!relu.has_value() || relu.value().op_type() != "Relu") {
                    throw ParsingException("Relu needs to be placed after conv!");
                }
                auto quant_after_relu = get_next_node(relu.value(), graph);
                if (!quant_after_relu.has_value() || quant_after_relu.value().op_type() != "Quant") {
                    throw ParsingException("Quant needs to be placed after Relu!");
                }
                // retrieve s_y of quant layer
                float s_y = find_scalar<float>(graph.initializer(), quant_after_relu.value().input()[1]);              

                auto prev_nodes = get_previous_nodes(curr_node, graph);
                if (prev_nodes.size() != 3) {
                    throw new ParsingException("invalid amount of inputs!");
                }
                auto prev_input = prev_nodes[0];
                if (prev_nodes[0].op_type() == "MaxPool")
                {
                    prev_input = get_previous_nodes(prev_input, graph)[0];
                }
                
                float s_x = find_scalar<float>(graph.initializer(), prev_input.input()[1]);

                // lets hope that matrices are just stored this way...
                Matrix<T> kernel = parse_quantized_initializer_matrix<T>(graph, prev_nodes[1].name());
                assertm(kernel.shape().size() == 4, "Kernel has to be 4D!");
                if (kernel.shape()[2] != kernel.shape()[3]) {
                    throw new ParsingException("We only support 2D filter in the conv layer!");
                }

                float s_w = find_scalar<float>(graph.initializer(), prev_nodes[1].input()[1]);

                size_t channel_count = kernel.shape()[0];
                size_t filter_size = kernel.shape()[2];

                Matrix<T> bias = parse_quantized_initializer_matrix<T>(graph, prev_nodes[2].name());
                assertm(bias.shape().size() == 1, "Bias has to be 1D!");

                float s_b = find_scalar<float>(graph.initializer(), prev_nodes[2].input()[1]);

                // update dimensions
                curr_dimensions[1] = channel_count;
                curr_dimensions[2] -= filter_size - 1;
                curr_dimensions[3] -= filter_size - 1;

                QuantConvolution<T, ACC> convolution(kernel, bias, batching, curr_dimensions[2], curr_dimensions[3], curr_dimensions[1], s_b, s_x, s_w, s_y);
                layers.push_back(make_unique<QuantConvolution<T, ACC>>(convolution));

                cout << "QuantConv(..., ..., " << curr_dimensions[0] << ", " << curr_dimensions[1] << ", ";
                cout << curr_dimensions[2] << ", " << curr_dimensions[3] << ")";

                // skip relu and quant layer as we combine them into the convolution layer
                curr_node = quant_after_relu.value();
            } else if (curr_node.op_type() == "MaxPool") {
                const onnx::AttributeProto& kernel_shape = find_attribute(curr_node.attribute(), "kernel_shape");
                array<int64_t, 2> kernel_shape_parsed = parse_shape<2>(kernel_shape);
                if (kernel_shape_parsed[0] != kernel_shape_parsed[1]) {
                    throw ParsingException("We only support squared kernels for MaxPooling!");
                }

                int64_t pool_size = kernel_shape_parsed[0];

                // update dimensions
                curr_dimensions[2] /= pool_size;
                curr_dimensions[3] /= pool_size;

                MaxPooling<T, ACC> pooling(pool_size, batching, curr_dimensions[2], curr_dimensions[3], curr_dimensions[1]);
                layers.push_back(make_unique<MaxPooling<T, ACC>>(pooling));

                cout << "MaxPooling(" << pool_size << ", " << batching << ", ";
                cout << curr_dimensions[0] << ", " << curr_dimensions[1] << ")";

            } else if (curr_node.op_type() == "Gemm") {
                if (curr_dimensions.size() != 2) {
                    throw ParsingException("Dense requires a 2D input");
                }

                auto prev_nodes = get_previous_nodes(curr_node, graph);
                if (prev_nodes.size() != 3) {
                    throw new ParsingException("invalid amount of inputs!");
                }
                // retrieve scale vector of input
                auto prev_input = prev_nodes[0];
                while (prev_input.op_type() != "Quant") {
                    prev_input = get_previous_nodes(prev_input, graph)[0];
                }
                float s_x = find_scalar<float>(graph.initializer(), prev_input.input()[1]);

                if (curr_node.input().size() != 3) {
                    throw new ParsingException("invalid amount of inputs!");
                }

                Matrix<T> weights_t = parse_quantized_initializer_matrix<T>(graph, prev_nodes[1].name());
                Matrix<T> weights = transpose_2d(weights_t);
                assertm(weights.shape().size() == 2, "Weights have to be a 2D matrix!");
                assertm(weights.shape()[0] == curr_dimensions[1],
                    "First dimension of weights have to match current dimensions!");
                // retrieve scale value of weight matrix
                float s_w = find_scalar<float>(graph.initializer(), prev_nodes[1].input()[1]);

                Matrix<T> bias_t = parse_quantized_initializer_matrix<T>(graph, prev_nodes[2].name());                
                Matrix<T> bias = transpose_2d(bias_t);
                curr_dimensions[1] = weights.shape()[1];
                // retrieve scale value of bias vector
                float s_b = find_scalar<float>(graph.initializer(), prev_nodes[2].input()[1]);
                // retrieve s_y from following quant layer
                auto quant_layer = get_next_node(curr_node, graph);
                if (!quant_layer.has_value() || quant_layer.value().op_type() != "Quant") {
                    throw ParsingException("Quant needs to be placed after Gemm!");
                }

                float s_y = find_scalar<float>(graph.initializer(), quant_layer.value().input()[1]);

                bool softmax = !get_next_node(quant_layer.value(), graph).has_value();
                QuantDense<T, ACC> dense(weights, bias, softmax, batching, curr_dimensions[1], s_b, s_x, s_w, s_y);
                layers.push_back(make_unique<QuantDense<T, ACC>>(dense));

                cout << "QuantDense(..., " << softmax << ", " << batching << ", " << curr_dimensions[1] << ")";
                // skip quant layer
                curr_node = quant_layer.value();
            
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
                    for (int i = 1; i < curr_dimensions.size(); i++) {
                        size *= curr_dimensions[i];
                    }
                    curr_dimensions.clear();

                    curr_dimensions.push_back(batching);
                    curr_dimensions.push_back(size);

                    Flatten<T, ACC> flatten(batching, size);
                    layers.push_back(make_unique<Flatten<T, ACC>>(flatten));

                    cout << "Flatten(" << batching << ", " << curr_dimensions[0] << ")";
                }

            } else if (curr_node.op_type() == "Quant") {
                float raw_scale = find_scalar<float>(graph.initializer(), curr_node.input()[1]);
                float raw_offset = find_scalar<float>(graph.initializer(), curr_node.input()[2]);

                if (curr_node.name() == prev_node.name()) {
                    cout << "Quant[Ignored]";
                    quant_args.scale = raw_scale;
                    quant_args.zero_point = raw_offset;
                } else {
                    // This case currently will not occur
                    // still there for legacy, but could be removed I guess

                    //T offset = convert_data<float, T>(raw_offset);
                    //T inv_scale = convert_data<float, T>(1/raw_scale);
                    
                    //Quant<T, ACC> quant(curr_dimensions, inv_scale, offset);
                    //layers.push_back(make_unique<Quant<T, ACC>>(quant));

                    //cout << "Quant(" << inv_scale << ", " << offset << ")";
                }

            } else if (curr_node.op_type() == "Relu") {
                throw ParsingException("Relu occurred in the wrong location!");    
            } else if (curr_node.op_type() == "Add") {
                throw ParsingException("Add occurred in the wrong location!");
            } else if (curr_node.op_type() == "Softmax") {
                throw ParsingException("Softmax occurred in the wrong location!");
            } else {
                throw ParsingException("Invalid op type");
            }
            
            cout << " --> ";
            print_dimensions(curr_dimensions);
            cout << endl;

            auto next = get_next_node(curr_node, graph);
            if (!next.has_value()) {
                break;
            }

            prev_node = curr_node;
            curr_node = next.value();
        }


        return layers;
    }
}

template<typename T, typename ACC>
vector<unique_ptr<Layer<T, ACC>>> parse_quantized(const string &filename, unsigned int batching, QuantArguments& args) {
    fstream file;
    file.open(filename, fstream::in | fstream::binary);

    cout << "Parsing \"" << filename << "\"..." << endl;

    // parse model
    onnx::ModelProto model;
    if(!model.ParseFromIstream(&file))
        throw ParsingException("Parsing failed!");
    
    cout << "Loaded quantized model!\n";

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

    return initialize_quant_layers<T, ACC>(model, batching, args);
}
