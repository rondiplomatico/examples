# This is the main build file for OpenCMISS examples using the CMake build system
#
# If standard procedure has been followed building OpenCMISS using CMake, all you
# need to do is set CMAKE_PREFIX_PATH to the <OPENCMISS_ROOT>/install directory.
# The script will do the rest.
#
# Otherwise, if the installation is located elsewhere on your system
# (it is placed inside the OpenCMISS installation folder by default), you need to additionally add that path to
# the CMAKE_MODULE_PATH variable.

# Convenience - capture the install dir from the environment (if not specified directly)
#if (EXISTS $ENV{OPENCMISS_PREFIX_PATH} AND NOT OPENCMISS_PREFIX_PATH)
#    file(TO_CMAKE_PATH "$ENV{OPENCMISS_INSTALL_DIR}" OPENCMISS_INSTALL_DIR)
#endif()

#################### Toolchain setup ####################

# This call to OpenCMISSToolchain needs to be done BEFORE the "project(OpenCMISS-Example..." command is issued,
# as it automatically sets the correct compilers (and MPI wrappers if present)
find_package(OpenCMISSToolchain REQUIRED)

#if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    # By default, we install the binary to the source folder of the example, as it contains the
    # input/output data. This might be subject to change later but is adopting the way the current examples are executed.
    set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR} CACHE FORCE "")
#endif()

#################### Example project setup ####################
cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
project(OpenCMISS-Example VERSION 1.0 LANGUAGES Fortran C CXX)

find_package(OpenCMISS 1.0 REQUIRED)

# Set the build type if not explicitly given
if (OPENCMISS_BUILD_TYPE AND CMAKE_BUILD_TYPE_INITIALIZED_TO_DEFAULT)
    message(STATUS "No build type specified. Using OpenCMISS installation build type ${OPENCMISS_BUILD_TYPE}")
    set(CMAKE_BUILD_TYPE ${OPENCMISS_BUILD_TYPE})
endif()

#################### Actual example code ####################

# Get sources in /src
file(GLOB SRC src/*.f90 src/*.c ../input/*.f90)
set(EXAMPLE_TARGET run)
# Add example executable
add_executable(${EXAMPLE_TARGET} ${SRC})
# Link to opencmiss - contains forward refs to all other necessary libs
target_link_libraries(${EXAMPLE_TARGET} PRIVATE iron)
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -cpp")
if (WIN32)
    target_compile_definitions(${EXAMPLE_TARGET} PRIVATE NOMPIMOD)
endif()
install(TARGETS ${EXAMPLE_TARGET} DESTINATION .)
