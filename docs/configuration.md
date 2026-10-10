# Configuration

The server reads a JSON configuration file that defines which folders it may read, where exports go,
and resource limits. The installer creates one at `%LOCALAPPDATA%\FModelMcp\config.json`.

## How the file is found

1. `--config <path>` on the command line (the installer's client configuration uses this).
2. Otherwise, the `FMODEL_MCP_CONFIG` environment variable.
3. Otherwise, no file: the server may read only its working directory and exports to `Exports\Mcp`
   beneath it. This is rarely what you want, because clients choose the working directory.

An explicit `--config` always wins. Relative paths inside the file are resolved against the folder that
contains the file. Unknown fields are rejected, so a typo in a field name stops the server with an error
rather than being silently ignored.

## Fields

| Field | Default | Description |
| --- | --- | --- |
| `inputRoots` | working directory | Required, non-empty. Folders the server may read: game archive folders, loose files, mapping files. Everything else is refused. |
| `outputRoot` | `Exports/Mcp` | Folder for exports. Every export job writes to a new unique subfolder. |
| `oodleLibrary` | `null` | Path to an x64 Oodle DLL for Oodle-compressed games. See [Compression and native codecs](#compression-and-native-codecs). |
| `fmodelSettingsPath` | `null` | Path to FModel's `AppSettings.json` to enable the saved-profile tools. |
| `maxSessions` | `4` | Open game sessions at once (1–16). |
| `maxJobs` | `32` | Export job records kept in memory (1–1000). Older finished records are dropped; their files remain. |
| `maxBatchAssets` | `500` | Assets per export request (1–10000). |
| `maxReadBytes` | `268435456` (256 MiB) | Largest single file or mapping the server will read (1024–2147483647). Not a total memory limit. |
| `maxResponseChars` | `100000` | Largest tool response, in characters (1024–1000000). Larger results return `response_too_large`. |

Copy-ready examples:

- [config.example.json](../examples/config.example.json): manual setup with explicit folders
- [config.fmodel-profile.example.json](../examples/config.fmodel-profile.example.json): reuse a saved FModel profile

JSON does not allow comments, and this server rejects unknown fields, so keep the file to the fields above.

### Choosing input roots

Add each folder the assistant should be able to open:

- the game's archive folder, for example `D:/Games/MyGame/MyGame/Content/Paks`;
- the folder containing mapping files (`.usmap`, `.jmap`, `.jmap.gz`), if the game needs them;
- any folder of loose Unreal files you want to inspect.

Paths passed to tools such as `fmodel_open_game` must be absolute and inside one of these roots.
Symbolic links and junctions inside input and output trees are refused.

Keep `outputRoot` outside your game installation.

## Saved FModel profiles

If you already use FModel, the server can reuse a game you have set up there, including its engine
profile, AES keys and mapping, without copying keys into the MCP configuration.

The installer sets this up automatically on first install when `%APPDATA%\FModel\AppSettings.json`
exists, or when you pass `-FModelSettingsPath`. It:

- adds FModel's selected game directory to `inputRoots`;
- adds the mapping folders FModel uses (a custom mapping file's folder and FModel's `.data\mappings`);
- sets `oodleLibrary` to FModel's cached `oodle-data-shared.dll` if present;
- records `fmodelSettingsPath`.

In FModel, open the game and save its settings first, so a profile exists for the selected directory.

At runtime, `fmodel_list_saved_games` lists the saved profiles, and `fmodel_open_saved_game` opens one.
The server reads keys from the FModel settings file only when opening a game, and never returns them to
the assistant. A saved profile cannot widen `inputRoots`: if a saved game's folder is not allowed, opening
it fails until you add the folder.

## Compression and native codecs

- **Oodle.** Many recent games use Oodle compression. Set `oodleLibrary` to a compatible x64 Oodle DLL
  from your own installation, such as FModel's cached `oodle-data-shared.dll` or a game's
  `oo2core_9_win64.dll`. The server never downloads native code.
- **Other native codecs.** Some animation, audio and texture formats need CUE4Parse's optional native
  libraries placed next to `FModel.Mcp.exe`. Releases do not include them. Without them, the affected
  exports fail with an explicit error, while browsing and property inspection keep working.

`fmodel_capabilities` reports whether Oodle is available.

## Game options when opening manually

For games without a saved profile, `fmodel_open_game` takes the engine profile and keys as arguments:

- `game`: required CUE4Parse profile such as `GAME_UE5_4`. Find it with `fmodel_list_options`
  (`category=game`). The server does not guess engine versions.
- `mappingsPath`: absolute path to a `.usmap`, `.jmap` or `.jmap.gz` file for games with unversioned
  properties.
- `aesKeys`: `{ "<GUID>": "<hex key>" }`. The main key uses GUID `00000000000000000000000000000000`.
  Keys can also be added later with `fmodel_submit_keys`.
- Optional: `texturePlatform`, `customVersions`, `versionOptions`, `mapStructTypes`, `readScriptData`
  (needed for Blueprint decompilation), `readShaderMaps`, `readNaniteData`.

Keys stay in server memory for the session only. Your MCP client may still keep them in its conversation
history, so prefer saved profiles for games that need keys. See [Security](security.md).

The full argument reference is in [Tool reference](tools.md#game-options).
