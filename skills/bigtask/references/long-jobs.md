# Bigtask -- Long-Job Discipline

For any job > 30 min: shader compiles, full lighting builds, mass asset imports, full automation suites.

1. Record the current power scheme into `STATE.long_jobs[].prev_power_scheme`:
   `powercfg /getactivescheme`
2. Prevent standby for the duration: `powercfg /change standby-timeout-ac 0`.
3. Launch the job **non-blocking** (background). Record `pid`, `log_path`, `started_at` in `STATE.long_jobs` and `PROGRESS.md`. (Stamp `started_at` from a real clock at write time -- do not guess.)
4. Notify start (Telegram MCP if connected, else inline). Exit the skill.
5. Next invocation, check the job FIRST:
   - Done -> parse results, append `EXPERIMENTS.md`, clear the entry from `long_jobs`, resume the phase loop.
   - Still running -> emit status, exit.
6. After the session's last long job completes, restore the power scheme:
   `powercfg /setactive <prev_guid>`.

Never `Start-Sleep` to wait out a long job in the foreground.
