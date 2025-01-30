FROM ros:humble-ros-base

RUN useradd -ms /bin/bash "ascento" && \
  echo "ascento":"ascento" | chpasswd && \
  adduser ascento sudo && \
  echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER ascento

RUN sudo apt-get update && sudo apt-get install -y wget
RUN echo "deb [signed-by=/usr/share/keyrings/gazebo-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" | sudo tee /etc/apt/sources.list.d/gazebo-stable.list
RUN wget -qO- http://packages.osrfoundation.org/gazebo.key | sudo tee /usr/share/keyrings/gazebo-archive-keyring.gpg > /dev/null
RUN sudo apt-get update -qq -y && sudo apt-get install -qq -y ignition-fortress

RUN sudo apt-get update
RUN sudo apt-get install -qq -y \
  ros-humble-clearpath-desktop \
  ros-humble-clearpath-simulator \
  python3-vcstool

RUN sudo apt-get update && sudo apt-get install -qq -y \
  ros-humble-clearpath-sensors || echo "Package not available, skipping installation"

ENV HOME=/home/ascento
ENV WORKSPACE=${HOME}/clearpath_ws
ENV SETUP_DIR=${HOME}/clearpath

RUN mkdir -p ${WORKSPACE}/src
RUN mkdir -p ${SETUP_DIR}

SHELL ["/bin/bash", "-c"]
WORKDIR ${WORKSPACE}
COPY dependencies.repos dependencies.repos
RUN vcs import src < dependencies.repos
RUN rosdep update && rosdep install -r --from-paths src -i -y
RUN source /opt/ros/humble/setup.bash && colcon build --symlink-install

RUN sudo apt-get install -qq -y nano

COPY robot.yaml ${SETUP_DIR}/robot.yaml
RUN source /opt/ros/humble/setup.bash && ros2 run clearpath_generator_common generate_bash -s ${SETUP_DIR}

WORKDIR ${HOME}
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
