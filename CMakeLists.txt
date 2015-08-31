# This script generates CMakeLists.txt files for each example and adds them as external project
# The only thing necessary to build them against an existing OpenCMISS installation is to specify the 
# installation directory/prefix CMAKE_PREFIX_PATH containing the config files
# (opencmiss-config.cmake / opencmisstoolchain-config.cmake)
#
# The USE MPI modification for windows has been made with eclipse, looking for
# (\ )*USE MPI\R((.|\R)*)IMPLICIT NONE\R
# and replacing with
# #ifndef NOMPIMOD\R$1 USE MPI\R#endif\R$2IMPLICIT NONE\R\R#ifdef NOMPIMOD\R#include "mpif.h"\R#endif\R\R
#
# @author Daniel Wirtz @date April 9th, 2015

# If the examples have been cloned to OPENCMISS_ROOT/examples and not architecture path is used,
# this will have the script automatically detect the opencmiss installation.
get_filename_component(INSTALL_GUESS "${CMAKE_CURRENT_SOURCE_DIR}/../install" ABSOLUTE)
# Convenience: The OPENCMISS_INSTALL_DIR may also be defined in the environment.
if (NOT DEFINED OPENCMISS_INSTALL_DIR AND EXISTS "$ENV{OPENCMISS_INSTALL_DIR}")
    file(TO_CMAKE_PATH "$ENV{OPENCMISS_INSTALL_DIR}" OPENCMISS_INSTALL_DIR)
elseif(EXISTS "${INSTALL_GUESS}/opencmiss-config.cmake")
    set(OPENCMISS_INSTALL_DIR "${INSTALL_GUESS}")
endif()
if (OPENCMISS_INSTALL_DIR)
    list(APPEND CMAKE_PREFIX_PATH ${OPENCMISS_INSTALL_DIR})
endif()

cmake_minimum_required(VERSION 3.0 FATAL_ERROR)
project(OpenCMISS-Examples VERSION 1.0 LANGUAGES C)
include(ExternalProject)

find_package(OpenCMISS CONFIG REQUIRED)

if (NOT DEFINED OPENCMISS_BUILD_TYPE)
    set(OPENCMISS_BUILD_TYPE ${CMAKE_BUILD_TYPE})
endif()

# Set default build/install dirs unless specified
set(OPENCMISS_EXAMPLES_BUILD_DIR ${CMAKE_CURRENT_BINARY_DIR})

enable_testing()

function(RECURSE curdir)
    file(GLOB content RELATIVE ${curdir} ${curdir}/*)
    SET(sources )
    foreach(entry ${content})
        set(filename ${curdir}/${entry})
        if(IS_DIRECTORY ${filename} AND NOT filename STREQUAL CMAKE_CURRENT_BINARY_DIR)
                RECURSE(${filename})
        else()
            get_filename_component(fname ${filename} NAME)
            string(FIND "${curdir}" "${CMAKE_CURRENT_BINARY_DIR}" _TMP)
            # Pick folders with either a CMakeLists.txt or Makefile
            if (fname STREQUAL CMakeLists.txt AND NOT curdir STREQUAL CMAKE_CURRENT_SOURCE_DIR)
                
                # Add as external project right away
                GET_FULLNAME(${curdir} EXAMPLE_FULLNAME)
                
                message(STATUS "Configuring example ${EXAMPLE_FULLNAME}")
                    
                ExternalProject_Add(${EXAMPLE_FULLNAME}
        		    PREFIX ${OPENCMISS_EXAMPLES_BUILD_DIR}
        		    TMP_DIR ${OPENCMISS_EXAMPLES_BUILD_DIR}/ep_tmp
        		    STAMP_DIR ${OPENCMISS_EXAMPLES_BUILD_DIR}/ep_stamps
        		
                    # Need empty download command, otherwise creation of external project fails with "no download info"
        		    DOWNLOAD_COMMAND ""
        		
        		    #--Configure step-------------
            		CMAKE_COMMAND ${CMAKE_COMMAND} -Wno-dev --no-warn-unused-cli # disables warnings for unused cmdline options
            		SOURCE_DIR ${curdir}
            		BINARY_DIR ${OPENCMISS_EXAMPLES_BUILD_DIR}/${EXAMPLE_FULLNAME}
            		CMAKE_ARGS 
            		    ${EXTRA_ARGS}
            		    -DOPENCMISS_INSTALL_DIR:PATH=${OPENCMISS_INSTALL_DIR}
            		    -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
            		    -DOPENCMISS_BUILD_TYPE=${OPENCMISS_BUILD_TYPE}
            		    -DCMAKE_INSTALL_PREFIX=${curdir}
            		    -DCMAKE_OBJECT_PATH_MAX=500
            	)
            	
            	add_test(NAME test_${EXAMPLE_FULLNAME}
            	    COMMAND ${CMAKE_COMMAND} -DWD=${curdir}
            	        -P ${CMAKE_CURRENT_SOURCE_DIR}/TestHelper.cmake)
            	set_tests_properties (test_${EXAMPLE_FULLNAME} PROPERTIES TIMEOUT 5)
            endif()
        endif()
    endforeach()
endfunction()

# Create a suitable unique example target name from the example folder
function(GET_FULLNAME EXAMPLE_DIR VARNAME)
    string(REPLACE "${CMAKE_CURRENT_SOURCE_DIR}" "" TMP "${EXAMPLE_DIR}")
    string(REGEX REPLACE "[/\\]" "_" TMP ${TMP})
    string(SUBSTRING ${TMP} 1 -1 TMP)
    # Need to shorten the example names on windows!
    if (WIN32)
        string(MD5 TMP ${TMP})
    endif()
    #set(RES "")
    #while(NOT EXAMPLE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
    #    get_filename_component(PARENT ${EXAMPLE_DIR} PATH)
    #    SET(EXAMPLE_DIR ${PARENT})
    #endwhile()
    set(${VARNAME} ${TMP} PARENT_SCOPE)
endfunction()

# Commence some real work here 
RECURSE(${CMAKE_CURRENT_SOURCE_DIR})