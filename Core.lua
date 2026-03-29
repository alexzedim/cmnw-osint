local addonName, ns = ...

--[[
    CMNW-OSINT
    Captures player target data: guid, name, realm, level, faction
    Exports to clipboard as JSON via /cmnw export
    Data persisted to SavedVariables for external reading
]]

-- ============================================
-- INITIALIZATION
-- ============================================

local function OnInitialize()
    if not CMNWOSINT_DB then
        CMNWOSINT_DB = {}
    end
end

-- ============================================
-- DATA COLLECTION
-- ============================================

local function CollectTargetData()
    local unit = "target"

    -- Only process players, not NPCs/mobs
    if not UnitExists(unit) or not UnitIsPlayer(unit) then
        return nil
    end

    local guid       = UnitGUID(unit)
    local name, realm = UnitName(unit)
    local level      = UnitLevel(unit)
    local faction    = UnitFactionGroup(unit)

    -- UnitName returns nil for realm if same realm; fill with current realm
    if not realm or realm == "" then
        realm = GetRealmName()
    end

    return {
        guid    = guid,
        name    = name,
        realm   = realm,
        level   = level,
        faction = faction,
        lastModified = date("!%Y-%m-%dT%H:%M:%SZ"), -- ISO 8601 UTC timestamp
    }
end

-- ============================================
-- DEBUG PRINT
-- ============================================

local function DebugPrint(data)
    print("|cff00ff00[CMNW-OSINT]|r Target captured:")
    print("  |cffffd700  GUID:|r    " .. tostring(data.guid))
    print("  |cffffd700  Name:|r    " .. tostring(data.name))
    print("  |cffffd700  Realm:|r   " .. tostring(data.realm))
    print("  |cffffd700  Level:|r   " .. tostring(data.level))
    print("  |cffffd700  Faction:|r " .. tostring(data.faction))
    print("  |cffffd700  Modified:|r    " .. tostring(data.lastModified))
end

-- ============================================
-- DATABASE
-- ============================================

local function SaveToDB(data)
    -- Key by GUID -- overwrites if same player seen again
    CMNWOSINT_DB[data.guid] = data
end

-- ============================================
-- EXPORT (JSON to clipboard)
-- ============================================

local function EscapeJSON(str)
    if not str then return "" end
    str = str:gsub("\\", "\\\\")
    str = str:gsub("\"", "\\\"")
    str = str:gsub("\n", "\\n")
    str = str:gsub("\r", "\\r")
    str = str:gsub("\t", "\\t")
    return str
end

local function ExportJSON()
    local entries = {}
    for guid, data in pairs(CMNWOSINT_DB) do
        local entry = string.format(
            '  {"guid":"%s","name":"%s","realm":"%s","level":%s,"faction":"%s","lastModified":"%s"}',
            EscapeJSON(data.guid),
            EscapeJSON(data.name),
            EscapeJSON(data.realm),
            tostring(data.level or 0),
            EscapeJSON(data.faction),
            EscapeJSON(data.lastModified)
        )
        table.insert(entries, entry)
    end

    local json
    if #entries > 0 then
        json = "[\n" .. table.concat(entries, ",\n") .. "\n]"
    else
        json = "[]"
    end

    Clipboard:SetText(json)
    print("|cff00ff00[CMNW-OSINT]|r JSON copied to clipboard (" .. #entries .. " entries)")
end

-- ============================================
-- SLASH COMMANDS
-- ============================================

SLASH_CMNWOSINT1 = "/cmnw"
SLASH_CMNWOSINT2 = "/osint"
SlashCmdList["CMNWOSINT"] = function(msg)
    msg = msg and msg:lower() or ""
    if msg == "export" then
        ExportJSON()
    elseif msg == "clear" then
        CMNWOSINT_DB = {}
        print("|cff00ff00[CMNW-OSINT]|r Database cleared.")
    elseif msg == "count" then
        local c = 0
        for _ in pairs(CMNWOSINT_DB) do c = c + 1 end
        print("|cff00ff00[CMNW-OSINT]|r " .. c .. " players in database.")
    else
        print("|cff00ff00[CMNW-OSINT]|r Commands:")
        print("  |cffffd700/cmnw export|r -- Copy JSON to clipboard")
        print("  |cffffd700/cmnw clear|r  -- Clear database")
        print("  |cffffd700/cmnw count|r  -- Show entry count")
    end
end

-- ============================================
-- EVENT HANDLING
-- ============================================

local EventFrame = CreateFrame("Frame")

EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")

EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and (...) == addonName then
        OnInitialize()
        print("|cff00ff00[CMNW-OSINT]|r Loaded. Target a player to collect data.")
    elseif event == "PLAYER_TARGET_CHANGED" then
        local data = CollectTargetData()
        if data then
            DebugPrint(data)
            SaveToDB(data)
        end
    end
end)
