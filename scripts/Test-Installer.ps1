param([string]$PackagePath)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
$repoRoot = Get-RepositoryRoot
$testRoot = Join-Path $repoRoot ('artifacts/installer-test-' + [Guid]::NewGuid().ToString('N'))
if (!$PackagePath) {
    # Default to the newest published package for the current project version.
    $version = Get-ProjectVersion $repoRoot
    $latest = Get-ChildItem -LiteralPath (Join-Path $repoRoot 'artifacts') -Directory -Filter "fmodel-mcp-$version-win-x64*" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
    if (!$latest) { throw "No published package for $version under artifacts/. Run scripts/Publish-Mcp.ps1 first or pass -PackagePath." }
    $PackagePath = $latest.FullName
}
$package = [IO.Path]::GetFullPath($PackagePath)
$installer = Join-Path $package 'Install-Mcp.ps1'
New-Item -ItemType Directory -Path $testRoot | Out-Null
try {
    $gameRoot = Join-Path $testRoot 'fake-game'
    New-Item -ItemType Directory -Path $gameRoot | Out-Null
    $mappingRoot = Join-Path $testRoot '.data/mappings'
    New-Item -ItemType Directory -Path $mappingRoot -Force | Out-Null
    $savedSettings = Join-Path $testRoot 'FModelSettings.json'
    $fixtureKey = 'AB' * 32
    @{ GameDirectory = $gameRoot; OutputDirectory = $testRoot; PerDirectory = @{ $gameRoot = @{
        GameName = 'InstallerFixture'; GameDirectory = $gameRoot; UeVersion = 'GAME_UE5_8'; TexturePlatform = 0;
        AesKeys = @{ mainKey = $fixtureKey }; Endpoints = @(@{}, @{})
    } } } | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $savedSettings -Encoding utf8
    # Exercise the stock Windows PowerShell host, which end users can run without installing PowerShell 7.
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -PackagePath $package -InstallRoot $testRoot -FModelSettingsPath $savedSettings -SkipRegistration
    if ($LASTEXITCODE -ne 0) { throw 'Fresh installation failed.' }
    $stable = Join-Path $testRoot 'current'
    $stableExe = Join-Path $stable 'FModel.Mcp.exe'
    $clientPath = Join-Path $testRoot 'mcp-client.json'
    $firstClient = Get-Content -LiteralPath $clientPath -Raw
    if (($firstClient | ConvertFrom-Json).mcpServers.fmodel.command -ne $stableExe) { throw 'Client configuration does not use the stable current\ path.' }
    if (!((Get-Item -LiteralPath $stable -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw 'current\ is not a junction.' }
    $firstTarget = [IO.Path]::GetFullPath([string](Get-Item -LiteralPath $stable -Force).Target)
    $configPath = Join-Path $testRoot 'config.json'
    $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
    if (!(Test-Path -LiteralPath $config.inputRoots[0] -PathType Container)) { throw 'Default input folder was not created.' }
    if ($config.fmodelSettingsPath -ne $savedSettings -or $gameRoot -notin $config.inputRoots -or $mappingRoot -notin $config.inputRoots) { throw 'Saved FModel access settings were not imported.' }
    if ((Get-Content -LiteralPath $configPath -Raw).Contains($fixtureKey)) { throw 'Installer copied an AES key into MCP configuration.' }
    $config.maxSessions = 2
    $config | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $configPath -Encoding utf8
    $before = [IO.File]::ReadAllBytes($configPath)
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $installer -PackagePath $package -InstallRoot $testRoot -SkipRegistration
    if ($LASTEXITCODE -ne 0) { throw 'Update installation failed.' }
    if ([Convert]::ToBase64String($before) -ne [Convert]::ToBase64String([IO.File]::ReadAllBytes($configPath))) { throw 'Update changed existing settings.' }
    if ((Get-Content -LiteralPath $clientPath -Raw) -ne $firstClient) { throw 'Update changed the MCP client configuration; the command path must stay stable.' }
    if (!(Test-Path -LiteralPath $stableExe -PathType Leaf)) { throw 'Stable executable path does not resolve after update.' }
    $versions = @(Get-ChildItem -LiteralPath (Join-Path $testRoot 'versions') -Directory)
    if ($versions.Count -ne 2) { throw 'Update did not use a separate version directory.' }
    $secondTarget = [IO.Path]::GetFullPath([string](Get-Item -LiteralPath $stable -Force).Target)
    if ($secondTarget -eq $firstTarget) { throw 'Update did not re-point current\ to the new version.' }
    if ($secondTarget -notin @($versions | ForEach-Object { $_.FullName })) { throw 'current\ does not point to an installed version.' }
    if (!(Test-Path -LiteralPath (Join-Path $firstTarget 'FModel.Mcp.exe') -PathType Leaf)) { throw 'Re-pointing current\ damaged the previous version.' }
    Write-Host 'Installer checks passed: Windows PowerShell 5.1, saved-profile import without copying keys, configuration preservation, side-by-side update, stable current\ path unchanged across updates, previous version intact.'
} finally {
    $resolved = [IO.Path]::GetFullPath($testRoot)
    $allowed = [IO.Path]::GetFullPath((Join-Path $repoRoot 'artifacts')) + [IO.Path]::DirectorySeparatorChar
    if (!$resolved.StartsWith($allowed, [StringComparison]::OrdinalIgnoreCase)) { throw 'Refusing unsafe test cleanup.' }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
