#pragma once
#include <cstdint>
#include <iostream>
#include <stdio.h>
#include <string.h>
// #include "assert_helper.h"

template<typename T, typename ACC, uint64_t BIT_CNT, uint64_t SIGN_INDEX>
class EmulatedInt {
private:
    T value;

    static T handle_overflow(ACC val) {
        return static_cast<T>(val & ((static_cast<ACC>(1) << BIT_CNT) - 1));
    }

    static T convert_value(int64_t input) {
        T val = 0;
        assert(BIT_CNT % 8 == 0);
        assert(BIT_CNT <= 64);
        uint8_t* src_ptr = reinterpret_cast<uint8_t*>(&input);
        uint8_t* dest_ptr = reinterpret_cast<uint8_t*>(&val);
        for (int i = 0; i < (BIT_CNT / 8); i++) {
            *(dest_ptr + i) = *(src_ptr + i);
        }

        if (input < 0) {
            val |= (static_cast<T>(1) << SIGN_INDEX);
        } else {
            val &= ~(static_cast<T>(1) << SIGN_INDEX);
        }
        return val;
    }

    static EmulatedInt div(const EmulatedInt& val1, int64_t d) {
        int64_t val = val1.get_val() / d;

        return EmulatedInt(static_cast<int32_t>(val));
    }

    static EmulatedInt new_with_val(ACC input) {
        EmulatedInt tmp;
        tmp.value = input;
        return tmp;
    }

public:

    EmulatedInt(): value(0) {}

    EmulatedInt(float input): EmulatedInt(static_cast<double>(input)) {}

    EmulatedInt(double input) {
        value = convert_value(input);
    }

    EmulatedInt(int32_t input) {
        value = convert_value(input);
    }


    // arithmetic operators
    EmulatedInt operator+(const EmulatedInt& other) const {
        ACC new_val = static_cast<ACC>(value) + static_cast<ACC>(other.value);
        return new_with_val(new_val);
    }

    EmulatedInt operator-(const EmulatedInt& other) const {
        ACC new_val = static_cast<ACC>(value) - static_cast<ACC>(other.value);
        return new_with_val(new_val);
    }

    EmulatedInt operator*(const EmulatedInt& other) const {
        ACC tmp = value;
        tmp *= other.value;
        return new_with_val(tmp);    
    }

    EmulatedInt operator/(const EmulatedInt& other) const {
        return div(*this, other.get_val());
    }

    EmulatedInt operator*(const float scale) const {
        ACC tmp = value;
        tmp *= scale;

        return new_with_val(tmp);
    }

    EmulatedInt operator/(const float scale) const {
        return div(*this, static_cast<int64_t>(scale));
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

    EmulatedInt& operator/=(const EmulatedInt& other) {
        value = div(this, other.get_val()).value;
        return *this;
    }

    // comparison operators
    bool operator==(const EmulatedInt& other) const {
        return get_val() == other.get_val();
    }

    bool operator!=(const EmulatedInt& other) const {
        return get_val() != other.get_val();
    }

    bool operator<(const EmulatedInt& other) const {
        return get_val() < other.get_val();
    }

    bool operator>(const EmulatedInt& other) const {
        return get_val() > other.get_val();
    }

    bool operator<=(const EmulatedInt& other) const {
        return get_val() <= other.get_val();
    }

    bool operator>=(const EmulatedInt& other) const {
        return get_val() >= other.get_val();
    }

    int64_t get_val() const {
        if ((value & (1 << SIGN_INDEX)) == 0) {
            return static_cast<int64_t>(value);
        } else {
            int64_t res = 0;
            const uint8_t* src_ptr = reinterpret_cast<const uint8_t*>(&value);
            uint8_t* dest_ptr = reinterpret_cast<uint8_t*>(&res);
            for (int i = 0; i < 8; i++) {
                if (i < (BIT_CNT / 8)) {
                    *(dest_ptr + i) = *(src_ptr + i);
                } else {
                    *(dest_ptr + i) = 0xff;
                }
            }

            return res;
        }
    }

    double get_double() const {
        double val = static_cast<double>(get_val());
        return val;
    }
};


template<typename T, typename ACC, uint64_t BIT_CNT, uint64_t SIGN_INDEX>
std::ostream& operator<<(std::ostream &out, EmulatedInt<T, ACC, BIT_CNT, SIGN_INDEX> const& data) {
    out << data.get_val();
    return out;
}

using Int24 = EmulatedInt<uint32_t, uint64_t, 24, 23>;
using Int32 = EmulatedInt<uint32_t, uint64_t, 32, 31>;
using VirtualInt8 = EmulatedInt<uint8_t, uint16_t, 8, 7>;
