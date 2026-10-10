# Security

## Trust model

FModel MCP is a local process started by your MCP client. It communicates only over stdio, opens no
network ports, makes no network requests at runtime, and runs with your user account's permissions.

Its controls limit what an AI assistant can reach through the tools:

- **Input allowlist.** Only folders listed in `inputRoots` can be opened. Path traversal and symbolic
  links or junctions in input trees are refused.
- **Confined output.** Every export job writes to a new unique folder under `outputRoot`. Every
  converter output, including automatically exported dependencies, is checked for containment, invalid
  or device names and links before it is written.
- **Read-only archives.** Game files are never modified.
- **Bounded work.** Sessions, jobs, batch sizes, single-file reads and response sizes are limited
  (see [Configuration](configuration.md#fields)).
- **No shell access.** There is no tool that runs commands, and nothing downloads keys, mappings,
  game content or native code.

These controls are **not an operating-system sandbox**. Parsing is done by CUE4Parse and native codecs
in the same process, and a deliberately malicious archive could exploit a parser bug. Only open archives
from sources you trust, and only allow folders you intend the assistant to read.

## AES keys

- **Saved FModel profiles (recommended).** The server reads keys from the configured FModel settings
  file only when opening a game. Keys are never returned to the assistant, and the installer records
  the settings file path, never key values.
- **Keys passed as tool arguments** (`fmodel_open_game`, `fmodel_submit_keys`) are held in memory for
  the session only and never echoed back. Your MCP client may still store tool arguments in its
  conversation history, so this is less private than a saved profile.
- Never put keys in command-line arguments or in `config.json`.

Only use keys and files you are authorized to use.

## Known dependency advisories

CUE4Parse's conversion library pins **SixLabors.ImageSharp 3.1.12**, which has published advisories:

| Advisory | Severity |
| --- | --- |
| [GHSA-j3p4-wp97-rph4](https://github.com/advisories/GHSA-j3p4-wp97-rph4) | High |
| [GHSA-j9gm-c75j-xc9q](https://github.com/advisories/GHSA-j9gm-c75j-xc9q) | High |
| [GHSA-jjfr-hcj7-qf5w](https://github.com/advisories/GHSA-jjfr-hcj7-qf5w) | High |
| [GHSA-gwg2-r3hj-4w44](https://github.com/advisories/GHSA-gwg2-r3hj-4w44) | Moderate |
| [GHSA-wmxv-xphr-5c9g](https://github.com/advisories/GHSA-wmxv-xphr-5c9g) | Moderate |

The fixed ImageSharp 4.x line requires a commercial or community license key, so this project keeps
CUE4Parse's pinned version rather than overriding it. In this code path ImageSharp only creates and
encodes new 16-bit heightmap images during landscape export; it does not decode images supplied by
users. That limits exposure but does not remove the advisories. Builds show them as `NU1902`/`NU1903`
warnings. Review them before deploying in a higher-risk environment.

`Microsoft.Bcl.Memory` is raised to 10.0.12 inside CUE4Parse to replace a vulnerable transitive 9.0.0
version ([GHSA-73j8-2gch-69rq](https://github.com/advisories/GHSA-73j8-2gch-69rq)). Full dependency
details are in [Dependencies](dependencies.md).

## Releases

Release ZIPs are built by GitHub Actions from a tagged commit and published with SHA-256 checksums.
They are **not code-signed**, so Windows SmartScreen may warn on first run. Verify the checksum as shown
in [Installation](installation.md#install-a-release).

## Responsible use

Only analyze files you have the right to access, and follow each game's terms of service and applicable
law. Do not use this project to bypass anti-cheat, tamper with running games, or interact with protected
online services.

## Reporting

Report vulnerabilities privately through
[GitHub private vulnerability reporting](https://github.com/MayankS-Code/fmodel-mcp/security/advisories/new).
Do not post exploit details, keys or game archives in public issues.

For ordinary bugs, open a [public issue](https://github.com/MayankS-Code/fmodel-mcp/issues) with a sanitized
error message, the game profile, the archive format and steps to reproduce.
