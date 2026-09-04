local ns = _G._test_ns
local library = assert(LibStub:GetLibrary("EnhanceQoLEditMode-1.0", true))
local dialog = CreateFrame("Frame", nil, UIParent)
local providerSelected = false
local closeCalls = 0

dialog:SetScript("OnHide", function() providerSelected = false end)

-- Installed EQoL's public close contract; its OnHide clears provider selection
local function HideSettingsDialog(self, frame, ...)
    if self ~= library or frame ~= nil or select("#", ...) ~= 0 then
        error("expected optional provider HideSettingsDialog() without a frame filter")
    end
    closeCalls = closeCalls + 1
    if not dialog:IsShown() then return false end
    dialog:Hide()
    return true
end

local function Reset()
    _G._ResetWowStubs()
    EventRegistry:TriggerEvent("EditMode.Exit")
    _G._FireEvent("PLAYER_REGEN_ENABLED")
    ns.Config.ResetBar()
    ns.Bar.ApplyGeometry()
    _G._FireEvent("PLAYER_ENTERING_WORLD")
    dialog:Hide()
    closeCalls = 0
    library.HideSettingsDialog = HideSettingsDialog
    EditModeManagerFrame:EnterEditMode()
end

local function SelectProvider()
    -- EQoL selectSelection clears Blizzard's selection before showing its dialog
    EditModeManagerFrame:ClearSelectedSystem()
    providerSelected = true
    dialog:Show()
end

local function SelectIronfur()
    _G._RunFrameScript(ns.EditMode._GetTestState().selection, "OnMouseDown")
    return ns.Settings._GetTestState()
end

describe("EnhanceQoL editor dialog handoff", function()
    it("closes the provider dialog before showing Ironfur settings and keeps it closed on repeated selection", function()
        Reset()
        SelectProvider()
        local state = SelectIronfur()
        expect(dialog:IsShown()).to_equal(false)
        expect(providerSelected).to_equal(false)
        expect(closeCalls).to_equal(1)
        expect(state.panel:IsShown()).to_equal(true)
        expect(ns.EditMode._GetTestState().selected).to_equal(true)
        expect(ns.EditMode.IsPreviewActive()).to_equal(true)
        expect(ns.Tracker._GetSnapshot().count).to_equal(0)
        SelectIronfur()
        ns.Settings.Refresh()
        expect(dialog:IsShown()).to_equal(false)
        expect(state.panel:IsShown()).to_equal(true)
        expect(closeCalls).to_equal(2)
        EditModeManagerFrame:ExitEditMode()
    end)

    it("supports switching back to the provider and preserves Ironfur dragging and hidden highlights", function()
        Reset()
        local state = SelectIronfur()
        ns.EditMode.ToggleHighlights()
        SelectProvider()
        expect(state.panel:IsShown()).to_equal(false)
        expect(dialog:IsShown()).to_equal(true)
        SelectIronfur()
        local selection = ns.EditMode._GetTestState().selection
        expect(dialog:IsShown()).to_equal(false)
        expect(state.panel:IsShown()).to_equal(true)
        expect(selection:GetAlpha()).to_equal(0)
        _G._RunFrameScript(selection, "OnDragStart")
        expect(ns.EditMode._GetTestState().dragging).to_equal(true)
        expect(state.panel:IsShown()).to_equal(true)
        expect(dialog:IsShown()).to_equal(false)
        _G._RunFrameScript(selection, "OnDragStop")
        expect(ns.EditMode._GetTestState().dragging).to_equal(false)
        expect(state.panel:IsShown()).to_equal(true)
        expect(selection:GetAlpha()).to_equal(0)
        EditModeManagerFrame:ExitEditMode()
    end)

    it("keeps Ironfur usable when the optional close API is absent and discovers it on the next selection", function()
        Reset()
        library.HideSettingsDialog = nil
        local state = SelectIronfur()
        expect(state.panel:IsShown()).to_equal(true)
        expect(closeCalls).to_equal(0)
        library.HideSettingsDialog = HideSettingsDialog
        SelectProvider()
        SelectIronfur()
        expect(dialog:IsShown()).to_equal(false)
        expect(state.panel:IsShown()).to_equal(true)
        expect(closeCalls).to_equal(1)
        EditModeManagerFrame:ExitEditMode()
    end)

    it("does not call the provider while editing is suspended and recovers after combat", function()
        Reset()
        SelectProvider()
        _G._stubInCombat = true
        _G._FireEvent("PLAYER_REGEN_DISABLED")
        ns.EditMode.Select()
        expect(closeCalls).to_equal(0)
        expect(dialog:IsShown()).to_equal(true)
        expect(ns.EditMode.IsPreviewActive()).to_equal(false)
        _G._stubInCombat = false
        _G._FireEvent("PLAYER_REGEN_ENABLED")
        local state = SelectIronfur()
        expect(closeCalls).to_equal(1)
        expect(dialog:IsShown()).to_equal(false)
        expect(state.panel:IsShown()).to_equal(true)
        EditModeManagerFrame:ExitEditMode()
    end)
end)
