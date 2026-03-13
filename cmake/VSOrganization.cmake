# cmake/VSOrganization.cmake
# CMake 3.10+ compatible; Visual Studio organization helpers.

include_guard()

function(vs_setup_folders)
  set_property(GLOBAL PROPERTY USE_FOLDERS ON)
endfunction()

function(_vs_group_files_by_dir base_dir)
  set(_files ${ARGN})

  if(NOT (MSVC OR CMAKE_GENERATOR MATCHES "Visual Studio"))
    return()
  endif()

  foreach(_f IN LISTS _files)
    if(IS_ABSOLUTE "${_f}")
      set(_abs "${_f}")
    else()
      get_filename_component(_abs "${_f}" ABSOLUTE BASE_DIR "${base_dir}")
    endif()

    file(RELATIVE_PATH _rel "${base_dir}" "${_abs}")
    get_filename_component(_dir "${_rel}" DIRECTORY)

    if(_dir STREQUAL "")
      set(_group "\\")
    else()
      string(REPLACE "/" "\\" _group "${_dir}")
    endif()

    source_group("${_group}" FILES "${_abs}")
  endforeach()
endfunction()

# vs_organize_target(target FOLDER <name> [HEAD <var-or-list>] [SRC <var-or-list>]
#                    [HEADERS_TARGET_SUFFIX <suffix>] [NO_HEADERS_TARGET])
#
# Defaults:
# - FOLDER is REQUIRED.
# - Only INTERFACE_LIBRARY targets auto-attach sources via target_sources(... INTERFACE ...).
# - INTERFACE_LIBRARY targets automatically get a visual-only <target>__headers target (VS only).
function(vs_organize_target target)
  if(NOT TARGET "${target}")
    message(FATAL_ERROR "vs_organize_target(): target '${target}' does not exist.")
  endif()

  set(options NO_HEADERS_TARGET)
  set(oneValueArgs FOLDER HEADERS_TARGET_SUFFIX)
  set(multiValueArgs HEAD SRC)
  cmake_parse_arguments(VS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  if(NOT VS_FOLDER)
    message(FATAL_ERROR
      "vs_organize_target(${target} ...): missing required FOLDER.\n"
      "Usage: vs_organize_target(${target} FOLDER \"Common\" HEAD HEAD_FILES SRC SRC_FILES)"
    )
  endif()

  if(VS_HEADERS_TARGET_SUFFIX)
    set(_suffix "${VS_HEADERS_TARGET_SUFFIX}")
  else()
    set(_suffix "__headers")
  endif()

  set(_head_files "")
  set(_src_files "")

  foreach(_kind IN ITEMS HEAD SRC)
    set(_vals "${VS_${_kind}}")
    if(NOT _vals)
      continue()
    endif()

    set(_resolved "")
    list(LENGTH _vals _len)
    if(_len EQUAL 1)
      list(GET _vals 0 _maybe_var)
      if(DEFINED ${_maybe_var})
        set(_resolved ${${_maybe_var}})
      else()
        set(_resolved ${_vals})
      endif()
    else()
      set(_resolved ${_vals})
    endif()

    if(_kind STREQUAL "HEAD")
      list(APPEND _head_files ${_resolved})
    else()
      list(APPEND _src_files ${_resolved})
    endif()
  endforeach()

  set(_all_files ${_head_files} ${_src_files})

  get_target_property(_type "${target}" TYPE)

  if(_type STREQUAL "INTERFACE_LIBRARY")
    if(_all_files)
      target_sources("${target}" INTERFACE ${_all_files})
    endif()
  endif()

  _vs_group_files_by_dir("${CMAKE_CURRENT_SOURCE_DIR}" ${_all_files})

  if(NOT (MSVC OR CMAKE_GENERATOR MATCHES "Visual Studio"))
    return()
  endif()

  if(_type STREQUAL "INTERFACE_LIBRARY")
    if(VS_NO_HEADERS_TARGET)
      return()
    endif()

    set(_hdr_target "${target}${_suffix}")
    if(NOT TARGET "${_hdr_target}")
      add_custom_target("${_hdr_target}" SOURCES ${_all_files})
    endif()
    set_property(TARGET "${_hdr_target}" PROPERTY FOLDER "${VS_FOLDER}")
  else()
    set_property(TARGET "${target}" PROPERTY FOLDER "${VS_FOLDER}")
  endif()
endfunction()