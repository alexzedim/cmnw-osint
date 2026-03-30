local addonName, ns = ...

--[[
    CMNW-OSINT
    Captures player target data: guid, id, name, realm, level, faction, race, class, gender, guild, status
    Exports to popup as JSON via /cmnw export
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

    if not UnitExists(unit) or not UnitIsPlayer(unit) then
        return nil
    end

    local guid       = UnitGUID(unit)
    local name, realm = UnitName(unit)
    local level      = UnitLevel(unit)
    local faction    = UnitFactionGroup(unit) or "Unknown"

    if not realm or realm == "" then
        realm = GetRealmName()
    end

    local _, _, raceIndex   = UnitRace(unit)
    local _, _, classIndex  = UnitClass(unit)
    local className, classFile, _ = UnitClass(unit)
    local raceName, _, _    = UnitRace(unit)
    local sex = UnitSex(unit)
    local gender = sex == 1 and "Male" or sex == 2 and "Female" or sex == 3 and "Neuter" or "Unknown"

    local guildName, guildRankName, guildRankIndex = GetGuildInfo(unit)

    local id = nil
    if guid then
        local parts = { strsplit("-", guid) }
        if parts[3] then
            id = tonumber(parts[3], 16)
        end
    end

    return {
        guid          = guid,
        id            = id,
        name          = name,
        realm         = realm,
        level         = level,
        faction       = faction,
        race          = raceIndex,
        raceName      = raceName,
        class         = classIndex,
        className     = className,
        classFile     = classFile,
        gender        = gender,
        guild         = guildName,
        guildRank     = guildRankIndex,
        guildRankName = guildRankName,
        status        = "------",
        createdBy     = "OSINT-CHARACTER-GET",
        updatedBy     = "OSINT-CHARACTER-INDEX",
        lastModified  = date("!%Y-%m-%dT%H:%M:%SZ"),
    }
end

-- ============================================
-- DEBUG PRINT
-- ============================================

local lastCaptured = nil

local function DebugPrint(data)
    lastCaptured = data
    print("|cff00ff00[CMNW-OSINT]|r Target captured:")
    print("  |cffffd700  GUID:|r          " .. tostring(data.guid))
    print("  |cffffd700  ID:|r            " .. tostring(data.id))
    print("  |cffffd700  Name:|r          " .. tostring(data.name))
    print("  |cffffd700  Realm:|r         " .. tostring(data.realm))
    print("  |cffffd700  Level:|r         " .. tostring(data.level))
    print("  |cffffd700  Faction:|r       " .. tostring(data.faction))
    print("  |cffffd700  Race:|r          " .. tostring(data.race) .. " (" .. tostring(data.raceName) .. ")")
    print("  |cffffd700  Class:|r         " .. tostring(data.class) .. " (" .. tostring(data.className) .. " - " .. tostring(data.classFile) .. ")")
    print("  |cffffd700  Gender:|r        " .. tostring(data.gender))
    print("  |cffffd700  Guild:|r         " .. tostring(data.guild))
    print("  |cffffd700  GuildRank:|r     " .. tostring(data.guildRank))
    print("  |cffffd700  GuildRankName:|r " .. tostring(data.guildRankName))
    print("  |cffffd700  Status:|r        " .. tostring(data.status))
    print("  |cffffd700  LastModified:|r  " .. tostring(data.lastModified))
end

local function SayLastCaptured()
    if not lastCaptured then
        print("|cff00ff00[CMNW-OSINT]|r No captured target yet.")
        return
    end
    local d = lastCaptured
    SendChatMessage("[CMNW-OSINT] GUID: " .. tostring(d.guid), "SAY")
    SendChatMessage("[CMNW-OSINT] ID: " .. tostring(d.id), "SAY")
    SendChatMessage("[CMNW-OSINT] Name: " .. tostring(d.name), "SAY")
    SendChatMessage("[CMNW-OSINT] Realm: " .. tostring(d.realm), "SAY")
    SendChatMessage("[CMNW-OSINT] Level: " .. tostring(d.level), "SAY")
    SendChatMessage("[CMNW-OSINT] Faction: " .. tostring(d.faction), "SAY")
    SendChatMessage("[CMNW-OSINT] Race: " .. tostring(d.race) .. " (" .. tostring(d.raceName) .. ")", "SAY")
    SendChatMessage("[CMNW-OSINT] Class: " .. tostring(d.class) .. " (" .. tostring(d.className) .. ")", "SAY")
    SendChatMessage("[CMNW-OSINT] Gender: " .. tostring(d.gender), "SAY")
    SendChatMessage("[CMNW-OSINT] Guild: " .. tostring(d.guild), "SAY")
    SendChatMessage("[CMNW-OSINT] GuildRank: " .. tostring(d.guildRank) .. " - " .. tostring(d.guildRankName), "SAY")
    SendChatMessage("[CMNW-OSINT] Status: " .. tostring(d.status), "SAY")
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

    print(GREEN .. "--- Identity ---" .. RST)
    print("  UnitExists:       " .. tostring(exists))
    print("  UnitIsPlayer:     " .. tostring(isPlayer))
    print("  UnitGUID:         " .. tostring(guid))
    print("  UnitName:         " .. tostring(name) .. " |cff888888(realm: " .. tostring(realm) .. ")" .. RST)
    print("  UnitIsSameServer: " .. tostring(sameServer))

    print(GREEN .. "--- Character Info ---" .. RST)
    print("  UnitLevel:           " .. tostring(level))
    print("  UnitClass:           " .. tostring(enClass) .. " |cff888888(file: " .. tostring(classFile) .. ", index: " .. tostring(classIndex) .. ")" .. RST)
    print("  UnitRace:            " .. tostring(enRace) .. " |cff888888(file: " .. tostring(raceFile) .. ", index: " .. tostring(raceIndex) .. ")" .. RST)
    print("  UnitSex:             " .. tostring(sexStr) .. " (" .. tostring(sex) .. ")")
    print("  UnitFactionGroup:    " .. tostring(factionGroup))
    print("  UnitReaction:        " .. reactionStr)

    print(GREEN .. "--- Guild / Social ---" .. RST)
    print("  GetGuildInfo:         " .. tostring(guildName) ..
        " |cff888888(rank: " .. tostring(guildRankName) ..
        ", index: " .. tostring(guildRankIndex) ..
        ", realm: " .. tostring(guildRealm) .. ")" .. RST)

    if guid then
        print(GREEN .. "--- GUID Parsed ---" .. RST)
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
-- EXPORT (JSON to clipboard via popup)
-- ============================================

local exportFrame = nil

local function CreateExportFrame()
    if exportFrame then return end

    local f = CreateFrame("Frame", "CMNWOSINT_ExportFrame", UIParent, "BackdropTemplate")
    f:SetSize(600, 400)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    f:SetBackdropColor(0, 0, 0, 1)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:EnableKeyboard(true)
    f:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" then f:Hide() end
    end)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -12)
    title:SetText("CMNW-OSINT Export — Ctrl+A then Ctrl+C to copy")

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -32)
    scroll:SetPoint("BOTTOMRIGHT", -36, 16)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontNormal)
    editBox:SetWidth(560)
    editBox:SetScript("OnEscapePressed", function() f:Hide() end)
    scroll:SetScrollChild(editBox)

    f.editBox = editBox
    exportFrame = f
