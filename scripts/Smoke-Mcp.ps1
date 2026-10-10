# Protocol smoke test over stdio using the 2025-11-25 initialize handshake (the unit tests cover 2026-07-28).
# -OpenSavedGame mounts the configured FModel saved profile; -AssetQuery additionally finds and inspects one
# .uasset matching the given name in that profile. Asset paths and values are never printed.
param([string]$ServerPath, [string]$ConfigPath, [switch]$OpenSavedGame, [string]$AssetQuery, [int]$ResponseTimeoutSeconds = 180)
if ($AssetQuery -and !$OpenSavedGame) { throw '-AssetQuery requires -OpenSavedGame.' }
$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
# Standalone (also shipped in release packages, without Common.ps1): default to a source-tree Release build.
if (!$ServerPath) { $ServerPath = Join-Path $repoRoot 'src/FModel.Mcp/bin/Release/net10.0/FModel.Mcp.exe' }
$info = [Diagnostics.ProcessStartInfo]::new()
$info.FileName = [IO.Path]::GetFullPath($ServerPath)
if ($ConfigPath) { $info.Arguments = '--config "' + [IO.Path]::GetFullPath($ConfigPath) + '"' }
$info.WorkingDirectory = $repoRoot
$info.UseShellExecute = $false
$info.CreateNoWindow = $true
$info.RedirectStandardInput = $true
$info.RedirectStandardOutput = $true
$info.RedirectStandardError = $true
$process = [Diagnostics.Process]::Start($info)
$errors = $process.StandardError.ReadToEndAsync()
function Send-Rpc([hashtable]$Message) {
    $process.StandardInput.WriteLine(($Message | ConvertTo-Json -Depth 30 -Compress))
    $process.StandardInput.Flush()
    if (!$Message.ContainsKey('id')) { return }
    $deadline = [DateTime]::UtcNow.AddSeconds($ResponseTimeoutSeconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        $line = $process.StandardOutput.ReadLineAsync()
        if (!$line.Wait($ResponseTimeoutSeconds * 1000)) { throw "Timed out awaiting MCP response to $($Message.method)." }
        if ($null -eq $line.Result) { throw "MCP stdout closed unexpectedly: $($errors.GetAwaiter().GetResult())" }
        $response = $line.Result | ConvertFrom-Json
        if ($response.id -eq $Message.id) {
            $errorProperty = $response.PSObject.Properties['error']
            if ($errorProperty -and $errorProperty.Value) { throw ($errorProperty.Value | ConvertTo-Json -Compress) }
            return $response.result
        }
    }
    throw 'No matching MCP response.'
}
try {
    $initialized = Send-Rpc @{ jsonrpc = '2.0'; id = 1; method = 'initialize'; params = @{ protocolVersion = '2025-11-25'; capabilities = @{}; clientInfo = @{ name = 'fmodel-smoke'; version = '1.0' } } }
    Send-Rpc @{ jsonrpc = '2.0'; method = 'notifications/initialized' }
    $tools = Send-Rpc @{ jsonrpc = '2.0'; id = 2; method = 'tools/list'; params = @{} }
    if ($tools.tools.Count -ne 34) { throw "Expected 34 tools; found $($tools.tools.Count)." }
    $capabilities = Send-Rpc @{ jsonrpc = '2.0'; id = 3; method = 'tools/call'; params = @{ name = 'fmodel_capabilities'; arguments = @{} } }
    if ($capabilities.isError) { throw 'Capabilities call failed.' }
    $resources = Send-Rpc @{ jsonrpc = '2.0'; id = 4; method = 'resources/list'; params = @{} }
    $prompts = Send-Rpc @{ jsonrpc = '2.0'; id = 5; method = 'prompts/list'; params = @{} }
    if ($resources.resources.Count -lt 2 -or $prompts.prompts.Count -ne 4) { throw 'Missing resources or prompts.' }
    if ($OpenSavedGame) {
        $saved = Send-Rpc @{ jsonrpc = '2.0'; id = 6; method = 'tools/call'; params = @{ name = 'fmodel_list_saved_games'; arguments = @{} } }
        if ($saved.isError) { throw 'Saved-game listing failed; details suppressed to avoid printing local profile paths.' }
        $savedGames = $saved.content[0].text | ConvertFrom-Json
        $opened = Send-Rpc @{ jsonrpc = '2.0'; id = 7; method = 'tools/call'; params = @{ name = 'fmodel_open_saved_game'; arguments = @{} } }
        if ($opened.isError) { throw 'Opening the saved profile failed; details suppressed to avoid printing local profile information.' }
        $session = $opened.content[0].text | ConvertFrom-Json
        if ($session.fileCount -lt 1) { throw 'Saved game mounted no files.' }
        $search = Send-Rpc @{ jsonrpc = '2.0'; id = 8; method = 'tools/call'; params = @{ name = 'fmodel_search_assets'; arguments = @{ sessionId = $session.sessionId; query = 'DefaultGame.ini'; limit = 1 } } }
        if ($search.isError) { throw 'Mounted-asset search failed.' }
        $found = $search.content[0].text | ConvertFrom-Json
        if ($found.items.Count -gt 0) {
            $read = Send-Rpc @{ jsonrpc = '2.0'; id = 9; method = 'tools/call'; params = @{ name = 'fmodel_read_file'; arguments = @{ sessionId = $session.sessionId; path = $found.items[0].path; count = 512 } } }
            if ($read.isError) { throw 'Bounded read from a mounted file failed.' }
        }
        if ($AssetQuery) {
            $assetSearch = Send-Rpc @{ jsonrpc = '2.0'; id = 11; method = 'tools/call'; params = @{ name = 'fmodel_search_assets'; arguments = @{ sessionId = $session.sessionId; query = $AssetQuery; limit = 10; offset = 0 } } }
            if ($assetSearch.isError) { throw 'Asset search failed.' }
            $assetResult = $assetSearch.content[0].text | ConvertFrom-Json
            $package = @($assetResult.items | Where-Object { $_.extension -eq 'uasset' } | Select-Object -First 1)[0]
            if (!$package) { throw 'Saved profile mounted successfully, but no .uasset matched -AssetQuery.' }
            $inspection = Send-Rpc @{ jsonrpc = '2.0'; id = 12; method = 'tools/call'; params = @{ name = 'fmodel_inspect_package'; arguments = @{ sessionId = $session.sessionId; path = $package.path; section = 'summary'; offset = 0; limit = 20 } } }
            if ($inspection.isError) { throw 'Package inspection failed.' }
            $properties = Send-Rpc @{ jsonrpc = '2.0'; id = 13; method = 'tools/call'; params = @{ name = 'fmodel_get_properties'; arguments = @{ sessionId = $session.sessionId; path = $package.path; exportIndex = 0; offset = 0; limit = 30 } } }
            if ($properties.isError) { throw 'Property inspection failed.' }
            Write-Host 'Asset smoke passed: package search, package summary, and property inspection returned successfully; asset paths and values suppressed.'
        }
        $closed = Send-Rpc @{ jsonrpc = '2.0'; id = 10; method = 'tools/call'; params = @{ name = 'fmodel_close_game'; arguments = @{ sessionId = $session.sessionId } } }
        if ($closed.isError) { throw ($closed.content[0].text) }
        Write-Host "Saved-profile smoke passed: $(@($savedGames).Count) saved profiles discovered; one profile mounted $($session.fileCount) files; bounded search/read completed. No profile paths or identifiers printed."
    }
    $process.StandardInput.Close()
    if (!$process.WaitForExit(10000)) { throw 'MCP process did not exit after stdin closed.' }
    if ($process.ExitCode -ne 0) { throw "MCP exited with code $($process.ExitCode): $($errors.GetAwaiter().GetResult())" }
    Write-Host "MCP smoke passed: $($initialized.serverInfo.name), protocol $($initialized.protocolVersion), 34 tools, 4 prompts, resources, clean stdout and graceful EOF."
} finally {
    if (!$process.HasExited) { $process.Kill(); $process.WaitForExit(5000) | Out-Null }
    $process.Dispose()
}
