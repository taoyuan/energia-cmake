cmake_minimum_required(VERSION 2.8.5)
include(CMakeParseArguments)


#=============================================================================#
#                           User Functions
#=============================================================================#

#=============================================================================#
# [PUBLIC/USER]
#
# print_board_list()
#
# see documentation at top
#=============================================================================#
function(PRINT_BOARD_LIST)
    foreach(P ${ENERGIA_PLATFORMS})
        if(${P}_BOARDS)
            message(STATUS "${P} Boards:")
            print_list(${P}_BOARDS)
            message(STATUS "")
        endif()
    endforeach()
endfunction()

#=============================================================================#
# [PUBLIC/USER]
#
# print_programmer_list()
#
# see documentation at top
#=============================================================================#
function(PRINT_PROGRAMMER_LIST)
    foreach(P ${ENERGIA_PLATFORMS})
        if(${P}_PROGRAMMERS)
            message(STATUS "${P} Programmers:")
            print_list(${P}_PROGRAMMERS)
        endif()
        message(STATUS "")
    endforeach()
endfunction()

#=============================================================================#
# [PUBLIC/USER]
#
# print_programmer_settings(PROGRAMMER)
#
# see documentation at top
#=============================================================================#
function(PRINT_PROGRAMMER_SETTINGS PROGRAMMER)
    if(${PROGRAMMER}.SETTINGS)
        message(STATUS "Programmer ${PROGRAMMER} Settings:")
        print_settings(${PROGRAMMER})
    endif()
endfunction()

# [PUBLIC/USER]
#
# print_board_settings(ENERGIA_BOARD)
#
# see documentation at top
function(PRINT_BOARD_SETTINGS ENERGIA_BOARD)
    if(${ENERGIA_BOARD}.SETTINGS)
        message(STATUS "Energia ${ENERGIA_BOARD} Board:")
        print_settings(${ENERGIA_BOARD})
    endif()
endfunction()


#=============================================================================#
# [PUBLIC/USER]
# see documentation at top
#=============================================================================#
function(GENERATE_ENERGIA_LIBRARY INPUT_NAME)
    message(STATUS "Generating ${INPUT_NAME}")
    parse_generator_arguments(${INPUT_NAME} INPUT
                              "NO_AUTOLIBS;MANUAL"                  # Options
                              "BOARD"                               # One Value Keywords
                              "SRCS;HDRS;LIBS"                      # Multi Value Keywords
                              ${ARGN})

    if(NOT INPUT_BOARD)
        set(INPUT_BOARD ${ENERGIA_DEFAULT_BOARD})
    endif()
    if(NOT INPUT_MANUAL)
        set(INPUT_MANUAL FALSE)
    endif()
    required_variables(VARS INPUT_SRCS INPUT_BOARD MSG "must define for target ${INPUT_NAME}")

    set(ALL_LIBS)
    set(ALL_SRCS ${INPUT_SRCS} ${INPUT_HDRS})

    if(NOT INPUT_MANUAL)
      setup_energia_core(CORE_LIB ${INPUT_BOARD})
    endif()

    find_energia_libraries(TARGET_LIBS "${ALL_SRCS}" "")

    set(LIB_DEP_INCLUDES)
    foreach(LIB_DEP ${TARGET_LIBS})
        set(LIB_DEP_INCLUDES "${LIB_DEP_INCLUDES} -I\"${LIB_DEP}\"")
    endforeach()

    if(NOT ${INPUT_NO_AUTOLIBS})
        setup_energia_libraries(ALL_LIBS  ${INPUT_BOARD} "${ALL_SRCS}" "" "${LIB_DEP_INCLUDES}" "")
    endif()

    list(APPEND ALL_LIBS ${CORE_LIB} ${INPUT_LIBS})

    add_library(${INPUT_NAME} ${ALL_SRCS})

    get_energia_flags(ENERGIA_COMPILE_FLAGS ENERGIA_LINK_FLAGS  ${INPUT_BOARD} ${INPUT_MANUAL})

#    message(" - XXX " "${ENERGIA_COMPILE_FLAGS} ${COMPILE_FLAGS} ${LIB_DEP_INCLUDES}")

    set_target_properties(${INPUT_NAME} PROPERTIES
                COMPILE_FLAGS "${ENERGIA_COMPILE_FLAGS} ${COMPILE_FLAGS} ${LIB_DEP_INCLUDES}"
                LINK_FLAGS "${ENERGIA_LINK_FLAGS} ${LINK_FLAGS}")

    target_link_libraries(${INPUT_NAME} ${ALL_LIBS} "-lc -lm")
endfunction()


#=============================================================================#
# [PUBLIC/USER]
# see documentation at top
#=============================================================================#
function(GENERATE_ENERGIA_FIRMWARE INPUT_NAME)
    message(STATUS "Generating ${INPUT_NAME}")
    parse_generator_arguments(${INPUT_NAME} INPUT
                              "NO_AUTOLIBS;MANUAL"                  # Options
                              "BOARD;PORT;SKETCH;PROGRAMMER"        # One Value Keywords
                              "SERIAL;SRCS;HDRS;LIBS;ARDLIBS;AFLAGS"  # Multi Value Keywords
                              ${ARGN})

    if(NOT INPUT_BOARD)
        set(INPUT_BOARD ${ENERGIA_DEFAULT_BOARD})
    endif()
    if(NOT INPUT_PORT)
        set(INPUT_PORT ${ENERGIA_DEFAULT_PORT})
    endif()
    if(NOT INPUT_SERIAL)
        set(INPUT_SERIAL ${ENERGIA_DEFAULT_SERIAL})
    endif()
    if(NOT INPUT_PROGRAMMER)
        set(INPUT_PROGRAMMER ${ENERGIA_DEFAULT_PROGRAMMER})
    endif()
    if(NOT INPUT_MANUAL)
        set(INPUT_MANUAL FALSE)
    endif()
    required_variables(VARS INPUT_BOARD MSG "must define for target ${INPUT_NAME}")

    set(ALL_LIBS)
    set(ALL_SRCS ${INPUT_SRCS} ${INPUT_HDRS})
    set(LIB_DEP_INCLUDES)

    if(NOT INPUT_MANUAL)
      setup_energia_core(CORE_LIB ${INPUT_BOARD})
    endif()

    if(NOT "${INPUT_SKETCH}" STREQUAL "")
        get_filename_component(INPUT_SKETCH "${INPUT_SKETCH}" ABSOLUTE)
        setup_energia_sketch(${INPUT_NAME} ${INPUT_SKETCH} ALL_SRCS)
        if (IS_DIRECTORY "${INPUT_SKETCH}")
            set(LIB_DEP_INCLUDES "${LIB_DEP_INCLUDES} -I\"${INPUT_SKETCH}\"")
        else()
            get_filename_component(INPUT_SKETCH_PATH "${INPUT_SKETCH}" PATH)
            set(LIB_DEP_INCLUDES "${LIB_DEP_INCLUDES} -I\"${INPUT_SKETCH_PATH}\"")
        endif()
    endif()

    required_variables(VARS ALL_SRCS MSG "must define SRCS or SKETCH for target ${INPUT_NAME}")

    find_energia_libraries(TARGET_LIBS "${ALL_SRCS}" "${INPUT_ARDLIBS}")

    foreach(LIB_DEP ${TARGET_LIBS})
        energia_debug_msg("Energia Library: ${LIB_DEP}")
        set(LIB_DEP_INCLUDES "${LIB_DEP_INCLUDES} -I\"${LIB_DEP}\" -I\"${LIB_DEP}/utility\"")
    endforeach()

    if(NOT INPUT_NO_AUTOLIBS)
        setup_energia_libraries(ALL_LIBS ${INPUT_BOARD} "${ALL_SRCS}" "${INPUT_ARDLIBS}" "${LIB_DEP_INCLUDES}" "")
        foreach(LIB_INCLUDES ${ALL_LIBS_INCLUDES})
            energia_debug_msg("Energia Library Includes: ${LIB_INCLUDES}")
            set(LIB_DEP_INCLUDES "${LIB_DEP_INCLUDES} ${LIB_INCLUDES}")
        endforeach()
    endif()

    list(APPEND ALL_LIBS ${CORE_LIB} ${INPUT_LIBS})

    setup_energia_target(${INPUT_NAME} ${INPUT_BOARD} "${ALL_SRCS}" "${ALL_LIBS}" "${LIB_DEP_INCLUDES}" "" "${INPUT_MANUAL}")

    if(INPUT_PORT)
        setup_energia_upload(${INPUT_BOARD} ${INPUT_NAME} ${INPUT_PORT} "${INPUT_PROGRAMMER}" "${INPUT_AFLAGS}")
    endif()

    if(INPUT_SERIAL)
        setup_serial_target(${INPUT_NAME} "${INPUT_SERIAL}" "${INPUT_PORT}")
    endif()

endfunction()

#=============================================================================#
#                        Internal Functions
#=============================================================================#

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# parse_generator_arguments(TARGET_NAME PREFIX OPTIONS ARGS MULTI_ARGS [ARG1 ARG2 .. ARGN])
#
#         PREFIX     - Parsed options prefix
#         OPTIONS    - List of options
#         ARGS       - List of one value keyword arguments
#         MULTI_ARGS - List of multi value keyword arguments
#         [ARG1 ARG2 .. ARGN] - command arguments [optional]
#
# Parses generator options from either variables or command arguments
#
#=============================================================================#
macro(PARSE_GENERATOR_ARGUMENTS TARGET_NAME PREFIX OPTIONS ARGS MULTI_ARGS)
    cmake_parse_arguments(${PREFIX} "${OPTIONS}" "${ARGS}" "${MULTI_ARGS}" ${ARGN})
    error_for_unparsed(${PREFIX})
    load_generator_settings(${TARGET_NAME} ${PREFIX} ${OPTIONS} ${ARGS} ${MULTI_ARGS})
