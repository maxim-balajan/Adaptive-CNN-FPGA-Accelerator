#include <initializer_list>
#include <stdio.h>
#include "symbols.h"
#include <simulation.h>
#include <npy_parser.h>
#include <iostream>
#include <assert.h>
#include <sys/types.h>
#include <xiltimer.h>
#include "acc_interface.h"

u8 get_y_num(int offset) {
    for (int i = 0; i < 10; i++) {
        if (Y_START[offset*10 + i] != 0) {
            return i;
        }
    }
    
    return 255;
}

struct InferenceStats {
    unsigned long long latency_ns;
    unsigned int correct;
};

InferenceStats run(int offset, bool verbose) {
    auto res = AccInterface::instance.run(reinterpret_cast<u8*>(&X_START[offset * 32*32]), 32*32);

    if (verbose) {
        cout << "error: " << res.error << endl;
        cout << "time: " << res.time_ns << endl;
        cout << "result: " << static_cast<int>(res.result) << endl;
        cout << "expected: " << static_cast<int>(get_y_num(offset)) << endl << endl;        
    }

    InferenceStats stats;
    stats.latency_ns = res.time_ns;
    stats.correct = (static_cast<int>(res.result) == static_cast<int>(get_y_num(offset))) ? 1 : 0;    
    return stats;
}

int main() {
    int inference_num = 10000;
    InferenceStats total_stats;
    total_stats.latency_ns = 0;
    total_stats.correct = 0;

    for (int i = 0; i < inference_num; i++) {
        auto stats = run(i, false);

        total_stats.correct += stats.correct;
        total_stats.latency_ns += stats.latency_ns;
        cout << "[" << ((i * 100) / inference_num) << "%] Inference of " << 1 << " image";
        cout << " completed in " << stats.latency_ns << "ns!";
        cout << " (current accuracy: " << (100 * total_stats.correct)/(i+1) << "%)" << endl;

        cout << "[BENCH-INFO] " << stats.latency_ns << endl;
    }

    cout << "\n" << "Inference finished!\n";
    cout << "\n";
    cout << "--- Result ---\n";
    cout << "Total inference duration: " << ((1.0*total_stats.latency_ns)/(1000 * 1000 * 1000)) << "s\n";
    cout << "Avg inference duration: " << ((1.0*total_stats.latency_ns)/inference_num) << "ns\n";
    cout << "Total misses: " << inference_num - total_stats.correct << " of " << inference_num << " images" << endl;
    cout << "Avg accuracy: " << (static_cast<float>(100 * total_stats.correct)/static_cast<float>(inference_num)) << "%" << endl;


    cout << "[BENCH-STATUS] Finished" << endl;

    return 0;
}
