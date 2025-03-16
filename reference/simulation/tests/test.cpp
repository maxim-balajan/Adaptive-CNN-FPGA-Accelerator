#include <iostream>

#include <simulation.h>

void printb(uint16_t v) {
    unsigned int i, s = 1<<((sizeof(v)<<3)-1); // s = only most significant bit at 1
    for (i = s; i; i>>=1) printf("%d", v & i || 0 );
}

// void test_virtual_int8() {
//     for (int8_t x = INT8_MIN; x < INT8_MAX; x++) {
//         int32_t x2 = x;
//         cout << ((int)x) <<" =?= " << ((int)((int8_t) x2)) << endl;
//         assert(((int64_t) x) == (int64_t)((int8_t) x2));
//     }
//     for (int8_t x = INT8_MIN; x < INT8_MAX; x++) {
//         for (int8_t y = INT8_MIN; y < INT8_MAX; y++) {
//             int8_t z = x + y;
//             int32_t x2 = x;
//             int32_t y2 = y;
            
//             int32_t z2 = x2 + y2;
//             cout << ((int)x) <<"+" << ((int)y) <<"=" << ((int)z) << " aka: ";
//             printb(z);
//             cout << " =?= ";
//             printb((int)((int8_t) z2));
//             cout << "(" << ((int)((int8_t) z2)) << ")" << endl;
//             assert(((int64_t) z) == (int64_t)((int8_t) z2));
//         }
//     }
//     for (int8_t x = INT8_MIN; x < INT8_MAX; x++) {
//         for (int8_t y = INT8_MIN; y < INT8_MAX; y++) {
//             int8_t z = x - y;
//             VirtualInt8 x2((int32_t) x);
//             VirtualInt8 y2((int32_t) y);
            
//             VirtualInt8 z2 = x2 - y2;
//             cout << ((int)x) <<"-" << ((int)y) <<"=" << ((int)z) << " aka: ";
//             printb(z);
//             cout << " =?= ";
//             printb(z2.get_val());
//             cout << "(" << z2.get_val() << ")" << endl;
//             assert(((int64_t) z) == z2.get_val());
//         }
//     }
//     for (int8_t x = INT8_MIN; x < INT8_MAX; x++) {
//         for (int8_t y = INT8_MIN; y < INT8_MAX; y++) {
//             int8_t z = x * y;
//             VirtualInt8 x2((int32_t) x);
//             VirtualInt8 y2((int32_t) y);
            
//             VirtualInt8 z2 = x2 * y2;
//             cout << ((int)x) <<"*" << ((int)y) <<"=" << ((int)z) << " aka: ";
//             printb(z);
//             cout << " =?= ";
//             printb(z2.get_val());
//             cout << "(" << z2.get_val() << ")" << endl;
//             assert(((int64_t) z) == z2.get_val());
//         }
//     }
//     for (int8_t x = INT8_MIN + 1; x < INT8_MAX; x++) {
//         for (int8_t y = INT8_MIN + 1; y < INT8_MAX; y++) {
//             if (y == 0) {
//                 continue;
//             }

//             int8_t z = x / y;
//             VirtualInt8 x2((int32_t) x);
//             VirtualInt8 y2((int32_t) y);
            
//             VirtualInt8 z2 = x2 / y2;
//             cout << ((int)x) <<"/" << ((int)y) <<"=" << ((int)z) << " aka: ";
//             printb(z);
//             cout << " =?= ";
//             printb(z2.get_val());
//             cout << "(" << z2.get_val() << ")" << endl;
//             assert(((int64_t) z) == z2.get_val());
//         }
//     }
// }

int main() {
    // test_virtual_int8();
    FPInt32<20> fp1(0.00021);
    FPInt32<20> fp2(-0.0000999);
    cout << fp1 << ", " << fp2 << endl;
    cout << fp1 + fp2 << endl;

    cout << (-8) << ", " << (-128 >> 3) << endl;

    FPInt8<0> fp3(20.0);
    FPInt8<0> fp4(128.0);
    FPInt8<0> fp5(-128.5);
    cout << fp3 << ", " << fp4 << ", " << fp5 << endl;

    return 0;
}
