local ns = _G._test_ns
local bar = ns.Bar.GetFrame()
local sharedMedia = LibStub("LibSharedMedia-3.0")
local DEFAULT_STACK_COLORS = {
    { 0.90, 0.16, 0.14, 1 }, { 1, 0.80, 0.10, 1 }, { 0.20, 0.80, 0.30, 1 },
    { 0.10, 0.75, 0.95, 1 }, { 0.65, 0.35, 1, 1 },
}

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

local function TextRegion()
    return ns.Bar._GetPresentationSnapshot().textRegion
end

local function ExpectRGBA(actual, expected)
    for index = 1, 4 do expect(actual[index]).to_be_close_to(expected[index]) end
end

local function SelectChoice(state, key, value)
    for _, option in ipairs(ns.Config.GetChoiceOptions(key)) do
        if option.value == value then
            _G._SelectDropdown(state.choices[key].dropdown, option.label)
            return
        end
    end
    error("missing choice " .. key .. ": " .. value)
end

local function SelectStack(index)
    local dropdown = ns.Settings._GetTestState().stackColors.dropdown
    local description = _G._OpenDropdown(dropdown)
    local entryIndex
    for position, threshold in ipairs(ns.Config.GetStackThresholds()) do
        if threshold == index then entryIndex = position end
    end
    if not entryIndex then error("missing stack threshold: " .. index) end
    _G._SelectDropdown(dropdown, description.entries[entryIndex].text)
    return ns.Settings._GetTestState().stackColors
end

local function TypeStackCount(palette, value)
    palette.input:SetFocus()
    palette.input:SetText(value)
end

local function EnterStackCount(palette, value)
    TypeStackCount(palette, value)
    _G._RunFrameScript(palette.input, "OnEnterPressed")
end

local function Click(button)
    _G._RunFrameScript(button, "OnClick", "LeftButton")
end

local function Update(now)
    _G._stubNow = now
    _G._RunFrameScript(ns.Core._GetUpdateDriver(), "OnUpdate", 0)
end

