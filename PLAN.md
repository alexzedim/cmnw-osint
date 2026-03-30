# Plan: ElvUI-Style UI + Full Data Model

## Overview

Two changes to `Core.lua`:
1. **Restyle all frames** to match ElvUI's dark pixel-border aesthetic
2. **Add a detail panel** showing all 20 JSON fields when a row is selected

No new files needed. No new dependencies.

---

## ElvUI Visual Constants

Extracted from ElvUI source (`Toolkit.lua`, `Install.lua`, `Core.lua`):

| Property | Value |
|---|---|
| Blank texture | `Interface\\Buttons\\WHITE8x8` (WoW built-in) |
| Backdrop color | `0.1, 0.1, 0.1, 1` (opaque dark gray) |
| Border color | `0.1, 0.1, 0.1, 1` |
| Transparent backdrop | `0.054, 0.054, 0.054, 0.8` |
| Row stripe even | `SetColorTexture(1, 1, 1, 0.03)` |
| Row stripe odd | `SetColorTexture(1, 1, 1, 0.01)` |
| Row highlight | `SetColorTexture(1, 1, 1, 0.06)` on hover |
| Row selected | `SetColorTexture(0.09, 0.51, 0.82, 0.15)` (ElvUI value blue) |
| Button highlight | `SetColorTexture(1, 1, 1, 0.3)` blend ADD |
| Button pushed | `SetColorTexture(0.9, 0.8, 0.1, 0.3)` blend ADD |
| Pixel border edge size | `1` |
| Label color | Gold `|cffffd700` for field names (already used) |
| Value color | White (default font color) |

---

## Changes to Core.lua

### 1. New constants at top of UI section (~line 340)

Add a shared backdrop table constant and a `BLANK_TEX` path:

```lua
local BLANK_TEX = "Interface\\Buttons\\WHITE8x8"

local ELVUI_BACKDROP = {
    bgFile   = BLANK_TEX,
    edgeFile = BLANK_TEX,
    edgeSize = 1,
}
```

### 2. Helper: `CreateElvUIButton(parent, text, width, height)` (~new, before CreateMainFrame)

Creates a button with ElvUI pixel-border styling:
- Backdrop with `ELVUI_BACKDROP`, color `0.1, 0.1, 0.1, 1`
- FontString overlay with the button text
- Highlight texture: white `0.3` alpha, blend ADD
- Pushed texture: gold `0.3` alpha, blend ADD
- Returns the button frame

### 3. Helper: `CreateElvUICloseButton(parent)` (~new)

- 16x16 button at TOPRIGHT `(-6, -6)`
- Backdrop with `ELVUI_BACKDROP`
- FontString "X" centered
- OnEnter: set text to ElvUI value blue
- OnLeave: set text to white
- OnClick: hide parent

### 4. Restructure `CreateMainFrame()` (~line 343)

**Frame size**: `960 x 500` (wider to accommodate detail panel)

**Backdrop**: Replace `UI-DialogBox-Background` / `UI-DialogBox-Border` with:
```lua
f:SetBackdrop(ELVUI_BACKDROP)
f:SetBackdropColor(0.1, 0.1, 0.1, 1)
f:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
```

**Layout**: Split into two regions:
- Left (~620px): scrollable table (same key columns as now)
- Right (~320px): detail panel

**Close button**: Replace `UIPanelCloseButton` with `CreateElvUICloseButton(f)`

**Action buttons**: Replace `UIPanelButtonTemplate` with `CreateElvUIButton`

**Table section**: Same column structure (keep existing columns `#, Name, Realm, Lvl, Class, Race, Fac, Guild, Src`), same scroll mechanism.

**Row selection behavior**: On row click, set `selectedEntry` and update detail panel. Highlight selected row with blue tint.

### 5. Detail panel (inside `CreateMainFrame`, new code)

Positioned on the right side of the frame:

```
+--DETAIL PANEL (320px)--+
| (no selection text)    |  <- when nothing selected
+------------------------+

or

+--DETAIL PANEL (320px)--+
| GUID          Player-..|  <- scrollable
| ID            12345    |
| RealmID       5678     |
| Name          Player   |
| Realm         Realm    |
| Level         80       |
| Faction       Horde    |
| Race          5        |
| RaceName      Undead   |
| Class         9        |
| ClassName     Warlock  |
| ClassFile     WARLOCK  |
| Gender        Male     |
| Guild         MyGuild  |
| GuildRank     3        |
| GuildRankName  Officer |
| Status        ------   |
| CreatedBy     OSINT... |
| UpdatedBy     OSINT... |
| LastModified  2025-... |
+------------------------+
```

