#!/bin/bash

# Script to build and run a Docker container as the current host user

# Function to display usage information
usage() {
    echo "Usage: $0 [build|run] [command]"
    echo "  build: Build the Docker image"
    echo "  run: Run the Docker container"
    echo "  [command]: Optional command to run in the container (default: sh)"
    exit 1
}

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
    usage
fi

# Get current user's UID and GID
HOST_UID=$(id -u)
HOST_GID=$(id -g)

# Get current username
HOST_USER=$(whoami)

# Image name
IMAGE_NAME="linux-workspace"

# Function to check if the Docker image exists
check_image_exists() {
    if [[ "$(docker images -q $IMAGE_NAME 2> /dev/null)" == "" ]]; then
        return 1  # Image does not exist
    else
        return 0  # Image exists
    fi
}

# Function to check and set xhost
check_xhost() {
    if ! xhost &>/dev/null; then
        echo "xhost command not found. Please install xorg-xhost package."
        exit 1
    fi

    if ! xhost | grep -q "LOCAL:"; then
        echo "Setting xhost for local connections..."
        xhost +local: &>/dev/null
    fi
}

# Function to build the Docker image
build_image() {
    echo "Building Docker image: $IMAGE_NAME"
    DOCKER_BUILDKIT=1 docker build \
        --build-arg HOST_UID=$HOST_UID \
        --build-arg HOST_GID=$HOST_GID \
        --build-arg HOST_USER=$HOST_USER \
        -t $IMAGE_NAME --no-cache .
}

# Run the Docker container
run_container() {
    echo "Running Docker container as user $HOST_USER (UID:$HOST_UID, GID:$HOST_GID)"
    
    # Check and set xhost
    check_xhost
    
    # Default command if none provided
    CMD=${@:-sh}
    
    docker run --rm --name workspace \
        -v ~/workspace:/home/$HOST_USER/workspace \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        -v ~/.Xauthority:/home/$HOST_USER/.Xauthority \
        -e DISPLAY=$DISPLAY \
        -e HOME=/home/$HOST_USER \
	-e HOST_USER=$HOST_USER \
        --net=host \
        --user $HOST_UID:$HOST_GID \
        -it $IMAGE_NAME $CMD
}

# Main logic
case "$1" in
    build)
        if check_image_exists; then
            echo "Docker image '$IMAGE_NAME' already exists. Skipping build."
        else
            build_image
        fi
        ;;
    run)
        shift
        run_container "$@"
        ;;
    *)
        usage
        ;;
esac
