# cmake/Xenomai.cmake
# CMake 3.10+ compatible.

include_guard()

function(xenomai_setup)
  set(XENOMAI_MODE "AUTO" CACHE STRING "Xenomai mode: AUTO, ON, OFF")
  set_property(CACHE XENOMAI_MODE PROPERTY STRINGS AUTO ON OFF)

  set(XENOMAI_ROOT "/usr/xenomai" CACHE PATH "Xenomai installation prefix (hint)")
  set(XENOMAI_SKIN "native" CACHE STRING "Default Xenomai skin (native/posix/...)")
  set(XENOMAI_DEFINE "HAVE_XENOMAI" CACHE STRING "Macro defined on targets that enable Xenomai")

  find_program(XENOMAI_XENOCONFIG xeno-config
    HINTS "${XENOMAI_ROOT}/bin"
    PATHS /usr/xenomai/bin /usr/local/xenomai/bin /usr/bin /usr/local/bin
  )

  string(TOUPPER "${XENOMAI_MODE}" _mode)

  if(_mode STREQUAL "ON")
    if(NOT XENOMAI_XENOCONFIG)
      message(FATAL_ERROR "XENOMAI_MODE=ON but xeno-config not found. Set -DXENOMAI_ROOT=... or put xeno-config in PATH.")
    endif()
    set(XENOMAI_ENABLED TRUE CACHE BOOL "" FORCE)
  elseif(_mode STREQUAL "OFF")
    set(XENOMAI_ENABLED FALSE CACHE BOOL "" FORCE)
  elseif(_mode STREQUAL "AUTO")
    if(XENOMAI_XENOCONFIG)
      set(XENOMAI_ENABLED TRUE CACHE BOOL "" FORCE)
    else()
      set(XENOMAI_ENABLED FALSE CACHE BOOL "" FORCE)
    endif()
  else()
    message(FATAL_ERROR "Invalid XENOMAI_MODE='${XENOMAI_MODE}'. Use AUTO, ON, OFF.")
  endif()

  if(XENOMAI_ENABLED)
    message(STATUS "Xenomai: enabled (mode=${XENOMAI_MODE}) xeno-config='${XENOMAI_XENOCONFIG}'")
  else()
    message(STATUS "Xenomai: disabled (mode=${XENOMAI_MODE})")
  endif()
endfunction()

function(xenomai_enable target)
  if(NOT TARGET "${target}")
    message(FATAL_ERROR "xenomai_enable(): target '${target}' does not exist.")
  endif()

  if(NOT DEFINED XENOMAI_ENABLED)
    message(FATAL_ERROR "xenomai_enable(): call xenomai_setup() first.")
  endif()

  if(NOT XENOMAI_ENABLED)
    return()
  endif()

  execute_process(
    COMMAND "${XENOMAI_XENOCONFIG}" --skin=${XENOMAI_SKIN} --cflags
    OUTPUT_VARIABLE _cflags OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  execute_process(
    COMMAND "${XENOMAI_XENOCONFIG}" --skin=${XENOMAI_SKIN} --ldflags
    OUTPUT_VARIABLE _ldflags OUTPUT_STRIP_TRAILING_WHITESPACE
  )

  separate_arguments(_cflags_list UNIX_COMMAND "${_cflags}")
  separate_arguments(_ldflags_list UNIX_COMMAND "${_ldflags}")

  set(_link_dirs "")
  set(_link_libs "")
  set(_link_other "")

  foreach(_tok IN LISTS _ldflags_list)
    if(_tok MATCHES "^-L(.+)")
      list(APPEND _link_dirs "${CMAKE_MATCH_1}")
    elseif(_tok MATCHES "^-l(.+)")
      list(APPEND _link_libs "${CMAKE_MATCH_1}")
    else()
      list(APPEND _link_other "${_tok}")
    endif()
  endforeach()

  target_compile_options("${target}" PRIVATE ${_cflags_list})
  target_compile_definitions("${target}" PRIVATE "${XENOMAI_DEFINE}=1")

  # PUBLIC to propagate to final executable after static libs
  if(_link_dirs)
    target_link_directories("${target}" PUBLIC ${_link_dirs})
  endif()
  if(_link_libs)
    target_link_libraries("${target}" PUBLIC ${_link_libs})
  endif()
  if(_link_other)
    # Pragmatic for CMake 3.10 (no target_link_options)
    target_link_libraries("${target}" PUBLIC ${_link_other})
  endif()
endfunction()
