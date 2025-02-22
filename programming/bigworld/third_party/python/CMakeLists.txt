CMAKE_MINIMUM_REQUIRED( VERSION 3.5 )

set(PY_VERSION_MAJOR 2)
set(PY_VERSION_MINOR 7)
set(PY_VERSION_PATCH 3)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_CONFIGURATION_TYPES Release CACHE STRING "Release configuration" FORCE)
    set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build." FORCE)
    # Set the possible values of build type for cmake-gui
    set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Release")
endif()

# BW change start
SET(BW_NO_UNICODE ON)
SET(BW_NO_UNICODE OFF)
ADD_DEFINITIONS( -DCOMPILED_FROM_DSP )
ADD_DEFINITIONS( -DXML_STATIC )
BW_REMOVE_COMPILE_FLAGS( /WX )
ADD_DEFINITIONS( -DPy_NO_ENABLE_SHARED )

INCLUDE_DIRECTORIES( ${BW_SOURCE_DIR}/third_party/zip )

# BW change end
project(libpython${PY_VERSION_MAJOR}${PY_VERSION_MINOR} C)

# This is the major version number of Python
set(LIBPYTHON_VERSION ${PY_VERSION_MAJOR}.${PY_VERSION_MINOR})
if(MSVC)
    set(LIBPYTHON_VERSION ${PY_VERSION_MAJOR}${PY_VERSION_MINOR})
endif(MSVC)
set(LIBPYTHON python${LIBPYTHON_VERSION})

# Include helper functions
include(cmake/Assembler.cmake)
include(cmake/Extensions.cmake)
include(CMakeDependentOption)
include(CMakeParseArguments)

# Options
option(BUILD_SHARED "Build a shared libpython library" OFF)
option(BUILD_STATIC "Build a static libpython library" ON)
option(USE_LIB64 "Search for dependencies and install to prefix/lib64 instead of prefix/lib" OFF)

option(USE_SYSTEM_LIBRARIES "Use system libraries" ON)

cmake_dependent_option(USE_SYSTEM_Curses "Use system Curse" ON "USE_SYSTEM_LIBRARIES" OFF)
cmake_dependent_option(USE_SYSTEM_EXPAT "Use system EXPAT" ON "USE_SYSTEM_LIBRARIES" OFF)
cmake_dependent_option(USE_SYSTEM_OpenSSL "Use system OpenSSL" ON "USE_SYSTEM_LIBRARIES" OFF)
cmake_dependent_option(USE_SYSTEM_TCL "Use system TCL" ON "USE_SYSTEM_LIBRARIES" OFF)
cmake_dependent_option(USE_SYSTEM_ZLIB "Use system ZLIB" ON "USE_SYSTEM_LIBRARIES" OFF)
cmake_dependent_option(USE_SYSTEM_DB "Use system DB" ON "USE_SYSTEM_LIBRARIES" OFF)
cmake_dependent_option(USE_SYSTEM_GDBM "Use system GDBM" ON "USE_SYSTEM_LIBRARIES" OFF)
cmake_dependent_option(USE_SYSTEM_READLINE "Use system READLINE" ON "USE_SYSTEM_LIBRARIES" OFF)
cmake_dependent_option(USE_SYSTEM_SQLITE3 "Use system SQLITE3" ON "USE_SYSTEM_LIBRARIES" OFF)

cmake_dependent_option(USE_LIBEDIT "Use libedit instead of readline" OFF
                       "USE_SYSTEM_READLINE" OFF)

option(WITH_TSC "profile with the Pentium timestamp counter" OFF)
option(ENABLE_IPV6 "Enable IP v6" ON)
option(WITH_DOC_STRINGS "Enable if you want documentation strings in extension modules" ON)
option(Py_USING_UNICODE "Enable unicode support" ON)
set(Py_DEBUG OFF) # TODO - Build debugging interpreter
option(WITH_PYMALLOC "Define if you want to compile in Python-specific mallocs" ON)
option(WITH_THREAD "Compile in rudimentary thread support" ON)

SET(SRC_DIR ${CMAKE_CURRENT_LIST_DIR})
# Detect source directory
set(_landmark "pyconfig.h.in") # CMake will look for this file.
if(EXISTS ${CMAKE_SOURCE_DIR}/${_landmark})
    set(SRC_DIR ${CMAKE_SOURCE_DIR})
elseif(NOT "${SRC_DIR}" STREQUAL "" AND EXISTS ${SRC_DIR}/${_landmark})
    # Do nothing - SRC_DIR is already set.
