
add_library(argparse INTERFACE)
target_include_directories(argparse INTERFACE ${CMAKE_SOURCE_DIR}/lib/argparse)

add_library(libnpy INTERFACE)
target_include_directories(libnpy INTERFACE ${CMAKE_SOURCE_DIR}/lib/libnpy)

