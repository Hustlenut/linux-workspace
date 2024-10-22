FROM alpine:3.20

# Set the working directory
WORKDIR /root

# Install necessary build tools and dependencies
RUN apk add --no-cache \
    git \
    gcc \
    g++ \
    make \
    cmake \
    ripgrep \
    python3 \
    py3-pip \
    xclip \
    fish \
    curl \
    cargo \
    rust \
    llvm-dev \
    musl-dev

# Set Rust flags for musl-libc compatibility
ENV RUSTFLAGS="-C target-feature=-crt-static"
# Add Helix to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

# Clone the Helix repository
RUN git clone --recurse-submodules https://github.com/helix-editor/helix.git /root/helix

# Compile from source
RUN cd /root/helix \
    && cargo install --path helix-term --locked

# Create a virtual environment for Python LSP
RUN python3 -m venv /root/venv \
    && . /root/venv/bin/activate \
    && pip install 'python-lsp-server[all]'

# Install Node.js-based language servers
RUN apk add --no-cache nodejs npm \
    && npm install -g bash-language-server dockerfile-language-server-nodejs markdownlint-cli

# Configure Helix runtime directory
ENV HELIX_RUNTIME="/root/helix/runtime"
RUN mkdir -p "$HELIX_RUNTIME"

# Copy Helix configuration files
COPY helix-config/config.toml /root/.config/helix/config.toml
COPY helix-config/language.toml /root/.config/helix/language.toml

# Set Fish shell configuration for PATH
RUN mkdir -p /root/.config/fish && \
    echo 'set -gx PATH /root/.cargo/bin $PATH' >> /root/.config/fish/config.fish

# Set environment variables for terminal to support true colors
ENV TERM=xterm-256color
ENV COLORTERM=truecolor

# Fetch and build Helix grammars
RUN hx --grammar fetch && hx --grammar build

# Clean up unnecessary packages and temporary files
RUN apk del gcc g++ make cmake cargo rust && \
    rm -rf /var/cache/apk/* /tmp/* /root/.config/helix/runtime

# Install lazygit
RUN wget https://github.com/jesseduffield/lazygit/releases/download/v0.41.0/lazygit_0.41.0_Linux_x86_64.tar.gz \
    && tar xf lazygit_0.41.0_Linux_x86_64.tar.gz \
    && mv lazygit /usr/local/bin/ \
    && rm lazygit_0.41.0_Linux_x86_64.tar.gz

# Activate venv for pylsp and use fish
ENTRYPOINT ["/bin/sh", "-c", "source /root/venv/bin/activate && exec fish"]
