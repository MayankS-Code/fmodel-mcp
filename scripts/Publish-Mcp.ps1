[CmdletBinding()]
param(
    [string]$PackagePath,
    [string]$OutputDirectory,
    # Bundled .NET runtime version. Defaults to the newest released patch for the target framework;
    # pass an exact version (e.g. 10.0.12) to reproduce an earlier build.
    [string]$RuntimeVersion,
    [switch]$SkipSmoke
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
Assert-WindowsX64
$repoRoot = Get-RepositoryRoot
$dotnet = Resolve-DotNet $repoRoot
$version = Get-ProjectVersion $repoRoot
if (!$RuntimeVersion) { $RuntimeVersion = Get-LatestDotNetRuntime $repoRoot }
if ($RuntimeVersion -notmatch '^\d+\.\d+\.\d+$') { throw "Invalid -RuntimeVersion '$RuntimeVersion'; expected a version such as 10.0.12." }
Write-Host "Bundling .NET runtime $RuntimeVersion"
if (!$PackagePath) { $PackagePath = Join-Path $repoRoot '.packages' }
$PackagePath = [IO.Path]::GetFullPath($PackagePath)
if (!$OutputDirectory) {
    $OutputDirectory = Get-UniquePath (Join-Path $repoRoot "artifacts/fmodel-mcp-$version-win-x64")
}
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$artifactsRoot = [IO.Path]::GetFullPath((Join-Path $repoRoot 'artifacts')) + [IO.Path]::DirectorySeparatorChar
if (!$OutputDirectory.StartsWith($artifactsRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Publish output must stay under the repository artifacts directory: $artifactsRoot"
}
if (Test-Path -LiteralPath $OutputDirectory) { throw "Publish output already exists; preserving it. Choose a new -OutputDirectory: $OutputDirectory" }
$project = Get-ServerProject $repoRoot
$created = $false
try {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
    $created = $true
    Invoke-DotNet $dotnet @('publish', $project, '-c', 'Release', '-r', 'win-x64', '--self-contained', 'true', '-o', $OutputDirectory,
        '-m:1', '-nr:false', '-p:CUE4PARSE_SKIP_NATIVE=true', "-p:RuntimeFrameworkVersion=$RuntimeVersion", '-p:DebugType=None', '-p:DebugSymbols=false', "-p:RestorePackagesPath=$PackagePath") 'Self-contained publish failed'
    $executable = Join-Path $OutputDirectory 'FModel.Mcp.exe'
    if (!(Test-Path -LiteralPath $executable -PathType Leaf)) { throw "Publish completed without the expected executable: $executable" }

    foreach ($name in @('Install-Mcp.ps1', 'Smoke-Mcp.ps1')) { Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination $OutputDirectory }
    foreach ($name in @('README.md', 'LICENSE', 'NOTICE', 'CHANGELOG.md', '.github/SECURITY.md')) {
        Copy-Item -LiteralPath (Join-Path $repoRoot $name) -Destination $OutputDirectory
    }
    foreach ($name in @('docs', 'examples')) { Copy-Item -LiteralPath (Join-Path $repoRoot $name) -Destination $OutputDirectory -Recurse -Force }
    & (Join-Path $PSScriptRoot 'Write-Notices.ps1') -PublishPath $OutputDirectory -PackagePath $PackagePath

    if (!$SkipSmoke) {
        & (Join-Path $PSScriptRoot 'Smoke-Mcp.ps1') -ServerPath $executable
    }

    $zipBase = Join-Path $repoRoot "artifacts/fmodel-mcp-$version-win-x64.zip"
    $zipPath = $zipBase
    for ($index = 2; (Test-Path -LiteralPath $zipPath) -or (Test-Path -LiteralPath ($zipPath + '.sha256')); $index++) {
        $zipPath = Join-Path $repoRoot "artifacts/fmodel-mcp-$version-win-x64-$index.zip"
    }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::CreateFromDirectory($OutputDirectory, $zipPath, [IO.Compression.CompressionLevel]::Optimal, $false)
    $hash = (Get-Sha256Checksum $zipPath).ToLowerInvariant()
    [IO.File]::WriteAllText(($zipPath + '.sha256'), "$hash  $([IO.Path]::GetFileName($zipPath))`n", [Text.UTF8Encoding]::new($false))
    Write-Host "Published self-contained Windows x64 executable (.NET runtime $RuntimeVersion): $executable"
    Write-Host "Release ZIP: $zipPath"
    Write-Host "SHA-256: $hash"
    Write-Output $OutputDirectory
} catch {
    if ($created -and (Test-Path -LiteralPath $OutputDirectory)) {
        $resolved = [IO.Path]::GetFullPath($OutputDirectory)
        if (!$resolved.StartsWith($artifactsRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing unsafe cleanup of failed publish output.' }
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
    throw
}
