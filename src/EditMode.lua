-- Ironfur Tracker: isolated Edit Mode companion UI
local _, ns = ...

local EditMode = {}
ns.EditMode = EditMode

local SUPPORTED_ENHANCE_EDIT_MODE_MINOR = 21000001
local stateChangedCallback
local eventsRegistered = false
local hookedManager
local modeActive = false
local selectionsShown = false
local eligible = false
local combatLocked = false
local selected = false
local dragging = false
local highlightsHidden = false

local selection
local FinishDrag
local overlayLibrary
local overlayButton
local observedOverlayLibraries = setmetatable({}, { __mode = "k" })
local observedOverlayButtons = setmetatable({}, { __mode = "k" })

local function IsCombatLocked()
    return combatLocked or (InCombatLockdown and InCombatLockdown())
end

local function NotifyStateChanged()
    if stateChangedCallback then
        stateChangedCallback()
    end
end

local function ApplyHighlightVisibility()
    if selection then
        selection:SetAlpha(highlightsHidden and 0 or 1)
    end
    ns.Settings.Refresh()
end

local function SyncExternalHighlightVisibility()
    if not modeActive or not overlayButton or type(overlayButton.allHidden) ~= "boolean" then
        return
    end
    highlightsHidden = overlayButton.allHidden
    ApplyHighlightVisibility()
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
    selection:HookScript("OnHide", function()
        FinishDrag(false)
        ns.Settings.Hide()
    end)
    selection:EnableMouse(false)
    selection:SetAlpha(highlightsHidden and 0 or 1)
    selection:Hide()
    return true
end

FinishDrag = function(applySnap)
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
    ns.EditModeSnap.Finish(applySnap and not IsCombatLocked())
    ns.Bar.CaptureCenterOffsets()
    barFrame:SetMovable(false)
    dragging = false
end

local function SuspendEditor()
    FinishDrag()
    selected = false
    ns.Settings.Hide()
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
    ApplyHighlightVisibility()
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
    ns.Settings.Show()
end

function EditMode.StartDrag()
    if dragging or not ShouldShowEditor() then
        return
    end

    EditMode.Select()

    local barFrame = ns.Bar.GetFrame()
    barFrame:SetMovable(true)
    barFrame:StartMoving()
    dragging = true
    ns.EditModeSnap.Begin(barFrame, selection)
end

function EditMode.StopDrag()
    FinishDrag(ShouldShowEditor())
    if selected and ShouldShowEditor() then
        ns.Settings.Show()
    end
    NotifyStateChanged()
end

function EditMode.OnEnter()
    EditMode.TryAttachManager()
    modeActive = true
    selectionsShown = true
    highlightsHidden = false
    RefreshEditorState()
    EditMode.TryAttachOverlayToggle()
    SyncExternalHighlightVisibility()
end

function EditMode.OnExit()
    modeActive = false
    selectionsShown = false
    highlightsHidden = false
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

function EditMode.AreHighlightsHidden()
    return highlightsHidden
end

function EditMode.ToggleHighlights()
    if not ShouldShowEditor() then
        return false
    end
    highlightsHidden = not highlightsHidden
    ApplyHighlightVisibility()
    return highlightsHidden
end

function EditMode.TryAttachOverlayToggle()
    -- EQoL has no global-eye callback; keep its verified private state here
    local library, minor = LibStub:GetLibrary("EnhanceQoLEditMode-1.0", true)
    if not library or minor ~= SUPPORTED_ENHANCE_EDIT_MODE_MINOR
        or type(library.RegisterCallback) ~= "function"
        or type(library.AddFrame) ~= "function" then
        overlayLibrary = nil
        overlayButton = nil
        return false
    end

    local previousLibrary, previousButton = overlayLibrary, overlayButton
    overlayLibrary = library
    if not observedOverlayLibraries[library] then
        observedOverlayLibraries[library] = true
        library:RegisterCallback("enter", function()
            if overlayLibrary == library then
                EditMode.TryAttachOverlayToggle()
                SyncExternalHighlightVisibility()
            end
        end)
        hooksecurefunc(library, "AddFrame", function()
            if overlayLibrary == library then
                EditMode.TryAttachOverlayToggle()
            end
        end)
    end

    local internal = library.internal
    local button = type(internal) == "table" and internal.managerEyeButton or nil
    if type(button) ~= "table" or type(button.HookScript) ~= "function" then
        overlayButton = nil
        return false
    end

    overlayButton = button
    if not observedOverlayButtons[button] then
        observedOverlayButtons[button] = true
        button:HookScript("OnClick", function(clickedButton)
            if overlayButton == clickedButton then
                SyncExternalHighlightVisibility()
            end
        end)
    end
    if previousLibrary ~= library or previousButton ~= button then
        SyncExternalHighlightVisibility()
    end
    return true
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
            FinishDrag(false)
            selected = false
            ns.Settings.Hide()
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
            FinishDrag(false)
            selected = false
            ns.Settings.Hide()
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
    ns.Settings.Initialize(NotifyStateChanged, function()
        selected = false
        if selection and selection:IsShown() then selection:ShowHighlighted() end
        ns.Settings.Hide()
    end, IsCombatLocked)

    if not eventsRegistered and EventRegistry and EventRegistry.RegisterCallback then
        EventRegistry:RegisterCallback("EditMode.Enter", EditMode.OnEnter, EditMode)
        EventRegistry:RegisterCallback("EditMode.Exit", EditMode.OnExit, EditMode)
        eventsRegistered = true
    end

    EditMode.TryAttachManager()
    return eventsRegistered
end

function EditMode._GetTestState()
    local settingsState = ns.Settings._GetTestState()

    return {
        modeActive = modeActive,
        selectionsShown = selectionsShown,
        eligible = eligible,
        combatLocked = combatLocked,
        selected = selected,
        dragging = dragging,
        highlightsHidden = highlightsHidden,
        overlayLibrary = overlayLibrary,
        overlayButton = overlayButton,
        selection = selection,
        panel = settingsState.panel,
        rows = settingsState.rows,
        eventsRegistered = eventsRegistered,
        hookedManager = hookedManager,
    }
end
