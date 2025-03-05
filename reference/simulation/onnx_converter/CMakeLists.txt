add_executable(onnx_converter ${CMAKE_CURRENT_LIST_DIR}/main.cpp)
set_target_properties(onnx_converter PROPERTIES OUTPUT_NAME "onnx_converter")

target_link_libraries(onnx_converter PRIVATE simulation)
target_link_libraries(onnx_converter PRIVATE npy_parser)
target_link_libraries(onnx_converter PRIVATE onnx_parser)

