FROM lukemathwalker/cargo-chef:latest-rust-1.84.0-slim-bookworm AS chef
WORKDIR app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
RUN apt update && apt install build-essential -y
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
RUN cargo build --release --bin atuin

FROM debian:bookworm-20250113-slim AS runtime

# Create user with home directory and config directory
RUN useradd -m -c 'atuin user' atuin && \
    mkdir /config && \
    chown atuin:atuin /config

# Install runtime dependencies
RUN apt update && \
    apt install ca-certificates -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
USER atuin

# Set environment variables
ENV TZ=Etc/UTC
ENV RUST_LOG=atuin::api=info
ENV ATUIN_CONFIG_DIR=/config

COPY --from=builder /app/target/release/atuin /usr/local/bin
ENTRYPOINT ["/usr/local/bin/atuin"]
