local ns = _G._test_ns

local IRONFUR_SPELL_ID = 192081
local MANGLE_SPELL_ID = 33917
local FRENZIED_REGENERATION_SPELL_ID = 22842
local URSOCS_ENDURANCE_SPELL_ID = 393611
local GUARDIAN_OF_ELUNE_SPELL_ID = 155578
local WILDSHAPE_MASTERY_TALENT_ID = 441678

local eventFrame = ns.Core._GetEventFrame()
local bar = ns.Bar.GetFrame()

local function Fire(event, ...)
    _G._FireEvent(event, ...)
end

local function Update()
    _G._RunFrameScript(ns.Core._GetUpdateDriver(), "OnUpdate", 0)
end

local function Cast(spellID)
    Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", spellID)
end

local function Reset()
    _G._ResetWowStubs()
    EventRegistry:TriggerEvent("EditMode.Exit")
    Fire("PLAYER_REGEN_ENABLED")
    ns.Config.ResetBar()
    ns.Bar.ApplyGeometry()
    Fire("PLAYER_ENTERING_WORLD")
end

local function OpenEditor()
    EditModeManagerFrame:EnterEditMode()
    local state = ns.EditMode._GetTestState()
    if not state.selection then
        error("Edit Mode did not create the tracker selection", 2)
    end
    _G._RunFrameScript(state.selection, "OnMouseDown")
    return ns.EditMode._GetTestState()
end

local function FindButton(text)
    for index = #_G._allFrames, 1, -1 do
        local frame = _G._allFrames[index]
        if frame._type == "Button" and frame:GetText() == text then
            return frame
        end
    end
end

local function HookCount(methodName)
    local hooks = EditModeManagerFrame._secureHooks
        and EditModeManagerFrame._secureHooks[methodName]
    return hooks and #hooks or 0
end

describe("Loading, persistence, and lifecycle", function()
    it("loads every runtime file in exact TOC order", function()
        expect(table.concat(_G._loadedAddonFiles, ",")).to_equal(
            "src/Config.lua,src/Tracker.lua,src/Bar.lua,src/EditModeSnap.lua,src/EditMode.lua,src/Core.lua"
        )
        expect(_G._tocMetadata.SavedVariables).to_equal("IronfurTrackerDB")
    end)

    it("starts with account-wide defaults at the screen center", function()
        Reset()

        local point, relativeTo, relativePoint, offsetX, offsetY = bar:GetPoint()
        expect(IronfurTrackerDB.schemaVersion).to_equal(1)
        expect(IronfurTrackerDB.bar.width).to_equal(300)
        expect(IronfurTrackerDB.bar.height).to_equal(18)
        expect(bar:GetWidth()).to_equal(300)
        expect(bar:GetHeight()).to_equal(18)
        expect(point).to_equal("CENTER")
        expect(relativeTo).to_equal(UIParent)
        expect(relativePoint).to_equal("CENTER")
        expect(offsetX).to_equal(0)
        expect(offsetY).to_equal(0)
        expect(bar:IsShown()).to_equal(false)
    end)

    it("recovers only invalid SavedVariables fields", function()
        local persisted = {
            schemaVersion = 0,
            bar = {
                width = 640,
                height = "broken",
                offsetX = 25.6,
                offsetY = math.huge,
            },
        }

        local normalized = ns.Config.Initialize(persisted)

        expect(normalized).to_equal(persisted)
        expect(normalized.schemaVersion).to_equal(1)
        expect(normalized.bar.width).to_equal(640)
        expect(normalized.bar.height).to_equal(18)
        expect(normalized.bar.offsetX).to_equal(25.6)
        expect(normalized.bar.offsetY).to_equal(0)
        expect(IronfurTrackerDB).to_equal(persisted)
        Reset()
    end)

    it("registers the required filtered and lifecycle events once", function()
        expect(eventFrame._events.ADDON_LOADED).to_equal(true)
        expect(eventFrame._events.UNIT_SPELLCAST_SUCCEEDED).to_equal(true)
        expect(eventFrame._unitEvents.UNIT_SPELLCAST_SUCCEEDED[1]).to_equal("player")
        expect(eventFrame._events.PLAYER_SPECIALIZATION_CHANGED).to_equal(true)
        expect(eventFrame._events.TRAIT_CONFIG_UPDATED).to_equal(true)
        expect(eventFrame._events.UPDATE_SHAPESHIFT_FORM).to_equal(true)
        expect(eventFrame._events.PLAYER_REGEN_DISABLED).to_equal(true)
        expect(eventFrame._events.DISPLAY_SIZE_CHANGED).to_equal(true)
        expect(_G._GetEventRegistryCallbackCount("EditMode.Enter")).to_equal(1)
        expect(_G._GetEventRegistryCallbackCount("EditMode.Exit")).to_equal(1)
    end)
end)

