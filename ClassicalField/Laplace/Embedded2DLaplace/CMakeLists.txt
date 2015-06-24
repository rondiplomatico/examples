# This is the main build file for OpenCMISS examples using the CMake build system
#
# If standard procedure has been followed building OpenCMISS using CMake, all you
# need to do is set OPENCMISS_INSTALL_DIR to the <OPENCMISS_ROOT>/install/[release|debug|...] directory.
# The script will do the rest.
#
# Otherwise, if the FindOpenCMISS.cmake module is located elsewhere on your system
# (it is placed inside the OpenCMISS installation folder by default), you need to additionally add that path to
# the CMAKE_MODULE_PATH variable.

# Have CMake find the FindOpenCMISS.cmake script
set(CMAKE_MODULE_PATH ${OPENCMISS_INSTALL_DIR})

# This call to FindOpenCMISS needs to be done BEFORE the "project(OpenCMISS-Example..." command is issued,
# as it automatically sets the correct compilers (and MPI wrappers if present)
find_package(OpenCMISS REQUIRED)

if (CMAKE_BUILD_TYPE_INITIALIZED_TO_DEFAULT)
    message(STATUS "No build type specified. Using same type ${OPENCMISS_BUILD_TYPE} as OpenCMISS installation")
    set(CMAKE_BUILD_TYPE ${OPENCMISS_BUILD_TYPE})
endif()
#if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    # By default, we install the binary to the source folder of the example, as it contains the
    # input/output data. This might be subject to change later but is adopting the way the current examples are executed.
    set(CMAKE_INSTALL_PREFIX ${CMAKE_CURRENT_SOURCE_DIR})
#endif()

#################### Actual example code ####################
cmake_minimum_required(VERSION ${OPENCMISS_CMAKE_MIN_VERSION} FATAL_ERROR)
project(OpenCMISS-Example VERSION 1.0 LANGUAGES Fortran C CXX)

OPENCMISS_IMPORT()

# Get sources in /src
file(GLOB SRC src/*.f90 src/*.c ../input/*.f90)
set(EXAMPLE_TARGET run)
# Add example executable
add_executable(${EXAMPLE_TARGET} ${SRC})
# Add a "d" to the executable name in debug builds
set_target_properties(${EXAMPLE_TARGET} PROPERTIES
    OUTPUT_NAME_DEBUG ${EXAMPLE_TARGET}d)
# Link to opencmiss - contains forward refs to all other necessary libs
target_link_libraries(${EXAMPLE_TARGET} PRIVATE iron)
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -cpp")
if (WIN32)
    target_compile_definitions(${EXAMPLE_TARGET} PRIVATE NOMPIMOD)
endif()
install(TARGETS ${EXAMPLE_TARGET} DESTINATION .)
