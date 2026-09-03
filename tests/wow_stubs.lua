-- Strict World of Warcraft API stubs for Ironfur Tracker.
-- Only contracts exercised by the add-on are represented here.

local unpackValues = table.unpack or unpack

local function AssertType(value, expected, label)
    if type(value) ~= expected then
        error(string.format("%s must be %s, got %s", label, expected, type(value)), 3)
    end
end

local function AssertNoExtraArguments(name, ...)
    if select("#", ...) ~= 0 then
        error(name .. " received unexpected arguments", 3)
    end
end

local TextureMixin = {}
TextureMixin.__index = TextureMixin

function TextureMixin:SetAllPoints(...) self._allPoints = { ... } end
function TextureMixin:SetColorTexture(...) self._color = { ... } end
function TextureMixin:SetSize(width, height) self._width = width; self._height = height end
function TextureMixin:SetWidth(width) self._width = width end
function TextureMixin:SetHeight(height) self._height = height end
function TextureMixin:GetWidth() return self._width or 0 end
function TextureMixin:GetHeight() return self._height or 0 end
function TextureMixin:SetPoint(...) self._point = { ... } end
function TextureMixin:GetPoint()
    if not self._point then return nil end
    return unpackValues(self._point)
end
function TextureMixin:ClearAllPoints() self._point = nil end
function TextureMixin:SetSnapToPixelGrid(value) self._snapToPixelGrid = value end
function TextureMixin:SetTexelSnappingBias(value) self._texelSnappingBias = value end
function TextureMixin:Show() self._shown = true end
function TextureMixin:Hide() self._shown = false end
function TextureMixin:IsShown() return self._shown == true end

local FontStringMixin = {}
FontStringMixin.__index = FontStringMixin

function FontStringMixin:SetPoint(...) self._point = { ... } end
function FontStringMixin:SetTextColor(...) self._color = { ... } end
function FontStringMixin:SetText(value) self._text = tostring(value or "") end
function FontStringMixin:GetText() return self._text or "" end
function FontStringMixin:SetWidth(width) self._width = width end
function FontStringMixin:SetHeight(height) self._height = height end
function FontStringMixin:SetJustifyH(justify) self._justifyH = justify end
function FontStringMixin:Show() self._shown = true end
function FontStringMixin:Hide() self._shown = false end
function FontStringMixin:IsShown() return self._shown == true end

local FrameMixin = {}
FrameMixin.__index = FrameMixin

function FrameMixin:GetParent() return self._parent end
function FrameMixin:GetName() return self._name end
function FrameMixin:SetSize(width, height) self._width = width; self._height = height end
function FrameMixin:SetWidth(width) self._width = width end
function FrameMixin:SetHeight(height) self._height = height end
function FrameMixin:GetWidth() return self._width or 0 end
function FrameMixin:GetHeight() return self._height or 0 end
function FrameMixin:GetSize() return self:GetWidth(), self:GetHeight() end

function FrameMixin:SetPoint(...)
    self._point = { ... }
    local point, relativeTo, relativePoint, offsetX, offsetY = ...
    if point == "CENTER" and relativePoint == "CENTER"
        and relativeTo and relativeTo.GetCenter then
        local relativeX, relativeY = relativeTo:GetCenter()
        if relativeX and relativeY then
            self._centerX = relativeX + (offsetX or 0)
            self._centerY = relativeY + (offsetY or 0)
        end
    end
end

function FrameMixin:GetPoint()
    if not self._point then return nil end
    return unpackValues(self._point)
end

function FrameMixin:ClearAllPoints()
    self._point = nil
    self._centerX = nil
    self._centerY = nil
end

function FrameMixin:SetAllPoints(...) self._allPoints = { ... } end
function FrameMixin:GetCenter()
    if self._centerX ~= nil and self._centerY ~= nil then
        return self._centerX, self._centerY
    end
    return self:GetWidth() / 2, self:GetHeight() / 2
end

