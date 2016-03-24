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
include(ASN1.cmake)

asn1_add_module_library(
	targetName
	GENERATED_SOURCE_DIRECTORY OutputDirectoryName
	INCLUDE_PREFIX_DIRECTORY SubdirectoryForIncludes
	ASN1C_OPTIONS asn1c_opt asn1c_opt ...
	ASN1_DEBUG_OUTPUT true
	DISABLE_WARNINGS "-" GNU MSVC ...
	COMPILE_FLAGS compiler-flag compiler-flag ...
	GLOBAL_TARGET
	MODULES ModuleFile.asn1 ModuleFile.asn1 ...)
```

The `GENERATED_SOURCE_DIRECTORY` keyword specifies the base directory for the location of the generated C source files. The default value is `${CMAKE_CURRENT_BINARY_DIR}/gensrc`. The external `asn1c` command will be run in this directory or a subdirectory named after the include prefix.

The `INCLUDE_PREFIX_DIRECTORY` keyword gives a subdirectory within the `GENERATED_SOURCE_DIRECTORY`, where the C source files will be found.  The intent is that this subdirectory will have to be used as part of the file name in the C/C++ `#include` directives that reference generated files. The default value for the prefix directory is `ASN1`. You can use the value `-` if you want no prefix directory for the resulting include files. In this case the generated files will be found directly under the `GENERATED_SOURCE_DIRECTORY`.

The `ASN1C_OPTIONS` keyword gives a list of additional options to be used on the command line to external `asn1c` tool. See the online [asn1c](http://lionet.info/asn1c) documentation for these options. You should not give any options that suppress the normal source generation of the compiler or that change the output directory. To specify the path to `asn1c` executable you can define the CMake variable `ASN1C_EXE`.

The `ASN1_DEBUG_OUTPUT` keyword with the value `true` will add a C preprocessor macro to the compilation options for your target. The macro is used by the generated C sources to output debug information when parsing encoded ASN.1 input. Use this options during debugging to see why the generated code can not parse your encoded input. The effect is to add `-DASN1_EMIT_DEBUG=1` to CMake targets that link with `ASN1::targetName`.

As the function produces generated code, you may want to disable warnings for the resulting sources. Unfortunately the warning options are compiler-specific, and CMake currently has no single option to disable warnings for any supported compiler.  So you can use the `DISABLE_WARNINGS` keyword with a list of compiler ID arguments, for one or more of the well known compilers. They currently are `GNU` and `MSVC` only. Or you can use a `-` to disable warnings on any of these known compilers.

You can pass any list of options to the compiler with the `COMPILE_FLAGS` keyword to the function. The flags listed will be used to compile the generated source files. The `DISABLE_WARNINGS` option above is just a pre-defined set of `COMPILE_FLAGS`.

The `GLOBAL_TARGET` keyword will make the given targetName visible to CMake scripts outside the current source directory. By default the new target `ASN1::targetName` is only visible in or below the current directory, see the CMake documentation for [interface libraries](https://cmake.org/cmake/help/latest/command/add_library.html#id6).

The `MODULES` keyword is only needed after the other list keywords (`ASN1C_OPTIONS`, `COMPILE_FLAGS`...) to terminate that list and start a list of modules to be compiled for C source generation.

Other arguments, that is `ModuleFile.asn1` give ASN.1 Module Definition files as defined in [X.680](https://www.itu.int/rec/dologin_pub.asp?lang=e&id=T-REC-X.680-201508-I!!PDF-E&type=items). File names are relative to [`CMAKE_CURRENT_SOURCE_DIR`](https://cmake.org/cmake/help/latest/variable/CMAKE_CURRENT_SOURCE_DIR.html) like other source files.

## Module library usage
The function above introduces a new `INTERFACE` library target to your CMake project, with the name given in the first function argument, but with the `ASN1::` prefix. So the resulting target name has the form `ASN1::targetName`. This library can then be added to the link libraries of other project targets, using [`target_link_libraries()`](https://cmake.org/cmake/help/latest/command/target_link_libraries.html). The dependent target will then automatically include the generated source files, that will be compiled with the given compiler options, if any.

Generated source files are never compiled into an actual library for the new target `ASN1::targetName`. This is an `INTERFACE IMPORT` library target, that can only add generated source files, include directories and options to other CMake targets, when used as described. See the CMake documentation for [`INTERFACE IMPORT`](https://cmake.org/cmake/help/latest/command/add_library.html#id6) libraries for details.
