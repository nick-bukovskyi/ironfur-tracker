-- Ironfur Tracker: grouped appearance controls and owned editor interactions
local _, ns = ...

local Settings = {}
ns.Settings = Settings

local LABEL_WIDTH, SLIDER_WIDTH, INPUT_WIDTH = 100, 200, 48
local CONTROL_GAP, INPUT_GAP = 5, 10
local ROW_WIDTH = LABEL_WIDTH + CONTROL_GAP + SLIDER_WIDTH + INPUT_GAP + INPUT_WIDTH
local PANEL_PADDING, ROW_HEIGHT = 20, 32
local PANEL_WIDTH = ROW_WIDTH + PANEL_PADDING * 2
local PANEL_TOP, PANEL_BOTTOM, RESET_HEIGHT = 45, 25, 28
local panel, scrollFrame, scrollBar, content, resetButton, alwaysVisible, eyeButton
local onStateChanged, onClose, isCombatLocked
local controlsRefreshing = false
local numericRows, colorRows, textureRows = {}, {}, {}
local choiceRows, dropdowns, layoutItems = {}, {}, {}
local stackColors, fontFamily, showStacks, showTicks
local selectedStack = 3
local laidOutColorMode
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
    if stackColors and stackColors.input and stackColors.input:HasFocus() then
        stackColors.input:ClearFocus()
    end
end

local function RefreshColor(key)
    local row = colorRows[key]
    if row then row.swatch:SetColorTexture(ns.Config.GetColor(key)) end
end

local function CloseTransientControls()
    ns.SettingsColorPicker.Cancel()
    for _, dropdown in ipairs(dropdowns) do dropdown:CloseMenu() end
end

local function OpenColorPicker(key, index)
    if not CanEdit() then return end
    ClearInputFocus(false)
    CloseTransientControls()
    ns.SettingsColorPicker.Open(key, index)
end

