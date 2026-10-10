# Installation

FModel MCP runs on **Windows x64**. Release packages are self-contained: they bundle the .NET 10 runtime,
so no separate .NET installation is needed. You do not need FModel, Unreal Editor or a GPU, although an
existing FModel setup can be imported (see [Configuration](configuration.md#saved-fmodel-profiles)).

- [Install a release](#install-a-release)
- [Connect your MCP client](#connect-your-mcp-client)
- [Verify the installation](#verify-the-installation)
- [Update and uninstall](#update-and-uninstall)
- [Build from source](#build-from-source)

## Install a release

1. Download `fmodel-mcp-<version>-win-x64.zip` and its `.sha256` file from the
   [releases page](https://github.com/plu1337/fmodel-mcp/releases/latest).
2. Optionally verify the download:

   ```powershell
   (Get-FileHash .\fmodel-mcp-<version>-win-x64.zip -Algorithm SHA256).Hash.ToLower()
   Get-Content .\fmodel-mcp-<version>-win-x64.zip.sha256
   ```

3. Extract the ZIP to any folder and run the installer from it:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Mcp.ps1 -SkipRegistration
   ```

The installer runs on the built-in Windows PowerShell 5.1. It:

- copies the package to `%LOCALAPPDATA%\FModelMcp\versions\<version>-<id>\`;
- creates `%LOCALAPPDATA%\FModelMcp\config.json` on first install, with an `Inputs` folder as the
  only allowed input and `Exports` as the output folder;
- imports your saved FModel profile automatically on first install, if
  `%APPDATA%\FModel\AppSettings.json` exists (paths only, never AES keys);
- smoke-tests the installed server before and after writing the configuration;
- writes `%LOCALAPPDATA%\FModelMcp\mcp-client.json` with the exact command and arguments for your client.

### Installer options

| Option | Effect |
| --- | --- |
| `-SkipRegistration` | Do not register with Codex. Use this for every other client. |
| `-InstallRoot <dir>` | Install somewhere other than `%LOCALAPPDATA%\FModelMcp`. |
| `-InputRoots <dir>,<dir>` | Absolute directories the server may read, such as game `Paks` folders and mapping folders. |
| `-OutputRoot <dir>` | Absolute directory for exports. |
| `-FModelSettingsPath <file>` | Import a specific FModel `AppSettings.json`. |
| `-ImportFModel` | Import the default FModel settings even when a configuration already exists. |
| `-CodexPath <file>` | Path to `codex.exe` when registering with Codex. |

Without `-SkipRegistration`, the installer registers the server with the Codex CLI and fails if it
cannot find Codex.

## Connect your MCP client

Every client needs the same two values from `%LOCALAPPDATA%\FModelMcp\mcp-client.json`:

- **command**: the full path to `FModel.Mcp.exe` inside `versions\<version>-<id>\`
- **args**: `["--config", "<install root>\config.json"]`

Print them with:

```powershell
(Get-Content "$env:LOCALAPPDATA\FModelMcp\mcp-client.json" -Raw | ConvertFrom-Json).mcpServers.fmodel
```

Ready-made templates are in [examples/clients](../examples/clients). Replace the placeholder paths with
your values, and use forward slashes or escaped backslashes (`\\`) inside JSON.

### Claude Code

```powershell
$s = (Get-Content "$env:LOCALAPPDATA\FModelMcp\mcp-client.json" -Raw | ConvertFrom-Json).mcpServers.fmodel
claude mcp add --transport stdio --scope user fmodel -- $s.command @($s.args)
claude mcp get fmodel
```

Use `--scope project` to write a shared `.mcp.json` instead
([template](../examples/clients/claude-code.mcp.json)). Inside Claude Code, `/mcp` shows the server status.

### Claude Desktop

Add the server to `%APPDATA%\Claude\claude_desktop_config.json`
([template](../examples/clients/claude-desktop.json)), then fully quit and restart Claude Desktop.
If the file already has an `mcpServers` object, add the `fmodel` entry to it rather than replacing it.

### VS Code

Add the server to `.vscode/mcp.json` in a workspace, or run **MCP: Open User Configuration** for all
workspaces ([template](../examples/clients/vscode-mcp.json)). VS Code uses a top-level `servers` key and
requires `"type": "stdio"`.

### Cursor

Add the server to `%USERPROFILE%\.cursor\mcp.json`, or to `.cursor/mcp.json` in a project
([template](../examples/clients/cursor-mcp.json)).

### Codex

Either let the installer register the server (omit `-SkipRegistration`), or add it to
`%USERPROFILE%\.codex\config.toml` ([template](../examples/clients/codex-config.toml)). In TOML, use
single-quoted strings so Windows backslashes are kept literally.

### Other clients

Any client that can launch a local stdio MCP server works. Configure it to run the `command` with the
`args` above. Do not point a client at `dotnet run` or a build script: build output is not MCP traffic.

## Verify the installation

After restarting your client, ask it to call `fmodel_capabilities`. The response lists the allowed input
roots, the output root, limits and whether Oodle is available.

To check the server without a client, run the bundled smoke test from the installed version folder:

```powershell
cd "$env:LOCALAPPDATA\FModelMcp\versions\<version>-<id>"
.\Smoke-Mcp.ps1 -ServerPath .\FModel.Mcp.exe -ConfigPath "$env:LOCALAPPDATA\FModelMcp\config.json"
```

Run directly, `FModel.Mcp.exe` waits silently for JSON-RPC on stdin. That is normal. `--help` prints usage.

## Update and uninstall

To update, extract the new release and run `Install-Mcp.ps1 -SkipRegistration` again. Each version goes
into its own `versions\` folder, so a running server is never overwritten, and your `config.json` is
kept unchanged unless you pass new paths. Because the executable path changes with each version,
**update your client configuration** with the new `command` from `mcp-client.json` (re-run the Claude
Code commands above after `claude mcp remove fmodel`), then restart the client. Old version folders can
be deleted once no client uses them.

To uninstall, remove the server from your client (for example `claude mcp remove fmodel`, or
`codex mcp remove fmodel`), then delete `%LOCALAPPDATA%\FModelMcp`. Check its `Exports` folder first if
you want to keep exported files.

## Build from source

Requirements: Windows x64, Git, the [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0),
and network access for the first build (it downloads the pinned CUE4Parse release and NuGet packages).

```powershell
git clone https://github.com/plu1337/fmodel-mcp.git
cd fmodel-mcp
.\setup.bat
```

`setup.bat` checks prerequisites, builds, runs the tests, publishes a package to
`artifacts\fmodel-mcp-<version>-win-x64\` with a ZIP and checksum, and tests the installer in an isolated
folder. Run `setup.bat -InstallPrerequisites` to be offered a `winget` install of missing Git or .NET
SDK. Setup asks before installing anything and never edits client configuration.

Then install the package you built:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\artifacts\fmodel-mcp-<version>-win-x64\Install-Mcp.ps1 -SkipRegistration
```

See [Development](development.md) for the individual build and test scripts.