else()
    foreach(dirname
        cpython-${PY_VERSION_MAJOR}.${PY_VERSION_MINOR}.${PY_VERSION_PATCH}
        Python-${PY_VERSION_MAJOR}.${PY_VERSION_MINOR}.${PY_VERSION_PATCH}
    )
        set(SRC_DIR "${CMAKE_CURRENT_BINARY_DIR}/../${dirname}")
        if(EXISTS ${SRC_DIR}/${_landmark})
            break()
        endif()
    endforeach()
endif()
if(NOT IS_ABSOLUTE ${SRC_DIR})
    set(SRC_DIR ${CMAKE_CURRENT_BINARY_DIR}/${SRC_DIR})
endif()
get_filename_component(_parent_dir ${CMAKE_CURRENT_BINARY_DIR} PATH)
set(_download_link "http://www.python.org/ftp/python/2.7.3/Python-2.7.3.tgz")
set(_extracted_dir "Python-2.7.3")
if(WIN32)
    set(_download_link "https://github.com/jonashaag/cpython/archive/v2.7.3.zip")
    set(_extracted_dir "cpython-2.7.3")
endif(WIN32)
if(NOT EXISTS ${SRC_DIR}/${_landmark})
    message(FATAL_ERROR "Failed to locate python source.
The searched locations were:
   <CMAKE_CURRENT_BINARY_DIR>
   <CMAKE_CURRENT_BINARY_DIR>/../cpython-${PY_VERSION_MAJOR}.${PY_VERSION_MINOR}.${PY_VERSION_PATCH}
   <CMAKE_CURRENT_BINARY_DIR>/../Python-${PY_VERSION_MAJOR}.${PY_VERSION_MINOR}.${PY_VERSION_PATCH}
   <SRC_DIR>
You could try to:
  1) download ${_download_link}
  2) extract the archive in folder: ${_parent_dir}
  3) Check that file \"${_parent_dir}/${_extracted_dir}/${_landmark}\" exists.
  4) re-configure.
If you already downloaded the source, you could try to re-configure this project passing -DSRC_DIR:PATH=/path/to/Python-2.7.3 using cmake or adding an PATH entry named SRC_DIR from cmake-gui.")
endif()
#message(STATUS "SRC_DIR: ${SRC_DIR}")

# Proceed to the configure checks
include(cmake/ConfigureChecks.cmake)

if(NOT BUILD_SHARED AND NOT BUILD_STATIC)
    message(FATAL_ERROR "One or both of BUILD_SHARED or BUILD_STATIC must be set")
endif(NOT BUILD_SHARED AND NOT BUILD_STATIC)

# Set PYTHONHOME
set(LIBDIR "Lib") # See Lib/distutils/sysconfig.py - function 'get_python_lib'
if(UNIX)
    set(LIBDIR "lib")
endif()
if(USE_LIB64)
    set_property(GLOBAL PROPERTY FIND_LIBRARY_USE_LIB64_PATHS ON)
    set(LIBDIR "lib64")
endif()
set(PYTHONHOME "${LIBDIR}")
if(UNIX)
    set(PYTHONHOME "${PYTHONHOME}/${LIBPYTHON}")
endif()

# Install tree directory
set(BIN_INSTALL_DIR bin)                         # Contains the python executable
set(CONFIG_INSTALL_DIR share/${LIBPYTHON})
set(EXTENSION_INSTALL_DIR ${PYTHONHOME}/lib-dynload)
set(INCLUDE_INSTALL_DIR include/${LIBPYTHON})
if(MSVC)
    set(INCLUDE_INSTALL_DIR include)
endif(MSVC)
# Build tree directory
set(BIN_BUILD_DIR ${CMAKE_BINARY_DIR}/bin)
set(CONFIG_BUILD_DIR ${CMAKE_BINARY_DIR}/${CONFIG_INSTALL_DIR})
set(EXTENSION_BUILD_DIR ${CMAKE_BINARY_DIR}/${EXTENSION_INSTALL_DIR})
set(INCLUDE_BUILD_DIR ${SRC_DIR}/Include)

set(ARCHIVEDIR "libs")      # Contains the static (*.a) and import libraries (*.lib)

# Directories specific to 'libpython'
set(LIBPYTHON_LIBDIR ${LIBDIR})
set(LIBPYTHON_ARCHIVEDIR ${LIBDIR})
set(LIBPYTHON_STATIC_ARCHIVEDIR ${LIBDIR})
if(WIN32)
    set(LIBPYTHON_LIBDIR ${BIN_INSTALL_DIR})
    set(LIBPYTHON_ARCHIVEDIR ${ARCHIVEDIR})
    set(LIBPYTHON_STATIC_ARCHIVEDIR static-${ARCHIVEDIR})
