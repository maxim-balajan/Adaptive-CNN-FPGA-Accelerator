#include <npy.hpp>
#include <string>
#include <simulation.h>

using namespace std;

template<typename FROM, typename TO>
Matrix<TO> parse_matrix(const string& filename) {
    ifstream stream(filename, ifstream::binary);
    if (!stream) {
        throw std::runtime_error("io error: failed to open a file.");
    }

    return parse_matrix<FROM, TO>(stream);
}

template<typename FROM, typename TO>
Matrix<TO> parse_matrix(istream& stream) {
    npy::npy_data d = npy::read_npy<FROM>(stream);
    std::vector<FROM> data = d.data;
    std::vector<unsigned long int> shape = d.shape;
    bool fortran_order = d.fortran_order;
    if (fortran_order) {
        throw ParsingException("Fortran order is not supported!");
    }

    Matrix<TO> res(shape);
    for (int i = 0; i < res.total_size(); i++) {
        res[i] = convert_data<FROM, TO>(data[i]);
    }

    return res;
}

template<typename FROM, typename TO>
Matrix<TO> parse_quantized_matrix(const string& filename, float scale, float zero_point) {
    ifstream stream(filename, ifstream::binary);
    if (!stream) {
        throw std::runtime_error("io error: failed to open a file.");
    }

    return parse_quantized_matrix<FROM, TO>(stream, scale, zero_point);
}

template<typename FROM, typename TO>
Matrix<TO> parse_quantized_matrix(istream& stream, float scale, float zero_point) {
        Matrix<FROM> original_matrix = parse_matrix<FROM, FROM>(stream);

        original_matrix *= (1/scale);
        original_matrix += zero_point;

        // convert to target type
        Matrix<TO> dest(original_matrix.shape());

        for (int i = 0; i < original_matrix.total_size(); i++) {
            dest[i] = convert_data<FROM, TO>(original_matrix[i]);
        }

        return dest;
}
