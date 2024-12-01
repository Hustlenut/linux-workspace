##############################################
############ Stage 1: Build stage ############
##############################################
FROM registry.access.redhat.com/ubi9/ubi-minimal AS builder

# Set the working directory
WORKDIR /root

# Remove existing Rust installation if it exists (ignore errors if it isn't installed)
RUN microdnf remove -y rust rustc cargo && microdnf clean all || true

# Install necessary development tools and libraries
RUN microdnf install -y git gcc gcc-c++ make cmake llvm-devel && \
    microdnf clean all

# Install Rust using rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    source $HOME/.cargo/env && \
    rustup target add x86_64-unknown-linux-gnu

# Set environment variables for Rust
ENV RUSTFLAGS="-C target-feature=-crt-static"
ENV PATH="/root/.cargo/bin:${PATH}"

# Clone the Helix editor repository and build it
RUN git clone --recurse-submodules https://github.com/helix-editor/helix.git /root/helix && \
    cd /root/helix && \
    cargo install --path helix-term --locked && \
    hx --grammar fetch && hx --grammar build

##############################################
############ Stage 2: Final stage ############
##############################################
FROM registry.access.redhat.com/ubi9/ubi-minimal

# Copy Helix and its runtime from the builder stage
COPY --from=builder /root/.cargo/bin/hx /usr/local/bin/
COPY --from=builder /root/helix/runtime /usr/local/share/helix/runtime

# Copy Helix configuration files
COPY helix-config/config.toml /home/helix_user/.config/helix/config.toml
COPY helix-config/language.toml /home/helix_user/.config/helix/language.toml

# Create necessary directories for Helix
RUN mkdir -p /home/helix_user/.cache/helix && \
    mkdir -p /home/helix_user/.config/helix/runtime && \
    mkdir -p /usr/local/share/helix/runtime

# Set environment variables for Helix runtime
ENV HELIX_RUNTIME="/usr/local/share/helix/runtime"
ENV TERM=xterm-256color
ENV COLORTERM=truecolor

# This has to correspond with the binded volume in the podman-compose.yml
WORKDIR /home/helix_user/workspace

# Set entry point to run a shell, allowing for command execution
ENTRYPOINT ["hx"]
