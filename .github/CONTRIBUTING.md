# Contributing

Thanks for helping improve FModel MCP.

## Getting started

On Windows x64 with Git and the .NET 10 SDK installed:

```powershell
git clone https://github.com/plu1337/fmodel-mcp.git
cd fmodel-mcp
./scripts/Build-Mcp.ps1
./scripts/Test-Mcp.ps1
```

The first build downloads the pinned CUE4Parse release. See [docs/development.md](../docs/development.md)
for the repository layout, all scripts, coding rules and how to update dependencies.

## Pull requests

- Keep changes focused, and describe what changed and how you tested it.
- `Build-Mcp.ps1` and `Test-Mcp.ps1` must pass. CI runs them on every pull request.
- For packaging or installer changes, also run `Publish-Mcp.ps1` and `Test-Installer.ps1`.
- Update the documentation and [CHANGELOG.md](../CHANGELOG.md) for user-visible changes.

## Never commit

Game files, AES keys, mappings, FModel profiles, machine-specific paths or build output. Describe
game-specific problems in words or with synthetic files instead of attaching copyrighted assets.

## Reporting bugs and security issues

Use the [issue templates](https://github.com/plu1337/fmodel-mcp/issues/new/choose) for bugs and feature
requests. Report vulnerabilities privately as described in [SECURITY.md](SECURITY.md).