describe("Font and stack-color persistence", function()
    it("preserves old appearance choices while filling newly introduced settings with the new defaults", function()
        local saved = { schemaVersion = 3, bar = {
            width = 420, height = 28, offsetX = 13.5, offsetY = -22,
            barColor = { r = 0.2, g = 0.3, b = 0.4, a = 0.5 },
            tickColor = { r = 0.6, g = 0.7, b = 0.8, a = 0.9 }, tickWidth = 7,
            borderSize = 4, borderOffset = -2, barTexture = "Blizzard", alwaysVisible = false,
        } }
        ns.Config.Initialize(saved)
        expect(saved.schemaVersion).to_equal(11)
        expect(saved.bar.offsetX).to_equal(13.5)
        expect(saved.bar.tickWidth).to_equal(7)
        expect(saved.bar.borderOffset).to_equal(-2)
        expect(saved.bar.barTexture).to_equal("Blizzard")
        expect(saved.bar.alwaysVisible).to_equal(false)
        expect(ns.Config.GetShowStacks()).to_equal(true)
        expect(ns.Config.GetFontFamily()).to_equal("Friz Quadrata TT")
        expect(ns.Config.GetNumber("fontSize")).to_equal(14)
        expect(ns.Config.GetNumber("fontOffset")).to_equal(0)
        expect(ns.Config.GetNumber("fontOffsetY")).to_equal(0)
        expect(ns.Config.GetChoice("fontPosition")).to_equal("CENTER")
        expect(ns.Config.GetChoice("fontStyle")).to_equal("SHADOW")
        expect(ns.Config.GetChoice("barColorMode")).to_equal("CLASS")
        ExpectRGBA({ ns.Config.GetColor("textColor") }, { 1, 1, 1, 1 })
        expect(ns.Config.GetStackColorCount()).to_equal(5)
        for index = 1, 5 do ExpectRGBA({ ns.Config.GetStackColor(index) }, DEFAULT_STACK_COLORS[index]) end
        ns.Config.SetStackColor(1, 1, 0, 0, 1)
        ExpectRGBA({ ns.Config.GetStackColor(2) }, DEFAULT_STACK_COLORS[2])
        ExpectRGBA({ ns.Config.GetColor("barColor") }, { 0.2, 0.3, 0.4, 0.5 })
        Reset()
    end)

    it("migrates explicit font aliases without replacing saved size, tick color, mode, or palette", function()
        local saved = { schemaVersion = 4, bar = {
            fontFamily = "Default", fontStyle = "DEFAULT", fontSize = 16,
            barColorMode = "STACKS", tickColor = { r = 1, g = 0.94, b = 0.72, a = 1 },
            stackColors = { { r = 0.2, g = 0.3, b = 0.4, a = 0.5 },
                { r = 0.6, g = 0.7, b = 0.8, a = 0.9 } },
        } }
        ns.Config.Initialize(saved)
        expect(saved.schemaVersion).to_equal(11)
        expect(ns.Config.GetFontFamily()).to_equal("Friz Quadrata TT")
        expect(ns.Config.GetChoice("fontStyle")).to_equal("SHADOW")
        expect(ns.Config.GetNumber("fontSize")).to_equal(16)
        expect(ns.Config.GetChoice("barColorMode")).to_equal("STACKS")
        ExpectRGBA({ ns.Config.GetColor("tickColor") }, { 1, 0.94, 0.72, 1 })
        expect(ns.Config.GetStackColorCount()).to_equal(2)
        ExpectRGBA({ ns.Config.GetStackColor(1) }, { 0.2, 0.3, 0.4, 0.5 })
        ExpectRGBA({ ns.Config.GetStackColor(2) }, { 0.6, 0.7, 0.8, 0.9 })
        saved.bar.barColorMode = "SOLID"
        ns.Config.Initialize(saved)
        expect(ns.Config.GetChoice("barColorMode")).to_equal("SOLID")
        Reset()
    end)

    it("migrates horizontal placement and normalizes vertical placement without changing the other axis", function()
        local saved = { schemaVersion = 9, bar = {
            fontOffset = -42, fontPosition = "RIGHT", fontSize = 22,
        } }
        ns.Config.Initialize(saved)
        expect(saved.schemaVersion).to_equal(11)
        expect(saved.bar.fontOffset).to_equal(-42)
        expect(saved.bar.fontOffsetY).to_equal(0)
        saved.bar.fontOffsetY = 37
        ns.Config.Initialize(saved)
        expect(ns.Config.GetNumber("fontOffsetY")).to_equal(37)
        for _, invalid in ipairs({ false, "broken", 1.5, math.huge }) do
            saved.bar.fontOffsetY = invalid
            ns.Config.Initialize(saved)
            expect(saved.bar.fontOffsetY).to_equal(0)
            expect(saved.bar.fontOffset).to_equal(-42)
            expect(saved.bar.fontPosition).to_equal("RIGHT")
            expect(saved.bar.fontSize).to_equal(22)
        end
        for _, value in ipairs({ -501, 501 }) do
            saved.bar.fontOffsetY = value
            ns.Config.Initialize(saved)
            expect(saved.bar.fontOffsetY).to_equal(value < 0 and -500 or 500)
            expect(saved.bar.fontOffset).to_equal(-42)
        end
        Reset()
    end)

    it("repairs only corrupt font fields and palette channels while retaining later colors", function()
        local saved = { schemaVersion = 4, bar = {
            showStacks = false, fontFamily = "Unavailable saved font", fontSize = 22,
            fontPosition = "INVALID", fontStyle = "SHADOW", fontOffset = math.huge, fontOffsetY = -21,
            barColorMode = "STACKS", barColor = { r = 0.2, g = 0.3, b = 0.4, a = 0.5 },
            textColor = { r = 0.6, g = "broken", b = 0.8, a = 0.9 },
            stackColors = { [1] = { r = 1, g = "broken", b = 0, a = 1 },
                [3] = { r = 0.4, g = 0.5, b = 0.6, a = 0.7 }, [105] = {} },
        } }
        ns.Config.Initialize(saved)
        expect(ns.Config.GetShowStacks()).to_equal(false)
        expect(ns.Config.GetFontFamily()).to_equal("Unavailable saved font")
        expect(ns.Config.GetNumber("fontSize")).to_equal(22)
        expect(ns.Config.GetNumber("fontOffset")).to_equal(0)
        expect(ns.Config.GetNumber("fontOffsetY")).to_equal(-21)
        expect(ns.Config.GetChoice("fontPosition")).to_equal("CENTER")
        expect(ns.Config.GetChoice("fontStyle")).to_equal("SHADOW")
        expect(ns.Config.GetStackColorCount()).to_equal(3)
        ExpectRGBA({ ns.Config.GetColor("textColor") }, { 0.6, 1, 0.8, 0.9 })
        ExpectRGBA({ ns.Config.GetStackColor(1) }, { 1, 0.3, 0, 1 })
        ExpectRGBA({ ns.Config.GetStackColor(2) }, { 0.2, 0.3, 0.4, 0.5 })
        ExpectRGBA({ ns.Config.GetStackColor(3) }, { 0.4, 0.5, 0.6, 0.7 })
        Reset()
    end)

    it("preserves sparse thresholds and inherits the nearest lower color across gaps", function()
        local saved = { schemaVersion = 5, bar = { barColorMode = "STACKS",
            stackColors = { [1] = { r = 1, g = 0, b = 0, a = 1 },
                [3] = { r = 0, g = 1, b = 0, a = 0.7 },
                [21] = { r = 0, g = 0, b = 1, a = 1 }, [100] = {} },
        } }
        ns.Config.Initialize(saved)
        local thresholds = ns.Config.GetStackThresholds()
        expect(#thresholds).to_equal(2)
        expect(thresholds[1]).to_equal(1)
        expect(thresholds[2]).to_equal(3)
        expect(ns.Config.HasStackColor(2)).to_equal(false)
        expect(ns.Config.GetStackColor(2)).to_be_nil()
        expect(ns.Config.HasStackColor(21)).to_equal(false)
        ExpectRGBA({ ns.Config.GetBarColor(2) }, { 1, 0, 0, 1 })
        ExpectRGBA({ ns.Config.GetBarColor(99) }, { 0, 1, 0, 0.7 })
        expect(ns.Config.AddStackColor(2)).to_be_truthy()
        ExpectRGBA({ ns.Config.GetStackColor(2) }, { 1, 0, 0, 1 })
        ns.Config.SetStackColor(2, 0, 0, 1, 0.8)
        ExpectRGBA({ ns.Config.GetStackColor(1) }, { 1, 0, 0, 1 })
        ExpectRGBA({ ns.Config.GetBarColor(2) }, { 0, 0, 1, 0.8 })
        expect(ns.Config.RemoveStackColor(2)).to_equal(true)
        expect(ns.Config.RemoveStackColor(2)).to_equal(false)
        ExpectRGBA({ ns.Config.GetBarColor(2) }, { 1, 0, 0, 1 })
        ns.Config.Initialize(saved)
        expect(ns.Config.GetStackColorCount()).to_equal(2)
        expect(ns.Config.HasStackColor(2)).to_equal(false)
        expect(ns.Config.RemoveStackColor(1)).to_equal(true)
        saved.schemaVersion = 5
        ns.Config.Initialize(saved)
        expect(ns.Config.HasStackColor(1)).to_equal(false)
        expect(ns.Config.GetStackColorCount()).to_equal(1)
        ExpectRGBA({ ns.Config.GetBarColor(2) }, { ns.Config.GetColor("barColor") })
        for _, mode in ipairs({ "CLASS", "SOLID", "STACKS" }) do
            ns.Config.SetChoice("barColorMode", mode)
            expect(ns.Config.AddStackColor(1)).to_be_truthy()
            ExpectRGBA({ ns.Config.GetStackColor(1) }, { ns.Config.GetColor("barColor") })
            ns.Config.RemoveStackColor(1)
        end
        Reset()
    end)
end)

describe("Stack text presentation", function()
    it("offers explicit font choices and uses the configured fixed defaults", function()
        Reset()
        local state = OpenSettings()
        expect(state.fontFamily.dropdown:GetText()).to_equal("Friz Quadrata TT")
        expect(state.choices.fontStyle.dropdown:GetText()).to_equal("Drop shadow")
        expect(select(2, TextRegion():GetFont())).to_equal(14)
        local fontMenu = _G._OpenDropdown(state.fontFamily.dropdown)
        local foundFriz = false
        for _, entry in ipairs(fontMenu.entries) do
            expect(entry.text == "Default").to_equal(false)
            if entry.text == "Friz Quadrata TT" then foundFriz = true end
        end
        expect(foundFriz).to_equal(true)
        local styleMenu = _G._OpenDropdown(state.choices.fontStyle.dropdown)
        for _, entry in ipairs(styleMenu.entries) do expect(entry.text == "Default").to_equal(false) end
        EditModeManagerFrame:ExitEditMode()
    end)

    it("applies anchors, independent signed offsets, size, font effects, and text visibility through controls", function()
        Reset()
        local state = OpenSettings()
        local text = TextRegion()
        expect(state.rows.fontOffset.label:GetText()).to_equal("Horizontal")
        expect(state.rows.fontOffsetY.label:GetText()).to_equal("Vertical")
        for _, position in ipairs({ "LEFT", "CENTER", "RIGHT" }) do
            SelectChoice(state, "fontPosition", position)
            state.rows.fontOffset.input:SetFocus()
            state.rows.fontOffset.input:SetText("-12")
            _G._RunFrameScript(state.rows.fontOffset.input, "OnEnterPressed")
            state.rows.fontOffsetY.input:SetFocus()
            state.rows.fontOffsetY.input:SetText("-9")
            _G._RunFrameScript(state.rows.fontOffsetY.input, "OnEnterPressed")
            local point, _, relativePoint, x, y = text:GetPoint()
            expect(point).to_equal(position)
            expect(relativePoint).to_equal(position)
            expect(x).to_equal(-12)
            expect(y).to_equal(-9)
            expect(text._justifyH).to_equal(position)
        end
        state.rows.fontOffset.slider:SetValue(15)
        expect(select(4, text:GetPoint())).to_equal(15)
        expect(select(5, text:GetPoint())).to_equal(-9)
        state.rows.fontOffsetY.slider:SetValue(20)
        expect(state.rows.fontOffsetY.input:GetText()).to_equal("20")
        expect(IronfurTrackerDB.bar.fontOffsetY).to_equal(20)
        expect(IronfurTrackerDB.bar.fontOffset).to_equal(15)
        state.rows.fontSize.slider:SetValue(24)
        state.rows.width.slider:SetValue(500)
        expect(select(4, text:GetPoint())).to_equal(15)
        expect(select(5, text:GetPoint())).to_equal(20)
        expect(select(2, text:GetFont())).to_equal(24)
        local styles = {
            { "NONE", "", 0 }, { "OUTLINE", "OUTLINE", 0 }, { "SHADOWOUTLINE", "OUTLINE", 0.6 },
            { "THICKOUTLINE", "THICKOUTLINE", 0 }, { "SHADOWTHICKOUTLINE", "THICKOUTLINE", 0.6 },
            { "SHADOW", "", 1 },
        }
        for _, style in ipairs(styles) do
            SelectChoice(state, "fontStyle", style[1])
            expect(select(3, text:GetFont())).to_equal(style[2])
            expect(select(4, text:GetShadowColor())).to_equal(style[3])
        end
        state.showStacks:SetChecked(false)
        Click(state.showStacks)
        expect(text:IsShown()).to_equal(false)
        expect(bar:IsShown()).to_equal(true)
        expect(ns.Tracker._GetSnapshot().count).to_equal(0)
        state.showStacks:SetChecked(true)
        Click(state.showStacks)
        expect(text:IsShown()).to_equal(true)
        expect(text:GetText()).to_equal("3")
        EditModeManagerFrame:ExitEditMode()
    end)

    it("recovers missing and rejected fonts without changing the saved family", function()
        Reset()
        local nativePath = GameFontHighlightLarge:GetFont()
        local name, path = "Test late font", "Interface\\AddOns\\TestMedia\\late.ttf"
        ns.Config.SetFontFamily(name)
        ns.Config.CommitNumber("fontSize", 22)
        ns.Config.SetChoice("fontStyle", "THICKOUTLINE")
        ns.Bar.ApplyAppearance()
        local state = OpenSettings()
        local text = TextRegion()
        expect(text:GetFont()).to_equal(nativePath)
        expect(state.fontFamily.dropdown:GetText()).to_equal(name)
        _G._stubKnownFileAssets[path] = true
        _G._stubFontSetResults[path] = true
        expect(sharedMedia:Register("font", name, path)).to_equal(true)
        expect(text:GetFont()).to_equal(path)
        _G._SelectDropdown(state.fontFamily.dropdown, name)
        expect(ns.Config.GetFontFamily()).to_equal(name)
        local preview
        for _, row in ipairs(state.fontFamily.dropdown._menuRows) do
            if row.fontString:GetText() == name then preview = row.fontString end
        end
        expect(preview:GetFont()).to_equal(path)
        expect(select(2, preview:GetFont())).to_equal(14)
        local previewObject = preview._fontObject
        _G._OpenDropdown(state.fontFamily.dropdown)
        expect(preview._fontObject).to_equal(previewObject)
        _G._stubFontSetResults[path] = false
        ns.Bar.ApplyAppearance()
        expect(text:GetFont()).to_equal(nativePath)
        expect(select(2, text:GetFont())).to_equal(22)
        expect(select(3, text:GetFont())).to_equal("THICKOUTLINE")
        expect(ns.Config.GetFontFamily()).to_equal(name)
        _G._stubFontSetResults[path] = true
        ns.Bar.ApplyAppearance()
        expect(text:GetFont()).to_equal(path)
        local rejectedName, rejectedPath = "Test rejected font", "Interface\\AddOns\\TestMedia\\rejected.ttf"
        _G._stubKnownFileAssets[rejectedPath], _G._stubFontSetResults[rejectedPath] = true, false
        sharedMedia:Register("font", rejectedName, rejectedPath)
        _G._SelectDropdown(state.fontFamily.dropdown, rejectedName)
        expect(ns.Config.GetFontFamily()).to_equal(rejectedName)
        expect(text:GetFont()).to_equal(nativePath)
        for _, row in ipairs(state.fontFamily.dropdown._menuRows) do
            if row.fontString:GetText() == rejectedName then expect(row.fontString:GetFont()).to_equal(nativePath) end
        end
        EditModeManagerFrame:ExitEditMode()
    end)

    it("cancels and accepts text color, then resets typography and visibility together", function()
        Reset()
        local state = OpenSettings()
        local text = TextRegion()
        Click(state.colors.textColor.button)
        _G._SetPickerColor(0.2, 0.3, 0.4, 0.5)
        ExpectRGBA(text._color, { 0.2, 0.3, 0.4, 0.5 })
        _G._CancelPicker()
        ExpectRGBA(text._color, { 1, 1, 1, 1 })
        Click(state.colors.textColor.button)
        _G._SetPickerColor(0.2, 0.3, 0.4, 0.5)
        _G._AcceptPicker()
        ExpectRGBA({ ns.Config.GetColor("textColor") }, { 0.2, 0.3, 0.4, 0.5 })
        _G._SelectDropdown(state.fontFamily.dropdown, "Arial Narrow")
        SelectChoice(state, "fontStyle", "SHADOWOUTLINE")
        SelectChoice(state, "fontPosition", "RIGHT")
        state.rows.fontSize.slider:SetValue(30)
        state.rows.fontOffset.slider:SetValue(-40)
        state.rows.fontOffsetY.slider:SetValue(30)
        state.showStacks:SetChecked(false)
        Click(state.showStacks)
        Click(state.resetButton)
        expect(ns.Config.GetFontFamily()).to_equal("Friz Quadrata TT")
        expect(ns.Config.GetChoice("fontStyle")).to_equal("SHADOW")
        expect(ns.Config.GetChoice("fontPosition")).to_equal("CENTER")
        expect(ns.Config.GetNumber("fontOffset")).to_equal(0)
        expect(ns.Config.GetNumber("fontOffsetY")).to_equal(0)
        expect(state.rows.fontOffset.input:GetText()).to_equal("0")
        expect(state.rows.fontOffsetY.input:GetText()).to_equal("0")
        expect(select(4, text:GetPoint())).to_equal(0)
        expect(select(5, text:GetPoint())).to_equal(0)
        expect(select(2, text:GetFont())).to_equal(14)
        expect(text:IsShown()).to_equal(true)
        ExpectRGBA(text._color, { 1, 1, 1, 1 })
        EditModeManagerFrame:ExitEditMode()
    end)
end)

describe("Bar color by stack count", function()
    it("uses the public Druid class color and recovers missing data without overwriting a custom solid color", function()
        Reset()
        local state = OpenSettings()
        expect(ns.Config.GetChoice("barColorMode")).to_equal("CLASS")
        ExpectRGBA({ ns.Config.GetColor("tickColor") }, { 1, 1, 1, 1 })
        ns.Config.SetColor("barColor", 0.2, 0.3, 0.4, 0.5)
        local previousOverrides = _G.CUSTOM_CLASS_COLORS
        _G.CUSTOM_CLASS_COLORS = { DRUID = { r = 0, g = 1, b = 0, a = 0.2 } }
        ns.Bar.ApplyAppearance()
        local displayed = bar._statusBarColor
        _G.CUSTOM_CLASS_COLORS = previousOverrides
        ExpectRGBA(displayed, { 1, 0.49, 0.04, 1 })
        _G._stubClassColorAvailable = false
        ns.Bar.ApplyAppearance()
        ExpectRGBA(bar._statusBarColor, { 0.2, 0.3, 0.4, 0.5 })
        _G._stubClassColorAvailable = true
        ns.Bar.ApplyAppearance()
        ExpectRGBA(bar._statusBarColor, { 1, 0.49, 0.04, 1 })
        SelectChoice(state, "barColorMode", "SOLID")
        ExpectRGBA(bar._statusBarColor, { 0.2, 0.3, 0.4, 0.5 })
        ExpectRGBA({ ns.Config.GetColor("barColor") }, { 0.2, 0.3, 0.4, 0.5 })
        EditModeManagerFrame:ExitEditMode()
    end)

    it("follows casts and expiry while hidden text leaves count-based tinting intact", function()
        Reset()
        ns.Config.SetColor("barColor", 0.2, 0.3, 0.4, 0.5)
        ns.Config.SetStackColor(1, 1, 0, 0, 1)
        ns.Config.SetStackColor(2, 0, 1, 0, 1)
        ns.Config.SetStackColor(5, 0, 0, 1, 1)
        ns.Config.SetChoice("barColorMode", "STACKS")
        ns.Config.SetShowStacks(false)
        ns.Bar.ApplyAppearance()
        _G._FireEvent("PLAYER_ENTERING_WORLD")
        ExpectRGBA(bar._statusBarColor, { 0.2, 0.3, 0.4, 0.5 })
        expect(bar._value).to_equal(0)
        for index = 1, 6 do
            _G._stubNow = index - 1
            _G._FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-color-" .. index, 192081)
            if index == 1 then ExpectRGBA(bar._statusBarColor, { 1, 0, 0, 1 }) end
            if index == 2 then ExpectRGBA(bar._statusBarColor, { 0, 1, 0, 1 }) end
        end
        expect(ns.Tracker._GetSnapshot().count).to_equal(6)
        expect(TextRegion():IsShown()).to_equal(false)
        ExpectRGBA(bar._statusBarColor, { 0, 0, 1, 1 })
        Update(10.1)
        ExpectRGBA(bar._statusBarColor, { 0, 1, 0, 1 })
        Update(11.1)
        ExpectRGBA(bar._statusBarColor, { 1, 0, 0, 1 })
        Update(12.1)
        ExpectRGBA(bar._statusBarColor, { 0.2, 0.3, 0.4, 0.5 })
        expect(bar._value).to_equal(0)
        expect(ns.Core._GetUpdateDriver():IsShown()).to_equal(false)
    end)

    it("previews the selected stack color and cancels indexed edits before palette or mode changes", function()
        Reset()
        local state = OpenSettings()
        SelectChoice(state, "barColorMode", "STACKS")
        local palette = SelectStack(3)
        expect(ns.Settings.GetPreviewStackCount()).to_equal(3)
        Click(palette.button)
        _G._SetPickerColor(0.1, 0.2, 0.3, 0.4)
        ExpectRGBA(bar._statusBarColor, { 0.1, 0.2, 0.3, 0.4 })
        local stale = ColorPickerFrame.swatchFunc
        palette = SelectStack(2)
        stale()
        expect(ColorPickerFrame:IsShown()).to_equal(false)
        ExpectRGBA({ ns.Config.GetStackColor(3) }, DEFAULT_STACK_COLORS[3])
        expect(TextRegion():GetText()).to_equal("2")
        expect(ns.Tracker._GetSnapshot().count).to_equal(0)
        Click(palette.button)
        _G._SetPickerColor(0.3, 0.4, 0.5, 0.6)
        stale = ColorPickerFrame.swatchFunc
        SelectChoice(state, "barColorMode", "SOLID")
        stale()
        expect(ns.Settings.GetPreviewStackCount()).to_be_nil()
        expect(ColorPickerFrame:IsShown()).to_equal(false)
        ExpectRGBA({ ns.Config.GetStackColor(2) }, DEFAULT_STACK_COLORS[2])
        SelectChoice(state, "barColorMode", "STACKS")
        palette = SelectStack(3)
        Click(palette.button)
        _G._SetPickerColor(0.6, 0.5, 0.4, 0.3)
        stale = ColorPickerFrame.swatchFunc
        Click(palette.removeButton)
        stale()
        expect(ns.Config.GetStackColorCount()).to_equal(4)
        expect(ns.Config.GetStackColor(3)).to_be_nil()
        expect(ns.Config.HasStackColor(5)).to_equal(true)
        expect(ns.Settings.GetPreviewStackCount()).to_equal(2)
        palette = ns.Settings._GetTestState().stackColors
        EnterStackCount(palette, "3")
        expect(ns.Config.GetStackColorCount()).to_equal(5)
        ExpectRGBA({ ns.Config.GetStackColor(3) }, { ns.Config.GetStackColor(2) })
        palette = SelectStack(3)
        Click(palette.button)
        _G._SetPickerColor(0.1, 0.2, 0.3, 0.4)
        stale = ColorPickerFrame.swatchFunc
        Click(state.resetButton)
        stale()
        expect(ns.Config.GetChoice("barColorMode")).to_equal("CLASS")
        expect(ns.Config.GetStackColorCount()).to_equal(5)
        ExpectRGBA({ ns.Config.GetStackColor(3) }, DEFAULT_STACK_COLORS[3])
        EditModeManagerFrame:ExitEditMode()
    end)

    it("uses the input count for add and remove and keeps it synchronized with the dropdown", function()
        Reset()
        ns.Config.AddStackColor(6)
        local state = OpenSettings()
        SelectChoice(state, "barColorMode", "STACKS")
        local palette = SelectStack(3)
        expect(palette.input:GetText()).to_equal("3")
        TypeStackCount(palette, "6")
        expect(ns.Settings.GetPreviewStackCount()).to_equal(6)
        expect(palette.addButton._enabled).to_equal(false)
        expect(palette.removeButton._enabled).to_equal(true)
        expect(palette.removeButton:GetText()).to_equal("Remove 6")
        Click(palette.removeButton)
        expect(ns.Config.HasStackColor(6)).to_equal(false)
        expect(ns.Config.HasStackColor(3)).to_equal(true)
        expect(palette.input:GetText()).to_equal("5")
        expect(ns.Settings.GetPreviewStackCount()).to_equal(5)
        expect(palette.button._enabled).to_equal(true)
        expect(palette.removeButton._enabled).to_equal(true)
        expect(palette.addButton._enabled).to_equal(false)
        ExpectRGBA(bar._statusBarColor, DEFAULT_STACK_COLORS[5])
        TypeStackCount(palette, "6")
        expect(palette.button._enabled).to_equal(false)
        expect(palette.removeButton._enabled).to_equal(false)
        expect(palette.addButton._enabled).to_equal(true)
        Click(palette.addButton)
        expect(ns.Config.HasStackColor(6)).to_equal(true)
        expect(palette.input:GetText()).to_equal("6")
        expect(ns.Settings.GetPreviewStackCount()).to_equal(6)
        expect(palette.button._enabled).to_equal(true)
        expect(palette.addButton._enabled).to_equal(false)
        expect(palette.removeButton._enabled).to_equal(true)
        ExpectRGBA({ ns.Config.GetStackColor(6) }, DEFAULT_STACK_COLORS[5])
        palette = SelectStack(2)
        expect(palette.input:GetText()).to_equal("2")
        expect(ns.Settings.GetPreviewStackCount()).to_equal(2)
        ExpectRGBA(bar._statusBarColor, DEFAULT_STACK_COLORS[2])
        EditModeManagerFrame:ExitEditMode()
    end)

    it("selects the remaining color that inherits a removed range and edits that exact rule", function()
        Reset()
        local state = OpenSettings()
        SelectChoice(state, "barColorMode", "STACKS")
        local palette = SelectStack(2)
        Click(palette.removeButton)
        expect(palette.input:GetText()).to_equal("1")
        expect(ns.Settings.GetPreviewStackCount()).to_equal(1)
        expect(palette.dropdown:GetText()).to_equal("1-2 stacks")
        local selected = 0
        for _, entry in ipairs(_G._OpenDropdown(palette.dropdown).entries) do
            if entry.isSelected(entry.data) then
                selected = selected + 1
                expect(entry.text).to_equal("1-2 stacks")
            end
        end
        expect(selected).to_equal(1)
        expect(ns.Config.HasStackColor(2)).to_equal(false)
        Click(palette.button)
        _G._SetPickerColor(0.11, 0.22, 0.33, 0.44)
        _G._AcceptPicker()
        ExpectRGBA({ ns.Config.GetStackColor(1) }, { 0.11, 0.22, 0.33, 0.44 })
        ExpectRGBA({ ns.Config.GetBarColor(2) }, { 0.11, 0.22, 0.33, 0.44 })
        ExpectRGBA(palette.swatch._color, { 0.11, 0.22, 0.33, 0.44 })
        expect(ns.Config.HasStackColor(2)).to_equal(false)
        for count = 3, 5 do
            ExpectRGBA({ ns.Config.GetStackColor(count) }, DEFAULT_STACK_COLORS[count])
        end

        Click(palette.removeButton)
        expect(ns.Config.HasStackColor(1)).to_equal(false)
        expect(palette.input:GetText()).to_equal("3")
        expect(ns.Settings.GetPreviewStackCount()).to_equal(3)
        expect(palette.dropdown:GetText()).to_equal("3 stacks")
        ExpectRGBA(palette.swatch._color, DEFAULT_STACK_COLORS[3])
        EditModeManagerFrame:ExitEditMode()
    end)

    it("cancels an indexed picker on input changes and rejects drafts outside one through twenty", function()
        Reset()
        local state = OpenSettings()
        SelectChoice(state, "barColorMode", "STACKS")
        local palette = SelectStack(3)
        Click(palette.button)
        _G._SetPickerColor(0.4, 0.5, 0.6, 0.7)
        local stale = ColorPickerFrame.swatchFunc
        TypeStackCount(palette, "6")
        stale()
        expect(ColorPickerFrame:IsShown()).to_equal(false)
        ExpectRGBA({ ns.Config.GetStackColor(3) }, DEFAULT_STACK_COLORS[3])
        expect(ns.Settings.GetPreviewStackCount()).to_equal(6)
        expect(ns.Config.HasStackColor(6)).to_equal(false)
        expect(palette.button._enabled).to_equal(false)
        ExpectRGBA(bar._statusBarColor, DEFAULT_STACK_COLORS[5])
        for _, value in ipairs({ "", "0", "21" }) do
            TypeStackCount(palette, value)
            expect(palette.addButton._enabled).to_equal(false)
            expect(palette.removeButton._enabled).to_equal(false)
            expect(palette.button._enabled).to_equal(false)
            Click(palette.addButton)
            Click(palette.removeButton)
            _G._RunFrameScript(palette.input, "OnEnterPressed")
            expect(ns.Config.GetStackColorCount()).to_equal(5)
            expect(ns.Settings.GetPreviewStackCount()).to_equal(6)
            expect(palette.input:GetText()).to_equal(value)
        end
        EnterStackCount(palette, "20")
        expect(ns.Config.HasStackColor(20)).to_equal(true)
        expect(palette.input:GetText()).to_equal("20")
        expect(ns.Settings.GetPreviewStackCount()).to_equal(20)
        expect(ns.Config.HasStackColor(21)).to_equal(false)
        EditModeManagerFrame:ExitEditMode()
    end)

    it("keeps preview counts separate from live applications and cancels an indexed edit on combat entry", function()
        Reset()
        for index = 1, 2 do
            _G._FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-preview-color-" .. index, 192081)
        end
        local state = OpenSettings()
        SelectChoice(state, "barColorMode", "STACKS")
        local palette = SelectStack(5)
        Click(palette.button)
        _G._SetPickerColor(0.2, 0.3, 0.4, 0.5)
        _G._AcceptPicker()
        ExpectRGBA({ ns.Config.GetStackColor(5) }, { 0.2, 0.3, 0.4, 0.5 })
        expect(TextRegion():GetText()).to_equal("5")
        local visibleTicks = 0
        for _, tick in ipairs(ns.Bar._GetPresentationSnapshot().tickTextures) do
            if tick.shown then visibleTicks = visibleTicks + 1 end
        end
        expect(visibleTicks).to_equal(5)
        expect(ns.Tracker._GetSnapshot().count).to_equal(2)
        ns.Settings.Hide()
        expect(TextRegion():GetText()).to_equal("3")
        expect(ns.Settings.GetPreviewStackCount()).to_be_nil()
        _G._RunFrameScript(ns.EditMode._GetTestState().selection, "OnMouseDown")
        expect(TextRegion():GetText()).to_equal("5")
        Click(palette.button)
        _G._SetPickerColor(0.8, 0.7, 0.6, 0.5)
        local stale = ColorPickerFrame.swatchFunc
        _G._stubInCombat = true
        _G._FireEvent("PLAYER_REGEN_DISABLED")
        stale()
        expect(state.panel:IsShown()).to_equal(false)
        expect(ColorPickerFrame:IsShown()).to_equal(false)
        ExpectRGBA({ ns.Config.GetStackColor(5) }, { 0.2, 0.3, 0.4, 0.5 })
        expect(ns.Tracker._GetSnapshot().count).to_equal(2)
        expect(TextRegion():GetText()).to_equal("2")
        _G._stubInCombat = false
        _G._FireEvent("PLAYER_REGEN_ENABLED")
        EditModeManagerFrame:ExitEditMode()
        expect(TextRegion():GetText()).to_equal("2")
    end)

    it("keeps a bounded editable palette and uses its highest color above the final count", function()
        Reset()
        for count = 6, ns.Config.GetMaximumStackColors() do
            expect(ns.Config.AddStackColor(count)).to_be_truthy()
        end
        expect(ns.Config.GetStackColorCount()).to_equal(20)
        for _, count in ipairs({ 0, 1, 2.5, 21 }) do expect(ns.Config.AddStackColor(count)).to_equal(false) end
        ns.Config.SetStackColor(20, 0.1, 0.2, 0.3, 0.4)
        ns.Config.SetChoice("barColorMode", "STACKS")
        ExpectRGBA({ ns.Config.GetBarColor(100) }, { 0.1, 0.2, 0.3, 0.4 })
        for count = 20, 2, -1 do expect(ns.Config.RemoveStackColor(count)).to_equal(true) end
        local state = OpenSettings()
        local palette = SelectStack(1)
        expect(palette.removeButton._enabled).to_equal(true)
        Click(palette.removeButton)
        expect(ns.Config.GetStackColorCount()).to_equal(0)
        expect(palette.input:GetText()).to_equal("1")
        expect(palette.dropdown:GetText()).to_equal("No stack colors")
        expect(palette.removeButton._enabled).to_equal(false)
        expect(palette.addButton._enabled).to_equal(true)
        ExpectRGBA(bar._statusBarColor, { ns.Config.GetColor("barColor") })
        IronfurTrackerDB.schemaVersion = 5
        ns.Config.Initialize(IronfurTrackerDB)
        expect(IronfurTrackerDB.schemaVersion).to_equal(11)
        expect(ns.Config.GetStackColorCount()).to_equal(0)
        Click(palette.addButton)
        expect(ns.Config.HasStackColor(1)).to_equal(true)
        ExpectRGBA({ ns.Config.GetStackColor(1) }, { ns.Config.GetColor("barColor") })
        EditModeManagerFrame:ExitEditMode()
    end)
end)
