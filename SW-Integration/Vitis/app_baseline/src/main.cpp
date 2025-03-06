#include <initializer_list>
#include <stdio.h>
#include <simulation.h>
#include <npy_parser.h>
#include <iostream>
#include <assert.h>
#include <sys/types.h>
#include <xiltimer.h>
#include "symbols.h"
#include <chrono>
#include <memory>
#include <vector>

using namespace std;


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

template<typename T, typename ACC>
void run(int index, vector<unique_ptr<Layer<T, ACC>>>& layers, Matrix<T>& input, Matrix<T>& output) {
    cout << "Running for index: " << index << endl;

    for (int offset = 0; offset < 32*32; offset++) {
        input[offset] = convert_data<int64_t, T>(static_cast<int64_t>(X_START[index * 32*32 + offset]));
    }
    for (int offset = 0; offset < 10; offset++) {
        output[offset] = convert_data<int64_t, T>(static_cast<int64_t>(Y_START[index * 10 + offset]));
    }
    auto stats = test_inference<T, ACC>(layers, input, output, true);

    cout << "time: " << stats.latency_us << endl;
    cout << "correct: " << stats.correct << endl;
}

int main() {
    using TargetType = FPInt8<0>;
    using AccumulatorType = FPInt24<0>;
    span data(LENET_LAYERS_START, LENET_LAYERS_SIZE);
    vector<unique_ptr<Layer<TargetType, AccumulatorType>>> layers = deserialize_layers<TargetType, AccumulatorType>(data);


    Matrix<TargetType> input({1, 32, 32});
    Matrix<TargetType> output({1, 10});
    for (int i = 0; i < 10; i++) {
        run<TargetType, AccumulatorType>(i, layers, input, output);
    }
    return 0;
}
