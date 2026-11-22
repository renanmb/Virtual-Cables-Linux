---
name: run-tests
description: Execute syntax, lint, mock-pactl E2E lifecycle tests, and .agents conformance checks for Virtual-Cables-Linux, plus optional live host audio verification.
---

# Run Tests (`Virtual-Cables-Linux`)

Use this workflow to validate shell scripts and workspace conformance both inside the isolated devcontainer and on a live Linux host.

## 1. Container-Safe Automated Suite (Always Run After Edits)

Inside the devcontainer (where no physical `/dev/snd` or host PulseAudio socket is mounted), run [`tests/test_virtual_cables.sh`](../../../tests/test_virtual_cables.sh):

```bash
bash tests/test_virtual_cables.sh
```

What this verifies:
1. **Syntax & Permissions**: Runs `bash -n` and verifies `+x` executable mode across [`virtual-cables-pulseaudio.sh`](../../../virtual-cables-pulseaudio.sh), [`virtual-cable-pipewire.sh`](../../../virtual-cable-pipewire.sh), [`.devcontainer/init_agent_workspace.sh`](../../../.devcontainer/init_agent_workspace.sh), and [`tests/test_virtual_cables.sh`](../../../tests/test_virtual_cables.sh).
2. **Static Analysis**: Runs `shellcheck` automatically when installed in the environment.
3. **Stateful Mock-`pactl` E2E Tests**: Exercises `--help`, unreachable-daemon failure exit, `start` (3 modules), idempotent `start` guard, `restart --no-loopback` (2 modules), and `stop` (0 modules remaining), including trailing-tab `pactl list short modules` formatting under POSIX `awk` (`mawk`/`gawk`).
4. **`.agents` Conformance Audit**: Verifies [`AGENTS.md`](../../../AGENTS.md), [`CLAUDE.md`](../../../CLAUDE.md), relative symlinks, `.gitignore` external-skill isolation, and zero absolute/`file://` Markdown links.

## 2. Initializer Idempotency Smoke Check

Whenever modifying [`.devcontainer/init_agent_workspace.sh`](../../../.devcontainer/init_agent_workspace.sh) or adding skills under [`skills/`](../../../skills):

```bash
bash .devcontainer/init_agent_workspace.sh
bash .devcontainer/init_agent_workspace.sh
git status -sb
```

Confirm the second invocation produces zero unintended diffs.

## 3. Live Host Verification (Host Terminal Only)

When verifying live audio routing on the Ubuntu/Linux host session:

```bash
# 1. Confirm host audio server
pactl info | grep "Server Name"

# 2. Exercise PulseAudio virtual cable lifecycle
./virtual-cables-pulseaudio.sh start
./virtual-cables-pulseaudio.sh status

# 3. End-to-end audio signal probe (watch Virtual_Microphone meter in pavucontrol)
paplay --device=virtspk /usr/share/sounds/alsa/Front_Center.wav

# 4. Clean teardown
./virtual-cables-pulseaudio.sh stop
```
