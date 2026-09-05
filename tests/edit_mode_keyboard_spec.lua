local ns = _G._test_ns
local Bootstrap = _G._testBootstrap
local bar = ns.Bar.GetFrame()

local function Reset()
  _G._ResetWowStubs()
  EventRegistry:TriggerEvent("EditMode.Exit")
  _G._FireEvent("PLAYER_REGEN_ENABLED")
  ns.Config.ResetBar()
  ns.Bar.ApplyGeometry()
  _G._FireEvent("PLAYER_ENTERING_WORLD")
end

local function OpenEditor()
  EditModeManagerFrame:EnterEditMode()
  _G._RunFrameScript(ns.EditMode._GetTestState().selection, "OnMouseDown", "LeftButton")
  return ns.EditMode._GetTestState()
end

local function KeyDown(panel, key)
  _G._RunFrameScript(panel, "OnKeyDown", key)
end

local function ExpectPosition(x, y)
  expect(IronfurTrackerDB.bar.offsetX).to_be_close_to(x)
  expect(IronfurTrackerDB.bar.offsetY).to_be_close_to(y)
  local point, parent, relativePoint, offsetX, offsetY = bar:GetPoint()
  expect(bar:GetNumPoints()).to_equal(1)
  expect(point).to_equal("CENTER")
  expect(parent).to_equal(UIParent)
  expect(relativePoint).to_equal("CENTER")
  expect(offsetX).to_be_close_to(x)
  expect(offsetY).to_be_close_to(y)
end