local function GridSnapInfos(offsetX, offsetY)
    return {
        { frame = UIParent, point = "CENTER", relativePoint = "CENTER", distance = 1,
            offset = offsetX, isHorizontal = true },
        { frame = UIParent, point = "CENTER", relativePoint = "CENTER", distance = 1,
            offset = offsetY, isHorizontal = false },
    }
end

local function StartControlledSnapDrag(infos, centerX, centerY, enableSnap)
    local state = OpenEditor()
    EditModeManagerFrame:SetEnableSnap(enableSnap ~= false)
    _G._stubMagneticFrameInfos = infos
    _G._RunFrameScript(state.selection, "OnDragStart")
    _G._SetFrameCenter(bar, centerX, centerY)
    return state.selection
end

local function RefreshSnapPreview()
    local state = ns.EditModeSnap._GetTestState()
    _G._RunFrameScript(state.previewFrame, "OnUpdate", 0.016)
    return ns.EditModeSnap._GetTestState()
end

local function ShownSnapLineCount()
    local count = 0
    for _, line in ipairs(ns.EditModeSnap._GetTestState().lines) do
        if line:IsShown() then count = count + 1 end
    end
    return count
end

local function ExpectSnapStopped()
    local state = ns.EditModeSnap._GetTestState()
    expect(state.active).to_equal(false)
    expect(state.previewFrame:IsShown()).to_equal(false)
    expect(state.previewFrame:GetScript("OnUpdate")).to_be_nil()
    expect(ShownSnapLineCount()).to_equal(0)
end

local function ExpectOnlyUIParentAnchors()
    local point, relativeTo, relativePoint = bar:GetPoint()
    expect(point).to_equal("CENTER")
    expect(relativeTo).to_equal(UIParent)
    expect(relativePoint).to_equal("CENTER")
    for _, anchor in ipairs(bar._pointHistory or {}) do
        expect(anchor[2]).to_equal(UIParent)
    end
end

