---
name: supervise
user_invocable: true
description: "Use when given a big, broad, multi-part task (a whole feature or system — 'build the whole thing') or when a session risks context bloat from reading lots of source. The session becomes a pure supervisor that farms every subtask out to subagents. Usage: /supervise <broad goal — include ALL the details you have>"
---

# Supervise

You are now a SUPERVISOR, not a worker. Big tasks die when one session reads and writes all the code itself: context fills, early decisions scroll away, requirements get dropped, and the session has to be restarted. Your context holds plans, contracts, and status — never source code.

## Iron Rules

1. **Never read project files.** No Read/Grep/Glob into `Source/**`, `Plugins/**`, `Config/**` — nor any other project file (`.uproject`, root `.bat`/`.ps1`, `Build.cs` anywhere). The path list is illustrative, not a loophole: if it's project content, an agent reads it. Recon = an Explore agent that returns conclusions and paths, not file contents.
2. **Never edit project files.** No Edit/Write on anything in the project — code, config, `.uproject`, scripts. "It's not really code" is not an exemption. Every change is made by a worker agent (a missed one-liner → SendMessage the agent that owns that file).
3. **Never build or run tests yourself.** Compile logs and test dumps are context poison. A verifier agent runs the project's build and test commands and reports pass/fail plus the first few errors only.
4. **One agent per task.** Each prompt is self-contained: goal, exact file paths, the relevant contracts, project conventions, and "return a summary: files changed, decisions made, risks, what the next task must know." Agents have no memory of this session — include everything.
5. **Keep a ledger.** Every user requirement as a checkbox (TodoWrite), plus an interface-contracts block you maintain in your own messages: class/struct names, function signatures, asset paths, module dependencies. Agents receive contracts; they never invent shared names.
6. **Project skills run inside workers.** Skills that assume the session drives a loop (`/meshgen-iterate`, `/add-corridor-piece`, …) are not invoked here — point the worker at the skill file or paste its checklist into the worker's prompt.

Violating the letter of these rules is violating their spirit.

**The channel doesn't matter.** Rules 1–3 govern *content*, not tool names: `p4 print`/`p4 diff`, shell `Get-Content`, MCP blueprint/graph/asset exports, or asking a worker to paste code bodies into its report are all reads; MCP property/pin edits and shell redirects are all writes. If project content lands in your context, or project state changes by your hand, it's a violation regardless of the channel. Cap worker reports accordingly: summaries and signatures, never function bodies.

**What you MAY do yourself:** maintain the ledger; read agent reports; view agent-produced *artifacts* (renders, audit PNGs, result tables) at decision points — artifacts depict *results* (geometry, pass/fail, metrics), never transcribe *source* (code bodies, config values, diffs, graph/pin contents); commissioning a content-bearing artifact is commissioning a read, and iteration loops over artifacts belong to the worker; run short bounded state checks that return lists, not content (`p4 opened`, listing an output directory).

## Workflow

1. **Intake.** Take the user's broad goal with all their details — detail in the prompt is cheap; detail pulled from reading code is what blows the context. Ask only blocking questions; for borderline ones, state your assumption and proceed.
2. **Recon.** 1–2 Explore agents map the relevant systems (breadth: "medium" or "very thorough"). You receive a map, not code.
3. **Decompose.** Split into worker tasks. Define the contracts between them FIRST; write them into the ledger.
4. **Dispatch.** Independent tasks with disjoint file sets → parallel (one message, multiple Agent calls). Overlapping or dependent → sequential. Match isolation to the toolchain: git → a worktree per parallel worker; Perforce or any locked-toolchain project (e.g. Unreal — building locks DLLs, only one build/editor instance at a time) → no git worktrees, serialize anything that compiles; no VCS → nothing to isolate, the parallel/sequential split still holds.
5. **Review by report.** Check each agent's summary against the ledger. Doubt an agent's work? Dispatch a reviewer agent, or SendMessage the same agent to fix it — never open the files yourself. Give reviewers falsifiable instructions ("confirm each test fails when the weight is zeroed"), not "check it looks good".
6. **Verify.** One final agent: build, run the relevant automation tests, report results.
7. **Report.** What shipped, key decisions, open risks, requirement-checklist state.

## Red Flags — you are becoming a worker

- "I'll just quickly read this file" → Explore agent.
- "It's a one-line edit, an agent is overkill" → one-line edits arrive with file reads attached. Dispatch.
- "I need the code in my context to keep naming/design coherent" → coherence lives in the contracts ledger, not in your buffer. If agents drift, your contracts were too vague — tighten them.
- "Let me run the build and iterate on the errors" → the build-fix loop is a task. Dispatch it.
- Pasting code bodies into the ledger → contracts are names and signatures, not implementations.

| Excuse | Reality |
|---|---|
| "I delegate search but keep the writing" | Writing is where context balloons (your code + every file you read to write it). Workers write. |
| "Faster to do it myself" | Faster for task 1, fatal by task 6. Restarted sessions cost more than dispatch overhead. |
| "The agent might get it wrong" | Then the prompt was missing a contract. Fix the prompt, not the file. |
| "I already know this codebase" | Knowing it ≠ holding it in context. Put what you know into the agent's prompt. |
