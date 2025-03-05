add_executable(tests ${CMAKE_CURRENT_LIST_DIR}/test.cpp)
target_link_libraries(tests PRIVATE simulation)

add_executable(test_serialize ${CMAKE_CURRENT_LIST_DIR}/test_serialize.cpp)
target_link_libraries(test_serialize PRIVATE simulation onnx_parser npy_parser)
