# Replace:
#   rv.code == RC_FAIL;
# with:
#   rv.code = RC_FAIL;
#
if (ASN1_GENERATED_SOURCE STREQUAL "${ASN1_WORKING_DIRECTORY}/constr_SET_Of.c")
    string(REGEX REPLACE
        "([\r\n]+[ \t\r\n]*)rv[ \r\r\n]*[.][ \t\r\n]*code[ \r\r\n]*==[ \t\r\n]*RC_FAIL[ \t\r\n]*;"
        "\\1rv.code = RC_FAIL;"
        ASN1_GENERATED_SOURCE_CONTENT "${ASN1_GENERATED_SOURCE_CONTENT}")
    set(ASN1_GENERATED_SOURCE_CHANGED TRUE)
endif()
