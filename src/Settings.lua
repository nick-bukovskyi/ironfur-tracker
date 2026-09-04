-- Ironfur Tracker: grouped appearance controls and owned editor interactions
local _, ns = ...

local Settings = {}
ns.Settings = Settings

local PANEL_WIDTH, ROW_WIDTH, ROW_HEIGHT = 450, 390, 32
local PANEL_TOP, PANEL_BOTTOM, RESET_HEIGHT = 45, 25, 28
local LABEL_WIDTH, SLIDER_WIDTH, INPUT_WIDTH = 100, 200, 48
local panel, scrollFrame, scrollBar, content, resetButton, alwaysVisible, eyeButton
local onStateChanged, onClose, isCombatLocked
local controlsRefreshing = false
local numericRows, colorRows, textureRows = {}, {}, {}
local colorSession
local eyeTooltipShown = false

local EYE_TEXTURE = "Interface\\LFGFrame\\LFG-Eye"
local EYE_FRAME_WIDTH = 0.125
local EYE_FRAME_HEIGHT = 0.25

local function CanEdit()
    return panel and panel:IsShown() and not isCombatLocked()
end

local function NotifyStateChanged()
    if onStateChanged then onStateChanged() end
end

local function EyeTooltipText()
    return ns.EditMode.AreHighlightsHidden() and "Show highlight" or "Hide highlight"
end

local function HideEyeTooltip()
    eyeTooltipShown = false
    if eyeButton and GameTooltip:GetOwner() == eyeButton then GameTooltip:Hide() end
end

local function RefreshEyeButton()
    if not eyeButton then return end
    local left = ns.EditMode.AreHighlightsHidden() and 0.5 or 0
    eyeButton:GetNormalTexture():SetTexCoord(
        left, left + EYE_FRAME_WIDTH, 0, EYE_FRAME_HEIGHT)
    if eyeTooltipShown and GameTooltip:GetOwner() == eyeButton then
        GameTooltip:SetText(EyeTooltipText())
        GameTooltip:Show()
    end
end

local function RefreshNumber(row)
    local value = ns.Config.GetNumber(row.definition.key)
    controlsRefreshing = true
    row.slider:SetValue(value)
    row.input:SetNumber(value)
    controlsRefreshing = false
end

local function ApplyNumber(row, rawValue)
    if controlsRefreshing or issecretvalue(rawValue) then return end
    local _, accepted = ns.Config.CommitNumber(row.definition.key, rawValue)
    if accepted then
        ns.Bar.ApplyGeometry()
    end
    RefreshNumber(row)
    NotifyStateChanged()
end

local function CommitInput(row)
    local text = row.input:GetText()
    if issecretvalue(text) then
        RefreshNumber(row)
        return
    end
    local value = tonumber(text)
    if value == nil then
        RefreshNumber(row)
        return
    end
    ApplyNumber(row, value)
end

local function ClearInputFocus(cancel)
    for _, row in pairs(numericRows) do
        if row.input:HasFocus() then
            row.cancelInputCommit = cancel
            row.input:ClearFocus()
        end
    end
end

local function RefreshColor(key)
    local row = colorRows[key]
    if row then row.swatch:SetColorTexture(ns.Config.GetColor(key)) end
end

local function CancelColorPreview()
    local session = colorSession
    if not session then return end
    colorSession = nil
    ns.Config.SetColor(session.key, session.r, session.g, session.b, session.a)
    ns.Bar.ApplyAppearance()
    RefreshColor(session.key)
    if ColorPickerFrame:GetExtraInfo() == session then ColorPickerFrame:Hide() end
end

local function CloseTransientControls()
    CancelColorPreview()
    for _, row in pairs(textureRows) do row.dropdown:CloseMenu() end
end

