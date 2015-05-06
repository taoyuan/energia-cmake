#=============================================================================#
# Author: Tomasz Bogdal (QueezyTheGreat)
# Home:   https://github.com/taoyuan/energia-cmake
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#=============================================================================#
set(CMAKE_SYSTEM_NAME Energia)

set(CMAKE_C_COMPILER   arm-none-eabi-gcc)
set(CMAKE_CXX_COMPILER arm-none-eabi-g++)

# Add current directory to CMake Module path automatically
if(EXISTS  ${CMAKE_CURRENT_LIST_DIR}/Platform/Energia.cmake)
    set(CMAKE_MODULE_PATH  ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_LIST_DIR})
endif()

#=============================================================================#
#                         System Paths                                        #
#=============================================================================#
if(UNIX)
    include(Platform/UnixPaths)
    if(APPLE)
        list(APPEND CMAKE_SYSTEM_PREFIX_PATH ~/Applications
                                             /Applications
                                             /Developer/Applications
                                             /sw          # Fink
                                             /opt/local)  # MacPorts
    endif()
elseif(WIN32)
    include(Platform/WindowsPaths)
endif()

#=============================================================================#
#                         Detect Energia SDK                                  #
#=============================================================================#
if(NOT ENERGIA_SDK_PATH)
    set(ENERGIA_PATHS)

    foreach(DETECT_VERSION_MAJOR 1)
        foreach(DETECT_VERSION_MINOR RANGE 5 0)
            list(APPEND ENERGIA_PATHS energia-${DETECT_VERSION_MAJOR}.${DETECT_VERSION_MINOR})
            foreach(DETECT_VERSION_PATCH  RANGE 3 0)
                list(APPEND ENERGIA_PATHS energia-${DETECT_VERSION_MAJOR}.${DETECT_VERSION_MINOR}.${DETECT_VERSION_PATCH})
            endforeach()
        endforeach()
    endforeach()

    foreach(VERSION RANGE 23 19)
        list(APPEND ENERGIA_PATHS energia-00${VERSION})
    endforeach()

    if(UNIX)
        file(GLOB SDK_PATH_HINTS /usr/share/energia*
            /opt/local/energia*
            /opt/energia*
            /usr/local/share/energia*)
    elseif(WIN32)
        set(SDK_PATH_HINTS "C:\\Program Files\\Energia"
            "C:\\Program Files (x86)\\Energia"
            "C:\\Energia"
            )
    endif()
    list(SORT SDK_PATH_HINTS)
    list(REVERSE SDK_PATH_HINTS)
endif()

find_path(ENERGIA_SDK_PATH
          NAMES lib/version.txt
          PATH_SUFFIXES share/energia
                        Energia.app/Contents/Resources/Java/
                        ${ENERGIA_PATHS}
          HINTS ${SDK_PATH_HINTS}
          DOC "Energia SDK path.")


if(ENERGIA_SDK_PATH)
    list(APPEND CMAKE_SYSTEM_PREFIX_PATH ${ENERGIA_SDK_PATH}/hardware/tools/lm4f/bin)
else()
    message(FATAL_ERROR "Could not find Energia SDK (set ENERGIA_SDK_PATH)!")
endif()

if (NOT ENERGIA_USER_PATH)
    get_filename_component(ENERGIA_USER_PATH "~/Documents/Energia" ABSOLUTE CACHE)
endif()

if(NOT ENERGIA_USER_PATH)
    message(FATAL_ERROR "Could not find Energia User Path (set ENERGIA_USER_PATH)!")
endif()
