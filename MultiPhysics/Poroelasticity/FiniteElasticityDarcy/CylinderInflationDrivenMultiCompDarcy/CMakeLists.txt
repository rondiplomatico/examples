# OpenCMISS (Open Continuum Mechanics, Imaging, Signal processing and System identification)
# is a mathematical modelling environment that enables the application of finite element
# analysis techniques to a variety of complex bioengineering problems.
# 
# The OpenCMISS project website can be found at http://www.opencmiss.org
#
# --- Welcome! ---
# This is the main build file for OpenCMISS examples using the CMake build system
#
# For default builds, all you need to do is set the OPENCMISS_INSTALL_DIR to the <OPENCMISS_ROOT>/install directory.
# Note that you may also define OPENCMISS_INSTALL_DIR in your environment.

########################################################################################################################
################################ DO NOT EDIT THIS PART !!!!!!!!!!! #####################################################
########################################################################################################################
# Convenience: The OPENCMISS_INSTALL_DIR may also be defined in the environment.
if (NOT DEFINED OPENCMISS_INSTALL_DIR AND EXISTS "$ENV{OPENCMISS_INSTALL_DIR}")
    file(TO_CMAKE_PATH "$ENV{OPENCMISS_INSTALL_DIR}" OPENCMISS_INSTALL_DIR)
endif()

# Use the OpenCMISS scripts to also allow choosing a separate toolchain
# This file is located at the opencmiss installation rather than the local example
# as it avoids file replication and makes maintenance much easier
if (TOOLCHAIN)
    set(_OCTC ${OPENCMISS_INSTALL_DIR}/cmake/OCToolchainCompilers.cmake)
    if (EXISTS "${_OCTC}")
        include(${_OCTC})
    else()
        message(WARNING "TOOLCHAIN specified but OpenCMISS config script could not be found at ${_OCTC}. Using CMake defaults.")
    endif()
endif()

# Project setup
cmake_minimum_required(VERSION 3.2 FATAL_ERROR)
project(OpenCMISS-Example VERSION 1.0 LANGUAGES Fortran C CXX)
set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
# One could specify CMAKE_PREFIX_PATH directly, however using OPENCMISS_INSTALL_DIR will be more intuitive, eh?
list(APPEND CMAKE_PREFIX_PATH ${OPENCMISS_INSTALL_DIR})
# Look for a matching OpenCMISS!
find_package(OpenCMISS REQUIRED CONFIG)

########################################################################################################################
################################ ONLY EDIT BELOW HERE !!!!!!!!!!! ######################################################
########################################################################################################################

# Get sources in /src
file(GLOB SRC src/*.f90 src/*.c ../input/*.f90)
set(EXAMPLE_TARGET run)
# Add example executable
add_executable(${EXAMPLE_TARGET} ${SRC})
# Link to opencmiss - contains forward refs to all other necessary libs
target_link_libraries(${EXAMPLE_TARGET} PRIVATE opencmiss)
# Turn on Fortran preprocessing (#include directives)
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -cpp")
if (WIN32)
    target_compile_definitions(${EXAMPLE_TARGET} PRIVATE NOMPIMOD)
endif()
install(TARGETS ${EXAMPLE_TARGET} DESTINATION .)
