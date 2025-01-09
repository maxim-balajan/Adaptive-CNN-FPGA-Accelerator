#include "dense.h"
#include "data/data_converter.h"

template<typename T, typename ACC>
Dense<T, ACC>::Dense(Matrix<T> weights, Matrix<T> bias, bool enable_softmax, size_t batching, size_t x)
    : weights(weights)
    , bias(bias)
    , enable_softmax(enable_softmax)
    , output_buffer({batching, x}) {}


namespace {
    template<typename T>
    inline void softmax(Matrix<T>& input) {
        for (size_t batch_id = 0; batch_id < input.shape()[0]; batch_id++)
        {
            size_t max_id = 0;
            // Determine greatest value
            for (size_t x_id = 1; x_id < input.shape()[1]; x_id++)
            {
                if (input[{batch_id, x_id}] > input[{batch_id, max_id}])
                {
                    max_id = x_id;
                }
                
            }
            // Fill vector with 0s and single 1
            for (size_t x_id = 0; x_id < input.shape()[1]; x_id++)
            {
                input[{batch_id, x_id}] = convert_data<float, T>(0.0f);
            }

            input[{batch_id, max_id}] = convert_data<float, T>(1.0f);
            
        }
    }
}

template<typename T, typename ACC>
const Matrix<T>& Dense<T, ACC>::calc(const Matrix<T>& input)
{
    for (size_t batch_id = 0; batch_id < input.shape()[0]; batch_id++)
    {
        for (size_t wy_id = 0; wy_id < weights.shape()[1]; wy_id++)
        {
            T tmp = convert_data<float, T>(0.0f);

            for (size_t x_id = 0; x_id < input.shape()[1]; x_id++)
            {
                tmp += weights[{x_id, wy_id}] * input[{batch_id, x_id}];
            }

            output_buffer[{batch_id, wy_id}] = tmp + bias[{wy_id}];
        }
    }
//    cout << "Dense output " << output_buffer << "\n";

    if (enable_softmax) {
        softmax(output_buffer);
    }

    return output_buffer;
}
