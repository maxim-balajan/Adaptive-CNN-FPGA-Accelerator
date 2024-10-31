#include "dense.h"

Dense::Dense(Matrix weights, size_t batching, size_t x) : weights(weights), output_buffer({batching, x}) {}

Matrix Dense::calc(Matrix input)
{
    for (size_t batch_id = 0; batch_id < input.shape()[0]; batch_id++)
    {
        for (size_t wy_id = 0; wy_id < weights.shape()[1]; wy_id++)
        {
            float tmp = 0;

            for (size_t x_id = 0; x_id < input.shape()[1]; x_id++)
            {
                tmp += weights[{x_id, wy_id}] * input[x_id];
            }

            output_buffer[{batch_id, wy_id}] = tmp;
        }
    }

    return output_buffer;
}
