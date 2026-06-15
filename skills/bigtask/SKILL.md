---
name: bigtask
description: "Use when starting or resuming a non-trivial multi-session task (feature, refactor, audit, migration) that must survive across sessions without losing context. Triggers: 'big task', multi-phase work, a task folder under .windsurf/plans/ or .plans/, resuming prior work, long-running VCS-agnostic (git / Perforce / none) work gated by a human submit."
user-invocable: true
disable-model-invocation: false
---

# Bigtask -- Persistent Plan / State / Progress

## Overview

Run a long multi-session task so any future session resumes without losing context. The whole skill rests on **three non-overlapping files** and **one human-gated unit of work**. Get those right and everything else follows.

**Core principle:** state lives on disk, not in context. Every checkpoint writes to disk; every invocation rebuilds context from disk.

**Run as supervisor by default (top agent only).** When you are the lead session driving this task -- not a sub-agent dispatched to execute one step -- invoke the `supervise` skill (`bigtask:supervise`, bundled in this plugin) and stay an orchestrator. The Resume + Phase Loop below still governs *what* happens and in what order; supervise changes only *how* each step runs: dispatch its reading, editing, and building to one sub-agent per step, while your own context holds nothing but `STATE.json`, the contracts, and the loop. bigtask keeps state across sessions; supervise keeps it lean within one -- together they let a task outlive both context limits and session boundaries. Opt out for a small, single-phase task by noting `supervise: off` in `PLAN.md`.

## The State Triad (the one idea that matters)

| File | Answers ONLY | Shape |
|------|--------------|-------|
| `STATE.json` | Where are we now? | tiny, always accurate (see `templates/STATE.json`) |
| `PROGRESS.md` | What was done? | one append-only entry per checkpoint |
| `EXPERIMENTS.md` | What was tried + result? | one section per experiment (create on first need) |

Never let these overlap. Large artifacts (reports, CSVs, screenshots) go under `reports/` or `experiments/` and are *linked* from `PROGRESS.md`, never inlined. Cross-task knowledge goes to memory (`~/.claude/.../memory/`), not the task folder.

## Task Folder

`<PLANS>/<slug>/` where `<PLANS>` = `.windsurf/plans/` if that dir already exists in the repo (interop with existing tasks), else `.plans/`. One task = one folder. Never mix tasks. `slug` is kebab-case, <=24 chars.

## Mode Detection (run this FIRST, every invocation)

```
folder missing            -> INIT  (see references/init.md)
folder exists, STATE.json present & valid   -> RESUME (loop below)
folder exists, STATE.json MISSING           -> REPAIR: reconstruct STATE.json from PROGRESS.md tail + PLAN.md, append a `repaired` PROGRESS entry, then RESUME. Do NOT abort, do NOT re-init over existing files.
STATE.json present but corrupted/unparseable -> do NOT overwrite. Append a `blockers` entry to PROGRESS.md, surface it, exit.
```

## Read Order (every invocation, before acting)

1. `STATE.json` -- where we are.
2. Tail (~80 lines) of `PROGRESS.md` -- recent activity.
3. `PLAN.md` -- current + next phase.
4. `EXPERIMENTS.md` -- only if current phase is experiment/validation.
5. Memory + any `.windsurf/rules/*.md` -- project context.

## Hard Rules

- **One unit of work, human-gated.** git -> feature branch `task/<slug>` off `main`. Perforce -> one pending CL via the connected Perforce MCP (never raw `p4`, no P4 branches). none -> `vcs:"none"`, skip branch/CL. All edits stay in that unit until the human submits/merges.
- **Never submit / merge / push to main automatically.** Agent prepares + verifies; human reviews and submits.
- **Never edit outside the current phase's scope** as written in `PLAN.md`. If the work doesn't fit the phase, split the step or stop.
- **Never weaken or delete existing tests. Never commit secrets.**
- **Code emitted by this skill is ASCII-only** (.h/.cpp/.cs/.py/.bat/.ps1) -- avoids P4/encoding breakage. Markdown plan files may use any chars.
- **Verify before claiming done** -- every code/content phase ends with automated verification, not "looks fine." See `references/verification.md`.
- **Tool-first** -- solve by building/extending/invoking a tool, not by hand-editing through the UI. See `references/tooling.md`.
- After each checkpoint: update `STATE.json`, append `PROGRESS.md`. Files stay in the unit of work.

## Resume + Phase Loop

