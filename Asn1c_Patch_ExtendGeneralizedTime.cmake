# Add C source file with wrapper functions over the date/time processing functions in <time.h> system header,
# to extend the maximum year values above year 3000.
#
# Microsoft C run-time library from Visual C++ limits the year value to 3000 for x64 systems, but ASN.1
# GeneralizedTime type can use larger values

if(EXISTS "${ASN1_WORKING_DIRECTORY}/GeneralizedTime.c")
    foreach(SRC "extended_datetime.h" "extended_datetime.c")
        configure_file("${ASN1_MODULE_LIST_DIR}/${SRC}" "${ASN1_WORKING_DIRECTORY}/${SRC}" COPYONLY)
        list(APPEND ASN1_ADD_CONFIGURE_DEPENDS "${ASN1_MODULE_LIST_DIR}/${SRC}")
    endforeach()
endif()
