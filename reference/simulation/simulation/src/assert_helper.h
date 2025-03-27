#pragma once

// uncomment this to disable assertions
#define NDEBUG 1

#include <cassert>

// assert with message
#define assertm(exp, msg) assert(((void)msg, exp))
