"""Simulation bringup (MuJoCo / Gazebo).

Validation only. See ADR-0002: no sim2real policy training in this project.
"""

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription(
        [
            DeclareLaunchArgument("use_sim_time", default_value="true"),
            DeclareLaunchArgument(
                "simulator",
                default_value="mujoco",
                description="mujoco | gazebo",
            ),
            # TODO:
            # 1. start the selected simulator bridge
            # 2. robot_state_publisher
            # 3. state_estimation + terrain + planning + control
            # 4. RViz / Foxglove for inspection
        ]
    )