endif()

set(EXTRA_PYTHONPATH "" CACHE STRING
    "A colon (:) separated list of extra paths to add to the PYTHONPATH")

# Configure 'pyconfig.h'
MESSAGE( STATUS "cur platform: ${UNIX}, BIN_BUILD_DIR: ${BIN_BUILD_DIR}, src_dir: ${SRC_DIR}")
if(UNIX)
    set(PYCONFIG_BUILD_DIR ${BIN_BUILD_DIR})
    configure_file(cmake/config-unix/pyconfig.h.in
                   ${PYCONFIG_BUILD_DIR}/pyconfig.h)
#[[
elseif(WIN32)
    set(PYCONFIG_BUILD_DIR ${SRC_DIR}/PC) # In a windows build tree, 'pyconfig.h' is NOT required to
                                          # live along side the python executable.
                                          # See function '_init_posix()' and '_init_non_posix()'
                                          # in 'Lib/sysconfig.py'
]]
endif(UNIX)

# Install 'pyconfig.h'
#install(FILES ${PYCONFIG_BUILD_DIR}/pyconfig.h
#        DESTINATION ${INCLUDE_INSTALL_DIR}/)

# Set include directories
include_directories(cmake)
include_directories(${PYCONFIG_BUILD_DIR})
include_directories(${INCLUDE_BUILD_DIR})
include_directories(${SRC_DIR}/Python)
INCLUDE( BWStandardProject )
INCLUDE( BWStandardLibrary )
message( STATUS "INCLUDE_BUILD_DIR: ${INCLUDE_BUILD_DIR}, SRC_DIR: ${SRC_DIR}, PYCONFIG_BUILD_DIR: ${PYCONFIG_BUILD_DIR}")

# Set cflags used by all components
if(UNIX)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-strict-aliasing -fwrapv -Wall -Wstrict-prototypes")
endif(UNIX)
if(MSVC)
    string(REPLACE "/Ob2" "/Ob1" CMAKE_C_FLAGS_RELEASE ${CMAKE_C_FLAGS_RELEASE}) # InlineFunctionExpansion=1
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}" CACHE STRING "Flags used by the compiler during release builds" FORCE)
endif(MSVC)

if(NOT WIN32)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
endif(NOT WIN32)

# Useful additional variables that extensions can use.
if(UNIX AND NOT APPLE)
    set(LINUX ON)
else(UNIX AND NOT APPLE)
    set(LINUX OFF)
endif(UNIX AND NOT APPLE)

# Clear PythonTargets.cmake
file(WRITE ${CONFIG_BUILD_DIR}/PythonTargets.cmake "")

# BigWorld: Override path to OpenSSL
FIND_PACKAGE(BWOpenSSL)
SET(OPENSSL_INCLUDE_DIR ${BWOPENSSL_INCLUDE_DIRS})
SET(OPENSSL_LIBRARIES ${BWOPENSSL_LIBRARIES})
# BigWorld: Override path to zlib
# since we include zlib as source we only need to define zlib
# so it exists
SET(ZLIB_LIBRARIES FOUND_DUMMY_DIR)


# Add extension modules
set(builtin_extensions "" CACHE INTERNAL "" FORCE)
set(builtin_source "" CACHE INTERNAL "" FORCE)
set(builtin_link_libraries "" CACHE INTERNAL "" FORCE)
set(builtin_includedirs "" CACHE INTERNAL "" FORCE)
set(builtin_definitions "" CACHE INTERNAL "" FORCE)
set(extensions_enabled "" CACHE INTERNAL "" FORCE)
set(extensions_disabled "" CACHE INTERNAL "" FORCE)
add_subdirectory(cmake/extensions CMakeBuild/extensions)

# Do not build python.exe and pgen
# add_subdirectory(cmake/pgen CMakeBuild/pgen)
# add_subdirectory(cmake/python CMakeBuild/python)

# Add the other subdirectories
add_subdirectory(cmake/libpython CMakeBuild/libpython)
#add_subdirectory(cmake/include CMakeBuild/include)
#add_subdirectory(cmake/lib CMakeBuild/lib)

#show_extension_summary()

