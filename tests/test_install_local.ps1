# Usage: powershell -NoProfile -File tests/test_install_local.ps1
# Also runs under PowerShell 7. All installs target disposable workspace fixtures.
# Fixtures are retained in ignored local-artifacts/install-tests for inspection.
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0
$repo = Split-Path -Parent $PSScriptRoot
$helper = Join-Path $repo 'scripts\install_local.ps1'
$runRoot = Join-Path $repo ('local-artifacts\install-tests\' + [Guid]::NewGuid().ToString('N'))
$utf8 = New-Object System.Text.UTF8Encoding($false)
$script:passed = 0
$script:skipped = 0

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

function Assert-Equal {
    param($Actual, $Expected, [string]$Message)
    if ($Actual -cne $Expected) {
        throw ('{0}: expected [{1}], got [{2}]' -f $Message, $Expected, $Actual)
    }
}

function Write-FixtureFile {
    param([string]$Path, [string]$Text)
    [void][System.IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
    [System.IO.File]::WriteAllText($Path, $Text, $utf8)
}

function Assert-FileText {
    param([string]$Path, [string]$Expected, [string]$Message)
    Assert-True ([System.IO.File]::Exists($Path)) ($Message + ': missing ' + $Path)
    Assert-Equal ([System.IO.File]::ReadAllText($Path)) $Expected $Message
}

function Get-TreeRows {
    param([string]$Root, [string]$Directory)
    foreach ($item in @(Get-ChildItem -LiteralPath $Directory -Force | Sort-Object Name)) {
        $relative = $item.FullName.Substring($Root.Length).TrimStart('\', '/')
        if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            'REPARSE|' + $relative
        } elseif ($item.PSIsContainer) {
            'DIRECTORY|' + $relative
            Get-TreeRows -Root $Root -Directory $item.FullName
        } else {
            'FILE|' + $relative + '|' + (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash
        }
    }
}

function Get-TreeState {
    param([string]$Root)
    return (@(Get-TreeRows -Root $Root -Directory $Root) -join "`n")
}

function New-Fixture {
    param([string]$Name)
    $root = Join-Path $runRoot $Name
    $fixtureRepo = Join-Path $root 'repo'
    $source = Join-Path $fixtureRepo 'addon\AzerothKart'
    $fixtureHelper = Join-Path $fixtureRepo 'scripts\install_local.ps1'
    $client = Join-Path $root 'client'
    $addOns = Join-Path $client '_fixture_\Interface\AddOns'
    [void][System.IO.Directory]::CreateDirectory($addOns)
    Write-FixtureFile $fixtureHelper ([System.IO.File]::ReadAllText($helper))
    Write-FixtureFile (Join-Path $source 'AzerothKart.toc') "## Interface: 16001`nCore.lua`n"
    Write-FixtureFile (Join-Path $source 'AzerothKart_Camelot.toc') "## Interface: 16001`nCore.lua`n"
    Write-FixtureFile (Join-Path $source 'Core.lua') 'return "original fixture"'
    Write-FixtureFile (Join-Path $source 'nested\asset [literal].txt') 'original nested fixture'
    $otherAddon = Join-Path $addOns 'UnrelatedAddon\main.lua'
    $save = Join-Path $client '_fixture_\WTF\Account\Fixture\SavedVariables\UnrelatedAddon.lua'
    Write-FixtureFile $otherAddon 'return "unrelated addon sentinel"'
    Write-FixtureFile $save 'UnrelatedAddonDB = { untouched = true }'
    return [PSCustomObject]@{
        Root = $root
        Repo = $fixtureRepo
        Source = $source
        Helper = $fixtureHelper
        AddOns = $addOns
        Target = (Join-Path $addOns 'AzerothKart')
        Backups = (Join-Path $root 'explicit-backups')
        OtherAddon = $otherAddon
        Save = $save
    }
}

function Assert-Isolation {
    param($Fixture)
    Assert-FileText $Fixture.OtherAddon 'return "unrelated addon sentinel"' 'Sibling addon changed'
    Assert-FileText $Fixture.Save 'UnrelatedAddonDB = { untouched = true }' 'SavedVariables sentinel changed'
}

function Assert-Throws {
    param([scriptblock]$Action, [string]$Message)
    $caught = $null
    try { & $Action | Out-Null } catch { $caught = $_ }
    Assert-True ($null -ne $caught) ($Message + ': expected a terminating error')
    return $caught
}

function Assert-RejectedUnchanged {
    param($Fixture, [scriptblock]$Action, [string]$Message, [string]$ExpectedError = '')
    $before = Get-TreeState $Fixture.Root
    $caught = Assert-Throws $Action $Message
    if ($ExpectedError) {
        Assert-True ([string]$caught -match $ExpectedError) ($Message + ': unexpected error: ' + [string]$caught)
    }
    Assert-Equal (Get-TreeState $Fixture.Root) $before ($Message + ': filesystem changed')
    Assert-Isolation $Fixture
}

function Assert-InstallResult {
    param($Result, $Fixture, [int]$ExpectedFileCount)
    Assert-Equal $Result.Target $Fixture.Target 'Result target'
    Assert-Equal $Result.FileCount $ExpectedFileCount 'Installed source file count'
    Assert-True ([System.IO.File]::Exists($Result.ManifestPath)) 'Missing install manifest'
    $manifest = Get-Content -LiteralPath $Result.ManifestPath -Raw | ConvertFrom-Json
    Assert-Equal $manifest.Status 'Verified' 'Manifest completion status'
    Assert-Equal $manifest.Source $Fixture.Source 'Manifest source'
    Assert-Equal $manifest.Target $Fixture.Target 'Manifest target'
    Assert-Equal @($manifest.Files).Count $ExpectedFileCount 'Manifest source file count'
    Assert-True ([string]::IsNullOrEmpty([string]$manifest.Error)) 'Verified manifest contains an error'
    foreach ($file in @($manifest.Files)) {
        $installed = Join-Path $Fixture.Target $file.Path
        Assert-Equal (Get-FileHash -LiteralPath $installed -Algorithm SHA256).Hash $file.SHA256 ('Installed hash: ' + $file.Path)
        Assert-Equal (Get-FileHash -LiteralPath (Join-Path $Fixture.Source $file.Path) -Algorithm SHA256).Hash $file.SHA256 ('Source hash: ' + $file.Path)
    }
    $run = Split-Path -Parent $Result.ManifestPath
    Assert-True ([System.IO.File]::Exists((Join-Path $run 'source.csv'))) 'Missing source manifest CSV'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Fixture.Target 'AzerothKart'))) 'Nested addon copy created'
    Assert-Isolation $Fixture
    return $manifest
}

