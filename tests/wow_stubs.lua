-- Strict World of Warcraft API stubs for Ironfur Tracker.
-- Only contracts exercised by the add-on are represented here.

local unpackValues = table.unpack or unpack
strmatch = string.match

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

-- Desktop compatibility for the bundled libraries' documented WoW globals
function getfenv(level, ...)
    AssertNoExtraArguments("getfenv", ...)
    if level ~= 0 then error("only getfenv(0) is exercised by the bundled libraries", 2) end
    return _G
end

bit = {
    band = function(left, right, ...)
        AssertNoExtraArguments("bit.band", ...)
        AssertType(left, "number", "left bit mask")
        AssertType(right, "number", "right bit mask")
        local result, place = 0, 1
        while left > 0 and right > 0 do
            if left % 2 == 1 and right % 2 == 1 then result = result + place end
            left, right, place = math.floor(left / 2), math.floor(right / 2), place * 2
        end
        return result
    end,
}

function GetLocale(...)
    AssertNoExtraArguments("GetLocale", ...)
    return "enUS"
end

function securecallfunction(callback, ...)
    AssertType(callback, "function", "securecallfunction callback")
    -- Preserve callback dispatch, but make callback errors fail the desktop test
    return callback(...)
end

_G._stubKnownFileAssets = {}
C_UIFileAsset = {
    IsKnownFile = function(asset, ...)
        AssertNoExtraArguments("C_UIFileAsset.IsKnownFile", ...)
        if type(asset) ~= "string" and type(asset) ~= "number" then
            error("IsKnownFile requires a file asset", 2)
        end
        local known = _G._stubKnownFileAssets[asset]
        if known == nil then error("file asset has no test fixture: " .. tostring(asset), 2) end
        return known
    end,
}

-- The public class-color result is RGB; ColorMixin:GetRGBA does not invent alpha
local druidClassColor = { r = 1, g = 0.49, b = 0.04 }
function druidClassColor:GetRGB(...)
    AssertNoExtraArguments("ColorMixin:GetRGB", ...)
    return self.r, self.g, self.b
end
function druidClassColor:GetRGBA(...)
    AssertNoExtraArguments("ColorMixin:GetRGBA", ...)
    return self.r, self.g, self.b, self.a
end
_G._stubClassColorAvailable = true
C_ClassColor = {
    GetClassColor = function(className, ...)
        AssertNoExtraArguments("C_ClassColor.GetClassColor", ...)
        if className ~= "DRUID" then error("unexpected class-color fixture", 2) end
        if _G._stubClassColorAvailable then return druidClassColor end
    end,
}

local TextureMixin = {}
TextureMixin.__index = TextureMixin

function TextureMixin:SetAllPoints(...) self._allPoints = { ... } end
function TextureMixin:SetColorTexture(...) self._color = { ... } end
function TextureMixin:SetTexture(asset, ...)
    AssertNoExtraArguments("Texture:SetTexture", ...)
    if asset ~= nil and type(asset) ~= "string" and type(asset) ~= "number" then
        error("SetTexture requires a file asset or nil", 2)
    end
    self._texture = asset
    return asset ~= nil
end
function TextureMixin:SetVertexColor(r, g, b, a, ...)
    AssertNoExtraArguments("Texture:SetVertexColor", ...)
    AssertType(r, "number", "red")
    AssertType(g, "number", "green")
    AssertType(b, "number", "blue")
    if a ~= nil then AssertType(a, "number", "alpha") end
    self._vertexColor = { r, g, b, a or 1 }
end
function TextureMixin:SetSize(width, height) self._width = width; self._height = height end
function TextureMixin:SetWidth(width) self._width = width end
function TextureMixin:SetHeight(height) self._height = height end
function TextureMixin:GetWidth() return self._width or 0 end
function TextureMixin:GetHeight() return self._height or 0 end
function TextureMixin:SetPoint(...) self._point = { ... } end
function TextureMixin:SetTexCoord(left, right, top, bottom, ...)
    AssertNoExtraArguments("Texture:SetTexCoord", ...)
    AssertType(left, "number", "left texture coordinate")
    AssertType(right, "number", "right texture coordinate")
    AssertType(top, "number", "top texture coordinate")
    AssertType(bottom, "number", "bottom texture coordinate")
    self._texCoord = { left, right, top, bottom }
end
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
function FontStringMixin:ClearAllPoints(...) AssertNoExtraArguments("FontString:ClearAllPoints", ...); self._point = nil end
function FontStringMixin:GetPoint(...)
    AssertNoExtraArguments("FontString:GetPoint", ...)
    if self._point then return unpackValues(self._point) end
end
function FontStringMixin:SetTextColor(...) self._color = { ... } end
function FontStringMixin:SetText(value) self._text = tostring(value or "") end
function FontStringMixin:GetText() return self._text or "" end
function FontStringMixin:SetWidth(width) self._width = width end
function FontStringMixin:SetHeight(height) self._height = height end
function FontStringMixin:SetJustifyH(justify) self._justifyH = justify end
function FontStringMixin:Show() self._shown = true end
function FontStringMixin:Hide() self._shown = false end
function FontStringMixin:IsShown() return self._shown == true end
function FontStringMixin:SetShown(shown, ...)
    AssertNoExtraArguments("FontString:SetShown", ...)
    AssertType(shown, "boolean", "font string shown")
    self._shown = shown
