
add_library(npy_parser INTERFACE)
target_include_directories(npy_parser INTERFACE ${CMAKE_CURRENT_LIST_DIR}/include)

target_link_libraries(npy_parser INTERFACE libnpy)
