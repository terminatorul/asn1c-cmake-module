# Rename the generated header file
#
#   Time.h
#
# which conflicts with the standard include <time.h>, to the new name:
#
#   ASN1_Time.h
#
# and replace all includes of the form #include <Time.h> / #include "Time.h"
# to use new file name as #include "ASN1_Time.h"
#
if(NOT DEFINED ASN1_GENERATED_SOURCE)
    if(EXISTS "${ASN1_WORKING_DIRECTORY}/Time.h")
        file(RENAME "${ASN1_WORKING_DIRECTORY}/Time.h" "${ASN1_WORKING_DIRECTORY}/ASN1_Time.h")
    endif()
else()
    if (ASN1_GENERATED_SOURCE_CONTENT MATCHES "[\r\n]+[ \t\r\n]*#[ \t]*include[ \t]*[\"<]Time\\.h[\">][ \t]*[\r\n]+")
        string(REGEX REPLACE "[\r\n]+[ \t\r\n]*#[ \t]*include[ \t]*([\"<])Time\\.h[\">][ \t]*[\r\n]+"
            "\n#include \\1ASN1_Time.h\\1\n" ASN1_GENERATED_SOURCE_CONTENT "${ASN1_GENERATED_SOURCE_CONTENT}")
        
        set(ASN1_GENERATED_SOURCE_CHANGED TRUE)
    endif()
endif()
