local ns = _G._test_ns
local bar = ns.Bar.GetFrame()

local function Reset()
    _G._ResetWowStubs()
    EventRegistry:TriggerEvent("EditMode.Exit")
    _G._FireEvent("PLAYER_REGEN_ENABLED")
    ns.Config.ResetBar()
    ns.Bar.ApplyGeometry()
    _G._FireEvent("PLAYER_ENTERING_WORLD")
end

local function OpenSettings()
    EditModeManagerFrame:EnterEditMode()
    _G._RunFrameScript(ns.EditMode._GetTestState().selection, "OnMouseDown")
    return ns.Settings._GetTestState()
end

local function SetCheckbox(checkbox, checked)
    checkbox:SetChecked(checked)
    _G._RunFrameScript(checkbox, "OnClick", "LeftButton")
end

local function Update(now)
    _G._stubNow = now
    _G._RunFrameScript(ns.Core._GetUpdateDriver(), "OnUpdate", 0)
end

describe("Tick visibility", function()
    it("defaults to visible and preserves an explicit hidden choice across migration and reload", function()
        local saved = { schemaVersion = 8, bar = {
            tickWidth = 7, tickColor = { r = 0.2, g = 0.3, b = 0.4, a = 0.5 },
            showStacks = false, alwaysVisible = false,
        } }
        ns.Config.Initialize(saved)
        expect(saved.schemaVersion).to_equal(9)
        expect(ns.Config.GetShowTicks()).to_equal(true)
        expect(ns.Config.SetShowTicks(false)).to_equal(true)
        ns.Config.Initialize(saved)
        expect(ns.Config.GetShowTicks()).to_equal(false)
        expect(ns.Config.GetNumber("tickWidth")).to_equal(7)
        expect(select(4, ns.Config.GetColor("tickColor"))).to_equal(0.5)
        expect(ns.Config.GetShowStacks()).to_equal(false)
        expect(ns.Config.GetAlwaysVisible()).to_equal(false)
        expect(ns.Config.SetShowTicks("false")).to_equal(false)
        expect(ns.Config.SetShowTicks(_G._stubSecretValue)).to_equal(false)
        expect(ns.Config.GetShowTicks()).to_equal(false)
        saved.bar.showTicks = "invalid"
        ns.Config.Initialize(saved)
        expect(ns.Config.GetShowTicks()).to_equal(true)
        expect(ns.Config.GetNumber("tickWidth")).to_equal(7)
        Reset()
    end)

    it("hides existing and newly created preview ticks while preserving the sample and restores them on reset", function()
        Reset()
        local state = OpenSettings()
        local snapshot = ns.Bar._GetPresentationSnapshot()
        local layer = snapshot.tickLayer
        local firstTick = layer._textures[1]
        local fill = bar._value
        expect(state.showTicks:GetChecked()).to_equal(true)
        expect(layer:IsShown()).to_equal(true)
        SetCheckbox(state.showTicks, false)
        expect(layer:IsShown()).to_equal(false)
        expect(ns.Config.GetShowTicks()).to_equal(false)
        expect(bar._value).to_equal(fill)
        expect(ns.Bar._GetPresentationSnapshot().stackText).to_equal("3")
        expect(ns.Tracker._GetSnapshot().count).to_equal(0)
        ns.Bar.RenderPreview(20)
        snapshot = ns.Bar._GetPresentationSnapshot()
        expect(layer:IsShown()).to_equal(false)
        expect(snapshot.stackText).to_equal("20")
        expect(#snapshot.tickTextures).to_equal(20)
        for _, tick in ipairs(snapshot.tickTextures) do expect(tick.point[2]).to_equal(layer) end
        expect(layer._textures[1]).to_equal(firstTick)
        state.rows.tickWidth.slider:SetValue(8)
        expect(layer:IsShown()).to_equal(false)
        _G._RunFrameScript(state.resetButton, "OnClick", "LeftButton")
        expect(state.showTicks:GetChecked()).to_equal(true)
        expect(ns.Config.GetShowTicks()).to_equal(true)
        expect(layer:IsShown()).to_equal(true)
        expect(layer._textures[1]).to_equal(firstTick)
        expect(ns.Bar._GetPresentationSnapshot().stackText).to_equal("3")
        expect(ns.Tracker._GetSnapshot().count).to_equal(0)
        EditModeManagerFrame:ExitEditMode()
    end)

    it("continues live timing, stack colors, and expiry while ticks are hidden and restores their current positions", function()
        Reset()
        ns.Config.SetChoice("barColorMode", "STACKS")
        ns.Config.SetStackColor(1, 1, 0, 0, 1)
        ns.Config.SetStackColor(2, 0, 1, 0, 1)
        ns.Config.SetShowTicks(false)
        ns.Bar.ApplyAppearance()
        local layer = ns.Bar._GetPresentationSnapshot().tickLayer
        for index = 1, 2 do
            _G._stubNow = index - 1
            _G._FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-hidden-ticks-" .. index, 192081)
        end
        expect(layer:IsShown()).to_equal(false)
        expect(ns.Tracker._GetSnapshot().count).to_equal(2)
        expect(ns.Bar._GetPresentationSnapshot().stackText).to_equal("2")
        expect(bar._statusBarColor[2]).to_equal(1)
        Update(4.5)
        local position = ns.Bar._GetPresentationSnapshot().tickTextures[2].point[4]
        expect(bar._value).to_be_close_to(0.5)
        local state = OpenSettings()
        expect(state.showTicks:GetChecked()).to_equal(false)
        SetCheckbox(state.showTicks, true)
        EditModeManagerFrame:ExitEditMode()
        expect(layer:IsShown()).to_equal(true)
        expect(ns.Bar._GetPresentationSnapshot().tickTextures[2].point[4]).to_be_close_to(position)
        expect(ns.Tracker._GetSnapshot().count).to_equal(2)
        expect(bar._value).to_be_close_to(0.5)
        state = OpenSettings()
        SetCheckbox(state.showTicks, false)
        EditModeManagerFrame:ExitEditMode()
        _G._stubInCombat = true
        _G._FireEvent("PLAYER_REGEN_DISABLED")
        Update(7.1)
        expect(layer:IsShown()).to_equal(false)
        expect(ns.Tracker._GetSnapshot().count).to_equal(1)
        expect(ns.Bar._GetPresentationSnapshot().stackText).to_equal("1")
        expect(bar._statusBarColor[1]).to_equal(1)
        expect(bar._statusBarColor[2]).to_equal(0)
        Update(8.1)
        expect(layer:IsShown()).to_equal(false)
        expect(ns.Tracker._GetSnapshot().count).to_equal(0)
        expect(ns.Bar._GetPresentationSnapshot().stackText).to_equal("0")
        expect(bar._value).to_equal(0)
        expect(bar:IsShown()).to_equal(true)
        expect(ns.Core._GetUpdateDriver():IsShown()).to_equal(false)
        _G._stubInCombat = false
        _G._FireEvent("PLAYER_REGEN_ENABLED")
        expect(layer:IsShown()).to_equal(false)
    end)
end)
