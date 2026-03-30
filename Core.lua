local addonName, ns = ...

--[[
    CMNW-OSINT
    Passive player intelligence collection from target, nameplates and chat
    Captures: guid, id, name, realm, level, faction, race, class, gender, guild, status
    Exports to popup as JSON via Export button in main frame
    Data persisted to SavedVariables — insert-only (never updates existing records)
]]

-- ============================================
-- INITIALIZATION
-- ============================================

-- ============================================
-- HELPERS
-- ============================================

local function ParseGuidID(guid)
    if not guid then return nil end
    local parts = { strsplit("-", guid) }
    if parts[3] then
        return tonumber(parts[3], 16)
    end
    return nil
end

local function ParseGuidRealmID(guid)
    if not guid then return nil end
    local parts = { strsplit("-", guid) }
    if parts[2] then
        return tonumber(parts[2])
    end
    return nil
end

local function ParseNameRealm(fullName)
    if not fullName then return nil, nil end
    local parts = { strsplit("-", fullName) }
    local name  = parts[1]
    local realm = parts[2] or GetRealmName()
    return name, realm
end

-- ============================================
-- DATA COLLECTION
-- ============================================

local function CollectUnitData(unit)
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
    local id     = ParseGuidID(guid)
    local realmId = ParseGuidRealmID(guid)

    return {
        guid          = guid,
        id            = id,
        realmId       = realmId,
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

local function CollectTargetData()
    return CollectUnitData("target")
end

local function CollectChatData(senderName, senderGUID)
    local name, realm = ParseNameRealm(senderName)
    local id          = ParseGuidID(senderGUID)
    local realmId     = ParseGuidRealmID(senderGUID)
    return {
        guid          = senderGUID,
        id            = id,
        realmId       = realmId,
        name          = name,
        realm         = realm,
        level         = nil,
        faction       = nil,
        race          = nil,
        raceName      = nil,
        class         = nil,
        className     = nil,
        classFile     = nil,
        gender        = nil,
        guild         = nil,
        guildRank     = nil,
        guildRankName = nil,
        status        = "------",
        createdBy     = "OSINT-CHAT-GET",
        updatedBy     = "OSINT-CHAT-INDEX",
        lastModified  = date("!%Y-%m-%dT%H:%M:%SZ"),
    }
end

-- ============================================
-- DEBUG PRINT
-- ============================================

local mainFrame = nil

local function DebugPrint(data, source)
    print("|cff00ff00[CMNW-OSINT]|r " .. (source or "Target") .. " captured:")
    print("  |cffffd700  GUID:|r          " .. tostring(data.guid))
    print("  |cffffd700  ID:|r            " .. tostring(data.id))
    print("  |cffffd700  RealmID:|r      " .. tostring(data.realmId))
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

--[[ Full unit debug dump (disabled)
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
--]]

-- ============================================
-- DATABASE
-- ============================================

local CHAT_EVENTS = {
    "CHAT_MSG_SAY",
    "CHAT_MSG_YELL",
    "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_GUILD",
    "CHAT_MSG_OFFICER",
    "CHAT_MSG_WHISPER",
    "CHAT_MSG_INSTANCE_CHAT",
    "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_CHANNEL",
}

local CHAT_EVENTS_SET = {}
for _, v in ipairs(CHAT_EVENTS) do CHAT_EVENTS_SET[v] = true end

local SOURCE_TAGS = {
    ["OSINT-CHARACTER-GET"] = "TGT",
    ["OSINT-CHAT-GET"]      = "CHT",
    ["OSINT-CLEU-GET"]      = "CLEU",
    ["OSINT-NAMEPLATE-GET"] = "NPL",
}

local UPDATED_TAGS = {
    ["OSINT-CHARACTER-INDEX"] = "TGT",
    ["OSINT-CHAT-INDEX"]      = "CHT",
    ["OSINT-CLEU-INDEX"]      = "CLEU",
    ["OSINT-NAMEPLATE-INDEX"] = "NPL",
}

local COLUMN_WIDTHS = { 25, 45, 90, 82, 50, 32, 34, 32, 66, 32, 66, 59, 43, 90, 38, 66, 50, 38, 97 }
local COLUMN_ALIGNS = { "CENTER", "CENTER", "LEFT", "LEFT", "CENTER", "CENTER", "CENTER", "CENTER", "LEFT", "CENTER", "LEFT", "LEFT", "CENTER", "LEFT", "CENTER", "LEFT", "CENTER", "CENTER", "LEFT" }
local ROW_HEIGHT    = 18
local MAX_ROWS      = 50
local visibleRows   = 18

local BLANK_TEX = "Interface\\Buttons\\WHITE8x8"

local ELVUI_BACKDROP = {
    bgFile   = BLANK_TEX,
    edgeFile = BLANK_TEX,
    edgeSize = 1,
}

local DETAIL_FIELDS = {}

local counterText       = nil
local scrollFrame       = nil
local rowButtons        = {}
local selectedEntry     = nil
local headerFS        = {}
local ExportJSON

function CMNWOSINT_UpdateCounter()
    if not counterText then return end
    local c = 0
    for _ in pairs(CMNWOSINT_DB) do c = c + 1 end
    counterText:SetText("Players: " .. c)
end

function CMNWOSINT_UpdateTable()
    if not scrollFrame then return end

    local data = {}
    for _, entry in pairs(CMNWOSINT_DB) do
        table.insert(data, entry)
    end
    table.sort(data, function(a, b)
        return (a.name or "") < (b.name or "")
    end)

    FauxScrollFrame_Update(scrollFrame, #data, visibleRows, ROW_HEIGHT)

    local offset = FauxScrollFrame_GetOffset(scrollFrame)

    for i = 1, visibleRows do
        local row   = rowButtons[i]
        local idx   = offset + i
        local entry = data[idx]

        if idx <= #data then
            row.guid = entry.guid

            local values = {
                tostring(idx),
                entry.id            and tostring(entry.id) or "-",
                entry.name          or "-",
                entry.realm         or "-",
                entry.realmId       and tostring(entry.realmId) or "-",
                entry.level         and tostring(entry.level) or "-",
                entry.faction       and entry.faction:sub(1, 1) or "-",
                entry.race          and tostring(entry.race) or "-",
                entry.raceName      or "-",
                entry.class         and tostring(entry.class) or "-",
                entry.className     or "-",
                entry.classFile     or "-",
                entry.gender        or "-",
                entry.guild         or "-",
                entry.guildRank     and tostring(entry.guildRank) or "-",
                entry.guildRankName or "-",
                entry.status        or "-",
                UPDATED_TAGS[entry.updatedBy] or entry.updatedBy or "-",
                entry.lastModified  and entry.lastModified:sub(1, 10) or "-",
            }

            for j, fs in ipairs(row.fontStrings) do
                fs:SetText(values[j])
            end

            row:Show()
            if row.bg then
                row.bg:Show()
                if idx % 2 == 0 then
                    row.bg:SetColorTexture(1, 1, 1, 0.03)
                else
                    row.bg:SetColorTexture(1, 1, 1, 0.01)
                end
            end

            if selectedEntry and entry.guid == selectedEntry.guid then
                row.selected:Show()
            else
                row.selected:Hide()
            end

            row:SetScript("OnClick", function()
                selectedEntry = entry
                CMNWOSINT_UpdateTable()
            end)
        else
            row:Hide()
            if row.bg then row.bg:Hide() end
            row.selected:Hide()
        end
    end

    for i = visibleRows + 1, #rowButtons do
        local row = rowButtons[i]
        row:Hide()
        if row.bg then row.bg:Hide() end
        row.selected:Hide()
    end
end

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

-- ============================================
-- UI — HELPERS
-- ============================================

local function CreateElvUIButton(parent, text, width, height)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, height)
    btn:SetBackdrop(ELVUI_BACKDROP)
    btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
    btn:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
    btn:SetNormalFontObject(GameFontNormal)
    btn:SetDisabledFontObject(GameFontDisable)
    btn:SetText(text)

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(btn)
    highlight:SetColorTexture(1, 1, 1, 0.3)
    highlight:SetBlendMode("ADD")

    local pushed = btn:CreateTexture(nil, "ARTWORK")
    pushed:SetAllPoints(btn)
    pushed:SetColorTexture(0.9, 0.8, 0.1, 0.3)
    pushed:SetBlendMode("ADD")
    btn:SetPushedTexture(pushed)

    return btn
end

local function CreateElvUICloseButton(parent)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(16, 16)
    btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -6)
    btn:SetBackdrop(ELVUI_BACKDROP)
    btn:SetBackdropColor(0.1, 0.1, 0.1, 1)
    btn:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText("X")
    btn.text = text

    btn:SetScript("OnEnter", function()
        text:SetTextColor(0.09, 0.51, 0.82)
    end)
    btn:SetScript("OnLeave", function()
        text:SetTextColor(1, 1, 1)
    end)
    btn:SetScript("OnClick", function()
        parent:Hide()
    end)

    return btn
