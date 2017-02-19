#
# CMake toolchain file for cross-compiling to x86_64-rumprun-netbsd
#
# When building software with CMake, specify as -DCMAKE_TOOLCHAIN_FILE=...
#

set(CMAKE_SYSTEM_NAME NetBSD)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(CMAKE_C_COMPILER /usr/bin/x86_64-rumprun-netbsd-gcc)
set(CMAKE_CXX_COMPILER /usr/bin/x86_64-rumprun-netbsd-g++)

set(CMAKE_FIND_ROOT_PATH /usr/rumprun-x86_64)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
