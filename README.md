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

This module is included by ASN1C.cmake, so you do not have to explicitly [`include()`](https://cmake.org/cmake/help/latest/command/include.html) it.

### ASN1C.cmake

Provides only one function function, `asn1_add_module_library()`, with the above syntax.

The first argument `<targetName>` is the name of a library target that will be added to your project, with the `ASN1::` prefix (so `targetName` will produce a target named `ASN1::targetName`). You have to link with this library in order to include and use the generated source files in the main target.

The `<ModuleFile.asn1>` arguments are names of ASN.1 Module Definition files, see [X.680](https://www.itu.int/rec/dologin_pub.asp?lang=e&id=T-REC-X.680-201508-I!!PDF-E&type=items). The same arguments can also be given later on the command if preceded by the `MODULE` keyword, see below.

The `GENERATED_SOURCE_DIRECTORY` keyword specifies the base directory for the location of the generated C sources. The default value is `${CMAKE_CURRENT_BINARY_DIR}/gensrc`. The external `asn1c` command will be run in this directory or in a subdirectory named after the include prefix.

The `INCLUDE_PREFIX_DIRECTORY` keyword gives a subdirectory within the `GENERATED_SOURCE_DIRECTORY`, where the C source files will be found.  The intent is that this subdirectory will have to be used as part of the file name in the C/C++ `#include` directives that reference generated files. The default value for the prefix directory is `ASN1`. You can use the value `-` if you want no prefix directory for the resulting include files. In this case the generated files will be found directly under the `GENERATED_SOURCE_DIRECTORY`.

The `ASN1C_OPTIONS` keyword gives a list of additional options to be used on the command line to external `asn1c` tool. See the online [asn1c](http://lionet.info/asn1c) documentation for these options. You should not give any options that suppress the normal source generation of the compiler or that change the output directory. To specify the path to `asn1c` executable you can define the CMake variable `ASN1C_EXE`.

The `ASN1_DEBUG_OUTPUT` keyword with the value `true` will add a C preprocessor macro to the compilation options for your target. The macro is used by the generated C sources to output debug information when parsing encoded ASN.1 input. Use this options during debugging to see why the generated code can not parse your encoded input. The effect is to add `-DASN1_EMIT_DEBUG=1` to CMake targets that link with `ASN1::targetName`.

As the function produces generated code, you may want to disable warnings for the resulting sources. Unfortunately the warning options are compiler-specific, and CMake currently has no single option to disable warnings for all supported compilers.  So you can use the `DISABLE_WARNINGS` keyword with a list of compiler ID arguments, for one or more of the well known compilers. They currently are `GNU` and `MSVC` only. Or you can use a dash `-` to disable warnings on any of these known compilers. Using this option is not recommended, instead disable specific warnings that are bothering you. For the appropriate warnings for MSVC use `COMPILE_OPTIONS MSVC "/wd4244" "/wd4267" "/wd4996"`, which will disable:
- C4244: conversion' conversion from 'type1' to 'type2', possible loss of data
- C4267: 'var' : conversion from 'size_t' to 'type', possible loss of data
- C4996: explicit `deprecated` declaration, for example: "This function or variable may be unsafe. Consider using _safe_version_ instead. To disable deprecation, use _CRT_SECURE_NO_WARNINGS. See online help for details."

You can pass any list of options to the compiler with the `COMPILE_OPTIONS` keyword. Specify the `<c_compiler_id>` immediately after `COMPILE_OPTIONS` and before the options list. Options will only be applied when [`CMAKE_C_COMPILER_ID`](https://cmake.org/cmake/help/latest/variable/CMAKE_LANG_COMPILER_ID.html) matches `<c_compiler_id>`. The flags listed will be used to compile the generated source files. The `DISABLE_WARNINGS` option above is a pre-defined set of `COMPILE_FLAGS`.

The `GLOBAL_TARGET` keyword will make the given targetName visible to CMake scripts outside the current source directory. By default the new target `ASN1::targetName` is only visible in or below the current directory, see the CMake documentation for [interface libraries](https://cmake.org/cmake/help/latest/command/add_library.html#id6).

The `MODULES` keyword is only needed after the other list keywords (`ASN1C_OPTIONS`, `COMPILE_FLAGS`...) to terminate that list and start a list of modules to be compiled for C source generation.

Other arguments, that is `<ModuleFile.asn1>` give ASN.1 Module Definition files as defined in [X.680](https://www.itu.int/rec/dologin_pub.asp?lang=e&id=T-REC-X.680-201508-I!!PDF-E&type=items). File names are relative to [`CMAKE_CURRENT_SOURCE_DIR`](https://cmake.org/cmake/help/latest/variable/CMAKE_CURRENT_SOURCE_DIR.html) like other source files.


A number of additional options are available mostly for compatibility with the Microsoft Windows systems, where the old `asn1c` version provided with the Windows installer would not work out-of-the-box. These allow you to:
- pass additional `#define's` for compiling generated sources
- apply .cmake scripts to patch the generated source files
- access `asn1c` skeleton files directory

See:
    [Windows compatibility](https://github.com/terminatorul/asn1c-cmake-module/blob/master/win_compat.md)
for the available options.

The `COMPILE_DEFINITIONS` keyword is used to add C compile definitions for compiling the generated sources.

Use `APPLY_DIRECTORY_PATCH_SCRIPT` keyword to pass a number of .cmake script files that will be [`include()`](https://cmake.org/cmake/help/latest/command/include.html)ed after C sources are generated/regenerated, in order to patch / modify the list of available files. The script has the `ASN1_WORKING_DIRECTORY` variable available in scope, with the directory name of the generated source files. See below for examples.

Use `APPLY_SOURCE_PATCH_SCRIPT` keyword to give a number of .cmake script files that will be included once for each of the generated source files. The script has the following CMake variables available in scope:

- `ASN1_GENERATED_SOURCE` - the full path of the source file. Can be used to patch only some of the source files if needed.
- `ASN1_GENERATED_SOURCE_CONTENT` - entire content of the source file. The patch script can modify the content in this variable, and the new content will be written back to the generated source.
- `ASN1_GENERATED_SOURCE_CHANGED` - will be TRUE if the content in `ASN1_GENERATED_SOURCE_CONTENT` has been modified (by other patch scripts). After the script modifies the content, it must set this variable to TRUE. After all patch scripts for a file were included, the resulting content in `ASN1_GENERATED_SOURCE_CONTENT` will be re-written back in the source file only if this variable is TRUE.

Patching generated sources with these options was found necessary to support the older Windows version. You can see in the table below a list of the patch files included with ASN1.cmake module for this purpose.

Use `CONFIGURE_DEPENDS` keyword to pass additional files as dependencies for the generated output. For example a patch script above could could invoke an external script file with user-defined actions for patching, and the external script should now be a dependency for the resulting sources.

The `COPY_SKELETON_FILES` keyword takes a list of `asn1c` skeleton source files that need to be included with the generated ASN.1 modules library. This is used if previous versions of the `asn1c`` do not copy the needed skeleton files automatically, resulting in missing header files and missing symbols related to the ASN.1 data types.

## Usage for the resulting ASN.1 module library
The function above introduces a new `INTERFACE` library target to your CMake project, with the name given in the first function argument, but with the `ASN1::` prefix. So the resulting target name has the form `ASN1::targetName`. This library can then be added to the link libraries of other project targets, using [`target_link_libraries()`](https://cmake.org/cmake/help/latest/command/target_link_libraries.html). The dependent target will then automatically include the generated source files, that will be compiled with the given compiler options, if any.

Generated source files are never compiled into an actual library for the new target `ASN1::targetName`. This is an `INTERFACE IMPORT` library target, that can only add generated source files, include directories and options to other CMake targets, when used as described. See the CMake documentation for [`INTERFACE IMPORT`](https://cmake.org/cmake/help/latest/command/add_library.html#id6) libraries for details.
