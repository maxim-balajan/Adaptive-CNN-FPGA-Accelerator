add_executable(desktop_simulation ${CMAKE_CURRENT_LIST_DIR}/main.cpp)
set_target_properties(desktop_simulation PROPERTIES OUTPUT_NAME "simulation")

target_link_libraries(desktop_simulation PRIVATE simulation)
target_link_libraries(desktop_simulation PRIVATE parsing)
target_link_libraries(desktop_simulation PRIVATE argparse)