end

_G._stubFontSetResults = {}
for _, name in ipairs({ "2002.TTF", "2002B.TTF", "ARHei.TTF", "ARKai_C.TTF", "ARKai_T.TTF",
    "ARIALN.TTF", "FRIZQT__.TTF", "K_Pagetext.TTF", "MORPHEUS_CYR.TTF", "NIM_____.ttf", "SKURRI_CYR.TTF" }) do
    _G._stubFontSetResults["Fonts\\" .. name] = true
end

function FontStringMixin:GetFont(...)
    AssertNoExtraArguments("GetFont", ...)
    if self._fontObject and not self._fontFile then return self._fontObject:GetFont() end
    return self._fontFile, self._fontHeight or 0, self._fontFlags or ""
end
function FontStringMixin:SetFont(asset, height, flags, ...)
    AssertNoExtraArguments("SetFont", ...)
    if self._menuOwned then error("Blizzard menu compositor forbids FontString:SetFont", 2) end
    if type(asset) ~= "string" and type(asset) ~= "number" then error("SetFont requires a font asset", 2) end
    if type(height) ~= "number" or height <= 0 or height ~= height or height == math.huge then
        error("SetFont requires a valid font height", 2)
    end
    if flags ~= nil and flags ~= "" and flags ~= "OUTLINE" and flags ~= "THICKOUTLINE" then
        error("unexpected font flags: " .. tostring(flags), 2)
    end
    local success = _G._stubFontSetResults[asset]
    if success == nil then error("font asset has no test fixture: " .. tostring(asset), 2) end
    if success then self._fontFile, self._fontHeight, self._fontFlags = asset, height, flags or "" end
    return success
end
function FontStringMixin:GetShadowColor(...)
    AssertNoExtraArguments("GetShadowColor", ...)
    if self._fontObject and not self._shadowColor then return self._fontObject:GetShadowColor() end
    return unpackValues(self._shadowColor or { 0, 0, 0, 1 })
end
function FontStringMixin:SetShadowColor(r, g, b, a, ...)
    AssertNoExtraArguments("SetShadowColor", ...)
    AssertType(r, "number", "shadow red")
    AssertType(g, "number", "shadow green")
    AssertType(b, "number", "shadow blue")
    if a ~= nil then AssertType(a, "number", "shadow alpha") end
    self._shadowColor = { r, g, b, a or 1 }
end
function FontStringMixin:GetShadowOffset(...)
    AssertNoExtraArguments("GetShadowOffset", ...)
    if self._fontObject and not self._shadowOffset then return self._fontObject:GetShadowOffset() end
    return unpackValues(self._shadowOffset or { 0, 0 })
end
function FontStringMixin:SetShadowOffset(x, y, ...)
    AssertNoExtraArguments("SetShadowOffset", ...)
    AssertType(x, "number", "shadow offset x")
    AssertType(y, "number", "shadow offset y")
    self._shadowOffset = { x, y }
end

-- SimpleFont:SetFont has no return value, unlike SimpleFontString:SetFont
local FontObjectMixin = {
    GetFont = FontStringMixin.GetFont,
    GetShadowColor = FontStringMixin.GetShadowColor,
    SetShadowColor = FontStringMixin.SetShadowColor,
    GetShadowOffset = FontStringMixin.GetShadowOffset,
    SetShadowOffset = FontStringMixin.SetShadowOffset,
}
FontObjectMixin.__index = FontObjectMixin
function FontObjectMixin:SetFont(asset, height, flags, ...)
    AssertType(asset, "string", "font object file name")
    AssertType(flags, "string", "font object flags")
    FontStringMixin.SetFont(self, asset, height, flags, ...)
end
function CreateFont(name, ...)
    AssertNoExtraArguments("CreateFont", ...)
    AssertType(name, "string", "font object name")
    if name == "" or _G[name] ~= nil then error("font object name must be new and nonempty", 2) end
    local font = setmetatable({ _name = name }, FontObjectMixin)
    _G[name] = font
    return font
end
function FontStringMixin:SetFontObject(font, ...)
    AssertNoExtraArguments("FontString:SetFontObject", ...)
    if type(font) == "string" then font = _G[font] end
    if getmetatable(font) ~= FontObjectMixin then error("SetFontObject requires a known Font object", 2) end
    self._fontObject = font
    self._fontFile, self._fontHeight, self._fontFlags = nil, nil, nil
    self._shadowColor, self._shadowOffset = nil, nil
end

GameFontHighlightLarge = setmetatable({
    _fontFile = "Fonts\\FRIZQT__.TTF", _fontHeight = 16, _fontFlags = "",
    _shadowColor = { 0, 0, 0, 1 }, _shadowOffset = { 1, -1 },
}, FontObjectMixin)

local FrameMixin = {}
FrameMixin.__index = FrameMixin

