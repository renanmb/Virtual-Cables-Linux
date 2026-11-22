# Task / Slice Specification Template

## 1. Objective
- Single clear sentence stating what this slice accomplishes and what "done" looks like.

## 2. Context & Pre-Slice Audit
- **Target Files** (strictly repository-relative links):
  - [`virtual-cables-pulseaudio.sh`](../../../virtual-cables-pulseaudio.sh)
- **Invariants & Constraints**:
  - Bash `set -euo pipefail`, POSIX `mawk`-compatible regexes (`[ \t]`, never `\s`).
  - Zero `file://` or absolute `/` Markdown links.

## 3. Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## 4. Verification Commands
```bash
bash tests/test_virtual_cables.sh
```

## 5. Out of Scope
- Explicitly list files, sibling repositories, or commits excluded from this slice (`git commit` / `git push` forbidden for coder subagents).
