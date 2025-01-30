FROM --platform=linux/amd64 ros:humble-ros-base

# Usa bash come shell predefinita
SHELL ["/bin/bash", "-c"]

# Creazione dell'utente "ascento" con privilegi sudo
RUN useradd -m -s /bin/bash ascento && \
    echo "ascento:ascento" | chpasswd && \
    usermod -aG sudo ascento && \
    echo "ascento ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ascento


USER ascento

# Installazione del motore di simulazione
RUN sudo apt-get update && sudo apt-get install -y wget
RUN echo "deb [signed-by=/usr/share/keyrings/gazebo-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable `lsb_release -cs` main" | \
    sudo tee /etc/apt/sources.list.d/gazebo-stable.list
RUN wget -qO- http://packages.osrfoundation.org/gazebo.key | sudo tee /usr/share/keyrings/gazebo-archive-keyring.gpg > /dev/null
RUN sudo apt-get update -qq -y && sudo apt-get install -qq -y ignition-fortress

# Installazione dei pacchetti necessari
RUN sudo apt-get update
RUN sudo apt-get install -qq -y \
    ros-humble-clearpath-desktop \
    ros-humble-clearpath-simulator \
    python3-vcstool

# Installazione dei pacchetti Clearpath (con gestione errori)
RUN sudo apt-get update && sudo apt-get install -qq -y ros-humble-clearpath-sensors || \
    echo "ros-humble-clearpath-sensors non disponibile, proseguo comunque."

# Definizione delle variabili di ambiente
ENV HOME=/home/ascento
ENV WORKSPACE=${HOME}/clearpath_ws
ENV SETUP_DIR=${HOME}/clearpath

# Creazione delle directory necessarie
RUN mkdir -p ${WORKSPACE}/src ${SETUP_DIR}

# Copia delle dipendenze e setup della workspace
WORKDIR ${WORKSPACE}
COPY dependencies.repos dependencies.repos
RUN vcs import src < dependencies.repos
RUN rosdep update && rosdep install -r --from-paths src -i -y
RUN source /opt/ros/humble/setup.bash && colcon build --symlink-install

# Installazione di nano per debug
RUN sudo apt-get install -qq -y nano

# Configurazione del robot
COPY robot.yaml ${SETUP_DIR}/robot.yaml
RUN source /opt/ros/humble/setup.bash && ros2 run clearpath_generator_common generate_bash -s ${SETUP_DIR}

# Configurazione del punto di ingresso
WORKDIR ${HOME}
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