function Invoke-Case {
    param([string]$Name, [scriptblock]$Action)
    & $Action
    $script:passed += 1
    Write-Host ('PASS ' + $Name)
}

[void][System.IO.Directory]::CreateDirectory($runRoot)
Write-Host ('Installer fixture root: ' + $runRoot)

Invoke-Case 'fresh install with literal bracketed paths and default artifact directory' {
    $f = New-Fixture 'fresh [literal]'
    $results = @(& $f.Helper -AddOnsDirectory $f.AddOns -Confirm:$false)
    Assert-Equal $results.Count 1 'Fresh install result count'
    $result = $results[0]
    $null = Assert-InstallResult $result $f 4
    Assert-True ($null -eq $result.BackupPath) 'Fresh install unexpectedly has a prior-install backup'
    Assert-Equal @($result.PreservedExtraFiles).Count 0 'Fresh install extra files'
    Assert-True ($result.ManifestPath.StartsWith((Join-Path $f.Repo 'local-artifacts\install-backups'), [StringComparison]::OrdinalIgnoreCase)) 'Default artifacts escaped fixture repository'
    Assert-FileText (Join-Path $f.Target 'nested\asset [literal].txt') 'original nested fixture' 'Literal filename copy'
}

Invoke-Case 'repeat install preserves complete prior files and unknown extras without nesting' {
    $f = New-Fixture 'repeat'
    $first = & $f.Helper -AddOnsDirectory $f.AddOns -Confirm:$false
    $null = Assert-InstallResult $first $f 4
    Write-FixtureFile (Join-Path $f.Target 'custom extra.lua') 'return "keep this local extra"'
    Write-FixtureFile (Join-Path $f.Source 'Core.lua') 'return "updated fixture"'
    Write-FixtureFile (Join-Path $f.Source 'added.lua') 'return "new source file"'
    Remove-Item -LiteralPath (Join-Path $f.Source 'nested\asset [literal].txt')
    $result = & $f.Helper -AddOnsDirectory $f.AddOns -Overwrite -BackupDirectory $f.Backups -Confirm:$false
    $manifest = Assert-InstallResult $result $f 4
    Assert-True ([System.IO.Directory]::Exists($result.BackupPath)) 'Missing prior-install backup'
    Assert-Equal $manifest.BackupPath $result.BackupPath 'Reported backup differs from manifest'
    Assert-FileText (Join-Path $result.BackupPath 'Core.lua') 'return "original fixture"' 'Prior source content not backed up'
    Assert-FileText (Join-Path $result.BackupPath 'custom extra.lua') 'return "keep this local extra"' 'Unknown extra not backed up'
    Assert-FileText (Join-Path $result.BackupPath 'nested\asset [literal].txt') 'original nested fixture' 'Removed source file not backed up'
    Assert-FileText (Join-Path $f.Target 'custom extra.lua') 'return "keep this local extra"' 'Unknown extra overwritten'
    Assert-FileText (Join-Path $f.Target 'nested\asset [literal].txt') 'original nested fixture' 'Removed source file deleted from target'
    $extras = @($result.PreservedExtraFiles | ForEach-Object { $_ -replace '\\', '/' } | Sort-Object)
    Assert-Equal ($extras -join '|') 'custom extra.lua|nested/asset [literal].txt' 'Preserved extra file report'
    $beforeCsv = Join-Path (Split-Path -Parent $result.ManifestPath) 'before.csv'
    Assert-True ([System.IO.File]::Exists($beforeCsv)) 'Missing prior-install manifest CSV'
    $beforeFiles = @(Import-Csv -LiteralPath $beforeCsv)
    Assert-Equal $beforeFiles.Count 5 'Prior-install manifest file count'
    foreach ($file in $beforeFiles) {
        Assert-Equal (Get-FileHash -LiteralPath (Join-Path $result.BackupPath $file.Path) -Algorithm SHA256).Hash $file.SHA256 ('Backup hash: ' + $file.Path)
    }
}