function FrameMixin:GetParent() return self._parent end
function FrameMixin:GetName() return self._name end
function FrameMixin:SetSize(width, height) self._width = width; self._height = height end
function FrameMixin:SetWidth(width) self._width = width end
function FrameMixin:SetHeight(height) self._height = height end
function FrameMixin:GetWidth()
    local target = self._allPoints and self._allPoints[1]
    return target and target:GetWidth() or self._width or 0
end
function FrameMixin:GetHeight()
    local target = self._allPoints and self._allPoints[1]
    return target and target:GetHeight() or self._height or 0
end
function FrameMixin:GetSize() return self:GetWidth(), self:GetHeight() end
function FrameMixin:GetScale() return self._scale or 1 end
function FrameMixin:SetScale(value) self._scale = value end
function FrameMixin:SetAlpha(alpha, ...)
    AssertNoExtraArguments("SetAlpha", ...)
    AssertType(alpha, "number", "alpha")
    self._alpha = alpha
end
function FrameMixin:GetAlpha(...)
    AssertNoExtraArguments("GetAlpha", ...)
    return self._alpha or 1
end
function FrameMixin:GetEffectiveScale()
    if self._effectiveScale ~= nil then return self._effectiveScale end
    local parentScale = self._parent and self._parent:GetEffectiveScale() or 1
    return parentScale * self:GetScale()
end
function FrameMixin:IsForbidden()
    if self._forbidden ~= nil then return self._forbidden end
    return false
end

