Set-StrictMode -Version Latest

function Get-RepositoryRoot {
    return [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}

function Assert-WindowsX64 {
    if ([Environment]::OSVersion.Platform -ne 'Win32NT' -or ![Environment]::Is64BitOperatingSystem) {
        throw 'FModel MCP release scripts require 64-bit Windows.'
    }
}

function Resolve-DotNet([string]$RepositoryRoot) {
    $candidates = @()
    $local = Join-Path $RepositoryRoot '.dotnet/dotnet.exe'
    if (Test-Path -LiteralPath $local -PathType Leaf) { $candidates += $local }
    $system = Get-Command dotnet.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($system) { $candidates += $system.Source }

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        try {
            $prevEAP = $ErrorActionPreference
            $ErrorActionPreference = 'SilentlyContinue'
            $versionOutput = cmd.exe /c "`"$candidate`" --version 2>NUL"
            $ErrorActionPreference = $prevEAP
            if ($LASTEXITCODE -eq 0 -and "$versionOutput" -match '^10\.') { return $candidate }
        } catch { }
    }
    throw 'The .NET 10 SDK was not found. Install the .NET 10 SDK from https://dotnet.microsoft.com/download/dotnet/10.0 and reopen PowerShell.'
}

function Invoke-DotNet([string]$DotNetPath, [string[]]$Arguments, [string]$FailureMessage) {
    & $DotNetPath @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$FailureMessage (dotnet exit code $LASTEXITCODE)." }
}

# Repository layout: the only place project locations are defined for the build scripts.
function Get-ServerProjectDir([string]$RepositoryRoot) { return Join-Path $RepositoryRoot 'src/FModel.Mcp' }
function Get-ServerProject([string]$RepositoryRoot) { return Join-Path (Get-ServerProjectDir $RepositoryRoot) 'FModel.Mcp.csproj' }
function Get-ServerBuildExe([string]$RepositoryRoot) { return Join-Path (Get-ServerProjectDir $RepositoryRoot) 'bin/Release/net10.0/FModel.Mcp.exe' }
function Get-TestProjectDir([string]$RepositoryRoot) { return Join-Path $RepositoryRoot 'tests/FModel.Mcp.Tests' }

function Get-ProjectVersion([string]$RepositoryRoot) {
    [xml]$project = Get-Content -LiteralPath (Get-ServerProject $RepositoryRoot) -Raw
    return [string]$project.Project.PropertyGroup.Version
}

function Get-UniquePath([string]$BasePath) {
    if (!(Test-Path -LiteralPath $BasePath)) { return $BasePath }
    for ($index = 2; $index -lt 1000; $index++) {
        $candidate = "$BasePath-$index"
        if (!(Test-Path -LiteralPath $candidate)) { return $candidate }
    }
    throw "Could not allocate a new output path beside $BasePath."
}

function Get-Sha256Checksum([string]$FilePath) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $stream = [IO.File]::OpenRead($FilePath)
        try {
            $bytes = $sha.ComputeHash($stream)
            return ([BitConverter]::ToString($bytes)).Replace('-', '')
        } finally { $stream.Dispose() }
    } finally { $sha.Dispose() }
}
