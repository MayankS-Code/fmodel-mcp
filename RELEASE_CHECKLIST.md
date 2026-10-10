# Release checklist

Run from any directory on a Windows x64 machine with Git and the .NET 10 SDK:

1. `setup.bat` (or `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Setup-Release.ps1`). Review and approve any offered `winget` installation.
2. Confirm Release build, all tests, published MCP protocol smoke test, and isolated installer test pass.
3. Inspect `artifacts/fmodel-mcp-<version>-win-x64/`, its ZIP, and `.sha256`. Publish uses a new path and preserves existing artifacts.
4. Verify the package against the supported game/profile setup in a local test configuration. Do not include game archives, mappings, keys, profiles, or user configuration in release files.
5. Run `git diff --check`, inspect the complete diff and `git status`, and confirm no local secrets or game files are tracked.
6. Verify dependency notices and perform an online NuGet security audit. Resolve or explicitly document advisories before publishing.
7. Test the extracted ZIP on a clean Windows x64 machine, initialize the MCP server over stdio, and verify the 34-tool catalog (runtime is bundled in the self-contained package).
8. A maintainer may then create a release through the normal repository process. This checklist does not create commits, tags, or releases.
