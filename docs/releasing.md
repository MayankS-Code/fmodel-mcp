# Releasing

Releases are built and published by the [Release workflow](../.github/workflows/release.yml) when a
version tag is pushed. Nothing is published from a developer machine.

## Versioning

The project uses [semantic versioning](https://semver.org/). The version lives in one place,
`<Version>` in `src/FModel.Mcp/FModel.Mcp.csproj`, and the tag must be `v` plus that version (`v1.2.0`).

- **Patch** (`1.1.x`): fixes and dependency updates without behavior changes.
- **Minor** (`1.x.0`): new tools, options or noticeable parser updates, such as a CUE4Parse release with
  new game support.
- **Major** (`x.0.0`): removed or renamed tools or arguments, or configuration changes that break
  existing setups.

## Steps

1. **Prepare the release on `main`.**
   - Set `<Version>` in `src/FModel.Mcp/FModel.Mcp.csproj`.
   - Add a `## <version>` section at the top of [CHANGELOG.md](../CHANGELOG.md). Its contents become the
     GitHub release notes, and the workflow fails if the section is missing.
   - Update [Dependencies](dependencies.md) if dependencies changed.
2. **Verify locally** on Windows x64:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Setup-Release.ps1
   ```

   This builds, runs the tests and protocol smoke test, publishes the package and tests the installer.
   Optionally, also test against a real game:
   `./scripts/Test-Mcp.ps1 -ConfigPath <local config> -OpenSavedGame -AssetQuery "<asset name>"`.
3. **Check what will be published.**

   ```powershell
   git status
   git diff --check
   ```

   Confirm no game files, keys, profiles or local paths are tracked.
4. **Commit, then push `main`** and wait for the **Build and test** workflow to pass.
5. **Tag and push the tag:**

   ```powershell
   git tag -a v<version> -m "FModel MCP <version>"
   git push origin v<version>
   ```

## What the Release workflow does

On a `v*` tag, on a fresh Windows runner, it:

1. fails if the tag does not match the project version;
2. bootstraps the pinned CUE4Parse release and builds;
3. runs all tests and the protocol smoke test;
4. publishes the self-contained package and runs the isolated installer test against it;
5. builds the source bundle;
6. extracts the version's CHANGELOG section;
7. creates the GitHub release with these assets:
   - `fmodel-mcp-<version>-win-x64.zip` and `.sha256`: the package users install
   - `fmodel-mcp-<version>-source.zip` and `.sha256`: source including the pinned CUE4Parse tree,
     for GPL source availability

If any step fails, nothing is published. Fix the problem, delete the tag
(`git tag -d v<version>` and `git push origin :refs/tags/v<version>`), and tag again.

## After publishing

- Download the Windows ZIP from the release page, verify the checksum, and install it on a clean
  Windows x64 machine following [Installation](installation.md).
- Connect a client and confirm the 34 tools appear.

Releases are not code-signed; [Security](security.md#releases) explains this to users.
