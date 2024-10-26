##############################################
############ Stage 1: Build Stage ############
##############################################
FROM alpine:3.20 AS builder

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

# Compile Helix from source
RUN cd /root/helix \
    && cargo install --path helix-term --locked

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

# Set the working directory
WORKDIR /root

# Copy Helix and its runtime from the builder stage
COPY --from=builder /root/.cargo/bin/hx /root/.cargo/bin/
COPY --from=builder /root/helix/runtime /root/helix/runtime

# Copy the virtual environment and installed tools
COPY --from=builder /usr/local/bin/lazygit /usr/local/bin/lazygit

# Install runtime dependencies only
RUN apk add --no-cache \
    git \
    ripgrep \
    xclip \
    fish \
    npm \
    && npm install -g bash-language-server dockerfile-language-server-nodejs markdownlint-cli

# Copy Helix configuration files
COPY helix-config/config.toml /root/.config/helix/config.toml
COPY helix-config/language.toml /root/.config/helix/language.toml

# Set environment variables for Helix and shell
ENV PATH="/root/.cargo/bin:${PATH}"
ENV HELIX_RUNTIME="/root/helix/runtime"
ENV TERM=xterm-256color
ENV COLORTERM=truecolor

# Set Fish shell configuration for PATH
RUN mkdir -p /root/.config/fish && \
    echo 'set -gx PATH /root/.cargo/bin $PATH' >> /root/.config/fish/config.fish

# Clean up unnecessary files
RUN rm -rf /var/cache/apk/* /tmp/*

# Activate venv for pylsp and use fish
ENTRYPOINT ["/bin/sh", "-c", "source /root/venv/bin/activate && exec fish"]
