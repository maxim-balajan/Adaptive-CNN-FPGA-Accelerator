#include "matrix.h"

#include <iostream>
#include <ranges>
#include <initializer_list>

template<typename T>
Matrix<T>::Matrix(initializer_list<size_t> input_dimensions): dimensions(input_dimensions.size()) {
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
Matrix<T>::Matrix(vector<size_t> input_dimensions): dimensions(input_dimensions.size()) {
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
Matrix<T>::Matrix(initializer_list<size_t> dimensions, vector<T> initial_vals): Matrix(dimensions) {
    set_data(initial_vals);
}

template<typename T>
const vector<size_t>& Matrix<T>::shape() const {
    return dimensions;
}

template<typename T>
inline void Matrix<T>::set_data(const vector<T>& data) {
    assertm(data.size() == total_size(), "Data has to be the same size as this matrix!");
    matrix_data = data;
}

template<typename T>
template<size_t N>
inline void Matrix<T>::set_data(const array<T, N>& data) {
    assertm(data.size() == total_size(), "Data has to be the same size as this matrix!");
    for (int i = 0; i < data.size(); i++) {
        matrix_data[i] = data[i];
    }
}

template<typename T>
constexpr size_t Matrix<T>::total_size() const {
    return matrix_data.size();
}


template<typename T>
inline void Matrix<T>::flatten() {
    reinterpret_dimensions(vector<size_t>(total_size()));
}

template<typename T>
inline void Matrix<T>::reinterpret_dimensions(const vector<size_t>& dimensions) {
    this->dimensions.clear();
    this->dimensions.insert(this->dimensions.end(), dimensions.begin(), dimensions.end());
}

template<typename T>
inline void Matrix<T>::copy_to(Matrix<T>& destination) const {
    assertm(this->dimensions == destination.dimensions, "the dimensions of the two matrixes have to match");

    for (auto [curr, dest] : views::zip(this->matrix_data, destination.matrix_data)) {
        dest = curr;
    }
}

template<typename T>
void Matrix<T>::print_hashes(size_t views) const {
    assert(this->matrix_data.size() % views == 0);
    size_t size = this->matrix_data.size() / views;

    cout << "hashes: [";
    for (int i = 0; i < views; i++) {
        if (i != 0) {
            cout << ", ";
        }
        cout << calc_hash(i * size, (i + 1) * size);
    }
    cout << "]\n";
}

template<typename T>
size_t Matrix<T>::calc_hash(size_t start, size_t end) const {
    assert(start <= end);
    assert(end <= this->matrix_data.size());

    size_t seed = end - start;
    for(int i = start; i < end; i++) {
        size_t x = (size_t) this->matrix_data[i];
        x = ((x >> 16) ^ x) * 0x45d9f3b;
        x = ((x >> 16) ^ x) * 0x45d9f3b;
        x = (x >> 16) ^ x;
        seed ^= x + 0x9e3779b9 + (seed << 6) + (seed >> 2);
    }
    return (size_t) seed;
}

template<typename T>
std::ostream& operator<<(std::ostream &out, Matrix<T> const& data) {
    vector<size_t> dimension_multipliers(data.shape());

    // first calculate the multiplier for each dimension
    // with this we can check when to print brackets
    // e.g. this calculates [2,5,2,3] -> [60,30,6,3]
    auto curr_multiplier = 1;
    for (auto& dim : views::reverse(dimension_multipliers)) {
        dim *= curr_multiplier;
        curr_multiplier *= dim;
    }
    
    int brackets_printed = 0;
    for (auto i = 0; i < data.total_size(); i++) {
        brackets_printed = 0;
        for (auto mult : views::reverse(dimension_multipliers)) {
            if (i % mult != 0) {
                break;
            }

            // print closing bracket
            if (i != 0) {
#ifdef FORMAT_MATRIX_WITH_LINE_BREAK
                if (brackets_printed >= 1) {
                    // we already printed at least one bracket
                    // print one line break with indentation
                    out << "\n";
                    for (int x = 0; x < (data.shape().size() - brackets_printed - 1); x++) {
                        out << "  ";
                    }
                }
#endif

                out << "]";
            }
            brackets_printed++;
        }

        if (i != 0 && brackets_printed != 0) {
            out << ",";
        }
        for (int bracket_i = data.shape().size() - brackets_printed; bracket_i < data.shape().size(); bracket_i++) {
            // print opening brackets
#ifdef FORMAT_MATRIX_WITH_LINE_BREAK
            if (bracket_i != data.shape().size() - brackets_printed || i != 0) {
                out << "\n";
                for (int x = 0; x < bracket_i; x++) {
                    out << "  ";
                }
            }
#endif
            out << "[";
        }
        
        if (i != 0 && brackets_printed == 0) {
            out << ",";
        }
        out << data[i];
    }

    for (int i = 0; i < data.shape().size(); i++) {
#ifdef FORMAT_MATRIX_WITH_LINE_BREAK
        if (i != 0) {
            out << "\n";
            for (int x = 0; x < (data.shape().size() - i - 1); x++) {
                out << "  ";
            }
        }
#endif
        out << "]";
    }

    return out;
}
