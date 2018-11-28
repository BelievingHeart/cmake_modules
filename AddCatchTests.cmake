# The purpose of this module is to mitigate the problem of 
# https://github.com/catchorg/Catch2/blob/master/docs/slow-compiles.md#top
#
# Usage:
#  add_catch_tests(TEST_MAIN_FILE <main_test_cpp> TEST_IMPL_FILE <impl_test_cpp> [TEST_ON_BUILD])
#
#           <main_test_cpp>:
#               A cpp file containing only two lines of code.
#           <impl_test_cpp>:
#               A cpp file containing the TEST_CASE-s
#            TEST_ON_BUILD:
#               If specified, catch tests will be run during buil time
#            TEST_OPTIONS:
#               The command line args for catch2 executable, example: -d yes -s or "-d" "yes" "-s"
#               It can only support 6 args at most
# 

function(add_catch_tests)
    set(options TEST_ON_BUILD)
    set(oneValueArgs TEST_MAIN_FILE TEST_IMPL_FILE)
    set(multiValueArgs TEST_OPTIONS)
    cmake_parse_arguments(MY "${options}" "${oneValueArgs}"
                        "${multiValueArgs}" ${ARGN} )

        
    set(CMAKE_TEMP_DIR ${CMAKE_BINARY_DIR}/temp)
    message(STATUS "Catch tests sit under ${CMAKE_TEMP_DIR}")
    if(NOT EXISTS ${MY_TEST_MAIN_FILE})
        message(FATAL_ERROR "${MY_TEST_MAIN_FILE} not exists")
    endif()
    if(NOT EXISTS ${MY_TEST_IMPL_FILE})
        message(FATAL_ERROR "${MY_TEST_IMPL_FILE} not exists")
    endif()

    get_filename_component(MY_main_test_file_name ${MY_TEST_MAIN_FILE} NAME)
    string(REPLACE "cpp" "o" MY_MAIN_OBJECT_NAME ${MY_main_test_file_name})

    set(OBJECT_LIB_PATH ${CMAKE_TEMP_DIR}/${MY_MAIN_OBJECT_NAME})

    if(MY_TEST_ON_BUILD)
        set(TEST_COMMAND ./catch_tests)
        set(TEST_OPTIONS ${MY_TEST_OPTIONS})
    else()
        unset(TEST_COMMAND)
        unset(TEST_OPTIONS)
    endif()
           

    file(WRITE ${CMAKE_TEMP_DIR}/check_object_exists.cmake
    "
if(NOT EXISTS ${OBJECT_LIB_PATH})
set(MAKE_OBJECT_LIB 
\"       
execute_process(
COMMAND 
    ${CMAKE_CXX_COMPILER} ${MY_TEST_MAIN_FILE} -c
WORKING_DIRECTORY
    ${CMAKE_TEMP_DIR}
    )     

execute_process(
COMMAND
    ${CMAKE_CXX_COMPILER} ${MY_MAIN_OBJECT_NAME} ${MY_TEST_IMPL_FILE} -o catch_tests 
WORKING_DIRECTORY
    ${CMAKE_TEMP_DIR}
    ) \"
                    )
else()
set(MAKE_OBJECT_LIB
\"    
execute_process(
COMMAND
    ${CMAKE_CXX_COMPILER} ${MY_MAIN_OBJECT_NAME} ${MY_TEST_IMPL_FILE} -o catch_tests 
WORKING_DIRECTORY
    ${CMAKE_TEMP_DIR}
    )\"
)                    
endif()
file(WRITE ${CMAKE_TEMP_DIR}/catch_tests_gen.cmake \${MAKE_OBJECT_LIB})"
    )

    add_custom_command(OUTPUT object_exists_
    COMMAND
        ${CMAKE_COMMAND} -P ${CMAKE_TEMP_DIR}/check_object_exists.cmake
        )

    add_custom_command(OUTPUT gen_tests_
    COMMAND 
        ${CMAKE_COMMAND} -P ${CMAKE_TEMP_DIR}/catch_tests_gen.cmake
    DEPENDS
        object_exists_
    WORKING_DIRECTORY
        ${CMAKE_TEMP_DIR}
        )      

    set(index_ 0)
    foreach(option_ ${TEST_OPTIONS})
        set(option_${index_} ${option_})
        math(EXPR index_ "${index_} + 1")
    endforeach()    

    add_custom_target(dummy_target ALL
        DEPENDS gen_tests_
        COMMAND
            ${TEST_COMMAND} ${option_0} ${option_1} ${option_2} ${option_3} ${option_4} ${option_5}
        WORKING_DIRECTORY
            ${CMAKE_TEMP_DIR}
        )       

endfunction()