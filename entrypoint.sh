#! /bin/bash

set -e

source /home/ascento/catkin_ws/setup.bash
ros2 launch clearpath_gz simulation.launch.py