endmacro()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# load_generator_settings(TARGET_NAME PREFIX [SUFFIX_1 SUFFIX_2 .. SUFFIX_N])
#
#         TARGET_NAME - The base name of the user settings
#         PREFIX      - The prefix name used for generator settings
#         SUFFIX_XX   - List of suffixes to load
#
#  Loads a list of user settings into the generators scope. User settings have
#  the following syntax:
#
#      ${BASE_NAME}${SUFFIX}
#
#  The BASE_NAME is the target name and the suffix is a specific generator settings.
#
#  For every user setting found a generator setting is created of the follwoing fromat:
#
#      ${PREFIX}${SUFFIX}
#
#  The purpose of loading the settings into the generator is to not modify user settings
#  and to have a generic naming of the settings within the generator.
#
#=============================================================================#
function(LOAD_GENERATOR_SETTINGS TARGET_NAME PREFIX)
    foreach(GEN_SUFFIX ${ARGN})
        if(${TARGET_NAME}_${GEN_SUFFIX} AND NOT ${PREFIX}_${GEN_SUFFIX})
            set(${PREFIX}_${GEN_SUFFIX} ${${TARGET_NAME}_${GEN_SUFFIX}} PARENT_SCOPE)
        endif()
    endforeach()
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# find_sources(VAR_NAME LIB_PATH RECURSE)
#
#        VAR_NAME - Variable name that will hold the detected sources
#        LIB_PATH - The base path
#        RECURSE  - Whether or not to recurse
#
# Finds all C/C++ sources located at the specified path.
#
#=============================================================================#
function(find_sources VAR_NAME LIB_PATH RECURSE)
    set(FILE_SEARCH_LIST
        ${LIB_PATH}/*.ino
        ${LIB_PATH}/*.cpp
        ${LIB_PATH}/*.c
        ${LIB_PATH}/*.cc
        ${LIB_PATH}/*.cxx
        ${LIB_PATH}/*.h
        ${LIB_PATH}/*.hh
        ${LIB_PATH}/*.hxx)

    if(RECURSE)
        file(GLOB_RECURSE LIB_FILES ${FILE_SEARCH_LIST})
    else()
        file(GLOB LIB_FILES ${FILE_SEARCH_LIST})
    endif()

    if(LIB_FILES)
        set(${VAR_NAME} ${LIB_FILES} PARENT_SCOPE)
    endif()
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# detect_energia_version(VAR_NAME)
#
#       VAR_NAME - Variable name where the detected version will be saved
#
# Detects the Energia SDK Version based on the revisions.txt file. The
# following variables will be generated:
#
#    ${VAR_NAME}         -> the full version (energia[E]energia)
#    ${VAR_NAME}_ENERGIA   -> the energia version
#    ${VAR_NAME}_ENERGIA   -> the energia version
#
#=============================================================================#
function(detect_energia_version VAR_NAME)
    if(ENERGIA_VERSION_PATH)
        file(READ ${ENERGIA_VERSION_PATH} RAW_VERSION)
        if("${RAW_VERSION}" MATCHES "[ ]*([0-9]+[E][0-9]+)")
            set(PARSED_VERSION ${CMAKE_MATCH_1})
        endif()

        if(NOT PARSED_VERSION STREQUAL "")
            string(REPLACE "E" ";" SPLIT_VERSION ${PARSED_VERSION})
            list(GET SPLIT_VERSION 0 SPLIT_VERSION_ARDUINO)
            list(GET SPLIT_VERSION 1 SPLIT_VERSION_ENERGIA)

            set(${VAR_NAME}         "${PARSED_VERSION}"         PARENT_SCOPE)
            set(${VAR_NAME}_ARDUINO "${SPLIT_VERSION_ARDUINO}"  PARENT_SCOPE)
            set(${VAR_NAME}_ENERGIA "${SPLIT_VERSION_ENERGIA}"  PARENT_SCOPE)
        endif()
    endif()
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# load_energia_style_settings(SETTINGS_LIST SETTINGS_PATH)
#
#      SETTINGS_LIST - Variable name of settings list
#      SETTINGS_PATH - File path of settings file to load.
#
# Load a Energia style settings file into the cache.
#
#  Examples of this type of settings file is the boards.txt and
# programmers.txt files located in ${ENERGIA_SDK}/hardware/energia.
#
# Settings have to following format:
#
#      entry.setting[.subsetting] = value
#
# where [.subsetting] is optional
#
# For example, the following settings:
#
#      uno.name=Energia Uno
#      uno.upload.protocol=stk500
#      uno.upload.maximum_size=32256
#      uno.build.mcu=atmega328p
#      uno.build.core=energia
#
# will generate the follwoing equivalent CMake variables:
#
#      set(uno.name "Energia Uno")
#      set(uno.upload.protocol     "stk500")
#      set(uno.upload.maximum_size "32256")
#      set(uno.build.mcu  "atmega328p")
#      set(uno.build.core "energia")
#
#      set(uno.SETTINGS  name upload build)              # List of settings for uno
#      set(uno.upload.SUBSETTINGS protocol maximum_size) # List of sub-settings for uno.upload
#      set(uno.build.SUBSETTINGS mcu core)               # List of sub-settings for uno.build
#
#  The ${ENTRY_NAME}.SETTINGS variable lists all settings for the entry, while
# ${ENTRY_NAME}.SUBSETTINGS variables lists all settings for a sub-setting of
# a entry setting pair.
#
#  These variables are generated in order to be able to  programatically traverse
# all settings (for a example see print_board_settings() function).
#
#=============================================================================#
function(LOAD_ENERGIA_STYLE_SETTINGS SETTINGS_LIST SETTINGS_PATH)

    if(NOT ${SETTINGS_LIST} AND EXISTS ${SETTINGS_PATH})
    file(STRINGS ${SETTINGS_PATH} FILE_ENTRIES)  # Settings file split into lines

    foreach(FILE_ENTRY ${FILE_ENTRIES})
        if("${FILE_ENTRY}" MATCHES "^[^#]+=.*")
            string(REGEX MATCH "^[^=]+" SETTING_NAME  ${FILE_ENTRY})
            string(REGEX MATCH "[^=]+$" SETTING_VALUE ${FILE_ENTRY})
            string(REPLACE "." ";" ENTRY_NAME_TOKENS ${SETTING_NAME})
            string(STRIP "${SETTING_VALUE}" SETTING_VALUE)

            list(LENGTH ENTRY_NAME_TOKENS ENTRY_NAME_TOKENS_LEN)

            # Add entry to settings list if it does not exist
            list(GET ENTRY_NAME_TOKENS 0 ENTRY_NAME)
            list(FIND ${SETTINGS_LIST} ${ENTRY_NAME} ENTRY_NAME_INDEX)
            if(ENTRY_NAME_INDEX LESS 0)
                # Add entry to main list
                list(APPEND ${SETTINGS_LIST} ${ENTRY_NAME})
            endif()

            # Add entry setting to entry settings list if it does not exist
            set(ENTRY_SETTING_LIST ${ENTRY_NAME}.SETTINGS)
            list(GET ENTRY_NAME_TOKENS 1 ENTRY_SETTING)
            list(FIND ${ENTRY_SETTING_LIST} ${ENTRY_SETTING} ENTRY_SETTING_INDEX)
            if(ENTRY_SETTING_INDEX LESS 0)
                # Add setting to entry
                list(APPEND ${ENTRY_SETTING_LIST} ${ENTRY_SETTING})
                set(${ENTRY_SETTING_LIST} ${${ENTRY_SETTING_LIST}}
                    CACHE INTERNAL "Energia ${ENTRY_NAME} Board settings list")
            endif()

            set(FULL_SETTING_NAME ${ENTRY_NAME}.${ENTRY_SETTING})

            # Add entry sub-setting to entry sub-settings list if it does not exists
            if(ENTRY_NAME_TOKENS_LEN GREATER 2)
                set(ENTRY_SUBSETTING_LIST ${ENTRY_NAME}.${ENTRY_SETTING}.SUBSETTINGS)
                list(GET ENTRY_NAME_TOKENS 2 ENTRY_SUBSETTING)
                list(FIND ${ENTRY_SUBSETTING_LIST} ${ENTRY_SUBSETTING} ENTRY_SUBSETTING_INDEX)
                if(ENTRY_SUBSETTING_INDEX LESS 0)
                    list(APPEND ${ENTRY_SUBSETTING_LIST} ${ENTRY_SUBSETTING})
                    set(${ENTRY_SUBSETTING_LIST}  ${${ENTRY_SUBSETTING_LIST}}
                        CACHE INTERNAL "Energia ${ENTRY_NAME} Board sub-settings list")
                endif()
                set(FULL_SETTING_NAME ${FULL_SETTING_NAME}.${ENTRY_SUBSETTING})
            endif()

            # Save setting value
            set(${FULL_SETTING_NAME} ${SETTING_VALUE}
                CACHE INTERNAL "Energia ${ENTRY_NAME} Board setting")


        endif()
    endforeach()
    set(${SETTINGS_LIST} ${${SETTINGS_LIST}}
        CACHE STRING "List of detected Energia Board configurations")
    mark_as_advanced(${SETTINGS_LIST})
    endif()
endfunction()

#=============================================================================#
# [PUBLIC/USER]
# see documentation at top
#=============================================================================#
function(REGISTER_HARDWARE_PLATFORM PLATFORM_PATH)
	string(REGEX REPLACE "/$" "" PLATFORM_PATH ${PLATFORM_PATH})
	GET_FILENAME_COMPONENT(PLATFORM_PATH ${PLATFORM_PATH} ABSOLUTE)
	GET_FILENAME_COMPONENT(PLATFORM_ARCH ${PLATFORM_PATH} NAME)

	GET_FILENAME_COMPONENT(PLATFORM_PARENT_PATH ${PLATFORM_PATH} PATH)

    set(PLATFORM "${PLATFORM_ARCH}")
    set(PLATFORM_ARCH "")

    if(PLATFORM)
        string(TOUPPER ${PLATFORM} PLATFORM)
        list(FIND ENERGIA_PLATFORMS ${PLATFORM} platform_exists)

        if (platform_exists EQUAL -1)
            set(${PLATFORM}_PLATFORM_PATH ${PLATFORM_PATH} CACHE INTERNAL "The path to ${PLATFORM}")
            set(ENERGIA_PLATFORMS ${ENERGIA_PLATFORMS} ${PLATFORM} CACHE INTERNAL "A list of registered platforms")

            find_file(${PLATFORM}_CORES_PATH
                  NAMES cores
                  PATHS ${PLATFORM_PATH}
                  DOC "Path to directory containing the Energia core sources.")

            find_file(${PLATFORM}_VARIANTS_PATH
                  NAMES variants
                  PATHS ${PLATFORM_PATH}
                  DOC "Path to directory containing the Energia variant sources.")

#            find_file(${PLATFORM}_BOOTLOADERS_PATH
#                  NAMES bootloaders
#                  PATHS ${PLATFORM_PATH}
#                  DOC "Path to directory containing the Energia bootloader images and sources.")

            find_file(${PLATFORM}_PROGRAMMERS_PATH
                NAMES programmers.txt
                PATHS ${PLATFORM_PATH}
                DOC "Path to Energia programmers definition file.")

            find_file(${PLATFORM}_BOARDS_PATH
                NAMES boards.txt
                PATHS ${PLATFORM_PATH}
                DOC "Path to Energia boards definition file.")

            if(${PLATFORM}_BOARDS_PATH)
                load_energia_style_settings(${PLATFORM}_BOARDS "${PLATFORM_PATH}/boards.txt")
            endif()

            if(${PLATFORM}_PROGRAMMERS_PATH)
                load_energia_style_settings(${PLATFORM}_PROGRAMMERS "${ENERGIA_PROGRAMMERS_PATH}")
            endif()

            if(${PLATFORM}_VARIANTS_PATH)
                file(GLOB sub-dir ${${PLATFORM}_VARIANTS_PATH}/*)
                foreach(dir ${sub-dir})
                    if(IS_DIRECTORY ${dir})
                        get_filename_component(variant ${dir} NAME)
                        set(VARIANTS ${VARIANTS} ${variant} CACHE INTERNAL "A list of registered variant boards")
                        set(${variant}.path ${dir} CACHE INTERNAL "The path to the variant ${variant}")
                    endif()
                endforeach()
            endif()

            if(${PLATFORM}_CORES_PATH)
                file(GLOB sub-dir ${${PLATFORM}_CORES_PATH}/*)
                foreach(dir ${sub-dir})
                    if(IS_DIRECTORY ${dir})
                        get_filename_component(core ${dir} NAME)
                        set(CORES ${CORES} ${core} CACHE INTERNAL "A list of registered cores")
                        set(${core}.path ${dir} CACHE INTERNAL "The path to the core ${core}")
                    endif()
                endforeach()
            endif()

            foreach(board ${${PLATFORM}_BOARDS})
                set(${board}.platform ${PLATFORM} CACHE INTERNAL "The ${board}'s platform")
            endforeach()

        endif()
    endif()
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# get_energia_flags(COMPILE_FLAGS LINK_FLAGS BOARD_ID MANUAL)
#
#       COMPILE_FLAGS_VAR -Variable holding compiler flags
#       LINK_FLAGS_VAR - Variable holding linker flags
#       BOARD_ID - The board id name
#       MANUAL - (Advanced) Only use AVR Libc/Includes
#
# Configures the the build settings for the specified Energia Board.
#
#=============================================================================#
function(get_energia_flags COMPILE_FLAGS_VAR LINK_FLAGS_VAR BOARD_ID MANUAL)

    set(BOARD_CORE ${${BOARD_ID}.build.core})
    if(BOARD_CORE)
        set(ARDUINO_VER "${ENERGIA_SDK_VERSION_ARDUINO}")
        set(ENERGIA_VER "${ENERGIA_SDK_VERSION_ENERGIA}")
        # output
        set(COMPILE_FLAGS " -mcpu=${${BOARD_ID}.build.mcu} -DF_CPU=${${BOARD_ID}.build.f_cpu} -MMD -DARDUINO=${ARDUINO_VER} -DENERGIA=${ENERGIA_VER} ")
        if(DEFINED ${BOARD_ID}.build.vid)
            set(COMPILE_FLAGS "${COMPILE_FLAGS} -DUSB_VID=${${BOARD_ID}.build.vid}")
        endif()
        if(DEFINED ${BOARD_ID}.build.pid)
            set(COMPILE_FLAGS "${COMPILE_FLAGS} -DUSB_PID=${${BOARD_ID}.build.pid}")
        endif()
        if(NOT MANUAL)
			set(COMPILE_FLAGS "${COMPILE_FLAGS} -I\"${${BOARD_CORE}.path}\"")
			foreach(LIBRARY_PATH ${ENERGIA_LIBRARIES_PATH})
				set(COMPILE_FLAGS "${COMPILE_FLAGS} -I\"${LIBRARY_PATH}\"")
			endforeach()
        endif()

        set(LINK_FLAGS "-mcpu=${${BOARD_ID}.build.mcu}")

        # add ldscript to link flags if exists
        if (${BOARD_ID}.ldscript)
            if (NOT DEFINED ${BOARD_ID}.ldscript.path)
               find_file(${BOARD_ID}.ldscript.path
                        NAMES ${${BOARD_ID}.ldscript}
                        PATHS ${${${BOARD_ID}.platform}_PLATFORM_PATH}
                              ${${${BOARD_ID}.build.core}.path}
                        DOC "${BOARD_ID}'s ldscript pth.")
            endif()
            if (${BOARD_ID}.ldscript.path)
                set(LINK_FLAGS "${LINK_FLAGS} -T ${${BOARD_ID}.ldscript.path}")
            endif()
        endif()

        if(ENERGIA_VER VERSION_GREATER 15 OR ENERGIA_VER VERSION_EQUAL 15)
            if(NOT MANUAL)
                set(PIN_HEADER ${${${BOARD_ID}.build.variant}.path})
                if(PIN_HEADER)
                    set(COMPILE_FLAGS "${COMPILE_FLAGS} -I\"${PIN_HEADER}\"")
                endif()
            endif()
        endif()

        # add -c to tell compiler compile but not link
        set(COMPILE_FLAGS "-c ${COMPILE_FLAGS}")

        # output
        set(${COMPILE_FLAGS_VAR} "${COMPILE_FLAGS}" PARENT_SCOPE)
        set(${LINK_FLAGS_VAR} "${LINK_FLAGS}" PARENT_SCOPE)

    else()
        message(FATAL_ERROR "Invalid Energia board ID (${BOARD_ID}), aborting.")
    endif()
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_energia_core(VAR_NAME BOARD_ID)
#
#        VAR_NAME    - Variable name that will hold the generated library name
#        BOARD_ID    - Energia board id
#
# Creates the Energia Core library for the specified board,
# each board gets it's own version of the library.
#
#=============================================================================#
function(setup_energia_core VAR_NAME BOARD_ID)
    set(CORE_LIB_NAME ${BOARD_ID}_CORE)
    set(BOARD_CORE ${${BOARD_ID}.build.core})
    if(BOARD_CORE)
        if(NOT TARGET ${CORE_LIB_NAME})
            set(BOARD_CORE_PATH ${${BOARD_CORE}.path})
            find_sources(CORE_SRCS ${BOARD_CORE_PATH} True)
            # Debian/Ubuntu fix
            list(REMOVE_ITEM CORE_SRCS "${BOARD_CORE_PATH}/main.cxx")
            add_library(${CORE_LIB_NAME} ${CORE_SRCS})
            get_energia_flags(ENERGIA_COMPILE_FLAGS ENERGIA_LINK_FLAGS ${BOARD_ID} FALSE)
            set_target_properties(${CORE_LIB_NAME} PROPERTIES
                COMPILE_FLAGS "${ENERGIA_COMPILE_FLAGS}"
                LINK_FLAGS "${ENERGIA_LINK_FLAGS}")
        endif()
        set(${VAR_NAME} ${CORE_LIB_NAME} PARENT_SCOPE)
    endif()
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# find_energia_libraries(VAR_NAME SRCS ARDLIBS)
#
#      VAR_NAME - Variable name which will hold the results
#      SRCS     - Sources that will be analized
#      ARDLIBS  - Energia libraries identified by name (e.g., Wire, SPI, Servo)
#
#     returns a list of paths to libraries found.
#
#  Finds all Energia type libraries included in sources. Available libraries
#  are ${ENERGIA_SDK_PATH}/libraries and ${CMAKE_CURRENT_SOURCE_DIR}.
#
#  Also adds Energia libraries specifically names in ALIBS.  We add ".h" to the
#  names and then process them just like the Energia libraries found in the sources.
#
#  A Energia library is a folder that has the same name as the include header.
#  For example, if we have a include "#include <LibraryName.h>" then the following
#  directory structure is considered a Energia library:
#
#     LibraryName/
#          |- LibraryName.h
#          `- LibraryName.c
#
#  If such a directory is found then all sources within that directory are considred
#  to be part of that Energia library.
#
#=============================================================================#
function(find_energia_libraries VAR_NAME SRCS ARDLIBS)
    set(ENERGIA_LIBS )
    foreach(SRC ${SRCS})

        # Skipping generated files. They are, probably, not exist yet.
        # TODO: Maybe it's possible to skip only really nonexisting files,
        # but then it wiil be less deterministic.
        get_source_file_property(_srcfile_generated ${SRC} GENERATED)
        # Workaround for sketches, which are marked as generated
        get_source_file_property(_sketch_generated ${SRC} GENERATED_SKETCH)

        if(NOT ${_srcfile_generated} OR ${_sketch_generated})

            if(NOT (EXISTS ${SRC} OR
                    EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${SRC} OR
                    EXISTS ${CMAKE_CURRENT_BINARY_DIR}/${SRC}))
                message(FATAL_ERROR "Invalid source file: ${SRC}")
            endif()
            file(STRINGS ${SRC} SRC_CONTENTS)

            foreach(LIBNAME ${ARDLIBS})
                list(APPEND SRC_CONTENTS "#include <${LIBNAME}.h>")
            endforeach()

            foreach(SRC_LINE ${SRC_CONTENTS})
                if("${SRC_LINE}" MATCHES "^[ \t]*#[ \t]*include[ \t]*[<\"]([^>\"]*)[>\"]")
                    get_filename_component(INCLUDE_NAME ${CMAKE_MATCH_1} NAME_WE)
                    get_property(LIBRARY_SEARCH_PATH
                                 DIRECTORY     # Property Scope
                                 PROPERTY LINK_DIRECTORIES)

                    foreach(LIB_SEARCH_PATH ${LIBRARY_SEARCH_PATH} ${ENERGIA_LIBRARIES_PATH} ${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/libraries ${ENERGIA_EXTRA_LIBRARIES_PATH})

                        if(EXISTS ${LIB_SEARCH_PATH}/${INCLUDE_NAME}/${CMAKE_MATCH_1})
                            list(APPEND ENERGIA_LIBS ${LIB_SEARCH_PATH}/${INCLUDE_NAME})
                            break()
                        endif()
                        if(EXISTS ${LIB_SEARCH_PATH}/${CMAKE_MATCH_1})
                            list(APPEND ENERGIA_LIBS ${LIB_SEARCH_PATH})
                            break()
                        endif()
                    endforeach()
                endif()
            endforeach()
        endif()
    endforeach()
    if(ENERGIA_LIBS)
        list(REMOVE_DUPLICATES ENERGIA_LIBS)
    endif()
    set(${VAR_NAME} ${ENERGIA_LIBS} PARENT_SCOPE)
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_energia_library(VAR_NAME BOARD_ID LIB_PATH COMPILE_FLAGS LINK_FLAGS)
#
#        VAR_NAME    - Vairable wich will hold the generated library names
#        BOARD_ID    - Board ID
#        LIB_PATH    - Path of the library
#        COMPILE_FLAGS - Compile flags
#        LINK_FLAGS    - Link flags
#
# Creates an Energia library, with all it's library dependencies.
#
#      ${LIB_NAME}_RECURSE controls if the library will recurse
#      when looking for source files.
#
#=============================================================================#

# For known libraries can list recurse here
set(Wire_RECURSE True)
set(Ethernet_RECURSE True)
set(SD_RECURSE True)
set(WiFi_RECURSE True)
#set(OxMqtt_RECURSE True)
function(setup_energia_library VAR_NAME BOARD_ID LIB_PATH COMPILE_FLAGS LINK_FLAGS)
    set(LIB_TARGETS)
    set(LIB_INCLUDES)

    get_filename_component(LIB_NAME ${LIB_PATH} NAME)

    set(TARGET_LIB_NAME ${BOARD_ID}_${LIB_NAME})
    if(NOT TARGET ${TARGET_LIB_NAME})
        string(REGEX REPLACE ".*/" "" LIB_SHORT_NAME ${LIB_NAME})

        # Detect if recursion is needed
        if (NOT DEFINED ${LIB_SHORT_NAME}_RECURSE)
            set(${LIB_SHORT_NAME}_RECURSE False)
        endif()

        find_sources(LIB_SRCS ${LIB_PATH} ${${LIB_SHORT_NAME}_RECURSE})
        if(LIB_SRCS)

            energia_debug_msg("Generating Energia ${LIB_NAME} library")

            add_library(${TARGET_LIB_NAME} STATIC ${LIB_SRCS})

            get_energia_flags(ENERGIA_COMPILE_FLAGS ENERGIA_LINK_FLAGS ${BOARD_ID} FALSE)

            find_energia_libraries(LIB_DEPS "${LIB_SRCS}" "")

            foreach(LIB_DEP ${LIB_DEPS})
                setup_energia_library(DEP_LIB_SRCS ${BOARD_ID} ${LIB_DEP} "${COMPILE_FLAGS}" "${LINK_FLAGS}")
                list(APPEND LIB_TARGETS ${DEP_LIB_SRCS})
                list(APPEND LIB_INCLUDES ${DEP_LIB_SRCS_INCLUDES})
            endforeach()

            if (LIB_INCLUDES)
                string(REPLACE ";" " " LIB_INCLUDES "${LIB_INCLUDES}")
            endif()

            set_target_properties(${TARGET_LIB_NAME} PROPERTIES
                COMPILE_FLAGS "${ENERGIA_COMPILE_FLAGS} ${LIB_INCLUDES} -I\"${LIB_PATH}\" -I\"${LIB_PATH}/utility\" ${COMPILE_FLAGS}"
                LINK_FLAGS "${ENERGIA_LINK_FLAGS} ${LINK_FLAGS}")
            list(APPEND LIB_INCLUDES "-I\"${LIB_PATH}\" -I\"${LIB_PATH}/utility\"")

            target_link_libraries(${TARGET_LIB_NAME} ${BOARD_ID}_CORE)
            list(APPEND LIB_TARGETS ${TARGET_LIB_NAME})

        endif()
    else()
        # Target already exists, skiping creating
        list(APPEND LIB_TARGETS ${TARGET_LIB_NAME})
    endif()
    if(LIB_TARGETS)
        list(REMOVE_DUPLICATES LIB_TARGETS)
    endif()
    set(${VAR_NAME}          ${LIB_TARGETS}  PARENT_SCOPE)
    set(${VAR_NAME}_INCLUDES ${LIB_INCLUDES} PARENT_SCOPE)
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_energia_libraries(VAR_NAME BOARD_ID SRCS COMPILE_FLAGS LINK_FLAGS)
#
#        VAR_NAME    - Vairable wich will hold the generated library names
#        BOARD_ID    - Board ID
#        SRCS        - source files
#        COMPILE_FLAGS - Compile flags
#        LINK_FLAGS    - Linker flags
#
# Finds and creates all dependency libraries based on sources.
#
#=============================================================================#
function(setup_energia_libraries VAR_NAME BOARD_ID SRCS ARDLIBS COMPILE_FLAGS LINK_FLAGS)
    set(LIB_TARGETS)
    set(LIB_INCLUDES)
    set(LIB_DIRS)

    find_energia_libraries(TARGET_LIBS "${SRCS}" ARDLIBS)
    foreach(TARGET_LIB ${TARGET_LIBS})
        # Create static library instead of returning sources
        setup_energia_library(LIB_DEPS ${BOARD_ID} ${TARGET_LIB} "${COMPILE_FLAGS}" "${LINK_FLAGS}")
        list(APPEND LIB_TARGETS ${LIB_DEPS})
        list(APPEND LIB_INCLUDES ${LIB_DEPS_INCLUDES})
        list(APPEND LIB_DIRS ${TARGET_LIB})
    endforeach()

    set(${VAR_NAME}          ${LIB_TARGETS}  PARENT_SCOPE)
    set(${VAR_NAME}_INCLUDES ${LIB_INCLUDES} PARENT_SCOPE)

endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_energia_target(TARGET_NAME ALL_SRCS ALL_LIBS COMPILE_FLAGS LINK_FLAGS MANUAL)
#
#        TARGET_NAME - Target name
#        BOARD_ID    - Energia board ID
#        ALL_SRCS    - All sources
#        ALL_LIBS    - All libraries
#        COMPILE_FLAGS - Compile flags
#        LINK_FLAGS    - Linker flags
#        MANUAL - (Advanced) Only use AVR Libc/Includes
#
# Creates an Energia firmware target.
#
#=============================================================================#
function(setup_energia_target TARGET_NAME BOARD_ID ALL_SRCS ALL_LIBS COMPILE_FLAGS LINK_FLAGS MANUAL)

    add_executable(${TARGET_NAME} ${ALL_SRCS})

    set_target_properties(${TARGET_NAME} PROPERTIES SUFFIX ".elf")

    get_energia_flags(ENERGIA_COMPILE_FLAGS ENERGIA_LINK_FLAGS ${BOARD_ID} ${MANUAL})

    set_target_properties(${TARGET_NAME} PROPERTIES
                COMPILE_FLAGS "${ENERGIA_COMPILE_FLAGS} ${COMPILE_FLAGS}"
                LINK_FLAGS "${ENERGIA_LINK_FLAGS} ${LINK_FLAGS}")
    target_link_libraries(${TARGET_NAME} ${ALL_LIBS} "-lc -lm -lgcc")

    if(NOT EXECUTABLE_OUTPUT_PATH)
      set(EXECUTABLE_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR})
    endif()
    set(TARGET_PATH ${EXECUTABLE_OUTPUT_PATH}/${TARGET_NAME})
    # Convert firmware image to BIN format
    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
                        COMMAND ${CMAKE_OBJCOPY}
                        ARGS    ${ENERGIA_OBJCOPY_BIN_FLAGS}
                                ${TARGET_PATH}.elf
                                ${TARGET_PATH}.bin
                        COMMENT "Generating BIN image"
                        VERBATIM)

    # Display target size
    # TODO
    add_custom_command(TARGET ${TARGET_NAME} POST_BUILD
                        COMMAND ${SIZE_PROGRAM}
                        ARGS    ${TARGET_PATH}.elf
                        COMMENT "Calculating image size"
                        VERBATIM)

    # Create ${TARGET_NAME}-size target
    add_custom_target(${TARGET_NAME}-size
                        COMMAND ${SIZE_PROGRAM}
                                ${TARGET_PATH}.elf
                        DEPENDS ${TARGET_NAME}
                        COMMENT "Calculating ${TARGET_NAME} image size")

endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_energia_upload(BOARD_ID TARGET_NAME PORT)
#
#        BOARD_ID    - Arduino board id
#        TARGET_NAME - Target name
#        PORT        - Serial port for upload
#        PROGRAMMER_ID - Programmer ID
#        UPLOAD_FLAGS - avrdude flags
#
# Create an upload target (${TARGET_NAME}-upload) for the specified Arduino target.
#
#=============================================================================#
function(setup_energia_upload BOARD_ID TARGET_NAME PORT PROGRAMMER_ID UPLOAD_FLAGS)
#    message(" - XXX " ${TARGET_NAME})
#    message(" - XXX " ${BOARD_ID})
#    message(" - XXX " ${PROGRAMMER_ID})
#    message(" - XXX " ${PORT})
#    message(" - XXX " ${UPLOAD_FLAGS})
    setup_energia_programmer_burn(${TARGET_NAME} ${BOARD_ID} ${PROGRAMMER_ID} ${PORT} "${UPLOAD_FLAGS}")
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_energia_programmer_burn(TARGET_NAME BOARD_ID PROGRAMMER PORT UPLOAD_FLAGS)
#
#      TARGET_NAME - name of target to burn
#      BOARD_ID    - board id
#      PROGRAMMER  - programmer id
#      PORT        - serial port
#      UPLOAD_FLAGS - upload flags (override)
#
# Sets up target for burning firmware via a programmer.
#
# The target for burning the firmware is ${TARGET_NAME}-burn .
#
#=============================================================================#
function(setup_energia_programmer_burn TARGET_NAME BOARD_ID PROGRAMMER PORT UPLOAD_FLAGS)

    set(PROGRAMMER_TARGET ${TARGET_NAME}-burn)

    set(UPLOAD_TOOL "cc3200prog")
    if (${BOARD_ID}.upload.tool)
        set(UPLOAD_TOOL ${${BOARD_ID}.upload.tool})
    endif()

    find_program(UPLOAD_PROGRAM
        NAMES ${UPLOAD_TOOL}
        PATHS ${ENERGIA_SDK_PATH}
        PATH_SUFFIXES hardware/tools hardware/tools/lm4f/bin
        NO_DEFAULT_PATH)

    if (NOT UPLOAD_PROGRAM)
        message("Could not find upload program \"${UPLOAD_TOOL}\", aborting!")
        return()
    endif()

    GET_FILENAME_COMPONENT(WORKING_DIRECTORY ${UPLOAD_PROGRAM} DIRECTORY)

    set(UPLOAD_ARGS)

    setup_energia_programmer_args(${BOARD_ID} ${PROGRAMMER} ${TARGET_NAME} ${PORT} "${UPLOAD_FLAGS}" UPLOAD_ARGS)

    if(NOT UPLOAD_ARGS)
        message("Could not generate default avrdude programmer args, aborting!")
        return()
    endif()

    if(NOT EXECUTABLE_OUTPUT_PATH)
      set(EXECUTABLE_OUTPUT_PATH ${CMAKE_CURRENT_BINARY_DIR})
    endif()
    set(TARGET_PATH ${EXECUTABLE_OUTPUT_PATH}/${TARGET_NAME})

    list(APPEND UPLOAD_ARGS "${TARGET_PATH}.bin")

    add_custom_target(${PROGRAMMER_TARGET}
                     ${UPLOAD_PROGRAM}
                     ${UPLOAD_ARGS}
                     WORKING_DIRECTORY ${WORKING_DIRECTORY}
                     DEPENDS ${TARGET_NAME})
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_energia_programmer_args(BOARD_ID PROGRAMMER TARGET_NAME PORT UPLOAD_FLAGS OUTPUT_VAR)
#
#      BOARD_ID    - board id
#      PROGRAMMER  - programmer id
#      TARGET_NAME - target name
#      PORT        - serial port
#      UPLOAD_FLAGS - avrdude flags (override)
#      OUTPUT_VAR  - name of output variable for result
#
# Sets up default avrdude settings for burning firmware via a programmer.
#=============================================================================#
function(setup_energia_programmer_args BOARD_ID PROGRAMMER TARGET_NAME PORT UPLOAD_FLAGS OUTPUT_VAR)
    set(UPLOAD_ARGS ${${OUTPUT_VAR}})

