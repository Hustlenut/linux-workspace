#!/bin/bash
 
# Script to build Podman containers and install shell functions for the current user

registry_prefix="localhost"
helix_version="24.7"
current_dir=$PWD

# Function to display usage information
usage() {
    echo "Usage: $0 [build|install-bash|install-fish]"
    echo "  build: Build the Podman images"
    echo "  install-bash: Install hx function in .bashrc"
    echo "  install-fish: Install hx function in Fish config"
    exit 1
}

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
    usage
fi

# Function to check if the Podman images exist
check_image_exists() {
    if [[ "$(podman images -q helix:$helix_version 2> /dev/null)" == "" ]] || \
       [[ "$(podman images -q pylsp:latest 2> /dev/null)" == "" ]]; then
        return 1  # One or both images do not exist
    else
        return 0  # Both images exist
    fi
}

# Function to check and set xhost for X11 forwarding
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

# Build using podman-compose
build() {
    # Check xhost settings for X11 forwarding
    check_xhost

    # Check if the Podman image exists before building
    if check_image_exists; then
        echo "Podman images 'helix:$helix_version' and 'pylsp:latest' already exist. Skipping build."
    else
        echo "Building Podman images..."
        podman network create --subnet 10.89.0.0/24 workspace
	      podman build -f helix/Dockerfile -t helix:$helix_version helix/
        podman-compose -f podman-compose.yml build
    fi
}

# Install hx function in .bashrc
install_bash_function() {
    local BASH_FUNC="hx() {
        podman-compose -f ${PWD}/podman-compose.yml up -d;
        podman-compose -f ${PWD}/podman-compose.yml exec helix hx \"\$@\";
        podman-compose -f ${PWD}/podman-compose.yml down;
    }"

    # Append function to .bashrc if it doesn't already exist
    if ! grep -Fxq "$BASH_FUNC" ~/.bashrc; then
        echo "$BASH_FUNC" >> ~/.bashrc
        echo "hx function installed in .bashrc. Please run 'source ~/.bashrc' to apply changes."
    else
        echo "hx function already exists in .bashrc."
    fi
}

# Install hx function in Fish config
install_fish_function() {
    local FISH_FUNC="function hx
    ## Start the container in detached mode
    podman-compose -f /home/hustlenut/linux-workspace/podman-compose.yml up -d

    # Execute Helix inside the running container
    podman run \
        --entrypoint hx \
        -it \
        -v $PWD:$PWD \
        --workdir=$PWD \
        -v $HOME/linux-workspace/helix/helix-config:/home/helix_user/.config/helix \
        -e DISPLAY=$DISPLAY \
        $registry_prefix/helix:$helix_version \
        $argv
    end"

    # Append function to Fish config if it doesn't already exist
    if ! grep -Fxq "$FISH_FUNC" ~/.config/fish/config.fish; then
        echo "$FISH_FUNC" >> ~/.config/fish/config.fish
        echo "hx function installed in Fish config. Please restart your Fish shell or run 'source ~/.config/fish/config.fish' to apply changes."
    else
        echo "hx function already exists in Fish config."
    fi
}

# Main logic to handle commands.
case "$1" in
    build)
        build   # Call the build function.
        ;;
    install-bash)
        install_bash_function   # Call the bash installation function.
        ;;
    install-fish)
        install_fish_function   # Call the fish installation function.
        ;;
    *)
        usage   # Display usage information for invalid commands.
        ;;
esac

