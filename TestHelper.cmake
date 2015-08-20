if (EXISTS ${WD}/run)
    execute_process(COMMAND ./run
        RESULT_VARIABLE RES
        OUTPUT_VARIABLE OUT
        ERROR_VARIABLE ERR
        WORKING_DIRECTORY ${WD})
    if (RES EQUAL 0)
        message(STATUS "Success! ${OUT}")
    else()
        message(FATAL_ERROR "Failed! ${OUT}\n${ERR}")
    endif()
else()
    message(STATUS "Skipping test case: No 'run' binary in ${WD}")
endif()
   