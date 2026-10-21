#!/usr/bin/env bash
# Install workspace dependencies. Safe to re-run.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROS_DISTRO="${ROS_DISTRO:-lyrical}"
ROS_SETUP="/opt/ros/${ROS_DISTRO}/setup.bash"

if [[ ! -f "${ROS_SETUP}" ]]; then
  echo "ROS 2 setup not found: ${ROS_SETUP}" >&2
  echo "Set ROS_DISTRO to the installed distribution." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "${ROS_SETUP}"

echo "[1/3] rosdep update"
rosdep update || true

echo "[2/3] rosdep install"
rosdep install --from-paths "${ROOT}/src" --ignore-src -r -y || true

echo "[3/3] optional tooling"
command -v pre-commit >/dev/null 2>&1 || echo "  pre-commit not installed (optional)"
command -v clang-format >/dev/null 2>&1 || echo "  clang-format not installed (optional)"

echo "Done. Next: make build"
