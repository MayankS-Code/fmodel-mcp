[CmdletBinding()]
param([string]$PackagePath)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
Assert-WindowsX64
$repoRoot = Get-RepositoryRoot
$dotnet = Resolve-DotNet $repoRoot
$solution = Join-Path $repoRoot 'FModel.Mcp.slnx'
if (!$PackagePath) { $PackagePath = Join-Path $repoRoot '.packages' }
$PackagePath = [IO.Path]::GetFullPath($PackagePath)
if (!(Test-Path -LiteralPath $solution -PathType Leaf)) { throw "Solution not found: $solution" }

& (Join-Path $PSScriptRoot 'Initialize-Mcp.ps1')

Invoke-DotNet $dotnet @('restore', $solution, '--packages', $PackagePath, '-p:CUE4PARSE_SKIP_NATIVE=true') 'Dependency restore failed'
Invoke-DotNet $dotnet @('build', $solution, '--no-restore', '-c', 'Release', '-m:1', '-nr:false', '-p:CUE4PARSE_SKIP_NATIVE=true', '-clp:ErrorsOnly') 'Release build failed'
Write-Host "Release build succeeded for FModel MCP $(Get-ProjectVersion $repoRoot)."
Write-Host "NuGet package cache: $PackagePath"