#    if(NOT UPLOAD_FLAGS)
#        set(UPLOAD_FLAGS ${ENERGIA_UPLOAD_FLAGS})
#    endif()
#
#    list(APPEND UPLOAD_ARGS "-C${ARDUINO_AVRDUDE_CONFIG_PATH}")
#
#    #TODO: Check mandatory settings before continuing
#    if(NOT ${PROGRAMMER}.protocol)
#        message(FATAL_ERROR "Missing ${PROGRAMMER}.protocol, aborting!")
#    endif()
#
#    list(APPEND UPLOAD_ARGS "-c${${PROGRAMMER}.protocol}") # Set programmer


    list(APPEND UPLOAD_ARGS "${PORT}") # Set port

#    if(${PROGRAMMER}.force)
#        list(APPEND UPLOAD_ARGS "-F") # Set forc
#    endif()
#
#    if(${PROGRAMMER}.delay)
#        list(APPEND UPLOAD_ARGS "-i${${PROGRAMMER}.delay}") # Set delay
#    endif()
#
#    list(APPEND UPLOAD_ARGS "-p${${BOARD_ID}.build.mcu}")  # MCU Type
#
#    list(APPEND UPLOAD_ARGS ${UPLOAD_FLAGS})

    set(${OUTPUT_VAR} ${UPLOAD_ARGS} PARENT_SCOPE)