local function OpenColorPicker(key)
    if not CanEdit() then return end
    ClearInputFocus(false)
    CloseTransientControls()
    local r, g, b, a = ns.Config.GetColor(key)
    local session = { key = key, r = r, g = g, b = b, a = a, initializing = true }
    colorSession = session
    local function ApplyPreview()
        if colorSession ~= session or session.initializing
            or ColorPickerFrame:GetExtraInfo() ~= session or not CanEdit() then return end
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        if ns.Config.SetColor(key, nr, ng, nb, ColorPickerFrame:GetColorAlpha()) then
            ns.Bar.ApplyAppearance()
            RefreshColor(key)
        end
    end
    ColorPickerFrame:SetupColorPickerAndShow({
        r = r, g = g, b = b, opacity = a, hasOpacity = true, extraInfo = session,
        swatchFunc = ApplyPreview,
        opacityFunc = ApplyPreview,
        cancelFunc = function()
            if colorSession == session and ColorPickerFrame:GetExtraInfo() == session then
                CancelColorPreview()
            end
        end,
    })
    session.initializing = false
end

local function CreateRow(parent, labelText, top)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(ROW_WIDTH, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -top)
    if labelText then
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
        row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.label:SetWidth(LABEL_WIDTH)
        row.label:SetJustifyH("LEFT")
        row.label:SetText(labelText)
    end
    return row
end

local function CreateNumericRow(definition, top)
    local row = CreateRow(content, definition.label, top)
    row.definition = definition
    local slider = CreateFrame("Frame", nil, row, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint("LEFT", row.label, "RIGHT", 5, 0)
    slider:SetSize(SLIDER_WIDTH, 17)
    local steps = (definition.max - definition.min) / definition.step
    slider:Init(ns.Config.GetNumber(definition.key), definition.min, definition.max, steps, {})
    row.slider = slider

    local input = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    input:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    input:SetSize(INPUT_WIDTH, 22)
    input:SetAutoFocus(false)
    -- Negative offsets require the ordinary edit box, validated on commit
    input:SetNumeric(definition.min >= 0)
    local maxMagnitude = math.max(math.abs(definition.min), math.abs(definition.max))
    input:SetMaxLetters(#tostring(math.floor(maxMagnitude)) + (definition.min < 0 and 1 or 0))
    input:SetJustifyH("CENTER")
    input:SetNumber(ns.Config.GetNumber(definition.key))
    row.input = input
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if controlsRefreshing or issecretvalue(value) or type(value) ~= "number" then return end
        ApplyNumber(row, math.floor(value + 0.5))
    end, row)
    input:SetScript("OnEnterPressed", function(editBox) editBox:ClearFocus() end)
    input:SetScript("OnEditFocusLost", function(editBox)
        if row.cancelInputCommit then
            row.cancelInputCommit = false
            RefreshNumber(row)
        else
            CommitInput(row)
        end
        EditBox_ClearHighlight(editBox)
    end)
    input:SetScript("OnEscapePressed", function(editBox)
        row.cancelInputCommit = true
        RefreshNumber(row)
        editBox:ClearFocus()
    end)
    numericRows[definition.key] = row
end

local function CreateColorRow(key, top)
    local row = CreateRow(content, "Color", top)
    local button = CreateFrame("Button", nil, row)
    button:SetPoint("LEFT", row.label, "RIGHT", 5, 0)
    button:SetSize(22, 22)
    local border = button:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints(button)
    border:SetColorTexture(0.5, 0.5, 0.5, 1)
    local swatch = button:CreateTexture(nil, "ARTWORK")
    swatch:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    swatch:SetSize(20, 20)
    row.button, row.swatch = button, swatch
    button:SetScript("OnClick", function() OpenColorPicker(key) end)
    colorRows[key] = row
end

local function RefreshTexture(row)
    local name = ns.Config.GetTexture(row.key)
    row.dropdown:OverrideText(name)
end

local function CreateTextureRow(key, mediaType, top)
    local row = CreateRow(content, "Texture", top)
    row.key = key
    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("LEFT", row.label, "RIGHT", 5, 0)
    dropdown:SetWidth(185)
    row.dropdown = dropdown
    dropdown:SetupMenu(function(_, rootDescription)
        rootDescription:SetScrollMode(300)
        for _, option in ipairs(ns.Media.GetOptions(mediaType)) do
            local name = option.name
            local item = rootDescription:CreateRadio(name,
                function() return ns.Config.GetTexture(key) == name end,
                function()
                    if not CanEdit() then return end
                    if ns.Config.SetTexture(key, name) then
                        ns.Bar.ApplyAppearance()
                        RefreshTexture(row)
                    end
                end)
            item:AddInitializer(function(button)
                button.fontString:SetWidth(190)
                local preview
                if mediaType == "border" then
                    preview = button:AttachTemplate("BackdropTemplate")
                    preview:SetSize(90, 24)
                    ns.Media.ApplyBorder(preview, name, 8, 1, 1, 1, 1)
                else
                    preview = button:AttachTexture()
                    preview:SetSize(90, 18)
                    preview:SetTexture(option.path)
                    preview:SetVertexColor(1, 1, 1, 1)
                end
                preview:SetPoint("RIGHT", button, "RIGHT", -4, 0)
                return 320, 30
            end)
        end
    end)
    textureRows[key] = row
end

local function CreateSection(label, top)
    if top > 0 then
        local divider = content:CreateTexture(nil, "ARTWORK")
        divider:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -top)
        divider:SetSize(ROW_WIDTH, 1)
        divider:SetColorTexture(1, 1, 1, 0.3)
        top = top + 10
    end
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -top)
    title:SetText(label)
    return top + 25
