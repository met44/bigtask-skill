# Bigtask -- Tool-First Principle

Solve every non-trivial task by creating, extending, or invoking a tool -- never by doing the work "manually" through the editor UI or hand-edited files. Compounding effect: every tool added makes the next ten similar tasks cheaper.

Before any non-trivial action, ask: **"what's the smallest tool that would do this and the next ten like it?"** Then build that tool, log it in `EXPERIMENTS.md`, and use it.

## Decision Order

1. **Use an existing tool.** Unreal: the relevant feature MCP, then `unrealMCP` / `UnrealPlay`. C#/EndDev: extend an existing class or feature module.
2. **Extend the right module.** Feature code belongs in the feature module, never bolted onto general infrastructure (Unreal: not on `unrealMCP` / `UnrealPlay`; EndDev: not on `EndDev.Core` if it belongs in a provider).
3. **Headless host / commandlet.** Unreal: a commandlet under `Source/<Module>/Private/`. EndDev: a console host of `EndDev.Core`. Document invocation in `PLAN.md`.
4. **Editor utility / scripted mutation.** Unreal: C++ Editor Utility or `play_exec_python`. EndDev: a `dotnet` tool or one-off `Program.cs` runner.
5. **PowerShell helper** under `<PLANS>/<slug>/scripts/` for orchestration only (build wrappers, log greps). One command per script; no long semicolon chains; no `cd` (pass a working dir); prefer `-File <script>` over inline blobs.
6. **Manual UI click-through** -- last resort, genuinely one-off only. If you'd do it twice, stop and write the tool.
