#include "matrix.h"

#include <iostream>
#include <ranges>
#include <initializer_list>

template<typename T>
GenericMatrix<T>::GenericMatrix(initializer_list<size_t> input_dimensions): dimensions(input_dimensions.size()) {
    assertm(input_dimensions.size() > 0, "input dimensions have to be > 0");
    
    size_t total_matrix_size = 1;
    for (const auto [index, dimension_size] : views::enumerate(input_dimensions)) {
        assertm(dimension_size != 0, "all dimensions have to be > 0");

        dimensions[index] = dimension_size;
        total_matrix_size *= dimension_size;
    }

    matrix_data.resize(total_matrix_size);
}

template<typename T>
const vector<size_t>& GenericMatrix<T>::shape() const {
    return dimensions;
}

template<typename T>
constexpr size_t GenericMatrix<T>::total_size() const {
    return matrix_data.size();
}


template<typename T>
inline void GenericMatrix<T>::flatten() {
    reinterpret_dimensions(vector<size_t>(total_size()));
}

template<typename T>
inline void GenericMatrix<T>::reinterpret_dimensions(const vector<size_t>& dimensions) {
    this->dimensions.clear();
    this->dimensions.insert(this->dimensions.end(), dimensions.begin(), dimensions.end());
}

template<typename T>
std::ostream& operator<<(std::ostream &out, GenericMatrix<T> const& data) {
    for (auto i = 0; i < data.total_size(); i++) {
        if (i != 0) {
            out << ",";
        }
        out << data[i];
    }
    return out;
}
