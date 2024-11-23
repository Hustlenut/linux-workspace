# Linux workspace - A command line suite with Docker

## Prerequisites
- Docker

## Purpose
This setup offers an isolated, easily deployable, and quickly removable environment for 
each project. It extends the host system's tools temporarily, using the current host 
user's credentials to create an equivalent user within the container.

## Content
This is a workspace suite in the command line, containing the following setup:
- Helix
- Lazygit
- Ripgrep

Included LSP(s):
- bash-language-server (npm)
- dockerfile-language-server-nodejs (npm)
- markdownlint-cli (npm)

## Usage
Choose a branch and run:

```git clone -b <branch-name> --single-branch https://github.com/Hustlenut/linux-workspace.git```

Available branches/languages:
- Python


From the base directory, build the docker image:

```./setup.sh build```

Then run it!

```./setup.sh run```
