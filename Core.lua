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
    local faction    = UnitFactionGroup(unit) or "Unknown"

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

local lastCaptured = nil

local function DebugPrint(data)
    lastCaptured = data
    print("|cff00ff00[CMNW-OSINT]|r Target captured:")
    print("  |cffffd700  GUID:|r    " .. tostring(data.guid))
    print("  |cffffd700  Name:|r    " .. tostring(data.name))
    print("  |cffffd700  Realm:|r   " .. tostring(data.realm))
    print("  |cffffd700  Level:|r   " .. tostring(data.level))
    print("  |cffffd700  Faction:|r " .. tostring(data.faction))
    print("  |cffffd700  LastModified:|r    " .. tostring(data.lastModified))
end

local function SayLastCaptured()
    if not lastCaptured then
        print("|cff00ff00[CMNW-OSINT]|r No captured target yet.")
        return
    end
    local d = lastCaptured
    SendChatMessage("[CMNW-OSINT] GUID: " .. tostring(d.guid), "SAY")
    SendChatMessage("[CMNW-OSINT] Name: " .. tostring(d.name), "SAY")
    SendChatMessage("[CMNW-OSINT] Realm: " .. tostring(d.realm), "SAY")
    SendChatMessage("[CMNW-OSINT] Level: " .. tostring(d.level), "SAY")
    SendChatMessage("[CMNW-OSINT] Faction: " .. tostring(d.faction), "SAY")
    SendChatMessage("[CMNW-OSINT] LastModified: " .. tostring(d.lastModified), "SAY")
end

--[[ Full unit debug dump ]]
local function DebugDumpUnit(unit)
    if not UnitExists(unit) then return end

    local GREEN = "|cff55ff55"
    local CYAN  = "|cff55ffff"
    local RST   = "|r"

    local exists     = UnitExists(unit)
    local isPlayer   = UnitIsPlayer(unit)
    local guid       = UnitGUID(unit)
    local name, realm = UnitName(unit)
    local sameServer = UnitIsSameServer(unit)

    local level          = UnitLevel(unit)
    local effectiveLevel = UnitEffectiveLevel(unit)
    local playerControl  = UnitPlayerControlled(unit)
    local playerOrPet    = UnitPlayerOrPetInGroup(unit)
    local classification = UnitClassification(unit)
    local enClass, classFile, classIndex = UnitClass(unit)
    local enRace, raceFile, raceIndex    = UnitRace(unit)
    local sex    = UnitSex(unit)
    local sexStr = sex == 1 and "Male" or sex == 2 and "Female" or sex == 3 and "Neuter" or tostring(sex)
    local factionGroup = UnitFactionGroup(unit)
    local reaction     = UnitReaction(unit, "player")
    local reactionStr  = reaction and ("%d |cff888888(%s)"):format(reaction,
        reaction == 1 and "Hated" or reaction == 2 and "Hostile" or reaction == 3 and "Unfriendly" or
        reaction == 4 and "Neutral" or reaction == 5 and "Friendly" or reaction == 6 and "Honored" or
        reaction == 7 and "Revered" or reaction == 8 and "Exalted" or "Unknown") or "nil"

    local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo(unit)

    local guidType, guidServerID, guidDbID, guidGuidLo, guidGuidHi
    if guid then
        guidType, guidServerID, guidDbID, guidGuidLo, guidGuidHi = strsplit("-", guid)
    end

    print("\n" .. GREEN .. "========== UNIT DUMP: " .. unit .. " ==========" .. RST)

    print(CYAN .. "--- Identity ---" .. RST)
    print("  UnitExists:       " .. tostring(exists))
    print("  UnitIsPlayer:     " .. tostring(isPlayer))
    print("  UnitGUID:         " .. tostring(guid))
    print("  UnitName:         " .. tostring(name) .. " |cff888888(realm: " .. tostring(realm) .. ")" .. RST)
    print("  UnitIsSameServer: " .. tostring(sameServer))

    print(CYAN .. "--- Character Info ---" .. RST)
    print("  UnitLevel:           " .. tostring(level))
    print("  UnitEffectiveLevel:  " .. tostring(effectiveLevel))
    print("  UnitPlayer:          " .. tostring(playerControl))
    print("  UnitPlayerOrPet:     " .. tostring(playerOrPet))
    print("  UnitClassification:  " .. tostring(classification))
    print("  UnitClass:           " .. tostring(enClass) .. " |cff888888(file: " .. tostring(classFile) .. ", index: " .. tostring(classIndex) .. ")" .. RST)
    print("  UnitRace:            " .. tostring(enRace) .. " |cff888888(file: " .. tostring(raceFile) .. ", index: " .. tostring(raceIndex) .. ")" .. RST)
    print("  UnitSex:             " .. tostring(sexStr) .. " (" .. tostring(sex) .. ")")
    print("  UnitFactionGroup:    " .. tostring(factionGroup))
    print("  UnitReaction:        " .. reactionStr)

    print(CYAN .. "--- Guild / Social ---" .. RST)
    print("  GetGuildInfo:         " .. tostring(guildName) ..
        " |cff888888(rank: " .. tostring(guildRankName) ..
        ", index: " .. tostring(guildRankIndex) ..
        ", realm: " .. tostring(guildRealm) .. ")" .. RST)

    if guid then
        print(CYAN .. "--- GUID Parsed ---" .. RST)
        print("  Raw parts:     type=" .. tostring(guidType) ..
            " serverID=" .. tostring(guidServerID) ..
            " dbID=" .. tostring(guidDbID) ..
            " guidLo=" .. tostring(guidGuidLo) ..
            " guidHi=" .. tostring(guidGuidHi))
    end

    print(GREEN .. "==========================================" .. RST .. "\n")
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
    elseif msg == "say" then
        SayLastCaptured()
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
        print("  |cffffd700/cmnw say|r   -- Say last capture in /say")
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
        pcall(DebugDumpUnit, "target")
        C_Timer.After(0.5, function()
            local data = CollectTargetData()
            if data then
                DebugPrint(data)
                SaveToDB(data)
            end
        end)
    end
end)
