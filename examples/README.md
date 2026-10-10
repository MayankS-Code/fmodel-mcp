# Examples

Replace every `<you>` and game path with your own values. After running the installer,
`%LOCALAPPDATA%\FModelMcp\mcp-client.json` contains the exact executable and config paths. The
executable path (`...\FModelMcp\current\FModel.Mcp.exe`) stays the same across updates.

## Server configuration

| File | Use |
| --- | --- |
| [config.example.json](config.example.json) | Manual setup with explicit game, mapping and export folders |
| [config.fmodel-profile.example.json](config.fmodel-profile.example.json) | Reuse a saved FModel profile (what the installer generates) |

Field reference: [docs/configuration.md](../docs/configuration.md).

## MCP client configuration

| File | Client | Location |
| --- | --- | --- |
| [clients/claude-desktop.json](clients/claude-desktop.json) | Claude Desktop | `%APPDATA%\Claude\claude_desktop_config.json` |
| [clients/claude-code.mcp.json](clients/claude-code.mcp.json) | Claude Code (project scope) | `.mcp.json` in the project root |
| [clients/vscode-mcp.json](clients/vscode-mcp.json) | VS Code | `.vscode/mcp.json`, or the user `mcp.json` |
| [clients/cursor-mcp.json](clients/cursor-mcp.json) | Cursor | `%USERPROFILE%\.cursor\mcp.json` or `.cursor/mcp.json` |
| [clients/codex-config.toml](clients/codex-config.toml) | Codex | `%USERPROFILE%\.codex\config.toml` |

For Claude Code, the `claude mcp add` command in [docs/installation.md](../docs/installation.md#claude-code)
is usually easier than editing JSON.
