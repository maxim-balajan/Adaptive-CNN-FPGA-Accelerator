#pragma once
#include <cstdint>
#include <iostream>

using namespace std;

// fixed point int
// value is 8 bits: 01011010
// and the point is determined statically e.g.:
// 01011010. (POINT_POS=0) or 010.11010 (POINT_POS=5) or .01011010 (POINT_POS=8)

template<uint8_t POINT_POS>
class FPUInt8 {
private:
    uint8_t value;

    FPUInt8(uint8_t value): value(value) {}

public:
    FPUInt8(): value(0) {}

    FPUInt8(float input): FPUInt8(static_cast<double>(input)) {}

    FPUInt8(double input) {
        uint8_t multiplier = static_cast<uint8_t>(1 << POINT_POS);
        input *= multiplier;

        value = static_cast<uint8_t>(input);
    }

    FPUInt8(int64_t input) {
        uint8_t multiplier = static_cast<uint8_t>(1 << POINT_POS);
        input *= multiplier;

        value = static_cast<uint8_t>(input);
    }

    // arithmetic operators
    FPUInt8 operator+(const FPUInt8& other) const {
        uint8_t new_val = value + other.value;
        return FPUInt8(new_val);
    }

    FPUInt8 operator-(const FPUInt8& other) const {
        uint8_t new_val = value - other.value;
        return FPUInt8(new_val);
    }

    FPUInt8 operator*(const FPUInt8& other) const {
        uint16_t tmp = value;
        tmp *= other.value;

        uint8_t new_value = static_cast<uint8_t>((tmp >> POINT_POS) & 0xFF);
        return FPUInt8(new_value);
    }

    FPUInt8& operator+=(const FPUInt8& other) {
        value += other.value;
        return *this;
    }

    FPUInt8& operator-=(const FPUInt8& other) {
        value -= other.value;
        return *this;
    }

    FPUInt8& operator*=(const FPUInt8& other) {
        uint16_t tmp = value;
        tmp *= other.value;

        value = static_cast<uint8_t>((tmp >> POINT_POS) & 0xFF);
        return *this;
    }

    // comparison operators
    bool operator==(const FPUInt8& other) const {
        return value == other.value;
    }

    bool operator!=(const FPUInt8& other) const {
        return value != other.value;
    }

    bool operator<(const FPUInt8& other) const {
        return value < other.value;
    }

    bool operator>(const FPUInt8& other) const {
        return value > other.value;
    }

    bool operator<=(const FPUInt8& other) const {
        return value <= other.value;
    }

    bool operator>=(const FPUInt8& other) const {
        return value >= other.value;
    }

    uint8_t get_val() const {
        return value;
    }
};

template<uint8_t POINT_POS>
std::ostream& operator<<(std::ostream &out, FPUInt8<POINT_POS> const& data) {
    char res[8];

    uint8_t curr = data.get_val();
    int pos = 8;
    while (curr) {
        pos--;

        res[pos] = (curr % 2) + 48;
        curr /= 2;
    }

    if (pos == 8) {
        out << "0";
    } else {
        for (; pos < 8; pos++) {
            out << res[pos];
        }
    }

    return out;
}

// template<uint8_t POINT_POS>
// using FPInt = FPUInt8;
