# bigtask

A Claude Code plugin for running **non-trivial multi-session tasks** (feature, refactor, audit, migration) that must survive across sessions without losing context.

It bundles **two complementary skills** that attack context loss from opposite ends:

- **bigtask** — survive *across* sessions: task state lives on disk (not in the conversation window), so any future session rebuilds context and resumes.
- **supervise** — survive *within* a session: the lead agent stays a pure orchestrator and farms every subtask to sub-agents, so its own context never fills with source.

When you drive a big task, the bigtask lead agent invokes **supervise by default** — so the work outlives both context limits and session boundaries. (Opt out for a small, single-phase task with `supervise: off` in `PLAN.md`.)

## bigtask — persistent plan / state / progress

Rests on two ideas:

1. **A three-file state triad on disk** — so any future session rebuilds context from disk, not from a vanishing conversation window:
   - `STATE.json` — where we are now (tiny, always accurate)
   - `PROGRESS.md` — what was done (append-only, one entry per checkpoint)
   - `EXPERIMENTS.md` — what was tried + result (one section per experiment)
2. **One human-gated unit of work** — a git branch, a Perforce CL, or nothing — that the agent prepares and verifies but **never submits/merges automatically**.

It is VCS-agnostic (git / Perforce / none), detects available tooling at runtime and degrades gracefully (e.g. no notification MCP → status goes inline), enforces phase scope and per-step budgets, and ends every code/content phase with **automated verification, not "looks fine to me."**

## supervise — supervisor / orchestrator

Turns the lead session into a pure supervisor. Big tasks die when one session reads and writes all the code itself: context fills, early decisions scroll away, requirements get dropped, and the session has to be restarted. supervise keeps the lead agent's context holding only **plans, interface contracts, and status** — never source — and dispatches everything else:

- **Recon** goes to read-only Explore agents that return a map, not file contents.
- **Writing, editing, building, and testing** go to one worker agent per task, each with a self-contained prompt.
- The supervisor **reviews by report** and verifies via a final agent — it never opens project files, builds, or runs tests itself.

It scales the dispatch to the toolchain (git → a worktree per parallel worker; Perforce / locked-toolchain like Unreal → no worktrees, serialize compiles). Use it for any big, broad "build the whole thing" task, or whenever a session risks context bloat from reading lots of source.

## Install

```text
/plugin marketplace add met44/bigtask-skill
/plugin install bigtask@met44-skills
```

Once installed, **bigtask** auto-triggers when you start or resume a big multi-session task, and **supervise** can be invoked explicitly via the Skill tool (or runs by default when bigtask leads a task).

## Update

To pull a newly published version into an already-installed plugin:

```text
/plugin marketplace update met44-skills
/reload-plugins
```

The first command re-fetches the marketplace catalog from GitHub (it **must** run first, or the reload won't see the new version); the second reloads plugins so the new version activates without restarting Claude Code. There is no standalone `/plugin update` command — refreshing the marketplace plus reloading is the update path. You can also do this from the `/plugin` interactive menu → **Marketplaces** tab → select `met44-skills` → update, then `/reload-plugins`.

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
skills/supervise/
  SKILL.md                 # supervisor rules, dispatch workflow, anti-rationalization guardrails
```

## How bigtask works

- **Mode detection** runs first every invocation: missing task folder → INIT; folder present with valid `STATE.json` → RESUME; folder present but `STATE.json` missing → **REPAIR** (reconstruct from `PROGRESS.md` + `PLAN.md`, never re-init over existing files); `STATE.json` corrupt → stop, never overwrite.
- **Phase loop** builds a 3–10 step todo list, makes one minimal scoped edit per step, verifies, then checkpoints to disk.
- **Budgets are mechanical**: >200 changed lines or >6 files per step → split or ask; >3 fix attempts → revert just the offending files; >4 phases without a human gate → insert one.
- **Human gates** are hard stops — the agent prepares and reports "ready for review/submit" and exits; a human submits.

## License

MIT
