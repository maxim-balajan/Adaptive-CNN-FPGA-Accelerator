#pragma once
#include <cstdint>
// #include "../data/fp_int.h"
#include "../data/fp_int.h"


template<typename T>
struct is_fpuint : std::false_type {};

template<int8_t POINT_POS, typename T, typename ACC_T, int64_t MIN_VAL, int64_t MAX_VAL>
struct is_fpuint<FPInt<POINT_POS, T, ACC_T, MIN_VAL, MAX_VAL>> : std::true_type {};

template<typename T>
struct is_not_fpuint : std::true_type {};

template<int8_t POINT_POS, typename T, typename ACC_T, int64_t MIN_VAL, int64_t MAX_VAL>
struct is_not_fpuint<FPInt<POINT_POS, T, ACC_T, MIN_VAL, MAX_VAL>> : std::false_type {};

template<typename FROM, typename TO, typename std::enable_if<is_not_fpuint<TO>::value, bool>::type = 0>
TO convert_data(FROM input) {
    return static_cast<TO>(input);
}

template<typename FROM, typename TO, typename std::enable_if<is_not_fpuint<FROM>::value, bool>::type = 0, typename std::enable_if<is_fpuint<TO>::value, bool>::type = 0>
TO convert_data(FROM input) {
    return TO(input);
}


template<typename FROM, typename TO, typename std::enable_if<is_fpuint<FROM>::value, bool>::type = 0, typename std::enable_if<is_fpuint<TO>::value, bool>::type = 0>
TO convert_data(FROM input) {
    return TO(input.get_double());
}
