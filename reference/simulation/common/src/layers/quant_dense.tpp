#include "quant_dense.h"

template<typename T, typename ACC>
QuantDense<T, ACC>::QuantDense(Matrix<T> weights, Matrix<T> bias, bool enable_softmax, size_t batching, size_t x, float s_b, float s_x, float s_w, float s_y)
    : weights(weights)
    , bias(bias)
    , enable_softmax(enable_softmax)
    , output_buffer({batching, x})
    , s_b(s_b)
    , s_x(s_x)
    , s_w(s_w)
    , s_y(s_y) {}


template<typename T, typename ACC>
const Matrix<T>& QuantDense<T, ACC>::calc(const Matrix<T>& input)
{
    for (size_t batch_id = 0; batch_id < input.shape()[0]; batch_id++)
    {
        for (size_t wy_id = 0; wy_id < weights.shape()[1]; wy_id++)
        {
            ACC tmp = convert_data<float, ACC>(0.0f);

            for (size_t x_id = 0; x_id < input.shape()[1]; x_id++)
            {
                tmp += convert_data<T, ACC>(weights[{x_id, wy_id}]) * convert_data<T, ACC>(input[{batch_id, x_id}]);
            }

            ACC res = tmp / convert_data<float, ACC>(s_y / (s_x * s_w)) + convert_data<T, ACC>(bias[{wy_id}]) / convert_data<float, ACC>(s_y / s_b);
            output_buffer[{batch_id, wy_id}] = convert_data<ACC, T>(res);
        }
    }

    if (enable_softmax) {
        softmax(output_buffer);
    }

    return output_buffer;
}
