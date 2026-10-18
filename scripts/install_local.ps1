# Usage: .\scripts\install_local.ps1 -AddOnsDirectory 'C:\...\_classic_beta_\Interface\AddOns'
# Copies this repo's addon to an explicitly supplied local install path.
param([Parameter(Mandatory=$true)][string]$AddOnsDirectory)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
$source=Join-Path $repo 'addon\AzerothKart'
if (-not (Test-Path $source -PathType Container)) { throw "Source addon not found: $source" }
if (-not (Test-Path $AddOnsDirectory -PathType Container)) { throw "Not a valid AddOns folder: $AddOnsDirectory" }
$target=Join-Path $AddOnsDirectory 'AzerothKart'
if (Test-Path $target) {
  Write-Warning "Existing AzerothKart folder detected at $target. Back it up manually if needed."
  $consent=Read-Host 'Overwrite files in existing AzerothKart folder? Type YES'
  if ($consent -cne 'YES') { throw 'Cancelled; no changes made' }
}
Copy-Item $source -Destination $target -Recurse -Force
Write-Host "Copied AzerothKart to $target"
Write-Host 'Launch Forever and test /akart. Confirm correct TOC flavor and watch for UI errors.'
