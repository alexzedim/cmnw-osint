local addonName, addon = ...

addon.panel = CreateFrame('FRAME')

--[[ Panel events ]] --

addon.panel:RegisterEvent('ADDON_LOADED')

addon.panel:SetScript('OnEvent', function(self, event, arg1)
    if (event == 'ADDON_LOADED' and arg1 == addonName) then
        self:Init()
    end
end)

addon.panel:SetScript('OnShow', function(self)
    self.autohide:SetChecked(OSINT.autohide)
    self.expiration:SetValue(OSINT.expiration)
    self.warning:SetChecked(OSINT.warning)
end)

--[[ Panel functions ]] --

function addon.panel:Init()
    OSINT = OSINT or self:GetDefaults()

    self.name = GetAddOnInfo(addonName)
    self.expiration_max = 300
    self.expiration_min = 5

    self:SetFrameTitle()
    self:SetFrameVersion()

    self:SetFrameAutohide()
    self:SetFramePosition()

    self.cancel = function(this) this:OnInterfaceOptionsCancel() end
    self.default = function(this) this:OnInterfaceOptionsReset() end
    self.okay = function(this) this:OnInterfaceOptionsSubmit() end

    InterfaceOptions_AddCategory(self)
end

function addon.panel:GetDefaults()
    return {
        ['whoami'] = UnitGUID('player'),
        ['autohide'] = false,
        ['expiration'] = 90,
        ['warning'] = false,
        ['watch'] = {},
        ['data'] = {},
        ['csv'] = {},
    }
end

function addon.panel:OnInterfaceOptionsCancel()
end

function addon.panel:OnInterfaceOptionsReset()
    OSINT = self:GetDefaults()

    self.autohide:SetChecked(OSINT.autohide)
    self.expiration:SetValue(OSINT.expiration)
    self.warning:SetChecked(OSINT.warning)
end

function addon.panel:OnInterfaceOptionsSubmit()
    OSINT.autohide = self.autohide:GetChecked()
    OSINT.expiration = self.expiration:GetValue()
    OSINT.warning = self.warning:GetChecked()

    addon:SetCounter()
end

function addon.panel:SetFrameAutohide()
    self.autohide = CreateFrame('CheckButton', nil, self, 'UICheckButtonTemplate')

    self.autohide:SetChecked(OSINT.autohide)
    self.autohide:SetPoint('TOPLEFT', self, 'TOPLEFT', 10, -50)
end

function addon.panel:SetFramePosition()
    self.position = CreateFrame('Button', nil, self, 'UIPanelButtonTemplate')

    self.position:SetPoint('BOTTOMLEFT', 20, 20)

    self.position:SetWidth(self.position:GetTextWidth() + 20)

    self.position:SetScript('OnClick', function()
        addon.frame:ClearAllPoints()
        addon.frame:SetPoint('BOTTOMLEFT', 10, 10)
    end)
end

function addon.panel:SetFrameTitle()
    self.title = self:CreateFontString(nil, 'OVERLAY', 'GameFontNormalLarge')

    self.title:SetPoint('TOPLEFT', 15, -15)
    self.title:SetText(GetAddOnInfo(addonName))
end

function addon.panel:SetFrameVersion()
    self.version = self:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')

    self.version:SetTextColor(0.5, 0.5, 0.5)
    self.version:SetPoint('BOTTOMLEFT', self.title, 'BOTTOMRIGHT', 5, 1)
    self.version:SetText(GetAddOnMetadata(addonName, 'Version'))
end

function CMNW_OSINT_AddonCompartmentFunc(button, menu)
    local function openConfig()
        if not addon or not addon.panel then return end

        InterfaceOptionsFrame_OpenToCategory(addon.panel)
        InterfaceOptionsFrame_OpenToCategory(addon.panel)
    end

    if menu then
        local info = UIDropDownMenu_CreateInfo()
        info.text = GetAddOnInfo(addonName)
        info.func = openConfig
        UIDropDownMenu_AddButton(info, 1)
    else
        openConfig()
    end
end
