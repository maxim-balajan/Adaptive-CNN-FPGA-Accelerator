#include "matrix_view.h"

template<typename T>
MatrixView<T>::MatrixView(Matrix<T> original_data, size_t window_size)
    : original_data(original_data)
    , curr_index(0)
    , current_data({1}) // init later
{
    vector<size_t> shape(original_data.shape());
    if (shape[0] % window_size != 0) {
        if (shape[0] >= window_size) {
            throw new runtime_error("size is too big!");
        }

        throw new runtime_error("matrix size is not devisable by window size!");
    }

    shape[0] = window_size;
    current_data = Matrix<T>(shape);

    element_count = 1;
    for (auto& dim : shape) {
        element_count *= dim;
    }

    // load first item
    next();
}

template<typename T>
const Matrix<T>& MatrixView<T>::get_current() {
    return current_data;
}

template<typename T>
bool MatrixView<T>::next() {
    if (curr_index * current_data.shape()[0] >= original_data.shape()[0]) {
        return false;
    }
    size_t offset = curr_index * element_count;

    for (int i = 0; i < element_count; i++) {
        current_data[i] = original_data[i + offset];
    }

    curr_index++;

    return true;
}
