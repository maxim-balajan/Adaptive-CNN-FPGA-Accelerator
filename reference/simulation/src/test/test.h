#pragma once

#include "../data/matrix.h"
void print_matrix3d(Matrix<float> m);

void print_matrix2d(Matrix<float> m);

Matrix<float> create_Input_Matrix1();
Matrix<float> create_Input_Matrix3();

int convolution_test();

int maxpolling_test();

int dense_test();