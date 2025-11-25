#include <stdio.h>
#include <assert.h>
#include <iostream>
#include <iomanip>
#include <sys/_intsup.h>
#include <sys/types.h>
#include <xiltimer.h>
#include <cmath>
#include "mem_interface.h"

using namespace std;

unsigned run(bool verbose) {
    auto res = MemInterface::instance.run();

    if (verbose) {
        cout << "error: " << res.error << endl;
        //cout << "result: " << static_cast<int>(res.result) << endl;        
    }

    return res.time_ns;
}

int main() {
    
    u8 *cfg_ptr = reinterpret_cast<u8*>((0x02000000 + 0x00600000));

    // 16 bit registers
    ((u16 *)cfg_ptr)[0] = $$TBD$$;                                               // Input Image Size
    ((u16 *)cfg_ptr)[1] = $$TBD$$;                                               // Output Image Size
    ((u16 *)cfg_ptr)[2] = $$TBD$$;                                               // Input Channel Size
    ((u16 *)cfg_ptr)[3] = $$TBD$$;                                               // Output Channel Size
    ((u16 *)cfg_ptr)[4] = ((u16 *)cfg_ptr)[1] * ((u16 *)cfg_ptr)[1];             // Output Image Size Squared
    ((u16 *)cfg_ptr)[5] = $$TBD$$;                                               // Concurrent Channel Amount
    // 8 bit registers
    cfg_ptr[12] = $$TBD$$;                                                        // Kernel Size
    cfg_ptr[13] = $$TBD$$;                                                        // Padding
    cfg_ptr[14] = $$TBD$$;                                                        // Stride Bit Mask (0, 1, 3, 7, ...)
    cfg_ptr[15] = $$TBD$$;                                                        // Shamt[6:2] + ReLU[1] + Mode[0]

    int test_num = 10000;
    uint64_t total_latency = 0;

    cout << "[BENCH-NAME] " << "CONV-TBD" << endl;
    for (int i = 0; i < test_num; i++) {
        uint64_t latency = run(false);

        total_latency += latency;
        cout << "[" << ((i * 100) / test_num) << "%] Inference of " << 1 << " image";
        cout << " completed in " << latency << "ns!" << endl;

        cout << "[BENCH-INFO] " << latency << endl;
    }

    cout << endl << "Inference finished!" << endl << endl;
    cout << "--- Result ---" << endl;
    uint64_t tot_lat = static_cast<uint64_t>(total_latency) / 1e6;    
    uint64_t avg_lat = static_cast<uint64_t>(total_latency) / test_num;
    cout << "Total inference duration: " << tot_lat << "ms" << endl;
    cout << "Avg inference duration: " << avg_lat << "ns" << endl;

    cout << "[BENCH-STATUS] Finished" << endl;
    

    return 0;
}
