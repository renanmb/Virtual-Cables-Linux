# AGENTS.md — Virtual-Cables-Linux

Canonical instructions for **Google Antigravity**, **Gemini CLI**, **Claude Code**, **OpenAI Codex**, **Hermes**, **Cursor**, and **VS Code (Copilot)** working in `Virtual-Cables-Linux`.

---

## 1. Project Overview & Architecture

`Virtual-Cables-Linux` provides lightweight, idempotent Bash utilities to create and tear down virtual audio routing ("virtual cables") on Linux desktops—routing isolated audio from **OBS Studio**, browsers, media players, or **Wine / Star Citizen (`LUG`)** games into conferencing/voice apps (**Zoom, Discord, Jitsi**) while preserving local headphone monitoring.

### Repository Layout

- [`README.md`](README.md) — User documentation, architecture diagram, `pavucontrol` testing guide, and per-app / Wine isolation instructions.
- [`virtual-cables-pulseaudio.sh`](virtual-cables-pulseaudio.sh) — PulseAudio virtual cable manager (`start`, `stop`, `restart`, `status`, `--no-loopback`) wiring `virtspk` (`Virtual_Speaker`) -> `virtmic` (`Virtual_Microphone`) + optional `Virtual_Speaker_Loopback`.
- [`virtual-cable-pipewire.sh`](virtual-cable-pipewire.sh) — PipeWire (`pipewire-pulse` + `pw-link`) virtual cable setup (`VirtualSpeaker` -> `VirtualMic` + loopback).
- [`tests/test_virtual_cables.sh`](tests/test_virtual_cables.sh) — Container-safe automated test suite (Bash syntax, executable bits, `shellcheck` if installed, stateful mock-`pactl` E2E tests, and `.agents` workspace conformance).
- [`.devcontainer/`](.devcontainer) — Ubuntu 22.04 Jammy multi-agent devcontainer (`agy`, `claude`, `hermes`, `codex`, `uv`, `gh`, `mcp-server-filesystem`, `shellcheck`, `pulseaudio-utils`) aligned with the host OS and `lug-wine-experimental` / `lug-helper` ecosystem.

### Key Commands & Quality Gates

```bash
# Run full automated test & conformance suite (safe inside container without /dev/snd)
bash tests/test_virtual_cables.sh

# Syntax-check all shell scripts
bash -n virtual-cables-pulseaudio.sh virtual-cable-pipewire.sh .devcontainer/init_agent_workspace.sh tests/test_virtual_cables.sh

# Host-only runtime commands (requires active PulseAudio server on host)
./virtual-cables-pulseaudio.sh start
./virtual-cables-pulseaudio.sh status
./virtual-cables-pulseaudio.sh restart --no-loopback
./virtual-cables-pulseaudio.sh stop
```

### Bash & Audio Scripting Conventions

1. **Shebang & Strict Mode**: Start scripts with `#!/usr/bin/env bash` on line 1 and `set -euo pipefail`.
2. **Ubuntu `mawk` Portability**: Default `awk` on Ubuntu 22.04 hosts is `mawk` (POSIX ERE). Never use GNU-only `\s` in `awk` regexes; always use `[ \t]` or `[[:space:]]`.
3. **PulseAudio Module Arguments**: Avoid unescaped spaces in `sink_properties` / `source_properties` / `sink_input_properties` (prefer underscore labels like `Virtual_Speaker`, `Virtual_Microphone`, `Virtual_Speaker_Loopback`), and always reference actual sink monitor names (`virtspk.monitor`, never display descriptions).
4. **Host vs. Container Execution**: The devcontainer has no physical `/dev/snd` or PulseAudio daemon by default. Automated tests must mock `pactl`/`pw-link` cleanly, while live audio verification runs in a host terminal.
5. **Wine / LUG Integration**: To isolate a Wine game (such as Star Citizen via `sc-launch.sh` or Lutris), ensure `virtual-cables-pulseaudio.sh` runs prior to launch and set `PULSE_SINK=virtspk` while leaving `PULSE_SOURCE` unset so in-game VOIP retains the physical microphone.

---

## 2. Skill Library

Canonical first-party skills live in tracked audience directories under [`skills/`](skills) and are exposed via strictly **relative** symlinks in [`.agents/skills/`](.agents/skills), [`.agent`](.agent), and [`.claude/skills`](.claude/skills):

- **Developer Skills ([`skills/developer/`](skills/developer))**:
  - [`commit-and-pr`](skills/developer/commit-and-pr/SKILL.md) — Git branch naming, DCO sign-off (`git commit -s`), zero AI trailers, and PR gates (`disable-model-invocation: true`).
  - [`run-tests`](skills/developer/run-tests/SKILL.md) — Syntax, lint, mock-`pactl` E2E, and `.agents` conformance verification workflow.
  - [`dev-container`](skills/developer/dev-container/SKILL.md) — Ubuntu 22.04 multi-agent container lifecycle, MCP fan-out, and LUG bind-mount rules.
