# cmake/PreemptRT.cmake
# CMake 3.10+ compatible.

include_guard()

function(preemptrt_setup)
  set(PREEMPT_RT_MODE "AUTO" CACHE STRING "PreemptRT mode: AUTO, ON, OFF")
  set_property(CACHE PREEMPT_RT_MODE PROPERTY STRINGS AUTO ON OFF)

  set(PREEMPT_RT_DEFINE "HAVE_POSIX_TICKER" CACHE STRING "Macro to enable POSIX ticker implementation")

  string(TOUPPER "${PREEMPT_RT_MODE}" _mode)

  set(_linux FALSE)
  if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set(_linux TRUE)
  endif()

  if(_mode STREQUAL "OFF")
    set(PREEMPT_RT_ENABLED FALSE CACHE BOOL "" FORCE)
  elseif(_mode STREQUAL "ON")
    if(NOT _linux)
      message(FATAL_ERROR "PREEMPT_RT_MODE=ON but platform is not Linux (CMAKE_SYSTEM_NAME='${CMAKE_SYSTEM_NAME}').")
    endif()
    set(PREEMPT_RT_ENABLED TRUE CACHE BOOL "" FORCE)
  elseif(_mode STREQUAL "AUTO")
    set(PREEMPT_RT_ENABLED ${_linux} CACHE BOOL "" FORCE)
  else()
    message(FATAL_ERROR "Invalid PREEMPT_RT_MODE='${PREEMPT_RT_MODE}'. Use AUTO, ON, OFF.")
  endif()

  if(PREEMPT_RT_ENABLED)
    message(STATUS "PreemptRT: enabled (mode=${PREEMPT_RT_MODE})")
  else()
    message(STATUS "PreemptRT: disabled (mode=${PREEMPT_RT_MODE})")
  endif()
endfunction()

function(preemptrt_enable target)
  if(NOT TARGET "${target}")
    message(FATAL_ERROR "preemptrt_enable(): target '${target}' does not exist.")
  endif()

  if(NOT DEFINED PREEMPT_RT_ENABLED)
    message(FATAL_ERROR "preemptrt_enable(): call preemptrt_setup() first.")
  endif()

  if(NOT PREEMPT_RT_ENABLED)
    return()
  endif()

  target_compile_definitions("${target}" PRIVATE "${PREEMPT_RT_DEFINE}=1")

  set(THREADS_PREFER_PTHREAD_FLAG ON)
  find_package(Threads REQUIRED)
  target_link_libraries("${target}" PRIVATE Threads::Threads)

  # Optional librt for some toolchains (clock_nanosleep)
  if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    include(CheckLibraryExists)
    check_library_exists(rt clock_nanosleep "" _HAVE_LIBRT)
    if(_HAVE_LIBRT)
      target_link_libraries("${target}" PRIVATE rt)
    endif()
  endif()
endfunction()