end

local function AddNumericSection(section, top)
    for _, definition in ipairs(ns.Config.GetNumericDefinitions()) do
        if definition.section == section then
            CreateNumericRow(definition, top)
            top = top + ROW_HEIGHT + 2
        end
    end
    return top
end

local function BuildControls()
    local top = CreateSection("Visibility", 0)
    local visibilityRow = CreateRow(content, nil, top)
    alwaysVisible = CreateFrame("CheckButton", nil, visibilityRow, "UICheckButtonTemplate")
    alwaysVisible:SetPoint("LEFT", visibilityRow, "LEFT", 0, 0)
    alwaysVisible:SetSize(30, 30)
    local label = visibilityRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    label:SetPoint("LEFT", alwaysVisible, "RIGHT", 5, 0)
    label:SetText("Always show in Bear Form")
    alwaysVisible:SetScript("OnClick", function(checkbox)
        if not CanEdit() then return end
        ns.Config.SetAlwaysVisible(checkbox:GetChecked() and true or false)
        NotifyStateChanged()
    end)
    top = CreateSection("Size", top + ROW_HEIGHT + 8)
    top = AddNumericSection("Size", top)
    top = CreateSection("Bar", top + 8)
    CreateColorRow("barColor", top)
    CreateTextureRow("barTexture", "statusbar", top + ROW_HEIGHT + 2)
    top = CreateSection("Tick", top + 2 * (ROW_HEIGHT + 2) + 8)
    CreateColorRow("tickColor", top)
    top = AddNumericSection("Tick", top + ROW_HEIGHT + 2)
    top = CreateSection("Border", top + 8)
    CreateColorRow("borderColor", top)
    CreateTextureRow("borderTexture", "border", top + ROW_HEIGHT + 2)
    top = AddNumericSection("Border", top + 2 * (ROW_HEIGHT + 2))
    content:SetHeight(top)
end

local function UpdatePanelSize()
    local desiredHeight = content:GetHeight() + PANEL_TOP + PANEL_BOTTOM + RESET_HEIGHT + 12
    local height = math.min(desiredHeight, math.max(240, UIParent:GetHeight() - 80))
    panel:SetHeight(height)
    scrollFrame:SetSize(ROW_WIDTH, height - PANEL_TOP - PANEL_BOTTOM - RESET_HEIGHT - 12)
    resetButton:ClearAllPoints()
    resetButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -(height - PANEL_BOTTOM - RESET_HEIGHT))
    scrollBar:SetShown(scrollFrame:GetVerticalScrollRange() > 0)
