#pragma once
#include <cstdint>
#include "../data/fp_int.h"

template<typename T>
concept IsWrapper = requires(T t) {
    t.get_val();
};

static_assert(IsWrapper<FPInt8<0>>);

template<typename FROM, typename TO>
requires IsWrapper<TO> && IsWrapper<FROM>
TO convert_data(FROM input) {
    return TO(input.get_double());
}

template<typename FROM, typename TO>
requires IsWrapper<TO>
TO convert_data(FROM input) {
    return TO(input);
}

template<typename FROM, typename TO>
TO convert_data(FROM input) {
    return static_cast<TO>(input);
}
