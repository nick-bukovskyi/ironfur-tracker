-- Ironfur Tracker: isolated Edit Mode companion UI
local _, ns = ...

local EditMode = {}
ns.EditMode = EditMode

local PANEL_WIDTH = 430
local PANEL_ROW_TOP = 45
local PANEL_BOTTOM_PADDING = 12
local RESET_GAP = 8
local RESET_HEIGHT = 28
local ROW_WIDTH = 390
local ROW_HEIGHT = 32
local ROW_GAP = 2
local LABEL_WIDTH = 100
local SLIDER_WIDTH = 200
local INPUT_WIDTH = 48

local stateChangedCallback
local eventsRegistered = false
local hookedManager
local modeActive = false
local selectionsShown = false
local eligible = false
local combatLocked = false
local selected = false
local dragging = false
local controlsRefreshing = false

local selection
local panel
local rows = {}

local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

local function IsCombatLocked()
    return combatLocked or (InCombatLockdown and InCombatLockdown())
end

local function NotifyStateChanged()
    if stateChangedCallback then
        stateChangedCallback()
    end
end

local function RefreshRow(row)
    local value = ns.Config.GetNumber(row.definition.key)
    controlsRefreshing = true
    row.slider:SetValue(value)
    row.input:SetNumber(value)
    controlsRefreshing = false
end

local function RefreshControls()
    for _, row in ipairs(rows) do
        RefreshRow(row)
    end
end

local function ApplyNumber(row, rawValue)
    if controlsRefreshing or IsSecret(rawValue) then
        return
    end

    local committed, accepted = ns.Config.CommitNumber(row.definition.key, rawValue)
    if accepted then
        ns.Bar.ApplyGeometry()
    end

    RefreshControls()
    NotifyStateChanged()
    return committed, accepted
end

local function CommitInput(row)
    local text = row.input:GetText()
    if IsSecret(text) then
        RefreshRow(row)
        return
    end

    local value = tonumber(text)
    if value == nil then
        RefreshRow(row)
        return
    end

    ApplyNumber(row, value)
end

local function ClearInputFocus()
    for _, row in ipairs(rows) do
        if row.input:HasFocus() then
            row.input:ClearFocus()
        end
    end
end

