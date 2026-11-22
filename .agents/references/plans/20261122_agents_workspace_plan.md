# Plan — `.agents` Multi-Assistant Workspace & Devcontainer (`Virtual-Cables-Linux`)

- **Status**: `completed`
- **Date**: 2026-11-22

## Goal

Establish a single source of truth across **Google Antigravity**, **Gemini CLI**, **Claude Code**, **OpenAI Codex**, **Hermes**, **Cursor**, and **VS Code (Copilot)** tailored to `Virtual-Cables-Linux` and its Ubuntu 22.04 / `lug-wine-experimental` host workflow.

## Slices

- [x] **Slice 1 — Reconnaissance & Scope Alignment**: Audited Bash scripts, host PulseAudio stack, and untracked `LUG Wine Builder` `.devcontainer/`. Confirmed adaptation to Ubuntu 22.04 + LUG bind mounts, standard canonical skills (`commit-and-pr`, `run-tests`, `dev-container`, `setup-virtual-cables`, `session-memory`), and `filesystem` MCP.
- [x] **Slice 2 — Canonical Instructions & `.gitignore`**: Created [`AGENTS.md`](../../../AGENTS.md), [`CLAUDE.md`](../../../CLAUDE.md), and default-deny / explicit-whitelist [`.gitignore`](../../../.gitignore).
- [x] **Slice 3 — Skills, 4-Pillar `.agents/` Tree & Devcontainer**: Created canonical skills under [`skills/`](../../../skills), relative discovery symlinks via [`.devcontainer/init_agent_workspace.sh`](../../../.devcontainer/init_agent_workspace.sh), streamlined Ubuntu 22.04 [`.devcontainer/Dockerfile`](../../../.devcontainer/Dockerfile), and automated [`tests/test_virtual_cables.sh`](../../../tests/test_virtual_cables.sh).
- [x] **Slice 4 — Conformance Audit & Commit Gate**: Verified double-run initializer idempotency, symlink integrity, `.gitignore` external-skill isolation, and zero absolute/`file://` Markdown links.
