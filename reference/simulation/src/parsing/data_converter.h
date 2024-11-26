#pragma once
#include <cstdint>
// #include "../data/fp_int.h"
#include "../data/fp_int32.h"
#include "../data/fp_int8.h"


template<typename T>
struct is_fpuint : std::false_type {};

template<uint8_t ARG>
struct is_fpuint<FPInt32<ARG>> : std::true_type {};

template<uint8_t ARG>
struct is_fpuint<FPInt8<ARG>> : std::true_type {};

template<typename T>
struct is_not_fpuint : std::true_type {};

template<uint8_t ARG>
struct is_not_fpuint<FPInt32<ARG>> : std::false_type {};

template<uint8_t ARG>
struct is_not_fpuint<FPInt8<ARG>> : std::false_type {};


template<typename FROM, typename TO, typename std::enable_if<is_not_fpuint<TO>::value, bool>::type = 0>
TO convert_data(FROM input) {
    return static_cast<TO>(input);
}

template<typename FROM, typename TO, typename std::enable_if<is_fpuint<TO>::value, bool>::type = 0>
TO convert_data(FROM input) {
    return TO(input);
}
