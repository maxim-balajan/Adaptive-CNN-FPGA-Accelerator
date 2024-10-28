#include <iostream>


#include "layers/max_polling.h"
#include "layers/flatten.h"


using namespace std;

int main() {
    std::cout << "Starting RADL MINST Simulation..." << std::endl;

    Flatten flatten((size_t) 2, (size_t) 20);
    matrix_4d test = init_matrix_4d(2, 2, 5, 2);
    int i = 0;
    for (auto &a: test) {
        for (auto &b: a) {
            for (auto &c: b) {
                for (auto &d: c) {
                    d = i++;
                    cout << d << " ";
                }
            }
        }
    }
    cout << endl;

    matrix_2d res = flatten.calc(test);
    for (auto &a: res) {
        for (auto &b: a) {
            cout << b << " ";
        }
    }

    cout << endl;

    return 0;
}