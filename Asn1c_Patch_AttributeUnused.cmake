# Removes uses of C attributes of the form
#
#   __attribute__ ((unused))
#
# which is not supported on Microsoft Visual C++ compiler for example

if(NOT DEFINED ATTRIBUTE_UNUSED_REGEXP)
    set(ATTRIBUTE_UNUSED_REGEXP "[ \t\r\n]+__attribute__[ \t\r\n]*\\(\\([ \t\r\n]*unused[ \t\r\n]*\\)\\)[ \t\r\n]*")
endif()

if(ASN1_GENERATED_SOURCE_CONTENT MATCHES "${ATTRIBUTE_UNUSED_REGEXP}")
    string(REGEX REPLACE "${ATTRIBUTE_UNUSED_REGEXP}" " " ASN1_GENERATED_SOURCE_CONTENT "${ASN1_GENERATED_SOURCE_CONTENT}")
    set(ASN1_GENERATED_SOURCE_CHANGED TRUE)
endif()