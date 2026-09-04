-- Ironfur Tracker: settings schema and SavedVariables ownership
local _, ns = ...

local Config = {}
ns.Config = Config

local CURRENT_SCHEMA_VERSION = 3

local NUMERIC_DEFINITIONS = {
    {
        key = "width",
        section = "Size",
        label = "Bar Width",
        default = 300,
        min = 80,
        max = 1000,
        step = 1,
    },
    {
        key = "height",
        section = "Size",
        label = "Bar Height",
        default = 18,
        min = 8,
        max = 128,
        step = 1,
    },
    {
        key = "tickWidth",
        section = "Tick",
        label = "Width",
        default = 2,
        min = 1,
        max = 20,
        step = 1,
    },
    {
        key = "borderSize",
        section = "Border",
        label = "Border Size",
        default = 1,
        min = 1,
        max = 20,
        step = 1,
    },
    {
        key = "borderOffset",
        section = "Border",
        label = "Border Offset",
        default = 0,
        min = -20,
        max = 20,
        step = 1,
    },
}

local DEFAULT_COLORS = {
    barColor = { r = 0.91, g = 0.38, b = 0.08, a = 0.92 },
    tickColor = { r = 1, g = 0.94, b = 0.72, a = 1 },
    borderColor = { r = 0.01, g = 0.01, b = 0.015, a = 1 },
}
local COLOR_CHANNELS = { "r", "g", "b", "a" }
local TEXTURE_KEYS = { barTexture = true, borderTexture = true }
local DEFAULT_TEXTURE = "Default"

local DEFINITION_BY_KEY = {}
for _, definition in ipairs(NUMERIC_DEFINITIONS) do
    DEFINITION_BY_KEY[definition.key] = definition
end

local database

local function IsFiniteNumber(value)
    return not issecretvalue(value) and type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function IsMediaName(value)
    return not issecretvalue(value) and type(value) == "string"
        and #value > 0 and #value <= 256 and not value:find("%c")
end

local function NormalizeAppearance(bar, reset)
    for key, defaults in pairs(DEFAULT_COLORS) do
        local color = bar[key]
        if reset or issecretvalue(color) or type(color) ~= "table" then
            color = {}
            bar[key] = color
        end
        for _, channel in ipairs(COLOR_CHANNELS) do
            local value = color[channel]
            if not IsFiniteNumber(value) or value < 0 or value > 1 then
                color[channel] = defaults[channel]
            end
        end
    end
    for key in pairs(TEXTURE_KEYS) do
        if reset or not IsMediaName(bar[key]) then
            bar[key] = DEFAULT_TEXTURE
        end
    end
    if reset or issecretvalue(bar.alwaysVisible) or type(bar.alwaysVisible) ~= "boolean" then
        bar.alwaysVisible = true
    end
end

local function IsAlignedToStep(value, definition)
    local steps = (value - definition.min) / definition.step
    return steps == math.floor(steps)
end

local function Clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function ValidatePersistedNumber(value, definition)
    if not IsFiniteNumber(value) or not IsAlignedToStep(value, definition) then
        return definition.default
    end
    return Clamp(value, definition.min, definition.max)
end

local function ValidatePersistedOffset(value)
    if not IsFiniteNumber(value) then
        return 0
    end
    return value
end

function Config.Initialize(savedRoot)
    local root = not issecretvalue(savedRoot) and type(savedRoot) == "table" and savedRoot or {}
    if issecretvalue(root.bar) or type(root.bar) ~= "table" then
        root.bar = {}
    end

    for _, definition in ipairs(NUMERIC_DEFINITIONS) do
        root.bar[definition.key] = ValidatePersistedNumber(root.bar[definition.key], definition)
    end

    root.bar.offsetX = ValidatePersistedOffset(root.bar.offsetX)
    root.bar.offsetY = ValidatePersistedOffset(root.bar.offsetY)

    -- Add schema 2 appearance and schema 3 tick choices while preserving valid fields
    NormalizeAppearance(root.bar)

    if not IsFiniteNumber(root.schemaVersion)
        or root.schemaVersion ~= math.floor(root.schemaVersion)
        or root.schemaVersion <= CURRENT_SCHEMA_VERSION then
        root.schemaVersion = CURRENT_SCHEMA_VERSION
    end

    database = root
    _G.IronfurTrackerDB = root
    return root
end

function Config.GetColor(key)
    if not database or not DEFAULT_COLORS[key] then
        return nil
    end
    local color = database.bar[key]
    return color.r, color.g, color.b, color.a
end

function Config.SetColor(key, r, g, b, a)
    if not database or not DEFAULT_COLORS[key]
        or not IsFiniteNumber(r) or r < 0 or r > 1
        or not IsFiniteNumber(g) or g < 0 or g > 1
        or not IsFiniteNumber(b) or b < 0 or b > 1
        or not IsFiniteNumber(a) or a < 0 or a > 1 then
        return false
    end
    local color = database.bar[key]
    color.r, color.g, color.b, color.a = r, g, b, a
    return true
end

function Config.GetTexture(key)
    return database and TEXTURE_KEYS[key] and database.bar[key] or nil
end

function Config.SetTexture(key, name)
    if not database or not TEXTURE_KEYS[key] or not IsMediaName(name) then
        return false
    end
    database.bar[key] = name
    return true
end

function Config.GetAlwaysVisible()
    return database and database.bar.alwaysVisible or false
end

function Config.SetAlwaysVisible(value)
    if not database or issecretvalue(value) or type(value) ~= "boolean" then
        return false
    end
    database.bar.alwaysVisible = value
    return true
end

function Config.GetNumericDefinitions()
    return NUMERIC_DEFINITIONS
end

function Config.GetNumber(key)
    local definition = DEFINITION_BY_KEY[key]
    if not definition or not database then
        return nil
    end
    return database.bar[key]
end

function Config.CommitNumber(key, rawValue)
    local definition = DEFINITION_BY_KEY[key]
    if not definition or not database then
        return nil, false
    end

    if not IsFiniteNumber(rawValue) or rawValue ~= math.floor(rawValue) then
        return database.bar[key], false
    end

    local value = Clamp(rawValue, definition.min, definition.max)
    if not IsAlignedToStep(value, definition) then
        return database.bar[key], false
    end

    database.bar[key] = value
    return value, true
end

function Config.GetBarValues()
    if not database then
        return nil
    end
    local bar = database.bar
    return bar.width, bar.height, bar.offsetX, bar.offsetY
end

function Config.SetPosition(offsetX, offsetY)
    if not database or not IsFiniteNumber(offsetX) or not IsFiniteNumber(offsetY) then
        return false
    end

    -- Preserve fractional coordinates from scaled Edit Mode targets and grid lines
    database.bar.offsetX = offsetX
    database.bar.offsetY = offsetY
    return true
end

function Config.ResetBar()
    if not database then
        return
    end

    for _, definition in ipairs(NUMERIC_DEFINITIONS) do
        database.bar[definition.key] = definition.default
    end
    database.bar.offsetX = 0
    database.bar.offsetY = 0
    NormalizeAppearance(database.bar, true)
end

function Config.GetSchemaVersion()
    return CURRENT_SCHEMA_VERSION
end
