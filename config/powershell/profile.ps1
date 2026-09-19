# PowerShell 7+. A copy is installed at $PROFILE.CurrentUserCurrentHost.
if (-not $env:XDG_CONFIG_HOME) {
    $env:XDG_CONFIG_HOME = Join-Path $HOME '.config'
}
# Atuin uses the same TOML on every platform; keep its database and login local.
if (-not $env:ATUIN_CONFIG_DIR) {
    $env:ATUIN_CONFIG_DIR = Join-Path $env:XDG_CONFIG_HOME 'atuin'
}

if (Get-Module -ListAvailable PSReadLine) {
    Import-Module PSReadLine
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

if (Get-Command atuin -CommandType Application -ErrorAction SilentlyContinue) {
    $atuinInit = & atuin init powershell --disable-up-arrow --disable-ai 2>$null
    if ($LASTEXITCODE -ne 0) {
        $atuinInit = & atuin init powershell --disable-up-arrow 2>$null
    }
    if ($LASTEXITCODE -eq 0 -and $atuinInit) {
        $atuinInit | Out-String | Invoke-Expression
    }
    Remove-Variable atuinInit -ErrorAction SilentlyContinue
}

if (Get-Command starship -CommandType Application -ErrorAction SilentlyContinue) {
    & starship init powershell | Out-String | Invoke-Expression
}

$dotfilesLocal = Join-Path $env:XDG_CONFIG_HOME 'powershell/profile.local.ps1'
if (Test-Path -LiteralPath $dotfilesLocal -PathType Leaf) {
    . $dotfilesLocal
}
Remove-Variable dotfilesLocal
