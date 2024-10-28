cmake_minimum_required(VERSION 3.20.0)

project(simulation)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++23 -O3")

set(SOURCE_FILES src/main.cpp src/layers/convolution.cpp src/layers/dense.cpp src/layers/max_polling.cpp)

add_executable(simulation ${SOURCE_FILES})
