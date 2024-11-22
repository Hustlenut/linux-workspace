##############################################
############ Stage 1: Build Stage ############
##############################################
FROM alpine:3.20 AS builder

WORKDIR /root

RUN apk update && apk add --no-cache \
    git=2.45.2-r0 \
    curl=8.11.0-r2 \
    gcc=13.2.1_git20240309-r0 \
    g++=13.2.1_git20240309-r0 \
    make=4.4.1-r2 \
    cmake=3.29.3-r0 \
    cargo=1.78.0-r0 \
    rust=1.78.0-r0 \
    llvm-dev=17.0.6-r1 \
    musl-dev=1.2.5-r0

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

# Create a user with the same UID and GID as the host user
RUN addgroup -g $HOST_GID $HOST_USER && \
    adduser -D -u $HOST_UID -G $HOST_USER $HOST_USER

# Install runtime dependencies
RUN apk update && apk add --no-cache \
    git=2.45.2-r0 \
    ripgrep=14.1.0-r0 \
    python3=3.12.7-r0 \
    py3-pip=24.0-r2 \
    xclip=0.13-r3 \
    fish=3.7.1-r0 \
    curl=8.11.0-r2 \
    nodejs=20.15.1-r0 \
    npm=10.8.0-r0 \
    && npm install -g bash-language-server@5.4.2 dockerfile-language-server-nodejs@0.13.0 markdownlint-cli@0.42.0

# Copy Helix and its runtime from the builder stage
COPY --from=builder /root/.cargo/bin/hx /usr/local/bin/
COPY --from=builder /root/helix/runtime /usr/local/share/helix/runtime
COPY --from=builder /usr/local/bin/lazygit /usr/local/bin/lazygit

# Create a virtual environment for Python LSP
RUN python3 -m venv /home/$HOST_USER/venv && \
    chown -R $HOST_USER:$HOST_USER /home/$HOST_USER/venv && \
    /home/$HOST_USER/venv/bin/pip install python-lsp-server

# Copy Helix configuration files
COPY helix-config/config.toml /home/$HOST_USER/.config/helix/config.toml
COPY helix-config/language.toml /home/$HOST_USER/.config/helix/language.toml

# Set ownership of config files
RUN chown -R $HOST_USER:$HOST_USER /home/$HOST_USER/.config

# Set environment variables for Helix and shell
ENV PATH="/usr/local/bin:/home/$HOST_USER/venv/bin:${PATH}"
ENV HELIX_RUNTIME="/usr/local/share/helix/runtime"
ENV TERM=xterm-256color
ENV COLORTERM=truecolor

# Set Fish shell configuration for PATH
RUN mkdir -p /home/$HOST_USER/.config/fish && \
    echo 'set -gx PATH /usr/local/bin $PATH' >> /home/$HOST_USER/.config/fish/config.fish && \
    chown -R $HOST_USER:$HOST_USER /home/$HOST_USER/.config/fish

# Clean up unnecessary files
RUN rm -rf /var/cache/apk/* /tmp/*

# Switch to the new user
USER $HOST_USER
WORKDIR /home/$HOST_USER

# Activate venv for pylsp and use fish as default shell
ENTRYPOINT ["/bin/sh", "-c", "source /home/$HOST_USER/venv/bin/activate && exec fish"]