Invoke-Case 'empty existing target is backed up and filled without strict-mode errors' {
    $f = New-Fixture 'empty-existing-target'
    [void][System.IO.Directory]::CreateDirectory($f.Target)
    $result = & $f.Helper -AddOnsDirectory $f.AddOns -Overwrite -BackupDirectory $f.Backups -Confirm:$false
    $manifest = Assert-InstallResult $result $f 4
    Assert-True ([System.IO.Directory]::Exists($result.BackupPath)) 'Empty prior target backup missing'
    Assert-Equal (Get-TreeState $result.BackupPath) '' 'Empty prior target backup unexpectedly has entries'
    Assert-Equal $manifest.BackupVerified $true 'Empty prior target backup not verified'
    Assert-Equal @($result.PreservedExtraFiles).Count 0 'Empty prior target reported extras'
}

Invoke-Case 'existing target requires explicit overwrite and creates no artifacts on refusal' {
    $f = New-Fixture 'overwrite-refused'
    Write-FixtureFile (Join-Path $f.Target 'Core.lua') 'existing target sentinel'
    Assert-RejectedUnchanged $f { & $f.Helper -AddOnsDirectory $f.AddOns -BackupDirectory $f.Backups -Confirm:$false } 'Missing overwrite consent'
}

Invoke-Case 'WhatIf fresh install performs no filesystem writes' {
    $f = New-Fixture 'whatif-fresh'
    $before = Get-TreeState $f.Root
    $result = @(& $f.Helper -AddOnsDirectory $f.AddOns -BackupDirectory $f.Backups -WhatIf)
    Assert-Equal $result.Count 0 'WhatIf returned an install result'
    Assert-Equal (Get-TreeState $f.Root) $before 'Fresh WhatIf changed filesystem'
    Assert-Isolation $f
}

