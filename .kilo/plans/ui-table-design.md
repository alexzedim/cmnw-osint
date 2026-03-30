# Plan: Add Main UI Frame with Table + Counter

## Summary

Replace `/cmnw [command]` subcommands with two toggle commands (`on`/`off`) and build a visual main frame with a player counter above a scrollable table. Move Export and Clear into UI buttons. Remove `say` and `count` commands (count displayed as counter in UI).

## Slash Command Changes

**Before:**
```
/cmnw export  — Copy JSON to clipboard
/cmnw say     — Say last capture in /say
/cmnw clear   — Clear database
/cmnw count   — Show entry count
```

**After:**
```
/cmnw on      — Show the main UI frame
/cmnw off     — Hide the main UI frame
/cmnw         — Toggle frame (show if hidden, hide if shown)
```

`/osint` alias preserved as toggle-only.

`say` command removed. `export` and `clear` become UI buttons. `count` is the counter label.

## UI Layout

```
+============================================================+
| CMNW-OSINT                                            [X]  |
+------------------------------------------------------------+
| Players: 42                        [Export JSON] [Clear DB] |
+------+------+-------+-----+------+------+-----+------+-----+
|  #   | Name | Realm | Lvl | Class| Race | Fac | Guild| Src |
+------+------+-------+-----+------+------+-----+------+-----+
|  1   | John | Azral | 80  | Mage | Human| A   | <WP> | TGT |  ▲
|  2   | Jane | Azral | 70  | Lock | Orc  | H   | <IO> | CHT |  |
|  3   | ...                                                         |
|  4   | ...                                                         |
|  5   | ...                                                    ▼    |
+------+-------+-------+-----+------+------+-----+------+-----+
```

### Frame Specifications

- **Name:** `CMNWOSINT_MainFrame`
- **Size:** 740 x 460 (fits 18 visible rows)
- **Parent:** `UIParent`
- **Backdrop:** `UI-DialogBox-Background` + `UI-DialogBox-Border`
- **Movable:** yes, drag by title area
- **Strata:** `DIALOG`
- **ESC close:** registered via `tinsert(UISpecialFrames, ...)`
- **Hidden by default** on load

### Component Breakdown

#### 1. Title Bar (top)
- Left-aligned: addon title "CMNW-OSINT" in `GameFontNormalLarge`
- Right-aligned: `UIPanelCloseButton`

#### 2. Toolbar Row (below title)
- Left: counter FontString `"Players: X"` in `GameFontHighlight`
- Right: two `UIPanelButtonTemplate` buttons
  - "Export JSON" — calls existing `ExportJSON()`
  - "Clear DB" — clears `CMNWOSINT_DB` and refreshes table

#### 3. Column Header Row
- 9 columns as FontStrings with `GameFontNormal`:
  - `#` (28px), `Name` (100px), `Realm` (90px), `Lvl` (34px), `Class` (72px), `Race` (72px), `Fac` (42px), `Guild` (100px), `Src` (72px)
- Horizontal divider line below headers (Texture)

#### 4. Scroll Area (FauxScrollFrame)
- `FauxScrollFrameTemplate` for virtual scrolling
- 18 visible row buttons at 18px height each
- Each row is a Button with 9 FontString children
- Alternating row background (Texture with `*` highlight)
- OnVerticalScroll calls `FauxScrollFrame_OnVerticalScroll(self, offset, 18, CMNWOSINT_UpdateTable)`
- Scrollbar positioned on right edge

#### 5. Row Button Template
- Virtual Button at 18px height
- 9 FontString children for column values
- `HighlightTexture` for mouseover effect
- Stores `guid` in `self.guid` for potential click interaction
- Row background texture toggles between two shades for readability

### Column Mappings

