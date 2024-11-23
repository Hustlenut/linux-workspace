# Linux workspace - A command line suite with Docker

## Prerequisites
- Docker

## Purpose
This setup provides an isolated environment, designed for easy availability
and quick teardown on a per-project basis. It serves as a temporary extension
of the tools available on the (host) operating system.

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


From the base directory build the docker image:

```./setup.sh build```

Then run it!

```./setup.sh run```
