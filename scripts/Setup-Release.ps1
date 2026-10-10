#Requires -Version 5.1
[CmdletBinding()]
param([switch]$InstallPrerequisites)
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
. (Join-Path $PSScriptRoot 'Common.ps1')
if ([Environment]::OSVersion.Platform -ne 'Win32NT' -or ![Environment]::Is64BitOperatingSystem) { throw 'Setup requires Windows x64.' }
if ($PSVersionTable.PSVersion -lt [Version]'5.1') { throw 'Windows PowerShell 5.1 or later is required.' }

function Offer-WingetInstall([string]$PackageId, [string]$Name) {
    $winget = Get-Command winget.exe -CommandType Application -ErrorAction SilentlyContinue
    if (!$winget) { throw "$Name is missing and winget is unavailable. Install it from the official vendor site, then rerun setup." }
    $answer = Read-Host "Install $Name with winget now? [y/N]"
    if ($answer -notmatch '^(y|yes)$') { throw "Install $Name and rerun setup, or choose the explicit prerequisite-install option." }
    & $winget.Source install --id $PackageId --exact --source winget
    if ($LASTEXITCODE -ne 0) { throw "winget failed to install $Name (exit code $LASTEXITCODE)." }
}

if (!(Get-Command git.exe -CommandType Application -ErrorAction SilentlyContinue)) {
    if (!$InstallPrerequisites) { throw 'Git is required for the pinned CUE4Parse source. Install Git from https://git-scm.com/download/win, then rerun setup.' }
    Offer-WingetInstall 'Git.Git' 'Git for Windows'
}
$localDotnet = Join-Path $root '.dotnet/dotnet.exe'
$systemDotnet = Get-Command dotnet.exe -CommandType Application -ErrorAction SilentlyContinue
$sdk = $false
foreach ($candidate in @($(if (Test-Path -LiteralPath $localDotnet) { $localDotnet }), $(if ($systemDotnet) { $systemDotnet.Source }))) {
    if ($candidate) {
        $version = cmd.exe /c "`"$candidate`" --version 2>NUL"
        if ($LASTEXITCODE -eq 0 -and "$version" -match '^10\.') { $sdk = $true; break }
    }
}
if (!$sdk) {
    if (!$InstallPrerequisites) { throw 'The .NET 10 SDK is required. Install it from https://dotnet.microsoft.com/download/dotnet/10.0, or rerun setup.bat -InstallPrerequisites to offer a winget install.' }
    Offer-WingetInstall 'Microsoft.DotNet.SDK.10' '.NET 10 SDK'
}

& (Join-Path $PSScriptRoot 'Build-Mcp.ps1')
& (Join-Path $PSScriptRoot 'Test-Mcp.ps1')
$publishOutput = Join-Path $root ('artifacts/fmodel-mcp-' + ([xml](Get-Content (Join-Path $root 'FModel.Mcp/FModel.Mcp.csproj') -Raw)).Project.PropertyGroup.Version + '-win-x64')
$publishOutput = Get-UniquePath $publishOutput
& (Join-Path $PSScriptRoot 'Publish-Mcp.ps1') -OutputDirectory $publishOutput
& (Join-Path $PSScriptRoot 'Test-Installer.ps1') -PackagePath $publishOutput
$exe = Join-Path $publishOutput 'FModel.Mcp.exe'
Write-Host ''
Write-Host 'Release verification completed.'
Write-Host "Executable: $exe"
Write-Host 'Codex MCP server entry (replace the example install/config paths with your chosen local paths):'
Write-Host '[mcp_servers.fmodel]'
Write-Host ('command = ''' + $exe + '''')
Write-Host "args = ['--config', 'C:\Users\<you>\AppData\Local\FModelMcp\config.json']"
Write-Host 'The published app is self-contained for Windows x64 and bundles the .NET runtime.'