Invoke-Case 'WhatIf repeat install performs no backup or target writes' {
    $f = New-Fixture 'whatif-existing'
    Write-FixtureFile (Join-Path $f.Target 'Core.lua') 'existing target sentinel'
    $before = Get-TreeState $f.Root
    $result = @(& $f.Helper -AddOnsDirectory $f.AddOns -Overwrite -BackupDirectory $f.Backups -WhatIf)
    Assert-Equal $result.Count 0 'Existing WhatIf returned an install result'
    Assert-Equal (Get-TreeState $f.Root) $before 'Existing WhatIf changed filesystem'
    Assert-Isolation $f
}

Invoke-Case 'missing AddOns directory is rejected without creating it' {
    $f = New-Fixture 'missing-addons'
    Assert-RejectedUnchanged $f { & $f.Helper -AddOnsDirectory (Join-Path $f.Root 'missing') -Confirm:$false } 'Missing AddOns'
}

Invoke-Case 'target file is rejected before backup or overwrite' {
    $f = New-Fixture 'target-is-file'
    Write-FixtureFile $f.Target 'target file sentinel'
    Assert-RejectedUnchanged $f { & $f.Helper -AddOnsDirectory $f.AddOns -Overwrite -Confirm:$false } 'Target is a file'
}

Invoke-Case 'missing required TOC is rejected without writes' {
    $f = New-Fixture 'missing-toc'
    Remove-Item -LiteralPath (Join-Path $f.Source 'AzerothKart_Camelot.toc')
    Assert-RejectedUnchanged $f { & $f.Helper -AddOnsDirectory $f.AddOns -Confirm:$false } 'Missing flavor TOC'
}

Invoke-Case 'source and target overlap is rejected' {
    $f = New-Fixture 'source-target-overlap'
    $embeddedAddOns = Join-Path $f.Source 'embedded\AddOns'
    [void][System.IO.Directory]::CreateDirectory($embeddedAddOns)
    Assert-RejectedUnchanged $f { & $f.Helper -AddOnsDirectory $embeddedAddOns -Overwrite -Confirm:$false } 'Source contains target' 'overlap'
}

Invoke-Case 'backup inside source is rejected' {
    $f = New-Fixture 'backup-source-overlap'
    Assert-RejectedUnchanged $f { & $f.Helper -AddOnsDirectory $f.AddOns -BackupDirectory (Join-Path $f.Source 'backup') -Confirm:$false } 'Backup within source'
}

Invoke-Case 'backup inside AddOns is rejected' {
    $f = New-Fixture 'backup-addons-overlap'
    Assert-RejectedUnchanged $f { & $f.Helper -AddOnsDirectory $f.AddOns -BackupDirectory (Join-Path $f.AddOns 'backup') -Confirm:$false } 'Backup within AddOns'
}

Invoke-Case 'backup ancestor of source and target is rejected' {
    $f = New-Fixture 'backup-ancestor-overlap'
    Assert-RejectedUnchanged $f { & $f.Helper -AddOnsDirectory $f.AddOns -BackupDirectory $f.Root -Confirm:$false } 'Backup ancestor overlap'
}

