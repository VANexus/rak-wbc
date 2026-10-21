"""Local development: no real hardware.

Intended for algorithm work on a laptop:
    ros2 launch rak_wbc_bringup bringup.launch.py profile:=dev

Typical set:
  - robot_state_publisher + RViz
  - mock hardware (ros2_control mock_components/GenericSystem) or
    joint_state_publisher
  - selected perception / planning nodes
  - optional rosbag replay
"""

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription(
        [
            DeclareLaunchArgument("use_sim_time", default_value="false"),
            DeclareLaunchArgument("use_mock_hardware", default_value="true"),
            DeclareLaunchArgument("start_rviz", default_value="true"),
            DeclareLaunchArgument("start_perception", default_value="true"),
            DeclareLaunchArgument("start_navigation", default_value="false"),
            # TODO:
            # 1. robot_state_publisher from rak_wbc_description
            # 2. mock ros2_control (mock_components/GenericSystem)
            # 3. joint_state_broadcaster + forward_command_controller
            # 4. RViz with rak_wbc.rviz
            # 5. optionally include perception.launch.py
        ]
    )
