#include <iostream>

#include "../layers/max_polling.h"
#include "../layers/flatten.h"
#include "../layers/convolution.h"
#include "../layers/dense.h"

using namespace std;

void print_matrix3d(Matrix m) {
    for (size_t i = 0; i < m.shape()[0]; i++)
    {
        for (size_t j = 0; j < m.shape()[3]; j++)
        {
            for (size_t k = 0; k < m.shape()[2]; k++)
            {
                for (size_t l = 0; l < m.shape()[1]; l++)
                {
                    cout << m[{i, l, k, j}] << " ";
                }

                cout << endl;
                
            }

            cout << endl << "----------------------" << endl;
            
        }
    }
    
}

void print_matrix2d(Matrix m) {
    for (size_t i = 0; i < m.shape()[0]; i++)
    {
        for (size_t j = 0; j < m.shape()[1]; j++)
        {
            cout << m[{i,j}] << " ";
        }
        
        cout << endl;
    }
    
}

Matrix create_Input_Matrix1() {
        // create input matrix
    Matrix input({1,5,5,2});

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

Matrix create_Input_Matrix2() {
    Matrix input({1,4,4,1});

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

Matrix create_Input_Matrix3() {
    Matrix input({4, 3});
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
    Matrix input = create_Input_Matrix1();

    // creation of kernel matrix
    Matrix kernel({1,2,3,3});
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

    Matrix bias({1});

    Convolution conv(kernel, bias, 1, 3, 3, 1);
    Matrix output_buffer = conv.calc(input);

    print_matrix3d(output_buffer);

    return 0;           
}

int maxpolling_test() {
    Matrix input = create_Input_Matrix2();

    MaxPolling mpoll(2, 1, 2, 2, 1);

    print_matrix3d(mpoll.calc(input));

    return 0;
}

int dense_test() {
    Matrix weight = create_Input_Matrix3();

    print_matrix2d(weight);

    Dense den(weight, 1, 3);

    Matrix input({1, 4});
    input[{0,0}] = 1;
    input[{0,1}] = 1;
    input[{0,2}] = 1;
    input[{0,3}] = 1;

    print_matrix2d(input);

    print_matrix2d(den.calc(input));


    return 0;
}
