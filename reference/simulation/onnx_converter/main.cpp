#include <iostream>
#include <chrono>

#include <simulation.h>
#include <onnx_parser.h>
#include <npy_parser.h>

using namespace std;

void print_help() {
    cout << "Usage: onnx_converter [onnx file] [output file]" << endl;
}

int main(int argc, char* argv[]) {
    if (argc != 3) {
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


    ofstream file(argv[2], std::ofstream::trunc | std::ofstream::binary);
    
    serialize_layers(layers, file);

    file.flush();
    file.close();

    return 0;
}
