# FModel MCP

[![Build and test](https://github.com/plu1337/fmodel-mcp/actions/workflows/build.yml/badge.svg)](https://github.com/plu1337/fmodel-mcp/actions/workflows/build.yml)
[![Latest release](https://img.shields.io/github/v/release/plu1337/fmodel-mcp)](https://github.com/plu1337/fmodel-mcp/releases/latest)
[![License: GPL-3.0-or-later](https://img.shields.io/badge/license-GPL--3.0--or--later-blue)](LICENSE)

A local [Model Context Protocol](https://modelcontextprotocol.io/) server that lets AI assistants explore
Unreal Engine game archives. It wraps the [CUE4Parse](https://github.com/FabianFG/CUE4Parse) parser
behind **34 tools**: open PAK/IoStore archives, browse and search assets, inspect packages, properties and
references, preview textures, decompile Blueprints to pseudocode, and export textures, meshes, animations,
audio and worlds.

It runs over stdio on Windows x64 and works with any MCP client, including Claude Desktop, Claude Code,
VS Code, Cursor and Codex. Game archives are only read, never modified.

## Quick start

1. Download `fmodel-mcp-<version>-win-x64.zip` from the
   [latest release](https://github.com/plu1337/fmodel-mcp/releases/latest) and extract it. The package
   bundles the .NET runtime, so nothing else needs to be installed.
2. In the extracted folder, run:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Mcp.ps1 -SkipRegistration
   ```

   This installs to `%LOCALAPPDATA%\FModelMcp`, creates `config.json`, imports your saved FModel game
   profile if one exists, and writes a ready-to-use `mcp-client.json`.
3. Register the server with your MCP client. `mcp-client.json` already contains the exact command and
   arguments. For Claude Code:

   ```powershell
   $s = (Get-Content "$env:LOCALAPPDATA\FModelMcp\mcp-client.json" -Raw | ConvertFrom-Json).mcpServers.fmodel
   claude mcp add --transport stdio --scope user fmodel -- $s.command @($s.args)
   ```

   For Claude Desktop, VS Code, Cursor and Codex, see [Installation](docs/installation.md#connect-your-mcp-client)
   and [examples/clients](examples/clients).
4. Restart the client and ask it to open a game, for example: *"List my saved FModel games and open the
   selected one."*

## Documentation

| Guide | Contents |
| --- | --- |
| [Installation](docs/installation.md) | Release install, client setup, updating and uninstalling, building from source |
| [Configuration](docs/configuration.md) | `config.json` fields, limits, saved FModel profiles, Oodle and native codecs |
| [Tool reference](docs/tools.md) | All 34 tools, export options, resources, prompts and the recommended AI workflow |
| [Troubleshooting](docs/troubleshooting.md) | Startup, mounting, mappings, export and client problems |
| [Security](docs/security.md) | Trust model, key handling, known dependency advisories, reporting |
| [Development](docs/development.md) | Building, testing, dependency updates and contributing |
| [Releasing](docs/releasing.md) | How versions are tagged, built and published |
| [Architecture](docs/architecture.md) | Design and coverage compared with the FModel desktop app |
| [Dependencies](docs/dependencies.md) | Pinned versions, licenses and compatibility notes |

Changes are listed in [CHANGELOG.md](CHANGELOG.md). Contributions are welcome; see
[CONTRIBUTING.md](.github/CONTRIBUTING.md).

## Compatibility

| Component | Version |
| --- | --- |
| Platform | Windows x64 |
| MCP protocol | 2026-07-28, with support for 2025-11-25 clients |
| CUE4Parse | `1.2.2.202610` release |
| .NET | 10 (runtime bundled in releases) |

Whether a particular game opens depends on its engine profile, mappings, AES keys and codecs, which you
supply locally. See [Configuration](docs/configuration.md).

## Responsible use

This project is not affiliated with or endorsed by Epic Games, the FModel project or CUE4Parse. It
contains no game content, mappings or keys. Only analyze files you have the right to access, follow
each game's terms of service, and do not use it to tamper with live games or online services.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE) and [NOTICE](NOTICE). Third-party licenses are included in
release packages under `licenses/`.
