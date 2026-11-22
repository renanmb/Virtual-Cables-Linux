---
name: commit-and-pr
description: Standardized Git branch, DCO sign-off (-s), pre-commit verification, and Pull Request workflow for Virtual-Cables-Linux.
disable-model-invocation: true
---

# Commit and Pull Request Workflow (`Virtual-Cables-Linux`)

Follow this checklist strictly whenever staging, committing, or opening a Pull Request in `Virtual-Cables-Linux`.

## 1. Pre-Commit Quality Gate

Before asking to commit, run the repository verification suite from the repository root:

```bash
bash tests/test_virtual_cables.sh
git status -sb
git diff --stat
```

Confirm:
- All Bash syntax checks, mock-`pactl` E2E checks, symlink checks, `.gitignore` external-skill checks, and Markdown link-invariant checks pass.
- No secrets, API keys, local MCP configs (`.vscode/mcp.json`, `.cursor/`), or temporary files are staged.

## 2. Explicit User Approval Gate

- **Always** present the summary of modified/created files and ask explicit user permission before running `git commit` or `git push`.

## 3. Branch Naming

Create or push to branches following `<username>/<type>/<short-description>`, where `<type>` is one of:
- `feature` — new audio routing capabilities or CLI flags
- `fix` — bug fixes in PulseAudio/PipeWire module wiring or shell portability
- `docs` — `README.md`, `AGENTS.md`, or `.agents/references/` updates
- `refactor` — internal script cleanup without behavior change
- `chore` — `.devcontainer/`, skill library, or maintenance updates
- `ci` — test harness or GitHub Actions workflow changes

Never force-push `main` or `release/*`.

## 4. Commit Format & DCO Sign-Off

- Always sign off commits with `-s` (`Signed-off-by:` via `git commit -s`).
- Use clear, imperative subject lines (`fix: wire virtspk.monitor directly to virtmic in pulseaudio script`).
- **Never** add AI-attribution trailers (`Co-Authored-By`, `Generated with...`, etc.).

```bash
git commit -s -m "<type>: <concise imperative summary>"
```

## 5. Remotes & Pull Requests

- `origin`: fork repository (`renanmb/Virtual-Cables-Linux`)
- `upstream`: upstream repository (`steven3363/Virtual-Cables-Linux`)
- Confirm target remote (`origin` vs. `upstream`) with the user before running `gh pr create`.
