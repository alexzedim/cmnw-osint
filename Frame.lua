local addonName, addon = ...

addon.frame = CreateFrame('FRAME', 'RadarFrame')

--[[ Frame events ]] --

addon.frame:RegisterEvent('ADDON_LOADED')
addon.frame:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')

addon.frame:SetScript('OnEvent', function(self, event, arg1)
    if (event == 'ADDON_LOADED' and arg1 == addonName) then
        self:Init()
    elseif (event == 'COMBAT_LOG_EVENT_UNFILTERED') then
        self:OnCombatLogEventUnfiltered(CombatLogGetCurrentEventInfo())
    end
end)

addon.frame:SetScript('OnEnter', function(self)
    self.tooltip = true
    self:SetTooltip()
end)

addon.frame:SetScript('OnHide', function(self)
    if (self.moving) then
        self:StopMovingOrSizing()
        self.moving = false
    end
end)

addon.frame:SetScript('OnLeave', function(self)
    self.tooltip = false
    self:RemTooltip()
end)

addon.frame:SetScript('OnMouseDown', function(self, button)
    if (button == 'LeftButton' and not self.moving) then
        self:StartMoving()
        self.moving = true
    end
end)

addon.frame:SetScript('OnMouseUp', function(self, button)
    if (button == 'LeftButton' and self.moving) then
        self:StopMovingOrSizing()
        self.moving = false
    end
end)

--[[ Frame functions ]] --

function addon.frame:Init()
    self.moving = false
    self.tooltip = false

    self:EnableMouse(true)
    self:SetFrameLevel(100)
    self:SetMovable(true)
    self:SetPoint('BOTTOMLEFT', 10, 10)
    self:SetSize(33, 33)

    self:SetFrameBackground()
    self:SetFrameCounter()

    addon:SetCounter()
end

function addon.frame:OnCombatLogEventUnfiltered(...)
    local timestamp, _, _, sourceGuid, _, sourceFlags, _, targetGuid, _, targetFlags = ...

    --local isSourceHostile = bit.band(sourceFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
    local isSourcePlayer = bit.band(sourceFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0

    if (isSourcePlayer) then addon:SetHostile(timestamp, sourceGuid) end

    --local isTargetHostile = bit.band(targetFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) > 0
    local isTargetPlayer = bit.band(targetFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0

    if (isTargetPlayer) then addon:SetHostile(timestamp, targetGuid) end
end

function addon.frame:SetFrameBackground()
    self.background = self:CreateTexture(nil, 'BACKGROUND')

    self.background:SetPoint('CENTER')
    self.background:SetSize(21, 21)
    self.background:SetTexture('Interface/Icons/Spell_Holy_ElunesGrace')
end

function addon.frame:SetFrameCounter()
    self.counter = self:CreateFontString(nil, 'ARTWORK', 'QuestFont_Shadow_Huge')

    self.counter:SetPoint('TOPLEFT', self, 'TOPRIGHT', 3, -6)
end

--[[ Tooltip functions ]] --

function addon.frame:RemTooltip()
    GameTooltip:Hide()
end

function addon.frame:SetTooltip()
    if (not self.tooltip) then return end

    GameTooltip:Hide()

    GameTooltip:SetOwner(self, 'ANCHOR_NONE')
    GameTooltip:SetPoint('BOTTOMRIGHT', 'UIParent', 'BOTTOMRIGHT', -CONTAINER_OFFSET_X - 13, CONTAINER_OFFSET_Y)
    GameTooltip:AddLine(addonName)

    for _, value in pairs(OSINT.csv) do
        GameTooltip:AddDoubleLine(value)
    end

    GameTooltip:Show()
end