$canCreateJunction = $false
if ($env:OS -eq 'Windows_NT') {
    Invoke-Case 'exclusive prior-file lock rejects preflight without creating artifacts' {
        $f = New-Fixture 'locked-preflight'
        Write-FixtureFile (Join-Path $f.Target 'Core.lua') 'exclusive lock sentinel'
        $before = Get-TreeState $f.Root
        $lock = [System.IO.File]::Open((Join-Path $f.Target 'Core.lua'), [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
        try {
            $null = Assert-Throws { & $f.Helper -AddOnsDirectory $f.AddOns -Overwrite -BackupDirectory $f.Backups -Confirm:$false } 'Exclusive prior-file lock'
        } finally {
            $lock.Dispose()
        }
        Assert-Equal (Get-TreeState $f.Root) $before 'Exclusive preflight failure changed filesystem'
        Assert-Isolation $f
    }

    $junctionProbeTarget = Join-Path $runRoot 'junction-capability-target'
    $junctionProbeLink = Join-Path $runRoot 'junction-capability-link'
    [void][System.IO.Directory]::CreateDirectory($junctionProbeTarget)
    try {
        $null = New-Item -ItemType Junction -Path $junctionProbeLink -Target $junctionProbeTarget
        $canCreateJunction = $true
    } catch {
        Write-Host ('Junction fixture creation unavailable: ' + $_.Exception.Message)
    }
}

if ($canCreateJunction) {
    Invoke-Case 'source junction entry is rejected without following it' {
        $f = New-Fixture 'source-junction'
        $outside = Join-Path $f.Root 'junction-destination'
        Write-FixtureFile (Join-Path $outside 'sentinel.txt') 'junction destination sentinel'
        $null = New-Item -ItemType Junction -Path (Join-Path $f.Source 'linked') -Target $outside
        Assert-RejectedUnchanged $f { & $f.Helper -AddOnsDirectory $f.AddOns -Confirm:$false } 'Source junction'
    }

    Invoke-Case 'target junction entry is rejected without following it' {
        $f = New-Fixture 'target-junction'
        $outside = Join-Path $f.Root 'junction-destination'
        Write-FixtureFile (Join-Path $outside 'sentinel.txt') 'junction destination sentinel'
        [void][System.IO.Directory]::CreateDirectory($f.Target)
        $null = New-Item -ItemType Junction -Path (Join-Path $f.Target 'linked') -Target $outside
        Assert-RejectedUnchanged $f { & $f.Helper -AddOnsDirectory $f.AddOns -Overwrite -Confirm:$false } 'Target junction'
    }

    Invoke-Case 'junction AddOns ancestor is rejected' {
        $f = New-Fixture 'ancestor-junction'
        $redirect = Join-Path $f.Root 'redirected-client'
        $null = New-Item -ItemType Junction -Path $redirect -Target (Split-Path -Parent $f.AddOns)
        $redirectedAddOns = Join-Path $redirect 'AddOns'
        Assert-RejectedUnchanged $f { & $f.Helper -AddOnsDirectory $redirectedAddOns -Confirm:$false } 'Junction ancestor'
    }
} else {
    $script:skipped += 3
    Write-Host 'SKIP three junction rejection tests: fixture junction creation is unavailable.'
}

if ($env:OS -eq 'Windows_NT') {
    Invoke-Case 'locked target write retains verified backup and failed manifest' {
        $f = New-Fixture 'locked-target'
        $first = & $f.Helper -AddOnsDirectory $f.AddOns -Confirm:$false
        $null = Assert-InstallResult $first $f 4
        Write-FixtureFile (Join-Path $f.Source 'Core.lua') 'return "updated while target is locked"'
        Write-FixtureFile (Join-Path $f.Source '000-added.lua') 'return "new file copied before locked Core"'
        Write-FixtureFile (Join-Path $f.Source 'AzerothKart.toc') "## Interface: 16001`n## Notes: changed before locked Core`nCore.lua`n"
        $lockedFile = Join-Path $f.Target 'Core.lua'
        $lock = [System.IO.File]::Open($lockedFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
        try {
            $caught = Assert-Throws { & $f.Helper -AddOnsDirectory $f.AddOns -Overwrite -BackupDirectory $f.Backups -Confirm:$false } 'Locked target copy'
        } finally {
            $lock.Dispose()
        }
        $manifests = @(Get-ChildItem -LiteralPath $f.Backups -Filter 'install.json' -File -Recurse)
        Assert-Equal $manifests.Count 1 'Failure manifest count'
        $manifest = Get-Content -LiteralPath $manifests[0].FullName -Raw | ConvertFrom-Json
        Assert-Equal $manifest.Status 'Failed' 'Failure manifest status'
        Assert-Equal $manifest.BackupVerified $true 'Target copy started before backup verification'
        Assert-Equal $manifest.TargetCopyStarted $true 'Locked target failure omitted copy-start marker'
        Assert-Equal $manifest.Stage 'Copy' 'Locked target failure stage'
        Assert-True (-not [string]::IsNullOrEmpty([string]$manifest.Error)) 'Failure manifest omits error'
        Assert-True (-not [string]::IsNullOrEmpty([string]$manifest.BackupPath)) 'Failure manifest omits backup'
        Assert-True ([string]$caught -match [regex]::Escape([string]$manifest.BackupPath)) 'Failure message omits preserved backup path'
        Assert-FileText (Join-Path $manifest.BackupPath 'Core.lua') 'return "original fixture"' 'Locked target prior file not preserved'
        Assert-FileText $lockedFile 'return "original fixture"' 'Locked target unexpectedly changed'
        Assert-FileText (Join-Path $f.Target '000-added.lua') 'return "new file copied before locked Core"' 'Expected partially installed new file missing'
        Assert-FileText (Join-Path $f.Target 'AzerothKart.toc') "## Interface: 16001`n## Notes: changed before locked Core`nCore.lua`n" 'Expected partially updated TOC missing'
        $beforeCsv = Join-Path (Split-Path -Parent $manifests[0].FullName) 'before.csv'
        Assert-True ([System.IO.File]::Exists($beforeCsv)) 'Failed install lacks verified prior manifest'
        $beforeFiles = @(Import-Csv -LiteralPath $beforeCsv)
        foreach ($file in $beforeFiles) {
            Assert-Equal (Get-FileHash -LiteralPath (Join-Path $manifest.BackupPath $file.Path) -Algorithm SHA256).Hash $file.SHA256 ('Failure backup hash: ' + $file.Path)
        }

        # Rehearse the documented manual recovery: preserve the incomplete target,
        # then overlay verified prior files. New files require deliberate cleanup.
        $failedCopy = Join-Path $f.Root 'failed-target-preserved'
        [void][System.IO.Directory]::CreateDirectory($failedCopy)
        foreach ($directory in @(Get-ChildItem -LiteralPath $f.Target -Directory -Recurse)) {
            $relative = $directory.FullName.Substring($f.Target.Length).TrimStart('\', '/')
            [void][System.IO.Directory]::CreateDirectory((Join-Path $failedCopy $relative))
        }
        foreach ($file in @(Get-ChildItem -LiteralPath $f.Target -File -Recurse)) {
            $relative = $file.FullName.Substring($f.Target.Length).TrimStart('\', '/')
            Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $failedCopy $relative) -Force
        }
        Assert-Equal (Get-TreeState $failedCopy) (Get-TreeState $f.Target) 'Failed target preservation differs'
        foreach ($file in $beforeFiles) {
            Copy-Item -LiteralPath (Join-Path $manifest.BackupPath $file.Path) -Destination (Join-Path $f.Target $file.Path) -Force
            Assert-Equal (Get-FileHash -LiteralPath (Join-Path $f.Target $file.Path) -Algorithm SHA256).Hash $file.SHA256 ('Manual restore hash: ' + $file.Path)
        }
        Assert-FileText (Join-Path $f.Target 'AzerothKart.toc') "## Interface: 16001`nCore.lua`n" 'Manual restore did not recover old TOC'
        Assert-FileText (Join-Path $f.Target '000-added.lua') 'return "new file copied before locked Core"' 'Manual overlay unexpectedly deleted new file'
        Assert-FileText (Join-Path $failedCopy 'AzerothKart.toc') "## Interface: 16001`n## Notes: changed before locked Core`nCore.lua`n" 'Preserved failed target changed during recovery'
        Assert-Isolation $f
    }
} else {
    $script:skipped += 2
    Write-Host 'SKIP two Windows file-sharing tests: Windows is required.'
}

Invoke-Case 'backup hash verification failure prevents target writes' {
    $f = New-Fixture 'backup-verification-failure'
    Write-FixtureFile (Join-Path $f.Target 'Core.lua') 'prior target must survive failed backup verification'
    $before = Get-TreeState $f.Target
    function Get-FileHash {
        [CmdletBinding()]
        param([string]$LiteralPath, [string]$Algorithm)
        $hash = Microsoft.PowerShell.Utility\Get-FileHash @PSBoundParameters
        if ($LiteralPath.StartsWith($f.Backups + [System.IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            $hash.Hash = ('0' * 64)
        }
        return $hash
    }
    try {
        $null = Assert-Throws { & $f.Helper -AddOnsDirectory $f.AddOns -Overwrite -BackupDirectory $f.Backups -Confirm:$false } 'Injected backup hash mismatch'
    } finally {
        Remove-Item -LiteralPath 'Function:\Get-FileHash'
    }
    $manifests = @(Get-ChildItem -LiteralPath $f.Backups -Filter 'install.json' -File -Recurse)
    Assert-Equal $manifests.Count 1 'Backup verification failure manifest count'
    $manifest = Get-Content -LiteralPath $manifests[0].FullName -Raw | ConvertFrom-Json
    Assert-Equal $manifest.Status 'Failed' 'Backup verification failure status'
    Assert-Equal $manifest.Stage 'Backup' 'Backup verification failure stage'
    Assert-Equal $manifest.BackupVerified $false 'Failed backup incorrectly marked verified'
    Assert-Equal $manifest.TargetCopyStarted $false 'Target copy started after failed backup verification'
    Assert-Equal (Get-TreeState $f.Target) $before 'Backup verification failure changed target'
    Assert-FileText (Join-Path $manifest.BackupPath 'Core.lua') 'prior target must survive failed backup verification' 'Backup copy was not preserved'
    Assert-Isolation $f
}

Invoke-Case 'target appearing after preflight is not overwritten without backup' {
    $f = New-Fixture 'concurrent-new-target'
    function Export-Csv {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline=$true)]$InputObject,
            [string]$LiteralPath, [switch]$NoTypeInformation, [string]$Encoding
        )
        begin { $entries=@() }
        process { $entries += $InputObject }
        end {
            $entries | Microsoft.PowerShell.Utility\Export-Csv -LiteralPath $LiteralPath -NoTypeInformation -Encoding $Encoding
            Write-FixtureFile (Join-Path $f.Target 'Core.lua') 'target appeared during preflight-to-copy interval'
        }
    }
    try {
        $caught = Assert-Throws { & $f.Helper -AddOnsDirectory $f.AddOns -BackupDirectory $f.Backups -Confirm:$false } 'Concurrent fresh target'
    } finally {
        Remove-Item -LiteralPath 'Function:\Export-Csv'
    }
    Assert-True ([string]$caught -match 'Target appeared after preflight') 'Wrong concurrent-target rejection'
    Assert-FileText (Join-Path $f.Target 'Core.lua') 'target appeared during preflight-to-copy interval' 'Concurrent target overwritten'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $f.Target 'AzerothKart.toc'))) 'Unexpected files copied into concurrent target'
    $manifestFile = @(Get-ChildItem -LiteralPath $f.Backups -Filter 'install.json' -File -Recurse)
    $manifest = Get-Content -LiteralPath $manifestFile[0].FullName -Raw | ConvertFrom-Json
    Assert-Equal $manifest.Status 'Failed' 'Concurrent-target failure status'
    Assert-Equal $manifest.TargetCopyStarted $false 'Concurrent-target rejection started copying'
    Assert-Isolation $f
}

