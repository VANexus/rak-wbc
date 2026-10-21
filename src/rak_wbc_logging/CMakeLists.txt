cmake_minimum_required(VERSION 3.16)
project(rak_wbc_logging CXX)

find_package(ament_cmake REQUIRED)

# TODO: add find_package(...) and targets as the package is implemented.
# TODO: keep the real-time path free of allocations, logging, and blocking calls.

install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME}
  OPTIONAL)

if(BUILD_TESTING)
  find_package(ament_lint_auto QUIET)
  if(ament_lint_auto_FOUND)
    ament_lint_auto_find_test_dependencies()
  endif()
endif()

ament_package()
