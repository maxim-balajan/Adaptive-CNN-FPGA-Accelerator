cmake_minimum_required(VERSION 3.20.0)

project(simulation)

set(CMAKE_CXX_STANDARD 23)
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++23 -O3")

# find protobuf, include proto lib directory and cmake_bin_dir where proto will be generated, then generate
find_package(Protobuf REQUIRED)
include_directories(${Protobuf_INCLUDE_DIRS} ${CMAKE_BINARY_DIR})

# compile .proto file
protobuf_generate_cpp(PROTO_SRC PROTO_HEADER src/parsing/onnx.proto)
add_library(proto ${PROTO_HEADER} ${PROTO_SRC})

add_executable(simulation ${SOURCE_FILES})
target_link_libraries(simulation proto ${PROTOBUF_LIBRARY})

add_subdirectory(src)
