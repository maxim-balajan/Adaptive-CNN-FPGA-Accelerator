#include <cassert>
#include <cstdint>
#include <iostream>
#include <chrono>
#include <stdexcept>
#include <vector>
#include <argparse.hpp>

#include <simulation.h>
#include <onnx_parser.h>
#include <npy_parser.h>
#include <vector>

using namespace std;
using namespace ParsingUtil;

#define COMMA ,

// https://stackoverflow.com/a/1055563
template<typename T>
struct TypeInfo;

#define REGISTER_PARSE_TYPE(X, HANDLE_DIV_ZERO, CLIPPING_ENABLED) template<> struct TypeInfo<X> { \
        static const char* name; \
        static bool handle_div_zero; \
        static bool clipping_enabled; \
    }; \
    const char* TypeInfo<X>::name = #X; \
    bool TypeInfo<X>::handle_div_zero = HANDLE_DIV_ZERO; \
    bool TypeInfo<X>::clipping_enabled = CLIPPING_ENABLED

REGISTER_PARSE_TYPE(SafeDivInt<int8_t COMMA false>, false, false);
REGISTER_PARSE_TYPE(SafeDivInt<int16_t COMMA false>, false, false);
REGISTER_PARSE_TYPE(Int24<false>, false, false);
REGISTER_PARSE_TYPE(SafeDivInt<int32_t COMMA false>, false, false);

REGISTER_PARSE_TYPE(SafeDivInt<int8_t COMMA true>, true, false);
REGISTER_PARSE_TYPE(SafeDivInt<int16_t COMMA true>, true, false);
REGISTER_PARSE_TYPE(Int24<true>, true, false);
REGISTER_PARSE_TYPE(SafeDivInt<int32_t COMMA true>, true, false);

REGISTER_PARSE_TYPE(FPInt8<0>, true, true);
REGISTER_PARSE_TYPE(FPInt16<0>, true, true);
REGISTER_PARSE_TYPE(FPInt24<0>, true, true);
REGISTER_PARSE_TYPE(FPInt32<0>, true, true);

template<typename T, typename ACC>
const Matrix<T>& inference(const vector<unique_ptr<Layer<T, ACC>>>& layers, const Matrix<T>& input) {
    const Matrix<T> *curr_input = &input;
    for (auto& layer : layers) {
        //std::cout << layer.get()->name() << "\n";
        curr_input = &layer.get()->calc(*curr_input);
        // std::cout << *curr_input << endl; 
    }

    return *curr_input;
}

struct InferenceStats {
    unsigned long latency_us;
    unsigned int correct;
};

template<typename T, typename ACC>
InferenceStats test_inference(const vector<unique_ptr<Layer<T, ACC>>>& layers, const Matrix<T>& input, const Matrix<T>& excepted_output, bool verbose) {

    chrono::steady_clock::time_point begin = chrono::steady_clock::now();

    const Matrix<T>& output = inference(layers, input);

    chrono::steady_clock::time_point end = chrono::steady_clock::now();

    InferenceStats stats;
    stats.latency_us = chrono::duration_cast<chrono::microseconds>(end - begin).count();
    stats.correct = 0;

    if (verbose) {
        cout << "Expected output " << excepted_output << "\n";
        cout << "Real output " << output << endl;
    }

    for (size_t i = 0; i < output.shape()[0]; i++) {
        bool matched = true;
        for (size_t j = 0; j < output.shape()[1]; j++) {
            if (output[{i,j}] != excepted_output[{i,j}]) {
                matched = false;
                break;
            }
        }

        if (matched) {
            stats.correct++;
        }
    }

    return stats;    
}

struct RunBenchmarkOptions {
    bool verbose;
    int image_count;
    int batching;
};

struct DataTypeTestResult {
    const char* data_type;
    const char* accumulator_type;
    bool data_type_handle_div_zero;
    bool data_type_clipping_enabled;
    bool accumulator_type_handle_div_zero;
    bool accumulator_type_clipping_enabled;
    double value;
    bool division_by_zero;
};

