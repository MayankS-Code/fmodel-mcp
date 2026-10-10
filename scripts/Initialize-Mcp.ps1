param()
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$dependencyRoot = Join-Path $repoRoot 'CUE4Parse'
$revision = 'ed9897a1a3a8dba84a4b6d2119846e0502d74f19'
$expectedHash = 'BE5FAC2BE22E56470D1EEA26267DAA6AEA54D176096F6EDCFE558E839FC2CBC1'

if (!(Test-Path -LiteralPath (Join-Path $dependencyRoot 'CUE4Parse/CUE4Parse.csproj'))) {
    if ((Test-Path -LiteralPath $dependencyRoot) -and (Get-ChildItem -LiteralPath $dependencyRoot -Force | Measure-Object).Count -gt 0) {
        throw 'CUE4Parse is nonempty but incomplete. Preserve that directory and restore the dependency manually; this script will not overwrite it.'
    }
    [IO.Directory]::CreateDirectory($dependencyRoot) | Out-Null
    $archivePath = Join-Path ([IO.Path]::GetTempPath()) ('fmodel-cue4parse-' + [Guid]::NewGuid().ToString('N') + '.zip')
    try {
        Write-Host "Downloading pinned CUE4Parse revision $revision"
        Invoke-WebRequest -Uri "https://codeload.github.com/FabianFG/CUE4Parse/zip/$revision" -OutFile $archivePath
        if ((Get-Sha256Checksum $archivePath) -ne $expectedHash) { throw 'CUE4Parse archive checksum mismatch.' }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [IO.Compression.ZipFile]::OpenRead($archivePath)
        try {
            foreach ($entry in $archive.Entries) {
                $parts = $entry.FullName.Split('/', 2)
                if ($parts.Count -lt 2 -or !$parts[1]) { continue }
                $destination = [IO.Path]::GetFullPath((Join-Path $dependencyRoot $parts[1]))
                if (!$destination.StartsWith($dependencyRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe archive entry.' }
                if ($entry.FullName.EndsWith('/')) { [IO.Directory]::CreateDirectory($destination) | Out-Null }
                else {
                    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
                    [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $destination, $false)
                }
            }
        } finally { $archive.Dispose() }
    } finally {
        if (Test-Path -LiteralPath $archivePath) { Remove-Item -LiteralPath $archivePath }
    }
}

# Idempotent host integrations and compatible .NET package patch pins. Existing changes are preserved.
function Add-SourceIntegration([string]$RelativePath, [string]$Marker, [string]$Anchor, [string]$Replacement) {
    $path = Join-Path $dependencyRoot $RelativePath
    $content = [IO.File]::ReadAllText($path).Replace("`r`n", "`n")
    if ($content.Contains($Marker)) { return }
    if (!$content.Contains($Anchor)) { throw "Unsupported CUE4Parse revision: expected source anchor missing in $RelativePath. Tested revision is $revision." }
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
