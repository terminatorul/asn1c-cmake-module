# Replace conflicting typdefs like:
#
#   typedef unsigned char uint8_t
#   typedef short         int16_t
#
# which clash with the standard header stdint.h, with the proper include line:
#
#   #include <stdint.h>
#

if(NOT DEFINED DUPLICATE_INT_TYPES_REGEXP)
    set(DUPLICATE_INT_TYPES_REGEXP "([\r\n]+[ \t\r\n]*typedef[ \t]+[^\r\n]+[ \t]+u?int(_[^\r\n \t]+)*[0-9]+_t[ \t]*;?[ \t]*)+[\r\n]")
endif()

if(ASN1_GENERATED_SOURCE_CONTENT MATCHES "${DUPLICATE_INT_TYPES_REGEXP}")
    string(REGEX REPLACE "${DUPLICATE_INT_TYPES_REGEXP}" "\n#include <stdint.h>\n"
            ASN1_GENERATED_SOURCE_CONTENT "${ASN1_GENERATED_SOURCE_CONTENT}")
    set(ASN1_GENERATED_SOURCE_CHANGED TRUE)
endif()
