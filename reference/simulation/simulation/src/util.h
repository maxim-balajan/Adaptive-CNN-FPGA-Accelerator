#pragma once
#include <ios>
#include <vector>
#include <iostream>
#include <bit>
#include <span>

using namespace std;

template<typename T>
void print_vector(vector<T> vec) {
    cout << "[";
    for (int i = 0; i < vec.size(); i++) {
        if (i != 0) {
            cout << ", ";
        }
        cout << vec[i];
    }

    cout << "]\n";
}

// also supports float, etc
template <typename T>
T custom_byteswap(T val) {
    T retVal;
    char *pVal = (char*) &val;
    char *pRetVal = (char*)&retVal;
    int size = sizeof(T);
    for(int i=0; i<size; i++) {
        pRetVal[size-1-i] = pVal[i];
    }

    return retVal;
}

template<typename T>
T htont(T val) {
    if constexpr(endian::native == endian::big) {
        return val;
    } else if (endian::native == endian::little) {
        return custom_byteswap(val);
    } else {
        // mixed endianess is not supported
        throw exception();
    }
}

template<typename T>
T ntoht(T val) {
    // function can be used two ways
    return htont(val);
}

template<typename T>
unsigned serialize_number(const T val, ostream& stream) {
    T serialized_size = htont(val);
    stream.write(reinterpret_cast<const char*>(&serialized_size), sizeof(T));

    return sizeof(T);    
}

template<typename T>
T deserialize_number(std::span<char>& data) {
    T val = ntoht(*reinterpret_cast<const T*>(&data[0]));
    data = data.subspan(sizeof(T));

    return val;
}


template<typename T>
unsigned serialize_vector(const vector<T>& vec, ostream& stream) {
    unsigned bytes = 0;
    bytes += serialize_number(vec.size(), stream);
    for (const auto& item : vec) {
        bytes += serialize_number(item, stream);
    }
    return bytes;
}


template<typename T>
vector<T> deserialize_vector(std::span<char>& data) {
    using size_type = typename vector<T>::size_type;

    size_type size = deserialize_number<size_type>(data);
    vector<T> vec(size);
    for (int i = 0; i < size; i++) {
        vec[i] = deserialize_number<T>(data);
    }

    return vec;
}
