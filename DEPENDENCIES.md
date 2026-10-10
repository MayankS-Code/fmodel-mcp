# Dependencies and compatibility

This project is FModel MCP 1.1.2. Versions below are pinned; no floating package ranges are used.

## Runtime and build

- Target framework: `net10.0`, Windows x64. The target is intentionally retained: .NET 10 is an LTS release supported by Microsoft through November 2028 ([lifecycle](https://learn.microsoft.com/dotnet/core/releases-and-support)).
- SDK: .NET 10 SDK. `global.json` selects 10.0.100 with `latestFeature` roll-forward. A newer compatible .NET 10 feature-band SDK may be selected; a different major SDK is not.
- Published app: self-contained for Windows x64 (`--self-contained true`, bundling the .NET 10 runtime). Target systems do not require a separate .NET installation.
- `Microsoft.Extensions.Hosting` 10.0.12 (MIT); `ModelContextProtocol` 2.2.0 (Apache-2.0).

## Unreal parsing

- CUE4Parse source revision: `ed9897a1a3a8dba84a4b6d2119846e0502d74f19` (upstream `master`, 2026-10-09), downloaded from the official `FabianFG/CUE4Parse` repository archive. `scripts/Initialize-Mcp.ps1` verifies SHA-256 `BE5FAC2BE22E56470D1EEA26267DAA6AEA54D176096F6EDCFE558E839FC2CBC1` before using it.
- The pinned `EUsmapVersion` defines `EngineVersioning` as value 5 and `Latest` as 5. `UsmapParser` reads the engine version for mappings at that version, proceeds into the mapping tables, and validates subsequent data. This is parser evidence, not a promise that every game mapping is compatible. The pin was selected because it includes USMAP v5 parsing and has been exercised with the MCP implementation.
- The source integration adds output-path validation hooks used by the host and pins CUE4Parse's direct `Microsoft.Bcl.Memory`, `System.IO.Hashing`, and `System.Numerics.Tensors` dependencies to 10.0.12. These changes are applied idempotently to the verified source revision; unrelated upstream files are retained.
- NuGet's stable CUE4Parse package observed during this release audit was `1.2.2.202610`. It is not substituted for the source pin: the source revision is newer and includes the host integration point required to validate all conversion outputs. Upstream package and source are separate artifacts and are not assumed interchangeable.
- CUE4Parse is Apache-2.0. Its full license and the licenses/notices for resolved dependencies are included in the source and release package where available.

## Tests and security notes

- Test dependency: `xunit.v3.mtp-v2` 4.0.1 (Apache-2.0). The test project is an executable and selects Microsoft Testing Platform through `global.json`, as required by .NET 10's `dotnet test` runner selection. `Test-Mcp.ps1` builds and invokes the test executable directly because this project currently validates through xUnit's in-process runner; the 21 tests run successfully this way.
- The restore audit identified advisories for the pinned CUE4Parse conversion dependency `SixLabors.ImageSharp` 3.1.12. The upstream fixed package observed was 4.1.2, which requires a commercial/community license key for direct use; this project does not embed or request that key. Current code uses ImageSharp to create a new 16-bit heightmap image and encode its output; it does not decode user-supplied ImageSharp images. This limits exposure but does not remove the dependency advisory. Review the [ImageSharp advisories](https://github.com/SixLabors/ImageSharp/security/advisories) before deploying in a higher-risk environment.
- NuGet audit and feed availability can vary by environment. Re-run `dotnet restore` with audit enabled on a networked build machine before release. No claim is made that transitive advisories have been eliminated.
- `scripts/Write-Notices.ps1` generates the dependency notice material from the restored dependency graph for each published build.

## License references

The MCP project is GPL-3.0-or-later as expressed by its existing `LICENSE`. CUE4Parse and ModelContextProtocol are Apache-2.0; Microsoft.Extensions.Hosting and Microsoft packages are MIT; xUnit v3 is Apache-2.0. Refer to each shipped package's license metadata and generated notices for the complete transitive set. This project does not assert rights to game assets or game data.
