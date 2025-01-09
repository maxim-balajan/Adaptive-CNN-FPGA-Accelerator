add_executable(tests ${CMAKE_SOURCE_DIR}/tests/test.cpp)

target_link_libraries(tests PRIVATE common)
