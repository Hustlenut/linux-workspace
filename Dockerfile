##############################################
############ Stage 1: Build Stage ############
##############################################
FROM alpine:3.20 AS builder

ARG HOST_UID
ARG HOST_GID
ARG HOST_USER

WORKDIR /root

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

# Install rustup and set up Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    source $HOME/.cargo/env && \
    rustup target add x86_64-unknown-linux-musl

# Set Rust flags for musl-libc compatibility
ENV RUSTFLAGS="-C target-feature=-crt-static"
# Add Helix to PATH
ENV PATH="/root/.cargo/bin:${PATH}"

# Clone the Helix repository
RUN git clone --recurse-submodules https://github.com/helix-editor/helix.git /root/helix

# Compile Helix from source
RUN cd /root/helix && cargo install --path helix-term --locked

# Create a virtual environment for Python LSP in the user's home directory
RUN mkdir -p /home/$HOST_USER && \
    python3 -m venv /home/$HOST_USER/venv 

# Fetch and build Helix grammars
RUN hx --grammar fetch && hx --grammar build

# Install lazygit
RUN wget https://github.com/jesseduffield/lazygit/releases/download/v0.41.0/lazygit_0.41.0_Linux_x86_64.tar.gz \
    && tar xf lazygit_0.41.0_Linux_x86_64.tar.gz \
    && mv lazygit /usr/local/bin/ \
    && rm lazygit_0.41.0_Linux_x86_64.tar.gz

##############################################
############ Stage 2: Final Stage ############
##############################################
FROM alpine:3.20

ARG HOST_UID
ARG HOST_GID
ARG HOST_USER

WORKDIR /root

# Copy Helix and its runtime from the builder stage
COPY --from=builder /root/.cargo/bin/hx /root/.cargo/bin/
COPY --from=builder /root/helix/runtime /root/helix/runtime

# Copy the virtual environment and installed tools
COPY --from=builder /home/$HOST_USER/venv /home/$HOST_USER/venv
COPY --from=builder /usr/local/bin/lazygit /usr/local/bin/lazygit

# Install runtime dependencies only
RUN apk add --no-cache \
    git \
    ripgrep \
    python3 \
    py3-pip \
    xclip \
    fish \
    nodejs \
    npm \
    && npm install -g bash-language-server dockerfile-language-server-nodejs markdownlint-cli

# Copy Helix configuration files
COPY helix-config/config.toml /root/.config/helix/config.toml
COPY helix-config/language.toml /root/.config/helix/language.toml

# Set environment variables for Helix and shell
ENV PATH="/root/.cargo/bin:/home/$HOST_USER/venv/bin:${PATH}"
ENV HELIX_RUNTIME="/root/helix/runtime"
ENV TERM=xterm-256color
ENV COLORTERM=truecolor

# Set Fish shell configuration for PATH
RUN mkdir -p /root/.config/fish && \
    echo 'set -gx PATH /root/.cargo/bin $PATH' >> /root/.config/fish/config.fish

# Create a user with the same UID and GID as the host user
RUN addgroup -g $HOST_GID $HOST_USER && \
    adduser -D -u $HOST_UID -G $HOST_USER $HOST_USER

# Set up user's home directory
RUN mkdir -p /home/$HOST_USER && \
    chown -R $HOST_USER:$HOST_USER /home/$HOST_USER

# Set correct permissions for the virtual environment
RUN chown -R $HOST_USER:$HOST_USER /home/$HOST_USER/venv && \
    chmod -R 755 /home/$HOST_USER/venv

# Switch to the new user
USER $HOST_USER
WORKDIR /home/$HOST_USER

# Clean up unnecessary files
RUN rm -rf /var/cache/apk/* /tmp/*

# Activate venv for pylsp and use fish as default shell
ENTRYPOINT ["/bin/sh", "-c", "source /home/$HOST_USER/venv/bin/activate && exec fish"]
