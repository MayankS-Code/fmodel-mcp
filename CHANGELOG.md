# Changelog

## 1.2.0

- **Stable executable path:** the installer now maintains `current\FModel.Mcp.exe`, a junction to the newest version. Client configuration stays the same across updates; clients set up with 1.1.1 or earlier need their `command` changed once.
- The server version is read from the project file instead of being hardcoded in two places.
- GitHub: structured bug and feature forms, private security reporting link, pull request checklist, and Dependabot for NuGet and Actions.

- Pinned CUE4Parse to its latest release tag, `1.2.2.202610` (USMAP v5 support), and retained the MCP output-path safety integration.
- Fixed a clean-checkout bootstrap failure: the `Microsoft.Bcl.Memory` integration step now inserts the package version instead of replacing a line that does not exist upstream.
- Verified MCP protocol 2026-07-28 with the official C# SDK client in the test suite; the stdio smoke test continues to cover 2025-11-25 clients.
- Updated the .NET hosting and test dependencies; migrated the test project to the maintained xUnit v3 line (4.0.2).
- Replaced the game-specific smoke check with a generic `-AssetQuery` option.
- Fixed the release workflow: it now runs tests, publishes the Windows package, verifies the installer and uses only the current version's changelog section as release notes. CI no longer hardcodes the version.
- Added repeatable build, test, publish, and Windows setup entry points with side-by-side release outputs.
- Restructured documentation: a short README with guides in `docs/` (installation, configuration, tool reference, troubleshooting, security, development, releasing, architecture), and configuration templates for Claude Desktop, Claude Code, VS Code, Cursor and Codex in `examples/`.
- The installer now prints the exact client command and arguments and links to setup instructions for any MCP client, instead of Codex-only guidance.
- Added a documentation link check to CI.

## 1.1.1

- Fixed inline texture previews sending raw PNG bytes where MCP requires base64 text. Images now display correctly in MCP clients.
- Added a regression test that opens a real Unreal texture through the official stdio MCP client and validates the received PNG encoding and dimensions.
- Full-resolution texture file exports and saved FModel profile integration remain available.

## 1.1.0

- Added saved-game discovery and one-command opening from FModel's local settings (34 tools total).
- Fresh installs reuse the selected game folder, mapping cache and existing Oodle library when available.
- Existing installations can connect with `Install-Mcp.ps1 -ImportFModel`.
- Saved AES keys are read in process without copying them into MCP configuration or tool arguments.
- Added tests for saved encrypted games, key redaction, mapping ambiguity, settings refresh and access boundaries.
- Saved-game discovery reflects saved settings; it does not control the desktop UI or fetch remote keys/mappings.

## 1.0.0

- Initial local stdio MCP server with 32 tools, four resources/resource templates, and four prompts.
- Archive mounting, explicit game profiles, AES keys, mappings, browsing, registry and localization search.
- Package properties, references, Blueprint pseudocode and inline texture previews.
- Background raw/JSON/converted/audio export jobs with cancellation and result manifests.
- Bounded input/output handling and per-session concurrency control.
- Windows x64 self-contained release with Codex/ChatGPT desktop installer.
- Automated tests against real Unreal PAK/IoStore fixtures and the official MCP client.

Game-specific and optional codec support remains dependent on CUE4Parse; see the tool guide.
