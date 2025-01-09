#pragma once

using namespace std;

template<typename T>
class MatrixView {
private:
    Matrix<T> original_data;
    Matrix<T> current_data;
    size_t curr_index;
    int element_count;

public:
    MatrixView(Matrix<T> original_data, size_t size);

    const Matrix<T>& get_current();
    bool next();
};

#include "matrix_view.tpp"
