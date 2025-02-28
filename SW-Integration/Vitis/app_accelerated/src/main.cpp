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

void run(int index) {
    cout << "Running for index: " << index << endl;

    auto res = AccInterface::instance.run(reinterpret_cast<u8*>(&X_START[index * 32*32]), 32*32);

    cout << "error: " << res.error << endl;
    cout << "time: " << res.time_ns << endl;
    cout << "result: " << static_cast<int>(res.result) << endl;
    cout << "expected: " << static_cast<int>(get_y_num(index)) << endl;
}

int main() {
    run(0);
    return 0;
}
