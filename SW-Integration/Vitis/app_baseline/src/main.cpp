#include <initializer_list>
#include <stdio.h>
#include <simulation.h>
#include <npy_parser.h>
#include <iostream>
#include <assert.h>
#include <sys/_intsup.h>
#include <sys/types.h>
#include "symbols.h"
#include <memory>
#include <vector>

extern "C" {
#include "xiltimer.h"
}

using namespace std;


template<typename T, typename ACC>
const Matrix<T>& inference(const vector<unique_ptr<Layer<T, ACC>>>& layers, const Matrix<T>& input) {
    const Matrix<T> *curr_input = &input;
    for (auto& layer : layers) {
        // std::cout << layer.get()->name() << " with input data: " << curr_input->calc_hash(0, curr_input->total_size()) << std::endl;
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
    XTime start;
    XTime_GetTime(&start);

    const Matrix<T>& output = inference(layers, input);

    XTime end;
    XTime_GetTime(&end);

    u64 time_us = ((end - start) * 1000 * 1000) / (COUNTS_PER_SECOND);

    InferenceStats stats;
    stats.latency_us = time_us;
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

template<typename T, typename ACC>
InferenceStats run(int index, vector<unique_ptr<Layer<T, ACC>>>& layers, Matrix<T>& input, Matrix<T>& output) {
    for (int offset = 0; offset < 32*32; offset++) {
        const signed char* ptr = reinterpret_cast<const signed char*>(&X_START[index * 32*32 + offset]);
        input[offset] = convert_data<int64_t, T>(static_cast<int64_t>(*ptr));
    }
    for (int offset = 0; offset < 10; offset++) {
        const signed char* ptr = reinterpret_cast<const signed char*>(&Y_START[index * 10 + offset]);
        output[offset] = convert_data<int64_t, T>(static_cast<int64_t>((*ptr) == 64 ? 1 : 0));
    }
    auto stats = test_inference<T, ACC>(layers, input, output, false);

    return stats;
}

int main() {
    int inference_num = 10000;

    using TargetType = FPInt8<0>;
    using AccumulatorType = FPInt24<0>;
    span data(LENET_LAYERS_START, LENET_LAYERS_SIZE);
    vector<unique_ptr<Layer<TargetType, AccumulatorType>>> layers = deserialize_layers<TargetType, AccumulatorType>(data);

    InferenceStats total_stats;
    total_stats.latency_us = 0;
    total_stats.correct = 0;

    Matrix<TargetType> input({1, 1, 32, 32});
    Matrix<TargetType> output({1, 10});
    for (int i = 0; i < inference_num; i++) {
        InferenceStats stats = run<TargetType, AccumulatorType>(i, layers, input, output);
        total_stats.latency_us += stats.latency_us;
        total_stats.correct += stats.correct;
        cout << "[" << (((double) (i * 1 * 100)) / inference_num) << "%] Inference of " << 1 << " image";
        cout << " completed in " << stats.latency_us << "us!";
        cout << " (current accuracy: " << ((100 * ((double) total_stats.correct))/i) << "%)\n";

        cout << "[BENCH-INFO] " << stats.latency_us << "\n";
        
    }

    cout << "\n" << "Inference finished!\n";
    cout << "\n";
    cout << "--- Result ---\n";
    // cout << "Accumulator-Type: FPInt24<0>" << endl;
    cout << "Total inference duration: " << ((1.0*total_stats.latency_us)/(1000 * 1000)) << "s\n";
    cout << "Avg inference duration: " << ((1.0*total_stats.latency_us)/inference_num) << "us\n";
    cout << "Total misses: " << inference_num - total_stats.correct << " of " << inference_num << " images" << endl;
    cout << "Avg accuracy: " << ((100 * ((double) total_stats.correct))/inference_num) << "%" << endl;
    
    cout << "[BENCH-STATUS] Finished" << endl;

    return 0;
}
