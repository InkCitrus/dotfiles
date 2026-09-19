#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-test-' + [Guid]::NewGuid().ToString('N'))
$testHome = Join-Path $fixture 'home with spaces'
$configHome = Join-Path $testHome 'config with spaces'
$stateHome = Join-Path $testHome 'state with spaces'
$testProfile = Join-Path $testHome 'Documents/PowerShell/Microsoft.PowerShell_profile.ps1'
$options = @{ TargetHome = $testHome; ConfigHome = $configHome; StateHome = $stateHome; ProfilePath = $testProfile }
function Assert([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
try {
    [IO.Directory]::CreateDirectory((Split-Path -Parent $testProfile)) | Out-Null
    [IO.File]::WriteAllText($testProfile, '# Original profile: 原配置' + "`r`n")
    $originalHash = (Get-FileHash -LiteralPath $testProfile).Hash
    & "$repo/install.ps1" @options -DryRun | Out-Null
    Assert (-not (Test-Path -LiteralPath $stateHome)) 'Preview wrote state files.'
    Assert ((Get-FileHash -LiteralPath $testProfile).Hash -eq $originalHash) 'Preview changed the profile.'

    & "$repo/install.ps1" @options -Install | Out-Null
    $backups = @(Get-ChildItem -LiteralPath (Join-Path $stateHome 'dotfiles/backups') -Directory)
    Assert ($backups.Count -eq 1) 'Expected one backup.'
    $backup = $backups[0].FullName
    $installedHash = (Get-FileHash -LiteralPath $testProfile).Hash
    Assert ($installedHash -eq (Get-FileHash -LiteralPath "$repo/config/powershell/profile.ps1").Hash) 'Profile differs from source.'
    & "$repo/install.ps1" @options -Install | Out-Null
    Assert (@(Get-ChildItem -LiteralPath (Join-Path $stateHome 'dotfiles/backups') -Directory).Count -eq 1) 'Repeat install created a backup.'

    Add-Content -LiteralPath $testProfile -Value '# Later edit'
    $refused = $false
    try { & "$repo/install.ps1" -Restore $backup | Out-Null } catch { $refused = $true }
    Assert $refused 'Restore erased a changed file.'
    Assert (Test-Path -LiteralPath (Join-Path $configHome 'atuin/config.toml')) 'Conflict caused a partial restore.'
    Copy-Item -LiteralPath "$repo/config/powershell/profile.ps1" -Destination $testProfile -Force
    & "$repo/install.ps1" -Restore $backup | Out-Null
    Assert ((Get-FileHash -LiteralPath $testProfile).Hash -eq $originalHash) 'Original profile was not restored byte-for-byte.'
    Assert (-not (Test-Path -LiteralPath (Join-Path $configHome 'atuin/config.toml'))) 'New config was not removed.'
    Assert (Test-Path -LiteralPath (Join-Path $backup 'RESTORED')) 'Restore marker missing.'

    foreach ($file in @(Get-ChildItem -LiteralPath $repo -Filter '*.ps1' -Recurse)) {
        $tokens = $null
        $parseErrors = $null
        [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
        Assert ($parseErrors.Count -eq 0) "PowerShell parse error: $($file.FullName) $parseErrors"
    }
    Write-Output 'PASS: preview, installation, idempotence, conflict protection, restore, custom paths, and PowerShell syntax'
} finally {
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}
