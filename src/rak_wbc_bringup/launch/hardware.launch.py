"""Hardware-only bringup for on-robot actuator and sensor checks.

Use this on the robot before the full autonomy stack is ready:
    ros2 launch rak_wbc_bringup bringup.launch.py profile:=hardware
"""

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription(
        [
            DeclareLaunchArgument("use_sim_time", default_value="false"),
            # TODO:
            # 1. robot_state_publisher + rak_wbc_description
            # 2. ros2_control_node + rak_wbc_hardware plugin
            # 3. joint_state_broadcaster + forward_command_controller
            # 4. state_estimation (IMU + leg kinematics + foot force)
            # 5. safety watchdog + rosbag2 logging
            # No perception, planning, manipulation or mission nodes.
        ]
    )
