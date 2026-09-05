local ns = _G._test_ns
local bar = ns.Bar.GetFrame()
local HIGH = { 0.20, 0.80, 0.30, 1 }
local MEDIUM = { 1, 0.80, 0.10, 1 }
local LOW = { 0.90, 0.16, 0.14, 1 }
local COLOR_KEYS = { "durationHighColor", "durationMediumColor", "durationLowColor" }

local function Reset()
  _G._ResetWowStubs()
  EventRegistry:TriggerEvent("EditMode.Exit")
  _G._FireEvent("PLAYER_REGEN_ENABLED")
  ns.Config.ResetBar()
  ns.Bar.ApplyGeometry()
  _G._FireEvent("PLAYER_ENTERING_WORLD")
end

local function ExpectColor(actual, expected)
  for channel = 1, 4 do
    expect(actual[channel]).to_be_close_to(expected[channel])
  end
end

local function OpenSettings()
  EditModeManagerFrame:EnterEditMode()
  _G._RunFrameScript(ns.EditMode._GetTestState().selection, "OnMouseDown")
  return ns.Settings._GetTestState()
end

local function Click(button)
  _G._RunFrameScript(button, "OnClick", "LeftButton")
end

local function Cast(spellID, now)
  _G._stubNow = now
  _G._FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-duration-color", spellID)
end

local function Update(now)
  _G._stubNow = now
  _G._RunFrameScript(ns.Core._GetUpdateDriver(), "OnUpdate", 0)
end

