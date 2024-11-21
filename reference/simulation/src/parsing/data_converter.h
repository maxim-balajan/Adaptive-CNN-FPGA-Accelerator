#pragma once
#include <cstdint>
#include "../data/fp_int.h"


template<typename T>
struct is_fpuint : std::false_type {};

template<uint8_t ARG>
struct is_fpuint<FPUInt8<ARG>> : std::true_type {};

template<typename T>
struct is_not_fpuint : std::true_type {};

template<uint8_t ARG>
struct is_not_fpuint<FPUInt8<ARG>> : std::false_type {};


template<typename FROM, typename TO, typename std::enable_if<is_not_fpuint<TO>::value, bool>::type = 0>
TO convert_data(FROM input) {
    return static_cast<TO>(input);
}

template<typename FROM, typename TO, typename std::enable_if<is_fpuint<TO>::value, bool>::type = 0>
TO convert_data(FROM input) {
    return TO(input);
}

// template<>
// FPUInt8<8> convert_data<double, FPUInt8<8>>(double input) {
//     return FPUInt8<8>(input);
// }

// template<>
// FPUInt8<8> convert_data<uint64_t, FPUInt8<8>>(uint64_t input) {
//     throw runtime_error("not defined...");
// }

// template<>
// FPUInt8<8> convert_data<int64_t, FPUInt8<8>>(int64_t input) {
//     throw runtime_error("not defined...");
// }
