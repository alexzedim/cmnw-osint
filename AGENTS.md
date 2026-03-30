# AGENTS.md — CMNW-OSINT

## Project Overview

World of Warcraft addon that collects player target intelligence data (guid, name, realm, level, race, class, guild, etc.) and exports it as JSON. Written in pure Lua for the WoW API. Licensed under MPL-2.0.

## Build / Lint / Test

This is a WoW addon — there is no build step, bundler, or package manager. Files are loaded directly by the WoW client via the `.toc` manifest.

- **No build command** — drop files into `Interface\AddOns\CMNW-OSINT\`
- **No linter configured** — optionally use [luacheck](https://github.com/luarocks/luacheck) with a WoW-compatible std definition
- **No tests** — testing requires an in-game WoW environment or a WoW API mock framework
- **Lint (optional):** `luacheck Core.lua --std wow`

### WoW API Stub for Static Analysis

If using luacheck, create a `.luacheckrc` that defines WoW globals:

```lua
stds.wow = {
  read_globals = {
    "UnitExists", "UnitIsPlayer", "UnitGUID", "UnitName", "UnitLevel",
    "UnitFactionGroup", "UnitRace", "UnitClass", "UnitSex", "GetGuildInfo",
    "GetRealmName", "CreateFrame", "SendChatMessage", "date", "strsplit",
    "pairs", "tostring", "print", "table", "string", "SlashCmdList",
    "UIParent", "GameFontNormal", "GameFontNormalLarge",
    "UIPanelScrollFrameTemplate", "UIPanelCloseButton", "BackdropTemplate",
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

## Code Style Guidelines

### General

- Single-file addon; all logic lives in `Core.lua`
- Use `local` for all variables and functions — never pollute the global namespace
- Wrap the addon in `local addonName, ns = ...` at the top of every file
- No external dependencies or libraries

### Naming Conventions

- **Variables:** `camelCase` — e.g., `guildRankName`, `lastCaptured`, `exportFrame`
- **Functions:** `PascalCase` — e.g., `OnInitialize`, `CollectTargetData`, `DebugPrint`, `SaveToDB`, `ExportJSON`
- **Constants / color codes:** `UPPER_CASE` for local color tokens (e.g., `GREEN`, `CYAN`, `RST` in debug code)
- **WoW globals / API:** Preserve Blizzard's naming — `UnitGUID`, `CreateFrame`, `SlashCmdList`, etc.
- **SavedVariables:** Use the `_DB` suffix — `CMNWOSINT_DB`
- **Slash command IDs:** `UPPER_CASE` with numeric suffix — `SLASH_CMNWOSINT1`, `SLASH_CMNWOSINT2`
- **Frame names:** Use addon prefix — `CMNWOSINT_ExportFrame`
- **Addon chat prefix:** `[CMNW-OSINT]` with green color `|cff00ff00`
- **Label color:** Gold `|cffffd700` for field names in chat output

### Formatting

- 4-space indentation, no tabs
- Alignment of variable assignments with spaces — align `=` signs in blocks:
  ```lua
  local guid       = UnitGUID(unit)
  local name, realm = UnitName(unit)
  local level      = UnitLevel(unit)
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
2. Data Collection
3. Debug / Print helpers
4. Database persistence
5. Export (JSON, UI)
6. Slash commands
7. Event handling (last — registers events and sets scripts)

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

### Tables & Data

- Use flat tables keyed by GUID for the database: `CMNWOSINT_DB[data.guid] = data`
- Return structured tables from data collection functions with named keys
- Use `string.format()` for JSON serialization; `table.concat()` for joining entries
- Use `pairs()` for iterating the database

### WoW-Specific Patterns

- Register events on a frame with `RegisterEvent()` then handle in `SetScript("OnEvent", ...)`
- Always check `ADDON_LOADED` event matches your addon name: `(...) == addonName`
- Use `BackdropTemplate` for frames with backdrops (WoW 9.0+ requirement)
- Make frames draggable via `SetMovable`, `RegisterForDrag`, `OnDragStart`/`OnDragStop`
- Use `SetScript("OnKeyDown")` with ESC to close popup frames
- Define slash commands via `SLASH_<NAME><N>` and `SlashCmdList["<NAME>"]`
- Use WoW color escape sequences: `|cffRRGGBBtext|r`

### Disabled / Commented-Out Code

- Wrap disabled debug code in `--[[ ... --]]` block comments
- Add a label above the block indicating what it is (e.g., `--[[ Full unit debug dump (disabled)`)

#### Block Comment Pitfall

`--[[ ... --]]` removes the function **definition** but NOT any **references** to it. If a disabled function `Foo()` is wrapped in `--[[ --]]` and code elsewhere still calls `pcall(Foo, ...)`, it will error with "attempt to call a nil value" at runtime. **Both the definition AND all call sites must be removed or commented out together.**

## Git Conventions

- Conventional commits: `git commit -m"<type>(<scope>): <description>"`
- Lowercased messages, no description body
- Split by logical change — never mix refactoring with features or bug fixes
- Types: `feat`, `fix`, `refactor`, `chore`, `docs`

## Environment-Specific Notes

- **File editing:** Always re-read a file before editing — the user frequently modifies files externally in an IDE. Avoid overwriting their unsaved changes.
- **Git operations:** The `bash` tool is unreliable in this environment. Use the `task` tool with a `general` subagent for all git operations (`git add`, `git commit`, `git tag`, etc.).

## Testing Policy

- Do not add tests unless explicitly requested
- No test framework is configured; testing requires a WoW runtime environment
