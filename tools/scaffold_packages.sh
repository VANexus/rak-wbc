#!/usr/bin/env bash
# Generate the rak-wbc ROS 2 package skeleton.
# Safe to re-run: it only creates missing files and never deletes content.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS="$ROOT/src"
mkdir -p "$WS"

MAINTAINER='rak-wbc team'
EMAIL='team@example.com'
LICENSE='Proprietary'

write_package_xml() {
  local dir="$1" pkg="$2" desc="$3" deps="$4" build_type="$5"
  cat > "$dir/package.xml" <<EOF
<?xml version="1.0"?>
<?xml-model href="http://download.ros.org/schema/package_format3.xsd" schematypens="http://www.w3.org/2001/XMLSchema"?>
<package format="3">
  <name>${pkg}</name>
  <version>0.1.0</version>
  <description>${desc}</description>
  <maintainer email="${EMAIL}">${MAINTAINER}</maintainer>
  <license>${LICENSE}</license>

${deps}

  <export>
    <build_type>${build_type}</build_type>
  </export>
</package>
EOF
}

write_cmake_lists() {
  local dir="$1" pkg="$2" install_dirs="$3"
  cat > "$dir/CMakeLists.txt" <<EOF
cmake_minimum_required(VERSION 3.16)
project(${pkg} CXX)

find_package(ament_cmake REQUIRED)

# TODO: add find_package(...) and targets as the package is implemented.
# TODO: keep the real-time path free of allocations, logging, and blocking calls.

install(DIRECTORY ${install_dirs}
  DESTINATION share/\${PROJECT_NAME}
  OPTIONAL)

if(BUILD_TESTING)
  find_package(ament_lint_auto QUIET)
  if(ament_lint_auto_FOUND)
    ament_lint_auto_find_test_dependencies()
  endif()
endif()

ament_package()
EOF
}

write_cpp_header() {
  local dir="$1" pkg="$2" header="$3" klass="$4" note="$5"
  cat > "$dir/include/${pkg}/${header}" <<EOF
#pragma once

// ${note}
// TODO: replace this placeholder with the real interface.

namespace rak_wbc {

class ${klass} {
public:
  ${klass}() = default;
  ~${klass}() = default;
};

}  // namespace rak_wbc
EOF
}

write_cpp_pkg() {
  local pkg="$1" desc="$2" header="$3" klass="$4" note="$5"
  local dir="$WS/$pkg"
  install -d "$dir/include/$pkg" "$dir/src" "$dir/launch" "$dir/config" "$dir/test"
  write_package_xml "$dir" "$pkg" "$desc" \
'  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>rclcpp_lifecycle</depend>
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <depend>sensor_msgs</depend>
  <depend>nav_msgs</depend>
  <depend>tf2</depend>
  <depend>tf2_ros</depend>
  <depend>tf2_eigen</depend>
  <depend>eigen</depend>
  <depend>rak_wbc_msgs</depend>
  <!-- TODO: add heavy dependencies only after they are installed:
       pinocchio, ocs2, crocoddyl, nav2_core, grid_map_ros, rosbag2_cpp, ... -->' \
    ament_cmake
  write_cmake_lists "$dir" "$pkg" "launch config"
  write_cpp_header "$dir" "$pkg" "$header" "$klass" "$note"
  touch "$dir/src/.gitkeep" "$dir/test/.gitkeep"
  cat > "$dir/README.md" <<EOF
# ${pkg}

${desc}

## 职责

TODO

## 接口

- 输入：TODO
- 输出：TODO
- 频率：TODO

## 状态

骨架占位，尚未实现。
EOF
}

