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
