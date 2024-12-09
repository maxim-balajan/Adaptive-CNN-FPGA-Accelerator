#include <iostream>
#include "../src/data/fp_int.h"

int main() {
    FPInt32<20> fp1(0.00021);
    FPInt32<20> fp2(-0.0000999);
    cout << fp1 << ", " << fp2 << endl;
    cout << fp1 + fp2 << endl;

    cout << (-8) << ", " << (-128 >> 3) << endl;
    return 0;
}