Implementation:
- Create a ScrollFrame + ScrollBar on the right side
- 20 rows, each with two FontStrings (label: gold, value: white)
- All 20 JSON field labels in a fixed array:
  ```lua
  local DETAIL_FIELDS = {
      { key = "guid",          label = "GUID" },
      { key = "id",            label = "ID" },
      { key = "realmId",       label = "Realm ID" },
      { key = "name",          label = "Name" },
      { key = "realm",         label = "Realm" },
      { key = "level",         label = "Level" },
      { key = "faction",       label = "Faction" },
      { key = "race",          label = "Race" },
      { key = "raceName",      label = "Race Name" },
      { key = "class",         label = "Class" },
      { key = "className",     label = "Class Name" },
      { key = "classFile",     label = "Class File" },
      { key = "gender",        label = "Gender" },
      { key = "guild",         label = "Guild" },
      { key = "guildRank",     label = "Guild Rank" },
      { key = "guildRankName", label = "Guild Rank Name" },
      { key = "status",        label = "Status" },
      { key = "createdBy",     label = "Created By" },
      { key = "updatedBy",     label = "Updated By" },
      { key = "lastModified",  label = "Last Modified" },
  }
  ```
- New function `UpdateDetailPanel(entry)` called when a row is clicked

### 6. New state variable

```lua
local selectedEntry = nil
local detailFontStrings = {}  -- { {label, value}, ... }
local noSelectionText = nil   -- "Select a row..." placeholder
```

### 7. Row click handler (in `CMNWOSINT_UpdateTable`)

For each row button, add `OnClick`:
```lua
row:SetScript("OnClick", function()
    selectedEntry = entry
    UpdateDetailPanel(entry)
end)
```

### 8. `UpdateDetailPanel(entry)` (~new function)

Iterates `DETAIL_FIELDS`, sets label/value font strings from the entry data. Shows "Select a player to view details" when `entry` is nil.

### 9. Restyle `CreateExportFrame()` (~line 472)

Same ElvUI styling:
- Replace `UI-DialogBox-Background` / `UI-DialogBox-Border` with `ELVUI_BACKDROP`
- Same backdrop/border colors as main frame
- Replace `UIPanelCloseButton` with `CreateElvUICloseButton`
- Replace `UIPanelScrollFrameTemplate` with a custom scrollbar or keep the template (it's internal, less visible)
- Use `BLANK_TEX` texture for editbox background tinting

### 10. Divider between table and detail panel

A 1px vertical texture inside the main frame:
```lua
local divider = f:CreateTexture(nil, "ARTWORK")
divider:SetWidth(1)
divider:SetPoint("TOPLEFT", tableArea, "TOPRIGHT", 0, 0)
divider:SetPoint("BOTTOMRIGHT", detailArea, "BOTTOMLEFT", 0, 0)
divider:SetColorTexture(0.1, 0.1, 0.1, 1)
```

---

## Summary of New/Modified Functions

| Function | Change |
|---|---|
| `CreateElvUIButton` | **New** — reusable ElvUI-style button factory |
| `CreateElvUICloseButton` | **New** — reusable ElvUI-style close button factory |
| `CreateMainFrame` | **Modify** — ElvUI backdrop, layout restructure, detail panel, row click selection |
| `UpdateDetailPanel` | **New** — populates detail panel from entry data |
| `CMNWOSINT_UpdateTable` | **Modify** — add OnClick handlers to rows, highlight selected row |
| `CreateExportFrame` | **Modify** — ElvUI backdrop styling |

## Constants/Lookup Tables Added

| Name | Purpose |
|---|---|
| `BLANK_TEX` | Path to `Interface\\Buttons\\WHITE8x8` |
| `ELVUI_BACKDROP` | Shared backdrop table for all frames |
| `DETAIL_FIELDS` | Ordered list of `{key, label}` for all 20 JSON fields |

## Files Modified

- `Core.lua` — all changes
- `CMNW-OSINT.toc` — no changes
- `AGENTS.md` — no changes

## Section Organization (per AGENTS.md)

New helpers (`CreateElvUIButton`, `CreateElvUICloseButton`, `BLANK_TEX`, `ELVUI_BACKDROP`, `DETAIL_FIELDS`) go at the top of the UI section, before `CreateMainFrame`. The detail panel update function goes alongside `CMNWOSINT_UpdateTable`.
