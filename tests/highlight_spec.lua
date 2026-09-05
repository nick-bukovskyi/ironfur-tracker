local ns = _G._test_ns
local LIBRARY_NAME = "EnhanceQoLEditMode-1.0"
local SUPPORTED_MINOR = 21000001
local externalLibrary

local function Reset()
  _G._ResetWowStubs()
  EventRegistry:TriggerEvent("EditMode.Exit")
  _G._FireEvent("PLAYER_REGEN_ENABLED")
  ns.Config.ResetBar()
  ns.Bar.ApplyGeometry()
  _G._FireEvent("PLAYER_ENTERING_WORLD")
  GameTooltip:Hide()
  if externalLibrary and externalLibrary.internal.managerEyeButton then
    externalLibrary.internal.managerEyeButton.allHidden = false
  end
end

local function OpenSettings()
  EditModeManagerFrame:EnterEditMode()
  _G._RunFrameScript(ns.EditMode._GetTestState().selection, "OnMouseDown")
  return ns.Settings._GetTestState(), ns.EditMode._GetTestState().selection
end

local function Click(button)
  _G._RunFrameScript(button, "OnClick", "LeftButton")
end

local function CreateExternalEye(hidden)
  local button = CreateFrame("Button", nil, EditModeManagerFrame)
  button.allHidden = hidden
  button:SetScript("OnClick", function(self, mouseButton)
    if mouseButton ~= "LeftButton" then
      error("external eye fixture expects LeftButton")
    end
    self.allHidden = not self.allHidden
  end)
  return button
end

