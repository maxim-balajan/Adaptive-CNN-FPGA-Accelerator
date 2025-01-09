
void benchmark_inference() {
    cout << "Starting RADL MNIST Simulation with " << image_count << " images to process (batch_size=" << batching << ")..." << endl;

    InferenceStats total_stats {
        .latency_ms = 0,
        .correct = 0
    };
    // Print doubles with two subdigits
    std::cout << std::setprecision(2) << std::fixed;

    int i = 0;
    do {
        InferenceStats stats = test_inference<TargetType, AccumulatorType>(layers, input_data_view.get_current(), output_data_view.get_current(), verbose);
        total_stats.latency_ms += stats.latency_ms;
        total_stats.correct += stats.correct;

        i++;
        if (!options.verbose) {
            cout << "\r";
        }

        cout << "[" << (((double) (i * batching * 100)) / image_count) << "%] Inference of " << batching << " image";
        if (batching > 1) {
            cout << "s";
        }
        cout << " completed in " << stats.latency_ms << "ms!";

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
    // cout << "Accumulator-Type: FPInt24<0>" << endl;
    cout << "Total inference duration: " << ((1.0*total_stats.latency_ms)/1000) << "s\n";
    cout << "Avg inference duration: " << ((1.0*total_stats.latency_ms)/image_count) << "ms\n";
    cout << "Total misses: " << image_count - total_stats.correct << " of " << image_count << " images" << endl;
    cout << "Avg accuracy: " << ((100 * ((double) total_stats.correct))/image_count) << "%" << endl;

}
