# Change preprocessor directives of the form
#
#   #warnings "Warning message string..."
#
# to the form used on Microsoft Visual C++ compilers:
#
#   #pragma message("Warning message string...")
#
# This should only be needed when CMAKE_COMPILER_ID is MSVC
#
if (ASN1_GENERATED_SOURCE_CONTENT MATCHES "[\r\n]+[ \t\r\n]*#[ \t]*warning[ \t]+")
    string(REGEX REPLACE "[\r\n]+[ \t\r\n]*#[ \t]*warning[ \t]+\"([^\r\n]+)\"[ \t]*[\r\n]+"
            "\n#pragma message(\"\\1\")\n"
            ASN1_GENERATED_SOURCE_CONTENT "${ASN1_GENERATED_SOURCE_CONTENT}")
    string(REGEX REPLACE "[\r\n]+[ \t\r\n]*#[ \t]*warning[ \t]+\"([^\r\n]+)\"[ \t]*[\r\n]+"
            "\n#pragma message(\"\\1\")\n"
            ASN1_GENERATED_SOURCE_CONTENT "${ASN1_GENERATED_SOURCE_CONTENT}")
    
    set(ASN1_GENERATED_SOURCE_CHANGED TRUE)
endif()
