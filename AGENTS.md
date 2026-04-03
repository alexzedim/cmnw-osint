# AGENTS.md — CMNW-OSINT

## Project Overview

World of Warcraft addon that passively collects player intelligence data from multiple sources and exports it as JSON. Written in pure Lua for the WoW API. Licensed under MPL-2.0.

**Data captured per player:** guid, id, realmId, name, realm, level, faction, race, raceName, class, className, classFile, gender, guild, guildRank, guildRankName, status, createdBy, updatedBy, lastModified.

**Data sources (5 collection paths):**

| Source | Event | createdBy | Data richness |
|--------|-------|-----------|---------------|
| Target | `PLAYER_TARGET_CHANGED` | `OSINT-CHARACTER-GET` | Full (all unit API fields) |
| Nameplate | `NAME_PLATE_UNIT_ADDED` | `OSINT-NAMEPLATE-GET` | Full (all unit API fields) |
| Chat | `CHAT_MSG_*` (12 events) | `OSINT-CHAT-GET` | Minimal (name, realm, guid only) |
| WHO list | `WHO_LIST_UPDATE` | `OSINT-WHO-GET` | Partial (name, realm, level, race, class, guild) |
| CLEU | `COMBAT_LOG_EVENT_UNFILTERED` (7 sub-events) | `OSINT-CLEU-GET` | Variable (uses `GetPlayerInfoByGUID` when available) |

**Console debug format:** `name@realm | level | id | source`

## Build / Lint / Test

This is a WoW addon — there is no build step, bundler, or package manager. Files are loaded directly by the WoW client via the `.toc` manifest.

