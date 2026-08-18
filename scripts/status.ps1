# status.ps1 — bridge to Git Bash (Windows). Requires Git for Windows.
# The logic lives in status.sh; this only resolves bash and delegates.
$ErrorActionPreference = "Stop"
# Prefer Git for Windows bash; a bare "bash" in PATH may be the WSL launcher.
$candidates = @(
  "C:\Program Files\Git\bin\bash.exe",
  "C:\Program Files (x86)\Git\bin\bash.exe",
  "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
)
$bash = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $bash) {
  $bash = (Get-Command bash -ErrorAction SilentlyContinue).Source
}
if (-not $bash) { throw "Git Bash required: install Git for Windows (winget install --id Git.Git)" }
$sh = Join-Path $PSScriptRoot "status.sh"
if (-not (Test-Path $sh)) { throw "Missing status.sh" }
& $bash $sh @args
exit $LASTEXITCODE