- **User Skills ([`skills/user/`](skills/user))**:
  - [`setup-virtual-cables`](skills/user/setup-virtual-cables/SKILL.md) — Host PulseAudio vs. PipeWire detection, `pavucontrol` testing, OBS mixing, and Wine/game isolation (paired with [`evaluations.md`](skills/user/setup-virtual-cables/evaluations.md)).
- **Workspace Memory Skill ([`.agents/skills/session-memory/`](.agents/skills/session-memory/SKILL.md))**:
  - Checkpointing milestones into [`.agents/memory/INDEX.md`](.agents/memory/INDEX.md) and [`.agents/memory/sessions/`](.agents/memory/sessions).

**Synchronization Rule**: Whenever adding, renaming, or removing a canonical skill under `skills/developer/` or `skills/user/`, keep its relative symlink in `.agents/skills/` and its `.gitignore` whitelist entry in [`.gitignore`](.gitignore) synchronized (re-run `bash .devcontainer/init_agent_workspace.sh`).

---

## 3. Repository Path & Link Invariant

- **Never** hardcode `file://` URIs or absolute filesystem paths (`workspaces/...`, `home/...`, `Users/...` prefixed with `/`) in Markdown links across `AGENTS.md`, `README.md`, `skills/`, or `.agents/`.
- **Always** use repository-relative Markdown links (for example, `[README.md](README.md)` or `[run-tests](../../skills/developer/run-tests/SKILL.md)`).
- Every symlink in the repository (`.agent`, `.claude/skills`, `.agents/skills/*`) **must** use a strictly relative target—never an absolute path.

---

## 4. Standard Multi-Agent Structure & Instantiation Patterns

### A. In-Session Implementation Squad (`/goal`)

For multi-step features or refactors, the main session acts as **Orchestrator** (owning the plan checklist in [`.agents/references/plans/`](.agents/references/plans) and slice state) and delegates via `define_subagent` + `invoke_subagent` with strict permission boundaries:

1. **`<domain>-researcher`** (`EnableWriteTools: false`, `EnableSubagentTools: false`, `EnableMCPTools: false`):
   - Performs a read-only pre-slice audit of exact relative file paths, line numbers, CLI flags, PulseAudio/PipeWire module parameters, and existing tests so coders never guess.
2. **`<domain>-coder`** (`EnableWriteTools: true`, `EnableSubagentTools: false`):
   - Implements strictly **one** assigned slice based on the researcher brief.
   - Runs `bash tests/test_virtual_cables.sh` (and `shellcheck` if available) until green.
   - **Never** runs `git commit` or `git push`.
3. **`<domain>-critic`** (`EnableWriteTools: false`, or `true` strictly to execute read-only test commands with **zero** edits to repository files):
   - Independently audits requirements, `mawk`/Bash portability, and `AGENTS.md` invariants, walks through failure modes, and returns `VERDICT: PASS` or prioritized `VERDICT: MUST-FIX` before the Orchestrator advances to the next slice.

### B. Plan & Prompt Review Squad

Before executing large plans, run in parallel:
- **`<domain>-path-reviewer`** (read-only): Verifies every relative path, Markdown link, line citation, and CLI flag against disk.
- **`<domain>-domain-reviewer`** (read-only): Verifies PulseAudio/PipeWire module semantics, `pactl`/`pw-link` behavior, and Wine audio routing contracts.
- **`<domain>-adversarial-critic`** (read-only): Performs a chronological mental-model dry run of execution steps to catch ordering bugs or host/container mismatches.

### C. Sharded Map-Reduce Pool

- **`<domain>-shard-worker`** (`EnableWriteTools: false`): Restricted to reading and summarizing a single assigned shard file or log to prevent Orchestrator context bloat.

### D. Cross-Session / Multi-Repo Protocol

- **Single-Writer Ownership**: Only one active agent session may hold write ownership of this repository at a time. Bind-mounted sibling paths (`lug-helper`, `star-citizen`) are treated as **read-only** from this workspace unless the user explicitly authorizes cross-repo edits.
- **Handoff & Bootstrap**: Cross-session handoffs record JSON/Markdown receipts in `.agents/memory/sessions/`, and `/goal` prompts explicitly list bootstrap reads (`AGENTS.md`, active plan in `.agents/references/plans/`, and relevant `.agent/skills/<name>/SKILL.md`).

---

## 5. Boundaries

1. **Commit & Push Gate**: Always ask explicit user permission before running `git commit` or `git push`.
2. **DCO & No AI Attribution**: Sign off every commit with `git commit -s` and **never** include AI-attribution trailers (`Co-Authored-By`, `Generated with...`, etc.).
3. **Branch Hygiene**: Push changes to `<username>/<type>/<short-description>` branches where `<type>` is one of `feature`, `fix`, `docs`, `refactor`, `chore`, or `ci`. Never force-push `main` or `release/*`.
4. **Secrets & Binaries**: Never commit API keys, tokens, credentials, audio recordings, datasets, or large binary archives.
5. **Protected Infrastructure**: Ask explicit permission before modifying `.devcontainer/`, `.github/workflows/`, `.pre-commit-config.yaml`, or any bind-mounted host directories outside the repository root.