describe("Color by remaining duration", function()
  it("adds duration colors without replacing saved appearance and repairs individual invalid channels", function()
    local saved = {
      schemaVersion = 10,
      bar = {
        fontOffset = -14,
        fontOffsetY = 8,
        barTexture = "Blizzard",
        barColor = { r = 0.1, g = 0.2, b = 0.3, a = 0.4 },
        stackColors = {},
      },
    }
    ns.Config.Initialize(saved)
    expect(saved.schemaVersion).to_equal(11)
    expect(ns.Config.GetChoice("barColorMode")).to_equal("CLASS")
    for index, color in ipairs({ HIGH, MEDIUM, LOW }) do
      ExpectColor({ ns.Config.GetColor(COLOR_KEYS[index]) }, color)
      ns.Config.SetColor(COLOR_KEYS[index], index / 10, 0.4, 0.5, 0.6)
    end
    ns.Config.SetChoice("barColorMode", "DURATION")
    ns.Config.Initialize(saved)
    expect(ns.Config.GetChoice("barColorMode")).to_equal("DURATION")
    for index, key in ipairs(COLOR_KEYS) do
      ExpectColor({ ns.Config.GetColor(key) }, { index / 10, 0.4, 0.5, 0.6 })
    end
    saved.bar.durationHighColor.g = math.huge
    saved.bar.durationMediumColor.a = "invalid"
    saved.bar.durationLowColor.b = -1
    ns.Config.Initialize(saved)
    ExpectColor({ ns.Config.GetColor("durationHighColor") }, { 0.1, 0.8, 0.5, 0.6 })
    ExpectColor({ ns.Config.GetColor("durationMediumColor") }, { 0.2, 0.4, 0.5, 1 })
    ExpectColor({ ns.Config.GetColor("durationLowColor") }, { 0.3, 0.4, 0.14, 0.6 })
    expect(saved.bar.fontOffset).to_equal(-14)
    expect(saved.bar.fontOffsetY).to_equal(8)
    expect(saved.bar.barTexture).to_equal("Blizzard")
    expect(ns.Config.GetStackColorCount()).to_equal(0)
    ExpectColor({ ns.Config.GetColor("barColor") }, { 0.1, 0.2, 0.3, 0.4 })
    Reset()
  end)

  it("uses exact duration boundaries independently of count and rejects invalid progress", function()
    Reset()
    ns.Config.SetChoice("barColorMode", "DURATION")
    for _, sample in ipairs({
      { 0.5001, HIGH },
      { 0.5, MEDIUM },
      { 0.2501, MEDIUM },
      { 0.25, LOW },
      { 0.2499, LOW },
      { 0.2, LOW },
      { 0.01, LOW },
      { 0, LOW },
    }) do
      for _, count in ipairs({ 0, 1, 20 }) do
        ExpectColor({ ns.Config.GetBarColor(count, sample[1]) }, sample[2])
      end
    end
    local solid = { ns.Config.GetColor("barColor") }
    for _, value in ipairs({ -0.1, 1.1, false, "0.7", math.huge, _G._stubSecretValue }) do
      ExpectColor({ ns.Config.GetBarColor(1, value) }, solid)
    end
    ExpectColor({ ns.Config.GetBarColor(1) }, solid)
  end)

  it("retints as time passes and reuses the visible fill for appearance and mode changes", function()
    Reset()
    ns.Config.SetChoice("barColorMode", "DURATION")
    ns.Bar.ApplyAppearance()
    local backdrop = ns.Bar._GetPresentationSnapshot().backdropRegion
    local backdropColor = { ns.Config.GetColor("backdropColor") }
    Cast(192081, 0)
    ExpectColor(bar._statusBarColor, HIGH)
    Update(3.5)
    expect(ns.Tracker._GetSnapshot().count).to_equal(1)
    expect(bar._value).to_be_close_to(0.5)
    ExpectColor(bar._statusBarColor, MEDIUM)
    ns.Config.SetColor("durationMediumColor", 0.1, 0.2, 0.3, 0.4)
    ns.Bar.ApplyAppearance()
    ExpectColor(bar._statusBarColor, { 0.1, 0.2, 0.3, 0.4 })
    expect(bar._value).to_be_close_to(0.5)
    ns.Config.SetChoice("barColorMode", "SOLID")
    ns.Bar.ApplyAppearance()
    ExpectColor(bar._statusBarColor, { ns.Config.GetColor("barColor") })
    ns.Config.SetChoice("barColorMode", "DURATION")
    ns.Bar.ApplyAppearance()
    ExpectColor(bar._statusBarColor, { 0.1, 0.2, 0.3, 0.4 })
    Update(5.25)
    expect(ns.Tracker._GetSnapshot().count).to_equal(1)
    expect(bar._value).to_equal(0.25)
    ExpectColor(bar._statusBarColor, LOW)
    Cast(192081, 6)
    expect(bar._value).to_equal(1)
    expect(ns.Tracker._GetSnapshot().count).to_equal(2)
    ExpectColor(bar._statusBarColor, HIGH)
    Update(7.1)
    expect(ns.Tracker._GetSnapshot().count).to_equal(1)
    ExpectColor(bar._statusBarColor, HIGH)
    Update(13.1)
    expect(bar._value).to_equal(0)
    expect(bar:IsShown()).to_equal(true)
    expect(ns.Tracker._GetSnapshot().count).to_equal(0)
    expect(ns.Core._GetUpdateDriver():IsShown()).to_equal(false)
    ExpectColor(backdrop._vertexColor, backdropColor)
  end)

  it("colors mixed-duration applications from the same maximum progress used by the fill", function()
    Reset()
    ns.Config.SetChoice("barColorMode", "DURATION")
    _G._stubKnownSpells[393611] = true
    _G._stubKnownSpells[155578] = true
    Cast(33917, 0)
    Cast(192081, 0)
    _G._stubKnownSpells[393611] = nil
    Cast(192081, 4)
    local ticks = ns.Tracker._GetSnapshot().ticks
    expect(ticks[1].duration).to_equal(12)
    expect(ticks[2].duration).to_equal(7)
    Update(7.2)
    expect(ns.Tracker._GetSnapshot().count).to_equal(2)
    expect(bar._value).to_be_close_to(3.8 / 7)
    ExpectColor(bar._statusBarColor, HIGH)
    Update(8)
    expect(ns.Tracker._GetSnapshot().count).to_equal(2)
    expect(bar._value).to_be_close_to(3 / 7)
    ExpectColor(bar._statusBarColor, MEDIUM)
    Update(10)
    expect(ns.Tracker._GetSnapshot().count).to_equal(2)
    expect(bar._value).to_be_close_to(2 / 12)
    ExpectColor(bar._statusBarColor, LOW)
  end)

  it("shows duration swatches only in their mode while preserving the scrollbar layout", function()
    Reset()
    local state = OpenSettings()
    UIParent:SetHeight(400)
    _G._FireEvent("DISPLAY_SIZE_CHANGED")
    local width = state.panel:GetWidth()
    for _, mode in ipairs({ "By time remaining", "Class color", "Solid", "By stack count", "By time remaining" }) do
      _G._SelectDropdown(state.choices.barColorMode.dropdown, mode)
      for _, key in ipairs(COLOR_KEYS) do
        expect(state.colors[key]:IsShown()).to_equal(mode == "By time remaining")
      end
      expect(state.panel:GetWidth()).to_equal(width)
      expect(state.scrollFrame:GetVerticalScrollRange() > 0).to_equal(true)
      expect(state.scrollFrame._scrollBar:IsShown()).to_equal(true)
    end
    expect(bar._value).to_equal(0.75)
    ExpectColor(bar._statusBarColor, HIGH)
    expect(ns.Tracker._GetSnapshot().count).to_equal(0)
    local descriptions = {
      { "Over half left", "More than 50% of the duration remains" },
      { "Quarter to half left", "More than 25% and up to 50% of the duration remains" },
      { "Quarter or less left", "25% or less of the duration remains" },
    }
    for index, key in ipairs(COLOR_KEYS) do
      local row = state.colors[key]
      expect(row.label:GetText()).to_equal(descriptions[index][1])
      _G._RunFrameScript(row.button, "OnEnter")
      expect(GameTooltip:IsShown()).to_equal(true)
      expect(GameTooltip:GetOwner()).to_equal(row.button)
      expect(GameTooltip._text).to_equal(descriptions[index][2])
      _G._RunFrameScript(row.button, "OnLeave")
      ns.Settings.Refresh()
      expect(GameTooltip:IsShown()).to_equal(false)
    end
    local button = state.colors.durationHighColor.button
    for _ = 1, 2 do
      _G._RunFrameScript(button, "OnEnter")
      _G._SelectDropdown(state.choices.barColorMode.dropdown, "Class color")
      expect(GameTooltip:IsShown()).to_equal(false)
      _G._SelectDropdown(state.choices.barColorMode.dropdown, "By time remaining")
    end
    _G._RunFrameScript(button, "OnEnter")
    GameTooltip:SetOwner(state.eyeButton, "ANCHOR_RIGHT")
    GameTooltip:SetText("Another tooltip")
    _G._RunFrameScript(button, "OnLeave")
    _G._SelectDropdown(state.choices.barColorMode.dropdown, "Class color")
    expect(GameTooltip:IsShown()).to_equal(true)
    expect(GameTooltip:GetOwner()).to_equal(state.eyeButton)
    expect(GameTooltip._text).to_equal("Another tooltip")
    EditModeManagerFrame:ExitEditMode()
  end)

  it("rolls back duration picker changes on cancel, mode change, combat, and reset", function()
    Reset()
    local state = OpenSettings()
    _G._SelectDropdown(state.choices.barColorMode.dropdown, "By time remaining")
    _G._RunFrameScript(state.colors.durationHighColor.button, "OnEnter")
    Click(state.colors.durationHighColor.button)
    expect(GameTooltip:IsShown()).to_equal(false)
    _G._SetPickerColor(0.1, 0.2, 0.3, 0.4)
    ExpectColor(bar._statusBarColor, { 0.1, 0.2, 0.3, 0.4 })
    _G._CancelPicker()
    ExpectColor(bar._statusBarColor, HIGH)
    Click(state.colors.durationHighColor.button)
    _G._SetPickerColor(0.2, 0.3, 0.4, 0.5)
    _G._AcceptPicker()
    Click(state.colors.durationHighColor.button)
    _G._SetPickerColor(0.6, 0.7, 0.8, 0.9)
    local stale = ColorPickerFrame.swatchFunc
    _G._SelectDropdown(state.choices.barColorMode.dropdown, "Solid")
    stale()
    ExpectColor({ ns.Config.GetColor("durationHighColor") }, { 0.2, 0.3, 0.4, 0.5 })
    _G._SelectDropdown(state.choices.barColorMode.dropdown, "By time remaining")
    Click(state.colors.durationMediumColor.button)
    _G._SetPickerColor(0.3, 0.4, 0.5, 0.6)
    ExpectColor(bar._statusBarColor, { 0.2, 0.3, 0.4, 0.5 })
    _G._AcceptPicker()
    Click(state.colors.durationLowColor.button)
    _G._SetPickerColor(0.5, 0.6, 0.7, 0.8)
    stale = ColorPickerFrame.swatchFunc
    _G._stubInCombat = true
    _G._FireEvent("PLAYER_REGEN_DISABLED")
    stale()
    expect(ColorPickerFrame:IsShown()).to_equal(false)
    ExpectColor({ ns.Config.GetColor("durationLowColor") }, LOW)
    _G._stubInCombat = false
    _G._FireEvent("PLAYER_REGEN_ENABLED")
    state = OpenSettings()
    Click(state.colors.durationHighColor.button)
    _G._SetPickerColor(0.7, 0.8, 0.9, 1)
    stale = ColorPickerFrame.swatchFunc
    Click(state.resetButton)
    stale()
    expect(ns.Config.GetChoice("barColorMode")).to_equal("CLASS")
    for index, key in ipairs(COLOR_KEYS) do
      ExpectColor({ ns.Config.GetColor(key) }, ({ HIGH, MEDIUM, LOW })[index])
    end
    EditModeManagerFrame:ExitEditMode()
  end)
end)
