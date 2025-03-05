cmake_minimum_required(VERSION 3.20.0)

project(simulation)
project(tests)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++23 -O3")

# generate compile_commands.json
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include("modules.cmake")

include(src/CMakeLists.txt)
include(npy_converter/CMakeLists.txt)
include(onnx_converter/CMakeLists.txt)
include(tests/CMakeLists.txt)

