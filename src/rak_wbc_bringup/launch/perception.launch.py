"""Perception / terrain development: sensors + perception, no locomotion.

Use on a laptop with recorded data or on the robot while standing still.
"""

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription(
        [
            DeclareLaunchArgument("use_sim_time", default_value="false"),
            DeclareLaunchArgument("start_camera", default_value="true"),
            DeclareLaunchArgument("start_lidar", default_value="true"),
            DeclareLaunchArgument("start_rviz", default_value="true"),
            # TODO:
            # 1. camera driver(s)
            # 2. LiDAR driver
            # 3. rak_wbc_perception
            # 4. rak_wbc_terrain
            # 5. RViz / Foxglove
        ]
    )
