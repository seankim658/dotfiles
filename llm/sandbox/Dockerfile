FROM node:22-bookworm

ARG USER_UID=1000
ARG USER_GID=1000

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Tools Claude reaches for while exploring and testing. Passwordless sudo lets it
# install more, which is fine because the container is the security boundary.
# hadolint ignore=DL3008
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    sudo ripgrep fd-find jq less python3-venv python3-pip \
  && rm -rf /var/lib/apt/lists/*

# Give the node user your host ids so files Claude writes in the clone are yours
RUN groupmod --non-unique --gid "$USER_GID" node \
  && usermod --non-unique --uid "$USER_UID" --gid "$USER_GID" node \
  && echo "node ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/node

# The real repo can look owned by another user inside the container, and git
# refuses to read such repos. A fetch from a local path checks the .git folder.
RUN git config --system --add safe.directory /upstream/.git \
  && git config --system user.name "Claude" \
  && git config --system user.email "claude@sandbox.invalid"

USER node
ENV PATH="/home/node/.local/bin:/home/node/.cargo/bin:$PATH" \
    CLAUDE_CONFIG_DIR=/home/node/.claude

# Docker copies this folder's ownership into the config volume when it is first
# created, so Claude Code can write its login and settings there
RUN mkdir -p /home/node/.claude

RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --profile minimal -c clippy -c rustfmt
RUN curl -fsSL https://claude.ai/install.sh | bash

WORKDIR /projects
