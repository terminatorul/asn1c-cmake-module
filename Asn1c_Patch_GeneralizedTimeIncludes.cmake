# Add missing #include <stdlib.h> in GeneralizedTime.c
#
# Replace:
#   #include "GeneralizedTime.h"
# with:
#   #include <stdlib.h>
#   #include "GeneralizedTime.h"
#
# Replace:
#   setenv(var, value, 1)
# with:
#   do { char env[128]; sprintf(env, sizeof env, "%s=%s", var, value); putenv(env); } while (0)
#
# Replace:
#   unsetenv(varname)
# with:
#   do { char env[128]; sprintf(env, sizeof env, "%s=", varname); putenv(env); } while (0)
#

if(ASN1_GENERATED_SOURCE STREQUAL "${ASN1_WORKING_DIRECTORY}/GeneralizedTime.c")
    string(REGEX REPLACE
            "([\r\n]+[ \t\r\n]*#[ \t]*include[ \t]*[\"<]GeneralizedTime\\.h[\">][ \t]*[\r\n]+)"
            "\n#include <stdlib.h>\\1"
        ASN1_GENERATED_SOURCE_CONTENT "${ASN1_GENERATED_SOURCE_CONTENT}")

    string(REGEX REPLACE
    "([ \t\r\n]+)setenv[ \t\r\n]*\\([ \t\r\n]*([^ \t\r\n,;]+)[ \t\r\n]*,[ \t\r\n]*([^ \t\r\n,;]+)[ \t\r\n]*,[ \t\r\n]*(1|true|TRUE|!0|~0)[ \t\r\n]*\\)"
    "\\1do { char envstring[128]; snprintf(envstring, sizeof envstring, \"%s=%s\", \\2, \\3); putenv(envstring); } while (0)"
    ASN1_GENERATED_SOURCE_CONTENT "${ASN1_GENERATED_SOURCE_CONTENT}")
    
    string(REGEX REPLACE
    "([ \t\r\n]+)unsetenv[ \t\r\n]*\\([ \t\r\n]*([^ \t\r\n,;)(]+)[ \t\r\n]*\\)"
    "\\1do { char envstring[128]; snprintf(envstring, sizeof envstring, \"%s=\", \\2); putenv(envstring); } while (0)"
    ASN1_GENERATED_SOURCE_CONTENT "${ASN1_GENERATED_SOURCE_CONTENT}")

    set(ASN1_GENERATED_SOURCE_CHANGED TRUE)
endif()