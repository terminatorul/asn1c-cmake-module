include("${CMAKE_CURRENT_LIST_DIR}/FindASN1C.cmake")

set(ASN1_MODULE_LIST_DIR ${CMAKE_CURRENT_LIST_DIR})
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
#           COMPILE_OPTIONS -g
#           COMPILE_DEFINITIONS ASN1_SRC=1
#           ASN1_DEBUG_OUTPUT false
#           DISABLE_WARNINGS "-"
#           COPY_SKELETON_FILES DER_Type.h DER_Type.c
#           APPLY_DIRECTORY_PATCH_SCRIPT PatchScript.cmake  OtherScritpt.cmake
#           APPLY_SOURCE_PATCH_SCRIPT PatchScript.cmake  OtherScritpt.cmake
#           CONFIGURE_DEPENDS DependecyFile.ext
#           GLOBAL_TARGET
#           MODULES "ModuleDefinitionFile.asn1" "ModuleDefinitionFile.asn1")
#
# target_link_libraries(... ASN1::x509)

function(asn1_add_module_library ASN1_LIBRARY_TARGET)

    # local variables for function arguments
    set(ASN1_EMIT_DEBUG false)
    set(ASN1_INCLUDE_PREFIX "-NOTFOUND")
    set(ASN1_BASE_OUTPUT_DIR)
    set(ASN1_COMPILE_OPTIONS)
    set(ASN1_COMPILE_OPTIONS_COMPILER_ID)
    set(ASN1_COMPILE_DEFINITIONS)
    set(ASN1_COPY_SKELETON_FILES)
    set(ASN1_DIRECTORY_PATCH_SCRIPTS)
    set(ASN1_SOURCE_PATCH_SCRITPS)
    SET(ASN1_ADD_CONFIGURE_DEPENDS)
    set(ASN1_COMPATIBILITY_ARG "-fskeletons-copy")
    if(ASN1_COMPATIBILITY_ARG IN_LIST ASN1C_OPTIONS)
        set(ASN1_CMD_OPTIONS ${ASN1_COMPATIBILITY_ARG})
    else()
        set(ASN1_CMD_OPTIONS)
    endif()
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
            elseif(ASN1_ARG_UPPER STREQUAL "COMPILE_OPTIONS")
                set(ASN1_ARG_SELECTOR "cflags_id")
            elseif(ASN1_ARG_UPPER STREQUAL "DISABLE_WARNINGS")
                set(ASN1_ARG_SELECTOR "warn")
            elseif(ASN1_ARG_UPPER STREQUAL "COMPILE_DEFINITIONS")
                set(ASN1_ARG_SELECTOR "defines")
            elseif(ASN1_ARG_UPPER STREQUAL "ASN1_DEBUG_OUTPUT")
                set(ASN1_ARG_SELECTOR "debug")
            elseif(ASN1_ARG_UPPER STREQUAL "COPY_SKELETON_FILES")
                set(ASN1_ARG_SELECTOR "skeleton")
            elseif(ASN1_ARG_UPPER STREQUAL "APPLY_DIRECTORY_PATCH_SCRIPT")
                set(ASN1_ARG_SELECTOR "dir_patch")
            elseif(ASN1_ARG_UPPER STREQUAL "APPLY_SOURCE_PATCH_SCRIPT")
                set(ASN1_ARG_SELECTOR "src_patch")
            elseif(ASN1_ARG_UPPER STREQUAL "CONFIGURE_DEPENDS")
                set(ASN1_ARG_SELECTOR "depends")
            elseif(ASN1_ARG_UPPER STREQUAL "GLOBAL_TARGET")
                set(ASN1_GLOBAL_TARGET "GLOBAL")
                set(ASN1_ARG_SELECTOR)
            elseif(ASN1_ARG_UPPER STREQUAL "MODULES")
                set(ASN1_ARG_SELECTOR)
            else()
                if(ASN1_ARG_SELECTOR STREQUAL "opts")
                    list(APPEND ASN1_CMD_OPTIONS ${ASN1_ARG})
                elseif(ASN1_ARG_SELECTOR STREQUAL "cflags_id")
                    set(ASN1_COMPILE_OPTIONS_COMPILER_ID ${ASN1_ARG})
                    set(ASN1_ARG_SELECTOR "cflags")
                elseif(ASN1_ARG_SELECTOR STREQUAL "cflags")
                    if (CMAKE_C_COMPILER_ID STREQUAL ASN1_COMPILE_OPTIONS_COMPILER_ID)
                        list(APPEND ASN1_COMPILE_OPTIONS ${ASN1_ARG})
                    endif()
                elseif(ASN1_ARG_SELECTOR STREQUAL "warn")
                    if(ASN1_ARG STREQUAL "-")
                        if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
                            list(APPEND ASN1_COMPILE_OPTIONS "/w")
                        elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
                            list(APPEND ASN1_COMPILE_OPTIONS "-w")
                        endif()
                    elseif(ASN1_ARG STREQUAL "MSVC")
                        if(MSVC)
                            list(APPEND ASN1_COMPILE_OPTIONS "/w")
                        endif()
                    elseif(ASN1_ARG STREQUAL "GNU")
                        if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_C_COMPILER_ID STREQUAL "GNU")
                            list(APPEND ASN1_COMPILE_OPTIONS "-w")
                        endif()
                    else()
                        message(WARNING "A known compiler is expected in order to disable warnings, ${ASN1_ARG} given.")
                    endif()
                elseif(ASN1_ARG_SELECTOR STREQUAL "skeleton")
                    list(APPEND ASN1_COPY_SKELETON_FILES ${ASN1_ARG})
                elseif(ASN1_ARG_SELECTOR STREQUAL "dir_patch")
                    list(APPEND ASN1_DIRECTORY_PATCH_SCRIPTS ${ASN1_ARG})
                elseif(ASN1_ARG_SELECTOR STREQUAL "src_patch")
                    list(APPEND ASN1_SOURCE_PATCH_SCRITPS ${ASN1_ARG})
                elseif(ASN1_ARG_SELECTOR STREQUAL "depends")
                    list(APPEND ASN1_ADD_CONFIGURE_DEPENDS ${ASN1_ARG})
                elseif(ASN1_ARG_SELECTOR STREQUAL "defines")
                    list(APPEND ASN1_COMPILE_DEFINITIONS ${ASN1_ARG})
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

    set(ASN1_GENERATE_SOURCES FALSE)

    if (NOT EXISTS "${ASN1_WORKING_DIRECTORY}")
        file(MAKE_DIRECTORY ${ASN1_WORKING_DIRECTORY})
        set(ASN1_GENERATE_SOURCES TRUE)
    endif()

    if(NOT ASN1_MODULES)
        message(FATAL_ERROR "No ASN.1 modules given for target ASN1::${ASN1_LIBRARY_TARGET}.")
    endif()

    ## walk through the modules list and other inputs, to create list of expected hashes
    # initialize values
    set(ASN1_CMD_MODULES)
    set(ASN1_EXPECTED_BUILD_ID)
    set(ASN1_BUILD_TAG_FILE "${ASN1_BASE_OUTPUT_DIR}/${ASN1_LIBRARY_TARGET}.build.tag")
    set(ASN1_LIBRARY_TARGET "ASN1::${ASN1_LIBRARY_TARGET}")

    # check CMake module file
    if("${ASN1C_MODULE_LIST_FILE}" IS_NEWER_THAN "${ASN1_BUILD_TAG_FILE}")
        set(ASN1_GENERATE_SOURCES true)
    endif()

    file(SHA3_384 ${ASN1C_MODULE_LIST_FILE} ASN1_EXPECTED_BUILD_ID)
    list(APPEND ASN1_EXPECTED_BUILD_ID "\n")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${ASN1C_MODULE_LIST_FILE})

    # check `asn1c` compiler executable
    if (NOT ASN1C_EXECUTABLE)
        message(FATAL_ERROR "ASN.1 compiler `asn1c` (see http://lionet.info/asn1c/) is needed to compile module definitions for target ${ASN1_LIBRARY_TARGET}.\n"
                    "You can set CMake variable ASN1C_EXECUTABLE to the `asn1c` compiler path.")
    endif()

    if("${ASN1C_EXECUTABLE}" IS_NEWER_THAN "${ASN1_BUILD_TAG_FILE}")
        set(ASN1_GENERATE_SOURCES true)
    endif()

    file(SHA3_384 ${ASN1C_EXECUTABLE} ASN1C_EXECUTABLE_HASH)
    list(APPEND ASN1_EXPECTED_BUILD_ID ${ASN1C_EXECUTABLE_HASH} "\n")
    list(APPEND ASN1_EXPECTED_BUILD_ID ${ASN1C_VERSION} "\n")
    set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${ASN1C_EXECUTABLE})

    # check skeleton files
    if (ASN1_COPY_SKELETON_FILES)
        if(NOT ASN1C_SHARED_INCLUDE_DIR)
            message(FATAL_ERROR "ASN.1 compiler source directory to copy the skeleton files from was not found.")
        endif()

        list(INSERT ASN1_DIRECTORY_PATCH_SCRIPTS 0 "${ASN1_MODULE_LIST_DIR}/Asn1c_Patch_SkeletonFiles.cmake")

        foreach(ASN1_COPY_SKELETON_FILE ${ASN1_COPY_SKELETON_FILES})
            list(APPEND ASN1_ADD_CONFIGURE_DEPENDS "${ASN1C_SHARED_INCLUDE_DIR}/${ASN1_COPY_SKELETON_FILE}")
        endforeach()
    endif()

    # check included patch script modules
    foreach(ASN1_PATCH_SCRIPT_MODULE ${ASN1_DIRECTORY_PATCH_SCRIPTS} ${ASN1_SOURCE_PATCH_SCRITPS})
        if(NOT IS_ABSOLUTE "${ASN1_PATCH_SCRIPT_MODULE}")
            set(ASN1_PATCH_SCRIPT_MODULE "${CMAKE_CURRENT_LIST_DIR}/${ASN1_PATCH_SCRIPT_MODULE}")
        endif()

        list(APPEND ASN1_ADD_CONFIGURE_DEPENDS "${ASN1_PATCH_SCRIPT_MODULE}")
    endforeach()

    # check configure dependencies
    foreach(ASN1_CONFIGURE_DEPENDS ${ASN1_ADD_CONFIGURE_DEPENDS})
        if(NOT IS_ABSOLUTE ${ASN1_CONFIGURE_DEPENDS})
            set(ASN1_CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${ASN1_CONFIGURE_DEPENDS}")
        endif()

        if("${ASN1_CONFIGURE_DEPENDS}" IS_NEWER_THAN "${ASN1_BUILD_TAG_FILE}")
            set(ASN1_GENERATE_SOURCES true)
        endif()

        file(SHA3_384 ${ASN1_CONFIGURE_DEPENDS} ASN1_CONFIGURE_DEPENDS_HASH)
        list(APPEND ASN1_EXPECTED_BUILD_ID ${ASN1_CONFIGURE_DEPENDS_HASH} "\n")

        set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${ASN1_CONFIGURE_DEPENDS})
    endforeach()

    # check build options
    list(APPEND ASN1_EXPECTED_BUILD_ID ${ASN1_CMD_OPTIONS} "\n")

    # check module definitions
    foreach(ASN1_MODULE ${ASN1_MODULES})
        if(NOT EXISTS ${ASN1_MODULE})
            message(FATAL_ERROR "Missing ASN.1 module definition file ${ASN1_MODULE}")
        endif()

        if("${ASN1_MODULE}" IS_NEWER_THAN "${ASN1_BUILD_TAG_FILE}")
            set(ASN1_GENERATE_SOURCES true)
        endif()

        file(SHA3_384 ${ASN1_MODULE} ASN1_MODULE_HASH)
        list(APPEND ASN1_EXPECTED_BUILD_ID ${ASN1_MODULE_HASH} "\n")

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

        # Generate C sources from ASN.1 module definitions
        execute_process(COMMAND "${ASN1C_EXECUTABLE}" ${ASN1_CMD_OPTIONS} ${ASN1_CMD_MODULES}
                        WORKING_DIRECTORY ${ASN1_WORKING_DIRECTORY}
                        RESULT_VARIABLE ASN1_EXIT_CODE)

        if (NOT ASN1_EXIT_CODE EQUAL 0)
            message(FATAL_ERROR "Source code generation for ${ASN1_LIBRARY_TARGET} target with `asn1c` compiler failed "
                    "with exit code ${ASN1_EXIT_CODE}.")
        endif()

        # run library patch scripts on the working directory
        foreach(ASN1_DIRECTORY_PATCH_SCRIPT ${ASN1_DIRECTORY_PATCH_SCRIPTS})
            include(${ASN1_DIRECTORY_PATCH_SCRIPT})
        endforeach()

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

    # run file patch scripts
    if(ASN1_GENERATE_SOURCES AND ASN1_SOURCE_PATCH_SCRITPS)
        set(ASN1_GENERATED_SOURCE_CHANGED FALSE)
        foreach(ASN1_GENERATED_SOURCE ${ASN1_GENERATED_SOURCES})
            file(READ ${ASN1_GENERATED_SOURCE} ASN1_GENERATED_SOURCE_CONTENT)

            foreach(ASN1_SOURCE_PATCH_SCRIPT ${ASN1_SOURCE_PATCH_SCRITPS})
                include(${ASN1_SOURCE_PATCH_SCRIPT})
            endforeach()

            if(ASN1_GENERATED_SOURCE_CHANGED)
                get_filename_component(ASN1_GENERATED_SOURCE_BASENAME ${ASN1_GENERATED_SOURCE} NAME)
                message(STATUS "Patching file ${ASN1_GENERATED_SOURCE_BASENAME}")
                file(WRITE ${ASN1_GENERATED_SOURCE} "${ASN1_GENERATED_SOURCE_CONTENT}")
                set(ASN1_GENERATED_SOURCE_CHANGED FALSE)
            endif()
        endforeach()
    endif()

    # create library target
    add_library(${ASN1_LIBRARY_TARGET} INTERFACE IMPORTED ${ASN1_GLOBAL_TARGET})

    # set public include directories
    target_include_directories(${ASN1_LIBRARY_TARGET} INTERFACE ${ASN1_BASE_OUTPUT_DIR} ${ASN1_WORKING_DIRECTORY})

    # set public compile flags
    if (ASN1_EMIT_DEBUG)
        target_compile_definitions(${ASN1_LIBRARY_TARGET} INTERFACE "-DEMIT_ASN_DEBUG=1")
    endif()

    # set public source files
    target_sources(${ASN1_LIBRARY_TARGET} INTERFACE ${ASN1_MODULES} ${ASN1_GENERATED_SOURCES})

    # add Ws2_32 library in compatibility
    if (ASN1C_VERSION VERSION_LESS "0.9.29" AND WIN32)
        target_link_libraries(${ASN1_LIBRARY_TARGET} INTERFACE "Ws2_32")
    endif()

    # set source file properties
    set_source_files_properties(${ASN1_GENERATED_SOURCES} PROPERTIES GENERATED true)
    set_source_files_properties(${ASN1_MODULES} PROPERTIES HEADER_FILE_ONLY true)

    set_property(SOURCE ${ASN1_GENERATED_SOURCES} APPEND PROPERTY COMPILE_OPTIONS ${ASN1_COMPILE_OPTIONS})
    set_property(SOURCE ${ASN1_GENERATED_SOURCES} APPEND PROPERTY COMPILE_DEFINITIONS ${ASN1_COMPILE_DEFINITIONS})
endfunction()
