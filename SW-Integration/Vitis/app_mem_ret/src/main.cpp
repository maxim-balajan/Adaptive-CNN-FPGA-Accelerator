#include <stdio.h>
#include <assert.h>
#include <iostream>
#include <sys/_intsup.h>
#include <sys/types.h>
#include <xiltimer.h>
#include "mem_interface.h"

using namespace std;

unsigned run(char* tx_buffer_wt, char *tx_buffer_px, bool verbose) {
    auto res = MemInterface::instance.run(reinterpret_cast<u8*>(tx_buffer_wt), reinterpret_cast<u8*>(tx_buffer_px));

    if (verbose) {
        cout << "error: " << res.error << endl;
        cout << "time: " << res.time_ns << endl;
        for (int i = 0; i < 1280; i++) {
            cout << "result " << i << ": " << static_cast<u8>(*(res.result + i)) << endl;        
        }
        //cout << "result: " << static_cast<int>(res.result) << endl;        
    }

    return res.time_ns;
}

void prepare_memory(char *base_address, size_t start_value, size_t length) {
    u8 value = start_value;
    for (char *i = base_address; i < base_address + length; i++) {
        *i = value;
        value = (value + 1) & 0x7F;
    }
}

int main() {
    char* weight_mem = (char*) 0x01000000 + 0x00100000;
    prepare_memory(weight_mem, 0, sizeof(u8) * 5 * 128);
    char* pixel_mem = (char*) 0x01000000 + 0x00200000;
    prepare_memory(pixel_mem, 16, sizeof(u8) * 5 * 128);
    int test_num = 10000;
    unsigned total_latency = 0;

    for (int i = 0; i < 1; i++) {
        unsigned latency = run(weight_mem, pixel_mem, true);

        total_latency += latency;
        cout << "[" << ((i * 100) / test_num) << "%] Inference of " << 1 << " image";
        cout << " completed in " << latency << "ns!" << endl;

        cout << "[BENCH-INFO] " << latency << endl;
    }

    cout << "\n" << "Inference finished!\n";
    cout << "\n";
    cout << "--- Result ---\n";
    cout << "Total inference duration: " << ((1.0*total_latency)/(1000 * 1000 * 1000)) << "s\n";
    cout << "Avg inference duration: " << ((1.0*total_latency)/test_num) << "ns\n";

    cout << "[BENCH-STATUS] Finished" << endl;

    return 0;
}
