#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$PWD}"
HOME_DIR="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}"

echo "[Agent Workspace Initializer] Bootstrapping ${TARGET_DIR}..."

mkdir -p \
  "${TARGET_DIR}/skills/developer" \
  "${TARGET_DIR}/skills/user" \
  "${TARGET_DIR}/.agents/skills" \
  "${TARGET_DIR}/.agents/memory/sessions" \
  "${TARGET_DIR}/.agents/references/docs" \
  "${TARGET_DIR}/.agents/references/notes" \
  "${TARGET_DIR}/.agents/references/plans" \
  "${TARGET_DIR}/.agents/references/templates" \
  "${TARGET_DIR}/.agents/scratch" \
  "${TARGET_DIR}/.claude" \
  "${TARGET_DIR}/.vscode" \
  "${TARGET_DIR}/.cursor"

touch \
  "${TARGET_DIR}/.agents/memory/sessions/.gitkeep" \
  "${TARGET_DIR}/.agents/references/notes/.gitkeep" \
  "${TARGET_DIR}/.agents/scratch/.gitkeep"

[ -L "${TARGET_DIR}/.agent" ] || [ -e "${TARGET_DIR}/.agent" ] || ln -s .agents "${TARGET_DIR}/.agent"
[ -L "${TARGET_DIR}/.claude/skills" ] || [ -e "${TARGET_DIR}/.claude/skills" ] || ln -s ../.agents/skills "${TARGET_DIR}/.claude/skills"

for group in developer user; do
  for skill_dir in "${TARGET_DIR}/skills/${group}"/*; do
    [ -d "${skill_dir}" ] || continue
    skill_name="$(basename "${skill_dir}")"
    if [ ! -L "${TARGET_DIR}/.agents/skills/${skill_name}" ] && [ ! -e "${TARGET_DIR}/.agents/skills/${skill_name}" ]; then
      ln -s "../../skills/${group}/${skill_name}" "${TARGET_DIR}/.agents/skills/${skill_name}"
    fi
  done
done

if [ ! -f "${TARGET_DIR}/CLAUDE.md" ] && [ -f "${TARGET_DIR}/AGENTS.md" ]; then
  printf '@AGENTS.md\n' > "${TARGET_DIR}/CLAUDE.md"
fi

if [ ! -f "${TARGET_DIR}/.agents/memory/INDEX.md" ]; then
  cat <<'EOF' > "${TARGET_DIR}/.agents/memory/INDEX.md"
# Architectural Session Memory Index

| Timestamp | Session ID | Topic / Milestone | Summary | Status |
| :--- | :--- | :--- | :--- | :--- |
EOF
fi

if [ ! -f "${TARGET_DIR}/.agents/references/README.md" ]; then
  cat <<'EOF' > "${TARGET_DIR}/.agents/references/README.md"
# Agent References

| Path | Description |
| :--- | :--- |
| **[`plans/README.md`](plans/README.md)** | Active and archived implementation plans. |
| **[`docs/`](docs)** | Setup, architecture, and operational guides. |
| **[`notes/`](notes)** | Investigation reports, benchmarks, and discoveries. |
| **[`templates/`](templates)** | Reusable specification templates. |
EOF
fi

if [ ! -f "${TARGET_DIR}/.agents/references/plans/README.md" ]; then
  cat <<'EOF' > "${TARGET_DIR}/.agents/references/plans/README.md"
# Active Plans

| Plan | Description | Status |
| :--- | :--- | :--- |
EOF
fi

# Preserve LUG ecosystem convenience symlinks inside the container when bind mounts are present
if [ -f "/.dockerenv" ]; then
  if [ -d "/home/tarfy/Games" ]; then
    ln -sfn /home/tarfy/Games "${HOME_DIR}/Games" 2>/dev/null || true
  fi
  if [ -d "/lug-wine-experimental" ]; then
    mkdir -p /home/tarfy/Documents/GitHub/renanmb /workspaces 2>/dev/null || true
    ln -sfn /lug-wine-experimental /home/tarfy/Documents/GitHub/renanmb/lug-wine-experimental 2>/dev/null || true
    [ -d "/workspaces/lug-wine-experimental" ] && [ ! -L "/workspaces/lug-wine-experimental" ] || ln -sfn /lug-wine-experimental /workspaces/lug-wine-experimental 2>/dev/null || true
  fi
  if [ -d "/lug-helper" ]; then
    mkdir -p /home/tarfy/Documents/GitHub/renanmb /workspaces 2>/dev/null || true
    ln -sfn /lug-helper /home/tarfy/Documents/GitHub/renanmb/lug-helper 2>/dev/null || true
    [ -d "/workspaces/lug-helper" ] && [ ! -L "/workspaces/lug-helper" ] || ln -sfn /lug-helper /workspaces/lug-helper 2>/dev/null || true
  fi
fi

# Non-clobbering MCP fan-out (workspace configs always; global $HOME configs only inside container or when binary exists)
python3 - "${TARGET_DIR}" "${HOME_DIR}" <<'PY'
import json, pathlib, shutil, sys

target = pathlib.Path(sys.argv[1]).resolve()
home = pathlib.Path(sys.argv[2]).resolve()
ws_root = str(target.parent if target.parent.name == "workspaces" else target)

mcp_servers = {
    "filesystem": {
        "command": "mcp-server-filesystem",
        "args": [ws_root],
    }
}

cfg_targets = [target / ".vscode/mcp.json", target / ".cursor/mcp.json"]
in_container_or_installed = pathlib.Path("/.dockerenv").exists() or shutil.which("mcp-server-filesystem") is not None

if in_container_or_installed:
    (home / ".gemini/config").mkdir(parents=True, exist_ok=True)
    (home / ".codex").mkdir(parents=True, exist_ok=True)
    cfg_targets.extend([home / ".gemini/config/mcp_config.json", home / ".claude.json"])

for cfg_path in cfg_targets:
    existing = {}
    if cfg_path.exists():
        try:
            existing = json.loads(cfg_path.read_text())
            if not isinstance(existing, dict):
                existing = {}
        except Exception:
            existing = {}
    existing.setdefault("mcpServers", {}).update(mcp_servers)
    cfg_path.write_text(json.dumps(existing, indent=2) + "\n")

if in_container_or_installed:
    codex_cfg = home / ".codex/config.toml"
    codex_text = codex_cfg.read_text() if codex_cfg.exists() else ""
    if "[mcp_servers.filesystem]" not in codex_text:
        block = f'\n[mcp_servers.filesystem]\ncommand = "mcp-server-filesystem"\nargs = ["{ws_root}"]\n'
        codex_cfg.write_text(codex_text + block)
PY

echo "[Agent Workspace Initializer] Ready."