local function CreateRow(parent, labelText)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(ROW_WIDTH, ROW_HEIGHT)
    layoutItems[#layoutItems + 1] = row
    if labelText then
        row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
        row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
        row.label:SetWidth(LABEL_WIDTH)
        row.label:SetJustifyH("LEFT")
        row.label:SetText(labelText)
    end
    return row
end

local function CreateNumericRow(definition)
    local row = CreateRow(content, definition.label)
    row.definition = definition
    local slider = CreateFrame("Frame", nil, row, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint("LEFT", row.label, "RIGHT", CONTROL_GAP, 0)
    slider:SetSize(SLIDER_WIDTH, 17)
    local steps = (definition.max - definition.min) / definition.step
    slider:Init(ns.Config.GetNumber(definition.key), definition.min, definition.max, steps, {})
    row.slider = slider

    local input = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    input:SetPoint("LEFT", slider, "RIGHT", INPUT_GAP, 0)
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

local function AddColorSwatch(row, relativeTo, onClick)
    local button = CreateFrame("Button", nil, row)
    button:SetPoint("LEFT", relativeTo, "RIGHT", 5, 0)
    button:SetSize(22, 22)
    local border = button:CreateTexture(nil, "BACKGROUND")
    border:SetAllPoints(button)
    border:SetColorTexture(0.5, 0.5, 0.5, 1)
    local swatch = button:CreateTexture(nil, "ARTWORK")
    swatch:SetPoint("TOPLEFT", button, "TOPLEFT", 1, -1)
    swatch:SetSize(20, 20)
    row.button, row.swatch = button, swatch
    button:SetScript("OnClick", onClick)
end

local function CreateColorRow(key, colorMode)
    local row = CreateRow(content, "Color")
    row.colorMode = colorMode
    AddColorSwatch(row, row.label, function() OpenColorPicker(key) end)
    colorRows[key] = row
end

local function RefreshTexture(row)
    local name = ns.Config.GetTexture(row.key)
    row.dropdown:OverrideText(name)
end

local function AddDropdown(row)
    local dropdown = CreateFrame("DropdownButton", nil, row, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("LEFT", row.label, "RIGHT", CONTROL_GAP, 0)
    dropdown:SetWidth(185)
    row.dropdown = dropdown
    dropdowns[#dropdowns + 1] = dropdown
    return dropdown
end

local function CreateTextureRow(key, mediaType)
    local row = CreateRow(content, "Texture")
    row.key = key
    local dropdown = AddDropdown(row)
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

local function ApplySettingsChange()
    ns.Bar.ApplyAppearance()
    Settings.Refresh()
    NotifyStateChanged()
end

local function CreateChoiceRow(key, label)
    local row = CreateRow(content, label)
    local dropdown = AddDropdown(row)
    dropdown:SetupMenu(function(_, rootDescription)
        for _, option in ipairs(ns.Config.GetChoiceOptions(key)) do
            local value = option.value
            rootDescription:CreateRadio(option.label,
                function() return ns.Config.GetChoice(key) == value end,
                function()
                    if not CanEdit() then return end
                    ClearInputFocus(false)
                    CloseTransientControls()
                    if ns.Config.SetChoice(key, value) then ApplySettingsChange() end
                end)
        end
    end)
    choiceRows[key] = row
end

local function StackCountLabel(count, nextCount)
    if not nextCount then return tostring(count) .. "+ stacks" end
    if nextCount > count + 1 then return tostring(count) .. "-" .. tostring(nextCount - 1) .. " stacks" end
    return tostring(count) .. (count == 1 and " stack" or " stacks")
end

local function ReadStackCount()
    local text = stackColors.input:GetText()
    if issecretvalue(text) then return nil end
    local count = tonumber(text)
    if not count or count ~= math.floor(count) or count < 1
        or count > ns.Config.GetMaximumStackColors() then return nil end
    return count
end

local function SyncStackInput()
    stackColors.updatingInput = true
    stackColors.input:SetNumber(selectedStack)
    stackColors.updatingInput = false
end

local function RefreshStackColors()
    local thresholds = ns.Config.GetStackThresholds()
    local exists = ns.Config.HasStackColor(selectedStack)
    local valid = ReadStackCount() == selectedStack
    if #thresholds == 0 then
        stackColors.dropdown:OverrideText("No stack colors")
    elseif not exists then
        stackColors.dropdown:OverrideText(StackCountLabel(selectedStack, selectedStack + 1) .. " (inherited)")
    end
    for index, count in ipairs(thresholds) do
        if count == selectedStack then
            stackColors.dropdown:OverrideText(StackCountLabel(count, thresholds[index + 1]))
            break
        end
    end
    if exists then
        stackColors.swatch:SetColorTexture(ns.Config.GetStackColor(selectedStack))
    else
        stackColors.swatch:SetColorTexture(ns.Config.GetBarColor(selectedStack))
    end
    stackColors.addButton:SetEnabled(valid and not exists)
    stackColors.removeButton:SetEnabled(valid and exists)
    stackColors.button:SetEnabled(valid and exists)
    stackColors.removeButton:SetText(valid and ("Remove " .. selectedStack) or "Remove")
    if not valid then
        stackColors.hint:SetText("Enter a whole number from 1 to " .. ns.Config.GetMaximumStackColors())
    elseif exists then
        stackColors.hint:SetText("Color applies until the next threshold")
    elseif not thresholds[1] or selectedStack < thresholds[1] then
        stackColors.hint:SetText("No earlier rule: uses the Solid color")
    else
        stackColors.hint:SetText("Inherited color; Add to customize")
    end
end

local function OnStackInputChanged()
    if stackColors.updatingInput then return end
    local count = ReadStackCount()
    if count ~= selectedStack then CloseTransientControls() end
    if count then selectedStack = count end
    RefreshStackColors()
    NotifyStateChanged()
end

local function CreateStackColorRows()
    stackColors = CreateRow(content, "Stack color")
    stackColors.colorMode = "STACKS"
    local dropdown = AddDropdown(stackColors)
    AddColorSwatch(stackColors, dropdown, function()
        local count = ReadStackCount()
        if count and ns.Config.HasStackColor(count) then OpenColorPicker("stackColor", count) end
    end)
    dropdown:SetupMenu(function(_, rootDescription)
        rootDescription:SetScrollMode(300)
        local thresholds = ns.Config.GetStackThresholds()
        for index, count in ipairs(thresholds) do
            local stackIndex = count
            local item = rootDescription:CreateRadio(StackCountLabel(count, thresholds[index + 1]),
                function() return selectedStack == stackIndex end,
                function()
                    if not CanEdit() then return end
                    CloseTransientControls()
                    selectedStack = stackIndex
                    SyncStackInput()
                    ApplySettingsChange()
                end)
            item:AddInitializer(function(button)
                local swatch = button:AttachTexture()
                swatch:SetSize(20, 20)
                swatch:SetPoint("RIGHT", button, "RIGHT", -4, 0)
                swatch:SetColorTexture(ns.Config.GetStackColor(stackIndex))
                return 185, 24
            end)
        end
    end)
    local actions = CreateRow(content, "Stack count")
    actions.colorMode = "STACKS"
    local input = CreateFrame("EditBox", nil, actions, "InputBoxTemplate")
    input:SetPoint("LEFT", actions.label, "RIGHT", CONTROL_GAP, 0)
    input:SetSize(INPUT_WIDTH, 22)
    input:SetAutoFocus(false)
    input:SetNumeric(true)
    input:SetMaxLetters(#tostring(ns.Config.GetMaximumStackColors()))
    input:SetJustifyH("CENTER")
    stackColors.input = input
    local addButton = CreateFrame("Button", nil, actions, "UIPanelButtonTemplate")
    addButton:SetPoint("LEFT", input, "RIGHT", 8, 0)
    addButton:SetSize(58, 26)
    addButton:SetText("Add")
    local function AddThreshold()
        if not CanEdit() then return end
        local count = ReadStackCount()
        if not count or ns.Config.HasStackColor(count) then
            input:ClearFocus()
            return
        end
        CloseTransientControls()
        ClearInputFocus(false)
        local added = ns.Config.AddStackColor(count)
        if added then
            selectedStack = added
            SyncStackInput()
            ApplySettingsChange()
        end
    end
    addButton:SetScript("OnClick", AddThreshold)
    input:SetScript("OnEnterPressed", AddThreshold)
    input:SetScript("OnEditFocusLost", EditBox_ClearHighlight)
    input:SetScript("OnEscapePressed", function()
        SyncStackInput()
        RefreshStackColors()
        input:ClearFocus()
    end)
    local removeButton = CreateFrame("Button", nil, actions, "UIPanelButtonTemplate")
    removeButton:SetPoint("LEFT", addButton, "RIGHT", 8, 0)
    removeButton:SetPoint("RIGHT", actions, "RIGHT", 0, 0)
    removeButton:SetHeight(26)
    removeButton:SetText("Remove")
    removeButton:SetScript("OnClick", function()
        if not CanEdit() then return end
        local count = ReadStackCount()
        if not count or not ns.Config.HasStackColor(count) then return end
        CloseTransientControls()
        ClearInputFocus(false)
        if ns.Config.RemoveStackColor(count) then
            local thresholds = ns.Config.GetStackThresholds()
            selectedStack = thresholds[1] or count
            for _, threshold in ipairs(thresholds) do
                if threshold > count then break end
                selectedStack = threshold
            end
            SyncStackInput()
            ApplySettingsChange()
        end
    end)
    stackColors.addButton, stackColors.removeButton = addButton, removeButton
    local hint = CreateRow(content)
    hint.colorMode = "STACKS"
    hint:SetHeight(22)
    local text = hint:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", hint, "LEFT", LABEL_WIDTH + CONTROL_GAP, 0)
    text:SetWidth(ROW_WIDTH - LABEL_WIDTH - CONTROL_GAP)
    text:SetJustifyH("LEFT")
    stackColors.hint = text
    SyncStackInput()
    RefreshStackColors()
    input:SetScript("OnTextChanged", OnStackInputChanged)
end

local function CreateFontFamilyRow()
    fontFamily = CreateRow(content, "Font")
    local dropdown = AddDropdown(fontFamily)
    dropdown:SetupMenu(function(_, rootDescription)
        rootDescription:SetScrollMode(300)
        for _, option in ipairs(ns.Media.GetOptions("font")) do
            local name = option.name
            local item = rootDescription:CreateRadio(name,
                function() return ns.Config.GetFontFamily() == name end,
                function()
                    if not CanEdit() then return end
                    CloseTransientControls()
                    if ns.Config.SetFontFamily(name) then ApplySettingsChange() end
                end)
            item:AddInitializer(function(button)
                button.fontString:SetFontObject(ns.Media.GetFontPreviewObject(name))
                button.fontString:SetWidth(270)
                return 300, 24
            end)
        end
    end)
end

local function CreateSection(label)
    local section = CreateFrame("Frame", nil, content)
    local first = #layoutItems == 0
    section:SetSize(ROW_WIDTH, first and 25 or 35)
    section.gapBefore = first and 0 or 8
    if not first then
        local divider = section:CreateTexture(nil, "ARTWORK")
        divider:SetPoint("TOPLEFT", section, "TOPLEFT", 0, 0)
        divider:SetSize(ROW_WIDTH, 1)
        divider:SetColorTexture(1, 1, 1, 0.3)
    end
    local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalMed3")
    title:SetPoint("TOPLEFT", section, "TOPLEFT", 0, first and 0 or -10)
    title:SetText(label)
    layoutItems[#layoutItems + 1] = section
end

local function AddNumericSection(section, key)
    for _, definition in ipairs(ns.Config.GetNumericDefinitions()) do
        if definition.section == section and (not key or definition.key == key) then CreateNumericRow(definition) end
    end
end

local function CreateCheckbox(label, getter, setter)
    local row = CreateRow(content)
    local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    checkbox:SetPoint("LEFT", row, "LEFT", 0, 0)
    checkbox:SetSize(30, 30)
    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    text:SetText(label)
    checkbox:SetChecked(getter())
    checkbox:SetScript("OnClick", function(button)
        if not CanEdit() then return end
        setter(button:GetChecked() and true or false)
        ApplySettingsChange()
    end)
    return checkbox
end

local function BuildControls()
    CreateSection("Visibility")
    alwaysVisible = CreateCheckbox("Always show in Bear Form", ns.Config.GetAlwaysVisible, ns.Config.SetAlwaysVisible)
    CreateSection("Font")
    showStacks = CreateCheckbox("Show stacks", ns.Config.GetShowStacks, ns.Config.SetShowStacks)
    CreateFontFamilyRow()
    AddNumericSection("Font", "fontSize")
    CreateChoiceRow("fontPosition", "Position")
    AddNumericSection("Font", "fontOffset")
    AddNumericSection("Font", "fontOffsetY")
    CreateChoiceRow("fontStyle", "Text style")
    CreateColorRow("textColor")
    CreateSection("Bar")
    AddNumericSection("Bar")
    CreateTextureRow("barTexture", "statusbar")
    CreateChoiceRow("barColorMode", "Color mode")
    CreateColorRow("barColor", "SOLID")
    CreateStackColorRows()
    CreateSection("Backdrop")
    CreateTextureRow("backdropTexture", "statusbar")
    CreateColorRow("backdropColor")
    CreateSection("Border")
    AddNumericSection("Border")
    CreateTextureRow("borderTexture", "border")
    CreateColorRow("borderColor")
    CreateSection("Tick")
    showTicks = CreateCheckbox("Show ticks", ns.Config.GetShowTicks, ns.Config.SetShowTicks)
    AddNumericSection("Tick")
    CreateColorRow("tickColor")
end

local function ReflowControls()
    local mode = ns.Config.GetChoice("barColorMode")
    if laidOutColorMode == mode then return end
    local top = 0
    for _, item in ipairs(layoutItems) do
        local shown = not item.colorMode or item.colorMode == mode
        item:SetShown(shown)
        if shown then
            top = top + (item.gapBefore or 0)
            item:ClearAllPoints()
            item:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -top)
            top = top + item:GetHeight() + 2
        end
    end
    content:SetHeight(top)
    laidOutColorMode = mode
end

local function UpdatePanelSize()
    local desiredHeight = content:GetHeight() + PANEL_TOP + PANEL_BOTTOM + RESET_HEIGHT + 12
    local height = math.min(desiredHeight, math.max(240, UIParent:GetHeight() - 80))
    panel:SetHeight(height)
    scrollFrame:SetSize(ROW_WIDTH, height - PANEL_TOP - PANEL_BOTTOM - RESET_HEIGHT - 12)
    resetButton:ClearAllPoints()
    resetButton:SetPoint("TOPLEFT", panel, "TOPLEFT", PANEL_PADDING, -(height - PANEL_BOTTOM - RESET_HEIGHT))
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
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", PANEL_PADDING, -PANEL_TOP)
    scrollFrame:EnableMouseWheel(true)
    scrollBar = CreateFrame("EventFrame", nil, panel, "MinimalScrollBar")
    scrollBar:SetPoint("TOP", scrollFrame, "TOPRIGHT", PANEL_PADDING / 2, 0)
    scrollBar:SetPoint("BOTTOM", scrollFrame, "BOTTOMRIGHT", PANEL_PADDING / 2, 0)
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
        selectedStack = ns.Config.HasStackColor(3) and 3 or 1
        SyncStackInput()
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
        NotifyStateChanged()
    end)
end

function Settings.Initialize(stateChanged, closed, combatCheck)
    onStateChanged, onClose, isCombatLocked = stateChanged, closed, combatCheck
    ns.SettingsColorPicker.Initialize(CanEdit, function(key, index)
        ns.Bar.ApplyAppearance()
        if index then RefreshStackColors() else RefreshColor(key) end
        NotifyStateChanged()
    end)
end

function Settings.Refresh()
    if not panel or not panel:IsShown() then return end
    for _, row in pairs(numericRows) do
        if not row.input:HasFocus() then RefreshNumber(row) end
    end
    for key in pairs(colorRows) do RefreshColor(key) end
    for _, row in pairs(textureRows) do RefreshTexture(row) end
    for key, row in pairs(choiceRows) do
        local selected = ns.Config.GetChoice(key)
        for _, option in ipairs(ns.Config.GetChoiceOptions(key)) do
            if option.value == selected then row.dropdown:OverrideText(option.label) end
        end
    end
    fontFamily.dropdown:OverrideText(ns.Config.GetFontFamily())
    showStacks:SetChecked(ns.Config.GetShowStacks())
    showTicks:SetChecked(ns.Config.GetShowTicks())
    RefreshStackColors()
    alwaysVisible:SetChecked(ns.Config.GetAlwaysVisible())
    RefreshEyeButton()
    ReflowControls()
    UpdatePanelSize()
end

function Settings.Show()
    EnsurePanel()
    panel:Show()
    Settings.Refresh()
    NotifyStateChanged()
end

function Settings.Hide()
    if panel then panel:Hide() end
end

function Settings.GetPreviewStackCount()
    if panel and panel:IsShown() and ns.Config.GetChoice("barColorMode") == "STACKS" then
        return selectedStack
    end
    return nil
end

function Settings._GetTestState()
    return {
        panel = panel, rows = numericRows, colors = colorRows, textures = textureRows,
        alwaysVisible = alwaysVisible, resetButton = resetButton, scrollFrame = scrollFrame,
        colorSession = ns.SettingsColorPicker._GetSession(), eyeButton = eyeButton,
        choices = choiceRows, fontFamily = fontFamily, showStacks = showStacks, showTicks = showTicks,
        stackColors = stackColors and {
            dropdown = stackColors.dropdown, button = stackColors.button, swatch = stackColors.swatch,
            addButton = stackColors.addButton, removeButton = stackColors.removeButton,
            selectedIndex = selectedStack, input = stackColors.input, hint = stackColors.hint,
        },
    }
end
