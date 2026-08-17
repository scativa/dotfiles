# lift.ps1 — bridge to Git Bash (Windows). Requires Git for Windows.
# The logic lives in lift.sh; this only resolves bash and delegates.
$ErrorActionPreference = "Stop"
$bash = (Get-Command bash -ErrorAction SilentlyContinue).Source
if (-not $bash) { throw "Git Bash required: install Git for Windows (winget install --id Git.Git)" }
$sh = Join-Path $PSScriptRoot "lift.sh"
if (-not (Test-Path $sh)) { throw "Missing lift.sh" }
& $bash $sh @args
exit $LASTEXITCODE
