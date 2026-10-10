[CmdletBinding()]
param(
    [string]$ServerPath,
    [string]$ConfigPath,
    [switch]$OpenSavedGame,
    [string]$AssetQuery
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
Assert-WindowsX64
$repoRoot = Get-RepositoryRoot
$dotnet = Resolve-DotNet $repoRoot
$testProject = Join-Path $repoRoot 'FModel.Mcp.Tests/FModel.Mcp.Tests.csproj'
Invoke-DotNet $dotnet @('build', $testProject, '--no-restore', '-c', 'Release', '-m:1', '-nr:false', '-p:CUE4PARSE_SKIP_NATIVE=true', '-clp:ErrorsOnly') 'Test project build failed'
$testExecutable = Join-Path $repoRoot 'FModel.Mcp.Tests/bin/Release/net10.0/FModel.Mcp.Tests.exe'
if (!(Test-Path -LiteralPath $testExecutable -PathType Leaf)) { throw "xUnit executable was not produced: $testExecutable" }
& $testExecutable
if ($LASTEXITCODE -ne 0) { throw "Test suite failed (exit code $LASTEXITCODE)." }
if (!$ServerPath) { $ServerPath = Join-Path $repoRoot 'FModel.Mcp/bin/Release/net10.0/FModel.Mcp.exe' }
$ServerPath = [IO.Path]::GetFullPath($ServerPath)
if (!(Test-Path -LiteralPath $ServerPath -PathType Leaf)) { throw "MCP executable not found for smoke testing: $ServerPath. Build or publish first." }
$smokeArgs = @{ ServerPath = $ServerPath }
if ($ConfigPath) { $smokeArgs.ConfigPath = [IO.Path]::GetFullPath($ConfigPath) }
if ($OpenSavedGame) { $smokeArgs.OpenSavedGame = $true }
if ($AssetQuery) { $smokeArgs.AssetQuery = $AssetQuery }
& (Join-Path $PSScriptRoot 'Smoke-Mcp.ps1') @smokeArgs
Write-Host 'Tests and MCP protocol smoke test passed.'
