# Linux workspace - A command line suite with Docker

## Prerequisites
- Docker

This is a workspace suite in the command line, containing the following setup:
- Helix
- Lazygit
- Ripgrep

## Usage
Choose a branch and run:
```git clone -b <branch-name> --single-branch https://github.com/Hustlenut/linux-workspace.git```

Then build the docker image:
```docker build -t workspace .```

Run a container and bind it to a workspace of your choice on the host,
e.g.:
```docker run -v ~/workspace:/root/workspace --rm -p 3000:3000 --name workspace -it <docker_image> sh```
