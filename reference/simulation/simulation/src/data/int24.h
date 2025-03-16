// https://stackoverflow.com/a/2682737

#pragma once
#include <cstdint>
#include <iostream>

const int INT24_MAX = 8388607;

template<bool throw_div_error>
class Int24 {
protected:
  unsigned char m_Internal[3];

public:
  Int24() {}

  Int24(const int32_t val) { *this = val; }

  Int24(float input) : Int24(static_cast<int32_t>(input)) {}
  Int24(double input) : Int24(static_cast<int32_t>(input)) {}

  Int24(const Int24 &val) { *this = val; }

  operator int() const {
    if (m_Internal[2] &
        0x80) // Is this a negative?  Then we need to siingn extend.
    {
      return (0xff << 24) | (m_Internal[2] << 16) | (m_Internal[1] << 8) |
             (m_Internal[0] << 0);
    } else {
      return (m_Internal[2] << 16) | (m_Internal[1] << 8) |
             (m_Internal[0] << 0);
    }
  }

  operator float() const { return (float)this->operator int(); }

  Int24 &operator=(const Int24 &input) {
    m_Internal[0] = input.m_Internal[0];
    m_Internal[1] = input.m_Internal[1];
    m_Internal[2] = input.m_Internal[2];

    return *this;
  }

  Int24 &operator=(const int input) {
    m_Internal[0] = ((unsigned char *)&input)[0];
    m_Internal[1] = ((unsigned char *)&input)[1];
    m_Internal[2] = ((unsigned char *)&input)[2];

    return *this;
  }

  /***********************************************/

  Int24 operator+(const Int24 &val) const {
    return Int24((int)*this + (int)val);
  }

  Int24 operator-(const Int24 &val) const {
    return Int24((int)*this - (int)val);
  }

  Int24 operator*(const Int24 &val) const {
    return Int24((int)*this * (int)val);
  }

  Int24 operator/(const Int24 &val) const {
    if (val == 0) {
      if (throw_div_error) {
        throw std::overflow_error("division by zero");
      }
      return Int24(0);
    }
    return Int24((int)*this / (int)val);
  }

  /***********************************************/

  Int24 operator+(const int val) const { return Int24((int)*this + val); }

  Int24 operator-(const int val) const { return Int24((int)*this - val); }

  Int24 operator*(const int val) const { return Int24((int)*this * val); }

  Int24 operator/(const int val) const {
    if (val == 0) {
      if (throw_div_error) {
        throw std::overflow_error("division by zero");
      }
      return Int24(0);
    }

    return Int24((int)*this / val);
  }

  /***********************************************/
  /***********************************************/

  Int24 &operator+=(const Int24 &val) {
    *this = *this + val;
    return *this;
  }

  Int24 &operator-=(const Int24 &val) {
    *this = *this - val;
    return *this;
  }

  Int24 &operator*=(const Int24 &val) {
    *this = *this * val;
    return *this;
  }

  Int24 &operator/=(const Int24 &val) {
    if (val == 0) {
      if (throw_div_error) {
        throw std::overflow_error("division by zero");
      }
      *this = 0;
      return *this;
    }

    *this = *this / val;
    return *this;
  }

  /***********************************************/

  Int24 &operator+=(const int val) {
    *this = *this + val;
    return *this;
  }

  Int24 &operator-=(const int val) {
    *this = *this - val;
    return *this;
  }

  Int24 &operator*=(const int val) {
    *this = *this * val;
    return *this;
  }

  Int24 &operator/=(const int val) {
    if (val == 0) {
      if (throw_div_error) {
        throw std::overflow_error("division by zero");
      }
      *this = 0;
      return *this;
    }
    *this = *this / val;
    return *this;
  }

  /***********************************************/
  /***********************************************/

  Int24 operator>>(const int val) const { return Int24((int)*this >> val); }

  Int24 operator<<(const int val) const { return Int24((int)*this << val); }

  /***********************************************/

  Int24 &operator>>=(const int val) {
    *this = *this >> val;
    return *this;
  }

  Int24 &operator<<=(const int val) {
    *this = *this << val;
    return *this;
  }

  /***********************************************/
  /***********************************************/

  operator bool() const { return (int)*this != 0; }

  bool operator!() const { return !((int)*this); }

  Int24 operator-() { return Int24(-(int)*this); }

  /***********************************************/
  /***********************************************/

  bool operator==(const Int24 &val) const { return (int)*this == (int)val; }

  bool operator!=(const Int24 &val) const { return (int)*this != (int)val; }

  bool operator>=(const Int24 &val) const { return (int)*this >= (int)val; }

  bool operator<=(const Int24 &val) const { return (int)*this <= (int)val; }

  bool operator>(const Int24 &val) const { return (int)*this > (int)val; }

  bool operator<(const Int24 &val) const { return (int)*this < (int)val; }

  /***********************************************/

  bool operator==(const int val) const { return (int)*this == val; }

  bool operator!=(const int val) const { return (int)*this != val; }

  bool operator>=(const int val) const { return (int)*this >= val; }

  bool operator<=(const int val) const { return (int)*this <= val; }

  bool operator>(const int val) const { return ((int)*this) > val; }

  bool operator<(const int val) const { return (int)*this < val; }

  int64_t get_val() const {
    int32_t val = (*this);
    return val;
  }

  double get_double() const {
    float val = (*this);
    return val;
  }

  /***********************************************/
  /***********************************************/
};

template<bool throw_div_error>
std::ostream &operator<<(std::ostream &out, Int24<throw_div_error> const &data) {
  int val = data.get_val();
  out << val;
  return out;
}