write_python_pkg() {
  local pkg="$1" desc="$2" module="$3"
  local dir="$WS/$pkg"
  install -d "$dir/resource" "$dir/$pkg" "$dir/launch" "$dir/config" "$dir/test"
  write_package_xml "$dir" "$pkg" "$desc" \
'  <buildtool_depend>ament_python</buildtool_depend>
  <exec_depend>rclpy</exec_depend>
  <exec_depend>rak_wbc_msgs</exec_depend>
  <test_depend>python3-pytest</test_depend>
  <!-- TODO: add heavy dependencies only after they are installed:
       cv_bridge, vision_msgs, moveit_py, py_trees, ... -->' \
    ament_python
  cat > "$dir/setup.py" <<EOF
from setuptools import setup

package_name = '${pkg}'

setup(
    name=package_name,
    version='0.1.0',
    packages=[package_name],
    data_files=[
        ('share/ament_index/resource_index/packages', ['resource/' + package_name]),
        ('share/' + package_name, ['package.xml']),
    ],
    install_requires=['setuptools'],
    extras_require={'test': ['pytest']},
    zip_safe=True,
    maintainer='${MAINTAINER}',
    maintainer_email='${EMAIL}',
    description='${desc}',
    license='${LICENSE}',
    entry_points={
        'console_scripts': [
            # TODO: '${module} = ${pkg}.${module}:main',
        ],
    },
)
EOF
  cat > "$dir/setup.cfg" <<EOF
[develop]
script_dir=\$base/lib/${pkg}
[install]
install_scripts=\$base/lib/${pkg}
[options]
tests_require = pytest
EOF
  touch "$dir/resource/$pkg"
  cat > "$dir/$pkg/__init__.py" <<EOF
"""${desc}"""
EOF
  cat > "$dir/$pkg/${module}.py" <<EOF
"""${desc}

TODO: implement the node. Keep this module free of import-time side effects.
"""


def main() -> None:
    raise NotImplementedError("${pkg} is a skeleton; implement ${module}.main()")
EOF
  touch "$dir/launch/.gitkeep" "$dir/config/.gitkeep" "$dir/test/.gitkeep"
  cat > "$dir/README.md" <<EOF
# ${pkg}

${desc}

## 职责

TODO

## 接口

- 输入：TODO
- 输出：TODO
- 频率：TODO

## 状态

骨架占位，尚未实现。
EOF
}

# ---------------------------------------------------------------------------
# msgs
# ---------------------------------------------------------------------------
PKG=rak_wbc_msgs
DIR="$WS/$PKG"
install -d "$DIR/msg" "$DIR/srv" "$DIR/action"
write_package_xml "$DIR" "$PKG" "rak-wbc message, service and action definitions." \
'  <buildtool_depend>ament_cmake</buildtool_depend>
  <buildtool_depend>rosidl_default_generators</buildtool_depend>
  <exec_depend>rosidl_default_runtime</exec_depend>
  <depend>std_msgs</depend>
  <depend>geometry_msgs</depend>
  <member_of_group>rosidl_interface_packages</member_of_group>' \
  ament_cmake
cat > "$DIR/CMakeLists.txt" <<'EOF'
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
EOF
cat > "$DIR/msg/RobotStatus.msg" <<'EOF'
std_msgs/Header header

uint8 NORMAL_WALK=0
uint8 OBSTACLE_CROSS=1
uint8 FALLEN=2
uint8 FAULT=3
uint8 LOW_BATTERY=4

uint8 state
string detail
float32 battery_percent
EOF
cat > "$DIR/msg/ContactState.msg" <<'EOF'
std_msgs/Header header

string foot
bool in_contact
bool slipping
float32 normal_force
float32 tangential_force
geometry_msgs/Point cop
EOF
cat > "$DIR/msg/Footstep.msg" <<'EOF'
geometry_msgs/Pose pose
float32 swing_height
float32 duration
uint8 support_foot
EOF
cat > "$DIR/msg/FootstepArray.msg" <<'EOF'
std_msgs/Header header
Footstep[] footsteps
EOF
cat > "$DIR/msg/MotionPrimitive.msg" <<'EOF'
std_msgs/Header header
string name
float32[] params
float32 duration
EOF
cat > "$DIR/srv/SetMotionPrimitive.srv" <<'EOF'
string name
float32[] params
---
bool success
string message
EOF
cat > "$DIR/action/ExecuteTask.action" <<'EOF'
string task_id
string[] params
---
bool success
string message
---
string phase
float32 progress
EOF
cat > "$DIR/README.md" <<'EOF'
# rak_wbc_msgs

rak-wbc 的接口定义包。所有跨包通信优先使用这里的消息/服务/Action，避免各自定义私有类型。

## 消息

