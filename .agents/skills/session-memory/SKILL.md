---
name: session-memory
description: Record architectural milestones and cross-session handoff checkpoints in .agents/memory/.
---

# Session Memory Skill

Use this skill to persist architectural decisions, completed slices, and cross-session handoffs without bloating `AGENTS.md`.

## 1. Directory Layout

- [`../../memory/INDEX.md`](../../memory/INDEX.md) — Chronological one-row-per-milestone ledger.
- [`../../memory/sessions/`](../../memory/sessions) — Detailed session checkpoint files named `YYYYMMDD_HHMMSS_<short_uuid>.md`.

## 2. When to Record a Checkpoint

Create a session checkpoint when:
1. Completing an architectural milestone or multi-slice `/goal` plan.
2. Handing off unfinished work between agent sessions or assistants (`Antigravity`, `Claude Code`, `Codex`, `Hermes`).
3. Discovering a non-obvious platform invariant (for example, Ubuntu `mawk` regex behavior, PulseAudio module argument rules, or Wine `winepulse.drv` `PULSE_SINK` semantics).

## 3. Checkpoint File Template

Write `.agents/memory/sessions/YYYYMMDD_HHMMSS_<short_uuid>.md` using **strictly repository-relative** Markdown links (never `file://` or leading `/` paths):

```markdown
# Session Checkpoint — <Title>

- **Timestamp (UTC)**: YYYY-MM-DDTHH:MM:SSZ
- **Session ID**: `<short_uuid>`
- **Status**: `completed` | `in-progress` | `blocked`

## Summary
- Concise bullets of what changed and why.

## Touched Files
- [`virtual-cables-pulseaudio.sh`](../../../virtual-cables-pulseaudio.sh)

## Verification
- Exact test commands run and pass/fail status.

## Next Steps / Open Questions
- Remaining items for the next session.
```

## 4. Updating `INDEX.md`

Append a matching row to [`../../memory/INDEX.md`](../../memory/INDEX.md) linking relatively to `sessions/YYYYMMDD_HHMMSS_<short_uuid>.md`.
