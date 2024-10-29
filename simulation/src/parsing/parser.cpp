#include <string>
#include <fstream>
#include <iostream>
#include <cstdint>
#include <tuple>

// include our onnx proto model
#include <onnx.pb.h>

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
}

void parse(const string &filename) {
    fstream file;
    file.open(filename, fstream::in | fstream::binary);

    cout << "Parsing \"" << filename << "\"..." << endl;

    // parse model
    onnx::ModelProto model;
    if(!model.ParseFromIstream(&file))
        throw runtime_error("Parsing failed!");
    
    cout << "Loaded model!\n";

    // print some model infos
    print_info("Producer", model.producer_name(), model.producer_version());
    for (auto x : model.opset_import()) {
        print_info("Opset Import", x.domain(), x.version());
    }
    print_info("Domain", model.domain());
    print_info("Documentation", model.doc_string());
    for (auto x : model.metadata_props()) {
        print_info("Metadata Props", x.key(), x.value());
    }
    print_info("Graph name", model.graph().name());
    print_info("Graph Documentation", model.graph().doc_string());
    for (auto x : model.graph().metadata_props()) {
        print_info("Graph Metadata Props", x.key(), x.value());
    }
    for (auto x : model.graph().input()) {
        print_value_info_proto("Graph Input", x);
    }
    for (auto x : model.graph().output()) {
        print_value_info_proto("Graph Output", x);
    }
}