Invoke-Case 'installed hash mismatch never reports a verified target' {
    $f = New-Fixture 'target-verification-failure'
    function Get-FileHash {
        [CmdletBinding()]
        param([string]$LiteralPath, [string]$Algorithm)
        $hash = Microsoft.PowerShell.Utility\Get-FileHash @PSBoundParameters
        if ($LiteralPath.StartsWith($f.Target + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            $hash.Hash = ('0' * 64)
        }
        return $hash
    }
    try {
        $caught = Assert-Throws { & $f.Helper -AddOnsDirectory $f.AddOns -BackupDirectory $f.Backups -Confirm:$false } 'Injected installed hash mismatch'
    } finally {
        Remove-Item -LiteralPath 'Function:\Get-FileHash'
    }
    Assert-True ([string]$caught -match 'SHA-256 verification failed') 'Wrong installed-hash rejection'
    $manifestFile = @(Get-ChildItem -LiteralPath $f.Backups -Filter 'install.json' -File -Recurse)
    $manifest = Get-Content -LiteralPath $manifestFile[0].FullName -Raw | ConvertFrom-Json
    Assert-Equal $manifest.Status 'Failed' 'Installed-hash failure status'
    Assert-Equal $manifest.TargetCopyStarted $true 'Installed-hash failure omitted copy-start marker'
    Assert-Equal $manifest.Stage 'Copy' 'Installed-hash failure stage'
    Assert-True ($null -eq $manifest.BackupPath) 'Fresh failed install fabricated a prior backup'
    Assert-Isolation $f
}

Write-Host ('Installer tests passed: {0}; skipped: {1}. Fixtures retained at {2}' -f $script:passed, $script:skipped, $runRoot)
