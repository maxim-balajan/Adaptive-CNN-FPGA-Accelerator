#include <npy.hpp>
#include <string>
#include "../matrix.h"
#include "util.h"

using namespace std;

template<typename FROM, typename TO>
Matrix<TO> parse_matrix(string path) {
    npy::npy_data d = npy::read_npy<FROM>(path);
    std::vector<FROM> data = d.data;
    std::vector<unsigned long int> shape = d.shape;
    bool fortran_order = d.fortran_order;
    if (fortran_order) {
        throw ParsingException("Fortran order is not supported!");
    }

    Matrix<TO> res(shape);
    for (int i = 0; i < res.total_size(); i++) {
        res[i] = static_cast<TO>(data[i]);
    }

    return res;
}
