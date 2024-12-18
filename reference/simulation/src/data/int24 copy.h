#pragma once
#include <cstdint>
#include <iostream>
#include <stdio.h>
#include <string.h>



template<typename T, typename ACC, uint64_t BITMASK, uint64_t SIGN_OFFSET>
class EmulatedInt {
private:
    T value;

    static T handle_overflow(ACC val) {
        ACC temp = val & BITMASK;
//        temp += (val & (~EmulatedInt_BITMASK)) << 1;

        return static_cast<T>(temp);
    }

    static T handle_overflow_double(double val) {
        return handle_overflow(static_cast<ACC>(val));
    }

public:

    EmulatedInt(): value(0) {}

    EmulatedInt(float input): EmulatedInt(static_cast<double>(input)) {}

    EmulatedInt(double input) {
        value = handle_overflow_double(input);
    }

    EmulatedInt(ACC input) {
        value = handle_overflow(input);
    }

    EmulatedInt(int32_t input) {
        value = handle_overflow(input);
    }


    // arithmetic operators
    EmulatedInt operator+(const EmulatedInt& other) const {
        ACC new_val = static_cast<ACC>(value) + static_cast<ACC>(other.value);
        return EmulatedInt(new_val);
    }

    EmulatedInt operator-(const EmulatedInt& other) const {
        ACC new_val = static_cast<ACC>(value) - static_cast<ACC>(other.value);
        return EmulatedInt(new_val);
    }

    EmulatedInt operator*(const EmulatedInt& other) const {
        ACC tmp = value;
        tmp *= other.value;
        return EmulatedInt(tmp);    
    }

    EmulatedInt operator*(const float scale) const {
        ACC tmp = value;
        tmp *= scale;

        return EmulatedInt(tmp);
    }

    EmulatedInt& operator+=(const EmulatedInt& other) {
        ACC new_val = static_cast<ACC>(value) + static_cast<ACC>(other.value);
        value = handle_overflow(new_val);
        return *this;
    }

    EmulatedInt& operator-=(const EmulatedInt& other) {
        ACC new_val = static_cast<ACC>(value) - static_cast<ACC>(other.value);
        value = handle_overflow(new_val);
        return *this;
    }

    EmulatedInt& operator*=(const EmulatedInt& other) {
        ACC tmp = value;
        tmp *= other.value;

        value = handle_overflow(tmp);    
        return *this;
    }

    // comparison operators
    bool operator==(const EmulatedInt& other) const {
        return value == other.value;
    }

    bool operator!=(const EmulatedInt& other) const {
        return value != other.value;
    }

    bool operator<(const EmulatedInt& other) const {
        return value < other.value;
    }

    bool operator>(const EmulatedInt& other) const {
        return value > other.value;
    }

    bool operator<=(const EmulatedInt& other) const {
        return value <= other.value;
    }

    bool operator>=(const EmulatedInt& other) const {
        return value >= other.value;
    }

    int64_t get_val() const {
        return static_cast<int64_t>(value);
    }

    double get_double() const {
        double val = static_cast<double>(value);
        return val;
    }
};

using Int24 = EmulatedInt<int32_t, int64_t, (1 << 30) - 1, 0>;
using VirtualInt8 = EmulatedInt<int8_t, int16_t, (1 << 7) - 1, 0>;
