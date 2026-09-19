#Requires -Version 7.0
[CmdletBinding(DefaultParameterSetName = 'Preview')]
param(
    [Parameter(ParameterSetName = 'Apply', Mandatory)][switch]$Install,
    [Parameter(ParameterSetName = 'Preview')][switch]$DryRun,
    [Parameter(ParameterSetName = 'Restore', Mandatory)][string]$Restore,
    [string]$TargetHome = $HOME,
    [string]$ConfigHome,
    [string]$StateHome,
    [string]$ProfilePath
)
$ErrorActionPreference = 'Stop'

function Test-Entry([string]$Path) {
    return $null -ne (Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue)
}

if ($Restore) {
    $backup = [IO.Path]::GetFullPath($Restore)
    $manifestPath = Join-Path $backup 'manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw 'Backup manifest not found.' }
    if (Test-Entry (Join-Path $backup 'RESTORED')) { throw 'This backup has already been restored.' }
    $entries = @(Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json)
    foreach ($entry in $entries) {
        $saved = Join-Path $backup "files/$($entry.Id)"
        if ($entry.Original -and -not (Test-Entry $saved) -and (Test-Entry $entry.Target)) { continue }
        if (Test-Entry $entry.Target) {
            $item = Get-Item -LiteralPath $entry.Target -Force
            if ($item.PSIsContainer -or $item.LinkType -or (Get-FileHash -LiteralPath $entry.Target).Hash -ne $entry.Hash) {
                throw "Destination was changed after installation; preserve it manually first: $($entry.Target)"
            }
        }
        if ($entry.Original -and -not (Test-Entry $saved)) { throw "Original backup is missing: $saved" }
    }
    foreach ($entry in $entries) {
        $saved = Join-Path $backup "files/$($entry.Id)"
        if ($entry.Original -and -not (Test-Entry $saved)) { continue }
        if (Test-Entry $entry.Target) { Remove-Item -LiteralPath $entry.Target -Force }
        if ($entry.Original) {
            [IO.Directory]::CreateDirectory((Split-Path -Parent $entry.Target)) | Out-Null
            Move-Item -LiteralPath $saved -Destination $entry.Target
        }
        Write-Output "Restored: $($entry.Target)"
    }
    [IO.File]::WriteAllText((Join-Path $backup 'RESTORED'), '')
    return
}

if (-not $ConfigHome) {
    $ConfigHome = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $TargetHome '.config' }
}
if (-not $StateHome) {
    $StateHome = if ($env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { Join-Path $TargetHome '.local/state' }
}
if (-not $ProfilePath) { $ProfilePath = $PROFILE.CurrentUserCurrentHost }

$targets = @(
    @{ Source = 'config/powershell/profile.ps1'; Target = $ProfilePath },
    @{ Source = 'config/atuin/config.toml'; Target = Join-Path $ConfigHome 'atuin/config.toml' },
    @{ Source = 'config/git/config'; Target = Join-Path $ConfigHome 'git/config' }
)
foreach ($target in $targets) {
    $target.Source = Join-Path $PSScriptRoot $target.Source
    $target.Target = [IO.Path]::GetFullPath($target.Target)
    if (-not (Test-Path -LiteralPath $target.Source -PathType Leaf)) { throw "Source is missing: $($target.Source)" }
    if (Test-Entry $target.Target) {
        $item = Get-Item -LiteralPath $target.Target -Force
        if ($item.PSIsContainer -and -not $item.LinkType) { throw "Refusing to replace a directory: $($target.Target)" }
    }
}

$backup = $null
$entries = [Collections.Generic.List[object]]::new()
foreach ($target in $targets) {
    $hash = (Get-FileHash -LiteralPath $target.Source).Hash
    $original = Test-Entry $target.Target
    if ($original) {
        $item = Get-Item -LiteralPath $target.Target -Force
        if (-not $item.PSIsContainer -and -not $item.LinkType -and (Get-FileHash -LiteralPath $target.Target).Hash -eq $hash) {
            Write-Output "Already current: $($target.Target)"
            continue
        }
    }
    if (-not $Install) {
        if ($original) { Write-Output "Back up: $($target.Target)" }
        Write-Output "Copy: $($target.Source) -> $($target.Target)"
        continue
    }
    if (-not $backup) {
        $backup = Join-Path $StateHome ('dotfiles/backups/' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ') + '-' + [Guid]::NewGuid().ToString('N'))
        [IO.Directory]::CreateDirectory((Join-Path $backup 'files')) | Out-Null
        Write-Output "Backup: $backup"
    }
    $id = $entries.Count
    $entries.Add(@{ Id = $id; Target = $target.Target; Hash = $hash; Original = $original })
    ConvertTo-Json -InputObject @($entries.ToArray()) -Depth 4 | Set-Content -LiteralPath (Join-Path $backup 'manifest.json') -Encoding utf8
    if ($original) { Move-Item -LiteralPath $target.Target -Destination (Join-Path $backup "files/$id") }
    [IO.Directory]::CreateDirectory((Split-Path -Parent $target.Target)) | Out-Null
    Copy-Item -LiteralPath $target.Source -Destination $target.Target
    Write-Output "Copied: $($target.Target)"
}
if ($backup) { Write-Output "Undo: ./install.ps1 -Restore '$($backup.Replace("'", "''"))'" }
elseif (-not $Install) { Write-Output 'Preview only. Apply with: ./install.ps1 -Install' }
