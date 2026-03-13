set(HEAD_FILES
  ticker.h
  cxx14_smoke.h
)

set(SRC_FILES
  ticker.cpp
)

add_library(ticker_lib STATIC
  ${HEAD_FILES}
  ${SRC_FILES}
)

target_include_directories(ticker_lib PUBLIC
  ${CMAKE_CURRENT_LIST_DIR}
)

# Backend selection: Xenomai > POSIX(Linux) > portable
if(DEFINED XENOMAI_ENABLED AND XENOMAI_ENABLED)
  xenomai_enable(ticker_lib)
else()
  preemptrt_enable(ticker_lib)
endif()

vs_organize_target(ticker_lib
  FOLDER "Libs"
  HEAD HEAD_FILES
  SRC  SRC_FILES
)
