#pragma once
#include <cstdint>
#include <iostream>

using namespace std;

namespace {
    int32_t handle_overflow_32(int64_t val) {
        if (val > INT32_MAX) {
            return INT32_MAX;
        } else if (val < INT32_MIN) {
            return INT32_MIN;
        } else {
            return static_cast<int32_t>(val);
        }
    }
    int32_t handle_overflow_32_double(double val) {
        if (val > INT32_MAX) {
            return INT32_MAX;
        } else if (val < INT32_MIN) {
            return INT32_MIN;
        } else {
            return static_cast<int32_t>(val);
        }
    }
    int32_t handle_overflow_32_64(int64_t val) {
        if (val > INT32_MAX) {
            return INT32_MAX;
        } else if (val < INT32_MIN) {
            return INT32_MIN;
        } else {
            return static_cast<int32_t>(val);
        }
    }
}

// fixed point int
// value is 8 bits: 01011010
// and the point is determined statically e.g.:
// 01011010. (POINT_POS=0) or 010.11010 (POINT_POS=5) or .01011010 (POINT_POS=8)

template<int32_t POINT_POS>
class FPInt32 {
private:
    int32_t value;

    FPInt32(int32_t value): value(value) {}

public:
    FPInt32(): value(0) {}

    FPInt32(float input): FPInt32(static_cast<double>(input)) {}

    FPInt32(double input) {
        int64_t multiplier = static_cast<int64_t>(1) << POINT_POS;
        input *= multiplier;

        value = handle_overflow_32_double(input);
    }

    FPInt32(int64_t input) {
        int64_t multiplier = static_cast<int64_t>(1) << POINT_POS;
        input *= multiplier;

        value = handle_overflow_32_64(input);
    }

    // arithmetic operators
    FPInt32 operator+(const FPInt32& other) const {
        int64_t new_val = static_cast<int64_t>(value) + static_cast<int64_t>(other.value);
        return FPInt32(handle_overflow_32(new_val));
    }

    FPInt32 operator-(const FPInt32& other) const {
        int64_t new_val = static_cast<int64_t>(value) - static_cast<int64_t>(other.value);
        return FPInt32(handle_overflow_32(new_val));
    }

    FPInt32 operator*(const FPInt32& other) const {
        int64_t tmp = value;
        tmp *= other.value;

        tmp = tmp >> POINT_POS;
        return FPInt32(handle_overflow_32(tmp));    
    }

    FPInt32& operator+=(const FPInt32& other) {
        int64_t new_val = static_cast<int64_t>(value) + static_cast<int64_t>(other.value);
        value = handle_overflow_32(new_val);
        return *this;
    }

    FPInt32& operator-=(const FPInt32& other) {
        int64_t new_val = static_cast<int64_t>(value) - static_cast<int64_t>(other.value);
        value = handle_overflow_32(new_val);
        return *this;
    }

    FPInt32& operator*=(const FPInt32& other) {
        int64_t tmp = value;
        tmp *= other.value;

        tmp = tmp >> POINT_POS;
        value = handle_overflow_32(tmp);    
        return *this;
    }

    // comparison operators
    bool operator==(const FPInt32& other) const {
        return value == other.value;
    }

    bool operator!=(const FPInt32& other) const {
        return value != other.value;
    }

    bool operator<(const FPInt32& other) const {
        return value < other.value;
    }

    bool operator>(const FPInt32& other) const {
        return value > other.value;
    }

    bool operator<=(const FPInt32& other) const {
        return value <= other.value;
    }

    bool operator>=(const FPInt32& other) const {
        return value >= other.value;
    }

    int32_t get_val() const {
        return value;
    }
};

template<int32_t POINT_POS>
std::ostream& operator<<(std::ostream &out, FPInt32<POINT_POS> const& data) {
    /*
    char res[32];
    for (int i = 0; i < 32; i++) {
        res[i] = '0';
    }

    uint32_t curr = 0;
    if (data.get_val() < 0) {
        if (data.get_val() == INT32_MIN) {
            curr = -(INT32_MIN);
        } else {
            curr = static_cast<uint32_t>(-data.get_val());
        }
        out << "-";
    } else {
        curr = static_cast<uint32_t>(data.get_val());
    }

    if (curr == 0) {
        out << "0";
        return out;
    }

    int end_pos = 32;
    int pos = 32;
    while (pos > 0 && curr != 0) {
        pos--;

        res[pos] = (curr % 2) + '0';
        if (end_pos - 1 == pos && (curr % 2 == 0)) {
            end_pos--;
        }

        curr = curr >> 1;        
    }

    if (pos > 32 - POINT_POS) {
        pos = 32 - POINT_POS;
    }

    for (; pos < end_pos; pos++) {
        if ((32 - POINT_POS) == pos) {
            out << ".";
        }
        out << res[pos];
    }
    
    return out;
    */
   double val = data.get_val();
   val = val / (1 << POINT_POS);
   out << val;
   return out;
}

// template<int32_t POINT_POS>
// using FPInt = FPInt32;