-- Only the verified public callback/AddFrame boundary and private eye state
local function CreateExternalLibrary(minor, hidden, withEye)
  local library = assert(LibStub:NewLibrary(LIBRARY_NAME, minor))
  library.internal = {}
  library._fixtureEnterCallbacks = {}
  library._fixtureAddFrameCount = 0
  if withEye then
    library.internal.managerEyeButton = CreateExternalEye(hidden)
  end
  function library:RegisterCallback(event, callback, ...)
    if select("#", ...) ~= 0 or event ~= "enter" or type(callback) ~= "function" then
      error("external library expects RegisterCallback('enter', function)")
    end
    self._fixtureEnterCallbacks[#self._fixtureEnterCallbacks + 1] = callback
  end
  function library:AddFrame(frame, callback, defaults, ...)
    if
      select("#", ...) ~= 0
      or type(frame) ~= "table"
      or not frame._type
      or (callback ~= nil and type(callback) ~= "function")
      or (defaults ~= nil and type(defaults) ~= "table")
    then
      error("external library received an invalid AddFrame signature")
    end
    self._fixtureAddFrameCount = self._fixtureAddFrameCount + 1
    if self._fixturePendingEye then
      self.internal.managerEyeButton = self._fixturePendingEye
      self._fixturePendingEye = nil
    end
  end
  return library
end

local function TriggerExternalEnter()
  local eye = externalLibrary.internal.managerEyeButton
  if eye then
    eye.allHidden = false
  end
  for _, callback in ipairs(externalLibrary._fixtureEnterCallbacks) do
    callback()
  end
end

describe("Edit Mode highlight visibility", function()
  it("toggles only Ironfur's highlight while preserving the settings, sample, and drag", function()
    Reset()
    expect(LibStub:GetLibrary(LIBRARY_NAME, true)).to_be_nil()
    local state, selection = OpenSettings()
    expect(state.eyeButton:GetNormalTexture()._texture).to_equal("Interface\\LFGFrame\\LFG-Eye")
    _G._RunFrameScript(state.eyeButton, "OnEnter")
    expect(GameTooltip:GetText()).to_equal("Hide highlight")
    Click(state.eyeButton)
    expect(ns.EditMode.AreHighlightsHidden()).to_equal(true)
    expect(selection:GetAlpha()).to_equal(0)
    expect(selection:IsShown()).to_equal(true)
    expect(selection:IsMouseEnabled()).to_equal(true)
    expect(state.panel:IsShown()).to_equal(true)
    expect(ns.EditMode.IsPreviewActive()).to_equal(true)
    expect(ns.Bar._GetPresentationSnapshot().stackText).to_equal("3")
    expect(ns.Tracker._GetSnapshot().count).to_equal(0)
    expect(GameTooltip:GetText()).to_equal("Show highlight")
    expect(state.eyeButton:GetNormalTexture()._texCoord[1]).to_equal(0.5)
    _G._RunFrameScript(selection, "OnDragStart")
    expect(ns.EditMode._GetTestState().dragging).to_equal(true)
    expect(selection:GetAlpha()).to_equal(0)
    expect(state.panel:IsShown()).to_equal(true)
    _G._RunFrameScript(selection, "OnDragStop")
    Click(state.eyeButton)
    expect(selection:GetAlpha()).to_equal(1)
    expect(state.eyeButton:GetNormalTexture()._texCoord[1]).to_equal(0)
    _G._RunFrameScript(state.eyeButton, "OnLeave")
    expect(GameTooltip:IsShown()).to_equal(false)
    ns.Settings.Refresh()
    expect(GameTooltip:IsShown()).to_equal(false)
    EditModeManagerFrame:ExitEditMode()
  end)

  it("resets a local choice on the next session and keeps foreign tooltips open", function()
    Reset()
    local state, selection = OpenSettings()
    Click(state.eyeButton)
    local foreign = CreateFrame("Button", nil, UIParent)
    GameTooltip:SetOwner(foreign, "ANCHOR_RIGHT")
    GameTooltip:SetText("Foreign tooltip")
    GameTooltip:Show()
    EditModeManagerFrame:ExitEditMode()
    expect(GameTooltip:IsShown()).to_equal(true)
    expect(GameTooltip:GetOwner()).to_equal(foreign)
    expect(GameTooltip:GetText()).to_equal("Foreign tooltip")
    state, selection = OpenSettings()
    expect(ns.EditMode.AreHighlightsHidden()).to_equal(false)
    expect(selection:GetAlpha()).to_equal(1)
    EditModeManagerFrame:ExitEditMode()
  end)

  it("suspends native selections and safely restores the local hidden highlight", function()
    Reset()
    local state, selection = OpenSettings()
    Click(state.eyeButton)
    _G._RunFrameScript(selection, "OnDragStart")
    EditModeManagerFrame:HideSystemSelections()
    expect(selection:IsShown()).to_equal(false)
    expect(state.panel:IsShown()).to_equal(false)
    expect(ns.EditMode._GetTestState().dragging).to_equal(false)
    expect(ns.EditMode.IsPreviewActive()).to_equal(false)
    EditModeManagerFrame:ShowSystemSelections()
    expect(selection:IsShown()).to_equal(true)
    expect(selection:GetAlpha()).to_equal(0)
    expect(selection:IsMouseEnabled()).to_equal(true)
    expect(ns.EditMode.IsPreviewActive()).to_equal(true)
    EditModeManagerFrame:ExitEditMode()
  end)

  it("ignores an unsupported optional library and attaches a supported late eye already hidden", function()
    Reset()
    local state, selection = OpenSettings()
    externalLibrary = CreateExternalLibrary(SUPPORTED_MINOR - 1, true, true)
    _G._FireEvent("ADDON_LOADED", "UnsupportedEditModeProvider")
    expect(#externalLibrary._fixtureEnterCallbacks).to_equal(0)
    expect(selection:GetAlpha()).to_equal(1)
    externalLibrary = CreateExternalLibrary(SUPPORTED_MINOR, true, false)
    _G._FireEvent("ADDON_LOADED", "SupportedEditModeProvider")
    expect(#externalLibrary._fixtureEnterCallbacks).to_equal(1)
    expect(selection:GetAlpha()).to_equal(1)
    externalLibrary._fixturePendingEye = CreateExternalEye(true)
    externalLibrary:AddFrame(CreateFrame("Frame", nil, UIParent))
    expect(ns.EditMode.AreHighlightsHidden()).to_equal(true)
    expect(selection:GetAlpha()).to_equal(0)
    expect(state.panel:IsShown()).to_equal(true)
    expect(ns.EditMode.IsPreviewActive()).to_equal(true)
    EditModeManagerFrame:ExitEditMode()
  end)

  it("follows repeated global clicks and lets each subsequent local or global action win", function()
    Reset()
    local state, selection = OpenSettings()
    local eye = externalLibrary.internal.managerEyeButton
    for _ = 1, 3 do
      Click(eye)
      expect(selection:GetAlpha()).to_equal(0)
      expect(state.panel:IsShown()).to_equal(true)
      Click(eye)
      expect(selection:GetAlpha()).to_equal(1)
    end
    Click(eye)
    Click(state.eyeButton)
    expect(eye.allHidden).to_equal(true)
    expect(selection:GetAlpha()).to_equal(1)
    _G._FireEvent("PLAYER_ENTERING_WORLD")
    expect(selection:GetAlpha()).to_equal(1)
    _G._FireEvent("ADDON_LOADED", "UnrelatedAddon")
    expect(selection:GetAlpha()).to_equal(1)
    externalLibrary:AddFrame(CreateFrame("Frame", nil, UIParent))
    expect(selection:GetAlpha()).to_equal(1)
    Click(eye)
    expect(selection:GetAlpha()).to_equal(1)
    Click(eye)
    expect(selection:GetAlpha()).to_equal(0)
    EditModeManagerFrame:ExitEditMode()
  end)

  it("reuses callbacks and ignores an obsolete eye after the library replaces it", function()
    Reset()
    local _, selection = OpenSettings()
    local oldEye = externalLibrary.internal.managerEyeButton
    local frame = CreateFrame("Frame", nil, UIParent)
    externalLibrary._fixturePendingEye = CreateExternalEye(false)
    externalLibrary:AddFrame(frame)
    local newEye = externalLibrary.internal.managerEyeButton
    for _ = 1, 3 do
      _G._FireEvent("ADDON_LOADED", "SupportedEditModeProvider")
      externalLibrary:AddFrame(frame)
    end
    expect(#externalLibrary._fixtureEnterCallbacks).to_equal(1)
    expect(#externalLibrary._secureHooks.AddFrame).to_equal(1)
    Click(oldEye)
    expect(oldEye.allHidden).to_equal(true)
    expect(selection:GetAlpha()).to_equal(1)
    Click(newEye)
    expect(selection:GetAlpha()).to_equal(0)
    EditModeManagerFrame:ExitEditMode()
  end)

  it("synchronizes after the provider resets its eye for a new Edit Mode session", function()
    Reset()
    local _, selection = OpenSettings()
    Click(externalLibrary.internal.managerEyeButton)
    expect(selection:GetAlpha()).to_equal(0)
    EditModeManagerFrame:ExitEditMode()
    EditModeManagerFrame:EnterEditMode()
    expect(selection:GetAlpha()).to_equal(0)
    TriggerExternalEnter()
    expect(selection:GetAlpha()).to_equal(1)
    expect(ns.EditMode.AreHighlightsHidden()).to_equal(false)
    EditModeManagerFrame:ExitEditMode()
  end)
end)
