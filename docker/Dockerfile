ARG ROS_DISTRO=lyrical
FROM ros:${ROS_DISTRO}-ros-base

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-pip \
    libeigen3-dev \
    libboost-all-dev \
    liburdfdom-dev \
    liburdfdom-headers-dev \
    ros-${ROS_DISTRO}-xacro \
    ros-${ROS_DISTRO}-robot-state-publisher \
    ros-${ROS_DISTRO}-joint-state-publisher \
    ros-${ROS_DISTRO}-tf2-ros \
    ros-${ROS_DISTRO}-tf2-eigen \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace
COPY . /workspace

RUN . /opt/ros/${ROS_DISTRO}/setup.sh && \
    cd /workspace && \
    colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release

SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["bash"]
