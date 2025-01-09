#pragma once
#include <string>
#include <exception>
#include <onnx.pb.h>

namespace ParsingUtil {
    using namespace std;

    class ParsingException : public exception {
        
        private:
            const char* what_val;
        public:
            ParsingException() : what_val("Something went wrong while parsing npy data...") {};
            ParsingException(const char* what): what_val(what) {};
            ParsingException(const string what): what_val(what.c_str()) {};

            virtual const char* what() const noexcept override {
                return what_val;
            }
    };

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
    T parse_scalar(const onnx::TensorProto& tensor) {
        if (tensor.data_location() != onnx::TensorProto::DEFAULT) {
            throw ParsingException("External storage of data is not supported!");
        }

        if (tensor.float_data().size() != 0) {
            if (tensor.data_type() != onnx::TensorProto::FLOAT) {
                throw ParsingException("Float data but data type is not float?!");
            }

            // cool, data is already stored as floats
            float f = tensor.float_data()[0];
            return convert_data<float, T>(f);

        } else if (tensor.int64_data().size() != 0) {
            if (tensor.data_type() != onnx::TensorProto::INT64) {
                throw ParsingException("Int64 data but data type is not int64?!");
            }

            // cool, data is already stored as ints
            int64_t i = tensor.int64_data()[0];
            return convert_data<int64_t, T>(i);
        } else if (tensor.raw_data().size() != 0) {
            // data is stored in as binary data, convert it now
            if (tensor.data_type() == onnx::TensorProto::FLOAT) {
                const char *ptr = &(tensor.raw_data()[0]);
                const float *float_ptr = reinterpret_cast<const float*>(ptr);

                return convert_data<float, T>(*float_ptr);
            } else if (tensor.data_type() == onnx::TensorProto::INT64) {
                int8_t bytes[8];
                for (int j = 0; j < 8; j++) {
                    bytes[j] = tensor.raw_data()[j];
                }

                int64_t *data = reinterpret_cast<int64_t*>(&bytes);
                return convert_data<int64_t, T>(*data);
            }
        } else {
            throw ParsingException("Matrix data not found!");
        }

        throw ParsingException("Could not parse scalar");
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

    onnx::NodeProto find_node(const onnx::GraphProto& graph, const string& node_name) {
        for (auto& node : graph.node()) {
            if (node.name() == node_name) {
                return node;
            }
        }

        throw new ParsingException("Could not find node!");
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

    template<typename T>
    T find_scalar(const google::protobuf::RepeatedPtrField<onnx::TensorProto>& tensors, const string& name) {
        for (const auto& tensor : tensors) {
            if (tensor.name() == name) {
                return parse_scalar<T>(tensor);
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
}
