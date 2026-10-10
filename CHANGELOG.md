# Changelog

## 1.2.0

> This release is a modified and updated version of [plu1337/fmodel-mcp](https://github.com/plu1337/fmodel-mcp)
> by [plu1337](https://github.com/plu1337), the original author of FModel MCP (versions up to 1.1.1).

FModel MCP lets AI assistants explore Unreal Engine game archives through the Model Context Protocol:
open PAK/IoStore archives, browse and search assets, inspect packages and properties, preview textures,
decompile Blueprints to pseudocode, and export textures, meshes, animations, audio and worlds. It works
with Claude Desktop, Claude Code, VS Code, Cursor, Codex and any other MCP client.

### Install

1. Download `fmodel-mcp-1.2.0-win-x64.zip` below and extract it. The .NET runtime is included.
2. In the extracted folder, run
   `powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Mcp.ps1 -SkipRegistration`.
3. Add the server to your MCP client: see the
   [installation guide](https://github.com/MayankS-Code/fmodel-mcp/blob/main/docs/installation.md#connect-your-mcp-client).

Requires Windows x64. Verify the download against `fmodel-mcp-1.2.0-win-x64.zip.sha256`.

### Highlights

- **Stable executable path.** Clients now launch `%LOCALAPPDATA%\FModelMcp\current\FModel.Mcp.exe`,
  which always points to the newest installed version. Updating is just "run the installer, restart the
  client"; an update never disturbs a server that is running.
- **Latest parser.** CUE4Parse release `1.2.2.202610`, including USMAP v5 mapping support.
- **Current MCP protocol.** Verified with protocol revision 2026-07-28, while still supporting
  2025-11-25 clients.
- **Setup for every major client.** Step-by-step guides and ready-made configuration templates for
  Claude Desktop, Claude Code, VS Code, Cursor and Codex.

### Changes

- The installer prints the exact client command and arguments, with a link to setup instructions for
  any MCP client.
- New documentation: installation, configuration, tool reference for all 34 tools, troubleshooting,
  security, development and releasing guides.
- The reported server version now always matches the release.
- Updated .NET hosting and test dependencies.

### Fixes

- Building from a clean checkout no longer fails while preparing the CUE4Parse dependency.
- The release pipeline now runs the full test suite and installer checks before publishing.

### Upgrading from 1.1.1

Run the new installer. Then change your MCP client's `command` **once** to
`%LOCALAPPDATA%\FModelMcp\current\FModel.Mcp.exe` (see
[Update and uninstall](https://github.com/MayankS-Code/fmodel-mcp/blob/main/docs/installation.md#update-and-uninstall)).
Future updates need no client changes. Your `config.json` is kept.

### Known issues

- Release files are not code-signed, so Windows SmartScreen may warn on first run.
- A CUE4Parse dependency (ImageSharp 3.1.12) has published advisories; exposure is limited and explained
  in the [security guide](https://github.com/MayankS-Code/fmodel-mcp/blob/main/docs/security.md#known-dependency-advisories).

### Files

| File | Contents |
| --- | --- |
| `fmodel-mcp-1.2.0-win-x64.zip` | Self-contained Windows x64 server, installer, documentation and licenses |
| `fmodel-mcp-1.2.0-source.zip` | Complete source including the pinned CUE4Parse release (builds without Git) |
| `*.sha256` | SHA-256 checksums |

## 1.1.1

Released by plu1337 in the original repository, [plu1337/fmodel-mcp](https://github.com/plu1337/fmodel-mcp).

- Fixed inline texture previews sending raw PNG bytes where MCP requires base64 text. Images now display correctly in MCP clients.
- Added a regression test that opens a real Unreal texture through the official stdio MCP client and validates the received PNG encoding and dimensions.
- Full-resolution texture file exports and saved FModel profile integration remain available.
