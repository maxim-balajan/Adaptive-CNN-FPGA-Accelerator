#pragma once
#include <cstdint>
#include <iostream>

using namespace std;

// uncomment to print floats with radix 10 
#define PRINT_10_REPR_FLOATS

// fixed point int
// value is 8 bits: 01011010
// and the point is determined statically e.g.:
// 01011010. (POINT_POS=0) or 010.11010 (POINT_POS=5) or .01011010 (POINT_POS=8)

template<int8_t POINT_POS, typename T, typename ACC_T, int64_t MIN_VAL, int64_t MAX_VAL>
class FPInt {
private:
    T value;

    FPInt(T value): value(value) {}

    static T handle_overflow(int64_t val) {
        if (val > MAX_VAL) {
            // cout << "overflow max" << endl;
            return MAX_VAL;
        } else if (val < MIN_VAL) {
            // cout << "overflow min" << endl;
            return MIN_VAL;
        } else {
            return static_cast<T>(val);
        }
    }
    static T handle_overflow_double(double val) {
        if (val > MAX_VAL) {
            // cout << "overflow max" << endl;
            return MAX_VAL;
        } else if (val < MIN_VAL) {
            // cout << "overflow min" << endl;
            return MIN_VAL;
        } else {
            return static_cast<T>(val);
        }
    }
    static T handle_overflow_64(int64_t val) {
        if (val > MAX_VAL) {
            // cout << "overflow max" << endl;
            return MAX_VAL;
        } else if (val < MIN_VAL) {
            // cout << "overflow min" << endl;
            return MIN_VAL;
        } else {
            return static_cast<T>(val);
        }
    }

public:
    FPInt(): value(0) {}

    FPInt(float input): FPInt(static_cast<double>(input)) {}

    FPInt(double input) {
        int64_t multiplier = static_cast<int64_t>(1) << POINT_POS;
        input *= multiplier;

        value = handle_overflow_double(input);
    }

    FPInt(int64_t input) {
        int64_t multiplier = static_cast<int64_t>(1) << POINT_POS;
        input *= multiplier;

        value = handle_overflow_64(input);
    }

    // arithmetic operators
    FPInt operator+(const FPInt& other) const {
        ACC_T new_val = static_cast<ACC_T>(value) + static_cast<ACC_T>(other.value);
        return FPInt(handle_overflow(new_val));
    }

    FPInt operator-(const FPInt& other) const {
        ACC_T new_val = static_cast<ACC_T>(value) - static_cast<ACC_T>(other.value);
        return FPInt(handle_overflow(new_val));
    }

    FPInt operator*(const FPInt& other) const {
        ACC_T tmp = value;
        tmp *= other.value;

        tmp = tmp >> POINT_POS;
        return FPInt(handle_overflow(tmp));    
    }

    FPInt operator/(const FPInt& other) const {
        assert(POINT_POS == 0);
        return FPInt(handle_overflow(value / other.value));    
    }

    FPInt operator*(const float scale) const {
        ACC_T tmp = value;
        int64_t multiplier = static_cast<int64_t>(1) << POINT_POS;

        tmp *= (scale * multiplier);

        return FPInt(handle_overflow(tmp));
    }

    FPInt operator/(const float scale) const {
        assert(POINT_POS == 0);
        return FPInt(handle_overflow(value / scale));    
    }

    FPInt& operator+=(const FPInt& other) {
        ACC_T new_val = static_cast<ACC_T>(value) + static_cast<ACC_T>(other.value);
        value = handle_overflow(new_val);
        return *this;
    }

    FPInt& operator-=(const FPInt& other) {
        ACC_T new_val = static_cast<ACC_T>(value) - static_cast<ACC_T>(other.value);
        value = handle_overflow(new_val);
        return *this;
    }

    FPInt& operator*=(const FPInt& other) {
        ACC_T tmp = value;
        tmp *= other.value;

        tmp = tmp >> POINT_POS;
        value = handle_overflow(tmp);    
        return *this;
    }

    // comparison operators
    bool operator==(const FPInt& other) const {
        return value == other.value;
    }

    bool operator!=(const FPInt& other) const {
        return value != other.value;
    }

    bool operator<(const FPInt& other) const {
        return value < other.value;
    }

    bool operator>(const FPInt& other) const {
        return value > other.value;
    }

    bool operator<=(const FPInt& other) const {
        return value <= other.value;
    }

    bool operator>=(const FPInt& other) const {
        return value >= other.value;
    }

    int8_t get_val() const {
        return value;
    }

    double get_double() const {
        double val = static_cast<double>(value);
        return val / (1 << POINT_POS);
    }
};

template<int8_t POINT_POS, typename T, typename ACC_T, int64_t MIN_VAL, int64_t MAX_VAL>
std::ostream& operator<<(std::ostream &out, FPInt<POINT_POS, T, ACC_T, MIN_VAL, MAX_VAL> const& data) {
#ifndef PRINT_10_REPR_FLOATS
    char res[65];
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
#else
    double val = data.get_double();
    out << val;
    return out;
#endif
}

template<int8_t POINT_POS>
using FPInt8 = FPInt<POINT_POS, int8_t, int16_t, INT8_MIN, INT8_MAX>;

template<int8_t POINT_POS>
using FPInt16 = FPInt<POINT_POS, int16_t, int32_t, INT16_MIN, INT16_MAX>;

template<int8_t POINT_POS>
using FPInt24 = FPInt<POINT_POS, int32_t, int32_t, -8388608, 8388607>;

template<int8_t POINT_POS>
using FPInt32 = FPInt<POINT_POS, int32_t, int64_t, INT32_MIN, INT32_MAX>;