| Column | Data Field        | Width | Alignment |
|--------|-------------------|-------|-----------|
| #      | row index         | 28    | CENTER    |
| Name   | data.name         | 100   | LEFT      |
| Realm  | data.realm        | 90    | LEFT      |
| Lvl    | data.level or "-" | 34    | CENTER    |
| Class  | data.className    | 72    | LEFT      |
| Race   | data.raceName     | 72    | LEFT      |
| Fac    | data.faction      | 42    | CENTER    |
| Guild  | data.guild or "-" | 100   | LEFT      |
| Src    | source short tag  | 72    | CENTER    |

### Source Tag Display

Map `createdBy` to short display text:

| createdBy           | Display |
|---------------------|---------|
| OSINT-CHARACTER-GET | TGT     |
| OSINT-CHAT-GET      | CHT     |
| OSINT-CLEU-GET      | CLEU    |
| OSINT-NAMEPLATE-GET | NPL     |

## Implementation Approach

All UI creation in a new function `CreateMainFrame()` called once on `ADDON_LOADED`. The function builds the entire frame hierarchy programmatically via `CreateFrame()` calls (consistent with existing `CreateExportFrame()` pattern — no XML files).

### New Functions

```
CreateMainFrame()          — builds frame, title, toolbar, header, scroll area, row buttons
CMNWOSINT_UpdateTable()    — FauxScrollFrame update callback; populates visible rows from DB
CMNWOSINT_UpdateCounter()  — updates "Players: X" FontString
```

### Modified Functions

```
SlashCmdList handler       — replace subcommand dispatch with on/off/toggle
OnInitialize()             — call CreateMainFrame() after DB init
```

### Removed Functions/Code

```
SayLastCaptured()          — removed entirely
lastCaptured variable      — removed
```

### New Slash Command Flow

```lua
SLASH_CMNWOSINT1 = "/cmnw"
SLASH_CMNWOSINT2 = "/osint"
SlashCmdList["CMNWOSINT"] = function(msg)
    msg = msg and msg:lower() or ""
    if msg == "on" then
        CMNWOSINT_MainFrame:Show()
    elseif msg == "off" then
        CMNWOSINT_MainFrame:Hide()
    else
        if CMNWOSINT_MainFrame:IsShown() then
            CMNWOSINT_MainFrame:Hide()
        else
            CMNWOSINT_MainFrame:Show()
        end
    end
end
```

### OnShow / OnHide Behavior

- `OnShow`: calls `CMNWOSINT_UpdateTable()` and `CMNWOSINT_UpdateCounter()`
- New DB inserts while frame is visible: call `CMNWOSINT_UpdateTable()` + `CMNWOSINT_UpdateCounter()` to refresh

### DB Change Notification

In `SaveToDB()`, after a successful insert, if the main frame is shown, trigger a refresh:

```lua
local function SaveToDB(data)
    if CMNWOSINT_DB[data.guid] then
        return false
    end
    CMNWOSINT_DB[data.guid] = data
    if mainFrame and mainFrame:IsShown() then
        CMNWOSINT_UpdateCounter()
        CMNWOSINT_UpdateTable()
    end
    return true
end
```

## Section Order in Core.lua

1. Initialization
2. Helpers
3. Data Collection
4. Debug / Print helpers (DebugPrint, DebugPrintSource)
5. Database persistence (SaveToDB — with UI refresh hook)
6. **UI — Main Frame** (new section — CreateMainFrame, CMNWOSINT_UpdateTable, CMNWOSINT_UpdateCounter)
7. Export (JSON, UI — CreateExportFrame stays)
8. Slash commands (rewritten — on/off/toggle)
9. Event handling

## Commits

1. `feat(ui): add main frame with scrollable table and counter`
   — CreateMainFrame, CMNWOSINT_UpdateTable, CMNWOSINT_UpdateCounter, toolbar with Export/Clear buttons

2. `feat(cmd): replace slash commands with on/off toggle`
   — Rewrite SlashCmdList handler, remove say/count commands, keep /cmnw on|off|toggle

3. `refactor(core): remove SayLastCaptured and lastCaptured`
   — Clean up dead code from removed say command
