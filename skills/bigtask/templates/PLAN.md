# PLAN -- <slug>

**Goal:** <one-line goal>

**VCS / unit of work:** <git branch task/<slug> | P4 CL #<n> | none>

**Phases:** <audit, design, impl_a, validate, human_gate_submit>

**Default build:** <compile_project MCP | dotnet build at solution root>
**Default tests:** <automation_run_tests <Filter> | tools/run-tests.ps1>

**Budgets (override per phase below):** <=200 changed lines/step, <=6 files/step, <=3 fix attempts, <=4 phases between human gates.

---

## Phase: <id>

- **Scope:** what this phase may touch (and what it may NOT).
- **Steps:**
  1. ...
  2. ...
- **Success criteria:** observable, verifiable conditions.
- **Test requirements:** which verification layer proves this phase (see references/verification.md).
- **Budget:** <inherit defaults | overrides>.

<!-- repeat per phase -->

## Phase: human_gate_submit  *(HUMAN GATE)*

- Agent prepares + verifies; cleans up the unit of work; emits "ready for review/submit".
- The human reviews and submits/merges. Agent never submits.
