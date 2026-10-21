"""Full robot bringup: real hardware + sensors + autonomy stack."""

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription(
        [
            DeclareLaunchArgument("use_sim_time", default_value="false"),
            DeclareLaunchArgument("start_sensors", default_value="true"),
            DeclareLaunchArgument("start_perception", default_value="true"),
            DeclareLaunchArgument("start_navigation", default_value="true"),
            DeclareLaunchArgument("start_manipulation", default_value="true"),
            # TODO:
            # 1. robot_state_publisher + rak_wbc_description
            # 2. ros2_control_node + rak_wbc_hardware plugin
            # 3. joint_state_broadcaster + forward_command_controller
            # 4. sensor drivers (IMU, foot force, cameras, LiDAR, GNSS)
            # 5. state_estimation + localization + terrain
            # 6. planning + control + manipulation + mission
            # 7. safety + logging
        ]
    )
