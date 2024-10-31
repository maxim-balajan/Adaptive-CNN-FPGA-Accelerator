#include <iostream>

#include "layers/max_polling.h"
#include "layers/flatten.h"
#include "layers/convolution.h"
#include "layers/dense.h"

#include "parsing/parser.h"
#include "test/test.h"

using namespace std;

int main() {
    std::cout << "Starting RADL MINST Simulation..." << std::endl;

    Flatten flatten((size_t) 2, (size_t) 20);
    Matrix test({2, 2, 5, 2});
    test[{0,1,0,1}] = 10;
    test[{0,1,4,1}] = 10;
    Matrix test2({2, 2, 5, 2});
    test2[{0,1,0,1}] = 4;
    test2 += test;
    cout << test[{0,1,0,1}] << " " << test2[{0,1,0,1}] << " " << test2[{0,1,4,1}] << endl;

    cout << test << endl;
    Matrix res = flatten.calc(test);
    cout << res << endl;

    vector<unique_ptr<Layer>> layers = parse("../../training/mnist.onnx", 1);

    // Convolution test
    convolution_test();
    maxpolling_test();
    dense_test();

    return 0;
}