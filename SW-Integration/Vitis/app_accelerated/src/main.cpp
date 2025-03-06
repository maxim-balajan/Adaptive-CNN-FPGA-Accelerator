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

u8 get_y_num(int index) {
    for (int i = 0; i < 10; i++) {
        if (Y_START[index*10 + i] != 0) {
            return i;
        }
    }
    
    return 255;
}

struct InferenceStats {
    unsigned long long latency_ns;
    unsigned int correct;
};

InferenceStats run(int index, bool verbose) {
    auto res = AccInterface::instance.run(reinterpret_cast<u8*>(&X_START[index * 32*32]), 32*32);

    if (verbose) {
        cout << "error: " << res.error << endl;
        cout << "time: " << res.time_ns << endl;
        cout << "result: " << static_cast<int>(res.result) << endl;
        cout << "expected: " << static_cast<int>(get_y_num(index)) << endl << endl;        
    }
    cout << "[BENCH-INFO] " << res.time_ns << "\n";

    InferenceStats stats;
    stats.latency_ns = res.time_ns;
    stats.correct = (static_cast<int>(res.result) == static_cast<int>(get_y_num(index))) ? 1 : 0;

    return stats;
}

int main() {
    int inference_num = 100000;
    InferenceStats total_stats;
    total_stats.latency_ns = 0;
    total_stats.correct = 0;


    for (int i = 0; i < inference_num; i++) {
        run(i, false);
    }

    cout << "\n" << "Inference finished!\n";
    cout << "\n";
    cout << "--- Result ---\n";
    // cout << "Accumulator-Type: FPInt24<0>" << endl;
    cout << "Total inference duration: " << ((1.0*total_stats.latency_ns)/(1000 * 1000 * 1000)) << "s\n";
    cout << "Avg inference duration: " << ((1.0*total_stats.latency_ns)/inference_num) << "ns\n";
    cout << "Total misses: " << inference_num - total_stats.correct << " of " << inference_num << " images" << endl;
    cout << "Avg accuracy: " << ((100 * ((double) total_stats.correct))/inference_num) << "%" << endl;


    cout << "[BENCH-STATUS] Finished" << endl;

    return 0;
}
