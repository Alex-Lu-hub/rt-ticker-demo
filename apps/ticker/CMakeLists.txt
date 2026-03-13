set(SRC_FILES
  main.cpp
)

add_executable(ticker_app
  ${SRC_FILES}
)

target_link_libraries(ticker_app PRIVATE
  ticker_lib
)

vs_organize_target(ticker_app
  FOLDER "Apps"
  SRC SRC_FILES
)
