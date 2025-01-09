#include <npy.hpp>
#include <string>
#include <simulation.h>
#include "quant_parser.h"

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
//        cout << data[i];
        res[i] = convert_data<FROM, TO>(data[i]);
//        cout << ", " << res[i] << endl;
        
    }

    return res;
}

template<typename FROM, typename TO>
Matrix<TO> parse_quantized_matrix(string path, QuantArguments quant_args) {
        Matrix<FROM> original_matrix = parse_matrix<FROM, FROM>(path);

        original_matrix *= (1/quant_args.scale);
        original_matrix += quant_args.zero_point;

        // convert to target type
        Matrix<TO> dest(original_matrix.shape());

        for (int i = 0; i < original_matrix.total_size(); i++) {
            dest[i] = convert_data<FROM, TO>(original_matrix[i]);
        }

        return dest;
}
