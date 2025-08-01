cmake_minimum_required(VERSION 3.20)
project(wrapper64_glibc C)

set(CMAKE_C_STANDARD 11)

add_library(wrapper64_glibc SHARED wrapper64_glibc.c)

set_target_properties(wrapper64_glibc PROPERTIES
    OUTPUT_NAME "wrapper64_glibc"
    PREFIX "lib"
)