function FrameMixin:SetPoint(...)
    local values = { ... }
    self._points = self._points or {}
    local replaced = false
    for index, existing in ipairs(self._points) do
        if existing[1] == values[1] then
            self._points[index] = values
            replaced = true
            break
        end
    end
    if not replaced then self._points[#self._points + 1] = values end
    self._point = self._points[1]
    self._pointHistory = self._pointHistory or {}
    self._pointHistory[#self._pointHistory + 1] = values
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

function FrameMixin:GetPoint(index)
    local point = self._points and self._points[index or 1]
    if not point then return nil end
    return unpackValues(point)
end
function FrameMixin:GetNumPoints() return #(self._points or {}) end

function FrameMixin:ClearAllPoints()
    self._point = nil
    self._points = nil
    self._allPoints = nil
    self._centerX = nil
    self._centerY = nil
end

function FrameMixin:SetAllPoints(target)
    self._allPoints = { target }
    self._points = {
        { "TOPLEFT", target, "TOPLEFT", 0, 0 },
        { "BOTTOMRIGHT", target, "BOTTOMRIGHT", 0, 0 },
    }
    self._point = self._points[1]
end
function FrameMixin:GetCenter()
    local target = self._allPoints and self._allPoints[1]
    if target then return target:GetCenter() end
    if self._centerX ~= nil and self._centerY ~= nil then
        return self._centerX, self._centerY
    end
    return self:GetWidth() / 2, self:GetHeight() / 2
end
function FrameMixin:GetRect()
    if self._invalidRect then return nil end
    if self._rectOverride then return unpackValues(self._rectOverride) end
    local centerX, centerY = self:GetCenter()
    local width, height = self:GetSize()
    if type(centerX) ~= "number" or type(centerY) ~= "number" then
        return centerX, centerY, width, height
    end
    return centerX - width / 2, centerY - height / 2, width, height
end

function FrameMixin:SetFrameStrata(strata) self._frameStrata = strata end
function FrameMixin:SetFrameLevel(level) self._frameLevel = level end
function FrameMixin:GetFrameLevel() return self._frameLevel or 0 end
function FrameMixin:SetMinMaxValues(minimum, maximum) self._min = minimum; self._max = maximum end
function FrameMixin:SetStatusBarTexture(texture) self._statusBarTexture = texture end
function FrameMixin:SetStatusBarColor(...) self._statusBarColor = { ... } end

function FrameMixin:SetBackdrop(info, ...)
    AssertNoExtraArguments("SetBackdrop", ...)
    if self._template ~= "BackdropTemplate" then
        error("SetBackdrop requires BackdropTemplate", 2)
    end
    if info ~= nil then
        AssertType(info, "table", "backdrop info")
        for key in pairs(info) do
            if key ~= "edgeFile" and key ~= "edgeSize" and key ~= "bgFile"
                and key ~= "tile" and key ~= "tileSize" and key ~= "insets" then
                error("unexpected backdrop field: " .. tostring(key), 2)
            end
        end
        if info.edgeFile ~= nil and type(info.edgeFile) ~= "string" and type(info.edgeFile) ~= "number" then
            error("backdrop edgeFile requires a file asset", 2)
        end
        if info.edgeSize ~= nil then AssertType(info.edgeSize, "number", "backdrop edge size") end
    end
    self._backdrop = info
end

function FrameMixin:SetBackdropBorderColor(r, g, b, a, ...)
    AssertNoExtraArguments("SetBackdropBorderColor", ...)
    if self._template ~= "BackdropTemplate" then
        error("SetBackdropBorderColor requires BackdropTemplate", 2)
    end
    AssertType(r, "number", "red")
    AssertType(g, "number", "green")
    AssertType(b, "number", "blue")
    if a ~= nil then AssertType(a, "number", "alpha") end
    if self._backdrop then self._borderColor = { r, g, b, a or 1 } end
end

function FrameMixin:SetChecked(checked, ...)
    AssertNoExtraArguments("SetChecked", ...)
    if self._type ~= "CheckButton" then error("SetChecked requires a CheckButton", 2) end
    if checked ~= nil then AssertType(checked, "boolean", "checked") end
    self._checked = checked or false
end

function FrameMixin:GetChecked(...)
    AssertNoExtraArguments("GetChecked", ...)
    if self._type ~= "CheckButton" then error("GetChecked requires a CheckButton", 2) end
    return self._checked or false
end

function FrameMixin:EnableMouseWheel(enabled, ...)
    AssertNoExtraArguments("EnableMouseWheel", ...)
    AssertType(enabled, "boolean", "mouse wheel enabled")
    self._mouseWheelEnabled = enabled
end

function FrameMixin:SetScrollChild(child, ...)
    AssertNoExtraArguments("SetScrollChild", ...)
    if self._type ~= "ScrollFrame" then error("SetScrollChild requires a ScrollFrame", 2) end
    AssertType(child, "table", "scroll child")
    if not child._type then error("scroll child must be a frame", 2) end
    child._parent = self
    self._scrollChild = child
end

function FrameMixin:GetVerticalScroll(...)
    AssertNoExtraArguments("GetVerticalScroll", ...)
    if self._type ~= "ScrollFrame" then error("GetVerticalScroll requires a ScrollFrame", 2) end
    return self._verticalScroll or 0
end

function FrameMixin:GetVerticalScrollRange(...)
    AssertNoExtraArguments("GetVerticalScrollRange", ...)
    if self._type ~= "ScrollFrame" then error("GetVerticalScrollRange requires a ScrollFrame", 2) end
    return math.max(0, (self._scrollChild and self._scrollChild:GetHeight() or 0) - self:GetHeight())
end

function FrameMixin:SetVerticalScroll(offset, ...)
    AssertNoExtraArguments("SetVerticalScroll", ...)
    if self._type ~= "ScrollFrame" then error("SetVerticalScroll requires a ScrollFrame", 2) end
    AssertType(offset, "number", "scroll offset")
    self._verticalScroll = offset
    local callback = self:GetScript("OnVerticalScroll")
    if callback then callback(self, offset) end
end

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

function FrameMixin:SetShown(shown, ...)
    AssertNoExtraArguments("SetShown", ...)
    AssertType(shown, "boolean", "shown")
    if shown then self:Show() else self:Hide() end
end

function FrameMixin:IsShown() return self._shown == true end
function FrameMixin:IsVisible()
    if self._visibleOverride ~= nil then return self._visibleOverride end
    return self:IsShown()
end

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

function FrameMixin:CreateLine(name, layer, template, ...)
    AssertNoExtraArguments("CreateLine", ...)
    if name ~= nil then AssertType(name, "string", "line name") end
    if layer ~= nil then AssertType(layer, "string", "line layer") end
    if template ~= "MagnetismPreviewLineTemplate" then
        error("unexpected line template: " .. tostring(template), 2)
    end
    local line = setmetatable({
        _parent = self,
        _template = template,
        _layer = layer,
        _shown = true,
    }, TextureMixin)
    function line:Setup(info, anchor, ...)
        AssertNoExtraArguments("MagnetismPreviewLine:Setup", ...)
        AssertType(info, "table", "magnetic frame info")
        AssertType(anchor, "string", "preview anchor")
        self._setupInfo = info
        self._setupAnchor = anchor
        self._setupCount = (self._setupCount or 0) + 1
        self._lineParent = UIParent
        self:Show()
    end
    self._lines = self._lines or {}
    self._lines[#self._lines + 1] = line
    return line
end

function FrameMixin:CreateFontString(name, layer, template)
    if name ~= nil then AssertType(name, "string", "font string name") end
    if layer ~= nil then AssertType(layer, "string", "font string layer") end
    local allowedFontTemplates = {
        GameFontHighlight = true,
        GameFontHighlightLarge = true,
        GameFontHighlightMedium = true,
        GameFontHighlightSmall = true,
        GameFontNormalMed3 = true,
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
    if template == "GameFontHighlightLarge" then
        fontString._fontFile, fontString._fontHeight, fontString._fontFlags = GameFontHighlightLarge:GetFont()
        fontString._shadowColor = { GameFontHighlightLarge:GetShadowColor() }
        fontString._shadowOffset = { GameFontHighlightLarge:GetShadowOffset() }
    end
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

function FrameMixin:SetText(value)
    local text = tostring(value or "")
    local changed = self._text ~= text
    self._text = text
    if changed and self._type == "EditBox" then
        local callback = self:GetScript("OnTextChanged")
        if callback then callback(self, false) end
    end
end
function FrameMixin:SetEnabled(enabled, ...)
    AssertNoExtraArguments("SetEnabled", ...)
    if self._type ~= "Button" then error("SetEnabled fixture requires a Button", 2) end
    AssertType(enabled, "boolean", "button enabled")
    self._enabled = enabled
end
function FrameMixin:GetText() return self._text or "" end
function FrameMixin:SetNumber(value) self:SetText(value) end
function FrameMixin:GetNumber() return tonumber(self:GetText()) or 0 end
function FrameMixin:SetAutoFocus(value) self._autoFocus = value and true or false end
function FrameMixin:SetNumeric(value) self._numeric = value and true or false end
function FrameMixin:SetMaxLetters(value) self._maxLetters = value end
function FrameMixin:SetJustifyH(value) self._justifyH = value end
function FrameMixin:SetNormalTexture(asset, ...)
    AssertNoExtraArguments("SetNormalTexture", ...)
    if self._type ~= "Button" then error("SetNormalTexture requires a Button", 2) end
    if type(asset) ~= "string" and type(asset) ~= "number" then
        error("SetNormalTexture requires a file asset", 2)
    end
    self._normalTexture = self._normalTexture or setmetatable({
        _parent = self, _shown = true,
    }, TextureMixin)
    self._normalTexture:SetTexture(asset)
end
function FrameMixin:GetNormalTexture(...)
    AssertNoExtraArguments("GetNormalTexture", ...)
    if self._type ~= "Button" then error("GetNormalTexture requires a Button", 2) end
    return self._normalTexture
end
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
    CheckButton = true,
    DropdownButton = true,
    EditBox = true,
    EventFrame = true,
    Frame = true,
    ScrollFrame = true,
    StatusBar = true,
}

local allowedTemplates = {
    BackdropTemplate = true,
    DialogBorderTranslucentTemplate = true,
    EditModeSystemSelectionTemplate = true,
    InputBoxTemplate = true,
    MinimalSliderWithSteppersTemplate = true,
    MinimalScrollBar = true,
    UICheckButtonTemplate = true,
    UIPanelButtonTemplate = true,
    UIPanelCloseButton = true,
    WowStyle1DropdownTemplate = true,
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

local function RequireDropdown(frame)
    if frame._type ~= "DropdownButton" or frame._template ~= "WowStyle1DropdownTemplate" then
        error("menu method requires a WowStyle1DropdownTemplate DropdownButton", 3)
    end
end

function FrameMixin:OverrideText(text, ...)
    AssertNoExtraArguments("OverrideText", ...)
    RequireDropdown(self)
    AssertType(text, "string", "dropdown text")
    self._overrideText = text
    self._text = text
end

function FrameMixin:SetupMenu(generator, ...)
    AssertNoExtraArguments("SetupMenu", ...)
    RequireDropdown(self)
    AssertType(generator, "function", "menu generator")
    self._menuGenerator = generator
    if self:IsShown() then self:GenerateMenu() end
end

function FrameMixin:GenerateMenu(...)
    AssertNoExtraArguments("GenerateMenu", ...)
    RequireDropdown(self)
    if not self._menuGenerator then return end
    local root = { entries = {} }
    function root:SetScrollMode(maximumHeight, ...)
        AssertNoExtraArguments("menu SetScrollMode", ...)
        AssertType(maximumHeight, "number", "maximum menu height")
        self.maximumHeight = maximumHeight
    end
    function root:CreateRadio(text, isSelected, onSelect, data, ...)
        AssertNoExtraArguments("CreateRadio", ...)
        AssertType(text, "string", "radio label")
        AssertType(isSelected, "function", "radio selection predicate")
        AssertType(onSelect, "function", "radio responder")
        local entry = { text = text, isSelected = isSelected, onSelect = onSelect, data = data, initializers = {} }
        function entry:AddInitializer(initializer, ...)
            AssertNoExtraArguments("AddInitializer", ...)
            AssertType(initializer, "function", "menu initializer")
            self.initializers[#self.initializers + 1] = initializer
        end
        self.entries[#self.entries + 1] = entry
        return entry
    end
    self._menuGenerator(self, root)
    self._menuDescription = root
    self._text = ""
    for _, entry in ipairs(root.entries) do
        if entry.isSelected(entry.data) then self._text = entry.text end
    end
    self._text = self._overrideText or self._text
end

function FrameMixin:CloseMenu(...)
    AssertNoExtraArguments("CloseMenu", ...)
    RequireDropdown(self)
    self._menuOpen = false
    for _, row in ipairs(self._menuRows or {}) do row:Hide() end
end

function _G._OpenDropdown(dropdown)
    RequireDropdown(dropdown)
    dropdown:GenerateMenu()
    dropdown._menuOpen = true
    dropdown._menuRows = dropdown._menuRows or {}
    for index, entry in ipairs(dropdown._menuDescription.entries) do
        local row = dropdown._menuRows[index]
        if not row then
            row = CreateFrame("Button", nil, dropdown)
            row.fontString = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.fontString._menuOwned = true
            function row:AttachTexture(...)
                AssertNoExtraArguments("menu AttachTexture", ...)
                self._previewTexture = self._previewTexture or self:CreateTexture()
                return self._previewTexture
            end
            function row:AttachTemplate(template, ...)
                AssertNoExtraArguments("menu AttachTemplate", ...)
                if template ~= "BackdropTemplate" then error("unexpected menu attachment template", 2) end
                self._previewBorder = self._previewBorder or CreateFrame("Frame", nil, self, template)
                return self._previewBorder
            end
            dropdown._menuRows[index] = row
        end
        row:Show()
        row.fontString:SetText(entry.text)
        for _, initializer in ipairs(entry.initializers) do
            local width, height = initializer(row, entry, dropdown._menuDescription)
            if width ~= nil then row:SetSize(width, height) end
        end
    end
    return dropdown._menuDescription
end

function _G._SelectDropdown(dropdown, name)
    RequireDropdown(dropdown)
    local root = _G._OpenDropdown(dropdown)
    for _, entry in ipairs(root.entries) do
        if entry.text == name then
            entry.onSelect(entry.data)
            dropdown:GenerateMenu()
            dropdown:CloseMenu()
            return
        end
    end
    error("dropdown has no entry named " .. tostring(name), 2)
end

-- Selected observable ScrollUtil behavior; this cannot prove native widget layout
ScrollUtil = {}
function ScrollUtil.InitScrollFrameWithScrollBar(scrollFrame, scrollBar, ...)
    AssertNoExtraArguments("ScrollUtil.InitScrollFrameWithScrollBar", ...)
    if scrollFrame._type ~= "ScrollFrame" or scrollBar._template ~= "MinimalScrollBar" then
        error("unexpected ScrollUtil frame or scrollbar", 2)
    end
    scrollFrame._scrollBar = scrollBar
    scrollFrame.panExtent = 30
    scrollFrame:SetScript("OnVerticalScroll", function(frame, offset)
        local range = frame:GetVerticalScrollRange()
        scrollBar._scrollPercentage = range > 0 and offset / range or 0
    end)
    scrollFrame:SetScript("OnScrollRangeChanged", function(frame, _, range)
        local height = frame:GetHeight()
        scrollBar._visibleExtentPercentage = height > 0 and height / (range + height) or 0
    end)
    scrollFrame:SetScript("OnMouseWheel", function(frame, value)
        frame:SetVerticalScroll(math.max(0, math.min(frame:GetVerticalScrollRange(), frame:GetVerticalScroll() - value * frame.panExtent)))
    end)
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

GameTooltip = CreateFrame("Frame", "GameTooltip", UIParent)
GameTooltip:Hide()
function GameTooltip:SetOwner(owner, anchor, ...)
    AssertNoExtraArguments("GameTooltip:SetOwner", ...)
    if type(owner) ~= "table" or not owner._type then error("tooltip owner must be a frame", 2) end
    if anchor ~= "ANCHOR_RIGHT" then error("unexpected tooltip anchor: " .. tostring(anchor), 2) end
    self._owner, self._ownerAnchor = owner, anchor
end
function GameTooltip:GetOwner(...)
    AssertNoExtraArguments("GameTooltip:GetOwner", ...)
    return self._owner
end
function GameTooltip:SetText(text, ...)
    AssertNoExtraArguments("GameTooltip:SetText", ...)
    AssertType(text, "string", "tooltip text")
    self._text = text
end

ColorPickerFrame = CreateFrame("Frame", "ColorPickerFrame", UIParent)
ColorPickerFrame:Hide()
function ColorPickerFrame:SetupColorPickerAndShow(info, ...)
    AssertNoExtraArguments("SetupColorPickerAndShow", ...)
    AssertType(info, "table", "color picker info")
    local fields = { r = true, g = true, b = true, opacity = true, hasOpacity = true,
        swatchFunc = true, opacityFunc = true, cancelFunc = true, extraInfo = true }
    for key in pairs(info) do
        if not fields[key] then error("unexpected color picker field: " .. tostring(key), 2) end
    end
    for _, channel in ipairs({ "r", "g", "b" }) do AssertType(info[channel], "number", channel) end
    AssertType(info.swatchFunc, "function", "color picker swatch callback")
    if info.hasOpacity ~= nil then AssertType(info.hasOpacity, "boolean", "color picker opacity toggle") end
    if info.opacity ~= nil then AssertType(info.opacity, "number", "color picker opacity") end
    if info.opacityFunc ~= nil then AssertType(info.opacityFunc, "function", "color picker opacity callback") end
    if info.cancelFunc ~= nil then AssertType(info.cancelFunc, "function", "color picker cancel callback") end
    self._info = info
    self.previousValues = { r = info.r, g = info.g, b = info.b, a = info.opacity }
    self._r, self._g, self._b, self._a = info.r, info.g, info.b, info.opacity
    self.extraInfo = info.extraInfo
    self.swatchFunc, self.opacityFunc, self.cancelFunc = info.swatchFunc, info.opacityFunc, info.cancelFunc
    self.swatchFunc()
    if self.opacityFunc then self.opacityFunc() end
    self:Show()
end
function ColorPickerFrame:GetColorRGB(...)
    AssertNoExtraArguments("GetColorRGB", ...)
    return self._r, self._g, self._b
end
function ColorPickerFrame:GetColorAlpha(...)
    AssertNoExtraArguments("GetColorAlpha", ...)
    return self._a
end
function ColorPickerFrame:GetExtraInfo(...)
    AssertNoExtraArguments("GetExtraInfo", ...)
    return self.extraInfo
end
function _G._SetPickerColor(r, g, b, a)
    if not ColorPickerFrame:IsShown() then error("color picker is not shown", 2) end
    ColorPickerFrame._r, ColorPickerFrame._g, ColorPickerFrame._b, ColorPickerFrame._a = r, g, b, a
    ColorPickerFrame.swatchFunc()
    if ColorPickerFrame.opacityFunc then ColorPickerFrame.opacityFunc() end
end
function _G._CancelPicker()
    if ColorPickerFrame.cancelFunc then ColorPickerFrame.cancelFunc(ColorPickerFrame.previousValues) end
    ColorPickerFrame:Hide()
end
function _G._AcceptPicker()
    ColorPickerFrame.swatchFunc()
    if ColorPickerFrame.opacityFunc then ColorPickerFrame.opacityFunc() end
    ColorPickerFrame:Hide()
end

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
function EditModeManagerFrame:IsSnapEnabled() return self._snapEnabled == true end
function EditModeManagerFrame:SetEnableSnap(value) self._snapEnabled = value and true or false end
function EditModeManagerFrame:RegisterSystemFrame()
    error("third-party native Edit Mode registration is outside this contract", 2)
end
function EditModeManagerFrame:SetSnapPreviewFrame()
    error("the add-on must not own Blizzard's snap preview frame", 2)
end

-- These selected build-matched geometry formulas are the native contracts used
-- by the local mover adapter. The native choice/search algorithm is not copied.
EditModeSystemMixin = {}

function EditModeSystemMixin:GetScaledSelectionSides()
    local left, bottom, width, height = self.Selection:GetRect()
    local scale = self:GetScale()
    return left * scale, (left + width) * scale, bottom * scale, (bottom + height) * scale
end
function EditModeSystemMixin:GetScaledSelectionCenter()
    local x, y = self.Selection:GetCenter()
    local scale = self:GetScale()
    return x * scale, y * scale
end
function EditModeSystemMixin:GetScaledCenter()
    local x, y = self:GetCenter()
    local scale = self:GetScale()
    return x * scale, y * scale
end
function EditModeSystemMixin:GetLeftOffset()
    return select(4, self.Selection:GetPoint(1)) - 2
end
function EditModeSystemMixin:GetRightOffset()
    return select(4, self.Selection:GetPoint(2)) + 2
end
function EditModeSystemMixin:GetTopOffset()
    return select(5, self.Selection:GetPoint(1)) + 2
end
function EditModeSystemMixin:GetBottomOffset()
    return select(5, self.Selection:GetPoint(2)) - 2
end
function EditModeSystemMixin:GetSelectionOffset(point, forYOffset)
    local offset
    if point == "LEFT" then offset = self:GetLeftOffset()
    elseif point == "RIGHT" then offset = self:GetRightOffset()
    elseif point == "TOP" then offset = self:GetTopOffset()
    elseif point == "BOTTOM" then offset = self:GetBottomOffset()
    elseif point == "TOPLEFT" then offset = forYOffset and self:GetTopOffset() or self:GetLeftOffset()
    elseif point == "TOPRIGHT" then offset = forYOffset and self:GetTopOffset() or self:GetRightOffset()
    elseif point == "BOTTOMLEFT" then offset = forYOffset and self:GetBottomOffset() or self:GetLeftOffset()
    elseif point == "BOTTOMRIGHT" then offset = forYOffset and self:GetBottomOffset() or self:GetRightOffset()
    else
        local selectionX, selectionY = self.Selection:GetCenter()
        local centerX, centerY = self:GetCenter()
        offset = forYOffset and selectionY - centerY or selectionX - centerX
    end
    return offset * self:GetScale()
end
function EditModeSystemMixin:GetCombinedSelectionOffset(info, forYOffset)
    local offset = -self:GetSelectionOffset(info.point, forYOffset) + info.offset
    if info.frame.Selection then
        offset = offset + info.frame:GetSelectionOffset(info.relativePoint, forYOffset)
    end
    return offset / self:GetScale()
end
function EditModeSystemMixin:GetCombinedCenterOffset(frame)
    local centerX, centerY = self:GetScaledCenter()
    local targetX, targetY
    if frame.GetScaledCenter then
        targetX, targetY = frame:GetScaledCenter()
    else
        targetX, targetY = frame:GetCenter()
    end
    local scale = self:GetScale()
    return (centerX - targetX) / scale, (centerY - targetY) / scale
end
function EditModeSystemMixin:GetSnapOffsets(info)
    local offsetX, offsetY
    if info.isCornerSnap then
        offsetX = self:GetCombinedSelectionOffset(info, false)
        offsetY = self:GetCombinedSelectionOffset(info, true)
    else
        offsetX, offsetY = self:GetCombinedCenterOffset(info.frame)
        if info.isHorizontal then
            offsetX = self:GetCombinedSelectionOffset(info, false)
        else
            offsetY = self:GetCombinedSelectionOffset(info, true)
        end
    end
    return offsetX, offsetY
end
function EditModeSystemMixin:IsToTheLeftOfFrame(frame)
    local _, right = self:GetScaledSelectionSides()
    local left = frame:GetScaledSelectionSides()
    return right < left
end
function EditModeSystemMixin:IsAboveFrame(frame)
    local _, _, bottom = self:GetScaledSelectionSides()
    local _, _, _, top = frame:GetScaledSelectionSides()
    return bottom > top
end

MagnetismPreviewLineMixin = {}
EditModeMagnetismManager = { magneticFrames = {} }
_G._stubMagneticFrameInfos = nil
_G._stubMagneticQueryCount = 0

function EditModeMagnetismManager:GetMagneticFrameInfos(mover, ...)
    AssertNoExtraArguments("GetMagneticFrameInfos", ...)
    AssertType(mover, "table", "magnetic mover")
    if type(mover.GetFrameMagneticEligibility) ~= "function" then
        error("magnetic mover must expose candidate eligibility", 2)
    end
    _G._stubMagneticQueryCount = _G._stubMagneticQueryCount + 1
    if not _G._stubMagneticFrameInfos then return nil end

    -- Choice is controlled by the fixture. Only exercise the native contract's
    -- candidate eligibility gate before delivering those predetermined results.
    local accepted = {}
    for _, info in ipairs(_G._stubMagneticFrameInfos) do
        if info.frame == UIParent then
            accepted[#accepted + 1] = info
        else
            local horizontal, vertical = mover:GetFrameMagneticEligibility(info.frame)
            if (info.isCornerSnap and (horizontal or vertical))
                or (info.isHorizontal and horizontal)
                or (not info.isHorizontal and vertical) then
                accepted[#accepted + 1] = info
            end
        end
    end
    if #accepted == 0 then return nil end
    return accepted
end

function EditModeMagnetismManager:GetPreviewLineAnchors(info, ...)
    AssertNoExtraArguments("GetPreviewLineAnchors", ...)
    AssertType(info, "table", "magnetic frame info")
    local relativePoint = info.relativePoint
    AssertType(relativePoint, "string", "relative point")
    if relativePoint:find("CENTER", 1, true) then
        return { info.isHorizontal and "CenterVertical" or "CenterHorizontal" }
    end
    local anchors = {}
    for _, item in ipairs({ { "TOP", "Top" }, { "BOTTOM", "Bottom" }, { "LEFT", "Left" }, { "RIGHT", "Right" } }) do
        if relativePoint:find(item[1], 1, true) then anchors[#anchors + 1] = item[2] end
    end
    return anchors
end

function EditModeMagnetismManager:ApplyMagnetism()
    error("native ApplyMagnetism would create a forbidden persistent anchor", 2)
end
function EditModeMagnetismManager:RegisterFrame()
    error("the add-on must not register a native magnetic frame", 2)
end
function EditModeMagnetismManager:UnregisterFrame()
    error("the add-on must not mutate native magnetic registration", 2)
end

function _G._RefreshStubMagnetismBounds()
    local manager = EditModeMagnetismManager
    local left, bottom, width, height = UIParent:GetRect()
    manager.topLevelParentCenterX, manager.topLevelParentCenterY = UIParent:GetCenter()
    manager.topLevelParentLeft = left
    manager.topLevelParentRight = left + width
    manager.topLevelParentBottom = bottom
    manager.topLevelParentTop = bottom + height
    manager.topLevelParentWidth = width
    manager.topLevelParentHeight = height
end

function _G._CreateMagneticFrame(centerX, centerY, width, height, scale)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(width, height)
    frame:SetScale(scale or 1)
    _G._SetFrameCenter(frame, centerX, centerY)
    frame.Selection = CreateFrame("Frame", nil, frame)
    frame.Selection:SetAllPoints(frame)
    for key, method in pairs(EditModeSystemMixin) do frame[key] = method end
    return frame
end

_G._stubDefaultEditModeManager = EditModeManagerFrame
_G._stubDefaultMagnetismManager = EditModeMagnetismManager
_G._stubDefaultEditModeSystemMixin = EditModeSystemMixin
_G._stubDefaultPreviewLineMixin = MagnetismPreviewLineMixin
_G._RefreshStubMagnetismBounds()

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
    EditModeManagerFrame = _G._stubDefaultEditModeManager
    EditModeMagnetismManager = _G._stubDefaultMagnetismManager
    EditModeSystemMixin = _G._stubDefaultEditModeSystemMixin
    MagnetismPreviewLineMixin = _G._stubDefaultPreviewLineMixin
    _G._stubNow = 0
    _G._stubClassToken = "DRUID"
    _G._stubClassColorAvailable = true
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
    EditModeManagerFrame._snapEnabled = false
    _G._stubMagneticFrameInfos = nil
    _G._stubMagneticQueryCount = 0
    for _, frame in ipairs(_G._allFrames) do
        frame._moving = false
        frame._hasFocus = false
        frame._forbidden = nil
        frame._visibleOverride = nil
        frame._invalidRect = nil
        frame._rectOverride = nil
        frame._scale = 1
        frame._effectiveScale = nil
        frame._pointHistory = {}
    end
    UIParent:SetSize(1920, 1080)
    _G._SetFrameCenter(UIParent, 960, 540)
    _G._RefreshStubMagnetismBounds()
end