template<typename TargetType, typename AccumulatorType>
DataTypeTestResult run_benchmark(RunBenchmarkOptions options) {
    try {
        auto & [ verbose, image_count, batching ] = options;

        cout << "Loading data..." << endl;

        QuantArguments quant_args {
            -1, // scale
            -1  // zero_point
        };
        auto layers = parse_quantized<TargetType, AccumulatorType>("../../training/Lenet_qonnx.onnx", batching, quant_args);
        assert(quant_args.scale != -1);
        assert(quant_args.zero_point != -1);

        Matrix<TargetType> input_data = parse_quantized_matrix<float, TargetType>("../../training/export/mnist/x_test.npy", quant_args.scale, quant_args.zero_point);
        Matrix<TargetType> output_data = parse_matrix<float, TargetType>("../../training/export/mnist/y_test.npy");

        assert(input_data.shape()[0] == output_data.shape()[0]);
        if (image_count == -1) {
            image_count = input_data.shape()[0];
        } else {
            if (image_count > input_data.shape()[0]) {
                cerr << "Image count too big!" << endl;
                assert(false);
            }
        }

        if (batching > image_count) {
            cerr << "Batching > image count!" << endl;
            assert(false);
        }

        if (image_count % batching != 0) {
            cerr << "Image count % batching != 0!" << endl;
            assert(false);
        }

        MatrixView<TargetType> input_data_view(input_data, batching);
        MatrixView<TargetType> output_data_view(output_data, batching);
        cout << input_data.shape()[0] <<","<< input_data.shape()[1] <<","<< input_data.shape()[2] << endl;
        cout << "Starting RADL MNIST Simulation with " << image_count << " images to process (batch_size=" << batching << ")..." << endl;

        InferenceStats total_stats {
            .latency_us = 0,
            .correct = 0
        };
        // Print doubles with two subdigits
        std::cout << std::setprecision(2) << std::fixed;

        int i = 0;
        do {
            InferenceStats stats = test_inference<TargetType, AccumulatorType>(layers, input_data_view.get_current(), output_data_view.get_current(), verbose);
            total_stats.latency_us += stats.latency_us;
            total_stats.correct += stats.correct;

            i++;
            if (!options.verbose) {
                cout << "\r";
            }

            cout << "[" << (((double) (i * batching * 100)) / image_count) << "%] Inference of " << batching << " image";
            if (batching > 1) {
                cout << "s";
            }
            cout << " completed in " << stats.latency_us << "us!";

            cout << " (current accuracy: " << ((100 * ((double) total_stats.correct))/(i * batching)) << "%)";

            if (options.verbose) {
                cout << endl;
            } else {
                cout << flush;
            }
        

            if (i * batching >= image_count) {
                break;
            }
        } while(input_data_view.next() && output_data_view.next());

        cout << endl << "Inference finished!\n";
        cout << "\n";
        cout << "--- Result ---\n";
        cout << "Data-Type: " << TypeInfo<TargetType>::name << endl;
        cout << "Accumulator-Type: " << TypeInfo<AccumulatorType>::name << endl;
        cout << "Total inference duration: " << ((1.0*total_stats.latency_us)/(1000 * 1000)) << "s\n";
        cout << "Avg inference duration: " << ((1.0*total_stats.latency_us)/image_count) << "us\n";
        cout << "Total misses: " << image_count - total_stats.correct << " of " << image_count << " images" << endl;
        cout << "Avg accuracy: " << ((100 * ((double) total_stats.correct))/image_count) << "%" << endl;

        DataTypeTestResult res;
        res.division_by_zero = false;
        res.data_type = TypeInfo<TargetType>::name;
        res.accumulator_type = TypeInfo<AccumulatorType>::name;
        res.data_type_handle_div_zero = TypeInfo<TargetType>::handle_div_zero;
        res.data_type_clipping_enabled = TypeInfo<TargetType>::clipping_enabled;
        res.accumulator_type_handle_div_zero = TypeInfo<AccumulatorType>::handle_div_zero;
        res.accumulator_type_clipping_enabled = TypeInfo<AccumulatorType>::clipping_enabled;
        res.value = ((100 * ((double) total_stats.correct))/image_count);

        return res;
    } catch(overflow_error e) {
        DataTypeTestResult res;
        res.division_by_zero = true;
        res.data_type = TypeInfo<TargetType>::name;
        res.accumulator_type = TypeInfo<AccumulatorType>::name;
        res.data_type_handle_div_zero = TypeInfo<TargetType>::handle_div_zero;
        res.data_type_clipping_enabled = TypeInfo<TargetType>::clipping_enabled;
        res.accumulator_type_handle_div_zero = TypeInfo<AccumulatorType>::handle_div_zero;
        res.accumulator_type_clipping_enabled = TypeInfo<AccumulatorType>::clipping_enabled;

        res.value = 0;

        return res;
    }
}

void print_help() {
    cout << "\n";
    cout << "Usage: benchmark_datatypes [image count] [batching]" << endl;
}


