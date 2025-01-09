#include <iostream>

#include "layers/max_pooling.h"
#include "layers/flatten.h"
#include "layers/convolution.h"
#include "layers/dense.h"
#include "data/matrix.h"

using namespace std;

Matrix<float> create_Input_Matrix1() {
        // create input matrix
    Matrix<float> input({1,5,5,2});

    input[{0,0,0,0}] = 3;
    input[{0,1,0,0}] = 3;
    input[{0,2,0,0}] = 2;
    input[{0,3,0,0}] = 1;
    input[{0,4,0,0}] = 0;
    input[{0,0,1,0}] = 0;
    input[{0,1,1,0}] = 0;
    input[{0,2,1,0}] = 1;
    input[{0,3,1,0}] = 3;
    input[{0,4,1,0}] = 1;
    input[{0,0,2,0}] = 3;
    input[{0,1,2,0}] = 1;
    input[{0,2,2,0}] = 2;
    input[{0,3,2,0}] = 2;
    input[{0,4,2,0}] = 3;
    input[{0,0,3,0}] = 2;
    input[{0,1,3,0}] = 0;
    input[{0,2,3,0}] = 0;
    input[{0,3,3,0}] = 2;
    input[{0,4,3,0}] = 2;
    input[{0,0,4,0}] = 2;
    input[{0,1,4,0}] = 0;
    input[{0,2,4,0}] = 0;
    input[{0,3,4,0}] = 0;
    input[{0,4,4,0}] = 1;

    input[{0,0,0,1}] = 1;
    input[{0,1,0,1}] = 1;
    input[{0,2,0,1}] = 1;
    input[{0,3,0,1}] = 1;
    input[{0,4,0,1}] = 1;
    input[{0,0,1,1}] = 1;
    input[{0,1,1,1}] = 1;
    input[{0,2,1,1}] = 1;
    input[{0,3,1,1}] = 1;
    input[{0,4,1,1}] = 1;
    input[{0,0,2,1}] = 1;
    input[{0,1,2,1}] = 1;
    input[{0,2,2,1}] = 1;
    input[{0,3,2,1}] = 1;
    input[{0,4,2,1}] = 1;
    input[{0,0,3,1}] = 1;
    input[{0,1,3,1}] = 1;
    input[{0,2,3,1}] = 1;
    input[{0,3,3,1}] = 1;
    input[{0,4,3,1}] = 1;
    input[{0,0,4,1}] = 1;
    input[{0,1,4,1}] = 1;
    input[{0,2,4,1}] = 1;
    input[{0,3,4,1}] = 1;
    input[{0,4,4,1}] = 1;

    return input;
}

Matrix<float> create_Input_Matrix2() {
    Matrix<float> input({1,4,4,1});

    input[{0,0,0,0}] = 4;
    input[{0,1,0,0}] = 6;
    input[{0,2,0,0}] = 0;
    input[{0,3,0,0}] = 8;
    input[{0,0,1,0}] = 4;
    input[{0,1,1,0}] = 2;
    input[{0,2,1,0}] = 9;
    input[{0,3,1,0}] = 3;
    input[{0,0,2,0}] = 1;
    input[{0,1,2,0}] = 3;
    input[{0,2,2,0}] = 3;
    input[{0,3,2,0}] = 2;
    input[{0,0,3,0}] = 7;
    input[{0,1,3,0}] = 1;
    input[{0,2,3,0}] = 2;
    input[{0,3,3,0}] = 5;

    return input;
}

Matrix<float> create_Input_Matrix3() {
    Matrix<float> input({4, 3});
    for (size_t i = 0; i < input.shape()[1]; i++)
    {
        for (size_t j = 0; j < input.shape()[0]; j++)
        {
            input[{j,i}] = i;
        }
        
    }

    return input;   
}

int convolution_test() {
    // create input matrix
    Matrix<float> input = create_Input_Matrix1();

    // creation of kernel matrix
    Matrix<float> kernel({1,2,3,3});
    kernel[{0,0,0,0}] = 0;
    kernel[{0,0,1,0}] = 1;
    kernel[{0,0,2,0}] = 2;
    kernel[{0,0,0,1}] = 2;
    kernel[{0,0,1,1}] = 2;
    kernel[{0,0,2,1}] = 0;
    kernel[{0,0,0,2}] = 0;
    kernel[{0,0,1,2}] = 1;
    kernel[{0,0,2,2}] = 2;

    kernel[{0,1,0,0}] = 1;
    kernel[{0,1,1,0}] = 1;
    kernel[{0,1,2,0}] = 1;
    kernel[{0,1,0,1}] = 1;
    kernel[{0,1,1,1}] = 1;
    kernel[{0,1,2,1}] = 1;
    kernel[{0,1,0,2}] = 1;
    kernel[{0,1,1,2}] = 1;
    kernel[{0,1,2,2}] = 1;

    Matrix<float> bias({1});

    Convolution conv(kernel, bias, 1, 3, 3, 1);
    Matrix<float> output_buffer = conv.calc(input);

    cout << "{convolution_test}\n" << output_buffer << endl;

    return 0;           
}

int maxpolling_test() {
    Matrix<float> input = create_Input_Matrix2();

    MaxPooling<float> mpoll(2, 1, 2, 2, 1);

    cout << "{create_Input_Matrix2}\n" << mpoll.calc(input) << endl;

    return 0;
}

int dense_test() {
    Matrix<float> weight = create_Input_Matrix3();

    cout << "{Weights}\n" << weight << endl;

    Matrix<float> bias({3});

    Dense den(weight, bias, false, 1, 3);

    Matrix<float> input({1, 4});
    input[{0,0}] = 1;
    input[{0,1}] = 1;
    input[{0,2}] = 1;
    input[{0,3}] = 1;

    cout << "{Input}\n" << input << endl;

    cout << "{create_Input_Matrix3}\n" << den.calc(input) << endl;

    return 0;
}
