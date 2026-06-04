# Bigtask -- Init (Bootstrap)

Run only when the task folder does not yet exist. If the folder exists, you are in RESUME or REPAIR (see SKILL.md mode detection) -- do NOT re-init over existing files.

Inputs (ask once if not provided): `slug` (kebab-case, <=24 chars), one-line `goal`, ordered `phases` (3-10 ids, e.g. `audit, design, impl_a, validate, human_gate_submit`).

## Steps

1. **Detect VCS and create the unit of work** (see SKILL.md "Tooling Availability"):
   - git -> create feature branch `task/<slug>` off `main`. If the tree has uncommitted unrelated changes, stash and warn rather than committing them.
   - Perforce (MCP connected) -> create one pending CL `"<slug>: <goal>"`; record the number in `STATE.changelist`. Do not touch unrelated pending CLs.
   - none -> `STATE.vcs="none"`, `STATE.changelist=null`; note in PLAN.md that VCS strategy is a phase-1 decision.
2. All edits this skill makes go into that unit of work and stay there until the human submits/merges.
3. Create `<PLANS>/<slug>/` and these files (abort only the file creation, not the task, if a specific file already exists -- prefer REPAIR):
   - `PLAN.md` -- from `templates/PLAN.md`. Header (goal, phase list, default build/test commands), then one section per phase: scope, concrete steps, success criteria, test requirements, budget, explicit `HUMAN GATE` markers. The final phase is always `human_gate_submit`.
   - `STATE.json` -- from `templates/STATE.json`, filled in. `phase` = first phase, `step` = "pending".
   - `PROGRESS.md` -- header + first entry: bootstrap, status `done`.
   - `EXPERIMENTS.md` -- only if a phase is experiment/validation.
   - `scripts/status.ps1` -- copy `templates/status.ps1` (prints STATE.json, last 10 PROGRESS entries, last 3 EXPERIMENTS headings, file count in the unit of work).
4. Keep the unit of work code-only where possible: in Perforce, put the plan docs in a separate/default CL so the task CL is easy to review. In git this is less critical; an initial `chore(<slug>): plan docs` commit is fine.
5. Emit a bootstrap status (goal, phase list, unit-of-work id, first phase about to run). Notify via Telegram MCP if connected; otherwise inline.
6. Output a short summary; ask whether to start the first phase now or stop here.
