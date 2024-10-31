#pragma once

#include <vector>
#include <ranges>
#include "assert.h"

#include <iostream>

#define FORMAT_MATRIX_WITH_LINE_BREAK 1


using namespace std;

template<typename T>
class GenericMatrix {
private:
    // list of dimension sizes
    vector<size_t> dimensions;

    // 1D matrix data
    vector<T> matrix_data;

public:
    GenericMatrix(initializer_list<size_t> dimensions);
    GenericMatrix(vector<size_t> dimensions);
    GenericMatrix(initializer_list<size_t> dimensions, vector<T> initial_vals);

    inline const vector<size_t>& shape() const;
    inline constexpr size_t total_size() const;
    inline void flatten();
    inline void set_data(const vector<T>& content);
    inline void reinterpret_dimensions(const vector<size_t>& dimensions);

    inline constexpr T& operator[](size_t abs_position) {
        assertm(abs_position < total_size(), "Dimensions do not match!");

        return matrix_data[abs_position];
    }
    inline constexpr const T& operator[](size_t abs_position) const {
        assertm(abs_position < total_size(), "Dimensions do not match!");

        return matrix_data[abs_position];
    }

    inline constexpr T& operator[](initializer_list<size_t> positions) {
        assertm(dimensions.size() == positions.size(), "Dimensions do not match!");

        // TODO: could be optimized by pre calculating the multipliers
        // calculate the postion of the matrix element
        size_t curr_position = 0;
        size_t curr_multiplier = 1;
        for (const auto [index, dimension_size] : views::reverse(views::zip(positions, dimensions))) {
            assertm(index < dimension_size, "position out of bounds");

            curr_position += index * curr_multiplier;
            curr_multiplier *= dimension_size;
        }
        return matrix_data[curr_position];
    }

    // add each cell value of `other` to this matrix
    inline constexpr GenericMatrix& operator+=(const GenericMatrix& other) {
        assertm(this->dimensions == other.dimensions, "the dimensions of the two matrixes have to match");

        for (auto [curr, add] : views::zip(this->matrix_data, other.matrix_data)) {
            curr += add;
        }

        return *this;
    }

    // multiple each cell value of `other` with each corresponding cell this matrix
    inline constexpr GenericMatrix& operator*=(const GenericMatrix& other) {
        assertm(this->dimensions == other.dimensions, "the dimensions of the two matrixes have to match");

        for (auto [curr, add] : views::zip(this->matrix_data, other.matrix_data)) {
            curr *= add;
        }

        return *this;
    }

    // multiple each cell value of `other` with each corresponding cell this matrix
    inline constexpr GenericMatrix& operator=(const GenericMatrix& other) {
        assertm(this->dimensions == other.dimensions, "the dimensions of the two matrixes have to match");

        for (auto [curr, add] : views::zip(this->matrix_data, other.matrix_data)) {
            curr = add;
        }

        return *this;
    }
};

#include "matrix.tpp"

using Matrix = GenericMatrix<float>;

