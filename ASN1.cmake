set(ASN1C_MODULE_LIST_FILE ${CMAKE_CURRENT_LIST_FILE})

# Generates C source files for the given ASN.1 module definition files,
# using the `asn1c` compiler, see http://lionet.info/asn1c/
#
# Creates the given library target, that can be linked with in order to 
# include generated sources and the needed options to your project.
#
# Sample usage:
#
#   asn1_modules_library(x509
#           GENERATED_SOURCE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/gensrc"
#           INCLUDE_PREFIX_DIRECTORY "asn1"
#           ASN1C_OPTIONS -fwide-types -fincludes-quoted -print-lines
#           ASN1_DEBUG_OUTPUT false
#           DISABLE_WARNINGS "-"
#           GLOBAL_TARGET
#           MODULES "ModuleDefinitionFile.asn1" "ModuleDefinitionFile.asn1")
#
# target_link_libraries(... ASN1::x509)

function(asn1_add_module_library ASN1_LIBRARY_TARGET)

    # local variables for function arguments
    set(ASN1_EMIT_DEBUG false)
    set(ASN1_INCLUDE_PREFIX "-NOTFOUND")
    set(ASN1_BASE_OUTPUT_DIR)
    set(ASN1_COMPILE_FLAGS)
    set(ASN1_CMD_OPTIONS)
    set(ASN1_MODULES)
    set(ASN1_ARG_SELECTOR)
    set(ASN1_GLOBAL_TARGET)
    
    # parse function arguments
    foreach(ASN1_ARG ${ARGN})
        if     (ASN1_ARG_SELECTOR STREQUAL "basepath")
            set(ASN1_BASE_OUTPUT_DIR ${ASN1_ARG})
            set(ASN1_ARG_SELECTOR)
        elseif (ASN1_ARG_SELECTOR STREQUAL "incprefix")
            set(ASN1_INCLUDE_PREFIX ${ASN1_ARG})
            set(ASN1_ARG_SELECTOR)
        elseif (ASN1_ARG_SELECTOR STREQUAL "debug")
            set(ASN1_EMIT_DEBUG ${ASN1_ARG})
            set(ASN1_ARG_SELECTOR)
        else()
            string(TOUPPER ${ASN1_ARG} ASN1_ARG_UPPER)

            if (ASN1_ARG_UPPER STREQUAL "GENERATED_SOURCE_DIRECTORY")
                set(ASN1_ARG_SELECTOR "basepath")
            elseif(ASN1_ARG_UPPER STREQUAL "INCLUDE_PREFIX_DIRECTORY")
                set(ASN1_ARG_SELECTOR "incprefix")
            elseif(ASN1_ARG_UPPER STREQUAL "ASN1C_OPTIONS")
                set(ASN1_ARG_SELECTOR "opts")
            elseif(ASN1_ARG_UPPER STREQUAL "COMPILE_FLAGS")
                set(ASN1_ARG_SELECTOR "cflags")
            elseif(ASN1_ARG_UPPER STREQUAL "DISABLE_WARNINGS")
                set(ASN1_ARG_SELECTOR "warn")
            elseif(ASN1_ARG_UPPER STREQUAL "ASN1_DEBUG_OUTPUT")
                set(ASN1_ARG_SELECTOR "debug")
            elseif(ASN1_ARG_UPPER STREQUAL "GLOBAL_TARGET")
                set(ASN1_GLOBAL_TARGET "GLOBAL")
                set(ASN1_ARG_SELECTOR)
            elseif(ASN1_ARG_UPPER STREQUAL "MODULES")
                set(ASN1_ARG_SELECTOR)
            else()
                if(ASN1_ARG_SELECTOR STREQUAL "opts")
                    list(APPEND ASN1_CMD_OPTIONS ${ASN1_ARG})
                elseif(ASN1_ARG_SELECTOR STREQUAL "cflags")
                    list(APPEND ASN1_COMPILE_FLAGS ${ASN1_ARG})
                elseif(ASN1_ARG_SELECTOR STREQUAL "warn")
                    if(ASN1_ARG STREQUAL "-")
                        if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" OR CMAKE_C_COMPILER_ID STREQUAL "MSVC")
                            list(APPEND ASN1_COMPILE_FLAGS "/w")
                        elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "GNU")
                            list(APPEND ASN1_COMPILE_FLAGS "-w")
                        endif()
                    elseif(ASN1_ARG STREQUAL "MSVC")
                        if(MSVC)
                            list(APPEND ASN1_COMPILE_FLAGS "/w")
                        endif()
                    elseif(ASN1_ARG STREQUAL "GNU")
                        if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "GNU")
                            list(APPEND ASN1_COMPILE_FLAGS "-w")
                        endif()
                    else()
                        message(WARNING "A known compiler is expected in order to disable warnings, ${ASN1_ARG} given.")
                    endif()
                else()
                    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${ASN1_ARG}")

                    if(NOT IS_ABSOLUTE ${ASN1_ARG})
                        set(ASN1_ARG "${CMAKE_CURRENT_SOURCE_DIR}/${ASN1_ARG}")
                    endif()
    
                    list(APPEND ASN1_MODULES ${ASN1_ARG})
                endif()
            endif()
        endif()
    endforeach()

    # apply defaults and verify the command options
    if(NOT ASN1_BASE_OUTPUT_DIR)
        set(ASN1_BASE_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/gensrc")
    endif()

    if (NOT IS_ABSOLUTE ${ASN1_BASE_OUTPUT_DIR})
        set(ASN1_BASE_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}/${ASN1_BASE_OUTPUT_DIR}")
    endif()

    if (ASN1_INCLUDE_PREFIX STREQUAL "-NOTFOUND")
        set(ASN1_INCLUDE_PREFIX "ASN1")
    endif()

    if (ASN1_INCLUDE_PREFIX STREQUAL "-")
        set(ASN1_INCLUDE_PREFIX "")
    endif()

    if (IS_ABSOLUTE ${ASN1_INCLUDE_PREFIX})
        message(FATAL_ERROR "Absolute path ${ASN1_INCLUDE_PREFIX} given as include prefix directory for generated ASN1 sources.")
    endif()

    set(ASN1_WORKING_DIRECTORY "${ASN1_BASE_OUTPUT_DIR}/${ASN1_INCLUDE_PREFIX}")

    set(ASN1_GENERATE_SOURCES false)

    if (NOT EXISTS "${ASN1_WORKING_DIRECTORY}")
        file(MAKE_DIRECTORY ${ASN1_WORKING_DIRECTORY})
        set(ASN1_GENERATE_SOURCES true)
    endif()

    if(NOT ASN1_MODULES)
        message(FATAL_ERROR "No ASN.1 modules given for target ASN1::${ASN1_LIBRARY_TARGET}.")
    endif()

    # walk through the modules list and create list of expected hashes
    set(ASN1_CMD_MODULES)
    set(ASN1_EXPECTED_BUILD_ID)
    set(ASN1_BUILD_TAG_FILE "${ASN1_BASE_OUTPUT_DIR}/${ASN1_LIBRARY_TARGET}.build.tag")
    set(ASN1_LIBRARY_TARGET "ASN1::${ASN1_LIBRARY_TARGET}")

    # check CMake module file
    if("${ASN1C_MODULE_LIST_FILE}" IS_NEWER_THAN "${ASN1_BUILD_TAG_FILE}")
        set(ASN1_GENERATE_SOURCES true)
    endif()

    file(SHA3_384 ${ASN1C_MODULE_LIST_FILE} ASN1_EXPECTED_BUILD_ID)
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${ASN1C_MODULE_LIST_FILE})

    # check `asn1c` compiler executable
    find_program(ASN1C_EXE asn1c)

    if (NOT ASN1C_EXE)
        message(FATAL_ERROR "ASN.1 compiler `asn1c` (see http://lionet.info/asn1c/) is needed to compile module definitions for target ${ASN1_LIBRARY_TARGET}.\n"
                    "You can set CMake variable ASN1C_EXE to the `asn1c` compiler path.")
    endif()

    if("${ASN1C_EXE}" IS_NEWER_THAN "${ASN1_BUILD_TAG_FILE}")
        set(ASN1_GENERATE_SOURCES true)
    endif()

    file(SHA3_384 ${ASN1C_EXE} ASN1C_EXE_HASH)
    list(APPEND ASN1_EXPECTED_BUILD_ID ${ASN1C_EXE_HASH})
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${ASN1C_EXE})

    # check build options together with the hashes
    list(APPEND ASN1_EXPECTED_BUILD_ID ${ASN1_CMD_OPTIONS})

    # check module definitions
    foreach(ASN1_MODULE ${ASN1_MODULES})
        if(NOT EXISTS ${ASN1_MODULE})
            message(FATAL_ERROR "Missing ASN.1 module definition file ${ASN1_MODULE}")
        endif()

        if("${ASN1_MODULE}" IS_NEWER_THAN "${ASN1_BUILD_TAG_FILE}")
            set(ASN1_GENERATE_SOURCES true)
        endif()

        file(SHA3_384 ${ASN1_MODULE} ASN1_MODULE_HASH)
        list(APPEND ASN1_EXPECTED_BUILD_ID ${ASN1_MODULE_HASH})

        file(RELATIVE_PATH ASN1_CMD_MODULE ${ASN1_WORKING_DIRECTORY} ${ASN1_MODULE})
        list(APPEND ASN1_CMD_MODULES ${ASN1_CMD_MODULE})
    endforeach()

    # check previous build hashes and options
    if (NOT ASN1_GENERATE_SOURCES)
        file(READ ${ASN1_BUILD_TAG_FILE} ASN1_PREVIOUS_BUILD_ID)

        if (NOT ASN1_EXPECTED_BUILD_ID STREQUAL ASN1_PREVIOUS_BUILD_ID)
            set(ASN1_GENERATE_SOURCES true)
        endif()
    endif()

    # invoke `asn1c` compiler to generate C sources from ASN.1 module definitions
    if(ASN1_GENERATE_SOURCES)
        file(REMOVE ${ASN1_BUILD_TAG_FILE})
        file(REMOVE_RECURSE ${ASN1_WORKING_DIRECTORY})
        file(MAKE_DIRECTORY ${ASN1_WORKING_DIRECTORY})

        execute_process(COMMAND "${ASN1C_EXE}" ${ASN1_CMD_OPTIONS} ${ASN1_CMD_MODULES}
                        WORKING_DIRECTORY ${ASN1_WORKING_DIRECTORY}
                        RESULT_VARIABLE ASN1_EXIT_CODE)

        if (NOT ASN1_EXIT_CODE EQUAL 0)
            message(FATAL_ERROR "Source code generation for ${ASN1_LIBRARY_TARGET} target with `asn1c` compiler failed "
                    "with exit code ${ASN1_EXIT_CODE}.")
        endif()

        file(WRITE ${ASN1_BUILD_TAG_FILE} "${ASN1_EXPECTED_BUILD_ID}")
    endif()

    # list generated files
    file(GLOB_RECURSE ASN1_GENERATED_SOURCES
            "${ASN1_WORKING_DIRECTORY}/*.c"
            "${ASN1_WORKING_DIRECTORY}/*.h"
            "${ASN1_WORKING_DIRECTORY}/*.C"
            "${ASN1_WORKING_DIRECTORY}/*.H"
            "${ASN1_WORKING_DIRECTORY}/*.cc"
            "${ASN1_WORKING_DIRECTORY}/*.hh"
            "${ASN1_WORKING_DIRECTORY}/*.cxx"
            "${ASN1_WORKING_DIRECTORY}/*.hxx"
            "${ASN1_WORKING_DIRECTORY}/*.cpp"
            "${ASN1_WORKING_DIRECTORY}/*.hpp")

    foreach(ASN1_GENERATED_MAIN_FILE "${ASN1_WORKING_DIRECTORY}/converter-sample.c" "${ASN1_WORKING_DIRECTORY}/converter-sample.h"
                                    "${ASN1_WORKING_DIRECTORY}/converter-example.h" "${ASN1_WORKING_DIRECTORY}/converter-example.c")
        list(REMOVE_ITEM ASN1_GENERATED_SOURCES ${ASN1_GENERATED_MAIN_FILE})
    endforeach()

    # create library target
    add_library(${ASN1_LIBRARY_TARGET} INTERFACE IMPORTED ${ASN1_GLOBAL_TARGET})
    target_include_directories(${ASN1_LIBRARY_TARGET} INTERFACE ${ASN1_BASE_OUTPUT_DIR} ${ASN1_WORKING_DIRECTORY})
    if (ASN1_EMIT_DEBUG)
        target_compile_definitions(${ASN1_LIBRARY_TARGET} INTERFACE "-DASN1_EMIT_DEBUG=1")
    endif()
    target_sources(${ASN1_LIBRARY_TARGET} INTERFACE ${ASN1_MODULES} ${ASN1_GENERATED_SOURCES})
    set_source_files_properties(${ASN1_GENERATED_SOURCES} PROPERTIES GENERATED true)
    set_source_files_properties(${ASN1_MODULES} PROPERTIES HEADER_FILE_ONLY true)

    if (ASN1_COMPILE_FLAGS)
        foreach(ASN1_GENERATED_SOURCE ${ASN1_GENERATED_SOURCES})
            set_property(SOURCE ${ASN1_GENERATED_SOURCE} APPEND_STRING PROPERTY COMPILE_FLAGS ${ASN1_COMPILE_FLAGS})
        endforeach()
    endif()
endfunction()
