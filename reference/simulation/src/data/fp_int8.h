#pragma once
#include <cstdint>
#include <iostream>

using namespace std;

namespace {
    int8_t handle_overflow_8(int16_t val) {
        if (val > INT8_MAX) {
            return INT8_MAX;
        } else if (val < INT8_MIN) {
            return INT8_MIN;
        } else {
            return static_cast<int8_t>(val);
        }
    }
}

// fixed point int
// value is 8 bits: 01011010
// and the point is determined statically e.g.:
// 01011010. (POINT_POS=0) or 010.11010 (POINT_POS=5) or .01011010 (POINT_POS=8)

template<int8_t POINT_POS>
class FPInt8 {
private:
    int8_t value;

    FPInt8(int8_t value): value(value) {}

public:
    FPInt8(): value(0) {}

    FPInt8(float input): FPInt8(static_cast<double>(input)) {}

    FPInt8(double input) {
        int16_t multiplier = static_cast<int16_t>(1) << POINT_POS;
        input *= multiplier;

        value = handle_overflow_8(input);
    }

    FPInt8(int64_t input) {
        int16_t multiplier = static_cast<int16_t>(1) << POINT_POS;
        input *= multiplier;

        value = handle_overflow_8(input);
    }

    // arithmetic operators
    FPInt8 operator+(const FPInt8& other) const {
        int16_t new_val = static_cast<int16_t>(value) + static_cast<int16_t>(other.value);
        return FPInt8(handle_overflow_8(new_val));
    }

    FPInt8 operator-(const FPInt8& other) const {
        int16_t new_val = static_cast<int16_t>(value) - static_cast<int16_t>(other.value);
        return FPInt8(handle_overflow_8(new_val));
    }

    FPInt8 operator*(const FPInt8& other) const {
        int16_t tmp = value;
        tmp *= other.value;

        tmp = tmp >> POINT_POS;
        return FPInt8(handle_overflow_8(tmp));    
    }

    FPInt8& operator+=(const FPInt8& other) {
        int16_t new_val = static_cast<int16_t>(value) + static_cast<int16_t>(other.value);
        value = handle_overflow_8(new_val);
        return *this;
    }

    FPInt8& operator-=(const FPInt8& other) {
        int16_t new_val = static_cast<int16_t>(value) - static_cast<int16_t>(other.value);
        value = handle_overflow_8(new_val);
        return *this;
    }

    FPInt8& operator*=(const FPInt8& other) {
        int16_t tmp = value;
        tmp *= other.value;

        tmp = tmp >> POINT_POS;
        value = handle_overflow_8(tmp);    
        return *this;
    }

    // comparison operators
    bool operator==(const FPInt8& other) const {
        return value == other.value;
    }

    bool operator!=(const FPInt8& other) const {
        return value != other.value;
    }

    bool operator<(const FPInt8& other) const {
        return value < other.value;
    }

    bool operator>(const FPInt8& other) const {
        return value > other.value;
    }

    bool operator<=(const FPInt8& other) const {
        return value <= other.value;
    }

    bool operator>=(const FPInt8& other) const {
        return value >= other.value;
    }

    int8_t get_val() const {
        return value;
    }
};

template<int8_t POINT_POS>
std::ostream& operator<<(std::ostream &out, FPInt8<POINT_POS> const& data) {
    /*
    char res[8];
    for (int i = 0; i < 8; i++) {
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

    int end_pos = 8;
    int pos = 8;
    while (pos > 0 && curr != 0) {
        pos--;

        res[pos] = (curr % 2) + '0';
        if (end_pos - 1 == pos && (curr % 2 == 0)) {
            end_pos--;
        }

        curr = curr >> 1;        
    }

    if (pos > 8 - POINT_POS) {
        pos = 8 - POINT_POS;
    }

    for (; pos < end_pos; pos++) {
        if ((8 - POINT_POS) == pos) {
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

// template<int8_t POINT_POS>
// using FPInt = FPInt8;
