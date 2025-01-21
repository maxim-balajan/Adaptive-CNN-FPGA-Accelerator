
add_library(argparse INTERFACE)
target_include_directories(argparse INTERFACE ${CMAKE_CURRENT_LIST_DIR}/argparse)

add_library(libnpy INTERFACE)
target_include_directories(libnpy INTERFACE ${CMAKE_CURRENT_LIST_DIR}/libnpy)

