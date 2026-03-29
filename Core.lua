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

--[[ Full unit debug dump ]]
local function DebugDumpUnit(unit)
    if not UnitExists(unit) then return end

    local RED   = "|cffff5555"
    local GREEN = "|cff55ff55"
    local YELLOW = "|cffffff55"
    local CYAN  = "|cff55ffff"
    local WHITE = "|cffffffff"
    local RST   = "|r"

    print("\n" .. GREEN .. "========== UNIT DUMP: " .. unit .. " ==========" .. RST)

    -- Identity
    print(CYAN .. "--- Identity ---" .. RST)
    print("  UnitExists:     " .. tostring(UnitExists(unit)))
    print("  UnitIsPlayer:   " .. tostring(UnitIsPlayer(unit)))
    print("  UnitGUID:       " .. tostring(UnitGUID(unit)))
    local name, realm = UnitName(unit)
    print("  UnitName:       " .. tostring(name) .. " |cff888888(realm: " .. tostring(realm) .. ")" .. RST)
    print("  UnitIsSameServer: " .. tostring(UnitIsSameServer(unit)))
    print("  UnitIsDead:       " .. tostring(UnitIsDead(unit)))
    print("  UnitIsGhost:      " .. tostring(UnitIsGhost(unit)))

    -- Classification / Relations
    print(CYAN .. "--- Classification ---" .. RST)
    print("  UnitCanAttack:    " .. tostring(UnitCanAttack(unit, "player")))
    print("  UnitCanCooperate: " .. tostring(UnitCanCooperate(unit, "player")))
    print("  UnitIsEnemy:      " .. tostring(UnitIsEnemy(unit, "player")))
    print("  UnitIsFriend:     " .. tostring(UnitIsFriend(unit, "player")))
    print("  UnitIsPVP:        " .. tostring(UnitIsPVP(unit)))
    print("  UnitIsPVPFlagged: " .. tostring(UnitIsPVPFlagged(unit)))
    print("  UnitIsInGroup:    " .. tostring(UnitIsInGroup(unit)))
    print("  UnitIsInRaid:     " .. tostring(UnitIsInRaid(unit)))
    print("  UnitIsUnit:       " .. tostring(UnitIsUnit(unit, "player")))

    -- Character Info
    print(CYAN .. "--- Character Info ---" .. RST)
    print("  UnitLevel:           " .. tostring(UnitLevel(unit)))
    print("  UnitEffectiveLevel:  " .. tostring(UnitEffectiveLevel(unit)))
    print("  UnitPlayer:          " .. tostring(UnitPlayerControlled(unit)))
    print("  UnitPlayerOrPet:     " .. tostring(UnitPlayerOrPetInGroup(unit)))
    print("  UnitClassification:  " .. tostring(UnitClassification(unit)))
    local enClass, classFile, classIndex = UnitClass(unit)
    print("  UnitClass:           " .. tostring(enClass) .. " |cff888888(file: " .. tostring(classFile) .. ", index: " .. tostring(classIndex) .. ")" .. RST)
    local enRace, raceFile, raceIndex = UnitRace(unit)
    print("  UnitRace:            " .. tostring(enRace) .. " |cff888888(file: " .. tostring(raceFile) .. ", index: " .. tostring(raceIndex) .. ")" .. RST)
    local sex = UnitSex(unit)
    local sexStr = sex == 1 and "Male" or sex == 2 and "Female" or sex == 3 and "Neuter" or tostring(sex)
    print("  UnitSex:             " .. tostring(sexStr) .. " (" .. tostring(sex) .. ")")
    print("  UnitFactionGroup:   " .. tostring(UnitFactionGroup(unit)))
    local reaction = UnitReaction(unit, "player")
    local reactionStr = reaction and ("%d |cff888888(%s)"):format(reaction, 
        reaction == 1 and "Hated" or reaction == 2 and "Hostile" or reaction == 3 and "Unfriendly" or
        reaction == 4 and "Neutral" or reaction == 5 and "Friendly" or reaction == 6 and "Honored" or
        reaction == 7 and "Revered" or reaction == 8 and "Exalted" or "Unknown") or "nil"
    print("  UnitReaction:        " .. reactionStr)

    -- Health / Power
    print(CYAN .. "--- Resources ---" .. RST)
    print("  UnitHealth:           " .. tostring(UnitHealth(unit)))
    print("  UnitHealthMax:        " .. tostring(UnitHealthMax(unit)))
    local powerType = UnitPowerType(unit)
    print("  UnitPowerType:        " .. tostring(powerType))
    print("  UnitPower:            " .. tostring(UnitPower(unit)))
    print("  UnitPowerMax:         " .. tostring(UnitPowerMax(unit)))
    local manaType = UnitManaType(unit)
    print("  UnitManaType:         " .. tostring(manaType))

    -- Combat / Status
    print(CYAN .. "--- Combat / Status ---" .. RST)
    print("  UnitAffectingCombat:  " .. tostring(UnitAffectingCombat(unit)))
    print("  UnitCharmed:          " .. tostring(UnitCharmed(unit)))
    print("  UnitIsCharmed:        " .. tostring(UnitIsCharmed(unit)))
    print("  UnitIsPossessed:      " .. tostring(UnitIsPossessed(unit)))
    print("  UnitOnTaxi:           " .. tostring(UnitOnTaxi(unit)))
    print("  UnitInVehicle:        " .. tostring(UnitInVehicle(unit)))
    print("  UnitUsingVehicle:     " .. tostring(UnitUsingVehicle(unit)))
    print("  UnitHasVehicleUI:     " .. tostring(UnitHasVehicleUI(unit)))

    -- Guild / Social
    print(CYAN .. "--- Guild / Social ---" .. RST)
    local guildName, guildRankName, guildRankIndex, guildRealm = GetGuildInfo(unit)
    print("  GetGuildInfo:         " .. tostring(guildName) .. 
        " |cff888888(rank: " .. tostring(guildRankName) .. 
        ", index: " .. tostring(guildRankIndex) .. 
        ", realm: " .. tostring(guildRealm) .. ")" .. RST)

    -- Auras (buffs - first 8)
    print(CYAN .. "--- Buffs (first 8) ---" .. RST)
    for i = 1, 8 do
        local name, icon, count, debuffType, duration, expires, caster, isStealable = UnitAura(unit, i, "HELPFUL")
        if name then
            print(("  Buff[%d]: %s |cff888888x%d |ctype:%s |cdur:%.1f |cexp:%.1f |ccaster:%s |csteal:%s"):format(
                i, tostring(name), count or 0, tostring(debuffType), duration or 0, expires or 0,
                tostring(caster and caster ~= "player" and caster or "player"), tostring(isStealable)
            ))
        end
    end

    -- Casting
    print(CYAN .. "--- Casting ---" .. RST)
    local castName, castName2, castText, castTexture, castStartTime, castEndTime, castIsTrade, castNotInterruptible, castSpellId = UnitCastingInfo(unit)
    if castName then
        print("  Casting:       " .. tostring(castName) .. 
            " |cff888888(id: " .. tostring(castSpellId) .. 
            ", start: " .. tostring(castStartTime) .. 
            ", end: " .. tostring(castEndTime) ..
            ", trade: " .. tostring(castIsTrade) ..
            ", interrupt: " .. tostring(not castNotInterruptible) .. ")" .. RST)
    else
        print("  Casting:       none")
    end
    local chName, chName2, chText, chTexture, chStartTime, chEndTime, chIsTrade, chNotInterruptible, chSpellId = UnitChannelInfo(unit)
    if chName then
        print("  Channeling:    " .. tostring(chName) ..
            " |cff888888(id: " .. tostring(chSpellId) ..
            ", start: " .. tostring(chStartTime) ..
            ", end: " .. tostring(chEndTime) ..
            ", interrupt: " .. tostring(not chNotInterruptible) .. ")" .. RST)
    else
        print("  Channeling:   none")
    end

    -- Special flags
    print(CYAN .. "--- Special Flags ---" .. RST)
    print("  UnitIsBattlePet:         " .. tostring(UnitIsBattlePet(unit)))
    print("  UnitIsBattlePetCompanion: " .. tostring(UnitIsBattlePetCompanion(unit)))
    print("  UnitIsWildBattlePet:      " .. tostring(UnitIsWildBattlePet(unit)))
    print("  UnitIsTapDenied:          " .. tostring(UnitIsTapDenied(unit)))
    print("  UnitIsDND:                " .. tostring(UnitIsDND(unit)))
    print("  UnitIsAFK:                " .. tostring(UnitIsAFK(unit)))

    -- Faction (extra)
    print(CYAN .. "--- Faction ---" .. RST)
    local fac1, localizedFac1 = UnitFactionGroup(unit)
    local fac2, localizedFac2 = UnitFactionGroup("player")
    print("  Target Faction:     " .. tostring(fac1) .. " |cff888888(" .. tostring(localizedFac1) .. ")" .. RST)
    print("  Player Faction:    " .. tostring(fac2) .. " |cff888888(" .. tostring(localizedFac2) .. ")" .. RST)
    print("  Same Faction:     " .. tostring(fac1 == fac2))

    -- Target/Threat (if in combat)
    print(CYAN .. "--- Threat ---" .. RST)
    local threat = UnitThreatSituation(unit)
    local threatStr = threat == 0 and "None" or threat == 1 and "Low" or threat == 2 and "Medium" or threat == 3 and "High" or tostring(threat)
    print("  UnitThreatSituation: " .. threatStr)

    -- GUID parse (parse the GUID for extra info)
    local guid = UnitGUID(unit)
    if guid then
        print(CYAN .. "--- GUID Parsed ---" .. RST)
        local guidType, guidServerID, guidDbID, guidGuidLo, guidGuidHi = strsplit("-", guid or "")
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
        pcall(DebugDumpUnit, "target")
        local data = CollectTargetData()
        if data then
            DebugPrint(data)
            SaveToDB(data)
        end
    end
end)
