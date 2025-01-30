#! /bin/bash

set -e

source /home/ascento/clearpath_ws/install/setup.bash
ros2 launch clearpath_gz simulation.launch.py
