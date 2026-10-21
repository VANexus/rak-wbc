#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROS_DISTRO="${ROS_DISTRO:-lyrical}"
# shellcheck disable=SC1090
source "/opt/ros/${ROS_DISTRO}/setup.bash"

cd "${ROOT}"
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release "$@"
