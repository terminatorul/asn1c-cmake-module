# ASN1.cmake

A CMake include file (TODO: module) that can run the external `asn1c` compiler on ASN.1 Module Definition ([X.680](https://www.itu.int/rec/dologin_pub.asp?lang=e&id=T-REC-X.680-201508-I!!PDF-E&type=items)) files and generate C source files. For ASN.1 compiler see <http://lionet.info/asn1c>.

## Basic usage
The CMake script file allows you to include the ASN.1 module definition files as sources in your `CMakeLists.txt`. In the list file you can create an ASN.1 module library, and use it in your project in a call to [`target_link_libraries()`](https://cmake.org/cmake/help/latest/command/target_link_libraries.html).

For example:
```
    include(ASN1.cmake)

    asn1_add_module_library(encoderLib ModuleDefinitionFile.asn1 NextModuleDefinition.asn1)

    #....

    target_link_libraries(project_exe ... ASN1::encoderLib)
```

Notice how the resulting library name receives the `ANS1::` prefix applied to the name given in the first argument. To include the generated headers in your C/C++ code, use a line like:
```
#include <ASN1/NumericString.h>
```

## Syntax
To use the script in your project, create a git [submodule](https://git-scm.com/book/en/v2/Git-Tools-Submodules) or [subtree](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.txt) in your repository, or include a [`file(DOWNLOAD ...)`](https://cmake.org/cmake/help/latest/command/file.html#download) command in your `CMakeLists.txt` to download the script when it does not exist.

The full function syntax is as follows:
```
include(FindASN1C)
include(ASN1.cmake)

asn1_add_module_library(
        <targetName>
        <ModuleFile.asn1>...

        [GENERATED_SOURCE_DIRECTORY <OutputDirectoryName>]
        [INCLUDE_PREFIX_DIRECTORY <SubdirectoryPrefixForIncludes>]
        [ASN1C_OPTIONS asn1c_opt...]
        [ASN1_DEBUG_OUTPUT (TRUE | FALSE) ]
        [DISABLE_WARNINGS ("-" | GNU | MSVC)...]
        [COMPILE_OPTIONS <c_compiler_id> <c_compiler_flag>...]
        [GLOBAL_TARGET]
        [MODULES <ModuleFile.asn1>...]

        # compatibility options
        [COMPILE_DEFINITIONS <define>...]
        [APPLY_DIRECTORY_PATCH_SCRIPT <cmake_script>...]
        [APPLY_SOURCE_PATCH_SCRIPT <cmake_script>... ]
        [CONFIGURE_DEPENDS <dependency>... ]
        [COPY_SKELETON_FILES <asn1c_skeleton_file>...])
```

### FindASN1C.cmake

Looks for asn1c compiler on the current system. After including the module file, the following variables will be populated:
* `ASN1C_FOUND` Will be populated with a `TRUE` value if the compiler is found on the system.
* `ASN1C_EXECUTABLE` The path to the compiler if it was found, or `"ASN1C_EXECUTABLE-NOTFOUND"` otherwise. The compiler is searched normally in the standard system paths, and for Windows the registry will also be searched to find the installation path. You can define the CMake variable `ASN1C_EXECUTABLE` to override the search and use the given executable. You could even try to pass a different tool in this variable that generates C and C++ source files, although depending on your case this may or may not work as intended.
* `ASN1C_VERSION` The version number found in the compiler output with the `-version` option, currently 0.9.21 or 0.9.29.
* `ASN1C_OPTIONS` A list of command line options found in the compiler output with the `-help` option.
* `ASN1C_SHARED_INCLUDE_DIR` Internal option used by `ASN1C.cmake` module. If found, it is the directory to the skeleton files for the compiler. Files from this directory are copied as needed by the compiler and placed next to the generated files to provide the support for standard ASN.1 data types.

This module is included by ASN1C.cmake, so you do not have to explicitly [`include()`](https://cmake.org/cmake/help/latest/command/include.html) it if.

### ASN1C.cmake

Provides only one function function, `asn1_add_module_library()`, with the above syntax.

The first argument `<targetName>` is the name of a library target that will be added to your project, with the `ASN1::` prefix. You have to link with this library in order to include and use the generated source files in the main target.

The `<ModuleFile.asn1>` arguments are names of ASN.1 Module Definition files, see [X.680](https://www.itu.int/rec/dologin_pub.asp?lang=e&id=T-REC-X.680-201508-I!!PDF-E&type=items). The same arguments can also be given later on the command if preceded by the `MODULE` keyword, see below.

The `GENERATED_SOURCE_DIRECTORY` keyword specifies the base directory for the location of the generated C sources. The default value is `${CMAKE_CURRENT_BINARY_DIR}/gensrc`. The external `asn1c` command will be run in this directory or in a subdirectory named after the include prefix.

The `INCLUDE_PREFIX_DIRECTORY` keyword gives a subdirectory within the `GENERATED_SOURCE_DIRECTORY`, where the C source files will be found.  The intent is that this subdirectory will have to be used as part of the file name in the C/C++ `#include` directives that reference generated files. The default value for the prefix directory is `ASN1`. You can use the value `-` if you want no prefix directory for the resulting include files. In this case the generated files will be found directly under the `GENERATED_SOURCE_DIRECTORY`.

The `ASN1C_OPTIONS` keyword gives a list of additional options to be used on the command line to external `asn1c` tool. See the online [asn1c](http://lionet.info/asn1c) documentation for these options. You should not give any options that suppress the normal source generation of the compiler or that change the output directory. To specify the path to `asn1c` executable you can define the CMake variable `ASN1C_EXE`.

The `ASN1_DEBUG_OUTPUT` keyword with the value `true` will add a C preprocessor macro to the compilation options for your target. The macro is used by the generated C sources to output debug information when parsing encoded ASN.1 input. Use this options during debugging to see why the generated code can not parse your encoded input. The effect is to add `-DASN1_EMIT_DEBUG=1` to CMake targets that link with `ASN1::targetName`.

As the function produces generated code, you may want to disable warnings for the resulting sources. Unfortunately the warning options are compiler-specific, and CMake currently has no single option to disable warnings for any supported compiler.  So you can use the `DISABLE_WARNINGS` keyword with a list of compiler ID arguments, for one or more of the well known compilers. They currently are `GNU` and `MSVC` only. Or you can use a `-` to disable warnings on any of these known compilers.

You can pass any list of options to the compiler with the `COMPILE_OPTIONS` keyword to the function. Specify the `<c_compiler_id>` immediately after `COMPILE_OPTIONS` and before the options list. Options will only be applied when the current C compiler (see ][`CMAKE_C_COMPILER_ID`](https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_COMPILER_ID.html)). The flags listed will be used to compile the generated source files. The `DISABLE_WARNINGS` option above is a pre-defined set of `COMPILE_FLAGS`.

The `GLOBAL_TARGET` keyword will make the given targetName visible to CMake scripts outside the current source directory. By default the new target `ASN1::targetName` is only visible in or below the current directory, see the CMake documentation for [interface libraries](https://cmake.org/cmake/help/latest/command/add_library.html#id6).

The `MODULES` keyword is only needed after the other list keywords (`ASN1C_OPTIONS`, `COMPILE_FLAGS`...) to terminate that list and start a list of modules to be compiled for C source generation.

Other arguments, that is `<ModuleFile.asn1>` give ASN.1 Module Definition files as defined in [X.680](https://www.itu.int/rec/dologin_pub.asp?lang=e&id=T-REC-X.680-201508-I!!PDF-E&type=items). File names are relative to [`CMAKE_CURRENT_SOURCE_DIR`](https://cmake.org/cmake/help/latest/variable/CMAKE_CURRENT_SOURCE_DIR.html) like other source files.


A number of additional options are provided mostly for compatibility with Windows systems, where the old `asn1c` version provided with the Windows installer would not work out-of-the-box. These allow you to:
- pass additional `#define's` for compiling generated sources
- apply .cmake scripts to patch the generated source files
- access `asn1c` skeleton files directory

Also for compatibility the following options are used automatically:
- `-fskeletons-copy` option is given to `asn1c` command when it is available (when it is found in the output from the `-help` option)
- `Ws2_32.dll` library is added to the list of dependency libraries when `asn1c` version is below 0.9.29 and the compiler ID is 'MSVC'. In this cases the library is needed to provide the implementation for the POSIX [`ntohl()`](http://pubs.opengroup.org/onlinepubs/9699919799/functions/ntohl.html) function, that may be used by the generated C sources (in `constr_SET.c`).

The `COMPILE_DEFINITIONS` keyword is used to add C compile definitions for compiling the generated sources.

Use `APPLY_DIRECTORY_PATCH_SCRIPT` keyword to pass a number of .cmake script files that will be [`include()`](https://cmake.org/cmake/help/latest/command/include.html)ed after C sources are generated/regenerated, in order to patch / modify the list of available files. The script has the `ASN1_WORKING_DIRECTORY` variable available in scope, with the directory name of the generated source files. See below for examples.

Use `APPLY_SOURCE_PATCH_SCRIPT` keyword to give a number of .cmake script files that will be included once for each of the generated source files. The script has the following CMake variables available in scope:

- `ASN1_GENERATED_SOURCE` - the full path of the source file. Can be used to patch only some of the source files if needed.
- `ASN1_GENERATED_SOURCE_CONTENT` - entire content of the source file. The patch script can modify the content in this variable, and the new content will be written back to the generated source.
- `ASN1_GENERATED_SOURCE_CHANGED` - will be TRUE if the content in `ASN1_GENERATED_SOURCE_CONTENT` has been modified (by other patch scripts). After the script modifies the content, it must set this variable to TRUE. After all patch scripts for a file were included, the resulting content in `ASN1_GENERATED_SOURCE_CONTENT` will be re-written back in the source file only if this variable is TRUE.

Patching generated sources with these options was found necessary to support the older Windows version. You can see in the table below a list of the patch files included with ASN1.cmake module for this purpose.

Use `CONFIGURE_DEPENDS` keyword to pass additional files as dependencies for the generated output. For example a patch script above could could invoke an external script file with user-defined actions for patching, and the external script should now be a dependency for the resulting sources.

The `COPY_SKELETON_FILES` keyword takes a list of `asn1c` skeleton source files that need to be included with the generated ASN.1 modules library. This is used if previous versions of the `asn1c`` do not copy the needed skeleton files automatically, resulting in missing header files and missing symbols related to the ASN.1 data types.

#### Included patch scripts (.cmake includes files)

These .cmake scripts are made available together with ASN1C.cmake module and can be used as arguments to `APPLY_DIRECTORY_PATCH_SCRIPT` or `APPLY_SOURCE_PATCH_SCRIPT` as appropriate.

All of them will be needed on Windows with Visual Studio and the default version of `asn1c` from the installer (that is 0.9.21, if you do not compile `asn1c` from sources with MinGW/cygwin).

- Asn1c_Patch_SkeletonFiles.cmake
    * Used internally by ASN1C.cmake to copy all skeleton files given to the `COPY_SKELETON_FILE` keyword. This copy is an example of a directory patch script applied to the working directory (included) after `asn1c` has generated the C sources.
- Asn1c_Patch_DuplicateHeaderTimeH.cmake
    * Fixes for generated "Time.h" file, which on case-insensitive file systems is the same as the C / POSIX runtime header `<time.h>`. The script will rename the file to "ASN1_Time.h", and update all the `#include ` lines in the other sources appropriately. Note that for Linux the file system is tipically case-sensitive so this patch script need not be applied.
- Asn1c_Patch_DuplicateIntTypesTypedef.cmake
    * Fixes typedefs in the generated sources (by previous compiler version), that duplicate standard C int types int8_t, uint8_t, int16_t, ... for the `<stdint.h>` header. The script will remove the typedefs and add an `#include ` line for the standard library header instead.
- Asn1c_Patch_WarningPragma.cmake
    * Fixes C preprocessor `#warning "output message..."` lines, and replaces them with lines of the form `#pragma message("oputput message...")`. This is becase Visual Studio on Windows does not support the first form.
- Asn1c_Patch_GMTOffsetMacro.cmake
    * Fixes macro `GMTOFF(tm)` in `GeneralizedTime.c` source (if present), as taking the GMT offset of a calendar date in `struct tm` is not yet implemented in Visual C++. Instead this offset is implemented as the difference between `mktime(&tm)` and `gmtime(&tm)`, adjusted for any changes in daylight saving time introduced on the given `tm` argument by the call to `gmtime()`.
- Asn1c_Patch_GeneralizedTimeIncludes.cmake
    * Fixes missing `#include <stdlib.h>` in GeneralizedTime.c for `getenv()` function. Replaces calls to `setenv()` and `unsetenv()` with inline `do { } while()` blocks that implment the same calls using `putenv()` instead. This is because `setenv()` and `unsetenv()` are not implemented in Visual C++.
- Asn1c_Patch_EqualityToAssignSetConstr.cmake
    * Fixes an assignament in `constr_SET_Of.c` mistakenly written using `==` instead of `=`.
- Asn1c_Patch_AttributeUnused.cmake
    * Removes occurrences of `__attribute__ ((unused))` in the generated sources, as the attribute is not supported in Visual C++.

Note the resulting GeneralizedTime.c file (if you need it) still has issues on Windows, even after patching, and you will not be able to validate ASN.1 constraints on this data type. Using a newer version then 0.9.21, compiled from sources for example, is recommended.

## Usage for the resulting ASN.1 module library
The function above introduces a new `INTERFACE` library target to your CMake project, with the name given in the first function argument, but with the `ASN1::` prefix. So the resulting target name has the form `ASN1::targetName`. This library can then be added to the link libraries of other project targets, using [`target_link_libraries()`](https://cmake.org/cmake/help/latest/command/target_link_libraries.html). The dependent target will then automatically include the generated source files, that will be compiled with the given compiler options, if any.

Generated source files are never compiled into an actual library for the new target `ASN1::targetName`. This is an `INTERFACE IMPORT` library target, that can only add generated source files, include directories and options to other CMake targets, when used as described. See the CMake documentation for [`INTERFACE IMPORT`](https://cmake.org/cmake/help/latest/command/add_library.html#id6) libraries for details.
