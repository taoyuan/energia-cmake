set(CMAKE_TOOLCHAIN_FILE cmake/EnergiaToolchain.cmake)

cmake_minimum_required(VERSION 3.0)
#====================================================================#
#  Setup Project                                                     #
#====================================================================#
project(EnergiaExample)

generate_energia_firmware(blink
    SRCS Blink.cpp
    BOARD lpcc3200)