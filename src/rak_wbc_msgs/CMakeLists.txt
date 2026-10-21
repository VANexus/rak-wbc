cmake_minimum_required(VERSION 3.16)
project(rak_wbc_msgs)

find_package(ament_cmake REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(std_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)

rosidl_generate_interfaces(${PROJECT_NAME}
  "msg/RobotStatus.msg"
  "msg/ContactState.msg"
  "msg/Footstep.msg"
  "msg/FootstepArray.msg"
  "msg/MotionPrimitive.msg"
  "srv/SetMotionPrimitive.srv"
  "action/ExecuteTask.action"
  DEPENDENCIES std_msgs geometry_msgs
)

ament_export_dependencies(rosidl_default_runtime)
ament_package()