endfunction()

#=============================================================================#
# include_energia_libs(TARGET_NAME DEP_LIBS)
#
#      TARGET_NAME - name of target
#      DEP_LIBS    - dependency libraries
#
#=============================================================================#
function(include_energia_libs TARGET_NAME DEP_LIBS)
    set(${TARGET_NAME}_DEP_LIBS ${DEP_LIBS} CACHE PATH "The ${INPUT_NAME} dependencies libraries")
    include_directories(${${TARGET_NAME}_DEP_LIBS})
endfunction()

#=============================================================================#
# print_settings(ENTRY_NAME)
#
#      ENTRY_NAME - name of entry
#
# Print the entry settings (see load_energia_syle_settings()).
#
#=============================================================================#
function(PRINT_SETTINGS ENTRY_NAME)
    if(${ENTRY_NAME}.SETTINGS)

        foreach(ENTRY_SETTING ${${ENTRY_NAME}.SETTINGS})
            if(${ENTRY_NAME}.${ENTRY_SETTING})
                message(STATUS "   ${ENTRY_NAME}.${ENTRY_SETTING}=${${ENTRY_NAME}.${ENTRY_SETTING}}")
            endif()
            if(${ENTRY_NAME}.${ENTRY_SETTING}.SUBSETTINGS)
                foreach(ENTRY_SUBSETTING ${${ENTRY_NAME}.${ENTRY_SETTING}.SUBSETTINGS})
                    if(${ENTRY_NAME}.${ENTRY_SETTING}.${ENTRY_SUBSETTING})
                        message(STATUS "   ${ENTRY_NAME}.${ENTRY_SETTING}.${ENTRY_SUBSETTING}=${${ENTRY_NAME}.${ENTRY_SETTING}.${ENTRY_SUBSETTING}}")
                    endif()
                endforeach()
            endif()
            message(STATUS "")
        endforeach()
    endif()
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# print_list(SETTINGS_LIST)
#
#      SETTINGS_LIST - Variables name of settings list
#
# Print list settings and names (see load_energia_syle_settings()).
#=============================================================================#
function(PRINT_LIST SETTINGS_LIST)
    if(${SETTINGS_LIST})
        set(MAX_LENGTH 0)
        foreach(ENTRY_NAME ${${SETTINGS_LIST}})
            string(LENGTH "${ENTRY_NAME}" CURRENT_LENGTH)
            if(CURRENT_LENGTH GREATER MAX_LENGTH)
                set(MAX_LENGTH ${CURRENT_LENGTH})
            endif()
        endforeach()
        foreach(ENTRY_NAME ${${SETTINGS_LIST}})
            string(LENGTH "${ENTRY_NAME}" CURRENT_LENGTH)
            math(EXPR PADDING_LENGTH "${MAX_LENGTH}-${CURRENT_LENGTH}")
            set(PADDING "")
            foreach(X RANGE ${PADDING_LENGTH})
                set(PADDING "${PADDING} ")
            endforeach()
            message(STATUS "   ${PADDING}${ENTRY_NAME}: ${${ENTRY_NAME}.name}")
        endforeach()
    endif()
endfunction()



