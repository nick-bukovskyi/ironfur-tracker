local ns = _G._test_ns
local bar = ns.Bar.GetFrame()
local sharedMedia = LibStub("LibSharedMedia-3.0")

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

local function ExpectColor(key, r, g, b, a)
    local actualR, actualG, actualB, actualA = ns.Config.GetColor(key)
    expect(actualR).to_be_close_to(r)
    expect(actualG).to_be_close_to(g)
    expect(actualB).to_be_close_to(b)
    expect(actualA).to_be_close_to(a)
end

local function ExpectTickColor(r, g, b, a)
    local markers = ns.Bar._GetPresentationSnapshot().tickTextures
    local textures = markers[1].point[2]._textures
    for _, texture in ipairs(textures) do
        expect(texture._color[1]).to_be_close_to(r)
        expect(texture._color[2]).to_be_close_to(g)
        expect(texture._color[3]).to_be_close_to(b)
        expect(texture._color[4]).to_be_close_to(a)
    end
end

local function FindBorder()
    for _, child in ipairs(bar._children) do
        if child._template == "BackdropTemplate" then return child end
    end
    error("bar border is missing")
end

describe("Appearance persistence and media recovery", function()
    it("migrates texture aliases while preserving colors and custom media, and applies new colors only on reset", function()
        local saved = { schemaVersion = 7, bar = {
            barTexture = "Default", backdropTexture = "Default", borderTexture = "Default",
            backdropColor = { r = 0.055, g = 0.065, b = 0.08, a = 0.92 },
            textColor = { r = 1, g = 0.96, b = 0.86, a = 1 },
            borderColor = { r = 0.01, g = 0.01, b = 0.015, a = 1 },
        } }
        ns.Config.Initialize(saved)
        expect(saved.schemaVersion).to_equal(10)
        for _, key in ipairs({ "barTexture", "backdropTexture", "borderTexture" }) do
            expect(ns.Config.GetTexture(key)).to_equal("Solid")
            expect(ns.Config.SetTexture(key, "Default")).to_equal(false)
            expect(ns.Config.GetTexture(key)).to_equal("Solid")
        end
        ExpectColor("backdropColor", 0.055, 0.065, 0.08, 0.92)
        ExpectColor("textColor", 1, 0.96, 0.86, 1)
        ExpectColor("borderColor", 0.01, 0.01, 0.015, 1)
        saved.bar.barTexture = "Blizzard"
        saved.bar.backdropTexture = "Unavailable custom backdrop"
        saved.bar.borderTexture = "Blizzard Tooltip"
        ns.Config.Initialize(saved)
        expect(ns.Config.GetTexture("barTexture")).to_equal("Blizzard")
        expect(ns.Config.GetTexture("backdropTexture")).to_equal("Unavailable custom backdrop")
        expect(ns.Config.GetTexture("borderTexture")).to_equal("Blizzard Tooltip")
        ExpectColor("backdropColor", 0.055, 0.065, 0.08, 0.92)
        ExpectColor("textColor", 1, 0.96, 0.86, 1)
        ExpectColor("borderColor", 0.01, 0.01, 0.015, 1)
        Reset()
        ExpectColor("backdropColor", 0, 0, 0, 0.8)
        ExpectColor("textColor", 1, 1, 1, 1)
        ExpectColor("borderColor", 0, 0, 0, 1)
    end)

    it("offers one built-in Solid texture in every texture menu despite reserved provider names", function()
        Reset()
        local foreignPath = "Interface\\AddOns\\TestMedia\\foreign-solid.tga"
        _G._stubKnownFileAssets[foreignPath] = true
        -- Statusbar Solid is already registered by the real bundled library
        expect(sharedMedia:Register("statusbar", "Solid", foreignPath)).to_equal(false)
        expect(sharedMedia:Register("border", "Solid", foreignPath)).to_equal(true)
        expect(sharedMedia:Register("statusbar", "Default", foreignPath)).to_equal(true)
        expect(sharedMedia:Register("border", "Default", foreignPath)).to_equal(true)
        local state = OpenSettings()
        local builtIn = "Interface\\Buttons\\WHITE8X8"
        for _, entry in ipairs({ { "barTexture", "statusbar" }, { "backdropTexture", "statusbar" },
            { "borderTexture", "border" } }) do
            local key, mediaType = entry[1], entry[2]
            local dropdown = state.textures[key].dropdown
            local menu = _G._OpenDropdown(dropdown)
            local solidCount = 0
            expect(menu.entries[1].text).to_equal("Solid")
            for _, item in ipairs(menu.entries) do
                expect(item.text == "Default").to_equal(false)
                if item.text == "Solid" then solidCount = solidCount + 1 end
            end
            expect(solidCount).to_equal(1)
            _G._SelectDropdown(dropdown, "Solid")
            expect(ns.Config.GetTexture(key)).to_equal("Solid")
            expect(ns.Media.Resolve(mediaType, "Solid")).to_equal(builtIn)
        end
        expect(bar._statusBarTexture).to_equal(builtIn)
        expect(ns.Bar._GetPresentationSnapshot().backdropRegion._texture).to_equal(builtIn)
        expect(FindBorder()._backdrop.edgeFile).to_equal(builtIn)
        local fontPath = "Interface\\AddOns\\TestMedia\\solid-font.ttf"
        _G._stubKnownFileAssets[fontPath], _G._stubFontSetResults[fontPath] = true, true
        expect(sharedMedia:Register("font", "Solid", fontPath)).to_equal(true)
        _G._SelectDropdown(state.fontFamily.dropdown, "Solid")
        expect(ns.Config.GetFontFamily()).to_equal("Solid")
        expect(ns.Media.Resolve("font", "Solid")).to_equal(fontPath)
        EditModeManagerFrame:ExitEditMode()
    end)

    it("preserves upgraded placement and repairs only invalid appearance channels", function()
        local saved = {
            schemaVersion = 1,
            bar = { width = 450, height = 40, offsetX = 12.5, offsetY = -20,
                barColor = { r = 0.2, g = "broken", b = 0.6, a = 0.4 },
                borderColor = { r = 0.3, g = 0.4, b = 0.5, a = 0.6 },
                barTexture = "Unavailable saved texture", alwaysVisible = false },
        }
        ns.Config.Initialize(saved)
        expect(IronfurTrackerDB).to_equal(saved)
        expect(saved.schemaVersion).to_equal(10)
        expect(saved.bar.width).to_equal(450)
        expect(saved.bar.offsetX).to_equal(12.5)
        expect(saved.bar.offsetY).to_equal(-20)
        expect(saved.bar.alwaysVisible).to_equal(false)
        expect(saved.bar.barTexture).to_equal("Unavailable saved texture")
        ExpectColor("barColor", 0.2, 0.38, 0.6, 0.4)
        ExpectColor("borderColor", 0.3, 0.4, 0.5, 0.6)
        Reset()
    end)

    it("upgrades schema 2 without replacing appearance and repairs invalid tick fields individually", function()
        local saved = {
            schemaVersion = 2,
            bar = { width = 510, height = 24, offsetX = 13, offsetY = -21,
                barColor = { r = 0.2, g = 0.3, b = 0.4, a = 0.5 },
                borderColor = { r = 0.6, g = 0.7, b = 0.8, a = 0.9 },
                barTexture = "Blizzard", borderTexture = "Blizzard Tooltip",
                borderSize = 8, borderOffset = -4, alwaysVisible = false },
        }
        ns.Config.Initialize(saved)
        expect(saved.schemaVersion).to_equal(10)
        expect(saved.bar.tickWidth).to_equal(2)
        ExpectColor("tickColor", 1, 1, 1, 1)
        expect(saved.bar.width).to_equal(510)
        expect(saved.bar.offsetX).to_equal(13)
        expect(saved.bar.offsetY).to_equal(-21)
        expect(saved.bar.borderSize).to_equal(8)
        expect(saved.bar.borderOffset).to_equal(-4)
        expect(saved.bar.barTexture).to_equal("Blizzard")
        expect(saved.bar.borderTexture).to_equal("Blizzard Tooltip")
        expect(saved.bar.alwaysVisible).to_equal(false)
        ExpectColor("barColor", 0.2, 0.3, 0.4, 0.5)
        ExpectColor("borderColor", 0.6, 0.7, 0.8, 0.9)

        saved.bar.tickWidth = 2.5
        saved.bar.tickColor = { r = 0.25, g = math.huge, b = 0.75, a = "broken" }
        ns.Config.Initialize(saved)
        expect(saved.bar.tickWidth).to_equal(2)
        ExpectColor("tickColor", 0.25, 1, 0.75, 1)
        expect(saved.bar.borderSize).to_equal(8)
        ExpectColor("barColor", 0.2, 0.3, 0.4, 0.5)
        saved.bar.tickWidth = 13
        ns.Config.Initialize(saved)
        expect(saved.bar.tickWidth).to_equal(13)
        Reset()
    end)

    it("falls back for missing media and recovers both textures when their provider registers", function()
        Reset()
        local fillName, borderName = "Test provider fill", "Test provider border"
        local fillPath = "Interface\\AddOns\\TestMedia\\fill.tga"
        local borderPath = "Interface\\AddOns\\TestMedia\\border.tga"
        ns.Config.SetTexture("barTexture", fillName)
        ns.Config.SetTexture("borderTexture", borderName)
        ns.Bar.ApplyAppearance()
        local fallback = ns.Media.Resolve("statusbar", "Solid")
        expect(bar._statusBarTexture).to_equal(fallback)
        expect(FindBorder()._backdrop.edgeFile).to_equal(ns.Media.Resolve("border", "Solid"))
        local state = OpenSettings()
        expect(state.textures.barTexture.dropdown:GetText()).to_equal(fillName)
        expect(ns.Config.GetTexture("barTexture")).to_equal(fillName)

        _G._stubKnownFileAssets[fillPath], _G._stubKnownFileAssets[borderPath] = true, true
        expect(sharedMedia:Register("statusbar", fillName, fillPath)).to_equal(true)
        expect(bar._statusBarTexture).to_equal(fillPath)
        expect(state.textures.barTexture.dropdown:GetText()).to_equal(fillName)
        _G._SelectDropdown(state.textures.barTexture.dropdown, fillName)
        expect(sharedMedia:Register("border", borderName, borderPath)).to_equal(true)
        expect(FindBorder()._backdrop.edgeFile).to_equal(borderPath)
        expect(state.textures.borderTexture.dropdown:GetText()).to_equal(borderName)
        _G._SelectDropdown(state.textures.borderTexture.dropdown, borderName)
        expect(ns.Config.GetTexture("borderTexture")).to_equal(borderName)
        EditModeManagerFrame:ExitEditMode()
    end)

    it("selects fill and border media from named menu entries with matching previews", function()
        Reset()
        local state = OpenSettings()
        local fill = state.textures.barTexture.dropdown
        local border = state.textures.borderTexture.dropdown
        _G._OpenDropdown(fill)
        expect(fill._menuDescription.entries[1].text).to_equal("Solid")
        for index, entry in ipairs(fill._menuDescription.entries) do
            expect(fill._menuRows[index]._previewTexture._texture).to_equal(ns.Media.Resolve("statusbar", entry.text))
        end
        _G._OpenDropdown(border)
        for index, entry in ipairs(border._menuDescription.entries) do
            expect(border._menuRows[index]._previewBorder._backdrop.edgeFile).to_equal(ns.Media.Resolve("border", entry.text))
        end
        _G._SelectDropdown(fill, "Blizzard")
        _G._SelectDropdown(border, "Blizzard Tooltip")
        expect(ns.Config.GetTexture("barTexture")).to_equal("Blizzard")
        expect(bar._statusBarTexture).to_equal(ns.Media.Resolve("statusbar", "Blizzard"))
        expect(ns.Config.GetTexture("borderTexture")).to_equal("Blizzard Tooltip")
        expect(FindBorder()._backdrop.edgeFile).to_equal(ns.Media.Resolve("border", "Blizzard Tooltip"))
        EditModeManagerFrame:ExitEditMode()
    end)
end)