if(UNIX)

    # python.pc
    configure_file(cmake/python.pc.in
                  ${CMAKE_BINARY_DIR}/Misc/python-${LIBPYTHON_VERSION}.pc @ONLY)
    configure_file(cmake/python.pc.in
                  ${CMAKE_BINARY_DIR}/Misc/python-${PY_VERSION_MAJOR}.pc @ONLY)
    configure_file(cmake/python.pc.in
                  ${CMAKE_BINARY_DIR}/Misc/python.pc @ONLY)
    #install(FILES
    #            ${CMAKE_BINARY_DIR}/Misc/python-${LIBPYTHON_VERSION}.pc
    #            ${CMAKE_BINARY_DIR}/Misc/python-${PY_VERSION_MAJOR}.pc
    #            ${CMAKE_BINARY_DIR}/Misc/python.pc
    #        DESTINATION lib/pkgconfig)

    # Makefile
    set(MAKEFILE_LDSHARED_FLAGS "-shared")
    if(APPLE)
        set(MAKEFILE_LDSHARED_FLAGS "-dynamiclib -headerpad_max_install_names -undefined dynamic_lookup")
    endif(APPLE)
    configure_file(cmake/makefile-variables.in
                   ${BIN_BUILD_DIR}/Makefile @ONLY)
    #install(FILES ${BIN_BUILD_DIR}/Makefile
    #        DESTINATION ${PYTHONHOME}/config/
    #        RENAME Makefile)

    # Utility scripts
    #install(FILES ${SRC_DIR}/install-sh ${SRC_DIR}/Modules/makesetup
    #        DESTINATION ${PYTHONHOME}/config/)

endif(UNIX)


if(HAVE_CONFIGURE_PACKAGE_CONFIG_FILE AND HAVE_WRITE_BASIC_PACKAGE_VERSION_FILE)

# Configure 'PythonConfig.cmake' for a build tree
set(CONFIG_DIR_CONFIG ${CONFIG_BUILD_DIR})
set(INCLUDE_DIR_CONFIG ${INCLUDE_BUILD_DIR})
set(PYTHON_CONFIG_CODE "####### Expanded from \@PYTHON_CONFIG_CODE\@ #######\n")
set(PYTHON_CONFIG_CODE "${PYTHON_CONFIG_CODE}list(APPEND PYTHON_INCLUDE_DIR \"${PYCONFIG_BUILD_DIR}\")\n")
set(PYTHON_CONFIG_CODE "${PYTHON_CONFIG_CODE}##################################################")
set(python_config ${CONFIG_BUILD_DIR}/PythonConfig.cmake)
configure_package_config_file(
    cmake/PythonConfig.cmake.in
    ${python_config}
    INSTALL_DESTINATION ${CMAKE_BINARY_DIR}
    PATH_VARS CONFIG_DIR_CONFIG INCLUDE_DIR_CONFIG
    NO_CHECK_REQUIRED_COMPONENTS_MACRO
)

# Configure 'PythonConfig.cmake' for an install tree
set(CONFIG_DIR_CONFIG ${CONFIG_INSTALL_DIR})
set(INCLUDE_DIR_CONFIG ${INCLUDE_INSTALL_DIR})
set(PYTHON_CONFIG_CODE "")
set(python_install_config ${CMAKE_BINARY_DIR}/CMakeFiles/PythonConfig.cmake)
configure_package_config_file(
    cmake/PythonConfig.cmake.in
    ${python_install_config}
    INSTALL_DESTINATION ${CMAKE_INSTALL_PREFIX}/${CONFIG_INSTALL_DIR}
    PATH_VARS CONFIG_DIR_CONFIG INCLUDE_DIR_CONFIG
    NO_CHECK_REQUIRED_COMPONENTS_MACRO
)

# Configure 'PythonTargets.cmake' and 'PythonConfigVersion.cmake
get_property(PYTHON_TARGETS GLOBAL PROPERTY PYTHON_TARGETS)
export(TARGETS ${PYTHON_TARGETS} APPEND FILE ${CONFIG_BUILD_DIR}/PythonTargets.cmake)

set(python_config_version ${CONFIG_BUILD_DIR}/PythonConfigVersion.cmake)
write_basic_package_version_file(
    ${python_config_version}
    VERSION ${PY_VERSION_MAJOR}.${PY_VERSION_MINOR}.${PY_VERSION_PATCH}
    COMPATIBILITY SameMajorVersion
)

# Install 'PythonTargets.cmake', 'PythonConfig.cmake' and 'PythonConfigVersion.cmake
#install(EXPORT PythonTargets FILE PythonTargets.cmake DESTINATION ${CONFIG_INSTALL_DIR})

#install(
#    FILES ${python_install_config} ${python_config_version}
#    DESTINATION ${CONFIG_INSTALL_DIR} COMPONENT Development
#)

endif(HAVE_CONFIGURE_PACKAGE_CONFIG_FILE AND HAVE_WRITE_BASIC_PACKAGE_VERSION_FILE)

message("---------------*** python Include directories in order:")
get_property(dirs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
foreach(dir ${dirs})
    message("  ${dir}")
endforeach()