- **No build command** — drop files into `Interface\AddOns\CMNW-OSINT\`
- **No linter configured** — optionally use [luacheck](https://github.com/luarocks/luacheck) with a WoW-compatible std definition
- **No tests** — testing requires an in-game WoW environment or a WoW API mock framework

### Lint Command

```bash
luacheck Core.lua --std wow
```

### WoW API Stub for Static Analysis

Create a `.luacheckrc` in the project root for luacheck with WoW globals:

```lua
stds.wow = {
  read_globals = {
    "UnitExists", "UnitIsPlayer", "UnitGUID", "UnitName", "UnitLevel",
    "UnitFactionGroup", "UnitRace", "UnitClass", "UnitSex", "GetGuildInfo",
    "GetRealmName", "CreateFrame", "SendChatMessage", "date", "strsplit",
    "pairs", "tostring", "print", "table", "string", "SlashCmdList",
    "UIParent", "GameFontNormal", "GameFontNormalLarge", "GameFontHighlight",
    "GameFontDisable", "UnitIsSameServer", "UnitEffectiveLevel",
    "UnitPlayerControlled", "UnitClassification", "UnitReaction",
    "UnitOnCurrentScreen", "strjoin", "type", "ipairs",
    "FauxScrollFrame_GetOffset", "FauxScrollFrame_Update",
    "UIPanelScrollFrameTemplate", "UIPanelCloseButton", "BackdropTemplate",
    "UISpecialFrames", "tinsert", "bit", "pcall", "tonumber",
    "GetPlayerInfoByGUID", "C_Secrets", "C_FriendList",
    "COMBATLOG_OBJECT_REACTION_HOSTILE", "COMBATLOG_OBJECT_REACTION_FRIENDLY",
    "COMBATLOG_OBJECT_REACTION_NEUTRAL", "COMBATLOG_OBJECT_TYPE_PLAYER",
    "COMBATLOG_OBJECT_TYPE_NPC", "COMBATLOG_OBJECT_TYPE_PET",
    "FauxScrollFrame_OnVerticalScroll",
  },
}
std = "wow"
```

## Repository Structure

```
CMNW-OSINT.toc    — Addon manifest (interface version, files, SavedVariables)
Core.lua          — All addon logic (single-file architecture)
LICENSE           — MPL-2.0
```

## Local Paths

| Item | Path |
|------|------|
| Addon source | `D:\Projects\alexzedim\cmnw-osint\` |
| WoW addon install | `D:\Games\World of Warcraft\_retail_\Interface\AddOns\CMNW-OSINT\` |
| SavedVariables | `D:\Games\World of Warcraft\_retail_\WTF\Account\ALEXZEDIM\SavedVariables\cmnw-osint.lua` |

The addon source repo is the authoring copy. Deploy by copying `Core.lua` and `CMNW-OSINT.toc` to the WoW addon install directory. SavedVariables are written by WoW on logout/reload only.

## Code Style Guidelines

### General

- Single-file addon; all logic lives in `Core.lua`
- Use `local` for all variables and functions — never pollute the global namespace
- Wrap the addon in `local addonName, ns = ...` at the top of every file
- No external dependencies or libraries
- Use 4-space indentation, no tabs

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Variables | camelCase | `guildRankName`, `lastCaptured`, `exportFrame` |
| Functions | PascalCase | `OnInitialize`, `CollectTargetData`, `SaveToDB` |
| Constants / color codes | UPPER_CASE | `GREEN`, `CYAN`, `RST` |
| WoW globals / API | Preserve Blizzard's naming | `UnitGUID`, `CreateFrame`, `SlashCmdList` |
| SavedVariables | `_DB` suffix | `CMNWOSINT_DB` |
| Slash command IDs | UPPER_CASE with numeric suffix | `SLASH_CMNWOSINT1`, `SLASH_CMNWOSINT2` |
| Frame names | Addon prefix | `CMNWOSINT_ExportFrame` |

### Color Escape Sequences

- **Addon chat prefix:** `[CMNW-OSINT]` with green color `|cff00ff00`
- **Label color:** Gold `|cffffd700` for field names in chat output

### Formatting

- Alignment of variable assignments with spaces — align `=` signs in blocks:
  ```lua
  local guid        = UnitGUID(unit)
  local name, realm = UnitName(unit)
  local level       = UnitLevel(unit)
  ```
- Keep lines under ~120 characters
- Use `tostring()` wrapping when concatenating potentially-nil values with `..`
- Use `or` for nil-coalescing: `UnitFactionGroup(unit) or "Unknown"`

### Section Organization

Organize code into clearly labeled sections with banner comments:

```lua
-- ============================================
-- SECTION NAME
-- ============================================
```

Follow this order:
1. Initialization
2. Helpers (`ParseGuidID`, `ParseGuidRealmID`, `NormalizeRealm`, `ParseNameRealm`, `IsIdentitySecret`)
3. Data Collection (`CollectUnitData`, `CollectTargetData`, `CollectChatData`, `CollectWhoData`, `CollectCLEUData`)
4. Debug / Print helpers (`DebugPrint`, `DebugCLEU`)
5. Database persistence (`SaveToDB`, `FindPlayerInDB`)
6. UI helpers (`CreateElvUIButton`, `CreateElvUICloseButton`, `RedistributeColumns`)
7. UI — Main Frame (`CreateMainFrame`, table update functions)
8. Export (JSON to clipboard via popup, `ExportJSON`)
9. Slash commands
10. Initialization (deferred `OnInitialize`)
11. Event handling (last — registers events and sets scripts)

### Imports / Globals

- No `require()` statements — WoW loads files listed in `.toc`
- Declare all WoW API functions used as read-globals in `.luacheckrc`
- Access SavedVariables as plain globals (e.g., `CMNWOSINT_DB`)

### Error Handling

- Validate `nil` / empty values before use with guard clauses: `if not X then return nil end`
- Use `tostring()` when printing potentially nil values
- Use `or` to provide fallback defaults: `or "Unknown"`, `or ""`
- Check `UnitExists(unit)` and `UnitIsPlayer(unit)` before collecting data
- Gracefully handle missing realm: `if not realm or realm == "" then realm = GetRealmName() end`
- Initialize SavedVariables on `ADDON_LOADED`: `if not CMNWOSINT_DB then CMNWOSINT_DB = {} end`
- Use `pcall()` when calling functions that may error in chat event handlers

### Tables & Data

- Use flat tables keyed by GUID for the database: `CMNWOSINT_DB[data.guid] = data`
- Return structured tables from data collection functions with named keys
- Use `string.format()` for JSON serialization; `table.concat()` for joining entries
- Use `pairs()` for iterating the database
- Insert-only database pattern: never update existing records, only add new ones

### Data Normalization

All `name` and `realm` values are lowercased at the collection point before entering the database:

- **name**: Always lowercased via `:lower()` in every `Collect*` function
- **realm**: Processed through `NormalizeRealm()` which:
  1. Inserts `-` before each uppercase letter (except the first)
  2. Lowercases the result
  - Example: `ВечнаяПесня` → `вечная-песня`, `Гордунни` → `гордунни`, `Ревущийфьорд` → `ревущий-фьорд`

This normalization ensures deduplication works correctly across sources (e.g., WHO handler's `FindPlayerInDB` lookup matches already-known players).

### WHO Handler Deduplication

The `WHO_LIST_UPDATE` handler uses `FindPlayerInDB(name, realm)` to skip players already in the database. This prevents duplicate entries with different GUID prefixes (e.g., `WHO-Name` vs `Player-XXXX-XXXX`). The lookup compares lowercased `name` + normalized `realm` fields.

### WoW-Specific Patterns

- Register events on a frame with `RegisterEvent()` then handle in `SetScript("OnEvent", ...)`
- Always check `ADDON_LOADED` event matches your addon name: `(...) == addonName`
- Use `BackdropTemplate` for frames with backdrops (WoW 9.0+ requirement)
- Make frames draggable via `SetMovable`, `RegisterForDrag`, `OnDragStart`/`OnDragStop`
- Use `SetScript("OnKeyDown")` with ESC to close popup frames
- Define slash commands via `SLASH_<NAME><N>` and `SlashCmdList["<NAME>"]`
- Use WoW color escape sequences: `|cffRRGGBBtext|r`
- Use `tinsert(UISpecialFrames, "FrameName")` for ESC to close functionality

### Disabled / Commented-Out Code

- Wrap disabled debug code in `--[[ ... --]]` block comments
- Add a label above the block indicating what it is:
  ```lua
  --[[ Full unit debug dump (disabled)
  local function DebugDumpUnit(...)
  ...
  end
  --]]
  ```

**Block Comment Pitfall:** `--[[ ... --]]` removes the function **definition** but NOT any **references** to it. If a disabled function `Foo()` is wrapped and code elsewhere still calls `pcall(Foo, ...)`, it will error with "attempt to call a nil value" at runtime. **Both the definition AND all call sites must be removed or commented out together.**

## Git Conventions

- Conventional commits: `git commit -m"<type>(<scope>): <description>"`
- Lowercased messages, no description body
- Split by logical change — never mix refactoring with features or bug fixes
- Types: `feat`, `fix`, `refactor`, `chore`, `docs`

## Environment-Specific Notes

- **File editing:** Always re-read a file before editing — the user frequently modifies files externally in an IDE. Avoid overwriting their unsaved changes.
- **Git operations:** Use the `task` tool with a `general` subagent for all git operations (`git add`, `git commit`, `git tag`, etc.).
- **SavedVariables:** Do NOT attempt to batch-edit the SavedVariables file with PowerShell regex scripts — the bash tool passes `$_.Groups` incorrectly to PowerShell, causing catastrophic file corruption. If SavedVariables need bulk changes, write a standalone `.ps1` script file first, then execute it.
- **Reload after code changes:** After modifying `Core.lua`, the user must `/reload` in-game for changes to take effect. Existing in-memory data is preserved across reloads; SavedVariables are re-read from disk.

## Testing Policy

- Do not add tests unless explicitly requested
- No test framework is configured; testing requires a WoW runtime environment

## Useful Links

- [WoW API Reference (wowpedia)](https://wowpedia.fandom.com/wiki/World_of_Warcraft_API)
- [WoW API Reference (wowprogramming)](https://wowprogramming.com/docs/api)
- [WoW AddOn Best Practices](https://wowpedia.fandom.com/wiki/AddOn_best_practices)
- [COMBAT_LOG_EVENT_UNFILTERED](https://wowpedia.fandom.com/wiki/COMBAT_LOG_EVENT_UNFILTERED)
- [GetPlayerInfoByGUID](https://wowpedia.fandom.com/wiki/API_GetPlayerInfoByGUID)
- [C_FriendList.GetWhoInfo](https://wowpedia.fandom.com/wiki/API_C_FriendList.GetWhoInfo)
- [SavedVariables](https://wowpedia.fandom.com/wiki/SavedVariables)
- [luacheck](https://github.com/luarocks/luacheck)
- [WoW UI Escape Sequences](https://wowpedia.fandom.com/wiki/UI_escape_sequences)
- [String.format patterns](https://www.lua.org/manual/5.1/manual.html#pdf-string.format)
