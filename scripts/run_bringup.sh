#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROS_DISTRO="${ROS_DISTRO:-lyrical}"
# shellcheck disable=SC1090
source "/opt/ros/${ROS_DISTRO}/setup.bash"
# shellcheck disable=SC1091
source "${ROOT}/install/setup.bash"

PROFILE="${PROFILE:-dev}"
ros2 launch rak_wbc_bringup bringup.launch.py "profile:=${PROFILE}" "$@"
