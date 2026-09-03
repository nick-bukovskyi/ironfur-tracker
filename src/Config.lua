-- Ironfur Tracker: settings schema and SavedVariables ownership
local _, ns = ...

local Config = {}
ns.Config = Config

local CURRENT_SCHEMA_VERSION = 1

local NUMERIC_DEFINITIONS = {
    {
        key = "width",
        label = "Bar Width",
        default = 300,
        min = 80,
        max = 1000,
        step = 1,
    },
    {
        key = "height",
        label = "Bar Height",
        default = 18,
        min = 8,
        max = 128,
        step = 1,
    },
}

local DEFINITION_BY_KEY = {}
for _, definition in ipairs(NUMERIC_DEFINITIONS) do
    DEFINITION_BY_KEY[definition.key] = definition
end

local database

local function IsFiniteNumber(value)
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
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
    local root = type(savedRoot) == "table" and savedRoot or {}
    if type(root.bar) ~= "table" then
        root.bar = {}
    end

    for _, definition in ipairs(NUMERIC_DEFINITIONS) do
        root.bar[definition.key] = ValidatePersistedNumber(root.bar[definition.key], definition)
    end

    root.bar.offsetX = ValidatePersistedOffset(root.bar.offsetX)
    root.bar.offsetY = ValidatePersistedOffset(root.bar.offsetY)

    if not IsFiniteNumber(root.schemaVersion)
        or root.schemaVersion ~= math.floor(root.schemaVersion)
        or root.schemaVersion <= CURRENT_SCHEMA_VERSION then
        root.schemaVersion = CURRENT_SCHEMA_VERSION
    end

    database = root
    _G.IronfurTrackerDB = root
    return root
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
end

function Config.GetSchemaVersion()
    return CURRENT_SCHEMA_VERSION
end
