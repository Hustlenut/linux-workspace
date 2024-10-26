# Linux workspace - A command line suite with Docker

## Prerequisites
- Docker
- xclip/wl-clipboard

## Content
This is a workspace suite in the command line, containing the following setup:
- Helix
  - with following LSPs: Docker, bash and for the programming language of current branch.
- Lazygit
- Ripgrep

Supported languages:
- Python (*Docker image size: 1,6 GB*)

## Usage
Choose a branch and run:
```git clone -b <branch-name> --single-branch https://github.com/Hustlenut/linux-workspace.git```

Then build the docker image:
```DOCKER_BUILDKIT=1 docker build -t <image_name> --no-cache .```

Ensure that the host machine has xclip or wl-clipboard.
Run a container and bind it to a workspace of your choice on the host,
e.g.:
```
docker run --rm -p 3000:3000 --name workspace \
                        -v ~/workspace:/root/workspace \
                        -v /tmp/.X11-unix:/tmp/.X11-unix \
                        -v ~/.Xauthority:/root/.Xauthority \
                        -e DISPLAY=$DISPLAY \
                        --net=host \
                        -it <image_name> sh
```