describe("Appearance control transactions", function()
    it("applies the visibility checkbox after leaving the editor sample", function()
        Reset()
        local state = OpenSettings()
        expect(state.alwaysVisible:GetChecked()).to_equal(true)
        state.alwaysVisible:SetChecked(false)
        _G._RunFrameScript(state.alwaysVisible, "OnClick")
        expect(ns.Config.GetAlwaysVisible()).to_equal(false)
        expect(bar:IsShown()).to_equal(true)
        EditModeManagerFrame:ExitEditMode()
        expect(bar:IsShown()).to_equal(false)
        _G._FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-visibility", 192081)
        expect(bar:IsShown()).to_equal(true)
        _G._stubNow = 8
        _G._RunFrameScript(ns.Core._GetUpdateDriver(), "OnUpdate", 0)
        expect(bar:IsShown()).to_equal(false)
        state = OpenSettings()
        state.alwaysVisible:SetChecked(true)
        _G._RunFrameScript(state.alwaysVisible, "OnClick")
        EditModeManagerFrame:ExitEditMode()
        expect(bar:IsShown()).to_equal(true)
        expect(ns.Bar._GetPresentationSnapshot().stackText).to_equal("0")
        expect(ns.Core._GetUpdateDriver():IsShown()).to_equal(false)
    end)

    it("centers settings initially, fits viewport changes, and retains a dragged position when reopened", function()
        Reset()
        local state = OpenSettings()
        local panel = state.panel
        local point, relativeTo, relativePoint, x, y = panel:GetPoint()
        expect(point).to_equal("RIGHT")
        expect(relativeTo).to_equal(UIParent)
        expect(relativePoint).to_equal("RIGHT")
        expect(x).to_equal(-250)
        expect(y).to_equal(0)
        expect(panel._clampedToScreen).to_equal(true)
        local originalHeight = UIParent:GetHeight()
        for _, viewport in ipairs({ { 300, "DISPLAY_SIZE_CHANGED" }, { 1600, "UI_SCALE_CHANGED" } }) do
            UIParent:SetHeight(viewport[1])
            _G._FireEvent(viewport[2])
            expect(panel:GetHeight() <= viewport[1] - 80).to_equal(true)
            if viewport[1] == 300 then
                expect(panel:GetHeight()).to_equal(220)
                expect(state.scrollFrame:GetVerticalScrollRange() > 0).to_equal(true)
            else
                expect(state.scrollFrame:GetVerticalScrollRange()).to_equal(0)
            end
            local _, resetParent, _, resetX, resetY = state.resetButton:GetPoint()
            expect(resetParent).to_equal(panel)
            expect(-resetY + state.resetButton:GetHeight() + 25).to_equal(panel:GetHeight())
            expect(resetX * 2 + state.resetButton:GetWidth()).to_equal(panel:GetWidth())
        end
        _G._RunFrameScript(panel, "OnDragStart")
        expect(panel._moving).to_equal(true)
        -- Supply the native drag's final anchor without emulating screen geometry
        panel:ClearAllPoints()
        panel:SetPoint("CENTER", UIParent, "CENTER", -120, 40)
        _G._RunFrameScript(panel, "OnDragStop")
        local frameCount = #_G._allFrames
        for _ = 1, 3 do
            ns.Settings.Refresh()
            ns.Settings.Hide()
            UIParent:SetHeight(400)
            _G._FireEvent("DISPLAY_SIZE_CHANGED")
            expect(panel:IsShown()).to_equal(false)
            expect(OpenSettings().panel).to_equal(panel)
            expect(panel:GetHeight()).to_equal(320)
            expect(panel:GetPoint()).to_equal("CENTER")
            expect(select(4, panel:GetPoint())).to_equal(-120)
            expect(select(5, panel:GetPoint())).to_equal(40)
        end
        expect(#_G._allFrames).to_equal(frameCount)
        panel:ClearAllPoints()
        panel:SetPoint(point, relativeTo, relativePoint, x, y)
        UIParent:SetHeight(originalHeight)
        _G._FireEvent("UI_SCALE_CHANGED")
        EditModeManagerFrame:ExitEditMode()
    end)

    it("previews color and alpha immediately, restores cancel, and retains accept", function()
        Reset()
        local state = OpenSettings()
        _G._SelectDropdown(state.choices.barColorMode.dropdown, "Solid")
        _G._RunFrameScript(state.colors.barColor.button, "OnClick")
        _G._SetPickerColor(0.2, 0.3, 0.4, 0.5)
        ExpectColor("barColor", 0.2, 0.3, 0.4, 0.5)
        expect(bar._statusBarColor[4]).to_equal(0.5)
        _G._CancelPicker()
        ExpectColor("barColor", 0.91, 0.38, 0.08, 0.92)

        _G._RunFrameScript(state.colors.tickColor.button, "OnClick")
        _G._SetPickerColor(0.15, 0.25, 0.35, 0.45)
        ExpectColor("tickColor", 0.15, 0.25, 0.35, 0.45)
        ExpectTickColor(0.15, 0.25, 0.35, 0.45)
        _G._CancelPicker()
        ExpectColor("tickColor", 1, 1, 1, 1)
        ExpectTickColor(1, 1, 1, 1)
        _G._RunFrameScript(state.colors.tickColor.button, "OnClick")
        _G._SetPickerColor(0.15, 0.25, 0.35, 0.45)
        _G._AcceptPicker()

        _G._RunFrameScript(state.colors.borderColor.button, "OnClick")
        _G._SetPickerColor(0.6, 0.7, 0.8, 0.9)
        _G._AcceptPicker()
        EditModeManagerFrame:ExitEditMode()
        ExpectColor("borderColor", 0.6, 0.7, 0.8, 0.9)
        expect(FindBorder()._borderColor[1]).to_equal(0.6)
        _G._FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-tick-color", 192081)
        ExpectTickColor(0.15, 0.25, 0.35, 0.45)
    end)

    it("cancels tick color previews on combat and ignores their later callbacks", function()
        Reset()
        local state = OpenSettings()
        _G._RunFrameScript(state.colors.tickColor.button, "OnClick")
        local staleUpdate = ColorPickerFrame.swatchFunc
        _G._SetPickerColor(0.1, 0.2, 0.3, 0.4)
        _G._stubInCombat = true
        _G._FireEvent("PLAYER_REGEN_DISABLED")
        expect(state.panel:IsShown()).to_equal(false)
        expect(ColorPickerFrame:IsShown()).to_equal(false)
        ExpectColor("tickColor", 1, 1, 1, 1)
        ExpectTickColor(1, 1, 1, 1)
        staleUpdate()
        ExpectColor("tickColor", 1, 1, 1, 1)
        _G._stubInCombat = false
        _G._FireEvent("PLAYER_REGEN_ENABLED")
        state = OpenSettings()
        _G._RunFrameScript(state.colors.tickColor.button, "OnClick")
        _G._SetPickerColor(0.3, 0.4, 0.5, 0.6)
        _G._AcceptPicker()
        ExpectColor("tickColor", 0.3, 0.4, 0.5, 0.6)
        ExpectTickColor(0.3, 0.4, 0.5, 0.6)
        EditModeManagerFrame:ExitEditMode()
    end)

    it("does not close another add-on's replacement color picker", function()
        Reset()
        local state = OpenSettings()
        _G._SelectDropdown(state.choices.barColorMode.dropdown, "Solid")
        _G._RunFrameScript(state.colors.barColor.button, "OnClick")
        _G._SetPickerColor(0.2, 0.3, 0.4, 0.5)
        local foreignOwner = {}
        ColorPickerFrame:SetupColorPickerAndShow({ r = 1, g = 1, b = 1,
            extraInfo = foreignOwner, swatchFunc = function() end })
        EditModeManagerFrame:ExitEditMode()
        expect(ColorPickerFrame:GetExtraInfo()).to_equal(foreignOwner)
        expect(ColorPickerFrame:IsShown()).to_equal(true)
        ExpectColor("barColor", 0.91, 0.38, 0.08, 0.92)
        ColorPickerFrame:Hide()
    end)

    it("resets every appearance setting while cancelling focused input and color preview", function()
        Reset()
        local state = OpenSettings()
        ns.Config.SetTexture("barTexture", "Blizzard")
        ns.Config.SetTexture("borderTexture", "Blizzard Tooltip")
        ns.Config.SetAlwaysVisible(false)
        ns.Config.SetPosition(40, -50)
        state.rows.borderSize.slider:SetValue(7)
        state.rows.tickWidth.slider:SetValue(14)
        ns.Config.SetColor("barColor", 0.5, 0.6, 0.7, 0.8)
        _G._RunFrameScript(state.colors.tickColor.button, "OnClick")
        _G._SetPickerColor(0.1, 0.2, 0.3, 0.4)
        local staleUpdate = ColorPickerFrame.swatchFunc
        state.rows.borderOffset.input:SetFocus()
        state.rows.borderOffset.input:SetText("-12")
        _G._RunFrameScript(state.resetButton, "OnClick")
        staleUpdate()
        expect(ns.Config.GetNumber("borderSize")).to_equal(1)
        expect(ns.Config.GetNumber("borderOffset")).to_equal(0)
        expect(ns.Config.GetNumber("tickWidth")).to_equal(2)
        expect(ns.Config.GetTexture("barTexture")).to_equal("Solid")
        expect(ns.Config.GetTexture("borderTexture")).to_equal("Solid")
        expect(ns.Config.GetAlwaysVisible()).to_equal(true)
        expect(IronfurTrackerDB.bar.offsetX).to_equal(0)
        expect(IronfurTrackerDB.bar.offsetY).to_equal(0)
        ExpectColor("barColor", 0.91, 0.38, 0.08, 0.92)
        ExpectColor("tickColor", 1, 1, 1, 1)
        ExpectTickColor(1, 1, 1, 1)
        expect(ColorPickerFrame:IsShown()).to_equal(false)
        expect(state.rows.borderOffset.input:HasFocus()).to_equal(false)
        EditModeManagerFrame:ExitEditMode()
    end)

    it("accepts signed border offsets and clamps appearance without losing the requested setting", function()
        Reset()
        local state = OpenSettings()
        local input = state.rows.borderOffset.input
        input:SetFocus()
        input:SetText("-20")
        _G._RunFrameScript(input, "OnEnterPressed")
        expect(ns.Config.GetNumber("borderOffset")).to_equal(-20)
        expect(state.rows.borderOffset.slider._value).to_equal(-20)
        state.rows.height.slider:SetValue(8)
        state.rows.borderSize.slider:SetValue(20)
        expect(ns.Config.GetNumber("borderSize")).to_equal(20)
        local snapshot = ns.Bar._GetPresentationSnapshot()
        expect(snapshot.tickTextures[1].height).to_equal(bar:GetHeight() - 2)
        expect(FindBorder()._backdrop.edgeSize > 0).to_equal(true)
        EditModeManagerFrame:ExitEditMode()
    end)

    it("keeps markers full height and on the same timeline when border decoration changes", function()
        Reset()
        local state = OpenSettings()
        state.rows.height.slider:SetValue(24)

        local function ExpectMarkers(height, positions)
            local markers = ns.Bar._GetPresentationSnapshot().tickTextures
            for index, x in ipairs(positions) do
                expect(markers[index].shown).to_equal(true)
                expect(markers[index].height).to_equal(height)
                expect(markers[index].point[4]).to_be_close_to(x)
            end
            for index = #positions + 1, #markers do
                expect(markers[index].shown).to_equal(false)
            end
            return markers
        end

        local markers = ExpectMarkers(22, { 76, 150, 224 })
        local tickLayer = markers[1].point[2]
        local firstTexture = tickLayer._textures[1]
        local textureCount = #tickLayer._textures
        state.rows.borderSize.slider:SetValue(8)
        ExpectMarkers(22, { 76, 150, 224 })
        state.rows.borderOffset.slider:SetValue(-4)
        ExpectMarkers(22, { 76, 150, 224 })
        _G._SelectDropdown(state.textures.borderTexture.dropdown, "Blizzard Tooltip")
        ExpectMarkers(22, { 76, 150, 224 })
        state.rows.borderOffset.slider:SetValue(20)
        ExpectMarkers(22, { 76, 150, 224 })
        state.rows.width.slider:SetValue(420)
        state.rows.height.slider:SetValue(40)
        ExpectMarkers(38, { 106, 210, 314 })

        _G._FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-marker-1", 192081)
        _G._stubNow = 1.75
        _G._FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-marker-2", 192081)
        _G._stubNow = 3.5
        EditModeManagerFrame:ExitEditMode()
        ExpectMarkers(38, { 210, 314 })
        OpenSettings()
        ExpectMarkers(38, { 106, 210, 314 })
        expect(#tickLayer._textures).to_equal(textureCount)
        expect(tickLayer._textures[1]).to_equal(firstTexture)
        EditModeManagerFrame:ExitEditMode()
    end)

    it("persists tick width controls and styles new and reused markers within the resized bar", function()
        Reset()
        local state = OpenSettings()
        local row = state.rows.tickWidth
        row.slider:SetValue(7)
        expect(row.input:GetText()).to_equal("7")
        expect(IronfurTrackerDB.bar.tickWidth).to_equal(7)
        row.input:SetFocus()
        row.input:SetText("0")
        _G._RunFrameScript(row.input, "OnEnterPressed")
        expect(row.slider._value).to_equal(1)
        row.input:SetFocus()
        row.input:SetText("99")
        _G._RunFrameScript(row.input, "OnEnterPressed")
        expect(row.slider._value).to_equal(20)
        expect(IronfurTrackerDB.bar.tickWidth).to_equal(20)
        row.input:SetFocus()
        row.input:SetText("2.5")
        _G._RunFrameScript(row.input, "OnEnterPressed")
        expect(row.input:GetText()).to_equal("20")

        _G._RunFrameScript(state.colors.tickColor.button, "OnClick")
        _G._SetPickerColor(0.2, 0.4, 0.6, 0.8)
        _G._AcceptPicker()
        state.rows.width.slider:SetValue(80)
        state.rows.height.slider:SetValue(8)
        state.rows.borderSize.slider:SetValue(20)
        state.rows.borderOffset.slider:SetValue(-20)
        _G._SelectDropdown(state.textures.borderTexture.dropdown, "Blizzard Tooltip")

        local function ExpectMarkerGeometry(width, count)
            local markers = ns.Bar._GetPresentationSnapshot().tickTextures
            for index, marker in ipairs(markers) do
                expect(marker.width).to_equal(width)
                expect(marker.height).to_equal(6)
                expect(marker.shown).to_equal(index <= count)
                if marker.shown then
                    expect(marker.point[4] - width / 2 >= 1).to_equal(true)
                    expect(marker.point[4] + width / 2 <= 79).to_equal(true)
                end
            end
            ExpectTickColor(0.2, 0.4, 0.6, 0.8)
            return markers
        end
        local markers = ExpectMarkerGeometry(20, 3)
        expect(markers[1].point[4]).to_be_close_to(25.5)
        expect(markers[3].point[4]).to_be_close_to(54.5)
        local tickLayer = markers[1].point[2]
        local originalTexture = tickLayer._textures[1]
        local applicationCount = #tickLayer._textures + 1
        for index = 1, applicationCount do
            _G._stubNow = index * 0.25
            _G._FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-tick-width-" .. index, 192081)
        end
        EditModeManagerFrame:ExitEditMode()
        expect(#ExpectMarkerGeometry(20, applicationCount)).to_equal(applicationCount)
        state = OpenSettings()
        ExpectMarkerGeometry(20, 3)
        expect(state.rows.tickWidth.input:GetText()).to_equal("20")
        state.rows.tickWidth.slider:SetValue(9)
        EditModeManagerFrame:ExitEditMode()
        ExpectMarkerGeometry(9, applicationCount)
        expect(tickLayer._textures[1]).to_equal(originalTexture)
        expect(IronfurTrackerDB.bar.tickWidth).to_equal(9)
    end)
end)
