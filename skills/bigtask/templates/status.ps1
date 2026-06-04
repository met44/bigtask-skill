#requires -Version 5.1
# Bigtask status: prints STATE.json, recent progress, recent experiments.
# Usage: powershell -File status.ps1 -PlanDir <PLANS>\<slug>
param(
    [Parameter(Mandatory = $true)][string]$PlanDir
)

$ErrorActionPreference = 'Stop'

$statePath = Join-Path $PlanDir 'STATE.json'
$progressPath = Join-Path $PlanDir 'PROGRESS.md'
$experimentsPath = Join-Path $PlanDir 'EXPERIMENTS.md'

Write-Output '=== STATE ==='
if (Test-Path $statePath) { Get-Content $statePath -Raw } else { Write-Output '(missing STATE.json)' }

Write-Output ''
Write-Output '=== LAST 10 PROGRESS ==='
if (Test-Path $progressPath) { Get-Content $progressPath -Tail 10 } else { Write-Output '(no PROGRESS.md)' }

Write-Output ''
Write-Output '=== LAST 3 EXPERIMENT HEADINGS ==='
if (Test-Path $experimentsPath) {
    Select-String -Path $experimentsPath -Pattern '^##\s' | Select-Object -Last 3 | ForEach-Object { $_.Line }
} else {
    Write-Output '(no EXPERIMENTS.md)'
}
