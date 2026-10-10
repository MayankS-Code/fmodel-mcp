# Development

## Requirements

- Windows x64
- Git
- [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0). `global.json` requires 10.0.100 or a
  later .NET 10 feature band. The scripts also accept a repository-local SDK in `.dotnet\`.
- PowerShell 7 for development. End users only need the built-in Windows PowerShell 5.1.

## Repository layout

| Path | Contents |
| --- | --- |
| `FModel.Mcp/` | The MCP server: tools (`FModelTools.cs`), domain logic (`FModelService*.cs`), path policy, configuration |
| `FModel.Mcp.Tests/` | xUnit v3 tests, run against CUE4Parse's UE5.8 fixtures |
| `scripts/` | Build, test, publish, install and release scripts |
| `docs/` | User and developer documentation |
| `examples/` | Example server and client configurations |
| `CUE4Parse/` | Pinned CUE4Parse release, downloaded by the build (ignored by Git) |

## Build and test

| Script | What it does |
| --- | --- |
| `setup.bat` | Everything below in order, plus prerequisite checks. The one-command path for new contributors. |
| `scripts/Build-Mcp.ps1` | Downloads and verifies the pinned CUE4Parse release if needed, applies the integrations, restores packages into `.packages\` and builds Release. |
| `scripts/Test-Mcp.ps1` | Builds and runs the 21 tests, then the stdio protocol smoke test. Run `Build-Mcp.ps1` first, since it skips restore. |
| `scripts/Publish-Mcp.ps1` | Publishes a self-contained win-x64 package to a new `artifacts\fmodel-mcp-<version>-win-x64*` folder, generates license notices, smoke-tests it, and writes a ZIP and `.sha256`. Prints the package folder as its last output line. |
| `scripts/Test-Installer.ps1` | Runs the installer against a package in an isolated temporary folder: fresh install, saved-profile import without copying keys, configuration preserved on update, side-by-side versions. Defaults to the newest package for the current version. |
| `scripts/Package-Source.ps1` | Builds a source ZIP that includes the bootstrapped CUE4Parse tree. |
| `scripts/Test-DocLinks.ps1` | Checks that relative links and `#anchors` in all Markdown files resolve. Runs in CI. |
| `scripts/Smoke-Mcp.ps1` | Standalone protocol smoke test. `-OpenSavedGame` mounts the configured saved FModel profile, and `-AssetQuery <name>` also inspects one matching asset. Asset paths and values are not printed. |

Typical loop:

```powershell
./scripts/Build-Mcp.ps1
./scripts/Test-Mcp.ps1
```

Before opening a pull request that touches packaging or installation:

```powershell
$package = ./scripts/Publish-Mcp.ps1 | Select-Object -Last 1
./scripts/Test-Installer.ps1 -PackagePath $package
```

To test against a real game on your machine, create a local configuration (`*.local.json` files are
ignored by Git) and run:

```powershell
./scripts/Test-Mcp.ps1 -ConfigPath .\my.local.json -OpenSavedGame -AssetQuery "<asset name>"
```

### Protocol coverage

The test suite connects through the official MCP C# SDK client, which negotiates protocol **2026-07-28**,
and asserts that version. `Smoke-Mcp.ps1` performs the **2025-11-25** `initialize` handshake. Together
they cover current and older clients.

### Warnings

The CUE4Parse projects produce several hundred compiler warnings; those belong to upstream. The MCP
server and test projects build without compiler warnings. ImageSharp `NU1902`/`NU1903` warnings are a
known, documented advisory (see [Security](security.md#known-dependency-advisories)).

## Rules for changes

- **Stdout is reserved for MCP JSON-RPC.** Write diagnostics to stderr.
- Keep responses bounded and paginated, file selections explicit, and work scoped to sessions.
- Do not add a shell-execution tool or any automatic download of keys, mappings or native libraries.
- When adding or changing a tool, update its description, [tools.md](tools.md), the tool count checks in
  `ServerTests.cs` and `Smoke-Mcp.ps1`, and [architecture.md](architecture.md) if coverage changes.
- Never commit game content, keys, profiles, local paths or build output.

## Updating CUE4Parse

The project tracks CUE4Parse's monthly **release tags** (for example `1.2.2.202610`), not `master`.
Integrations are applied to the downloaded source by `scripts/Initialize-Mcp.ps1`; there is no fork.

1. Find the newest tag and its commit:

   ```powershell
   git ls-remote --tags https://github.com/FabianFG/CUE4Parse.git
   ```

2. Compute the SHA-256 of the archive GitHub serves for that commit:

   ```powershell
   $sha = '<commit>'
   Invoke-WebRequest "https://codeload.github.com/FabianFG/CUE4Parse/zip/$sha" -OutFile $env:TEMP\cue4parse.zip
   (Get-FileHash $env:TEMP\cue4parse.zip -Algorithm SHA256).Hash
   ```

3. Update `$revision` and `$expectedHash` (and the tag comment) in `scripts/Initialize-Mcp.ps1`.
4. Delete or move the existing `CUE4Parse\` folder, so the next build downloads the new release.
5. Run `Build-Mcp.ps1` and `Test-Mcp.ps1`. If an integration anchor is missing, the bootstrap stops with
   `Unsupported CUE4Parse revision`; adjust that integration in `Initialize-Mcp.ps1`.
6. Update the revision and hash in [DEPENDENCIES.md](../DEPENDENCIES.md), [NOTICE](../NOTICE) and
   [architecture.md](architecture.md#dependency-integration), and add a [CHANGELOG](../CHANGELOG.md) entry.

## Updating NuGet packages

```powershell
./.dotnet/dotnet.exe list FModel.Mcp/FModel.Mcp.csproj package --outdated
./.dotnet/dotnet.exe list FModel.Mcp.Tests/FModel.Mcp.Tests.csproj package --outdated
```

(Use `dotnet` instead of `./.dotnet/dotnet.exe` when a .NET 10 SDK is installed system-wide.) Versions are
pinned exactly. After updating, rebuild, rerun the tests, and update [DEPENDENCIES.md](../DEPENDENCIES.md).

## Releasing

See [Releasing](releasing.md).