end

local function RedistributeColumns(width)
    local totalBase = 0
    for _, w in ipairs(COLUMN_WIDTHS) do totalBase = totalBase + w end
    local available = width - 52
    local scale = available / totalBase

    local x = 0
    for i, baseW in ipairs(COLUMN_WIDTHS) do
        local w = baseW * scale
        if headerFS[i] then
            headerFS[i]:ClearAllPoints()
            headerFS[i]:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 16 + x, -60)
            headerFS[i]:SetWidth(w)
        end
        for _, row in ipairs(rowButtons) do
            if row.fontStrings[i] then
                row.fontStrings[i]:ClearAllPoints()
                row.fontStrings[i]:SetPoint("LEFT", row, "LEFT", x, 0)
                row.fontStrings[i]:SetWidth(w)
            end
        end
        x = x + w
    end

    for _, row in ipairs(rowButtons) do
        row:SetWidth(available)
    end
end

-- ============================================
-- UI — MAIN FRAME
-- ============================================

local function CreateMainFrame()
    if mainFrame then return end

    local f = CreateFrame("Frame", "CMNWOSINT_MainFrame", UIParent, "BackdropTemplate")
    f:SetSize(1100, 500)
    f:SetPoint("TOPLEFT", UIParent, "CENTER", -550, 250)
    f:SetBackdrop(ELVUI_BACKDROP)
    f:SetBackdropColor(0.1, 0.1, 0.1, 1)
    f:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
    f:SetMovable(true)
    f:SetResizable(true)
    f:SetResizeBounds(640, 200, 1600, 900)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:Hide()

    tinsert(UISpecialFrames, "CMNWOSINT_MainFrame")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -14)
    title:SetText("CMNW-OSINT")

    CreateElvUICloseButton(f)

    counterText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    counterText:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)

    local exportBtn = CreateElvUIButton(f, "Export JSON", 90, 22)
    exportBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -28, -30)
    exportBtn:SetScript("OnClick", function()
        ExportJSON()
    end)

    local clearBtn = CreateElvUIButton(f, "Clear DB", 70, 22)
    clearBtn:SetPoint("RIGHT", exportBtn, "LEFT", -4, 0)
    clearBtn:SetScript("OnClick", function()
        CMNWOSINT_DB = {}
        selectedEntry = nil
        CMNWOSINT_UpdateCounter()
        CMNWOSINT_UpdateTable()
        print("|cff00ff00[CMNW-OSINT]|r Database cleared.")
    end)

    local headerY = -60
    local headers = { "#", "ID", "Name", "Realm", "RealmID", "Lvl", "Fac", "Race", "RaceNm", "Class", "ClassNm", "ClassFile", "Gender", "Guild", "GRank", "GTitle", "Status", "UpdBy", "Modified" }
    local totalW  = 0
    for _, w in ipairs(COLUMN_WIDTHS) do totalW = totalW + w end

    local colX = 16
    for i, hdr in ipairs(headers) do
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", f, "TOPLEFT", colX, headerY)
        fs:SetWidth(COLUMN_WIDTHS[i])
        fs:SetJustifyH(COLUMN_ALIGNS[i])
        fs:SetText(hdr)
        headerFS[i] = fs
        colX = colX + COLUMN_WIDTHS[i]
    end

    local headerDiv = f:CreateTexture(nil, "ARTWORK")
    headerDiv:SetPoint("TOPLEFT", f, "TOPLEFT", 16, headerY - 14)
    headerDiv:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, headerY - 14)
    headerDiv:SetHeight(1)
    headerDiv:SetColorTexture(0.3, 0.3, 0.3, 0.5)

    local tableTop    = headerY - 18
    local tableBottom = -16
    local tableLeft   = 16
    local tableRight  = -36

    scrollFrame = CreateFrame("ScrollFrame", "CMNWOSINT_ScrollFrame", f, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", tableLeft, tableTop)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", tableRight, tableBottom)
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, CMNWOSINT_UpdateTable)
    end)

    for i = 1, MAX_ROWS do
        local row = CreateFrame("Button", nil, f)
        row:SetSize(totalW, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))

        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(row)
        bg:Hide()
        row.bg = bg

        local selected = row:CreateTexture(nil, "ARTWORK")
        selected:SetAllPoints(row)
        selected:SetColorTexture(0.09, 0.51, 0.82, 0.15)
        selected:Hide()
        row.selected = selected

        local highlight = row:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints(row)
        highlight:SetColorTexture(1, 1, 1, 0.06)

        row.fontStrings = {}
        local rx = 0
        for j = 1, #COLUMN_WIDTHS do
            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            fs:SetPoint("LEFT", row, "LEFT", rx, 0)
            fs:SetWidth(COLUMN_WIDTHS[j])
            fs:SetHeight(ROW_HEIGHT)
            fs:SetJustifyH(COLUMN_ALIGNS[j])
            table.insert(row.fontStrings, fs)
            rx = rx + COLUMN_WIDTHS[j]
        end

        row:Hide()
        rowButtons[i] = row
    end

    local resizeGrip = CreateFrame("Button", nil, f)
    resizeGrip:SetSize(16, 16)
    resizeGrip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 4)
    resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeGrip:SetScript("OnMouseDown", function()
        f:StartSizing("BOTTOMRIGHT")
    end)
    resizeGrip:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
    end)

    f:SetScript("OnSizeChanged", function(_, width, height)
        visibleRows = math.max(1, math.floor((height - 94) / ROW_HEIGHT))
        RedistributeColumns(width)
        CMNWOSINT_UpdateTable()
    end)

    f:SetScript("OnShow", function()
        local width  = f:GetWidth()
        local height = f:GetHeight()
        visibleRows = math.max(1, math.floor((height - 94) / ROW_HEIGHT))
        RedistributeColumns(width)
        CMNWOSINT_UpdateCounter()
        CMNWOSINT_UpdateTable()
    end)

    mainFrame = f
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
    f:SetBackdrop(ELVUI_BACKDROP)
    f:SetBackdropColor(0.1, 0.1, 0.1, 1)
    f:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)
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

    CreateElvUICloseButton(f)

    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -32)
    scroll:SetPoint("BOTTOMRIGHT", -36, 16)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(GameFontNormal)
    editBox:SetWidth(560)
    editBox:SetScript("OnEscapePressed", function() f:Hide() end)

    local editBg = editBox:CreateTexture(nil, "BACKGROUND")
    editBg:SetAllPoints(editBox)
    editBg:SetColorTexture(0.05, 0.05, 0.05, 1)

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

