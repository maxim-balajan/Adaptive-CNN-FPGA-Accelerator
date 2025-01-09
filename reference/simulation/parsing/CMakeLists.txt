# find protobuf, include proto lib directory and cmake_bin_dir where proto will be generated, then generate
find_package(Protobuf REQUIRED)

# compile .proto file
protobuf_generate_cpp(PROTO_SRC PROTO_HEADER ${CMAKE_SOURCE_DIR}/parsing/parsing/onnx.proto)
add_library(parsing_protobuf ${PROTO_HEADER} ${PROTO_SRC})
target_include_directories(parsing_protobuf PUBLIC ${Protobuf_INCLUDE_DIRS} ${CMAKE_BINARY_DIR})
target_link_libraries(parsing_protobuf PUBLIC ${Protobuf_LIBRARIES})

add_library(parsing INTERFACE)
target_link_libraries(parsing INTERFACE parsing_protobuf)
target_include_directories(parsing INTERFACE ${CMAKE_SOURCE_DIR}/parsing)

target_link_libraries(parsing INTERFACE libnpy)
