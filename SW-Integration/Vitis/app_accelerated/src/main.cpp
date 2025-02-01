#include <initializer_list>
#include <stdio.h>
#include "symbols.h"
#include <simulation.h>
#include <npy_parser.h>
#include <iostream>
#include <assert.h>
#include <sys/types.h>

Matrix<int8_t> parse(char* buffer, size_t size, initializer_list<size_t> dimensions) {
    Matrix<int8_t> matrix(dimensions);
    for (size_t i = 0; i < size; i++) {
        matrix[i] = *(buffer + i);
    }

    return matrix;
}

int main() {
    cout << X_SIZE << ", " << Y_SIZE << endl;
    assert(X_SIZE % (32 * 32) == 0);
//    Matrix<int8_t> input = parse(X_START, X_SIZE, {X_SIZE/(32 * 32), 32, 32});
    assert(Y_SIZE % (10) == 0);
    Matrix<int8_t> output = parse(Y_START, 10, {1, 10});

    // MatrixView<int8_t> input_data_view(input, 1);
    // cout << "first image: " << input_data_view.get_current() << endl;

    // MatrixView<int8_t> output_data_view(output, 1);
    // cout << "first output: " << output_data_view.get_current() << endl;
    for (int i = 0; i < 5; i++) {
        cout << i << ": ";
        for (int x = 0; x < 10; x++) {
            cout << static_cast<int>(Y_START[i*10 + x]) << " ";
        }
        cout << endl;
    }

    return 0;
}