function ExportJSON()
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
            '  {"guid":%s,"id":%s,"realmId":%s,"name":%s,"realm":%s,"level":%s,"faction":%s,"race":%s,"raceName":%s,"class":%s,"className":%s,"classFile":%s,"gender":%s,"guild":%s,"guildRank":%s,"guildRankName":%s,"status":%s,"createdBy":%s,"updatedBy":%s,"lastModified":%s}',
            jsonStr(data.guid),
            jsonNum(data.id),
            jsonNum(data.realmId),
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
    if msg == "on" then
        mainFrame:Show()
    elseif msg == "off" then
        mainFrame:Hide()
    else
        if mainFrame:IsShown() then
            mainFrame:Hide()
        else
            mainFrame:Show()
        end
    end
end

-- ============================================
-- INITIALIZATION (deferred)
-- ============================================

local function OnInitialize()
    if not CMNWOSINT_DB then
        CMNWOSINT_DB = {}
    end
    CreateMainFrame()
end

-- ============================================
-- EVENT HANDLING
-- ============================================

local EventFrame = CreateFrame("Frame")

EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
EventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")

for _, eventName in ipairs(CHAT_EVENTS) do
    EventFrame:RegisterEvent(eventName)
end

EventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" and (...) == addonName then
        OnInitialize()
        print("|cff00ff00[CMNW-OSINT]|r Loaded. Target a player to collect data.")
    elseif event == "PLAYER_TARGET_CHANGED" then
        local data = CollectTargetData()
        if data then
            if SaveToDB(data) then
                DebugPrint(data)
            end
        end
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        local plateUnit = ...
        local data = CollectUnitData(plateUnit)
        if data then
            data.createdBy = "OSINT-NAMEPLATE-GET"
            data.updatedBy = "OSINT-NAMEPLATE-INDEX"
            if SaveToDB(data) then
                DebugPrint(data, "Nameplate")
            end
        end
    elseif CHAT_EVENTS_SET[event] then
        local _, senderName, _, _, _, _, _, _, _, _, _, senderGUID = ...
        if senderGUID then
            pcall(function()
                local data = CollectChatData(senderName, senderGUID)
                if data then
                    if SaveToDB(data) then
                        DebugPrint(data, "Chat")
                    end
                end
            end)
        end
    end
end)