describe("Placement-only Edit Mode snapping", function()
    it("uses live snap toggles and keeps free placement when snapping is off", function()
        Reset()
        local selection = StartControlledSnapDrag(GridSnapInfos(20, 30), 1100.25, 400.75, false)
        RefreshSnapPreview()
        expect(_G._stubMagneticQueryCount).to_equal(0)
        expect(ShownSnapLineCount()).to_equal(0)

        EditModeManagerFrame:SetEnableSnap(true)
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(2)
        EditModeManagerFrame:SetEnableSnap(false)
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(0)

        _G._RunFrameScript(selection, "OnDragStop")
        expect(IronfurTrackerDB.bar.offsetX).to_equal(140.25)
        expect(IronfurTrackerDB.bar.offsetY).to_equal(-139.25)
        ExpectOnlyUIParentAnchors()
        ExpectSnapStopped()
    end)

    it("applies controlled two-axis grid output without rounding or native anchors", function()
        Reset()
        local registeredSystems = EditModeManagerFrame.registeredSystemFrames
        local magneticFrames = EditModeMagnetismManager.magneticFrames
        local nativePreview = {}
        EditModeManagerFrame.snapPreviewFrame = nativePreview
        local infos = GridSnapInfos(13.25, -47.5)
        local selection = StartControlledSnapDrag(infos, 970, 490)
        local state = RefreshSnapPreview()

        expect(state.previewFrame._allPoints[1]).to_equal(UIParent)
        expect(state.previewFrame._frameStrata).to_equal("HIGH")
        expect(state.previewFrame:IsMouseEnabled()).to_equal(false)
        expect(ShownSnapLineCount()).to_equal(2)
        expect(state.lines[1]._setupInfo).to_equal(infos[1])
        expect(state.lines[1]._setupAnchor).to_equal("CenterVertical")
        expect(state.lines[2]._setupAnchor).to_equal("CenterHorizontal")

        _G._RunFrameScript(selection, "OnDragStop")
        expect(IronfurTrackerDB.bar.offsetX).to_equal(13.25)
        expect(IronfurTrackerDB.bar.offsetY).to_equal(-47.5)
        expect(EditModeManagerFrame.registeredSystemFrames).to_equal(registeredSystems)
        expect(EditModeMagnetismManager.magneticFrames).to_equal(magneticFrames)
        expect(next(magneticFrames)).to_be_nil()
        expect(EditModeManagerFrame.snapPreviewFrame).to_equal(nativePreview)
        ExpectOnlyUIParentAnchors()
        ExpectSnapStopped()
    end)

    it("converts controlled native-element output to an independent screen position", function()
        Reset()
        local target = _G._CreateMagneticFrame(1000, 550, 200, 100)
        local info = { frame = target, point = "LEFT", relativePoint = "RIGHT",
            distance = 5, offset = 0, isHorizontal = true }
        local selection = StartControlledSnapDrag({ info }, 1255, 550)
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(1)

        _G._RunFrameScript(selection, "OnDragStop")
        local centerX, centerY = bar:GetCenter()
        expect(centerX).to_equal(1254)
        expect(centerY).to_equal(550)
        expect(IronfurTrackerDB.bar.offsetX).to_equal(294)
        expect(IronfurTrackerDB.bar.offsetY).to_equal(10)
        ExpectOnlyUIParentAnchors()

        _G._SetFrameCenter(target, 600, 300)
        local unchangedX, unchangedY = bar:GetCenter()
        expect(unchangedX).to_equal(1254)
        expect(unchangedY).to_equal(550)
        expect(target.snappedFrames).to_be_nil()
        expect(bar.snappedToFrame).to_be_nil()
        ExpectSnapStopped()
    end)

    it("clears guides for invalid own geometry and recovers during the same drag", function()
        Reset()
        local selection = StartControlledSnapDrag(GridSnapInfos(20, 30), 970, 565)
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(2)
        local queryCount = _G._stubMagneticQueryCount

        bar._rectOverride = { _G._stubSecretValue, 0, 300, 18 }
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(0)
        expect(_G._stubMagneticQueryCount).to_equal(queryCount)
        bar._rectOverride = nil
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(2)

        UIParent._effectiveScale = 0
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(0)
        UIParent._effectiveScale = nil
        EditModeMagnetismManager.topLevelParentWidth = _G._stubSecretValue
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(0)
        _G._RefreshStubMagnetismBounds()
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(2)
        _G._RunFrameScript(selection, "OnDragStop")
        ExpectSnapStopped()
    end)

    it("rejects unreadable, forbidden, hidden, or incomplete native candidates", function()
        Reset()
        local target = _G._CreateMagneticFrame(1000, 550, 200, 100)
        local info = { frame = target, point = "LEFT", relativePoint = "RIGHT",
            distance = 5, offset = 0, isHorizontal = true }
        local selection = StartControlledSnapDrag({ info }, 1255, 550)
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(1)

        local cases = {
            { object = target, key = "_forbidden", value = true },
            { object = target, key = "_forbidden", value = _G._stubSecretValue },
            { object = target.Selection, key = "_forbidden", value = _G._stubSecretValue },
            { object = target, key = "_visibleOverride", value = _G._stubSecretValue },
            { object = target.Selection, key = "_visibleOverride", value = false },
            { object = target, key = "_invalidRect", value = true },
            { object = target, key = "_scale", value = _G._stubSecretValue },
            { object = target, key = "_scale", value = math.huge },
            { object = target.Selection, key = "_rectOverride", value = { _G._stubSecretValue, 0, 200, 100 } },
            { object = target, key = "GetSelectionOffset", value = false },
        }
        for _, case in ipairs(cases) do
            local previous = case.object[case.key]
            case.object[case.key] = case.value
            local ok, failure = pcall(RefreshSnapPreview)
            local shown = ShownSnapLineCount()
            case.object[case.key] = previous
            if not ok then error(failure) end
            expect(shown).to_equal(0)
            RefreshSnapPreview()
            expect(ShownSnapLineCount()).to_equal(1)
        end

        target.Selection._points[1][4] = _G._stubSecretValue
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(0)
        target.Selection._points[1][4] = 0
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(1)
        _G._RunFrameScript(selection, "OnDragStop")
        ExpectSnapStopped()
    end)

    it("falls back to free dragging while native modules are unavailable and recovers", function()
        Reset()
        local selection = StartControlledSnapDrag(GridSnapInfos(20, 30), 970, 565)
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(2)

        local missing = {
            { object = _G, key = "EditModeManagerFrame" },
            { object = _G, key = "EditModeMagnetismManager" },
            { object = _G, key = "EditModeSystemMixin" },
            { object = _G, key = "MagnetismPreviewLineMixin" },
            { object = EditModeManagerFrame, key = "IsSnapEnabled" },
            { object = EditModeMagnetismManager, key = "GetMagneticFrameInfos" },
            { object = EditModeSystemMixin, key = "GetSnapOffsets" },
        }
        for _, case in ipairs(missing) do
            local previous = case.object[case.key]
            case.object[case.key] = nil
            local ok, failure = pcall(RefreshSnapPreview)
            local shown = ShownSnapLineCount()
            case.object[case.key] = previous
            if not ok then error(failure) end
            expect(shown).to_equal(0)
            RefreshSnapPreview()
            expect(ShownSnapLineCount()).to_equal(2)
        end
        _G._RunFrameScript(selection, "OnDragStop")
        ExpectSnapStopped()
    end)

    it("uses current bar size and scaled native geometry without losing fractions", function()
        Reset()
        ns.Config.CommitNumber("width", 400)
        ns.Config.CommitNumber("height", 30)
        ns.Bar.ApplyGeometry()
        UIParent._scale = 0.75
        _G._RefreshStubMagnetismBounds()
        local target = _G._CreateMagneticFrame(1500, 875, 100, 50, 0.8)
        local info = { frame = target, point = "RIGHT", relativePoint = "LEFT",
            distance = 5, offset = 0, isHorizontal = true }
        local selection = StartControlledSnapDrag({ info }, 955, 700)
        RefreshSnapPreview()
        expect(ShownSnapLineCount()).to_equal(1)
        _G._RunFrameScript(selection, "OnDragStop")

        local centerX, centerY = bar:GetCenter()
        expect(centerX).to_be_close_to(956.4)
        expect(centerY).to_equal(700)
        expect(IronfurTrackerDB.bar.offsetX).to_be_close_to(-3.6)
        expect(IronfurTrackerDB.bar.offsetY).to_equal(160)
        expect(bar:GetWidth()).to_equal(400)
        expect(bar:GetHeight()).to_equal(30)
        Fire("UI_SCALE_CHANGED")
        local restoredX, restoredY = bar:GetCenter()
        expect(restoredX).to_be_close_to(956.4)
        expect(restoredY).to_equal(700)
        ExpectOnlyUIParentAnchors()
        ExpectSnapStopped()
    end)

    local cancellationCases = {
        { name = "combat entry", run = function()
            _G._stubInCombat = true
            Fire("PLAYER_REGEN_DISABLED")
        end },
        { name = "Edit Mode exit", run = function() EditModeManagerFrame:ExitEditMode() end },
        { name = "hidden native selections", run = function() EditModeManagerFrame:HideSystemSelections() end },
        { name = "selection hiding", run = function(selection) selection:Hide() end },
        { name = "Guardian specialization loss", run = function()
            _G._stubSpecializationID = 105
            Fire("PLAYER_SPECIALIZATION_CHANGED", "player")
        end },
        { name = "native system selection", run = function() EditModeManagerFrame:SelectSystem({}) end },
        { name = "native deselection", run = function() EditModeManagerFrame:ClearSelectedSystem() end },
    }
    for _, case in ipairs(cancellationCases) do
        it("stops preview work and does not snap after " .. case.name, function()
            Reset()
            local selection = StartControlledSnapDrag(GridSnapInfos(20, 30), 1100.25, 400.75)
            RefreshSnapPreview()
            expect(ShownSnapLineCount()).to_equal(2)
            case.run(selection)
            expect(IronfurTrackerDB.bar.offsetX).to_equal(140.25)
            expect(IronfurTrackerDB.bar.offsetY).to_equal(-139.25)
            ExpectOnlyUIParentAnchors()
            ExpectSnapStopped()
        end)
    end

    it("reuses preview frames and lines across repeated drags", function()
        Reset()
        local selection = StartControlledSnapDrag(GridSnapInfos(20, 30), 970, 565)
        local first = RefreshSnapPreview()
        local previewFrame = first.previewFrame
        local firstLine, secondLine = first.lines[1], first.lines[2]
        local frameCount = #_G._allFrames
        _G._RunFrameScript(selection, "OnDragStop")

        _G._RunFrameScript(selection, "OnDragStart")
        _G._SetFrameCenter(bar, 970, 565)
        local second = RefreshSnapPreview()
        expect(second.previewFrame).to_equal(previewFrame)
        expect(second.lines[1]).to_equal(firstLine)
        expect(second.lines[2]).to_equal(secondLine)
        expect(#_G._allFrames).to_equal(frameCount)
        _G._RunFrameScript(selection, "OnDragStop")
        ExpectSnapStopped()
    end)
end)

describe("Ironfur timer behavior", function()
    it("shows one seven-second application in Guardian Bear Form", function()
        Reset()
        Cast(IRONFUR_SPELL_ID)

        local state = ns.Tracker._GetSnapshot()
        expect(state.count).to_equal(1)
        expect(state.ticks[1].duration).to_equal(7)
        expect(ns.Bar._GetPresentationSnapshot().stackText).to_equal("1")
        expect(bar:IsShown()).to_equal(true)
        expect(bar._value).to_equal(1)
    end)

    it("tracks overlaps and stops its driver after the final expiry", function()
        Reset()
        Cast(IRONFUR_SPELL_ID)
        _G._stubNow = 3
        Cast(IRONFUR_SPELL_ID)
        expect(ns.Tracker._GetSnapshot().count).to_equal(2)

        _G._stubNow = 7.1
        Update()
        expect(ns.Tracker._GetSnapshot().count).to_equal(1)
        expect(bar:IsShown()).to_equal(true)

        _G._stubNow = 10.1
        Update()
        expect(ns.Tracker._GetSnapshot().count).to_equal(0)
        expect(bar:IsShown()).to_equal(false)
        expect(ns.Core._GetUpdateDriver():IsShown()).to_equal(false)
    end)

    it("moves the fill left over an application's lifetime", function()
        Reset()
        Cast(IRONFUR_SPELL_ID)
        _G._stubNow = 3.5
        Update()

        expect(bar._value).to_be_close_to(0.5)
    end)

    it("ignores casts outside Guardian Druid and clears on spec loss", function()
        Reset()
        _G._stubClassToken = "MAGE"
        Fire("PLAYER_SPECIALIZATION_CHANGED", "player")
        Cast(IRONFUR_SPELL_ID)
        expect(ns.Tracker._GetSnapshot().count).to_equal(0)

        _G._stubClassToken = "DRUID"
        _G._stubSpecializationID = 104
        Fire("PLAYER_SPECIALIZATION_CHANGED", "player")
        Cast(IRONFUR_SPELL_ID)
        expect(ns.Tracker._GetSnapshot().count).to_equal(1)

        _G._stubSpecializationID = 105
        Fire("PLAYER_SPECIALIZATION_CHANGED", "player")
        expect(ns.Tracker._GetSnapshot().count).to_equal(0)
        expect(bar:IsShown()).to_equal(false)
    end)

    it("uses the current Ursoc's Endurance and Guardian of Elune durations", function()
        Reset()
        _G._stubKnownSpells[URSOCS_ENDURANCE_SPELL_ID] = true
        Cast(IRONFUR_SPELL_ID)
        expect(ns.Tracker._GetSnapshot().ticks[1].duration).to_equal(9)

        Reset()
        _G._stubKnownSpells[GUARDIAN_OF_ELUNE_SPELL_ID] = true
        Cast(MANGLE_SPELL_ID)
        Cast(IRONFUR_SPELL_ID)
        Cast(IRONFUR_SPELL_ID)
        local state = ns.Tracker._GetSnapshot()
        expect(state.ticks[1].duration).to_equal(10)
        expect(state.ticks[2].duration).to_equal(7)

        Reset()
        _G._stubKnownSpells[URSOCS_ENDURANCE_SPELL_ID] = true
        _G._stubKnownSpells[GUARDIAN_OF_ELUNE_SPELL_ID] = true
        Cast(MANGLE_SPELL_ID)
        Cast(IRONFUR_SPELL_ID)
        expect(ns.Tracker._GetSnapshot().ticks[1].duration).to_equal(12)
    end)

    it("lets Frenzied Regeneration consume Guardian of Elune", function()
        Reset()
        _G._stubKnownSpells[GUARDIAN_OF_ELUNE_SPELL_ID] = true
        Cast(MANGLE_SPELL_ID)
        Cast(FRENZIED_REGENERATION_SPELL_ID)
        Cast(IRONFUR_SPELL_ID)

        expect(ns.Tracker._GetSnapshot().ticks[1].duration).to_equal(7)
    end)
end)

describe("Bear-only presentation", function()
    it("clears applications in a form that cannot retain Ironfur", function()
        Reset()
        Cast(IRONFUR_SPELL_ID)
        _G._stubShapeshiftFormID = nil
        Fire("UPDATE_SHAPESHIFT_FORM")

        expect(ns.Tracker._GetSnapshot().count).to_equal(0)
        expect(bar:IsShown()).to_equal(false)
    end)

    it("retains timers invisibly in Cat Form with Wildshape Mastery", function()
        Reset()
        _G._stubKnownSpells[WILDSHAPE_MASTERY_TALENT_ID] = true
        Cast(IRONFUR_SPELL_ID)

        _G._stubShapeshiftFormID = 1
        Fire("UPDATE_SHAPESHIFT_FORM")
        expect(ns.Tracker._GetSnapshot().count).to_equal(1)
        expect(bar:IsShown()).to_equal(false)
        expect(ns.Core._GetUpdateDriver():IsShown()).to_equal(true)

        _G._stubNow = 3.5
        _G._stubShapeshiftFormID = 5
        Fire("UPDATE_SHAPESHIFT_FORM")
        expect(ns.Tracker._GetSnapshot().count).to_equal(1)
        expect(bar:IsShown()).to_equal(true)
        expect(bar._value).to_be_close_to(0.5)
    end)

    it("expires a retained Cat Form timer while the bar stays hidden", function()
        Reset()
        _G._stubKnownSpells[WILDSHAPE_MASTERY_TALENT_ID] = true
        Cast(IRONFUR_SPELL_ID)
        _G._stubShapeshiftFormID = 1
        Fire("UPDATE_SHAPESHIFT_FORM")

        _G._stubNow = 7.1
        Update()
        expect(ns.Tracker._GetSnapshot().count).to_equal(0)
        expect(bar:IsShown()).to_equal(false)
        expect(ns.Core._GetUpdateDriver():IsShown()).to_equal(false)
    end)

    it("hides on secret form data and recovers when combat ends", function()
        Reset()
        Cast(IRONFUR_SPELL_ID)
        _G._stubInCombat = true
        Fire("PLAYER_REGEN_DISABLED")
        _G._stubShapeshiftFormID = _G._stubSecretValue
        Fire("UPDATE_SHAPESHIFT_FORM")

        expect(ns.Core._GetPlayerState().formDisposition).to_equal("UNKNOWN")
        expect(ns.Tracker._GetSnapshot().count).to_equal(1)
        expect(bar:IsShown()).to_equal(false)

        _G._stubShapeshiftFormID = 5
        _G._stubInCombat = false
        Fire("PLAYER_REGEN_ENABLED")
        expect(ns.Tracker._GetSnapshot().count).to_equal(1)
        expect(bar:IsShown()).to_equal(true)
    end)
end)

describe("Edit Mode companion", function()
    it("shows a Guardian preview, opens settings, and yields to native selection", function()
        Reset()
        local registeredSystems = EditModeManagerFrame.registeredSystemFrames
        local registeredSentinel = registeredSystems[1]

        EditModeManagerFrame:EnterEditMode()
        local state = ns.EditMode._GetTestState()
        expect(state.selection ~= nil).to_equal(true)
        expect(state.selection:IsShown()).to_equal(true)
        expect(state.selection:IsMouseEnabled()).to_equal(true)
        expect(state.selection._system:GetSystemName()).to_equal("Ironfur Tracker")
        expect(ns.Bar._GetPresentationSnapshot().stackText).to_equal("")
        expect(bar:IsShown()).to_equal(true)

        _G._RunFrameScript(state.selection, "OnMouseDown")
        state = ns.EditMode._GetTestState()
        expect(state.selected).to_equal(true)
        expect(state.panel:IsShown()).to_equal(true)
        expect(state.panel:IsMovable()).to_equal(true)
        expect(state.panel._dragButtons[1]).to_equal("LeftButton")
        expect(state.rows.width ~= nil).to_equal(true)
        expect(state.rows.height ~= nil).to_equal(true)

        local nativeSystem = {}
        EditModeManagerFrame:SelectSystem(nativeSystem)
        state = ns.EditMode._GetTestState()
        expect(state.selected).to_equal(false)
        expect(state.panel:IsShown()).to_equal(false)
        expect(EditModeManagerFrame.registeredSystemFrames).to_equal(registeredSystems)
        expect(EditModeManagerFrame.registeredSystemFrames[1]).to_equal(registeredSentinel)

        _G._RunFrameScript(state.selection, "OnMouseDown")
        expect(ns.EditMode._GetTestState().panel:IsShown()).to_equal(true)
        EditModeManagerFrame:ClearSelectedSystem()
        state = ns.EditMode._GetTestState()
        expect(state.selected).to_equal(false)
        expect(state.panel:IsShown()).to_equal(false)

        EditModeManagerFrame:ExitEditMode()
        expect(bar:IsShown()).to_equal(false)
        expect(state.selection:IsShown()).to_equal(false)
    end)

    it("does not expose the editor to a non-Guardian character", function()
        Reset()
        _G._stubSpecializationID = 105
        Fire("PLAYER_SPECIALIZATION_CHANGED", "player")
        EditModeManagerFrame:EnterEditMode()

        local state = ns.EditMode._GetTestState()
        expect(state.eligible).to_equal(false)
        expect(state.selection:IsShown()).to_equal(false)
        expect(bar:IsShown()).to_equal(false)
        EditModeManagerFrame:ExitEditMode()
    end)

    it("persists drag offsets and safely suspends a drag on combat entry", function()
        Reset()
        local state = OpenEditor()
        _G._RunFrameScript(state.selection, "OnDragStart")
        state = ns.EditMode._GetTestState()
        expect(state.dragging).to_equal(true)
        expect(bar._moving).to_equal(true)

        _G._SetFrameCenter(bar, 1120, 460)
        _G._RunFrameScript(state.selection, "OnDragStop")
        expect(IronfurTrackerDB.bar.offsetX).to_equal(160)
        expect(IronfurTrackerDB.bar.offsetY).to_equal(-80)
        expect(bar._moving).to_equal(false)
        expect(bar:IsMovable()).to_equal(false)

        state = ns.EditMode._GetTestState()
        _G._RunFrameScript(state.selection, "OnDragStart")
        _G._SetFrameCenter(bar, _G._stubSecretValue, 700)
        _G._RunFrameScript(state.selection, "OnDragStop")
        local _, _, _, recoveredX, recoveredY = bar:GetPoint()
        expect(IronfurTrackerDB.bar.offsetX).to_equal(160)
        expect(IronfurTrackerDB.bar.offsetY).to_equal(-80)
        expect(recoveredX).to_equal(160)
        expect(recoveredY).to_equal(-80)

        state = ns.EditMode._GetTestState()
        _G._RunFrameScript(state.selection, "OnDragStart")
        _G._SetFrameCenter(bar, 1200, 600)
        _G._stubInCombat = true
        Fire("PLAYER_REGEN_DISABLED")

        state = ns.EditMode._GetTestState()
        expect(state.combatLocked).to_equal(true)
        expect(state.dragging).to_equal(false)
        expect(state.selection:IsShown()).to_equal(false)
        expect(state.panel:IsShown()).to_equal(false)
        expect(bar._moving).to_equal(false)
        expect(IronfurTrackerDB.bar.offsetX).to_equal(240)
        expect(IronfurTrackerDB.bar.offsetY).to_equal(60)
        expect(bar:IsShown()).to_equal(false)
    end)

    it("synchronizes width and height through sliders and numeric input", function()
        Reset()
        Cast(IRONFUR_SPELL_ID)
        local state = OpenEditor()
        local widthRow = state.rows.width
        local heightRow = state.rows.height

        expect(widthRow.input:GetWidth()).to_equal(48)
        expect(heightRow.input:GetWidth()).to_equal(48)

        widthRow.slider:SetValue(600)
        expect(IronfurTrackerDB.bar.width).to_equal(600)
        expect(widthRow.input:GetText()).to_equal("600")
        expect(bar:GetWidth()).to_equal(600)

        heightRow.input:SetFocus()
        heightRow.input:SetText("40")
        _G._RunFrameScript(heightRow.input, "OnEnterPressed")
        expect(IronfurTrackerDB.bar.height).to_equal(40)
        expect(heightRow.slider._value).to_equal(40)
        expect(bar:GetHeight()).to_equal(40)
        expect(ns.Bar._GetPresentationSnapshot().tickTextures[1].height).to_equal(38)

        _G._stubNow = 3.5
        EditModeManagerFrame:ExitEditMode()
        local liveTexture = ns.Bar._GetPresentationSnapshot().tickTextures[1]
        expect(liveTexture.shown).to_equal(true)
        expect(liveTexture.point[4]).to_be_close_to(300)

        _G._stubNow = 7.1
        Update()
        expect(ns.Bar._GetPresentationSnapshot().tickTextures[1].shown).to_equal(false)

        state = OpenEditor()
        heightRow = state.rows.height
        heightRow.input:SetFocus()
        heightRow.input:SetText("50")
        _G._RunFrameScript(heightRow.input, "OnEditFocusLost")
        expect(ns.Bar._GetPresentationSnapshot().tickTextures[1].height).to_equal(48)
    end)

    it("clamps range overflow and restores invalid numeric input", function()
        Reset()
        local state = OpenEditor()
        local widthInput = state.rows.width.input
        local heightInput = state.rows.height.input

        widthInput:SetFocus()
        widthInput:SetText("1")
        _G._RunFrameScript(widthInput, "OnEnterPressed")
        expect(IronfurTrackerDB.bar.width).to_equal(80)
        expect(widthInput:GetText()).to_equal("80")
        expect(state.rows.width.slider._value).to_equal(80)

        heightInput:SetFocus()
        heightInput:SetText("9999")
        _G._RunFrameScript(heightInput, "OnEnterPressed")
        expect(IronfurTrackerDB.bar.height).to_equal(128)
        expect(heightInput:GetText()).to_equal("128")

        heightInput:SetFocus()
        heightInput:SetText("")
        _G._RunFrameScript(heightInput, "OnEnterPressed")
        expect(IronfurTrackerDB.bar.height).to_equal(128)
        expect(heightInput:GetText()).to_equal("128")

        heightInput:SetFocus()
        heightInput:SetText("12.5")
        _G._RunFrameScript(heightInput, "OnEnterPressed")
        expect(IronfurTrackerDB.bar.height).to_equal(128)
        expect(heightInput:GetText()).to_equal("128")

        heightInput:SetFocus()
        heightInput:SetText("not-a-number")
        _G._RunFrameScript(heightInput, "OnEnterPressed")
        expect(IronfurTrackerDB.bar.height).to_equal(128)
        expect(heightInput:GetText()).to_equal("128")

        heightInput:SetFocus()
        heightInput:SetText("40")
        _G._RunFrameScript(heightInput, "OnEscapePressed")
        expect(IronfurTrackerDB.bar.height).to_equal(128)
        expect(heightInput:GetText()).to_equal("128")
        expect(heightInput._highlightCleared).to_equal(true)
    end)

    it("resets size and position through the panel button", function()
        Reset()
        local state = OpenEditor()
        state.rows.width.slider:SetValue(700)
        state.rows.height.input:SetFocus()
        state.rows.height.input:SetText("44")
        _G._RunFrameScript(state.rows.height.input, "OnEnterPressed")
        ns.Config.SetPosition(100, 50)
        ns.Bar.ApplyGeometry()

        local resetButton = FindButton("Reset to Defaults")
        expect(resetButton ~= nil).to_equal(true)
        expect(resetButton:GetWidth()).to_equal(state.rows.width:GetWidth())
        expect(resetButton:GetHeight()).to_equal(28)
        _G._RunFrameScript(resetButton, "OnClick")

        local _, _, _, offsetX, offsetY = bar:GetPoint()
        expect(IronfurTrackerDB.bar.width).to_equal(300)
        expect(IronfurTrackerDB.bar.height).to_equal(18)
        expect(IronfurTrackerDB.bar.offsetX).to_equal(0)
        expect(IronfurTrackerDB.bar.offsetY).to_equal(0)
        expect(bar:GetWidth()).to_equal(300)
        expect(bar:GetHeight()).to_equal(18)
        expect(offsetX).to_equal(0)
        expect(offsetY).to_equal(0)
    end)

    it("does not duplicate frames, callbacks, or hooks on repeated setup", function()
        Reset()
        local state = OpenEditor()
        expect(state.panel ~= nil).to_equal(true)
        EditModeManagerFrame:ExitEditMode()

        local frameCount = #_G._allFrames
        local enterCallbacks = _G._GetEventRegistryCallbackCount("EditMode.Enter")
        local exitCallbacks = _G._GetEventRegistryCallbackCount("EditMode.Exit")
        local selectHooks = HookCount("SelectSystem")
        local clearHooks = HookCount("ClearSelectedSystem")
        local showHooks = HookCount("ShowSystemSelections")
        local hideHooks = HookCount("HideSystemSelections")

        Fire("ADDON_LOADED", "IronfurTracker")
        Fire("ADDON_LOADED", "IronfurTracker")
        EditModeManagerFrame:EnterEditMode()
        EditModeManagerFrame:ExitEditMode()
        EditModeManagerFrame:EnterEditMode()
        EditModeManagerFrame:ExitEditMode()

        expect(#_G._allFrames).to_equal(frameCount)
        expect(_G._GetEventRegistryCallbackCount("EditMode.Enter")).to_equal(enterCallbacks)
        expect(_G._GetEventRegistryCallbackCount("EditMode.Exit")).to_equal(exitCallbacks)
        expect(HookCount("SelectSystem")).to_equal(selectHooks)
        expect(HookCount("ClearSelectedSystem")).to_equal(clearHooks)
        expect(HookCount("ShowSystemSelections")).to_equal(showHooks)
        expect(HookCount("HideSystemSelections")).to_equal(hideHooks)
    end)

    it("does not create a slash-command surface", function()
        expect(next(SlashCmdList)).to_be_nil()
        for key in pairs(_G) do
            if type(key) == "string" and key:match("^SLASH_IRONFURTRACKER") then
                error("unexpected slash-command global: " .. key)
            end
        end
    end)
end)
