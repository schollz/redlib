# syntax=docker/dockerfile:1

FROM rust:1.89-slim-bookworm AS builder

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        libclang-dev \
        perl \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

COPY Cargo.lock Cargo.toml build.rs ./
COPY src ./src
COPY static ./static
COPY templates ./templates

RUN cargo build --release --locked --bin redlib

FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates wget \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 --no-create-home redlib

COPY --from=builder /src/target/release/redlib /usr/local/bin/redlib

USER redlib

ENV IPV4_ONLY=1 \
    PORT=8080

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://127.0.0.1:8080/settings >/dev/null || exit 1

ENTRYPOINT ["/usr/local/bin/redlib"]
