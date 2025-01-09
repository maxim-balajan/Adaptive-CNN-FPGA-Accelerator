cmake_minimum_required(VERSION 3.30.0)

project(simulation)
project(tests)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++23 -O3")

include("lib/CMakeLists.txt")
include("common/CMakeLists.txt")
include("parsing/CMakeLists.txt")

include(src/CMakeLists.txt)
include(tests/CMakeLists.txt)

