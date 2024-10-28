#include "flatten.h"
#include "../assert.h"

#include <ranges>

Flatten::Flatten(size_t batching, size_t x) : output_buffer(init_matrix_2d(batching, x)) {}

matrix_2d Flatten::calc(matrix_4d input) {
    assertm(output_buffer.size() == input.size(), "Batching dimensions must match");
    assertm((input[0].size() * input[0][0].size() * input[0][0][0].size()) == output_buffer[0].size(), "Flattened dimensions must match");

    for(auto [input_item, output_item] : views::zip(input, output_buffer)) {
        int curr_i = 0;

        for(auto &a: input_item) {
            for(auto &b: a) {
                for(auto &c: b) {
                    output_item[curr_i] = c;
                    curr_i++;
                }    
            }
        }
    }
    return output_buffer;
}