| 类型 | 用途 |
|---|---|
| `RobotStatus` | 比赛状态码：正常行走/越障/跌倒/故障/低电量 |
| `ContactState` | 单足接触、打滑、法向力、CoP |
| `Footstep` / `FootstepArray` | 落脚点序列 |
| `MotionPrimitive` | 运动基元指令（站/蹲/跪/趴/起身/受控跌倒） |
| `SetMotionPrimitive` | 切换运动基元 |
| `ExecuteTask` | 任务层 Action |

## 约定

- 所有 header 的 `frame_id` 必须符合 REP-105。
- 时间戳统一用 ROS 时间；硬件时间戳在驱动层转换。
EOF

# ---------------------------------------------------------------------------
# description
# ---------------------------------------------------------------------------
PKG=rak_wbc_description
DIR="$WS/$PKG"
install -d "$DIR/urdf" "$DIR/meshes" "$DIR/launch" "$DIR/config"
write_package_xml "$DIR" "$PKG" "Robot description, URDF/xacro and meshes for the Lingxi X2 platform." \
'  <buildtool_depend>ament_cmake</buildtool_depend>
  <exec_depend>xacro</exec_depend>
  <exec_depend>robot_state_publisher</exec_depend>
  <exec_depend>joint_state_publisher</exec_depend>' \
  ament_cmake
cat > "$DIR/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(rak_wbc_description)

find_package(ament_cmake REQUIRED)

install(DIRECTORY urdf meshes launch config
  DESTINATION share/${PROJECT_NAME}
  OPTIONAL)

ament_package()
EOF
cat > "$DIR/urdf/rak_wbc.urdf.xacro" <<'EOF'
<?xml version="1.0"?>
<robot name="rak_wbc" xmlns:xacro="http://www.ros.org/wiki/xacro">
  <!-- TODO: import the official Lingxi X2 URDF/Xacro and add
       inertial, visual, collision, foot contact and sensor frames. -->
  <link name="base_link"/>
</robot>
EOF
cat > "$DIR/meshes/README.md" <<'EOF'
# meshes

放置官方提供的 STL/DAE/OBJ。大文件建议后续接 Git LFS。
EOF
cat > "$DIR/launch/description.launch.py" <<'EOF'
from launch import LaunchDescription


def generate_launch_description() -> LaunchDescription:
    # TODO: run robot_state_publisher with rak_wbc.urdf.xacro.
    return LaunchDescription([])
EOF
cat > "$DIR/config/robot.yaml" <<'EOF'
# Platform parameters. Fill from the official datasheet and on-site measurement.
robot:
  name: lingxi_x2
  mass_kg: null
  height_m: null
  dof: null
  foot_force_sensors: null
EOF
cat > "$DIR/README.md" <<'EOF'
# rak_wbc_description

机器人描述包：URDF/xacro、mesh、传感器坐标系。

## 约定

- `base_link` 为躯干主坐标系；`base_footprint` 投影到地面。
- 所有传感器 frame 命名：`imu_link`、`lidar_link`、`camera_link`、`foot_*_link`。
- 质量/惯量必须来自官方参数或实测，不要用默认值。
EOF

# ---------------------------------------------------------------------------
# hardware
# ---------------------------------------------------------------------------
PKG=rak_wbc_hardware
DIR="$WS/$PKG"
install -d "$DIR/include/$PKG" "$DIR/src" "$DIR/launch" "$DIR/config" "$DIR/test"
write_package_xml "$DIR" "$PKG" "ros2_control hardware interface bridging the Lingxi X2 SDK." \
'  <buildtool_depend>ament_cmake</buildtool_depend>
  <depend>rclcpp</depend>
  <depend>rclcpp_lifecycle</depend>
  <depend>hardware_interface</depend>
  <depend>pluginlib</depend>
  <depend>std_msgs</depend>
  <depend>sensor_msgs</depend>
  <depend>rak_wbc_msgs</depend>' \
  ament_cmake
cat > "$DIR/CMakeLists.txt" <<'EOF'
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
EOF
write_cpp_header "$DIR" "$PKG" "hardware_interface.hpp" "HardwareInterface" \
  "ros2_control SystemInterface for the Lingxi X2 SDK."