local function CreateNumericRow(parent, definition, previousRow)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(ROW_WIDTH, ROW_HEIGHT)
    if previousRow then
        row:SetPoint("TOPLEFT", previousRow, "BOTTOMLEFT", 0, -ROW_GAP)
    else
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, -PANEL_ROW_TOP)
    end
    row.definition = definition

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    label:SetPoint("LEFT", row, "LEFT", 0, 0)
    label:SetWidth(LABEL_WIDTH)
    label:SetJustifyH("LEFT")
    label:SetText(definition.label)
    row.label = label

    local slider = CreateFrame("Frame", nil, row, "MinimalSliderWithSteppersTemplate")
    slider:SetPoint("LEFT", label, "RIGHT", 5, 0)
    slider:SetSize(SLIDER_WIDTH, 17)
    local steps = (definition.max - definition.min) / definition.step
    slider:Init(ns.Config.GetNumber(definition.key), definition.min, definition.max, steps, {})
    row.slider = slider

    local input = CreateFrame("EditBox", nil, row, "InputBoxTemplate")
    input:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    input:SetSize(INPUT_WIDTH, 22)
    input:SetAutoFocus(false)
    input:SetNumeric(true)
    local maxMagnitude = math.max(math.abs(definition.min), math.abs(definition.max))
    local maxLetters = #tostring(math.floor(maxMagnitude))
    if definition.min < 0 then
        maxLetters = maxLetters + 1
    end
    input:SetMaxLetters(maxLetters)
    input:SetJustifyH("CENTER")
    input:SetNumber(ns.Config.GetNumber(definition.key))
    row.input = input

    slider:RegisterCallback(
        MinimalSliderWithSteppersMixin.Event.OnValueChanged,
        function(_, value)
            if controlsRefreshing or IsSecret(value) or type(value) ~= "number" then
                return
            end
            ApplyNumber(row, math.floor(value + 0.5))
        end,
        row
    )

    input:SetScript("OnEnterPressed", function(editBox)
        editBox:ClearFocus()
    end)
    input:SetScript("OnEditFocusLost", function(editBox)
        if row.cancelInputCommit then
            row.cancelInputCommit = false
            RefreshRow(row)
        else
            CommitInput(row)
        end
        EditBox_ClearHighlight(editBox)
    end)
    input:SetScript("OnEscapePressed", function(editBox)
        row.cancelInputCommit = true
        RefreshRow(row)
        editBox:ClearFocus()
    end)

    rows[#rows + 1] = row
    return row
end

local function EnsurePanel()
    if panel then
        return panel
    end

    local definitions = ns.Config.GetNumericDefinitions()
    local rowCount = #definitions
    local rowsHeight = (rowCount * ROW_HEIGHT) + (math.max(0, rowCount - 1) * ROW_GAP)
    local panelHeight = PANEL_ROW_TOP + rowsHeight + RESET_GAP + RESET_HEIGHT + PANEL_BOTTOM_PADDING

    panel = CreateFrame("Frame", nil, UIParent)
    panel:SetSize(PANEL_WIDTH, panelHeight)
    panel:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -250, 200)
    panel:SetFrameStrata("DIALOG")
    panel:SetFrameLevel(200)
    panel:SetMovable(true)
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(settingsPanel)
        if not IsCombatLocked() then
            settingsPanel:StartMoving()
        end
    end)
    panel:SetScript("OnDragStop", function(settingsPanel)
        settingsPanel:StopMovingOrSizing()
        settingsPanel:SetUserPlaced(false)
    end)
    panel:Hide()

    local border = CreateFrame("Frame", nil, panel, "DialogBorderTranslucentTemplate")
    border:SetAllPoints(panel)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", panel, "TOP", 0, -15)
    title:SetText("Ironfur Tracker")

    local closeButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    closeButton:SetScript("OnClick", function()
        selected = false
        if selection and selection:IsShown() then
            selection:ShowHighlighted()
        end
        panel:Hide()
    end)

    local previousRow
    for _, definition in ipairs(definitions) do
        previousRow = CreateNumericRow(panel, definition, previousRow)
    end

    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetSize(ROW_WIDTH, RESET_HEIGHT)
    resetButton:SetPoint("TOP", previousRow, "BOTTOM", 0, -RESET_GAP)
    resetButton:SetText("Reset to Defaults")
    resetButton:SetScript("OnClick", function()
        ns.Config.ResetBar()
        ns.Bar.ApplyGeometry()
        RefreshControls()
        NotifyStateChanged()
    end)

    panel:SetScript("OnHide", ClearInputFocus)
    return panel
end

local function EnsureSelection()
    if selection then
        return true
    end
    if not MinimalSliderWithSteppersMixin
        or not MinimalSliderWithSteppersMixin.Event
        or not MinimalSliderWithSteppersMixin.Event.OnValueChanged then
        return false
    end

    local barFrame = ns.Bar.GetFrame()
    selection = CreateFrame("Frame", nil, barFrame, "EditModeSystemSelectionTemplate")
    selection:SetAllPoints(barFrame)
    selection:SetSystem({
        GetSystemName = function()
            return "Ironfur Tracker"
        end,
    })

    selection:SetScript("OnMouseDown", function()
        EditMode.Select()
    end)
    selection:SetScript("OnDragStart", function()
        EditMode.StartDrag()
    end)
    selection:SetScript("OnDragStop", function()
        EditMode.StopDrag()
    end)
    selection:EnableMouse(false)
    selection:Hide()
    return true
end

local function FinishDrag()
    if not dragging then
        local barFrame = ns.Bar.GetFrame()
        if barFrame then
            barFrame:SetMovable(false)
        end
        return
    end

    local barFrame = ns.Bar.GetFrame()
    barFrame:StopMovingOrSizing()
    barFrame:SetUserPlaced(false)
    ns.Bar.CaptureCenterOffsets()
    barFrame:SetMovable(false)
    dragging = false
end

local function SuspendEditor()
    FinishDrag()
    selected = false
    ClearInputFocus()
    if panel then
        panel:StopMovingOrSizing()
        panel:SetUserPlaced(false)
        panel:Hide()
    end
    if selection then
        selection:EnableMouse(false)
        selection:Hide()
    end
end

local function ShouldShowEditor()
    return modeActive and selectionsShown and eligible and not IsCombatLocked()
end

local function RefreshEditorState()
    if not ShouldShowEditor() or not EnsureSelection() then
        SuspendEditor()
        NotifyStateChanged()
        return
    end

    selection:EnableMouse(true)
    if selected then
        selection:ShowSelected()
    else
        selection:ShowHighlighted()
    end
    NotifyStateChanged()
