# Author: DP-Dev
# File: mingw-toolchain.cmake
# Implementation of a toolchain file for mingw.

# Look for $PREFIX.
option(MINGW_USE_PREFIX "Use the PREFIX environment variable" ON)
# Force the set of installation prefix.
option(MINGW_FORCE_INSTALLATION_PREFIX "Set always the installation prefix" ON)

# Optional PREFIX environment variable
if(MINGW_USE_PREFIX)
  if(DEFINED ENV{PREFIX})
    set(MINGW_CROSS_PREFIX $ENV{PREFIX})
  else()
    set(MINGW_CROSS_PREFIX "")
  endif()
endif()

# Optional ARCH variable, default to x86_64
if(DEFINED MINGW_ARCH)
  set(MINGW_TARGET_ARCH MINGW_ARCH)
else()
  set(MINGW_TARGET_ARCH "x86_64")
endif()

# Map ARCH to MinGW triplet prefixes
if(MINGW_TARGET_ARCH STREQUAL "x86_64")
  set(MINGW_TRIPLET "x86_64-w64-mingw32")
elseif(MINGW_TARGET_ARCH STREQUAL "i686")
  set(MINGW_TRIPLET "i686-w64-mingw32")
elseif(MINGW_TARGET_ARCH STREQUAL "aarch64")
  set(MINGW_TRIPLET "aarch64-w64-mingw32")
elseif(MINGW_TARGET_ARCH STREQUAL "armv7")
  set(MINGW_TRIPLET "armv7-w64-mingw32")
else()
  message(FATAL_ERROR "Unsupported MINGW_ARCH: ${MINGW_TARGET_ARCH}. "
          "Supported: x86_64, i686, aarch64, armv7")
endif()

# Set the system name to Windows for cross-compiling
set(CMAKE_SYSTEM_NAME Windows)

# Set compiler executables with prefix and triplet
set(CMAKE_C_COMPILER   "${MINGW_CROSS_PREFIX}/bin/${MINGW_TRIPLET}-gcc")
set(CMAKE_CXX_COMPILER "${MINGW_CROSS_PREFIX}/bin/${MINGW_TRIPLET}-g++")
set(CMAKE_RC_COMPILER  "${MINGW_CROSS_PREFIX}/bin/${MINGW_TRIPLET}-windres")
set(CMAKE_AR           "${MINGW_CROSS_PREFIX}/bin/${MINGW_TRIPLET}-ar")
set(CMAKE_RANLIB       "${MINGW_CROSS_PREFIX}/bin/${MINGW_TRIPLET}-ranlib")
set(CMAKE_STRIP        "${MINGW_CROSS_PREFIX}/bin/${MINGW_TRIPLET}-strip")

# Set processor according to arch
if(MINGW_TARGET_ARCH STREQUAL "x86_64")
    set(CMAKE_SYSTEM_PROCESSOR x86_64)
elseif(MINGW_TARGET_ARCH STREQUAL "i686")
    set(CMAKE_SYSTEM_PROCESSOR i686)
elseif(MINGW_TARGET_ARCH STREQUAL "aarch64")
    set(CMAKE_SYSTEM_PROCESSOR aarch64)
elseif(MINGW_TARGET_ARCH STREQUAL "armv7")
    set(CMAKE_SYSTEM_PROCESSOR armv7)
endif()

# Detect custom, llvm-mingw or classic mingw-w64 install path
if(MINGW_CUSTOM_OPT_DIR)
  set(MINGW_INSTALL_PATH "${MINGW_CUSTOM_OPT_DIR}")
elseif(EXISTS "${MINGW_CROSS_PREFIX}/opt/llvm-mingw-w64/${MINGW_TRIPLET}")
  set(MINGW_INSTALL_PATH "${MINGW_CROSS_PREFIX}/opt/llvm-mingw-w64/${MINGW_TRIPLET}")
elseif(EXISTS "${MINGW_CROSS_PREFIX}/opt/mingw-w64/${MINGW_TRIPLET}")
  set(MINGW_INSTALL_PATH "${MINGW_CROSS_PREFIX}/opt/mingw-w64/${MINGW_TRIPLET}")
else()
  set(MINGW_INSTALL_PATH "${MINGW_CROSS_PREFIX}/${MINGW_TRIPLET}")
endif()

# Set the root path for finding target libraries and headers
set(CMAKE_FIND_ROOT_PATH "${MINGW_INSTALL_PATH}")

# Search behavior for find commands
# Programs run on host, don't search sysroot
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# Search only in sysroot for libs
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
# Search only in sysroot for includes
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
# Same for packages
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Set the cmake installation prefix
if(MINGW_FORCE_INSTALLATION_PREFIX)
  set(CMAKE_INSTALL_PREFIX ${MINGW_INSTALL_PATH} CACHE
      FILEPATH "CMake installation prefix" FORCE)
endif()

# Set some installation directories.
set(CMAKE_INSTALL_BINDIR     "bin" CACHE PATH "User executables" FORCE)
set(CMAKE_INSTALL_LIBDIR     "lib" CACHE PATH "Object code libraries" FORCE)
set(CMAKE_INSTALL_INCLUDEDIR "include" CACHE PATH "Header files" FORCE)
set(CMAKE_INSTALL_RUNTIMEDIR "lib" CACHE PATH "Runtime DLLs" FORCE)

# Set the library prefix.
set(CMAKE_SHARED_LIBRARY_PREFIX "")
set(CMAKE_STATIC_LIBRARY_PREFIX "")

# Prevent CMake from trying to build executables for test
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
