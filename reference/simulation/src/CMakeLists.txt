add_executable(simulation ${CMAKE_SOURCE_DIR}/src/main.cpp)

target_link_libraries(simulation PRIVATE common)
target_link_libraries(simulation PRIVATE parsing)
target_link_libraries(simulation PRIVATE argparse)