int main(int argc, char* argv[]) {
    argparse::ArgumentParser parser("LeNet-5 Datatype Benchmark");
    parser.add_argument("-b", "--batching")
        .default_value(1)
        .help("batch size")
        .scan<'i', int>();

    parser.add_argument("-i", "--image-count")
        .default_value(-1)
        .help("amount of images to process")
        .scan<'i', int>();

    parser.add_argument("--verbose")
        .help("increase output verbosity")
        .default_value(false)
        .implicit_value(true);

    try {
        parser.parse_args(argc, argv);
    }
    catch (const std::exception& err) {
        std::cerr << err.what() << std::endl;
        std::cerr << parser;
        return 1;
    }

  
    RunBenchmarkOptions options = {
        .verbose = parser.get<bool>("verbose"),
        .image_count = parser.get<int>("image-count"),
        .batching = parser.get<int>("batching")
    };

    if (argc == 2 && strcmp(argv[1], "--help") == 0) {
        print_help();
        return 0;
    }

    vector<DataTypeTestResult> results;

    // ---- PART 1: DO NOT HANDLE DIVISIONS BY ZERO ----
    results.push_back(run_benchmark<SafeDivInt<int8_t, false>, SafeDivInt<int8_t, false>>(options));
    results.push_back(run_benchmark<SafeDivInt<int8_t, false>, SafeDivInt<int16_t, false>>(options));
    results.push_back(run_benchmark<SafeDivInt<int8_t, false>, Int24<false>>(options));
    results.push_back(run_benchmark<SafeDivInt<int8_t, false>, SafeDivInt<int32_t, false>>(options));

    results.push_back(run_benchmark<SafeDivInt<int16_t, false>, SafeDivInt<int16_t, false>>(options));
    results.push_back(run_benchmark<SafeDivInt<int16_t, false>, Int24<false>>(options));
    results.push_back(run_benchmark<SafeDivInt<int16_t, false>, SafeDivInt<int32_t, false>>(options));

    results.push_back(run_benchmark<Int24<false>, Int24<false>>(options));
    results.push_back(run_benchmark<Int24<false>, SafeDivInt<int32_t, false>>(options));

    results.push_back(run_benchmark<SafeDivInt<int32_t, false>, SafeDivInt<int32_t, false>>(options));

    // ---- PART 2: DO HANDLE DIVISIONS BY ZERO ----
    results.push_back(run_benchmark<SafeDivInt<int8_t, true>, SafeDivInt<int8_t, true>>(options));
    results.push_back(run_benchmark<SafeDivInt<int8_t, true>, SafeDivInt<int16_t, true>>(options));
    results.push_back(run_benchmark<SafeDivInt<int8_t, true>, Int24<true>>(options));
    results.push_back(run_benchmark<SafeDivInt<int8_t, true>, SafeDivInt<int32_t, true>>(options));

    results.push_back(run_benchmark<SafeDivInt<int16_t, true>, SafeDivInt<int16_t, true>>(options));
    results.push_back(run_benchmark<SafeDivInt<int16_t, true>, Int24<true>>(options));
    results.push_back(run_benchmark<SafeDivInt<int16_t, true>, SafeDivInt<int32_t, true>>(options));

    results.push_back(run_benchmark<Int24<true>, Int24<true>>(options));
    results.push_back(run_benchmark<Int24<true>, SafeDivInt<int32_t, true>>(options));

    results.push_back(run_benchmark<SafeDivInt<int32_t, true>, SafeDivInt<int32_t, true>>(options));

    // ---- PART 3: CLIPPING ----
    results.push_back(run_benchmark<FPInt8<0>, FPInt8<0>>(options));
    results.push_back(run_benchmark<FPInt8<0>, FPInt16<0>>(options));
    results.push_back(run_benchmark<FPInt8<0>, FPInt32<0>>(options));
    results.push_back(run_benchmark<FPInt8<0>, FPInt32<0>>(options));

    results.push_back(run_benchmark<FPInt16<0>, FPInt16<0>>(options));
    results.push_back(run_benchmark<FPInt16<0>, FPInt32<0>>(options));
    results.push_back(run_benchmark<FPInt16<0>, FPInt32<0>>(options));

    results.push_back(run_benchmark<FPInt32<0>, FPInt32<0>>(options));
    results.push_back(run_benchmark<FPInt32<0>, FPInt32<0>>(options));

    results.push_back(run_benchmark<FPInt32<0>, FPInt32<0>>(options));

    cout << "\nFinished Benchmark!\n\n--- Result ---\n";
    cout << "data_type;accumulator_type;data_type_handle_div_zero;data_type_clipping_enabled;accumulator_type_handle_div_zero;accumulator_type_clipping_enabled;value;division_by_zero\n";
    for (auto& result : results) {
        cout << result.data_type << ";";
        cout << result.accumulator_type << ";";
        cout << result.data_type_handle_div_zero << ";";
        cout << result.data_type_clipping_enabled << ";";
        cout << result.accumulator_type_handle_div_zero << ";";
        cout << result.accumulator_type_clipping_enabled << ";";
        cout << result.value << ";";
        cout << result.division_by_zero << "\n";
    }

    cout << flush;

    return 0;
}