1. Read sources in the order above.
2. Verify the unit of work still exists (git: branch present; P4: CL via Perforce MCP). If gone/submitted, mark the task complete in `PROGRESS.md` and ask whether to open a new one or close out.
3. If `STATE.phase` is `human_gate_*` -> emit status (what's ready to review/test), exit. Do not cross the gate.
4. Read the current phase from `PLAN.md`. Build a **TodoWrite list** of 3-10 concrete steps; keep exactly one `in_progress`.
5. For each step:
   - One minimal logical edit. Respect the budget (below).
   - Add/update the tests the phase requires.
   - Build + test per `PLAN.md` for this phase (see `references/verification.md`).
   - On green: update `STATE.json` (`step`, `last_green_step`); append a `PROGRESS.md` entry (status `done`, brief note, files touched).
   - Experiments/benchmarks: also append a section to `EXPERIMENTS.md`.
6. When all phase steps are `done`: run the phase's full (or defined smoke) suite; visual phases capture before/after screenshots; write `reports/<phase>.md` if the phase requires an artifact; advance `STATE.phase`. If next is `human_gate_*` -> emit status + exit. Else continue.
7. Final phase / pre-rollout gate: clean up the unit of work (git: tidy commits / squash only if asked; P4: edit CL description, drop untouched files), emit "ready for review/submit", exit. The human submits.

## Budgets (mechanical -- actually check these)

Per step, before committing the edit, measure the diff:
- changed lines > **200** OR changed files > **6** -> stop, split the step (or ask for an explicit allowance recorded in `PLAN.md`).
- fix attempts on one failure > **3** -> revert just the offending files (not the whole unit), append `reverted` to `PROGRESS.md`, set `STATE.blockers`, exit.
- phases since last human gate > **4** -> insert a gate.

Override any default by stating it in the `PLAN.md` phase header.

## Re-Planning

If mid-task you discover `PLAN.md` is wrong or infeasible: do NOT silently deviate. Append a `PROGRESS.md` note describing the gap, propose a revised phase/plan, and treat it as a human gate (exit and ask) unless the change is within the current phase's scope and budget.

## Tooling Availability & Graceful Degradation

Detect what's actually connected this session; never assume a specific MCP exists.

- **VCS:** prefer the VCS whose tooling is available and safe. `.git` present -> git via Bash. Perforce workspace + connected Perforce MCP -> P4 via that MCP. If a P4 workspace exists but no MCP is connected, do NOT shell raw `p4` -- record a blocker and ask. If both git and P4 exist, prefer the one with safe tooling this session (default git); if ambiguous, ask once.
- **Build/test (Unreal):** `compile_project` (unrealMCP / UnrealPlay), `automation_run_tests`, PIE introspection via `play_*`. (C# / .NET: `dotnet build`, `tools/run-tests.ps1`.)
- **Notifications:** if a Telegram/`interact`-style MCP is connected, notify on bootstrap, before/after builds, at each gate, on long-job start, and on final stop. If none is connected, **skip silently and surface the same status inline in chat** -- never block on it.

## Stop Conditions (any -> exit cleanly)

- Reached a `human_gate_*`.
- A test that should pass fails twice after a fix attempt (then follow the 3-attempt revert rule).
- Change would exceed a phase budget without explicit allowance.
- Destructive/irreversible action required.
- Working tree dirty in a way that doesn't match this task.
- A long job (>30 min) was started -- record in `STATE.long_jobs` + `PROGRESS.md` and exit (see `references/long-jobs.md`).

On any stop: append `PROGRESS.md` (`blocked` or natural `done`), update `STATE.json`, emit a status message (current phase, done this run, pending, input needed).

## Red Flags -- STOP

| Thought | Reality |
|---------|---------|
| "I'll just submit/merge to wrap up" | Submission is a human gate. Never auto-submit. |
| "This edit is small, scope creep is fine" | Out-of-phase edits break review. Split or stop. |
| "I'll fix STATE later / overwrite the corrupt one" | Corrupt STATE = blocker + exit, never overwrite. |
| "No Telegram MCP, so I can't proceed" | Notifications are optional. Surface inline, continue. |
| "Plan's wrong, I'll just do the right thing" | Silent deviation loses the human. Re-plan at a gate. |
| "Looks fine to me" | Not verification. Run the toolkit. |
| "I'll click through the editor just this once" | Twice = build the tool. Tool-first. |

## References (read on demand, not every invocation)

- `references/init.md` -- full bootstrap (folder, files, unit of work, first message).
- `references/verification.md` -- verification toolkit (Unreal + C#/.NET).
- `references/tooling.md` -- tool-first decision ladder.
- `references/long-jobs.md` -- long-job + power-scheme discipline.
- `templates/` -- `STATE.json`, `PLAN.md`, `status.ps1` skeletons.
