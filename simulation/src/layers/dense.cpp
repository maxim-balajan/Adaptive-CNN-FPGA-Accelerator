#include "dense.h"

Dense::Dense(Matrix weights, Matrix bias, bool enable_softmax, size_t batching, size_t x)
    : weights(weights)
    , bias(bias)
    , enable_softmax(enable_softmax)
    , output_buffer({batching, x}) {}

Matrix& Dense::softmax(Matrix& input) {
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
            input[{batch_id, x_id}] = 0;
        }

        input[{batch_id, max_id}] = 1;
        
    }

    return input;
}

Matrix& Dense::calc(Matrix& input)
{
    for (size_t batch_id = 0; batch_id < input.shape()[0]; batch_id++)
    {
        for (size_t wy_id = 0; wy_id < weights.shape()[1]; wy_id++)
        {
            float tmp = 0;

            for (size_t x_id = 0; x_id < input.shape()[1]; x_id++)
            {
                tmp += weights[{x_id, wy_id}] * input[{batch_id, x_id}];
            }

            output_buffer[{batch_id, wy_id}] = tmp + bias[{wy_id}];
        }
    }

    if (enable_softmax) {
        softmax(output_buffer);
    }

    return output_buffer;
}
