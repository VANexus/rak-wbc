"""Top-level launch dispatcher.

Select a profile with:
    ros2 launch rak_wbc_bringup bringup.launch.py profile:=dev

Profiles:
    robot       real hardware + sensors + full autonomy
    hardware    real hardware + controllers + state estimation only
    sim         simulation bridge + full autonomy
    dev         local development (mock hardware / RViz / selected nodes)
    perception  sensors + perception + terrain only
    replay      rosbag/MCAP replay + selected nodes
"""

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, IncludeLaunchDescription, LogInfo
from launch.conditions import LaunchConfigurationEquals
from launch.launch_description_sources import PythonLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare


def _profile_include(name: str, filename: str) -> IncludeLaunchDescription:
    return IncludeLaunchDescription(
        PythonLaunchDescriptionSource(
            PathJoinSubstitution(
                [FindPackageShare("rak_wbc_bringup"), "launch", filename]
            )
        ),
        condition=LaunchConfigurationEquals("profile", name),
    )


def generate_launch_description() -> LaunchDescription:
    return LaunchDescription(
        [
            DeclareLaunchArgument(
                "profile",
                default_value="dev",
                description="robot | hardware | sim | dev | perception | replay",
            ),
            LogInfo(msg=["rak-wbc profile: ", LaunchConfiguration("profile")]),
            _profile_include("robot", "robot.launch.py"),
            _profile_include("hardware", "hardware.launch.py"),
            _profile_include("sim", "sim.launch.py"),
            _profile_include("dev", "dev.launch.py"),
            _profile_include("perception", "perception.launch.py"),
            _profile_include("replay", "replay.launch.py"),
        ]
    )
