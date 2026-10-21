cmake_minimum_required(VERSION 3.16)
project(rak_wbc_hardware CXX)

find_package(ament_cmake REQUIRED)
find_package(hardware_interface REQUIRED)
find_package(pluginlib REQUIRED)
find_package(rclcpp REQUIRED)
find_package(rclcpp_lifecycle REQUIRED)

# TODO: uncomment when the implementation lands.
# add_library(${PROJECT_NAME} SHARED src/hardware_interface.cpp)
# target_include_directories(${PROJECT_NAME} PUBLIC include)
# ament_target_dependencies(${PROJECT_NAME} hardware_interface pluginlib rclcpp rclcpp_lifecycle)
# pluginlib_export_plugin_description_file(hardware_interface plugin.xml)
# install(TARGETS ${PROJECT_NAME} DESTINATION lib)

install(DIRECTORY launch config
  DESTINATION share/${PROJECT_NAME}
  OPTIONAL)

ament_package()
