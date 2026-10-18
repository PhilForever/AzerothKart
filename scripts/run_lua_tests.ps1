$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
Push-Location $repo
try {
  if (-not (Get-Command lua -ErrorAction SilentlyContinue)) { throw 'Lua not on PATH. Install a compatible Lua runtime first.' }
  & lua tests/run.lua
  if ($LASTEXITCODE -ne 0) { throw "Lua tests failed (exit $LASTEXITCODE)" }
} finally { Pop-Location }
