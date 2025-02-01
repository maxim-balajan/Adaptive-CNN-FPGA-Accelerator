#include <iostream>
#include <chrono>

#include <simulation.h>
#include <onnx_parser.h>
#include <npy_parser.h>

using namespace std;

void print_help() {
    cout << "Usage: npy_converter [onnx file] [npy file] [output file]" << endl;
}

int main(int argc, char* argv[]) {
    if (argc != 4) {
        print_help();
        return -1;
    }
    using TargetType = FPInt8<0>;
    using AccumulatorType = FPInt24<0>;

    cout << "Loading data..." << endl;

    QuantArguments quant_args {
        -1, // scale
        -1  // zero_point
    };
    auto layers = parse_quantized<TargetType, AccumulatorType>(argv[1], 1, quant_args);
    assert(quant_args.scale != -1);
    assert(quant_args.zero_point != -1);

    ofstream file(argv[3], std::ofstream::trunc | std::ofstream::binary);
    Matrix<TargetType> matrix = parse_quantized_matrix<float, TargetType>(argv[2], quant_args.scale, quant_args.zero_point);
    cout << "shape: ";
    print_vector(matrix.shape());
    for (int i = 0; i < matrix.total_size(); i++) {
        TargetType val = matrix[i];
        // printf("%02x ", (static_cast<int32_t>(val.get_real_val()) & 0xff));
        file << val.get_real_val();
    }

    file.flush();
    file.close();


    return 0;
}
