#include <iostream>
#include <chrono>
#include <argparse.hpp>

#include "layers/max_pooling.h"
#include "layers/flatten.h"
#include "layers/convolution.h"
#include "layers/dense.h"

#include "parsing/parser.h"
#include "parsing/npy_parser.h"
#include "test/test.h"
#include "util.h"

#include "data/matrix_view.h"

using namespace std;


template<typename T>
const Matrix<T>& inference(const vector<unique_ptr<Layer<T>>>& layers, const Matrix<T>& input) {
    const Matrix<T> *curr_input = &input;
    for (auto& layer : layers) {
        curr_input = &layer.get()->calc(*curr_input);
    }

    return *curr_input;
}

struct InferenceStats {
    unsigned long latency_ms;
    unsigned int correct;
};

template<typename T>
InferenceStats test_inference(const vector<unique_ptr<Layer<T>>>& layers, const Matrix<T>& input, const Matrix<T>& excepted_output, bool verbose) {
    chrono::steady_clock::time_point begin = chrono::steady_clock::now();

    const Matrix<T>& output = inference(layers, input);

    chrono::steady_clock::time_point end = chrono::steady_clock::now();

    InferenceStats stats;
    stats.latency_ms = chrono::duration_cast<chrono::milliseconds>(end - begin).count();
    stats.correct = 0;

    if (verbose) {
        cout << "Expected output " << excepted_output << "\n";
        cout << "Real output " << output << "\n";
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

int run_benchmark(RunBenchmarkOptions options) {
    auto & [ verbose, image_count, batching ] = options;

    cout << "Loading data..." << endl;
    vector<unique_ptr<Layer<float>>> layers = parse<float>("../../training/export/original_model.onnx", batching);
    Matrix<float> input_data = parse_matrix<double, float>("../../training/export/mnist/x_test.npy");
    Matrix<float> output_data = parse_matrix<double, float>("../../training/export/mnist/y_test.npy");

    assert(input_data.shape()[0] == output_data.shape()[0]);
    if (image_count == -1) {
        image_count = input_data.shape()[0];
    } else {
        if (image_count > input_data.shape()[0]) {
            cerr << "Image count too big!" << endl;
            return 1;
        }
    }

    if (batching > image_count) {
        cerr << "Batching > image count!" << endl;
        return 1;
    }

    if (image_count % batching != 0) {
        cerr << "Image count % batching != 0!" << endl;
        return 1;
    }

    MatrixView<float> input_data_view(input_data, batching);
    MatrixView<float> output_data_view(output_data, batching);

    cout << "Starting RADL MINST Simulation with " << image_count << " images to process (batch_size=" << batching << ")..." << endl;

    InferenceStats total_stats {
        .latency_ms = 0,
        .correct = 0
    };

    int i = 0;
    do {
        InferenceStats stats = test_inference<float>(layers, input_data_view.get_current(), output_data_view.get_current(), verbose);
        total_stats.latency_ms += stats.latency_ms;
        total_stats.correct += stats.correct;

        i++;
        cout << "[" << ((i * batching * 100) / image_count) << "%] Inference of " << batching << " image";
        if (batching > 1) {
            cout << "s";
        }
        cout << " completed in " << stats.latency_ms << "ms!";

        cout << " (current accuracy: " << ((100 * total_stats.correct)/(i * batching)) << "%)" << endl;
    

        if (i * batching >= image_count) {
            break;
        }
    } while(input_data_view.next() && output_data_view.next());

    cout << "Inference finished!\n";
    cout << "\n";
    cout << "--- Result ---\n";
    cout << "Total inference duration: " << ((1.0*total_stats.latency_ms)/1000) << "s\n";
    cout << "Avg inference duration: " << ((1.0*total_stats.latency_ms)/image_count) << "ms\n";
    cout << "Avg accuracy: " << ((100 * total_stats.correct)/image_count) << "%" << endl;
    
    return 0;
}

void print_help() {
    cout << "\n";
    cout << "Usage: simulation [image count] [batching]" << endl;
}

int main(int argc, char* argv[]) {
    argparse::ArgumentParser parser("LeNet-5 Simulator");
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
    cout << "y" << endl;

    if (argc == 2 && strcmp(argv[1], "--help") == 0) {
        print_help();
        return 0;
    }

    run_benchmark(options);

    return 0;
}