end

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
        local function jsonStr(v)
            if v == nil then return "null" end
            return '"' .. EscapeJSON(tostring(v)) .. '"'
        end
        local function jsonNum(v)
            if v == nil then return "null" end
            return tostring(v)
        end
        local entry = string.format(
            '  {"guid":%s,"id":%s,"name":%s,"realm":%s,"level":%s,"faction":%s,"race":%s,"raceName":%s,"class":%s,"className":%s,"classFile":%s,"gender":%s,"guild":%s,"guildRank":%s,"guildRankName":%s,"status":%s,"createdBy":%s,"updatedBy":%s,"lastModified":%s}',
            jsonStr(data.guid),
            jsonNum(data.id),
            jsonStr(data.name),
            jsonStr(data.realm),
            jsonNum(data.level),
            jsonStr(data.faction),
            jsonNum(data.race),
            jsonStr(data.raceName),
            jsonNum(data.class),
            jsonStr(data.className),
            jsonStr(data.classFile),
            jsonStr(data.gender),
            jsonStr(data.guild),
            jsonNum(data.guildRank),
            jsonStr(data.guildRankName),
            jsonStr(data.status),
            jsonStr(data.createdBy),
            jsonStr(data.updatedBy),
            jsonStr(data.lastModified)
        )
        table.insert(entries, entry)
    end

    local json
    if #entries > 0 then
        json = "[\n" .. table.concat(entries, ",\n") .. "\n]"
    else
        json = "[]"
    end

    CreateExportFrame()
    exportFrame.editBox:SetText(json)
    exportFrame.editBox:HighlightText()
    exportFrame:Show()
    print("|cff00ff00[CMNW-OSINT]|r JSON exported (" .. #entries .. " entries) — Ctrl+A, Ctrl+C in the popup to copy")
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
        local ok, err = pcall(DebugDumpUnit, "target")
        if not ok then
            print("|cffff5555[CMNW-OSINT] DebugDumpUnit error:|r " .. tostring(err))
        end
        local data = CollectTargetData()
        if data then
            DebugPrint(data)
            SaveToDB(data)
        end
    end
end)
