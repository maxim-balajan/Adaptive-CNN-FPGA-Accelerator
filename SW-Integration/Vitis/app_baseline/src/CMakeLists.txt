# Copyright (C) 2023 - 2024 Advanced Micro Devices, Inc.  All rights reserved.
# SPDX-License-Identifier: MIT
cmake_minimum_required(VERSION 3.20)

include(${CMAKE_SOURCE_DIR}/Empty_applicationExample.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/UserConfig.cmake)
set(APP_NAME app_baseline)
project(${APP_NAME})

find_package(common)
enable_language(C ASM CXX)
collect(PROJECT_LIB_DEPS xilstandalone;xiltimer)




set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++20")

# collect neccesary libs 

set(DATA_DIR ${CMAKE_SOURCE_DIR}/../../data)
message(DATA_DIR=${DATA_DIR})

set(SIMULATION_BASE_DIR ${CMAKE_SOURCE_DIR}/../../../../reference/simulation)
message(SIMULATION_BASE_DIR=${SIMULATION_BASE_DIR})

include("${SIMULATION_BASE_DIR}/modules.cmake")

collect(PROJECT_LIB_DEPS xilstandalone;xiltimer)



collect(PROJECT_LIB_DEPS xil)
collect(PROJECT_LIB_DEPS gcc)
collect(PROJECT_LIB_DEPS c)

aux_source_directory(${CMAKE_SOURCE_DIR} _sources)
foreach (source ${_sources})
    get_filename_component(ext ${source} EXT)
    list(APPEND src_ext ${ext})
endforeach()

find_project_type ("${src_ext}" PROJECT_TYPE)

if("${PROJECT_TYPE}" STREQUAL "c++")
collect(PROJECT_LIB_DEPS stdc++)
endif()
collector_list (_deps PROJECT_LIB_DEPS)
list (APPEND _deps ${USER_LINK_LIBRARIES})

if("${PROJECT_TYPE}" STREQUAL "c++")
string (REPLACE ";" ",-l" _deps "${_deps}")
endif()
if(CMAKE_EXPORT_COMPILE_COMMANDS)
    set(CMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES})
    set(CMAKE_C_STANDARD_INCLUDE_DIRECTORIES ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES})
endif()
linker_gen("${CMAKE_SOURCE_DIR}/linker_files/")
string(APPEND CMAKE_C_FLAGS ${USER_COMPILE_OPTIONS})
string(APPEND CMAKE_CXX_FLAGS ${USER_COMPILE_OPTIONS})
string(APPEND CMAKE_C_LINK_FLAGS ${USER_LINK_OPTIONS})
string(APPEND CMAKE_CXX_LINK_FLAGS ${USER_LINK_OPTIONS})
if(NOT "${_sources}" STREQUAL "")
add_dependency_on_bsp(_sources)


add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/data/x_test.bin ${CMAKE_CURRENT_BINARY_DIR}/data/y_test.bin ${CMAKE_CURRENT_BINARY_DIR}/data/lenet_layers.bin
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${DATA_DIR} ${CMAKE_CURRENT_BINARY_DIR}/data
)
message(CMAKE_CXX_LINK_EXECUTABLE ${CMAKE_LINKER})
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/data/x_test.o
    COMMAND ${CMAKE_LINKER} -r -b binary -o x_test.o x_test.bin
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/data/x_test.bin
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/data
)
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/data/y_test.o
    COMMAND ${CMAKE_LINKER} -r -b binary -o y_test.o y_test.bin
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/data/y_test.bin
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/data
)
add_custom_command(
    OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/data/lenet_layers.o
    COMMAND ${CMAKE_LINKER} -r -b binary -o lenet_layers.o lenet_layers.bin
    DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/data/lenet_layers.bin
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/data
)

set(X_TEST_SYMBOL_PREFIX _binary_x_test_bin)
set(Y_TEST_SYMBOL_PREFIX _binary_y_test_bin)
set(LENET_LAYERS_SYMBOL_PREFIX _binary_lenet_layers_bin)

configure_file(symbols.h.in symbols.h)


add_executable(${APP_NAME}.elf ${_sources} ${CMAKE_CURRENT_BINARY_DIR}/data/x_test.o ${CMAKE_CURRENT_BINARY_DIR}/data/y_test.o ${CMAKE_CURRENT_BINARY_DIR}/data/lenet_layers.o)

target_include_directories(${APP_NAME}.elf PRIVATE ${CMAKE_CURRENT_BINARY_DIR})

set_target_properties(${APP_NAME}.elf PROPERTIES LINK_DEPENDS ${USER_LINKER_SCRIPT})

# link our modules
target_link_libraries(${APP_NAME}.elf simulation)
target_link_libraries(${APP_NAME}.elf npy_parser)

target_link_libraries(${APP_NAME}.elf -Wl,-T -Wl,\"${USER_LINKER_SCRIPT}\" -L\"${CMAKE_SOURCE_DIR}/\" -L\"${CMAKE_LIBRARY_PATH}/\" -L\"${USER_LINK_DIRECTORIES}/\" -Wl,--start-group,-l${_deps} -Wl,--end-group)

target_compile_definitions(${APP_NAME}.elf PUBLIC ${USER_COMPILE_DEFINITIONS})
target_include_directories(${APP_NAME}.elf PUBLIC ${USER_INCLUDE_DIRECTORIES})

print_elf_size(CMAKE_SIZE ${APP_NAME})
message(CMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD})
message(CMAKE_CXX_FLAGS=${CMAKE_CXX_FLAGS})
endif()