end

function EditMode.Select()
    if not ShouldShowEditor() or not EnsureSelection() then
        return
    end

    if hookedManager and hookedManager.ClearSelectedSystem and not IsCombatLocked() then
        hookedManager:ClearSelectedSystem()
    end

    selected = true
    selection:ShowSelected()
    EnsurePanel()
    RefreshControls()
    panel:Show()
end

function EditMode.StartDrag()
    if not ShouldShowEditor() then
        return
    end

    EditMode.Select()
    if panel then
        panel:Hide()
    end

    local barFrame = ns.Bar.GetFrame()
    barFrame:SetMovable(true)
    barFrame:StartMoving()
    dragging = true
end

function EditMode.StopDrag()
    FinishDrag()
    if selected and ShouldShowEditor() then
        EnsurePanel()
        RefreshControls()
        panel:Show()
    end
    NotifyStateChanged()
end

function EditMode.OnEnter()
    EditMode.TryAttachManager()
    modeActive = true
    selectionsShown = true
    RefreshEditorState()
end

function EditMode.OnExit()
    modeActive = false
    selectionsShown = false
    SuspendEditor()
    NotifyStateChanged()
end

function EditMode.OnSelectionsShown()
    selectionsShown = true
    if hookedManager and hookedManager.IsEditModeActive then
        modeActive = hookedManager:IsEditModeActive() and true or false
    end
    RefreshEditorState()
end

function EditMode.OnSelectionsHidden()
    selectionsShown = false
    SuspendEditor()
    NotifyStateChanged()
end

function EditMode.SetEligible(isEligible)
    eligible = isEligible and true or false
    RefreshEditorState()
end

function EditMode.SetCombatLocked(isLocked)
    combatLocked = isLocked and true or false
    RefreshEditorState()
end

function EditMode.IsPreviewActive()
    return ShouldShowEditor() and selection ~= nil and selection:IsShown()
end

function EditMode.TryAttachManager()
    local manager = EditModeManagerFrame
    if not manager or manager == hookedManager or not hooksecurefunc then
        return manager ~= nil and manager == hookedManager
    end
    if type(manager.SelectSystem) ~= "function"
        or type(manager.ShowSystemSelections) ~= "function"
        or type(manager.HideSystemSelections) ~= "function"
        or type(manager.IsEditModeActive) ~= "function" then
        return false
    end

    hooksecurefunc(manager, "SelectSystem", function()
        if hookedManager ~= manager then
            return
        end
        if selected then
            selected = false
            if panel then
                panel:Hide()
            end
            if selection and selection:IsShown() then
                selection:ShowHighlighted()
            end
        end
    end)
    if type(manager.ClearSelectedSystem) == "function" then
        hooksecurefunc(manager, "ClearSelectedSystem", function()
            if hookedManager ~= manager or not selected then
                return
            end
            selected = false
            if panel then
                panel:Hide()
            end
            if selection and selection:IsShown() then
                selection:ShowHighlighted()
            end
        end)
    end
    hooksecurefunc(manager, "ShowSystemSelections", function()
        if hookedManager == manager then
            EditMode.OnSelectionsShown()
        end
    end)
    hooksecurefunc(manager, "HideSystemSelections", function()
        if hookedManager == manager then
            EditMode.OnSelectionsHidden()
        end
    end)

    hookedManager = manager
    if manager:IsEditModeActive() then
        modeActive = true
        selectionsShown = true
        RefreshEditorState()
    end
    return true
end

function EditMode.Initialize(onStateChanged)
    stateChangedCallback = onStateChanged

    if not eventsRegistered and EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("EditMode.Enter", EditMode.OnEnter, EditMode)
        EventRegistry:RegisterCallback("EditMode.Exit", EditMode.OnExit, EditMode)
        eventsRegistered = true
    end

    EditMode.TryAttachManager()
    return eventsRegistered
end

function EditMode._GetTestState()
    local rowsByKey = {}
    for _, row in ipairs(rows) do
        rowsByKey[row.definition.key] = row
    end

    return {
        modeActive = modeActive,
        selectionsShown = selectionsShown,
        eligible = eligible,
        combatLocked = combatLocked,
        selected = selected,
        dragging = dragging,
        selection = selection,
        panel = panel,
        rows = rowsByKey,
        eventsRegistered = eventsRegistered,
        hookedManager = hookedManager,
    }
end
