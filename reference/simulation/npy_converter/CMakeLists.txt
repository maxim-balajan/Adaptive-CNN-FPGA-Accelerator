add_executable(npy_converter ${CMAKE_CURRENT_LIST_DIR}/main.cpp)
set_target_properties(npy_converter PROPERTIES OUTPUT_NAME "npy_converter")

target_link_libraries(npy_converter PRIVATE simulation)
target_link_libraries(npy_converter PRIVATE npy_parser)
target_link_libraries(npy_converter PRIVATE onnx_parser)