cat > "$DIR/src/hardware_interface.cpp" <<'EOF'
// TODO: implement the ros2_control SystemInterface.
// Responsibilities:
//   - open/close the vendor SDK
//   - export joint state, IMU, foot force and battery interfaces
//   - write joint position/torque commands at the SDK rate
//   - keep the real-time path allocation-free
EOF
cat > "$DIR/plugin.xml" <<'EOF'
<library path="rak_wbc_hardware">
  <!-- TODO: declare the hardware_interface::SystemInterface plugin here. -->
</library>
EOF
touch "$DIR/test/.gitkeep"
cat > "$DIR/README.md" <<'EOF'
# rak_wbc_hardware

`ros2_control` 硬件接口，负责把灵犀 X2 官方 SDK 包装成标准的
`hardware_interface::SystemInterface`。

## 必须先确认

- SDK 控制模式：位置 / 速度 / 力矩；最高频率；是否支持流式指令。
- 反馈：关节编码器、IMU、足底力、电池 BMS 的频率与时间戳。
- 急停：软件触发接口；卸力斜坡；是否可读取急停状态。
- 通信：TCP / UDP / CAN / EtherCAT；是否需要实时线程。

## 设计约束

- 实时线程内禁止动态分配、日志写盘、阻塞调用。
- 所有单位统一为 SI（rad、rad/s、N、N·m、m、s）。
- 关节顺序与 `rak_wbc_description` 的 URDF 完全一致。
EOF

# ---------------------------------------------------------------------------
# C++ algorithm / system packages
# ---------------------------------------------------------------------------
write_cpp_pkg rak_wbc_state_estimation \
  "Floating-base state estimation, contact detection and slip detection." \
  "state_estimator.hpp" "StateEstimator" \
  "IMU + leg kinematics + foot force fusion."
write_cpp_pkg rak_wbc_localization \
  "Global localization: LiDAR-inertial odometry fused with GNSS/INS." \
  "localization.hpp" "Localization" \
  "LIO + GNSS fusion and TF map->odom->base_link."
write_cpp_pkg rak_wbc_terrain \
  "2.5D elevation mapping and traversability cost." \
  "elevation_map.hpp" "ElevationMap" \
  "Point cloud to elevation/slope/roughness/step-height layers."
write_cpp_pkg rak_wbc_planning \
  "Global/local planning, boundary constraints and footstep planning." \
  "footstep_planner.hpp" "FootstepPlanner" \
  "Terrain-aware foothold search on a 2.5D cost map."
write_cpp_pkg rak_wbc_control \
  "Whole-body control, centroidal MPC, gait scheduling and motion primitives." \
  "wbc.hpp" "WholeBodyController" \
  "Hierarchical QP over task-space accelerations, torques and contact forces."
write_cpp_pkg rak_wbc_safety \
  "Watchdog, emergency stop sequencing and fault grading." \
  "watchdog.hpp" "Watchdog" \
  "Heartbeat monitoring and slow-unload e-stop sequence."
write_cpp_pkg rak_wbc_logging \
  "rosbag2 recording, event logging and judge telemetry." \
  "event_logger.hpp" "EventLogger" \
  "Structured event log plus MCAP recording."

# Extra control headers
cat > "$WS/rak_wbc_control/include/rak_wbc_control/mpc.hpp" <<'EOF'
#pragma once

// Centroidal MPC placeholder.
// TODO: implement the 50-100 Hz MPC that produces CoM trajectory and contact forces.

namespace rak_wbc {
class CentroidalMpc {
public:
  CentroidalMpc() = default;
  ~CentroidalMpc() = default;
};
}  // namespace rak_wbc
EOF
cat > "$WS/rak_wbc_control/include/rak_wbc_control/motion_primitive.hpp" <<'EOF'
#pragma once

// Motion primitive placeholder: STAND / CROUCH / KNEEL / SIT / PRONE / SUPINE / SIDE.
// TODO: implement the motion graph, phase variable and contact schedule.

namespace rak_wbc {
class MotionPrimitive {
public:
  MotionPrimitive() = default;
  ~MotionPrimitive() = default;
};
}  // namespace rak_wbc
EOF

# Extra state-estimation headers
cat > "$WS/rak_wbc_state_estimation/include/rak_wbc_state_estimation/contact_detector.hpp" <<'EOF'
#pragma once

// Contact and slip detection from foot force, joint velocity and IMU.
// TODO: implement Schmitt-trigger contact detection and slip residual.

