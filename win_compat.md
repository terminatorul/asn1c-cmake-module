# Windows compatibility

## Compatibility options

For compatibility the following options are applied automatically:
- `-fskeletons-copy` option is given to `asn1c` command when it is available (when it is found in the output from the `-help` option)
- `Ws2_32.dll` library is added to the list of dependency libraries when `asn1c` version is below 0.9.29 on Windows. In this cases the library is needed to provide the implementation for the POSIX [`ntohl()`](http://pubs.opengroup.org/onlinepubs/9699919799/functions/ntohl.html) function, that may be used by the generated C sources (in `constr_SET.c`).

## Available patch scripts (.cmake includes files)

The following .cmake patch scripts are made available with `ASN1.cmake` module. They are not applied automatically (TODO: add checks for auto-apply), but you should probably include them all as arguments to the apropriate keyword (`APPLY_DIRECTORY_PATCH_SCRIPT` or `APPLY_SOURCE_PATCH_SCRIPT`) when using `asn1_add_module_library()`.

All of them were needed in the case of:
- Windows with Visual Studio
- the default version of `asn1c` provided by the Windows installer (that is 0.9.21, if you do not compile `asn1c` from sources with MinGW/cygwin)
- for the use case of procesing ASN.1 modules for X.509 certificates (DER encoding).

It is possible you will need other patches for your modules or for other compilers.

The included patch scripts are:

- Asn1c_Patch_SkeletonFiles.cmake (directory, internal)
    * Used internally by ASN1C.cmake to implement the `COPY_SKELETON_FILE` keyword. It is an example of a directory patch script applied to the working directory after `asn1c` has generated the C sources.
- Asn1c_Patch_DuplicateHeaderTimeH.cmake (directory, source)
    * Fixes for generated "Time.h" file, which on case-insensitive file systems has the name of the standard C / POSIX runtime header `<time.h>`. The script will rename the generated file to "ASN1_Time.h", and update all the `#include ` lines in the other sources appropriately. Note that for Linux the file system is tipically case-sensitive so the patch script need not be applied.
- Asn1c_Patch_DuplicateIntTypesTypedef.cmake (source)
    * Fixes typedef declarations that duplicate standard C int types int8_t, uint8_t, int16_t, ... declared in `<stdint.h>`. The script will remove the typedefs and add an `#include ` line for the standard library header instead.
- Asn1c_Patch_WarningPragma.cmake (source)
    * Fixes C preprocessor `#warning "output message..."` lines, and replaces them with lines of the form `#pragma message("oputput message...")`. This is becase Visual Studio on Windows does not support the first form.
- Asn1c_Patch_GMTOffsetMacro.cmake (source)
    * Fixes macro `GMTOFF(tm)` in `GeneralizedTime.c` source (if present), as taking the GMT offset of a calendar date in `struct tm` is not yet implemented in Visual C++. Instead this offset is implemented as the difference between `mktime(&tm)` and `gmtime(&tm)`, adjusted for any changes in daylight saving time introduced on the given `tm` argument by the call to `gmtime()`.
- Asn1c_Patch_GeneralizedTimeIncludes.cmake (source)
    * Fixes missing `#include <stdlib.h>` in GeneralizedTime.c for `getenv()` function. Replaces calls to `setenv()` and `unsetenv()` with inline `do { } while()` blocks that implment the same calls using `putenv()` instead. This is because `setenv()` and `unsetenv()` are not implemented in Visual C++.
- Asn1c_Patch_EqualityToAssignSetConstr.cmake (source)
    * Fixes an assignament in `constr_SET_Of.c` mistakenly written using `==` instead of `=`.
- Asn1c_Patch_AttributeUnused.cmake (source)
    * Removes occurrences of `__attribute__ ((unused))` in the generated sources, as the attribute is not supported in Visual C++.
- TODO: Asn1c_Patch_ExtendGeneralizedTime.cmake (directory)
    * Add equivalents for the standard library date/time functions for working with year ranges above year 3000. Used for ASN.1 GeneralizedTime type.

Note the resulting GeneralizedTime.c file (if you generate it) is still limited by the C run-time library functions from Visual C++ used for date/time maninpulations declared in `<time.h>` system header. Microsoft C run-time library limits the year number for date/times to a maximum value of 3000 for x64 system (and 2038 as expected for x86 systems). So if your encoded data uses larger values, the generated code of the modules library will return an encoding error (TODO: Complete the .cmake patch script for support for extended ranges of years).
