local ns = _G._test_ns
local bar = ns.Bar.GetFrame()
local sharedMedia = LibStub("LibSharedMedia-3.0")
local DEFAULT_COLOR = { 0, 0, 0, 0.8 }

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

local function Backdrop()
  return ns.Bar._GetPresentationSnapshot().backdropRegion
end

local function ExpectColor(actual, expected)
  for index = 1, 4 do
    expect(actual[index]).to_be_close_to(expected[index])
  end
end

local function Click(button)
  _G._RunFrameScript(button, "OnClick", "LeftButton")
end

describe("Backdrop appearance", function()
  it("adds backdrop defaults to existing settings and repairs only corrupt backdrop fields", function()
    local saved = {
      schemaVersion = 6,
      bar = {
        width = 410,
        barTexture = "Blizzard",
        fontSize = 19,
        barColorMode = "STACKS",
        stackColors = {},
        tickColor = { r = 0.2, g = 0.3, b = 0.4, a = 0.5 },
      },
    }
    ns.Config.Initialize(saved)
    expect(saved.schemaVersion).to_equal(11)
    expect(ns.Config.GetTexture("backdropTexture")).to_equal("Solid")
    ExpectColor({ ns.Config.GetColor("backdropColor") }, DEFAULT_COLOR)
    expect(ns.Config.GetNumber("width")).to_equal(410)
    expect(ns.Config.GetNumber("fontSize")).to_equal(19)
    expect(ns.Config.GetStackColorCount()).to_equal(0)
    saved.bar.backdropTexture = "Saved unavailable backdrop"
    saved.bar.backdropColor = { r = 0.2, g = math.huge, b = 0.4, a = "invalid" }
    ns.Config.Initialize(saved)
    expect(ns.Config.GetTexture("backdropTexture")).to_equal("Saved unavailable backdrop")
    ExpectColor({ ns.Config.GetColor("backdropColor") }, { 0.2, 0, 0.4, 0.8 })
    ExpectColor({ ns.Config.GetColor("tickColor") }, { 0.2, 0.3, 0.4, 0.5 })
    saved.bar.backdropTexture = "invalid\nname"
    ns.Config.Initialize(saved)
    expect(ns.Config.GetTexture("backdropTexture")).to_equal("Solid")
    expect(ns.Config.GetTexture("barTexture")).to_equal("Blizzard")
    Reset()
  end)

  it("keeps the backdrop full size and independent of live fill, stack colors, and expiry", function()
    Reset()
    ns.Config.SetTexture("backdropTexture", "Blizzard")
    ns.Config.SetColor("backdropColor", 0.2, 0.3, 0.4, 0.35)
    ns.Config.SetColor("tickColor", 0.6, 0.7, 0.8, 0.9)
    ns.Config.SetChoice("barColorMode", "STACKS")
    ns.Config.SetStackColor(1, 1, 0, 0, 1)
    ns.Config.SetStackColor(2, 0, 1, 0, 1)
    ns.Bar.ApplyAppearance()
    local backdrop = Backdrop()
    expect(backdrop._layer).to_equal("BACKGROUND")
    expect(backdrop._allPoints[1]).to_equal(bar)
    expect(backdrop._texture).to_equal(ns.Media.Resolve("statusbar", "Blizzard"))
    expect(bar._value).to_equal(0)
    expect(bar:IsShown()).to_equal(true)
    for index = 1, 2 do
      _G._stubNow = index - 1
      _G._FireEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-backdrop-" .. index, 192081)
      ExpectColor(backdrop._vertexColor, { 0.2, 0.3, 0.4, 0.35 })
    end
    ExpectColor(bar._statusBarColor, { 0, 1, 0, 1 })
    local tickLayer = ns.Bar._GetPresentationSnapshot().tickTextures[1].point[2]
    ExpectColor(tickLayer._textures[1]._color, { 0.6, 0.7, 0.8, 0.9 })
    ns.Config.SetChoice("barColorMode", "CLASS")
    ns.Config.CommitNumber("width", 510)
    ns.Bar.ApplyGeometry()
    expect(Backdrop()).to_equal(backdrop)
    expect(backdrop._allPoints[1]).to_equal(bar)
    ExpectColor(backdrop._vertexColor, { 0.2, 0.3, 0.4, 0.35 })
    _G._stubNow = 9
    _G._RunFrameScript(ns.Core._GetUpdateDriver(), "OnUpdate", 0)
    expect(bar._value).to_equal(0)
    expect(bar:IsShown()).to_equal(true)
    expect(ns.Tracker._GetSnapshot().count).to_equal(0)
    ExpectColor(backdrop._vertexColor, { 0.2, 0.3, 0.4, 0.35 })
    expect(backdrop._texture).to_equal(ns.Media.Resolve("statusbar", "Blizzard"))
  end)

  it("previews backdrop opacity, cancels stale combat edits, and resets both backdrop controls", function()
    Reset()
    local state = OpenSettings()
    local backdrop = Backdrop()
    Click(state.colors.backdropColor.button)
    _G._SetPickerColor(0.2, 0.3, 0.4, 0)
    ExpectColor(backdrop._vertexColor, { 0.2, 0.3, 0.4, 0 })
    expect(bar._statusBarColor[4]).to_equal(1)
    _G._CancelPicker()
    ExpectColor(backdrop._vertexColor, DEFAULT_COLOR)
    Click(state.colors.backdropColor.button)
    _G._SetPickerColor(0.3, 0.4, 0.5, 0.6)
    _G._AcceptPicker()
    Click(state.colors.backdropColor.button)
    _G._SetPickerColor(0.7, 0.8, 0.9, 1)
    local stale = ColorPickerFrame.swatchFunc
    _G._stubInCombat = true
    _G._FireEvent("PLAYER_REGEN_DISABLED")
    stale()
    expect(ColorPickerFrame:IsShown()).to_equal(false)
    ExpectColor(backdrop._vertexColor, { 0.3, 0.4, 0.5, 0.6 })
    ExpectColor({ ns.Config.GetColor("backdropColor") }, { 0.3, 0.4, 0.5, 0.6 })
    _G._stubInCombat = false
    _G._FireEvent("PLAYER_REGEN_ENABLED")
    state = OpenSettings()
    _G._SelectDropdown(state.textures.backdropTexture.dropdown, "Blizzard")
    Click(state.colors.backdropColor.button)
    _G._SetPickerColor(0.7, 0.8, 0.9, 1)
    stale = ColorPickerFrame.swatchFunc
    Click(state.resetButton)
    stale()
    expect(ns.Config.GetTexture("backdropTexture")).to_equal("Solid")
    expect(backdrop._texture).to_equal(ns.Media.Resolve("statusbar", "Solid"))
    ExpectColor(backdrop._vertexColor, DEFAULT_COLOR)
    ExpectColor({ ns.Config.GetColor("backdropColor") }, DEFAULT_COLOR)
    EditModeManagerFrame:ExitEditMode()
  end)

  it("recovers a late backdrop texture without changing the independently selected fill", function()
    Reset()
    local name, path = "Test late backdrop", "Interface\\AddOns\\TestMedia\\backdrop.tga"
    ns.Config.SetTexture("backdropTexture", name)
    ns.Bar.ApplyAppearance()
    local state = OpenSettings()
    local backdrop = Backdrop()
    local fillPath = bar._statusBarTexture
    local dropdown = state.textures.backdropTexture.dropdown
    expect(backdrop._texture).to_equal(ns.Media.Resolve("statusbar", "Solid"))
    expect(dropdown:GetText()).to_equal(name)
    _G._stubKnownFileAssets[path] = true
    expect(sharedMedia:Register("statusbar", name, path)).to_equal(true)
    expect(backdrop._texture).to_equal(path)
    expect(bar._statusBarTexture).to_equal(fillPath)
    expect(ns.Config.GetTexture("barTexture")).to_equal("Solid")
    expect(ns.Config.GetTexture("backdropTexture")).to_equal(name)
    local menu = _G._OpenDropdown(dropdown)
    for index, entry in ipairs(menu.entries) do
      expect(dropdown._menuRows[index]._previewTexture._texture).to_equal(ns.Media.Resolve("statusbar", entry.text))
    end
    _G._SelectDropdown(dropdown, name)
    expect(Backdrop()).to_equal(backdrop)
    expect(backdrop._texture).to_equal(path)
    EditModeManagerFrame:ExitEditMode()
  end)

  it("orders the appearance sections and keeps width and height above the bar texture", function()
    Reset()
    local state = OpenSettings()
    local content = state.scrollFrame._scrollChild
    local sections = {}
    for _, child in ipairs(content._children) do
      for _, text in ipairs(child._fontStrings or {}) do
        if text._template == "GameFontNormalMed3" then
          sections[#sections + 1] = { name = text:GetText(), frame = child }
        end
      end
    end
    local function CheckOrder()
      table.sort(sections, function(left, right)
        return select(5, left.frame:GetPoint()) > select(5, right.frame:GetPoint())
      end)
      local names, positions = {}, {}
      for _, section in ipairs(sections) do
        names[#names + 1] = section.name
        positions[section.name] = select(5, section.frame:GetPoint())
      end
      expect(table.concat(names, ",")).to_equal("Visibility,Font,Bar,Backdrop,Border,Tick")
      local widthY, heightY = select(5, state.rows.width:GetPoint()), select(5, state.rows.height:GetPoint())
      local textureY = select(5, state.textures.barTexture:GetPoint())
      expect(positions.Bar > widthY and widthY > heightY).to_equal(true)
      expect(heightY > textureY and textureY > positions.Backdrop).to_equal(true)
    end
    CheckOrder()
    _G._SelectDropdown(state.choices.barColorMode.dropdown, "By stack count")
    CheckOrder()
    EditModeManagerFrame:ExitEditMode()
  end)

  it("reserves scrollbar space and preserves its native state through content range changes", function()
    Reset()
    local state = OpenSettings()
    local scrollbar
    for _, frame in ipairs(_G._allFrames) do
      if frame._template == "MinimalScrollBar" and frame:GetParent() == state.panel then
        scrollbar = frame
      end
    end
    expect(scrollbar).to_be_truthy()
    UIParent:SetHeight(1600)
    _G._FireEvent("DISPLAY_SIZE_CHANGED")
    UIParent:SetHeight(state.panel:GetHeight() + 80)
    _G._FireEvent("UI_SCALE_CHANGED")
    for _, mode in ipairs({ "Class color", "By stack count", "Solid", "Class color" }) do
      _G._SelectDropdown(state.choices.barColorMode.dropdown, mode)
      local range = state.scrollFrame:GetVerticalScrollRange()
      -- Native layout delivers this callback after the content or viewport changes
      _G._RunFrameScript(state.scrollFrame, "OnScrollRangeChanged", 0, range)
      expect(state.panel:GetWidth()).to_equal(428)
      expect(state.scrollFrame:GetWidth()).to_equal(363)
      local leftMargin = select(4, state.scrollFrame:GetPoint())
      expect(leftMargin).to_equal(20)
      for _, row in pairs(state.rows) do
        local _, sliderAnchor, sliderRelativePoint, sliderGap = row.slider:GetPoint()
        local _, inputAnchor, inputRelativePoint, inputGap = row.input:GetPoint()
        expect(sliderAnchor).to_equal(row.label)
        expect(inputAnchor).to_equal(row.slider)
        expect(sliderRelativePoint).to_equal("RIGHT")
        expect(inputRelativePoint).to_equal("RIGHT")
        local edge = select(4, row:GetPoint())
          + select(4, row.label:GetPoint())
          + row.label._width
          + sliderGap
          + row.slider:GetWidth()
          + inputGap
          + row.input:GetWidth()
        expect(edge).to_equal(state.scrollFrame:GetWidth())
      end
      expect(scrollbar:IsShown()).to_equal(true)
      local _, scrollAnchor, scrollRelativePoint, scrollOffset = scrollbar:GetPoint()
      expect(scrollAnchor).to_equal(state.scrollFrame)
      expect(scrollRelativePoint).to_equal("TOPRIGHT")
      expect(scrollOffset - 17 / 2).to_equal(8)
      local arrowRight = leftMargin + state.scrollFrame:GetWidth() + scrollOffset + 17 / 2
      expect(state.panel:GetWidth() - arrowRight).to_equal(20)
      if mode == "Class color" then
        expect(range).to_equal(0)
        expect(state.scrollFrame:GetVerticalScroll()).to_equal(0)
        expect(scrollbar._visibleExtentPercentage).to_equal(1)
        expect(scrollbar._scrollPercentage).to_equal(0)
      else
        expect(range > 0).to_equal(true)
        expect(scrollbar._visibleExtentPercentage < 1).to_equal(true)
        expect(state.scrollFrame:GetVerticalScroll() <= range).to_equal(true)
        state.scrollFrame:SetVerticalScroll(range)
        expect(scrollbar._scrollPercentage).to_equal(1)
      end
    end
    local removeButton = state.stackColors.removeButton
    local rightAnchorFound = false
    for index = 1, removeButton:GetNumPoints() do
      local point, relativeTo, relativePoint, x = removeButton:GetPoint(index)
      if point == "RIGHT" then
        expect(relativeTo).to_equal(removeButton:GetParent())
        expect(relativePoint).to_equal("RIGHT")
        expect(x <= 0).to_equal(true)
        rightAnchorFound = true
      end
    end
    expect(rightAnchorFound).to_equal(true)
    expect(removeButton:GetParent():GetWidth() <= state.scrollFrame:GetWidth()).to_equal(true)
    EditModeManagerFrame:ExitEditMode()
  end)
end)
