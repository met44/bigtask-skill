# Bigtask -- Verification Toolkit

Every phase that touches code or content MUST end with automated verification, not "looks fine to me." Pick the lowest-cost layer that *proves* the change. When something looks wrong, read logs before guessing.

## Unreal C++ (inside a UE project)

1. **Build** -- `compile_project` MCP (unrealMCP / UnrealPlay). Always first. It handles editor kill/relaunch around the build; never `Start-Process` the editor, use `launch_editor`.
2. **Headless automation** -- `automation_run_tests` (filter to the touched suite), then `automation_get_results`. Or `UnrealEditor-Cmd.exe <Project>.uproject -run=Automation -ExecCmds="Automation RunTests <Filter>"`.
3. **PIE state introspection** -- `play_get_world_state`, `play_get_player_state`, `play_get_nearby_actors`, `play_get_actor_info`, `play_get_gameplay_state`, `play_get_ui_state`, `play_get_console_output`.
4. **Direct gameplay drive** -- `play_call_function`, `play_exec_console` (`ke * <event>`, `ce <event>`).
5. **Input simulation** -- `play_keyboard_input`, `play_mouse_input`, `play_gamepad_input`, `play_interact_ui`, `play_navigate_to`. Only when validating the input path itself.
6. **Visual verification** -- `play_screenshot` / `pie_screenshot`. Capture a before/after pair `<slug>_<phase>_before.png` / `_after.png` under `reports/screens/`, link both from `PROGRESS.md`. Standard angles: Front=-Y, Back=+Y, Left=+X, Right=-X, Top=+Z, Perspective=45deg front-right-above.
7. **Feature-specific MCP** -- use per-feature MCPs for scenario setup; do not hand-place actors in PIE.

## C# / .NET / WPF

1. **Build** -- `dotnet build` at solution root; warnings-as-errors must pass.
2. **Unit tests** -- via `tools/run-tests.ps1` (bare `dotnet test` truncates output in this shell). Filter to the touched class first, then the full suite.
3. **Headless smoke** -- `dotnet run --project src/EndDev.Bridge -- --adapter repl` (or `runheadless.bat repl`) drives the engine via stdin/stdout without WPF.
4. **WPF smoke** -- `dotnet run --project src/EndDev.Tray` (or `run.bat`); drive via UIAutomation, or capture the window via `PrintWindow` (works regardless of z-order / monitor placement).
5. **Visual verification** -- screenshot affected screen before + after at final display size; save under `reports/screens/`, link from `PROGRESS.md`.

## Timing

Never `Start-Sleep` to wait on a long job -- run it non-blocking and follow `references/long-jobs.md`, or use the connected MCP's wait mechanism.
