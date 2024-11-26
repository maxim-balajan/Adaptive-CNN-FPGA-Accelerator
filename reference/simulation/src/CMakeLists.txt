target_link_libraries(simulation proto ${PROTOBUF_LIBRARY})


target_sources(simulation PRIVATE main.cpp)
add_subdirectory(data)
add_subdirectory(layers)
add_subdirectory(parsing)
