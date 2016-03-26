# Find ASN.1 Compiler asn1c

# For Windows the install package pouplates registry key HKCU\Software\asn1c-0.9.21 or similar
# All such keys are read in this case and used as HINTs with the find_program() function
# In addition, all directories of the form "C:\Program Files\asn1c-"* are also given as HINTs

function(ASN1_Win32_Search_Reg ASN1_INSTALL_PATH_LIST)
    if(WIN32)
        # List asn1c install directories in %ProgramFiles%
        set(ASN1C_PROGRAM_FILES_X86 "ProgramFiles(X86)")
        foreach(ASN1C_PROGRAM_FILE "$ENV{ProgramFiles}/asn1c" "$ENV{${ASN1C_PROGRAM_FILES_X86}}/asn1c")
            if (EXISTS "${ASN1C_PROGRAM_FILE}")
                file(TO_CMAKE_PATH ${ASN1C_PROGRAM_FILE} ASN1C_PROGRAM_FILE)
                list(APPEND ASN1_PROGRAM_FILES_PATHS ${ASN1C_PROGRAM_FILE})
            endif()
        endforeach()

        if (EXISTS ${ASN1_PROGRAM_FILES_PATHS})
        else()
            set(ASN1_PROGRAM_FILES_PATHS)
        endif()

        # list registry keys
        execute_process(COMMAND reg query "HKCU\\Software" /f "asn1c-*"
            RESULT_VARIABLE REG_QUERY_RESULT
            OUTPUT_VARIABLE ASN1C_VERSIONS)

        if(REG_QUERY_RESULT EQUAL 0)
            # split output to a list of lines
            string(REGEX MATCHALL "[^\r\n]+" ASN1C_REG_KEYS ${ASN1C_VERSIONS})

            # start with an initial registry key with no explicit version
            set(REG_PATH_LIST "-FFFFFF-FFFFFF-FFFFFF |HKEY_CURRENT_USER\\Software\\asn1c")

            # transform each line to prepend 0-padded version number
            foreach(ASN1C_REG_KEY_LINE ${ASN1C_REG_KEYS})
                if(ASN1C_REG_KEY_LINE MATCHES "^HKEY_CURRENT_USER\\\\Software\\\\asn1c-([0-9]+)[.]([0-9]+)[.]([0-9]+.*)$")
                    set(REG_PATH)
                    foreach(VERSION_COMPONENT ${CMAKE_MATCH_1} ${CMAKE_MATCH_2} ${CMAKE_MATCH_3})
                        # 0-pad each component
                        string(LENGTH ${VERSION_COMPONENT} COMPONENT_LENGTH)
                        while(COMPONENT_LENGTH LESS 6)
                            string(PREPEND VERSION_COMPONENT "0")
                            string(LENGTH ${VERSION_COMPONENT} COMPONENT_LENGTH)
                        endwhile()

                        # append component to REG_PATH
                        string(APPEND REG_PATH "-${VERSION_COMPONENT}")
                    endforeach()

                    string(APPEND REG_PATH " |${ASN1C_REG_KEY_LINE}")
                    list(APPEND REG_PATH_LIST ${REG_PATH})
                endif()
            endforeach()

            if(REG_PATH_LIST)
                # sort all lines
                list(SORT REG_PATH_LIST)

                # transform each line to strip 0-padded version number
                set(ASN1C_REG_KEYS)
                foreach(REG_PATH ${REG_PATH_LIST})
                    string(SUBSTRING ${REG_PATH} 23 -1 REG_PATH)
                    list(APPEND ASN1C_REG_KEYS ${REG_PATH})
                endforeach()

                # read all registry keys and get the file names
                set(ASN1C_INSTALL_PATHS)
                foreach(ASN1_REG_KEY ${ASN1C_REG_KEYS})
                    get_filename_component(ASN1_INSTALL_PATH "[${ASN1_REG_KEY};InstPath]" ABSOLUTE)
                    if(EXISTS "${ASN1_INSTALL_PATH}")
                        list(APPEND ASN1C_INSTALL_PATHS ${ASN1_INSTALL_PATH})
                    endif()
                endforeach()

                if (ASN1C_INSTALL_PATHS)
                    list(INSERT ASN1_PROGRAM_FILES_PATHS 0 ${ASN1C_INSTALL_PATHS})
                endif()
            endif()
        endif()

        # return resulting install path list
        set(${ASN1_INSTALL_PATH_LIST} ${ASN1_PROGRAM_FILES_PATHS} PARENT_SCOPE)
    else()
        set(${ASN1_INSTALL_PATH_LIST} PARENT_SCOPE)
    endif()