function FrameMixin:SetFrameStrata(strata) self._frameStrata = strata end
function FrameMixin:SetFrameLevel(level) self._frameLevel = level end
function FrameMixin:GetFrameLevel() return self._frameLevel or 0 end
function FrameMixin:SetMinMaxValues(minimum, maximum) self._min = minimum; self._max = maximum end
function FrameMixin:SetStatusBarTexture(texture) self._statusBarTexture = texture end
function FrameMixin:SetStatusBarColor(...) self._statusBarColor = { ... } end

local function TriggerFrameCallback(frame, event, ...)
    local callbacks = frame._callbacks and frame._callbacks[event]
    if not callbacks then return end

    local snapshot = {}
    for _, entry in ipairs(callbacks) do
        snapshot[#snapshot + 1] = entry
    end
    for _, entry in ipairs(snapshot) do
        entry.callback(entry.owner, ...)
    end
end

function FrameMixin:SetValue(value)
    if self._template == "MinimalSliderWithSteppersTemplate" and self._sliderInitialized then
        if value < self._min then value = self._min end
        if value > self._max then value = self._max end
        local step = self._step or 1
        value = self._min + (math.floor(((value - self._min) / step) + 0.5) * step)
    end

    self._value = value
    if self._template == "MinimalSliderWithSteppersTemplate" and self._sliderInitialized then
        TriggerFrameCallback(self, MinimalSliderWithSteppersMixin.Event.OnValueChanged, value)
    end
end

function FrameMixin:Show()
    local changed = self._shown ~= true
    self._shown = true
    if changed and self._scripts and self._scripts.OnShow then
        self._scripts.OnShow(self)
    end
end

function FrameMixin:Hide()
    local changed = self._shown == true
    self._shown = false
    if changed and self._scripts and self._scripts.OnHide then
        self._scripts.OnHide(self)
    end
end

function FrameMixin:IsShown() return self._shown == true end
function FrameMixin:IsVisible() return self:IsShown() end

function FrameMixin:CreateTexture(name, layer, template, subLevel)
    if name ~= nil then AssertType(name, "string", "texture name") end
    if layer ~= nil then AssertType(layer, "string", "texture layer") end
    local texture = setmetatable({
        _name = name,
        _layer = layer,
        _template = template,
        _subLevel = subLevel,
        _parent = self,
        _shown = true,
    }, TextureMixin)
    self._textures = self._textures or {}
    self._textures[#self._textures + 1] = texture
    return texture
end

function FrameMixin:CreateFontString(name, layer, template)
    if name ~= nil then AssertType(name, "string", "font string name") end
    if layer ~= nil then AssertType(layer, "string", "font string layer") end
    local allowedFontTemplates = {
        GameFontHighlightLarge = true,
        GameFontHighlightMedium = true,
        GameFontNormalLarge = true,
    }
    if template ~= nil and not allowedFontTemplates[template] then
        error("unexpected font-string template: " .. tostring(template), 2)
    end
    local fontString = setmetatable({
        _name = name,
        _layer = layer,
        _template = template,
        _parent = self,
        _shown = true,
        _text = "",
    }, FontStringMixin)
    self._fontStrings = self._fontStrings or {}
    self._fontStrings[#self._fontStrings + 1] = fontString
    return fontString
end

function FrameMixin:SetScript(scriptType, callback)
    AssertType(scriptType, "string", "script type")
    if callback ~= nil then AssertType(callback, "function", "script callback") end
    self._scripts = self._scripts or {}
    self._scripts[scriptType] = callback
end

function FrameMixin:GetScript(scriptType)
    return self._scripts and self._scripts[scriptType]
end

function FrameMixin:HookScript(scriptType, callback)
    AssertType(scriptType, "string", "script type")
    AssertType(callback, "function", "script callback")
    local original = self:GetScript(scriptType)
    self:SetScript(scriptType, function(frame, ...)
        if original then original(frame, ...) end
        callback(frame, ...)
    end)
end

function FrameMixin:RegisterEvent(event)
    AssertType(event, "string", "event")
    self._events = self._events or {}
    self._events[event] = true
end

function FrameMixin:RegisterUnitEvent(event, ...)
    AssertType(event, "string", "event")
    if select("#", ...) == 0 then
        error("RegisterUnitEvent requires at least one unit", 2)
    end
    self:RegisterEvent(event)
    self._unitEvents = self._unitEvents or {}
    self._unitEvents[event] = { ... }
end

function FrameMixin:SetMovable(value) self._movable = value and true or false end
function FrameMixin:IsMovable() return self._movable == true end
function FrameMixin:SetClampedToScreen(value) self._clampedToScreen = value and true or false end
function FrameMixin:EnableMouse(value) self._mouseEnabled = value and true or false end
function FrameMixin:IsMouseEnabled() return self._mouseEnabled == true end
function FrameMixin:RegisterForDrag(...) self._dragButtons = { ... } end
function FrameMixin:StartMoving()
    if not self:IsMovable() then
        error("StartMoving called on a non-movable frame", 2)
    end
    self._moving = true
end
function FrameMixin:StopMovingOrSizing() self._moving = false end
function FrameMixin:SetUserPlaced(value) self._userPlaced = value and true or false end

function FrameMixin:SetText(value) self._text = tostring(value or "") end
function FrameMixin:GetText() return self._text or "" end
function FrameMixin:SetNumber(value) self:SetText(value) end
function FrameMixin:GetNumber() return tonumber(self:GetText()) or 0 end
function FrameMixin:SetAutoFocus(value) self._autoFocus = value and true or false end
function FrameMixin:SetNumeric(value) self._numeric = value and true or false end
function FrameMixin:SetMaxLetters(value) self._maxLetters = value end
function FrameMixin:SetJustifyH(value) self._justifyH = value end
function FrameMixin:SetFocus() self._hasFocus = true end
function FrameMixin:HasFocus() return self._hasFocus == true end
function FrameMixin:ClearFocus()
    local hadFocus = self._hasFocus == true
    self._hasFocus = false
    if hadFocus and self._scripts and self._scripts.OnEditFocusLost then
        self._scripts.OnEditFocusLost(self)
    end
end

function FrameMixin:Init(value, minimum, maximum, steps, formatters)
    if self._template ~= "MinimalSliderWithSteppersTemplate" then
        error("Init is only available on MinimalSliderWithSteppersTemplate", 2)
    end
    if type(value) ~= "number" or type(minimum) ~= "number"
        or type(maximum) ~= "number" or type(steps) ~= "number" or steps <= 0 then
        error("invalid MinimalSliderWithSteppers initialization", 2)
    end
    self._min = minimum
    self._max = maximum
    self._steps = steps
    self._step = (maximum - minimum) / steps
    self._formatters = formatters
    self._value = value
    self._sliderInitialized = true
end

function FrameMixin:RegisterCallback(event, callback, owner)
    AssertType(event, "string", "callback event")
    AssertType(callback, "function", "callback")
    owner = owner or {}
    self._callbacks = self._callbacks or {}
    local callbacks = self._callbacks[event]
    if not callbacks then
        callbacks = {}
        self._callbacks[event] = callbacks
    end
    for index, entry in ipairs(callbacks) do
        if entry.owner == owner then
            callbacks[index] = { owner = owner, callback = callback }
            return owner
        end
    end
    callbacks[#callbacks + 1] = { owner = owner, callback = callback }
    return owner
end

function FrameMixin:SetSystem(system) self._system = system end
function FrameMixin:ShowHighlighted() self._selectionState = "highlighted"; self:Show() end
function FrameMixin:ShowSelected() self._selectionState = "selected"; self:Show() end

_G._allFrames = {}

local allowedFrameTypes = {
    Button = true,
    EditBox = true,
    Frame = true,
    StatusBar = true,
}

local allowedTemplates = {
    DialogBorderTranslucentTemplate = true,
    EditModeSystemSelectionTemplate = true,
    InputBoxTemplate = true,
    MinimalSliderWithSteppersTemplate = true,
    UIPanelButtonTemplate = true,
    UIPanelCloseButton = true,
}

function CreateFrame(frameType, name, parent, template, ...)
    AssertNoExtraArguments("CreateFrame", ...)
    if not allowedFrameTypes[frameType] then
        error("unexpected frame type: " .. tostring(frameType), 2)
    end
    if name ~= nil then AssertType(name, "string", "frame name") end
    if template ~= nil and not allowedTemplates[template] then
        error("unexpected frame template: " .. tostring(template), 2)
    end

    local frame = setmetatable({
        _type = frameType,
        _name = name,
        _parent = parent,
        _template = template,
        _shown = true,
        _width = 0,
        _height = 0,
        _movable = false,
        _mouseEnabled = false,
    }, FrameMixin)
    if name then _G[name] = frame end
    if parent then
        parent._children = parent._children or {}
        parent._children[#parent._children + 1] = frame
    end
    _G._allFrames[#_G._allFrames + 1] = frame
    return frame
end

function _G._RunFrameScript(frame, scriptType, ...)
    local callback = frame and frame._scripts and frame._scripts[scriptType]
    if not callback then
        error("frame has no " .. tostring(scriptType) .. " script", 2)
    end
    return callback(frame, ...)
end

function _G._SetFrameCenter(frame, centerX, centerY)
    frame._centerX = centerX
    frame._centerY = centerY
end

function _G._FireEvent(event, ...)
    AssertType(event, "string", "event")
    local frameCount = #_G._allFrames
    for index = 1, frameCount do
        local frame = _G._allFrames[index]
        if frame._events and frame._events[event] then
            local callback = frame._scripts and frame._scripts.OnEvent
            if not callback then
                error("frame registered " .. event .. " without an OnEvent script", 2)
            end
            callback(frame, event, ...)
        end
    end
end

UIParent = CreateFrame("Frame", "UIParent")
UIParent:SetSize(1920, 1080)
_G._SetFrameCenter(UIParent, 960, 540)

MinimalSliderWithSteppersMixin = {
    Event = { OnValueChanged = "OnValueChanged" },
    Label = { Right = "Right" },
}

function CreateMinimalSliderFormatter(label)
    return function(value) return tostring(value) end
end

local eventRegistryCallbacks = {}
EventRegistry = {}

function EventRegistry:RegisterCallback(event, callback, owner, ...)
    AssertNoExtraArguments("EventRegistry:RegisterCallback", ...)
    AssertType(event, "string", "callback event")
    AssertType(callback, "function", "callback")
    owner = owner or {}
    local callbacks = eventRegistryCallbacks[event]
    if not callbacks then
        callbacks = {}
        eventRegistryCallbacks[event] = callbacks
    end
    for index, entry in ipairs(callbacks) do
        if entry.owner == owner then
            callbacks[index] = { owner = owner, callback = callback }
            return owner
        end
    end
    callbacks[#callbacks + 1] = { owner = owner, callback = callback }
    return owner
end

function EventRegistry:TriggerEvent(event, ...)
    AssertType(event, "string", "callback event")
    local callbacks = eventRegistryCallbacks[event] or {}
    local snapshot = {}
    for _, entry in ipairs(callbacks) do
        snapshot[#snapshot + 1] = entry
    end
    for _, entry in ipairs(snapshot) do
        entry.callback(entry.owner, ...)
    end
end

function _G._GetEventRegistryCallbackCount(event)
    return #(eventRegistryCallbacks[event] or {})
end

function hooksecurefunc(target, methodName, callback)
    if type(target) ~= "table" or type(methodName) ~= "string" or type(callback) ~= "function" then
        error("only object-method hooksecurefunc is supported by this strict stub", 2)
    end
    if type(target[methodName]) ~= "function" then
        error("cannot hook missing method " .. methodName, 2)
    end

    target._secureHooks = target._secureHooks or {}
    target._secureHooks[methodName] = target._secureHooks[methodName] or {}
    local hooks = target._secureHooks[methodName]

    target._secureOriginals = target._secureOriginals or {}
    if not target._secureOriginals[methodName] then
        local original = target[methodName]
        target._secureOriginals[methodName] = original
        target[methodName] = function(...)
            local packed = table.pack(original(...))
            for _, hook in ipairs(target._secureHooks[methodName]) do
                hook(...)
            end
            return unpackValues(packed, 1, packed.n)
        end
    end

    hooks[#hooks + 1] = callback
end

EditModeManagerFrame = CreateFrame("Frame", "EditModeManagerFrame", UIParent)
EditModeManagerFrame.registeredSystemFrames = { { sentinel = true } }
function EditModeManagerFrame:IsEditModeActive() return self._editModeActive == true end
function EditModeManagerFrame:ShowSystemSelections() self._selectionsShown = true end
function EditModeManagerFrame:HideSystemSelections() self._selectionsShown = false end
function EditModeManagerFrame:SelectSystem(system) self._selectedSystem = system end
function EditModeManagerFrame:ClearSelectedSystem()
    self._selectedSystem = nil
    self._clearSelectionCalls = (self._clearSelectionCalls or 0) + 1
end
function EditModeManagerFrame:EnterEditMode()
    self._editModeActive = true
    self:ShowSystemSelections()
    EventRegistry:TriggerEvent("EditMode.Enter")
end
function EditModeManagerFrame:ExitEditMode()
    self._editModeActive = false
    self:HideSystemSelections()
    EventRegistry:TriggerEvent("EditMode.Exit")
end

_G._stubNow = 0
_G._stubClassToken = "DRUID"
_G._stubClassID = 11
_G._stubSpecializationIndex = 3
_G._stubSpecializationID = 104
_G._stubShapeshiftFormID = 5
_G._stubKnownSpells = {}
_G._stubInCombat = false
_G._stubSecretValue = {}

function GetTime(...)
    AssertNoExtraArguments("GetTime", ...)
    return _G._stubNow
end

function UnitClass(unit, ...)
    AssertNoExtraArguments("UnitClass", ...)
    if unit ~= "player" then error("UnitClass expected player", 2) end
    return "Druid", _G._stubClassToken, _G._stubClassID
end

function GetShapeshiftFormID(...)
    AssertNoExtraArguments("GetShapeshiftFormID", ...)
    return _G._stubShapeshiftFormID
end

function issecretvalue(value, ...)
    AssertNoExtraArguments("issecretvalue", ...)
    return value == _G._stubSecretValue
end

function InCombatLockdown(...)
    AssertNoExtraArguments("InCombatLockdown", ...)
    return _G._stubInCombat
end

C_SpecializationInfo = {
    GetSpecialization = function(...)
        AssertNoExtraArguments("C_SpecializationInfo.GetSpecialization", ...)
        return _G._stubSpecializationIndex
    end,
    GetSpecializationInfo = function(index, ...)
        AssertNoExtraArguments("C_SpecializationInfo.GetSpecializationInfo", ...)
        if type(index) ~= "number" then
            error("GetSpecializationInfo expected numeric index", 2)
        end
        return _G._stubSpecializationID
    end,
}

C_SpellBook = {
    IsSpellKnown = function(spellID, ...)
        AssertNoExtraArguments("C_SpellBook.IsSpellKnown", ...)
        if type(spellID) ~= "number" then
            error("IsSpellKnown expected numeric spell ID", 2)
        end
        local value = rawget(_G._stubKnownSpells, spellID)
        if value == nil then return false end
        return value
    end,
}

SlashCmdList = {}

function EditBox_ClearHighlight(editBox)
    if type(editBox) ~= "table" then
        error("EditBox_ClearHighlight expected an EditBox", 2)
    end
    editBox._highlightCleared = true
end

function _G._ResetWowStubs()
    _G._stubNow = 0
    _G._stubClassToken = "DRUID"
    _G._stubClassID = 11
    _G._stubSpecializationIndex = 3
    _G._stubSpecializationID = 104
    _G._stubShapeshiftFormID = 5
    _G._stubInCombat = false
    for spellID in pairs(_G._stubKnownSpells) do
        _G._stubKnownSpells[spellID] = nil
    end
    EditModeManagerFrame._editModeActive = false
    EditModeManagerFrame._selectionsShown = false
    EditModeManagerFrame._selectedSystem = nil
    for _, frame in ipairs(_G._allFrames) do
        frame._moving = false
        frame._hasFocus = false
    end
end
