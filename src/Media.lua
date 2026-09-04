-- Ironfur Tracker: shared-media discovery and border presentation
local _, ns = ...

local Media = {}
ns.Media = Media

local DEFAULT_TEXTURE = "Interface\\Buttons\\WHITE8X8"
local sharedMedia = LibStub("LibSharedMedia-3.0")
local onChanged
local registered = false

local function IsTexturePath(path)
    return (type(path) == "string" and path ~= "")
        or (type(path) == "number" and path > 0 and path < math.huge and path == math.floor(path))
end

function Media.Resolve(mediaType, name)
    if name ~= "Default" then
        local catalog = sharedMedia:HashTable(mediaType)
        local path = catalog and catalog[name]
        if IsTexturePath(path) then
            return path
        end
    end
    return DEFAULT_TEXTURE
end

function Media.GetOptions(mediaType)
    local options = {}
    local catalog = sharedMedia:HashTable(mediaType)
    for name, path in pairs(catalog or {}) do
        if type(name) == "string" and name ~= "" and name ~= "Default" and IsTexturePath(path) then
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
    table.insert(options, 1, { name = "Default", path = DEFAULT_TEXTURE })
    return options
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
    if onChanged and (mediaType == "statusbar" or mediaType == "border") then
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
