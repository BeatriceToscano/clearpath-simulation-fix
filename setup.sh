#! /bin/bash

set -e

IMAGE_NAME=clearpath-simulation:latest

echo "Image does not exist. Building image..."
docker buildx build --output=type=docker -f Dockerfile -t ${IMAGE_NAME} .

docker run --rm -it --name 2025-production-takehome \
    -v /tmp/.X11-unix:/tmp/.X11-unix \
    -e DISPLAY=$DISPLAY \
    -v /dev:/dev --privileged --net=host clearpath-simulaiton:latest ./entrypoint.sh

