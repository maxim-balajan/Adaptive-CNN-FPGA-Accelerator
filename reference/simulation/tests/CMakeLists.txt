add_executable(tests ${CMAKE_CURRENT_LIST_DIR}/test.cpp)

target_link_libraries(tests PRIVATE simulation)
