# Developer install only. No default game path, deletion, rollback or publishing.
# Preview: .\scripts\install_local.ps1 -AddOnsDirectory 'C:\...\Interface\AddOns' -Overwrite -WhatIf
[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
param(
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$AddOnsDirectory,
    [switch]$Overwrite,
    [string]$BackupDirectory
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

function Test-Within([string]$Path, [string]$Root) {
    $prefix = $Root.TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
    return $Path.Equals($Root, [StringComparison]::OrdinalIgnoreCase) -or
        $Path.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
}

function Assert-Separate([string]$First, [string]$Second) {
    if ((Test-Within $First $Second) -or (Test-Within $Second $First)) {
        throw "Paths must not overlap: $First ; $Second"
    }
}

function Assert-PlainPath([string]$Path) {
    # Resolve-Path alone does not reject a junction in an ancestor directory.
    $cursor = $Path
    while ($cursor) {
        if (Test-Path -LiteralPath $cursor) {
            $item = Get-Item -LiteralPath $cursor -Force
            if ($item -isnot [IO.FileSystemInfo] -or
                ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                throw "Non-filesystem or reparse path is unsupported: $cursor"
            }
        }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
}

function Get-Tree([string]$Root) {
    # Walk explicitly so reparse directories are rejected before traversal.
    $files = @()
    $directories = @()
    $pending = New-Object 'System.Collections.Generic.Queue[string]'
    $pending.Enqueue($Root)
    while ($pending.Count -gt 0) {
        $folder = $pending.Dequeue()
        foreach ($item in Get-ChildItem -LiteralPath $folder -Force) {
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Reparse entry is unsupported: $($item.FullName)"
            }
            $relative = $item.FullName.Substring($Root.Length).TrimStart([char[]]'\/')
            if ($item.PSIsContainer) {
                $directories += $relative
                $pending.Enqueue($item.FullName)
            } else {
                $files += [pscustomobject]@{
                    Path = $relative
                    SHA256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
                }
            }
        }
    }
    return [pscustomobject]@{ Files=@($files | Sort-Object Path); Directories=$directories }
}

function Copy-Tree([string]$From, [string]$To, $Tree) {
    [void][IO.Directory]::CreateDirectory($To)
    foreach ($relative in $Tree.Directories) {
        [void][IO.Directory]::CreateDirectory((Join-Path $To $relative))
    }
    foreach ($file in $Tree.Files) {
        Copy-Item -LiteralPath (Join-Path $From $file.Path) -Destination (Join-Path $To $file.Path) -Force
    }
}

function Assert-Hashes([string]$Root, $Files) {
    foreach ($file in $Files) {
        $path = Join-Path $Root $file.Path
        if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or
            (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $file.SHA256) {
            throw "SHA-256 verification failed: $path"
        }
    }
}

function Assert-Snapshot([string]$Root, $Tree) {
    $current = Get-Tree $Root
    if ($current.Files.Count -ne $Tree.Files.Count -or
        (@($current.Directories | Sort-Object) -join '|') -cne (@($Tree.Directories | Sort-Object) -join '|') -or
        (@($current.Files | ForEach-Object { $_.Path }) -join '|') -cne
        (@($Tree.Files | ForEach-Object { $_.Path }) -join '|')) {
        throw "File tree changed during install: $Root"
    }
    for ($index=0; $index -lt $Tree.Files.Count; $index++) {
        if ($current.Files[$index].SHA256 -ne $Tree.Files[$index].SHA256) {
            throw "SHA-256 snapshot changed during install: $Root"
        }
    }
}

function Write-Record($Record, [string]$Path) {
    $json = $Record | ConvertTo-Json -Depth 6
    [IO.File]::WriteAllText($Path, $json, (New-Object Text.UTF8Encoding($false)))
}

$repo = Split-Path -Parent $PSScriptRoot
$source = [IO.Path]::GetFullPath((Join-Path $repo 'addon\AzerothKart'))
$addOns = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($AddOnsDirectory)
$addOns = [IO.Path]::GetFullPath($addOns).TrimEnd([char[]]'\/')
if (-not (Test-Path -LiteralPath $source -PathType Container)) { throw "Source addon not found: $source" }
if (-not (Test-Path -LiteralPath $addOns -PathType Container) -or
    (Split-Path -Leaf $addOns) -ine 'AddOns') { throw "Not an existing AddOns folder: $addOns" }
$target = Join-Path $addOns 'AzerothKart'
if (-not $BackupDirectory) { $BackupDirectory = Join-Path $repo 'local-artifacts\install-backups' }
$backups = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($BackupDirectory)
$backups = [IO.Path]::GetFullPath($backups).TrimEnd([char[]]'\/')
Assert-Separate $source $addOns
Assert-Separate $backups $addOns
Assert-Separate $backups $source
foreach ($path in @($source,$target,$backups)) { Assert-PlainPath $path }
if ((Test-Path -LiteralPath $backups) -and -not (Test-Path -LiteralPath $backups -PathType Container)) {
    throw "Backup path is not a directory: $backups"
}
$exists = Test-Path -LiteralPath $target
if ($exists -and -not (Test-Path -LiteralPath $target -PathType Container)) {
    throw "Target is not a directory: $target"
}
if ($exists -and -not $Overwrite) { throw 'Existing AzerothKart requires -Overwrite; no changes made.' }
foreach ($toc in @('AzerothKart.toc','AzerothKart_Camelot.toc')) {
    if (-not (Test-Path -LiteralPath (Join-Path $source $toc) -PathType Leaf)) {
        throw "Source TOC missing: $toc"
    }
}
$sourceTree = Get-Tree $source
$beforeTree = if ($exists) { Get-Tree $target } else { $null }
# Detect all file/directory collisions before any backup or target write.
foreach ($file in $sourceTree.Files) {
    if (Test-Path -LiteralPath (Join-Path $target $file.Path) -PathType Container) {
        throw "Source file conflicts with target directory: $($file.Path)"
    }
}
foreach ($directory in $sourceTree.Directories) {
    if (Test-Path -LiteralPath (Join-Path $target $directory) -PathType Leaf) {
        throw "Source directory conflicts with target file: $directory"
    }
}
if (-not $PSCmdlet.ShouldProcess($target, 'Back up existing files, copy AzerothKart files and verify SHA-256')) { return }

$run = Join-Path $backups ((Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [guid]::NewGuid().ToString('N'))
$backupPath = if ($exists) { Join-Path $run 'before' } else { $null }
$manifestPath = Join-Path $run 'install.json'
$record = [ordered]@{
    Status='Prepared'; Stage='Backup'; StartedUtc=[DateTime]::UtcNow.ToString('o')
    Source=$source; Target=$target; BackupPath=$backupPath
    BackupVerified=$false; TargetCopyStarted=$false; Files=$sourceTree.Files; Error=$null
}
$targetStarted = $false
try {
    [void][IO.Directory]::CreateDirectory($run)
    Write-Record $record $manifestPath
    $sourceTree.Files | Export-Csv -LiteralPath (Join-Path $run 'source.csv') -NoTypeInformation -Encoding UTF8
    if ($exists) {
        $beforeTree.Files | Export-Csv -LiteralPath (Join-Path $run 'before.csv') -NoTypeInformation -Encoding UTF8
        Copy-Tree $target $backupPath $beforeTree
        Assert-Snapshot $backupPath $beforeTree
        $record.BackupVerified = $true
    }
    # Recheck path redirection and the preflight snapshots before target writes.
    foreach ($path in @($source,$target,$run)) { Assert-PlainPath $path }
    Assert-Snapshot $source $sourceTree
    if ($exists) { Assert-Snapshot $target $beforeTree }
    elseif (Test-Path -LiteralPath $target) { throw "Target appeared after preflight; rerun with a backup: $target" }
    $targetStarted = $true
    $record.TargetCopyStarted = $true
    $record.Stage = 'Copy'
    Write-Record $record $manifestPath
    Copy-Tree $source $target $sourceTree
    Assert-Hashes $target $sourceTree.Files
    $record.Status = 'Verified'
    $record.Stage = 'Verified'
    Write-Record $record $manifestPath
} catch {
    $record.Status = 'Failed'
    $record.Error = $_.Exception.Message
    try { Write-Record $record $manifestPath } catch { Write-Warning "Could not update manifest: $manifestPath" }
    $state = if ($targetStarted) { 'Target may be partially updated; no automatic rollback was attempted.' }
             else { 'Target copy was not started.' }
    throw "Install failed: $($record.Error) $state Backup: $backupPath ; manifest: $manifestPath"
}
$extras = @()
if ($exists) {
    $extras = @($beforeTree.Files | Where-Object { $_.Path -notin $sourceTree.Files.Path } | ForEach-Object { $_.Path })
}
Write-Host "Verified $($sourceTree.Files.Count) source files in $target"
if ($backupPath) { Write-Host "Prior files preserved in $backupPath" }
if ($extras.Count) { Write-Host "Preserved $($extras.Count) extra target files; see the backup manifest before manual cleanup." }
[pscustomobject]@{
    Target=$target; BackupPath=$backupPath; ManifestPath=$manifestPath
    FileCount=$sourceTree.Files.Count; PreservedExtraFiles=$extras
}
