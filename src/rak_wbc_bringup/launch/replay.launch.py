"""Replay a recorded MCAP/rosbag for offline algorithm development.

Usage:
    ros2 launch rak_wbc_bringup bringup.launch.py profile:=replay \
        bag_path:=/path/to/run.mcap
"""

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription(
        [
            DeclareLaunchArgument("bag_path", default_value=""),
            DeclareLaunchArgument("use_sim_time", default_value="true"),
            DeclareLaunchArgument("start_perception", default_value="false"),
            DeclareLaunchArgument("start_planning", default_value="false"),
            # TODO:
            # 1. ros2 bag play <bag_path> --clock
            # 2. start selected algorithm nodes with use_sim_time:=true
            # 3. RViz / Foxglove
        ]
    )
