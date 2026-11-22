# Base image pinned to Ubuntu 22.04 Jammy (matching host OS & LUG Wine ecosystem)
FROM ubuntu:22.04

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONUNBUFFERED=1

# 1. Core utilities, Bash linting & PulseAudio CLI tools, Python, and Node.js 20 LTS
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    dirmngr \
    gawk \
    git \
    git-lfs \
    gnupg2 \
    jq \
    pulseaudio-utils \
    python3 \
    python3-pip \
    python3-venv \
    ripgrep \
    shellcheck \
    software-properties-common \
    wget \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends nodejs gh \
    && rm -rf /var/lib/apt/lists/* \
    && git lfs install

# 2. Install Astral UV / UVX
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    ln -sf /root/.local/bin/uv /usr/local/bin/uv && \
    ln -sf /root/.local/bin/uvx /usr/local/bin/uvx

# 3. Install Multi-Assistant Agent CLIs & Filesystem MCP Server globally at build time
RUN npm install -g \
    @anthropic-ai/claude-code \
    @openai/codex \
    @modelcontextprotocol/server-filesystem \
    && (curl -fsSL https://antigravity.google/cli/install.sh | bash || true) \
    && (if [ -f /root/.local/bin/agy ]; then ln -sf /root/.local/bin/agy /usr/local/bin/agy; fi) \
    && (curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup --skip-browser || true)

WORKDIR /workspaces/Virtual-Cables-Linux
