#pragma once
#include "vector"
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