namespace rak_wbc {
class ContactDetector {
public:
  ContactDetector() = default;
  ~ContactDetector() = default;
};
}  // namespace rak_wbc
EOF

# Extra terrain headers
cat > "$WS/rak_wbc_terrain/include/rak_wbc_terrain/traversability.hpp" <<'EOF'
#pragma once

// Traversability cost placeholder.
// TODO: combine slope, roughness, step height and semantic free space.

namespace rak_wbc {
class TraversabilityCost {
public:
  TraversabilityCost() = default;
  ~TraversabilityCost() = default;
};
}  // namespace rak_wbc
EOF

# ---------------------------------------------------------------------------
# bringup
# ---------------------------------------------------------------------------
PKG=rak_wbc_bringup
DIR="$WS/$PKG"
install -d "$DIR/launch" "$DIR/config" "$DIR/rviz"
write_package_xml "$DIR" "$PKG" "Launch files and top-level configuration for rak-wbc." \
'  <buildtool_depend>ament_cmake</buildtool_depend>
  <exec_depend>launch</exec_depend>
  <exec_depend>launch_ros</exec_depend>
  <exec_depend>rak_wbc_description</exec_depend>
  <exec_depend>rak_wbc_hardware</exec_depend>
  <exec_depend>rak_wbc_state_estimation</exec_depend>
  <exec_depend>rak_wbc_localization</exec_depend>
  <exec_depend>rak_wbc_perception</exec_depend>
  <exec_depend>rak_wbc_terrain</exec_depend>
  <exec_depend>rak_wbc_planning</exec_depend>
  <exec_depend>rak_wbc_control</exec_depend>
  <exec_depend>rak_wbc_manipulation</exec_depend>
  <exec_depend>rak_wbc_mission</exec_depend>
  <exec_depend>rak_wbc_safety</exec_depend>
  <exec_depend>rak_wbc_logging</exec_depend>' \
  ament_cmake
cat > "$DIR/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(rak_wbc_bringup)

find_package(ament_cmake REQUIRED)

install(DIRECTORY launch config rviz
  DESTINATION share/${PROJECT_NAME}
  OPTIONAL)

ament_package()
EOF
cat > "$DIR/launch/bringup.launch.py" <<'EOF'
from launch import LaunchDescription


def generate_launch_description() -> LaunchDescription:
    """Top-level bringup.

    TODO:
      1. robot_state_publisher + rak_wbc_description
      2. ros2_control_node + rak_wbc_hardware
      3. joint_state_broadcaster + forward_command_controller
      4. state_estimation / localization / terrain
      5. safety watchdog + logging
      6. mission node
    """
    return LaunchDescription([])
EOF
cat > "$DIR/config/bringup.yaml" <<'EOF'
# Top-level bringup parameters. Package-specific parameters live in each package.
bringup:
  use_sim_time: false
  autostart: true
  log_level: info
EOF
cat > "$DIR/rviz/rak_wbc.rviz" <<'EOF'
# TODO: save the standard RViz layout here.
EOF
cat > "$DIR/README.md" <<'EOF'
# rak_wbc_bringup

顶层启动包。比赛/调试只从这里启动，避免每个包各自一套 launch。

## 计划中的 launch

| launch | 用途 |
|---|---|
| `bringup.launch.py` | 真机全系统 |
| `sim.launch.py` | MuJoCo/Gazebo 仿真 |
| `debug.launch.py` | 只启动状态估计 + 控制 + 可视化 |
EOF

# ---------------------------------------------------------------------------
# Python packages
# ---------------------------------------------------------------------------
write_python_pkg rak_wbc_perception \
  "Camera/LiDAR perception: detection, segmentation, markers and visual servoing." \
  "perception_node"
write_python_pkg rak_wbc_manipulation \
  "Upper-body skills: grasp, pull, place, carry and throw." \
  "manipulation_node"
write_python_pkg rak_wbc_mission \
  "Mission orchestration: behavior tree / state machine, time budget and degradation." \
  "mission_node"

# ---------------------------------------------------------------------------
# Make sure launch/config dirs survive git even when empty.
# ---------------------------------------------------------------------------
find "$WS" -type d \( -name launch -o -name config -o -name test \) -empty -exec touch {}/.gitkeep \;

echo "Scaffold complete under $WS"
