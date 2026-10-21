SHELL := /bin/bash
ROS_DISTRO ?= lyrical
ROS_SETUP := /opt/ros/$(ROS_DISTRO)/setup.bash

.PHONY: help build test clean docs fmt lint precommit packages

help:
	@echo "make build      - colcon build (Release, symlink-install)"
	@echo "make test       - colcon test"
	@echo "make clean      - remove build/install/log"
	@echo "make fmt        - clang-format all C++ sources"
	@echo "make lint       - clang-tidy (requires build/compile_commands.json)"
	@echo "make packages   - list ROS 2 packages"
	@echo "make docs       - print docs index path"

build:
	source $(ROS_SETUP) && \
	  colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release

test:
	source $(ROS_SETUP) && \
	  colcon test --event-handlers console_direct+ && colcon test-result --verbose

clean:
	rm -rf build install log

docs:
	@echo "docs index: docs/README.md"
	@echo "architecture: docs/03-architecture/system-architecture.md"

fmt:
	find src -type f \( -name '*.cpp' -o -name '*.hpp' -o -name '*.h' -o -name '*.cc' \) \
	  -print0 | xargs -0 -r clang-format -i

lint:
	find src -type f \( -name '*.cpp' -o -name '*.cc' \) \
	  -print0 | xargs -0 -r clang-tidy -p build

packages:
	source $(ROS_SETUP) && colcon list

precommit:
	pre-commit run --all-files
