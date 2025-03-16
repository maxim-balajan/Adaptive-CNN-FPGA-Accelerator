#pragma once
#include <cstdint>
#include <ostream>
#include <stdexcept>

template <typename T, bool throw_error>
class SafeDivInt {

public:
    SafeDivInt() : value(0) {}

    SafeDivInt(const int32_t val) : value(static_cast<T>(val)) {}

    SafeDivInt(float input) : SafeDivInt(static_cast<int32_t>(input)) {}
    SafeDivInt(double input) : SafeDivInt(static_cast<int32_t>(input)) {}

    SafeDivInt operator/(const SafeDivInt &other) const {
        if (other.value == 0) {
            if (throw_error) {
                throw std::overflow_error("division by zero");
            }
            return SafeDivInt(0);
        }
        return SafeDivInt(value / other.value);
    }
    SafeDivInt operator/(const int other) const {
        if (other == 0) {
            if (throw_error) {
                throw std::overflow_error("division by zero");
            }
            return SafeDivInt(0);
        }
        return SafeDivInt(value / other);
    }
    SafeDivInt &operator/=(const SafeDivInt &other) const {
        if (other.value == 0) {
            if (throw_error) {
                throw std::overflow_error("division by zero");
            }
            return SafeDivInt(0);
        }
        return SafeDivInt(value / other.value);
    }
    SafeDivInt &operator/=(const int other) const {
        if (other == 0) {
            if (throw_error) {
                throw std::overflow_error("division by zero");
            }
            return SafeDivInt(0);
        }
        return SafeDivInt(value / other);
    }

    SafeDivInt &operator=(const T &other) {
        value = other;
        return *this;
    }

    SafeDivInt operator+(const SafeDivInt &val) const {
        return SafeDivInt((T)*this + (T)val);
    }

    SafeDivInt operator-(const SafeDivInt &val) const {
        return SafeDivInt((T)*this - (T)val);
    }

    SafeDivInt operator*(const SafeDivInt &val) const {
        return SafeDivInt((T)*this * (T)val);
    }

    SafeDivInt operator+(const int val) const {
        return SafeDivInt((T)*this + val);
    }

    SafeDivInt operator-(const int val) const {
        return SafeDivInt((T)*this - val);
    }

    SafeDivInt operator*(const int val) const {
        return SafeDivInt((T)*this * val);
    }

    SafeDivInt &operator+=(const SafeDivInt &val) {
        *this = *this + val;
        return *this;
    }

    SafeDivInt &operator-=(const SafeDivInt &val) {
        *this = *this - val;
        return *this;
    }

    SafeDivInt &operator*=(const SafeDivInt &val) {
        *this = *this * val;
        return *this;
    }

    SafeDivInt &operator+=(const int val) {
        *this = *this + val;
        return *this;
    }

    SafeDivInt &operator-=(const int val) {
        *this = *this - val;
        return *this;
    }

    SafeDivInt &operator*=(const int val) {
        *this = *this * val;
        return *this;
    }

    operator T() const { return value; }

    operator bool() const { return (T)*this != 0; }

    bool operator!() const { return !((T)*this); }

    SafeDivInt operator-() { return SafeDivInt(-(T)*this); }

    bool operator==(const SafeDivInt &val) const {
        return (T)*this == (T)val;
    }

    bool operator!=(const SafeDivInt &val) const {
        return (T)*this != (T)val;
    }

    bool operator>=(const SafeDivInt &val) const {
        return (T)*this >= (T)val;
    }

    bool operator<=(const SafeDivInt &val) const {
        return (T)*this <= (T)val;
    }

    bool operator>(const SafeDivInt &val) const { return (T)*this > (T)val; }

    bool operator<(const SafeDivInt &val) const { return (T)*this < (T)val; }

    /***********************************************/

    bool operator==(const int val) const { return (T)*this == val; }

    bool operator!=(const int val) const { return (T)*this != val; }

    bool operator>=(const int val) const { return (T)*this >= val; }

    bool operator<=(const int val) const { return (T)*this <= val; }

    bool operator>(const int val) const { return ((T)*this) > val; }

    bool operator<(const int val) const { return (T)*this < val; }

    int64_t get_val() const { return static_cast<int64_t>((T) *this); }

    double get_double() const { return static_cast<double>((T) *this); }

private:
    T value;
};

template <typename T, bool throw_error>
std::ostream &operator<<(std::ostream &out, SafeDivInt<T, throw_error> const &data) {
  int val = data.get_val();
  out << val;
  return out;
}