#=============================================================================#
# [PRIVATE/INTERNAL]
#
# setup_energia_sketch(TARGET_NAME SKETCH_PATH OUTPUT_VAR)
#
#      TARGET_NAME - Target name
#      SKETCH_PATH - Path to sketch directory
#      OUTPUT_VAR  - Variable name where to save generated sketch source
#
# Generates C++ sources from Arduino Sketch.
#=============================================================================#
function(SETUP_ENERGIA_SKETCH TARGET_NAME SKETCH_PATH OUTPUT_VAR)
    get_filename_component(SKETCH_NAME "${SKETCH_PATH}" NAME)
    get_filename_component(SKETCH_PATH "${SKETCH_PATH}" ABSOLUTE)

    if(EXISTS "${SKETCH_PATH}")
        set(SKETCH_CPP  ${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}_${SKETCH_NAME}.cpp)

        if (IS_DIRECTORY "${SKETCH_PATH}")
            # Sketch directory specified, try to find main sketch...
            set(MAIN_SKETCH ${SKETCH_PATH}/${SKETCH_NAME})

            if(EXISTS "${MAIN_SKETCH}.pde")
                set(MAIN_SKETCH "${MAIN_SKETCH}.pde")
            elseif(EXISTS "${MAIN_SKETCH}.ino")
                set(MAIN_SKETCH "${MAIN_SKETCH}.ino")
            else()
                message(FATAL_ERROR "Could not find main sketch (${SKETCH_NAME}.pde or ${SKETCH_NAME}.ino) at ${SKETCH_PATH}! Please specify the main sketch file path instead of directory.")
            endif()
        else()
            # Sektch file specified, assuming parent directory as sketch directory
            set(MAIN_SKETCH ${SKETCH_PATH})
            get_filename_component(SKETCH_PATH "${SKETCH_PATH}" PATH)
        endif()
        energia_debug_msg("sketch: ${MAIN_SKETCH}")

        # Find all sketch files
        file(GLOB SKETCH_SOURCES ${SKETCH_PATH}/*.pde ${SKETCH_PATH}/*.ino)
        list(REMOVE_ITEM SKETCH_SOURCES ${MAIN_SKETCH})
        list(SORT SKETCH_SOURCES)

        generate_cpp_from_sketch("${MAIN_SKETCH}" "${SKETCH_SOURCES}" "${SKETCH_CPP}")

        # Regenerate build system if sketch changes
        add_custom_command(OUTPUT ${SKETCH_CPP}
                           COMMAND ${CMAKE_COMMAND} ${CMAKE_SOURCE_DIR}
                           WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
                           DEPENDS ${MAIN_SKETCH} ${SKETCH_SOURCES}
                           COMMENT "Regnerating ${SKETCH_NAME} Sketch")
        set_source_files_properties(${SKETCH_CPP} PROPERTIES GENERATED TRUE)
        # Mark file that it exists for find_file
        set_source_files_properties(${SKETCH_CPP} PROPERTIES GENERATED_SKETCH TRUE)

        set("${OUTPUT_VAR}" ${${OUTPUT_VAR}} ${SKETCH_CPP} PARENT_SCOPE)
    else()
        message(FATAL_ERROR "Sketch does not exist: ${SKETCH_PATH}")
    endif()
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# generate_cpp_from_sketch(MAIN_SKETCH_PATH SKETCH_SOURCES SKETCH_CPP)
#
#         MAIN_SKETCH_PATH - Main sketch file path
#         SKETCH_SOURCES   - Setch source paths
#         SKETCH_CPP       - Name of file to generate
#
# Generate C++ source file from Arduino sketch files.
#=============================================================================#
function(GENERATE_CPP_FROM_SKETCH MAIN_SKETCH_PATH SKETCH_SOURCES SKETCH_CPP)
    file(WRITE ${SKETCH_CPP} "// automatically generated by energia-cmake\n")
    file(READ  ${MAIN_SKETCH_PATH} MAIN_SKETCH)

    # remove comments
    remove_comments(MAIN_SKETCH MAIN_SKETCH_NO_COMMENTS)

    # find first statement
    string(REGEX MATCH "[\n][_a-zA-Z0-9]+[^\n]*" FIRST_STATEMENT "${MAIN_SKETCH_NO_COMMENTS}")
    string(FIND "${MAIN_SKETCH}" "${FIRST_STATEMENT}" HEAD_LENGTH)
    if ("${HEAD_LENGTH}" STREQUAL "-1")
        set(HEAD_LENGTH 0)
    endif()
    #message(STATUS "FIRST STATEMENT: ${FIRST_STATEMENT}")
    #message(STATUS "FIRST STATEMENT POSITION: ${HEAD_LENGTH}")
    string(LENGTH "${MAIN_SKETCH}" MAIN_SKETCH_LENGTH)

    string(SUBSTRING "${MAIN_SKETCH}" 0 ${HEAD_LENGTH} SKETCH_HEAD)
    #energia_debug_msg("SKETCH_HEAD:\n${SKETCH_HEAD}")

    # find the body of the main pde
    math(EXPR BODY_LENGTH "${MAIN_SKETCH_LENGTH}-${HEAD_LENGTH}")
    string(SUBSTRING "${MAIN_SKETCH}" "${HEAD_LENGTH}+1" "${BODY_LENGTH}-1" SKETCH_BODY)
    #energia_debug_msg("BODY:\n${SKETCH_BODY}")

    # write the file head
    file(APPEND ${SKETCH_CPP} "#line 1 \"${MAIN_SKETCH_PATH}\"\n${SKETCH_HEAD}")

    # Count head line offset (for GCC error reporting)
    file(STRINGS ${SKETCH_CPP} SKETCH_HEAD_LINES)
    list(LENGTH SKETCH_HEAD_LINES SKETCH_HEAD_LINES_COUNT)
    math(EXPR SKETCH_HEAD_OFFSET "${SKETCH_HEAD_LINES_COUNT}+2")

    # add energia include header
    #file(APPEND ${SKETCH_CPP} "\n#line 1 \"autogenerated\"\n")
    file(APPEND ${SKETCH_CPP} "\n#line ${SKETCH_HEAD_OFFSET} \"${SKETCH_CPP}\"\n")
    file(APPEND ${SKETCH_CPP} "#include \"Arduino.h\"\n")

    # add function prototypes
    foreach(SKETCH_SOURCE_PATH ${SKETCH_SOURCES} ${MAIN_SKETCH_PATH})
        energia_debug_msg("Sketch: ${SKETCH_SOURCE_PATH}")
        file(READ ${SKETCH_SOURCE_PATH} SKETCH_SOURCE)
        remove_comments(SKETCH_SOURCE SKETCH_SOURCE)

        set(ALPHA "a-zA-Z")
        set(NUM "0-9")
        set(ALPHANUM "${ALPHA}${NUM}")
        set(WORD "_${ALPHANUM}")
        set(LINE_START "(^|[\n])")
        set(QUALIFIERS "[ \t]*([${ALPHA}]+[ ])*")
        set(TYPE "[${WORD}]+([ ]*[\n][\t]*|[ ])+")
        set(FNAME "[${WORD}]+[ ]?[\n]?[\t]*[ ]*")
        set(FARGS "[(]([\t]*[ ]*[*&]?[ ]?[${WORD}](\\[([${NUM}]+)?\\])*[,]?[ ]*[\n]?)*([,]?[ ]*[\n]?)?[)]")
        set(BODY_START "([ ]*[\n][\t]*|[ ]|[\n])*{")
        set(PROTOTYPE_PATTERN "${LINE_START}${QUALIFIERS}${TYPE}${FNAME}${FARGS}${BODY_START}")

        string(REGEX MATCHALL "${PROTOTYPE_PATTERN}" SKETCH_PROTOTYPES "${SKETCH_SOURCE}")

        # Write function prototypes
        file(APPEND ${SKETCH_CPP} "\n//=== START Forward: ${SKETCH_SOURCE_PATH}\n")
        foreach(SKETCH_PROTOTYPE ${SKETCH_PROTOTYPES})
            string(REPLACE "\n" " " SKETCH_PROTOTYPE "${SKETCH_PROTOTYPE}")
            string(REPLACE "{" "" SKETCH_PROTOTYPE "${SKETCH_PROTOTYPE}")
            energia_debug_msg("\tprototype: ${SKETCH_PROTOTYPE};")
            # " else if(var == other) {" shoudn't be listed as prototype
            if(NOT SKETCH_PROTOTYPE MATCHES "(if[ ]?[\n]?[\t]*[ ]*[(])")
                file(APPEND ${SKETCH_CPP} "${SKETCH_PROTOTYPE};\n")
            else()
                energia_debug_msg("\trejected prototype: ${SKETCH_PROTOTYPE};")
            endif()
        endforeach()
		file(APPEND ${SKETCH_CPP} "//=== END Forward: ${SKETCH_SOURCE_PATH}\n")
    endforeach()

    # Write Sketch CPP source
    get_num_lines("${SKETCH_HEAD}" HEAD_NUM_LINES)
    file(APPEND ${SKETCH_CPP} "#line ${HEAD_NUM_LINES} \"${MAIN_SKETCH_PATH}\"\n")
    file(APPEND ${SKETCH_CPP} "\n${SKETCH_BODY}")
    foreach (SKETCH_SOURCE_PATH ${SKETCH_SOURCES})
        file(READ ${SKETCH_SOURCE_PATH} SKETCH_SOURCE)
        file(APPEND ${SKETCH_CPP} "\n//=== START : ${SKETCH_SOURCE_PATH}\n")
        file(APPEND ${SKETCH_CPP} "#line 1 \"${SKETCH_SOURCE_PATH}\"\n")
        file(APPEND ${SKETCH_CPP} "${SKETCH_SOURCE}")
        file(APPEND ${SKETCH_CPP} "\n//=== END : ${SKETCH_SOURCE_PATH}\n")
    endforeach()
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# SETUP_SIZE_SCRIPT(OUTPUT_VAR)
#
#        OUTPUT_VAR - Output variable that will contain the script path
#
# Generates script used to display the firmware size.
#=============================================================================#
### !!! NOT WORK NOW !!!
#function(SETUP_SIZE_SCRIPT OUTPUT_VAR)
#    set(SIZE_SCRIPT_PATH ${CMAKE_BINARY_DIR}/CMakeFiles/FirmwareSize.cmake)
#
#    file(WRITE ${SIZE_SCRIPT_PATH} "
#        set(SIZE_FLAGS "")
#
#        execute_process(COMMAND \${SIZE_PROGRAM} \${SIZE_FLAGS} \${FIRMWARE_IMAGE} \${EEPROM_IMAGE}
#                        OUTPUT_VARIABLE SIZE_OUTPUT)
#
#
#        string(STRIP \"\${SIZE_OUTPUT}\" RAW_SIZE_OUTPUT)
#
#        # Convert lines into a list
#        string(REPLACE \"\\n\" \";\" SIZE_OUTPUT_LIST \"\${SIZE_OUTPUT}\")
#
#        set(SIZE_OUTPUT_LINES)
#        foreach(LINE \${SIZE_OUTPUT_LIST})
#            if(NOT \"\${LINE}\" STREQUAL \"\")
#                list(APPEND SIZE_OUTPUT_LINES \"\${LINE}\")
#            endif()
#        endforeach()
#
#        function(EXTRACT LIST_NAME INDEX VARIABLE)
#            list(GET \"\${LIST_NAME}\" \${INDEX} RAW_VALUE)
#            string(STRIP \"\${RAW_VALUE}\" VALUE)
#
#            set(\${VARIABLE} \"\${VALUE}\" PARENT_SCOPE)
#        endfunction()
#        function(PARSE INPUT VARIABLE_PREFIX)
#            if(\${INPUT} MATCHES \"([^:]+):[ \\t]*([0-9]+)[ \\t]*([^ \\t]+)[ \\t]*[(]([0-9.]+)%.*\")
#                set(ENTRY_NAME      \${CMAKE_MATCH_1})
#                set(ENTRY_SIZE      \${CMAKE_MATCH_2})
#                set(ENTRY_SIZE_TYPE \${CMAKE_MATCH_3})
#                set(ENTRY_PERCENT   \${CMAKE_MATCH_4})
#            endif()
#
#            set(\${VARIABLE_PREFIX}_NAME      \${ENTRY_NAME}      PARENT_SCOPE)
#            set(\${VARIABLE_PREFIX}_SIZE      \${ENTRY_SIZE}      PARENT_SCOPE)
#            set(\${VARIABLE_PREFIX}_SIZE_TYPE \${ENTRY_SIZE_TYPE} PARENT_SCOPE)
#            set(\${VARIABLE_PREFIX}_PERCENT   \${ENTRY_PERCENT}   PARENT_SCOPE)
#        endfunction()
#
#        list(LENGTH SIZE_OUTPUT_LINES SIZE_OUTPUT_LENGTH)
#        #message(\"\${SIZE_OUTPUT_LINES}\")
#        #message(\"\${SIZE_OUTPUT_LENGTH}\")
#        if (\${SIZE_OUTPUT_LENGTH} STREQUAL 14)
#            EXTRACT(SIZE_OUTPUT_LINES 3 FIRMWARE_PROGRAM_SIZE_ROW)
#            EXTRACT(SIZE_OUTPUT_LINES 5 FIRMWARE_DATA_SIZE_ROW)
#            PARSE(FIRMWARE_PROGRAM_SIZE_ROW FIRMWARE_PROGRAM)
#            PARSE(FIRMWARE_DATA_SIZE_ROW  FIRMWARE_DATA)
#
#            set(FIRMWARE_STATUS \"Firmware Size: \")
#            set(FIRMWARE_STATUS \"\${FIRMWARE_STATUS} [\${FIRMWARE_PROGRAM_NAME}: \${FIRMWARE_PROGRAM_SIZE} \${FIRMWARE_PROGRAM_SIZE_TYPE} (\${FIRMWARE_PROGRAM_PERCENT}%)] \")
#            set(FIRMWARE_STATUS \"\${FIRMWARE_STATUS} [\${FIRMWARE_DATA_NAME}: \${FIRMWARE_DATA_SIZE} \${FIRMWARE_DATA_SIZE_TYPE} (\${FIRMWARE_DATA_PERCENT}%)]\")
#            set(FIRMWARE_STATUS \"\${FIRMWARE_STATUS} on \${MCU}\")
#
#            EXTRACT(SIZE_OUTPUT_LINES 10 EEPROM_PROGRAM_SIZE_ROW)
#            EXTRACT(SIZE_OUTPUT_LINES 12 EEPROM_DATA_SIZE_ROW)
#            PARSE(EEPROM_PROGRAM_SIZE_ROW EEPROM_PROGRAM)
#            PARSE(EEPROM_DATA_SIZE_ROW  EEPROM_DATA)
#
#            set(EEPROM_STATUS \"EEPROM   Size: \")
#            set(EEPROM_STATUS \"\${EEPROM_STATUS} [\${EEPROM_PROGRAM_NAME}: \${EEPROM_PROGRAM_SIZE} \${EEPROM_PROGRAM_SIZE_TYPE} (\${EEPROM_PROGRAM_PERCENT}%)] \")
#            set(EEPROM_STATUS \"\${EEPROM_STATUS} [\${EEPROM_DATA_NAME}: \${EEPROM_DATA_SIZE} \${EEPROM_DATA_SIZE_TYPE} (\${EEPROM_DATA_PERCENT}%)]\")
#            set(EEPROM_STATUS \"\${EEPROM_STATUS} on \${MCU}\")
#
#            message(\"\${FIRMWARE_STATUS}\")
#            message(\"\${EEPROM_STATUS}\\n\")
#
#            if(\$ENV{VERBOSE})
#                message(\"\${RAW_SIZE_OUTPUT}\\n\")
#            elseif(\$ENV{VERBOSE_SIZE})
#                message(\"\${RAW_SIZE_OUTPUT}\\n\")
#            endif()
#        else()
#            message(\"\${RAW_SIZE_OUTPUT}\")
#        endif()
#    ")
#
#    set(${OUTPUT_VAR} ${SIZE_SCRIPT_PATH} PARENT_SCOPE)
#endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
#  energia_debug_on()
#
# Enables Energia module debugging.
#=============================================================================#
function(ENERGIA_DEBUG_ON)
    set(ENERGIA_DEBUG True PARENT_SCOPE)
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
#  energia_debug_off()
#
# Disables Energia module debugging.
#=============================================================================#
function(ENERGIA_DEBUG_OFF)
    set(ENERGIA_DEBUG False PARENT_SCOPE)
endfunction()


#=============================================================================#
# [PRIVATE/INTERNAL]
#
# energia_debug_msg(MSG)
#
#        MSG - Message to print
#
# Print Energia debugging information. In order to enable printing
# use energia_debug_on() and to disable use energia_debug_off().
#=============================================================================#
function(ENERGIA_DEBUG_MSG MSG)
    if(ENERGIA_DEBUG)
        message("## ${MSG}")
    endif()
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# remove_comments(SRC_VAR OUT_VAR)
#
#        SRC_VAR - variable holding sources
#        OUT_VAR - variable holding sources with no comments
#
# Removes all comments from the source code.
#=============================================================================#
function(REMOVE_COMMENTS SRC_VAR OUT_VAR)
    string(REGEX REPLACE "[\\./\\\\]" "_" FILE "${NAME}")

    set(SRC ${${SRC_VAR}})

    #message(STATUS "removing comments from: ${FILE}")
    #file(WRITE "${CMAKE_BINARY_DIR}/${FILE}_pre_remove_comments.txt" ${SRC})
    #message(STATUS "\n${SRC}")

    # remove all comments
    string(REGEX REPLACE "([/][/][^\n]*)|([/][\\*]([^\\*]|([\\*]+[^/\\*]))*[\\*]+[/])" "" OUT "${SRC}")

    #file(WRITE "${CMAKE_BINARY_DIR}/${FILE}_post_remove_comments.txt" ${SRC})
    #message(STATUS "\n${SRC}")

    set(${OUT_VAR} ${OUT} PARENT_SCOPE)

endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# get_num_lines(DOCUMENT OUTPUT_VAR)
#
#        DOCUMENT   - Document contents
#        OUTPUT_VAR - Variable which will hold the line number count
#
# Counts the line number of the document.
#=============================================================================#
function(GET_NUM_LINES DOCUMENT OUTPUT_VAR)
    string(REGEX MATCHALL "[\n]" MATCH_LIST "${DOCUMENT}")
    list(LENGTH MATCH_LIST NUM)
    set(${OUTPUT_VAR} ${NUM} PARENT_SCOPE)
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# required_variables(MSG msg VARS var1 var2 .. varN)
#
#        MSG  - Message to be displayed in case of error
#        VARS - List of variables names to check
#
# Ensure the specified variables are not empty, otherwise a fatal error is emmited.
#=============================================================================#
function(REQUIRED_VARIABLES)
    cmake_parse_arguments(INPUT "" "MSG" "VARS" ${ARGN})
    error_for_unparsed(INPUT)
    foreach(VAR ${INPUT_VARS})
        if ("${${VAR}}" STREQUAL "")
            message(FATAL_ERROR "${VAR} not set: ${INPUT_MSG}")
        endif()
    endforeach()
endfunction()

#=============================================================================#
# [PRIVATE/INTERNAL]
#
# error_for_unparsed(PREFIX)
#
#        PREFIX - Prefix name
#
# Emit fatal error if there are unparsed argument from cmake_parse_arguments().
#=============================================================================#
function(ERROR_FOR_UNPARSED PREFIX)
    set(ARGS "${${PREFIX}_UNPARSED_ARGUMENTS}")
    if (NOT ( "${ARGS}" STREQUAL "") )
        message(FATAL_ERROR "unparsed argument: ${ARGS}")
    endif()
endfunction()

#=============================================================================#
#                              C Flags
#=============================================================================#
if (NOT DEFINED ENERGIA_C_FLAGS)
    set(ENERGIA_C_FLAGS "-ffunction-sections -fdata-sections -mthumb")
endif (NOT DEFINED ENERGIA_C_FLAGS)
set(CMAKE_C_FLAGS                   "-Os -w   ${ENERGIA_C_FLAGS}" CACHE STRING "")
set(CMAKE_C_FLAGS_DEBUG             "-Os -w   ${ENERGIA_C_FLAGS}" CACHE STRING "")
set(CMAKE_C_FLAGS_MINSIZEREL        "-Os -w   ${ENERGIA_C_FLAGS}" CACHE STRING "")
set(CMAKE_C_FLAGS_RELEASE           "-Os -w   ${ENERGIA_C_FLAGS}" CACHE STRING "")
set(CMAKE_C_FLAGS_RELWITHDEBINFO    "-Os -w   ${ENERGIA_C_FLAGS}" CACHE STRING "")

#=============================================================================#
#                             C++ Flags
#=============================================================================#
if (NOT DEFINED ENERGIA_CXX_FLAGS)
    set(ENERGIA_CXX_FLAGS "${ENERGIA_C_FLAGS} -fno-rtti -fno-exceptions")
endif (NOT DEFINED ENERGIA_CXX_FLAGS)
set(CMAKE_CXX_FLAGS                 "-Os -w    ${ENERGIA_CXX_FLAGS}" CACHE STRING "")
set(CMAKE_CXX_FLAGS_DEBUG           "-Os -w    ${ENERGIA_CXX_FLAGS}" CACHE STRING "")
set(CMAKE_CXX_FLAGS_MINSIZEREL      "-Os -w    ${ENERGIA_CXX_FLAGS}" CACHE STRING "")
set(CMAKE_CXX_FLAGS_RELEASE         "-Os -w    ${ENERGIA_CXX_FLAGS}" CACHE STRING "")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO  "-Os -w    ${ENERGIA_CXX_FLAGS}" CACHE STRING "")

#=============================================================================#
#                       Executable Linker Flags                               #
#=============================================================================#
set(ENERGIA_LINKER_FLAGS "-Os -nostartfiles -nostdlib -Wl,--gc-sections -Wl,--entry=ResetISR -mthumb")
set(CMAKE_EXE_LINKER_FLAGS                "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_EXE_LINKER_FLAGS_DEBUG          "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_EXE_LINKER_FLAGS_MINSIZEREL     "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_EXE_LINKER_FLAGS_RELEASE        "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")

#=============================================================================#
#=============================================================================#
#                       Shared Lbrary Linker Flags                            #
#=============================================================================#
set(CMAKE_SHARED_LINKER_FLAGS                "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_SHARED_LINKER_FLAGS_DEBUG          "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_SHARED_LINKER_FLAGS_MINSIZEREL     "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_SHARED_LINKER_FLAGS_RELEASE        "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")

set(CMAKE_MODULE_LINKER_FLAGS                "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_MODULE_LINKER_FLAGS_DEBUG          "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_MODULE_LINKER_FLAGS_MINSIZEREL     "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_MODULE_LINKER_FLAGS_RELEASE        "${ENERGIA_LINKER_FLAGS}" CACHE STRING "")
set(CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO "${ARDUINO_LINKER_FLAGS}" CACHE STRING "")

#=============================================================================#
#                         Arduino Settings
#=============================================================================#
set(ENERGIA_OBJCOPY_BIN_FLAGS -O binary     CACHE STRING "")
set(ENERGIA_UPLOAD_FLAGS ""                 CACHE STRING "")


#=============================================================================#
#                          Initialization
#=============================================================================#
if(NOT ENERGIA_FOUND AND ENERGIA_SDK_PATH)

    if (NOT ENERGIA_PLATFORM)
        #default core
        set(ENERGIA_PLATFORM "cc3200")
    endif()

    # TODO: check user hardware
    set(ENERGIA_PLATFORM_PATH ${ENERGIA_SDK_PATH}/hardware/${ENERGIA_PLATFORM})

    register_hardware_platform(${ENERGIA_PLATFORM_PATH})

    # Reset libraries
    set(ENERGIA_LIBRARIES_PATH)

    # Include common libraries
    find_file(TMP_ENERGIA_LIBRARIES_PATH
        NAMES libraries
        PATHS ${ENERGIA_USER_PATH}
        DOC "Path to directory containing the Energia user libraries.")

    if (TMP_ENERGIA_LIBRARIES_PATH)
        set(ENERGIA_LIBRARIES_PATH "${ENERGIA_LIBRARIES_PATH}" "${TMP_ENERGIA_LIBRARIES_PATH}")
    endif(TMP_ENERGIA_LIBRARIES_PATH)

    # Include common libraries
    find_file(TMP_ENERGIA_LIBRARIES_PATH_1
        NAMES libraries
        PATHS ${ENERGIA_SDK_PATH}
        DOC "Path to directory containing the Energia libraries.")

    if (TMP_ENERGIA_LIBRARIES_PATH_1)
	    set(ENERGIA_LIBRARIES_PATH "${ENERGIA_LIBRARIES_PATH}" "${TMP_ENERGIA_LIBRARIES_PATH_1}")
	endif(TMP_ENERGIA_LIBRARIES_PATH_1)

    # Include hardware libraries
    find_file(TMP_ENERGIA_LIBRARIES_PATH_2
        NAMES libraries
        PATHS ${ENERGIA_PLATFORM_PATH}
        DOC "Path to directory containing the Energia architecture specific libraries.")
    if (TMP_ENERGIA_LIBRARIES_PATH_2)
        set(ENERGIA_LIBRARIES_PATH "${ENERGIA_LIBRARIES_PATH}" "${TMP_ENERGIA_LIBRARIES_PATH_2}")
    endif(TMP_ENERGIA_LIBRARIES_PATH_2)

    find_file(ENERGIA_VERSION_PATH
        NAMES lib/version.txt
        PATHS ${ENERGIA_SDK_PATH}
        DOC "Path to Energia version file.")

    #  [board].upload.tool
#    find_program(ENERGIA_AVRDUDE_PROGRAM
#        NAMES avrdude
#        PATHS ${ENERGIA_SDK_PATH}
#        PATH_SUFFIXES hardware/tools hardware/tools/avr/bin
#        NO_DEFAULT_PATH)

#    find_program(ENERGIA_AVRDUDE_PROGRAM
#        NAMES avrdude
#        DOC "Path to avrdude programmer binary.")
#
    # TODO costom size_program by board
    find_program(SIZE_PROGRAM
        NAMES arm-none-eabi-size
        PATHS ${ENERGIA_SDK_PATH}
        PATH_SUFFIXES hardware/tools
                      hardware/tools/lm4f/bin)
#
#    find_file(ENERGIA_AVRDUDE_CONFIG_PATH
#        NAMES avrdude.conf
#        PATHS ${ENERGIA_SDK_PATH} /etc/avrdude /etc
#        PATH_SUFFIXES hardware/tools
#                      hardware/tools/avr/etc
#        DOC "Path to avrdude programmer configuration file.")
#


    set(ENERGIA_DEFAULT_BOARD lpcc3200  CACHE STRING "Default Energia Board ID when not specified.")
    set(ENERGIA_DEFAULT_PORT            CACHE STRING "Default Energia port when not specified.")
    set(ENERGIA_DEFAULT_SERIAL          CACHE STRING "Default Energia Serial command when not specified.")
    set(ENERGIA_DEFAULT_PROGRAMMER "UNKNOWN"   CACHE STRING "Default Energia Programmer ID when not specified.")

    # Cahce ENERGIA_LIBRARIES_PATH
    set(ENERGIA_LIBRARIES_PATH ${ENERGIA_LIBRARIES_PATH} CACHE PATH "The Energia libraries path")
    string(TOUPPER ${ENERGIA_PLATFORM} ENERGIA_PLATFORM)
    # Ensure that all required paths are found
    required_variables(VARS
        ENERGIA_PLATFORMS
        ${ENERGIA_PLATFORM}_CORES_PATH
        ${ENERGIA_PLATFORM}_BOARDS_PATH
        ENERGIA_LIBRARIES_PATH
        ENERGIA_VERSION_PATH
        SIZE_PROGRAM
        MSG "Invalid Energia SDK path (${ENERGIA_SDK_PATH}).\n")

    detect_energia_version(ENERGIA_SDK_VERSION)
    set(ENERGIA_SDK_VERSION         ${ENERGIA_SDK_VERSION}          CACHE STRING "Energia SDK Version")
    set(ENERGIA_SDK_VERSION_ARDUINO ${ENERGIA_SDK_VERSION_ARDUINO}  CACHE STRING "Energia SDK Arduino Version")
    set(ENERGIA_SDK_VERSION_ENERGIA ${ENERGIA_SDK_VERSION_ENERGIA}  CACHE STRING "Energia SDK Energia Version")

    if(ENERGIA_SDK_VERSION_ENERGIA VERSION_LESS 15)
         message(FATAL_ERROR "Unsupported Energia SDK (require verion 15 or higher)")
    endif()

    message(STATUS "Energia SDK version ${ENERGIA_SDK_VERSION}: SDK>${ENERGIA_SDK_PATH}, USER>${ENERGIA_USER_PATH}")

#
#    setup_energia_size_script(ENERGIA_SIZE_SCRIPT)
#    set(ENERGIA_SIZE_SCRIPT ${ENERGIA_SIZE_SCRIPT} CACHE INTERNAL "Energia Size Script")
#
#    #print_board_list()
#
    set(ENERGIA_FOUND True CACHE INTERNAL "Energia Found")
    mark_as_advanced(
        ENERGIA_PLATFORMS
        ${ENERGIA_PLATFORM}_CORES_PATH
        ${ENERGIA_PLATFORM}_BOARDS_PATH
        ENERGIA_LIBRARIES_PATH
        ENERGIA_VERSION_PATH
        SIZE_PROGRAM)
endif()
