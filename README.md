# Linux workspace - Python

## Prerequisites
- Docker
- **Highly recommend that each running container 
    should have a dedicated python venv**

## Content
This is a workspace suite in the command line, containing the 
following setup (*Docker image size: ~1,7 GB*):
- Helix
- Lazygit
- Ripgrep

Included LSP(s):
- python-lsp (pip)
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