endfunction()

ASN1_Win32_Search_Reg(ASN1C_LOCATION_HINTS)

if(ASN1C_LOCATION_HINTS)
    find_program(ASN1C_EXECUTABLE NAMES asn1c HINTS ${ASN1C_LOCATION_HINTS} DOC "ASN.1 compiler")
else()
    find_program(ASN1C_EXECUTABLE NAMES asn1c DOC "ASN.1 compiler")
endif()

if(ASN1C_EXECUTABLE)
    # read asn1c version
    execute_process(COMMAND ${ASN1C_EXECUTABLE} -version
                        RESULT_VARIABLE ASN1C_VERSION_EXIT_CODE
                        ERROR_VARIABLE ASN1C_VERSION_ERROR
                        OUTPUT_VARIABLE ASN1C_VERSION_OUTPUT)
    if (ASN1C_VERSION_EXIT_CODE EQUAL 0)
        string(REGEX MATCH "[0-9]+\\.[0-9]+(\\.[0-9]+[^ \t\n\r,;]+)?" ASN1C_VERSION
                    "${ASN1C_VERSION_OUTPUT}" "${ASN1C_VERSION_ERROR}")
    endif()

    # read asn1c command line options from help output
    execute_process(COMMAND ${ASN1C_EXECUTABLE} -help
            OUTPUT_VARIABLE ASN1C_HELP_OUTPUT
            ERROR_VARIABLE ASN1C_ERROR_OUTPUT)

    if (ASN1C_HELP_OUTPUT OR ASN1C_ERROR_OUTPUT)
        string(REGEX MATCHALL "[\r\n][ \t]+-[^ \t=\r\n]+" ASN1C_CMDLINE_OPTIONS ${ASN1C_HELP_OUTPUT} ${ASN1C_ERROR_OUTPUT})

        set(ASN1C_OPTIONS)
        foreach(ASN1C_CMDLINE_OPTION ${ASN1C_CMDLINE_OPTIONS})
            string(REGEX MATCH "-[^ \t=\r\n]+" ASN1C_CMDLINE_OPTION ${ASN1C_CMDLINE_OPTION})

            if (ASN1C_CMDLINE_OPTION)
                list(APPEND ASN1C_OPTIONS ${ASN1C_CMDLINE_OPTION})
            endif()
        endforeach()
    endif()

    # locate the skeleton files directory needed to support old versions
    get_filename_component(ASN1C_EXECUTABLE_DIR "${ASN1C_EXECUTABLE}" DIRECTORY)
    if(EXISTS "${ASN1C_EXECUTABLE_DIR}/skeletons/INTEGER.h")
        set(ASN1C_SHARED_INCLUDE_DIR "${ASN1C_EXECUTABLE_DIR}/skeletons")
    else()
        get_filename_component(ASN1C_EXECUTABLE_DIR "${ASN1C_EXECUTABLE_DIR}" DIRECTORY)
        if(EXISTS "${ASN1C_EXECUTABLE_DIR}/share/asn1c/INTEGER.h")
            set(ASN1C_SHARED_INCLUDE_DIR "${ASN1C_EXECUTABLE_DIR}/share/asn1c")
        else()
            set(ASN1C_SHARED_INCLUDE_DIR)
        endif()
    endif()
endif()

include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(asn1c
    REQUIRED_VARS ASN1C_EXECUTABLE ASN1C_OPTIONS ASN1C_SHARED_INCLUDE_DIR
    FOUND_VAR ASN1C_FOUND
    VERSION_VAR ASN1C_VERSION)

mark_as_advanced(ASN1C_EXECUTABLE)
