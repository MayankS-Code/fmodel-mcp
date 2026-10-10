param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
$repoRoot = Get-RepositoryRoot
$dependencyRoot = Join-Path $repoRoot 'CUE4Parse'

# CUE4Parse is a git submodule pinned to a release tag (see .gitmodules and docs/development.md).
if (!(Test-Path -LiteralPath (Join-Path $dependencyRoot 'CUE4Parse/CUE4Parse.csproj'))) {
    if (!(Test-Path -LiteralPath (Join-Path $repoRoot '.git'))) {
        throw 'CUE4Parse is missing. GitHub "Download ZIP" archives do not include submodules: clone the repository with Git instead, or use the source ZIP from a GitHub release.'
    }
    Write-Host 'Initializing the CUE4Parse submodule'
    & git -C $repoRoot submodule update --init -- CUE4Parse
    if ($LASTEXITCODE -ne 0) { throw 'git submodule update failed. Check network access, then rerun.' }
}
$revision = if (Test-Path -LiteralPath (Join-Path $dependencyRoot '.git')) { (& git -C $dependencyRoot rev-parse HEAD) } else { 'from source bundle' }

# Idempotent host integrations and compatible .NET package patch pins. Existing changes are preserved.
function Add-SourceIntegration([string]$RelativePath, [string]$Marker, [string]$Anchor, [string]$Replacement) {
    $path = Join-Path $dependencyRoot $RelativePath
    $content = [IO.File]::ReadAllText($path).Replace("`r`n", "`n")
    if ($content.Contains($Marker)) { return }
    if (!$content.Contains($Anchor)) { throw "Unsupported CUE4Parse revision ($revision): expected source anchor missing in $RelativePath. Run 'git submodule update --init' to restore the pinned release." }
    [IO.File]::WriteAllText($path, $content.Replace($Anchor, $Replacement), [Text.UTF8Encoding]::new($false))
}
$sessionPath = 'CUE4Parse-Conversion/ExportSession.cs'
$anchor = '    public int MaxDegreeOfParallelism { get; init; } = Environment.ProcessorCount;'
Add-SourceIntegration $sessionPath 'public Func<string, string>? OutputPathValidator' $anchor ($anchor + "`n`n    // Hosts can constrain every output, including automatically queued dependencies.`n    public Func<string, string>? OutputPathValidator { get; init; }")
$anchor = "        var fullPath = Path.Combine(BaseDirectory.FullName, savePath) + nameSuffix + '.' + ext.ToLower();"
Add-SourceIntegration $sessionPath 'OutputPathValidator?.Invoke(fullPath)' $anchor ($anchor + "`n        fullPath = OutputPathValidator?.Invoke(fullPath) ?? fullPath;")
Add-SourceIntegration 'CUE4Parse/CUE4Parse.csproj' 'Include="Microsoft.Bcl.Memory"' '    <PackageReference Include="Newtonsoft.Json" />' "    <PackageReference Include=`"Newtonsoft.Json`" />`n    <PackageReference Include=`"Microsoft.Bcl.Memory`" />"
Add-SourceIntegration 'Directory.Packages.props' 'Microsoft.Bcl.Memory" Version="10.0.12' "  </PropertyGroup>`n  <ItemGroup>`n" "  </PropertyGroup>`n  <ItemGroup>`n    <PackageVersion Include=`"Microsoft.Bcl.Memory`" Version=`"10.0.12`" />`n"
Add-SourceIntegration 'Directory.Packages.props' 'System.IO.Hashing" Version="10.0.12' '    <PackageVersion Include="System.IO.Hashing" Version="10.0.8" />' '    <PackageVersion Include="System.IO.Hashing" Version="10.0.12" />'
Add-SourceIntegration 'Directory.Packages.props' 'System.Numerics.Tensors" Version="10.0.12' '    <PackageVersion Include="System.Numerics.Tensors" Version="10.0.10" />' '    <PackageVersion Include="System.Numerics.Tensors" Version="10.0.12" />'
Write-Host 'CUE4Parse MCP integrations are ready.'
