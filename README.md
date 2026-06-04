# bigtask

A Claude Code skill for running **non-trivial multi-session tasks** (feature, refactor, audit, migration) that must survive across sessions without losing context.

It rests on two ideas:

1. **A three-file state triad on disk** — so any future session rebuilds context from disk, not from a vanishing conversation window:
   - `STATE.json` — where we are now (tiny, always accurate)
   - `PROGRESS.md` — what was done (append-only, one entry per checkpoint)
   - `EXPERIMENTS.md` — what was tried + result (one section per experiment)
2. **One human-gated unit of work** — a git branch, a Perforce CL, or nothing — that the agent prepares and verifies but **never submits/merges automatically**.

It is VCS-agnostic (git / Perforce / none), detects available tooling at runtime and degrades gracefully (e.g. no notification MCP → status goes inline), enforces phase scope and per-step budgets, and ends every code/content phase with **automated verification, not "looks fine to me."**

## Install

```text
/plugin marketplace add met44/bigtask-skill
/plugin install bigtask@met44-skills
```

Once installed, the skill auto-triggers when you start or resume a big multi-session task, or invoke it explicitly via the Skill tool.

## What's inside

```
skills/bigtask/
  SKILL.md                 # lean hot path: state triad, mode detection, phase loop, budgets, stop conditions
  references/
    init.md                # full bootstrap
    verification.md         # verification toolkit (Unreal + C#/.NET)
    tooling.md              # tool-first decision ladder
    long-jobs.md            # >30 min job + power-scheme discipline
  templates/
    STATE.json              # fill-in skeleton
    PLAN.md                 # phase-structured skeleton
    status.ps1              # status reporter (-PlanDir <path>)
```

## How it works

- **Mode detection** runs first every invocation: missing task folder → INIT; folder present with valid `STATE.json` → RESUME; folder present but `STATE.json` missing → **REPAIR** (reconstruct from `PROGRESS.md` + `PLAN.md`, never re-init over existing files); `STATE.json` corrupt → stop, never overwrite.
- **Phase loop** builds a 3–10 step todo list, makes one minimal scoped edit per step, verifies, then checkpoints to disk.
- **Budgets are mechanical**: >200 changed lines or >6 files per step → split or ask; >3 fix attempts → revert just the offending files; >4 phases without a human gate → insert one.
- **Human gates** are hard stops — the agent prepares and reports "ready for review/submit" and exits; a human submits.

## License

MIT
