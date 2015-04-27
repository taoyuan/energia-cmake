set(CMAKE_TOOLCHAIN_FILE cmake/EnergiaToolchain.cmake)

set(CMAKE_VERBOSE_MAKEFILE on)

cmake_minimum_required(VERSION 3.0)
#====================================================================#
#  Setup Project                                                     #
#====================================================================#
project(EnergiaExample)

generate_energia_firmware(blink
    SRCS examples/Blink/Blink.cpp
    BOARD lpcc3200
    PORT /dev/tty.usbserial-cc3101B)

generate_energia_firmware(blink_bundled
    SKETCH examples/BlinkBundled/BlinkBundled.ino
    BOARD lpcc3200
    PORT /dev/tty.usbserial-cc3101B)