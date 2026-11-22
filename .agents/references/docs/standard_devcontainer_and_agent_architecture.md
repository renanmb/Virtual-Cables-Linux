# Standard Devcontainer & Multi-Agent Architecture (`Virtual-Cables-Linux`)

Reference architecture governing how multi-assistant instructions, skills, MCP servers, and the Ubuntu 22.04 devcontainer operate in `Virtual-Cables-Linux` alongside the `lug-wine-experimental` / `lug-helper` workflow.

---

## 1. Four-Pillar `.agents/` & Canonical `skills/` Topology

1. **Single Instruction Entrypoint**:
   - [`AGENTS.md`](../../../AGENTS.md) holds all canonical project conventions, multi-agent squad rules, and safety boundaries.
   - [`CLAUDE.md`](../../../CLAUDE.md) contains `@AGENTS.md` so Claude Code imports the exact same rules with zero drift.
2. **Audience-Separated Canonical Skills ([`skills/`](../../../skills))**:
   - `skills/developer/` (`commit-and-pr`, `run-tests`, `dev-container`)
   - `skills/user/` (`setup-virtual-cables` + `evaluations.md`)
3. **Flat Relative Discovery Symlinks**:
   - `.agents/skills/<name> -> ../../skills/<group>/<name>`
   - `.agent -> .agents` (Antigravity / Gemini CLI)
   - `.claude/skills -> ../.agents/skills` (Claude Code)
4. **Default-Deny `.gitignore` Whitelist ([`.gitignore`](../../../.gitignore))**:
   - Ignores `.agents/skills/*` by default so third-party dynamically installed skills never dirty `git status`, while explicitly whitelisting first-party skill symlinks and `session-memory`.

---

## 2. Ubuntu 22.04 + LUG Ecosystem Devcontainer

Unlike generic CPU templates pinned to Ubuntu 24.04, [`.devcontainer/Dockerfile`](../../../.devcontainer/Dockerfile) and [`.devcontainer/devcontainer.json`](../../../.devcontainer/devcontainer.json) intentionally align with the host Ubuntu 22.04 Jammy (`glibc 2.35`) environment and LUG Wine setup:
- **Lightweight Image**: Drops heavy `i386`/MinGW Wine compiler headers not needed by `Virtual-Cables-Linux` while retaining `shellcheck`, `pulseaudio-utils`, `uv`/`uvx`, `gh`, Node 20 LTS, `agy`, `claude`, `codex`, `hermes`, and `mcp-server-filesystem`.
- **Shared Bind Mounts & Persistent Volumes**: Preserves named volumes for CLI auth/state (`claude`, `hermes`, `antigravity`, `gh`) and bind-mounts `lug-wine-experimental`, `lug-helper`, and `Games` (treated as read-only unless cross-repo edits are requested) so Wine launch audio routing (`PULSE_SINK=virtspk`) can be inspected directly.
- **Idempotent Bootstrap**: [`.devcontainer/init_agent_workspace.sh`](../../../.devcontainer/init_agent_workspace.sh) fans out `filesystem` MCP configuration non-destructively across VS Code, Cursor, Antigravity/Gemini CLI, Claude Code, and Codex.
