# find protobuf, include proto lib directory and cmake_bin_dir where proto will be generated, then generate
find_package(Protobuf REQUIRED)

# compile .proto file
protobuf_generate_cpp(PROTO_SRC PROTO_HEADER ${CMAKE_CURRENT_LIST_DIR}/src/onnx.proto)
add_library(onnx_parser_protobuf ${PROTO_HEADER} ${PROTO_SRC})
target_include_directories(onnx_parser_protobuf PUBLIC ${Protobuf_INCLUDE_DIRS} ${CMAKE_BINARY_DIR})
target_link_libraries(onnx_parser_protobuf PUBLIC ${Protobuf_LIBRARIES})

add_library(onnx_parser INTERFACE)
target_link_libraries(onnx_parser INTERFACE onnx_parser_protobuf)
target_include_directories(onnx_parser INTERFACE ${CMAKE_CURRENT_LIST_DIR}/include)

target_link_libraries(onnx_parser INTERFACE libnpy)
