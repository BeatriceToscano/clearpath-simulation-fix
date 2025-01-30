FROM ros:humble-ros-base

RUN useradd -ms /bin/bash "ascento" && \
  echo "ascento":"ascento" | chpasswd && \
  adduser ascento sudo && \
  echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER ascento

# Install the simulation engine
RUN sudo apt-get update && sudo apt-get install wget
RUN sudo sh -c 'echo "deb http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" > /etc/apt/sources.list.d/gazebo-stable.list'
RUN wget http://packages.osrfoundation.org/gazebo.key -O - | sudo apt-key add -
RUN sudo apt-get update -qq -y && sudo apt-get  -qq -y install ignition-fortress

# Install software
RUN sudo apt-get update
RUN sudo apt-get install -qq -y \
  ros-humble-clearpath-desktop \
  ros-humble-clearpath-simulator \
  python3-vcstool


# Install clearpath debian packages
# Mmmm.... this does not seem to work. I found this interesting issue, maybe it can help!
# See https://github.com/clearpathrobotics/clearpath_simulator/issues/66
RUN sudo apt-get update && sudo apt-get install -qq -y \
  ros-humble-clearpath-sensors

# Generate filesystem and setup
ENV HOME=/home/ascento
ENV WORKSPACE=${HOME}/clearpath_ws
ENV SETUP_DIR=${HOME}/clearpath

RUN mkdir -p ${WORKSPACE}/src
RUN mkdir -p ${SETUP_DIR}

# Install the workspace and its dependencies
SHELL ["/bin/bash", "-c"]
WORKDIR ${WORKSPACE}
COPY dependencies.repos dependencies.repos
RUN vcs import src < dependencies.repos
RUN rosdep update && rosdep install -r --from-paths src -i -y
RUN source /opt/ros/humble/setup.bash && colcon build --symlink-install

# Install utility
RUN sudo apt-get install -qq -y nano

# Generate the setup configuration
COPY robot.yaml ${SETUP_DIR}/robot.yaml
RUN source /opt/ros/humble/setup.bash && ros2 run clearpath_generator_common generate_bash -s ${SETUP_DIR}

WORKDIR ${HOME}
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
