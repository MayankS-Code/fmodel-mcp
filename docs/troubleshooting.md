# Troubleshooting

When reporting a problem, include the error message, the game profile (`GAME_*`), the archive type
(PAK or IoStore) and whether mappings or Oodle are used. Do not attach game files, keys or private
profiles. See [Security](security.md#reporting).

## Server and client

| Symptom | What to check |
| --- | --- |
| Tools don't appear in the client | Fully restart the client after changing its configuration. Confirm the `command` is `...\FModelMcp\current\FModel.Mcp.exe` and that the file exists. Clients set up with 1.1.1 or earlier point into a `versions\` folder; see [Update and uninstall](installation.md#update-and-uninstall). In Claude Code, run `claude mcp get fmodel` or `/mcp`. |
| `current\ exists and is not a junction` during install | Something else created a real `current` folder in the install root. Move it elsewhere and rerun the installer. |
| Server exits immediately | Run `FModel.Mcp.exe --config <path>` in a terminal and read the error on stderr. Common causes: invalid JSON, an unknown field name, an empty `inputRoots`, or limits outside their ranges (see [Configuration](configuration.md#fields)). |
| Running the exe shows nothing | Normal. It waits for JSON-RPC on stdin. Use `--help` for usage, or run the [smoke test](installation.md#verify-the-installation). |
| Client reports invalid JSON or protocol errors | The client must start `FModel.Mcp.exe` directly, not a build command or `dotnet run`, whose output would corrupt the protocol stream. |
| Paths in JSON client config fail | Use forward slashes or escaped backslashes (`\\`) in JSON. In Codex TOML, use single-quoted strings. |
| `Codex CLI was not found` during install | Add `-SkipRegistration` and configure your client manually, or pass `-CodexPath`. |

## Opening games

| Symptom | What to check |
| --- | --- |
| `invalid_argument` about a path | The folder must be absolute and inside `inputRoots`. Add the folder to `config.json` and restart the server. Saved profiles cannot widen the allowlist. |
| Saved profile not found | In FModel, open the game and save its settings. Confirm `fmodelSettingsPath` points to that `AppSettings.json`. |
| Multiple mapping candidates | Pass `mappingsPath` explicitly to `fmodel_open_saved_game`. |
| No or few files | Check the directory, encrypted or unloaded archives, missing key GUIDs in `fmodel_session_info`, and whether archives have a directory index. |
| Encrypted archives stay unloaded | Submit the correct AES keys for the GUIDs listed by `fmodel_session_info`, or use a saved FModel profile. |
| IoStore packages fail | Include `global.utoc` and `global.ucas` and all companion containers, and use the correct profile. The global container can appear unloaded because it has no normal directory index. |
| Decompression errors | The game needs Oodle or another native codec. Set `oodleLibrary` (see [Compression and native codecs](configuration.md#compression-and-native-codecs)). |

## Mappings and properties

| Symptom | What to check |
| --- | --- |
| Unversioned properties fail to parse | Use mappings that match this exact game build, and the correct `GAME_*` profile. Mappings cannot fix a wrong engine version. |
| `Usmap has invalid version (N)` | The mapping file is newer than the bundled CUE4Parse supports, or was made for another build. This release supports USMAP up to version 5 (`EngineVersioning`). Check where the mapping came from and which build it targets. |

## Exports and inspection

| Symptom | What to check |
| --- | --- |
| Texture or mesh export fails | Check the texture platform and profile, missing bulk payloads (`.ubulk`, `.uptnl`), and unsupported formats or codecs. |
| Animation compression data unavailable | The animation's compression settings or codec assets are missing. Properties and raw export still work. |
| World format unsupported | Set `meshFormat` to `USD`. Decide whether to include sublevels with `includeStreamingLevels`. |
| Export finished with no files | Some packages, such as empty worlds, legitimately have nothing convertible. Check the job's result notes. |
| `response_too_large` | Use a smaller page, a deeper JSON pointer, or export properties and read the output in chunks. |
| Blueprint pseudocode unavailable | Open the game with `readScriptData=true` and confirm the package has a Blueprint class export. Cooked games may omit data. |
| Reference search is empty | Reverse references are only available for IoStore games, and soft references are not fully indexed. |
| Same metadata across versions | Equal metadata does not prove equal bytes. Use `fmodel_asset_info` with `hash`, including payload files. |

## Building from source

| Symptom | What to check |
| --- | --- |
| `.NET 10 SDK was not found` | Install the [.NET 10 SDK](https://dotnet.microsoft.com/download/dotnet/10.0), reopen PowerShell, and rerun. Or run `scripts\Setup-Release.ps1 -InstallPrerequisites`. |
| `A compatible .NET SDK was not found` when running `dotnet` by hand | `global.json` requires a .NET 10 SDK. Install one, or use the scripts, which also find a repository-local `.dotnet\` SDK. |
| `CUE4Parse archive checksum mismatch` | The download was corrupted, or GitHub changed the archive. Delete `CUE4Parse\` and retry. If it persists, open an issue. |
| `CUE4Parse is nonempty but incomplete` | A previous bootstrap was interrupted. Delete the `CUE4Parse\` folder and rebuild. |
| `Unsupported CUE4Parse revision: expected source anchor missing` | The CUE4Parse source doesn't match the pinned release. Delete `CUE4Parse\` so the pinned release is downloaded again. |
| NuGet restore fails | Check network access and disk space, then rerun `scripts\Build-Mcp.ps1`. |
| ImageSharp `NU1902`/`NU1903` warnings | Expected. This is a known advisory in a CUE4Parse dependency; see [Security](security.md#known-dependency-advisories). |
| Hundreds of compiler warnings | Expected. They come from the CUE4Parse projects; the MCP projects build cleanly. |