describe("Edit Mode keyboard placement", function()
  it("moves each arrow by one UI unit or ten with Shift and preserves fractional offsets", function()
    Reset()
    local state = OpenEditor()
    expect(state.panel:IsKeyboardEnabled()).to_equal(true)
    for _, shift in ipairs({ false, true }) do
      _G._stubShiftKeyDown = shift
      local step = shift and 10 or 1
      for _, direction in ipairs({ { "UP", 0, 1 }, { "DOWN", 0, -1 }, { "LEFT", -1, 0 }, { "RIGHT", 1, 0 } }) do
        ns.Config.SetPosition(125.5, -42.25)
        ns.Bar.ApplyGeometry()
        KeyDown(state.panel, direction[1])
        ExpectPosition(125.5 + direction[2] * step, -42.25 + direction[3] * step)
        expect(state.panel:GetPropagateKeyboardInput()).to_equal(false)
        expect(state.panel:IsShown()).to_equal(true)
        expect(ns.EditMode._GetTestState().selected).to_equal(true)
      end
    end
  end)

  it("handles repeated key events and reads the current Shift state without retaining it", function()
    Reset()
    local state = OpenEditor()
    for _ = 1, 20 do
      KeyDown(state.panel, "RIGHT")
    end
    _G._stubShiftKeyDown = true
    KeyDown(state.panel, "RIGHT")
    _G._stubShiftKeyDown = false
    KeyDown(state.panel, "RIGHT")
    _G._RunFrameScript(state.panel, "OnKeyUp", "RIGHT")
    ExpectPosition(31, 0)
    expect(state.panel:GetPropagateKeyboardInput()).to_equal(true)
    expect(state.panel:GetScript("OnUpdate")).to_be_nil()
  end)

  it("leaves other keys and key releases available to normal bindings", function()
    Reset()
    local state = OpenEditor()
    for _, key in ipairs({ "W", "ESCAPE", "PRINTSCREEN", "LSHIFT", "RSHIFT", "LCTRL", "LALT", "PAD1" }) do
      KeyDown(state.panel, "RIGHT")
      expect(state.panel:GetPropagateKeyboardInput()).to_equal(false)
      KeyDown(state.panel, key)
      expect(state.panel:GetPropagateKeyboardInput()).to_equal(true)
    end
    ExpectPosition(8, 0)
    KeyDown(state.panel, "RIGHT")
    _G._RunFrameScript(state.panel, "OnKeyUp", "W")
    expect(state.panel:GetPropagateKeyboardInput()).to_equal(true)
    ExpectPosition(9, 0)
  end)

  it("keeps arrows in focused settings and external text fields and resumes after focus clears", function()
    Reset()
    local state = OpenEditor()
    local chatInput = CreateFrame("EditBox", nil, UIParent)
    for _, input in ipairs({ state.rows.width.input, chatInput }) do
      input:SetFocus()
      _G._stubShiftKeyDown = true
      KeyDown(state.panel, "LEFT")
      ExpectPosition(0, 0)
      expect(input:HasFocus()).to_equal(true)
      expect(state.panel:GetPropagateKeyboardInput()).to_equal(true)
      input:ClearFocus()
    end
    _G._stubShiftKeyDown = false
    KeyDown(state.panel, "LEFT")
    ExpectPosition(-1, 0)
    expect(ns.Config.GetNumber("width")).to_equal(300)
  end)

  it("nudges away from a snapped position without querying or reapplying snapping", function()
    Reset()
    local state = OpenEditor()
    EditModeManagerFrame:SetEnableSnap(true)
    _G._stubMagneticFrameInfos = {
      { frame = UIParent, point = "CENTER", relativePoint = "CENTER", offset = 20, isHorizontal = true },
    }
    ns.Config.SetPosition(20, 30.5)
    ns.Bar.ApplyGeometry()
    KeyDown(state.panel, "LEFT")
    ExpectPosition(19, 30.5)
    expect(_G._stubMagneticQueryCount).to_equal(0)
    expect(ns.EditModeSnap._GetTestState().active).to_equal(false)
  end)

  it("ends an active drag at its current position before nudging and cancels snap preview work", function()
    Reset()
    local state = OpenEditor()
    EditModeManagerFrame:SetEnableSnap(true)
    _G._RunFrameScript(state.selection, "OnDragStart")
    _G._SetFrameCenter(bar, 1100.25, 400.75)
    KeyDown(state.panel, "RIGHT")
    ExpectPosition(141.25, -139.25)
    expect(ns.EditMode._GetTestState().dragging).to_equal(false)
    expect(bar._moving).to_equal(false)
    expect(bar:IsMovable()).to_equal(false)
    local snap = ns.EditModeSnap._GetTestState()
    expect(snap.active).to_equal(false)
    expect(snap.previewFrame:IsShown()).to_equal(false)
    expect(snap.previewFrame:GetScript("OnUpdate")).to_be_nil()
    _G._RunFrameScript(state.selection, "OnDragStop")
    ExpectPosition(141.25, -139.25)
    expect(_G._stubMagneticQueryCount).to_equal(0)
  end)

  it("clamps and saves each screen edge without accumulating invisible movement", function()
    Reset()
    local state = OpenEditor()
    for _, side in ipairs({ -1, 1 }) do
      ns.Config.SetPosition(side * 809.75, side * 530.75)
      ns.Bar.ApplyGeometry()
      local horizontal, vertical = side < 0 and "LEFT" or "RIGHT", side < 0 and "DOWN" or "UP"
      for _ = 1, 3 do
        KeyDown(state.panel, horizontal)
        KeyDown(state.panel, vertical)
      end
      ExpectPosition(side * 810, side * 531)
      KeyDown(state.panel, side < 0 and "RIGHT" or "LEFT")
      ExpectPosition(side * 809, side * 531)
    end
  end)

  it("preserves UI-unit increments across scale and resolution changes", function()
    Reset()
    local state = OpenEditor()
    ns.Config.SetPosition(125.5, -42.25)
    ns.Bar.ApplyGeometry()
    UIParent:SetScale(0.75)
    _G._FireEvent("UI_SCALE_CHANGED")
    KeyDown(state.panel, "RIGHT")
    ExpectPosition(126.5, -42.25)
    UIParent:SetSize(1280, 720)
    _G._SetFrameCenter(UIParent, 640, 360)
    _G._FireEvent("DISPLAY_SIZE_CHANGED")
    _G._stubShiftKeyDown = true
    KeyDown(state.panel, "UP")
    ExpectPosition(126.5, -32.25)
  end)

  it("restores nudged coordinates after reload while preserving existing appearance", function()
    Reset()
    local state = OpenEditor()
    ns.Config.CommitNumber("width", 640)
    ns.Config.SetPosition(125.5, -42.25)
    ns.Bar.ApplyGeometry()
    KeyDown(state.panel, "LEFT")
    _G._stubShiftKeyDown = true
    KeyDown(state.panel, "DOWN")
    local environment = Bootstrap.CreateEnvironment()
    local loaded = Bootstrap.LoadAddon(environment, IronfurTrackerDB)
    environment._FireEvent("ADDON_LOADED", Bootstrap.addonName)
    environment._FireEvent("PLAYER_ENTERING_WORLD")
    local _, _, _, x, y = loaded.Bar.GetFrame():GetPoint()
    expect(x).to_equal(124.5)
    expect(y).to_equal(-52.25)
    expect(loaded.Config.GetNumber("width")).to_equal(640)
    expect(environment.IronfurTrackerDB.schemaVersion).to_equal(11)
  end)

  local interruptions = {
    {
      name = "combat",
      interrupt = function()
        _G._stubInCombat = true
        _G._FireEvent("PLAYER_REGEN_DISABLED")
      end,
      recover = function()
        _G._stubInCombat = false
        _G._FireEvent("PLAYER_REGEN_ENABLED")
      end,
    },
    {
      name = "Edit Mode exit",
      interrupt = function()
        EditModeManagerFrame:ExitEditMode()
      end,
    },
    {
      name = "native system selection",
      interrupt = function()
        EditModeManagerFrame:SelectSystem({})
      end,
    },
    {
      name = "native deselection",
      interrupt = function()
        EditModeManagerFrame:ClearSelectedSystem()
      end,
    },
    {
      name = "hidden selections",
      interrupt = function()
        EditModeManagerFrame:HideSystemSelections()
      end,
    },
    {
      name = "hidden tracker selection",
      interrupt = function(state)
        state.selection:Hide()
      end,
    },
    {
      name = "hidden settings",
      interrupt = function()
        ns.Settings.Hide()
      end,
    },
    {
      name = "Druid eligibility loss",
      interrupt = function()
        _G._stubClassToken = "WARRIOR"
        _G._FireEvent("PLAYER_ENTERING_WORLD")
      end,
      recover = function()
        _G._stubClassToken = "DRUID"
        _G._FireEvent("PLAYER_ENTERING_WORLD")
      end,
    },
  }
  for _, case in ipairs(interruptions) do
    it("stops keyboard placement after " .. case.name .. " and resumes only after reselection", function()
      Reset()
      local state = OpenEditor()
      _G._stubShiftKeyDown = true
      KeyDown(state.panel, "RIGHT")
      case.interrupt(state)
      expect(state.panel:IsShown()).to_equal(false)
      -- Invoke stale callbacks directly to check their guards as well as hiding
      KeyDown(state.panel, "RIGHT")
      _G._RunFrameScript(state.panel, "OnKeyUp", "RIGHT")
      ExpectPosition(10, 0)
      if case.recover then
        case.recover()
      end
      _G._stubShiftKeyDown = false
      KeyDown(state.panel, "RIGHT")
      ExpectPosition(10, 0)
      OpenEditor()
      KeyDown(state.panel, "RIGHT")
      ExpectPosition(11, 0)
    end)
  end

  it("rejects input when combat lockdown precedes its event notification", function()
    Reset()
    local state = OpenEditor()
    _G._stubInCombat = true
    KeyDown(state.panel, "RIGHT")
    _G._RunFrameScript(state.panel, "OnKeyUp", "RIGHT")
    ExpectPosition(0, 0)
    _G._FireEvent("PLAYER_REGEN_DISABLED")
    expect(state.panel:IsShown()).to_equal(false)
  end)

  it("supports late manager loading and initialization while Edit Mode is already active", function()
    for _, alreadyActive in ipairs({ false, true }) do
      local environment = Bootstrap.CreateEnvironment()
      local manager = environment.EditModeManagerFrame
      if alreadyActive then
        manager:EnterEditMode()
      else
        environment.EditModeManagerFrame = nil
      end
      local loaded = Bootstrap.LoadAddon(environment)
      environment._FireEvent("ADDON_LOADED", Bootstrap.addonName)
      environment.EditModeManagerFrame = manager
      environment._FireEvent("ADDON_LOADED", "Blizzard_EditMode")
      if not alreadyActive then
        manager:EnterEditMode()
      end
      loaded.EditMode.Select()
      local panel = loaded.Settings._GetTestState().panel
      environment._RunFrameScript(panel, "OnKeyDown", "UP")
      expect(environment.IronfurTrackerDB.bar.offsetY).to_equal(1)
      expect(#manager._secureHooks.SelectSystem).to_equal(1)
    end
  end)

  it("keeps one keyboard handler through repeated editor and player-state transitions", function()
    Reset()
    local state = OpenEditor()
    local frameCount = #_G._allFrames
    local keyHandler = state.panel:GetScript("OnKeyDown")
    _G._stubShapeshiftFormID = 1
    for _ = 1, 30 do
      _G._FireEvent("UPDATE_SHAPESHIFT_FORM")
      _G._FireEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
      _G._FireEvent("PLAYER_DEAD")
      _G._FireEvent("PLAYER_ALIVE")
      _G._FireEvent("PLAYER_ENTERING_WORLD")
      KeyDown(state.panel, "UP")
      EditModeManagerFrame:ExitEditMode()
      OpenEditor()
    end
    ExpectPosition(0, 30)
    expect(#_G._allFrames).to_equal(frameCount)
    expect(state.panel:GetScript("OnKeyDown")).to_equal(keyHandler)
  end)
end)
