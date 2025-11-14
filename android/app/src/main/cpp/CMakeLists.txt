cmake_minimum_required(VERSION 3.4.1)
project(edge_inference)

add_library(edge_inference SHARED
        edge_inference.cpp
)

include_directories(edge_impulse_sdk)
add_subdirectory(edge_impulse_sdk)

find_library(log-lib log)

target_link_libraries(edge_inference
        ${log-lib}
)
