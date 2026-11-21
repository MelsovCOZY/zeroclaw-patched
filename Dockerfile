# ZeroClaw built from an upstream release tag with the patches in patches/ applied.
# The final image is the official ZeroClaw Debian image with only the binary replaced,
# so everything else (user, HOME, entrypoint, web dashboard, tools) matches upstream.

ARG ZEROCLAW_REF=v0.9.0
ARG ZEROCLAW_IMAGE=ghcr.io/zeroclaw-labs/zeroclaw:v0.9.0-debian

FROM ${ZEROCLAW_IMAGE} AS upstream

# Same Rust base image the upstream Dockerfile.debian pins for v0.9.0.
FROM rust:1.98-bookworm@sha256:93ce27a88655056a51dbdd8f5f2d7ddc071c7b0070fb288a37b5a285fc83971e AS build
ARG ZEROCLAW_REF
RUN apt-get update \
    && apt-get install -y --no-install-recommends pkg-config g++ git \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone --depth 1 --branch "${ZEROCLAW_REF}" https://github.com/zeroclaw-labs/zeroclaw.git .
COPY patches/ /patches/
RUN for p in /patches/*.patch; do echo "applying $p"; git apply --verbose "$p"; done
# The web dashboard is embedded at compile time; reuse the identical build from the official image.
COPY --from=upstream /usr/share/zeroclawlabs/web/dist web/dist
# Feature set copied from upstream Dockerfile.debian (v0.9.0) so the binary matches the official one.
ARG ZEROCLAW_CARGO_FLAGS="--no-default-features --features acp-bridge,agent-runtime,channel-acp-server,channel-discord,channel-email,channel-filesystem,channel-git,channel-lark,channel-matrix,channel-telegram,channel-webhook,gateway,observability-prometheus,plugins-wasm-cranelift,schema-export,tool-claude-code,tool-claude-code-runner,tool-codex-cli,tool-composio,tool-gemini-cli,tool-google-workspace,tool-jira,tool-linkedin,tool-microsoft365,tool-notion,tool-opencode-cli,tool-project-intel,tools-external,whatsapp-web"
ENV ZEROCLAW_BUILD_ID="${ZEROCLAW_REF}+patched"
RUN cargo build --release --locked -p zeroclaw ${ZEROCLAW_CARGO_FLAGS}

FROM upstream
COPY --from=build /src/target/release/zeroclaw /usr/local/bin/zeroclaw
