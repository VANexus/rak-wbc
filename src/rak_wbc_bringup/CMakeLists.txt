cmake_minimum_required(VERSION 3.16)
project(rak_wbc_bringup)

find_package(ament_cmake REQUIRED)

install(DIRECTORY launch config rviz
  DESTINATION share/${PROJECT_NAME}
  OPTIONAL)

ament_package()