end

local function EnsurePanel()
    if panel then return end
    panel = CreateFrame("Frame", nil, UIParent)
    panel:SetWidth(PANEL_WIDTH)
    panel:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -250, 200)
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(200)
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(frame)
        if CanEdit() then frame:StartMoving() end
    end)
    panel:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        frame:SetUserPlaced(false)
    end)
    panel:Hide()
    local border = CreateFrame("Frame", nil, panel, "DialogBorderTranslucentTemplate")
    border:SetAllPoints(panel)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -15)
    title:SetText("Ironfur Tracker")
    local closeButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    closeButton:SetScript("OnClick", function() onClose() end)
    eyeButton = CreateFrame("Button", nil, panel)
    eyeButton:SetSize(32, 32)
    eyeButton:SetPoint("RIGHT", closeButton, "LEFT", -4, 0)
    eyeButton:SetNormalTexture(EYE_TEXTURE)
    eyeButton:SetScript("OnClick", function()
        if not CanEdit() then return end
        ns.EditMode.ToggleHighlights()
    end)
    eyeButton:SetScript("OnEnter", function(button)
        eyeTooltipShown = true
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText(EyeTooltipText())
        GameTooltip:Show()
    end)
    eyeButton:SetScript("OnLeave", HideEyeTooltip)

    scrollFrame = CreateFrame("ScrollFrame", nil, panel)
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -PANEL_TOP)
    scrollFrame:EnableMouseWheel(true)
    scrollBar = CreateFrame("EventFrame", nil, panel, "MinimalScrollBar")
    scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 12, 0)
    scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 12, 0)
    ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, scrollBar)
    scrollFrame:HookScript("OnScrollRangeChanged", function(frame, _, range)
        scrollBar:SetShown(range > 0)
        if frame:GetVerticalScroll() > range then frame:SetVerticalScroll(range) end
    end)
    content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(ROW_WIDTH)
    scrollFrame:SetScrollChild(content)
    BuildControls()

    resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetSize(ROW_WIDTH, RESET_HEIGHT)
    resetButton:SetText("Reset to Defaults")
    resetButton:SetScript("OnClick", function()
        if not CanEdit() then return end
        CloseTransientControls()
        ClearInputFocus(true)
        ns.Config.ResetBar()
        ns.Bar.ApplyGeometry()
        Settings.Refresh()
        NotifyStateChanged()
    end)
    panel:SetScript("OnHide", function()
        HideEyeTooltip()
        CloseTransientControls()
        ClearInputFocus(false)
        panel:StopMovingOrSizing()
        panel:SetUserPlaced(false)
    end)
    ColorPickerFrame:HookScript("OnHide", function()
        if colorSession and ColorPickerFrame:GetExtraInfo() == colorSession then
            colorSession = nil
        end
    end)
end

function Settings.Initialize(stateChanged, closed, combatCheck)
    onStateChanged, onClose, isCombatLocked = stateChanged, closed, combatCheck
end

function Settings.Refresh()
    if not panel or not panel:IsShown() then return end
    for _, row in pairs(numericRows) do
        if not row.input:HasFocus() then RefreshNumber(row) end
    end
    for key in pairs(colorRows) do RefreshColor(key) end
    for _, row in pairs(textureRows) do RefreshTexture(row) end
    alwaysVisible:SetChecked(ns.Config.GetAlwaysVisible())
    RefreshEyeButton()
    UpdatePanelSize()
end

function Settings.Show()
    EnsurePanel()
    panel:Show()
    Settings.Refresh()
end

function Settings.Hide()
    if panel then panel:Hide() end
end

function Settings._GetTestState()
    return {
        panel = panel, rows = numericRows, colors = colorRows, textures = textureRows,
        alwaysVisible = alwaysVisible, resetButton = resetButton, scrollFrame = scrollFrame,
        colorSession = colorSession, eyeButton = eyeButton,
    }
end
