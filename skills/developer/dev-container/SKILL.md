---
name: dev-container
description: Manage the Ubuntu 22.04 multi-agent devcontainer, MCP server fan-out, and LUG Wine bind-mount boundaries for Virtual-Cables-Linux.
---

# Dev Container Guide (`Virtual-Cables-Linux`)

This repository uses an Ubuntu 22.04 Jammy devcontainer ([`.devcontainer/Dockerfile`](../../../.devcontainer/Dockerfile) and [`.devcontainer/devcontainer.json`](../../../.devcontainer/devcontainer.json)) aligned with the host OS and sibling `lug-wine-experimental` / `lug-helper` workflow.

## 1. Installed Tooling & Agents

Built as `root` at image build time so post-create hooks never hit global permission errors:
- **OS & Shell**: Ubuntu 22.04 Jammy, `bash`, `shellcheck`, `pulseaudio-utils`, `gawk`, `ripgrep`, `jq`, `git`, `git-lfs`, `gh`.
- **Runtimes**: Python 3 (`uv` / `uvx`), Node.js 20 LTS.
- **Agent CLIs**: Google Antigravity (`agy`), Claude Code (`claude`), OpenAI Codex (`codex`), Hermes (`hermes`).
- **MCP Server**: `mcp-server-filesystem` (`@modelcontextprotocol/server-filesystem`).

## 2. Workspace Bootstrap (`init_agent_workspace.sh`)

`postCreateCommand` runs [`bash .devcontainer/init_agent_workspace.sh`](../../../.devcontainer/init_agent_workspace.sh), which idempotently:
1. Ensures the 4-pillar `.agents/` hierarchy (`memory/`, `references/`, `scratch/`, `skills/`) and relative symlinks (`.agent`, `.claude/skills`, `.agents/skills/*`) exist.
2. Preserves convenience symlinks inside the container when LUG bind mounts (`lug-helper`, `Games`) are present.
3. Merges the `filesystem` MCP entry non-destructively into `.vscode/mcp.json`, `.cursor/mcp.json`, `$HOME/.gemini/config/mcp_config.json`, `$HOME/.claude.json`, and `$HOME/.codex/config.toml`.

## 3. Host Audio vs. Container Isolation

- By default, the container does **not** mount `/dev/snd` or the host's `/run/user/1000/pulse` socket.
- Run [`bash tests/test_virtual_cables.sh`](../../../tests/test_virtual_cables.sh) inside the container for fast, deterministic verification using the mock `pactl` harness.
- Run [`./virtual-cables-pulseaudio.sh`](../../../virtual-cables-pulseaudio.sh) or [`./virtual-cable-pipewire.sh`](../../../virtual-cable-pipewire.sh) directly in a **host terminal** to manage real host virtual audio devices.

## 4. Bind-Mount Safety Boundary

`devcontainer.json` mounts sibling LUG directories (`lug-helper` and `Games`) so agents can inspect launch scripts (such as Star Citizen's `sc-launch.sh`) for `PULSE_SINK=virtspk` compatibility. Treat those external bind mounts as **strictly read-only** unless the user explicitly asks to edit them.
