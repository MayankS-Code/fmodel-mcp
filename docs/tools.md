# Tool reference

FModel MCP exposes **34 tools**, 4 resources and resource templates, and 4 workflow prompts. All tool
names start with `fmodel_`. Read and list tools are marked read-only. The other tools change only
server-side state such as sessions and jobs, so they are marked non-destructive. No tool sends messages,
makes network requests or modifies game files.

Each tool's advertised schema contains its full defaults and descriptions; clients show them
automatically. This page explains how the tools fit together.

- [Recommended workflow](#recommended-workflow)
- [Tools](#tools)
- [Game options](#game-options)
- [Export options and results](#export-options-and-results)
- [Resources and prompts](#resources-and-prompts)
- [Responses, pagination and errors](#responses-pagination-and-errors)
- [Limits](#limits)
- [Not supported](#not-supported)

## Recommended workflow

**With a saved FModel profile** (when `fmodel_capabilities` reports `savedGamesConfigured=true`):

1. `fmodel_list_saved_games`, then `fmodel_open_saved_game`. An empty `selector` opens the game last
   selected in FModel, with its saved keys, profile overrides and mapping. If several cached mappings
   match, pass `mappingsPath` explicitly.
2. Continue from step 4 below with the returned `sessionId`.

**Manual setup:**

1. `fmodel_capabilities`: check the allowed roots, limits and Oodle availability.
2. `fmodel_list_options` with `category=game` and a filter, to find the correct `GAME_*` profile.
   `fmodel_open_game` never guesses the engine version.
3. `fmodel_open_game` on the archive folder. Keep the `sessionId`, and check `fmodel_session_info` for
   missing key GUIDs and mount counts. Add keys with `fmodel_submit_keys` or mappings with
   `fmodel_set_mappings` as needed. For IoStore games, include `global.utoc` and its data files.
4. Browse with `fmodel_browse` or search with `fmodel_search_assets`. For search by class, load
   `AssetRegistry.bin` with `fmodel_load_registry` first, then use `fmodel_search_registry`.
5. Inspect a package with `fmodel_inspect_package`, then drill into an object with
   `fmodel_get_properties` (JSON pointers and pagination keep responses small), preview textures with
   `fmodel_preview_texture`, follow references with `fmodel_find_references`, or generate Blueprint
   pseudocode with `fmodel_decompile_blueprint`.
6. Export with `fmodel_start_export` and keep the `jobId`. Poll `fmodel_job_status` about once a second
   until the job leaves `finalizing`, then read `fmodel_job_results` and the job's `manifest.json`
   before treating the export as successful.
7. `fmodel_close_game` when finished, to release archive file handles.

Example arguments (illustrative paths; use the paths the server returns):

```json
{"options":{"directory":"D:/Games/MyGame/MyGame/Content/Paks","game":"GAME_UE5_4","mappingsPath":"D:/Unreal/Mappings/MyGame.usmap","readScriptData":true}}
```
`fmodel_open_game`

```json
{"sessionId":"<id>","query":"T_Logo","packagesOnly":true,"limit":20}
```
`fmodel_search_assets`

```json
{"sessionId":"<id>","path":"MyGame/Content/UI/T_Logo.uasset","section":"exports"}
```
`fmodel_inspect_package`

```json
{"sessionId":"<id>","request":{"paths":["MyGame/Content/UI/T_Logo.uasset"],"mode":"converted","textureFormat":"Png"}}
```
`fmodel_start_export`

## Tools

### Server and sessions

| Tool | Purpose and key arguments |
| --- | --- |
| `fmodel_capabilities` | Server purpose, allowed roots, limits, codec availability and limitations. |
| `fmodel_list_options` | Valid enum values for a `category` (game profiles, formats and so on), with `filter`, `offset`, `limit`. |
| `fmodel_list_saved_games` | Saved FModel profiles: names, directories, selected profile, access status, mapping candidates and key counts. Requires `fmodelSettingsPath`. |
| `fmodel_open_saved_game` | Open a saved profile. Optional `selector` (name or directory; empty means the last selection), `mappingsPath`, `readScriptData` (default true). |
| `fmodel_open_game` | Open a local archive folder. `options` requires `directory` and `game`; see [Game options](#game-options). |
| `fmodel_list_sessions` | IDs and directories of open sessions. |
| `fmodel_session_info` | Profile, provider, file counts, mounted and unloaded archives, missing key GUIDs, mappings, culture, registry state. |
| `fmodel_close_game` | Close a session. Refused while the session has active export jobs. |

### Archives, keys and mappings

| Tool | Purpose and key arguments |
| --- | --- |
| `fmodel_list_archives` | Archive names, paths, sizes, compression, encryption and mount status, with a name `filter`. |
| `fmodel_submit_keys` | `keys` maps GUIDs to AES key hex. The all-zero GUID is the main key. |
| `fmodel_set_mappings` | Absolute local `.usmap`, `.jmap` or `.jmap.gz` `path`. |
| `fmodel_load_virtual_paths` | Resolve plugin mount aliases after mounting. |

### Browsing and reading

| Tool | Purpose and key arguments |
| --- | --- |
| `fmodel_browse` | Direct child folders and files of a virtual `path`; empty lists the roots. |
| `fmodel_search_assets` | Path `query`, folder `prefix`, exact `extension`, exact `archive`, `packagesOnly`. |
| `fmodel_asset_info` | Metadata and companion payloads; optional `hash` of the decompressed bytes. |
| `fmodel_read_file` | Bounded bytes of a virtual file: `encoding` (`utf8`, `utf16`, `base64`, `hex`), `offset`, `count`. At most 32768 bytes per call. |
| `fmodel_statistics` | File, package and byte totals grouped by extension under a `prefix`. |

### Package inspection

| Tool | Purpose and key arguments |
| --- | --- |
| `fmodel_inspect_package` | `section` = `summary`, `exports`, `imports` or `names`. Export indexes are zero-based. |
| `fmodel_get_properties` | One object by `objectName` or `exportIndex`; optional RFC 6901 `pointer`; pages through fields and array elements. |
| `fmodel_find_references` | `direction=dependencies` for outgoing imports, or `referencers` for IoStore container importers. |
| `fmodel_preview_texture` | Inline PNG of a texture `objectName`/`exportIndex`; `maxSize` 32–2048. |
| `fmodel_decompile_blueprint` | Approximate C++-like pseudocode, paginated by line. Requires `readScriptData=true`. |
| `fmodel_inspect_data_file` | Parse `format` = `locres`, `locmeta` or `binaryConfig`, with optional pointer and pagination. |

### Registry and localization

| Tool | Purpose and key arguments |
| --- | --- |
| `fmodel_load_registry` | Parse a virtual `AssetRegistry.bin` `path` into the session. One registry per session. |
| `fmodel_search_registry` | Object-path `query`, `className` substring, optional `includeTags`. |
| `fmodel_load_localization` | Set the active `culture`, such as `en`, `de` or `pt-BR`. |
| `fmodel_search_localization` | Search keys and values with `query` and optional `namespaceFilter`. |

### Export jobs

| Tool | Purpose and key arguments |
| --- | --- |
| `fmodel_start_export` | Start exporting explicit `request.paths` with a mode and options; returns a `jobId`. |
| `fmodel_list_jobs` | Retained jobs with status, counts, timestamps and output folders. |
| `fmodel_job_status` | `queued`, `running`, `cancelling`, `finalizing`, or a terminal status. |
| `fmodel_job_results` | Paginated per-asset `success`, `files` and error or skip notes. |
| `fmodel_cancel_job` | Cooperative cancellation; files already written are kept. |
| `fmodel_read_output` | Read a finished job's file by `relativePath` (default `manifest.json`), as `utf8` or `base64`, with byte offsets. |

### Comparison

| Tool | Purpose and key arguments |
| --- | --- |
| `fmodel_compare_sessions` | Added, removed and metadata-changed paths between `leftSessionId` and `rightSessionId`, with an optional `prefix`. |

## Game options

Options for `fmodel_open_game`:

| Option | Notes |
| --- | --- |
| `directory` | Required. Absolute archive folder inside an input root. |
| `game` | Required. `GAME_*` profile from `fmodel_list_options`. |
| `mappingsPath` | Absolute `.usmap`, `.jmap` or `.jmap.gz` file. |
| `aesKeys` | `{GUID: hex}`. Main key GUID is `00000000000000000000000000000000`. |
| `texturePlatform` | Defaults to `DesktopMobile`. |
| `customVersions` | GUID to integer version. |
| `versionOptions` | Parser option name to boolean. |
| `mapStructTypes` | Name to `{key, value}` type pair. |
| `readScriptData` | Default `false`. Needed for Blueprint decompilation. |
| `readShaderMaps` | Default `false`. |
| `readNaniteData` | Default `true`. |

Changing the profile or parser flags requires a new session. Keys and mappings can be updated in place.
Keys stay in memory for the session lifetime and are never echoed back, but your MCP client may keep tool
arguments in its own history.

## Export options and results

| Mode | Output |
| --- | --- |
| `raw` | Original decompressed bytes; packages include available `.uexp`, `.ubulk` and `.uptnl` companions. |
| `properties` | The package's exports serialized as a JSON array. |
| `audio` | Decoded SoundWave, SoundNodeWave and AkMediaAssetData where supported; the file extension reflects the actual codec. |
| `converted` | The matching CUE4Parse exporter for textures, materials, static and skeletal meshes, skeletons, animations, poses, geometry, worlds, landscapes, splines or DNA. |

- `objectName` limits a single-package export; it cannot be used with `raw` or multiple paths.
- Mesh formats: `Gltf2` (binary glTF), `ActorX`, `UEFormat`, `USD`. **Worlds require `USD`.**
- Animations support ActorX, UEFormat and USD, and need their skeleton and compression data.
- Other settings: `meshQuality`, `naniteMeshFormat`, `textureFormat`, `textureQuality` (1–100),
  `exportAllTextureMips`, `exportHdrTexturesAsHdr`, `exportMaterials`, `materialDepth`,
  `exportMorphTargets`, `socketFormat`, `compressionFormat`, `decompressAudio`, `includeStreamingLevels`.
  Use `fmodel_list_options` for the exact values. Unsupported combinations become explicit job errors.

Each job writes to a unique folder under `outputRoot`, keeping the virtual folder structure under `raw/`,
`properties/`, `audio/` or `converted/`. Converters may export dependencies too; those files appear in
the asset's results and in the manifest. World sublevels are referenced but not exported unless
`includeStreamingLevels` is set, which can greatly increase time and size.

Terminal states are `completed` (every requested path succeeded; check notes for skipped objects),
`completed_with_errors`, `cancelled` and `failed`. `manifest.json` records the status, per-asset results
and every written file, including partial output. Cancellation waits for the current parser operation and
does not delete files. Jobs run one at a time per session; different sessions can export in parallel.

## Resources and prompts

| Resource | Contents |
| --- | --- |
| `fmodel://guide` | Command-planning guide and troubleshooting for the AI |
| `fmodel://capabilities` | Current server capabilities |
| `fmodel://sessions/{sessionId}` | Current session state |
| `fmodel://jobs/{jobId}` | Current job status |

Prompts: `explore_game(directory, objective)`, `export_assets(sessionId, objective)`,
`diagnose_asset(sessionId, assetPath)` and `compare_game_versions(leftSessionId, rightSessionId, prefix)`.

## Responses, pagination and errors

Paged results contain `items`, `total`, `offset` and `nextOffset` (`null` on the last page), sometimes
wrapped in `data`, `results`, `lines` or `extensions`. Page size is 1–200. Protocol fields use camelCase,
while Unreal property names keep their original casing. JSON pointers are case-sensitive and escape `/`
as `~1` and `~` as `~0`.

Failed calls set `isError=true` with an `error` code and a `message`:

| Code | Meaning |
| --- | --- |
| `invalid_argument` | A parameter is missing, malformed or outside an allowed root. |
| `not_found` | The session, job, file or object does not exist. |
| `invalid_state` | The operation is not possible now, such as closing a session with running jobs. |
| `unsupported` | The asset, format or codec is not supported. |
| `parser_or_io_error` | CUE4Parse or the file system failed; the message has details. |
| `response_too_large` | The result exceeds `maxResponseChars`. Use a smaller page, a deeper JSON pointer, or export properties and read the output in chunks. |

## Limits

- Input roots are an allowlist, and symlinks or junctions are refused in input and output paths.
- `maxReadBytes` limits individual selected files and mappings. It does not cap total parser memory,
  dependency decompression or export disk usage, which can be large for big assets.
- `fmodel_read_file` returns at most 32768 bytes per call; text chunks can split multi-byte characters.
- Texture `maxSize` bounds the returned image, not intermediate decode memory.
- The server is a trusted local process, not a sandbox for hostile archives. See [Security](security.md).

## Not supported

These are advertised as unavailable rather than exposed as stub tools: control of the FModel desktop UI
or 3D viewport, streamed Fortnite and VALORANT providers, remote key or mapping downloads, external
Wwise, FMOD and CriWare bank conversion, per-game icon creators, native Lua decompilation, shader
decompilation, repacking, and any game modification.

Problems with specific games or exports: see [Troubleshooting](troubleshooting.md).
