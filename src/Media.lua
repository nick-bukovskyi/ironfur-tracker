-- Ironfur Tracker: shared-media discovery and appearance assets
local _, ns = ...

local Media = {}
ns.Media = Media

local DEFAULT_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local sharedMedia = LibStub("LibSharedMedia-3.0")
local onChanged
local registered = false
local fontPreviews = {}
local fontPreviewCount = 0
local fontPreviewFrame, fontPreviewProbe

local function IsTexturePath(path)
    return (type(path) == "string" and path ~= "")
        or (type(path) == "number" and path > 0 and path < math.huge and path == math.floor(path))
end

local function DefaultPath(mediaType)
    if mediaType == "font" then
        local catalog = sharedMedia:HashTable("font")
        local preferred = catalog and catalog[ns.Config.GetDefaultFontFamily()]
        if type(preferred) == "string" and preferred ~= "" then return preferred end
        local path = GameFontHighlightLarge:GetFont()
        return path
    end
    return DEFAULT_TEXTURE
end

local function IsMediaPath(mediaType, path)
    if mediaType == "font" then return type(path) == "string" and path ~= "" end
    return IsTexturePath(path)
end

function Media.Resolve(mediaType, name)
    if name ~= "Default" then
        local catalog = sharedMedia:HashTable(mediaType)
        local path = catalog and catalog[name]
        if IsMediaPath(mediaType, path) then
            return path
        end
    end
    return DefaultPath(mediaType)
end

function Media.GetOptions(mediaType)
    local options = {}
    local catalog = sharedMedia:HashTable(mediaType)
    for name, path in pairs(catalog or {}) do
        if type(name) == "string" and name ~= "" and name ~= "Default" and IsMediaPath(mediaType, path) then
            options[#options + 1] = { name = name, path = path }
        end
    end
    table.sort(options, function(left, right)
        local leftName, rightName = string.lower(left.name), string.lower(right.name)
        if leftName == rightName then
            return left.name < right.name
        end
        return leftName < rightName
    end)
    if mediaType ~= "font" then
        table.insert(options, 1, { name = "Default", path = DefaultPath(mediaType) })
    end
    return options
end

function Media.ApplyFont(target, family, size, style)
    local defaultPath = DefaultPath("font")
    local flags = ""
    if style == "OUTLINE" or style == "SHADOWOUTLINE" then
        flags = "OUTLINE"
    elseif style == "THICKOUTLINE" or style == "SHADOWTHICKOUTLINE" then
        flags = "THICKOUTLINE"
    end
    local path = Media.Resolve("font", family)
    if not target:SetFont(path, size, flags) then
        assert(target:SetFont(defaultPath, size, flags), "Ironfur Tracker could not load the default font")
    end
    if style == "SHADOW" or style == "SHADOWOUTLINE" or style == "SHADOWTHICKOUTLINE" then
        target:SetShadowColor(0, 0, 0, style == "SHADOW" and 1 or 0.6)
        target:SetShadowOffset(1, -1)
    else
        target:SetShadowColor(0, 0, 0, 0)
        target:SetShadowOffset(0, 0)
    end
end

local function UpdateFontPreview(font, name)
    if not fontPreviewProbe then
        fontPreviewFrame = CreateFrame("Frame", nil, UIParent)
        fontPreviewFrame:Hide()
        fontPreviewProbe = fontPreviewFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    end
    -- Only FontString:SetFont reports failure; Font:SetFont has no return value
    Media.ApplyFont(fontPreviewProbe, name, 14, "SHADOW")
    font:SetFont(fontPreviewProbe:GetFont())
    font:SetShadowColor(fontPreviewProbe:GetShadowColor())
    font:SetShadowOffset(fontPreviewProbe:GetShadowOffset())
end

function Media.GetFontPreviewObject(name)
    local font = fontPreviews[name]
    if not font then
        fontPreviewCount = fontPreviewCount + 1
        font = CreateFont("IronfurTrackerFontPreview" .. fontPreviewCount)
        UpdateFontPreview(font, name)
        fontPreviews[name] = font
    end
    return font
end

function Media.ApplyBorder(target, name, size, r, g, b, a)
    if size <= 0 then
        target:SetBackdrop(nil)
        return
    end
    target:SetBackdrop({ edgeFile = Media.Resolve("border", name), edgeSize = size })
    target:SetBackdropBorderColor(r, g, b, a)
end

local function OnMediaRegistered(_, mediaType, name)
    if mediaType == "font" and fontPreviews[name] then
        UpdateFontPreview(fontPreviews[name], name)
    end
    if onChanged and (mediaType == "statusbar" or mediaType == "border" or mediaType == "font") then
        onChanged(mediaType, name)
    end
end

function Media.Initialize(callback)
    onChanged = callback
    if not registered then
        sharedMedia.RegisterCallback(Media, "LibSharedMedia_Registered", OnMediaRegistered)
        registered = true
    end
end
