cmake_minimum_required(VERSION 3.10)
project(rt_ticker_demo LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake")

include(VSOrganization)
vs_setup_folders()

include(PreemptRT)
preemptrt_setup()

include(Xenomai)
xenomai_setup()

add_subdirectory(libs/ticker)
add_subdirectory(apps/ticker)
