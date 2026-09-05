-- Ironfur Tracker: settings schema and SavedVariables ownership
local _, ns = ...

local Config = {}
ns.Config = Config

local CURRENT_SCHEMA_VERSION = 11
local MAXIMUM_STACK_COLORS = 20
local DEFAULT_FONT_FAMILY = "Friz Quadrata TT"
local DEFAULT_STACK_COLORS = {
  { r = 0.90, g = 0.16, b = 0.14, a = 1 },
  { r = 1, g = 0.80, b = 0.10, a = 1 },
  { r = 0.20, g = 0.80, b = 0.30, a = 1 },
  { r = 0.10, g = 0.75, b = 0.95, a = 1 },
  { r = 0.65, g = 0.35, b = 1, a = 1 },
}

local NUMERIC_DEFINITIONS = {
  {
    key = "width",
    section = "Bar",
    label = "Bar Width",
    default = 300,
    min = 80,
    max = 1000,
    step = 1,
  },
  {
    key = "height",
    section = "Bar",
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
    key = "fontOffset",
    section = "Font",
    label = "Horizontal",
    default = 0,
    min = -500,
    max = 500,
    step = 1,
  },
  {
    key = "fontOffsetY",
    section = "Font",
    label = "Vertical",
    default = 0,
    min = -500,
    max = 500,
    step = 1,
  },
  {
    key = "fontSize",
    section = "Font",
    label = "Size",
    default = 14,
    min = 8,
    max = 64,
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
  durationHighColor = { r = 0.20, g = 0.80, b = 0.30, a = 1 },
  durationMediumColor = { r = 1, g = 0.80, b = 0.10, a = 1 },
  durationLowColor = { r = 0.90, g = 0.16, b = 0.14, a = 1 },
  backdropColor = { r = 0, g = 0, b = 0, a = 0.8 },
  tickColor = { r = 1, g = 1, b = 1, a = 1 },
  textColor = { r = 1, g = 1, b = 1, a = 1 },
  borderColor = { r = 0, g = 0, b = 0, a = 1 },
}
local COLOR_CHANNELS = { "r", "g", "b", "a" }
local TEXTURE_KEYS = { barTexture = true, backdropTexture = true, borderTexture = true }
local DEFAULT_TEXTURE = "Solid"
local CHOICES = {
  barColorMode = {
    { value = "CLASS", label = "Class color" },
    { value = "SOLID", label = "Solid" },
    { value = "STACKS", label = "By stack count" },
    { value = "DURATION", label = "By time remaining" },
  },
  fontPosition = {
    { value = "CENTER", label = "Center" },
    { value = "LEFT", label = "Left" },
    { value = "RIGHT", label = "Right" },
  },
  fontStyle = {
    { value = "SHADOW", label = "Drop shadow" },
    { value = "NONE", label = "None" },
    { value = "OUTLINE", label = "Outline" },
    { value = "THICKOUTLINE", label = "Thick outline" },
    { value = "SHADOWOUTLINE", label = "Outline and shadow" },
    { value = "SHADOWTHICKOUTLINE", label = "Thick outline and shadow" },
  },
}

local DEFINITION_BY_KEY = {}
for _, definition in ipairs(NUMERIC_DEFINITIONS) do
  DEFINITION_BY_KEY[definition.key] = definition
end

local database

local function IsFiniteNumber(value)
  return not issecretvalue(value) and type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function IsMediaName(value)
  return not issecretvalue(value) and type(value) == "string" and #value > 0 and #value <= 256 and not value:find("%c")
end

local function NormalizeColor(color, defaults)
  if issecretvalue(color) or type(color) ~= "table" then
    color = {}
  end
  for _, channel in ipairs(COLOR_CHANNELS) do
    local value = color[channel]
    if not IsFiniteNumber(value) or value < 0 or value > 1 then
      color[channel] = defaults[channel]
    end
  end
  return color
end

local function IsChoice(key, value)
  if issecretvalue(value) or type(value) ~= "string" then
    return false
  end
  for _, option in ipairs(CHOICES[key] or {}) do
    if option.value == value then
      return true
    end
  end
  return false
end

local function NormalizeStackColors(bar, reset, legacyDense)
  local colors = bar.stackColors
  local normalized = {}
  if reset or issecretvalue(colors) or type(colors) ~= "table" then
    for index, color in ipairs(DEFAULT_STACK_COLORS) do
      normalized[index] = NormalizeColor(nil, color)
    end
  else
    local highest = 0
    for index = 1, MAXIMUM_STACK_COLORS do
      if issecretvalue(colors[index]) or colors[index] ~= nil then
        highest = index
      end
    end
    -- Schema 4 stored every count; later schemas preserve gaps and empty palettes
    for index = 1, highest do
      if legacyDense or issecretvalue(colors[index]) or colors[index] ~= nil then
        normalized[index] = NormalizeColor(colors[index], bar.barColor)
      end
    end
  end
  bar.stackColors = normalized
end

local function NormalizeAppearance(bar, reset, legacyDense)
  for key, defaults in pairs(DEFAULT_COLORS) do
    local color = bar[key]
    if reset then
      color = nil
    end
    bar[key] = NormalizeColor(color, defaults)
  end
  for key in pairs(TEXTURE_KEYS) do
    if reset or not IsMediaName(bar[key]) or bar[key] == "Default" then
      bar[key] = DEFAULT_TEXTURE
    end
  end
  if reset or issecretvalue(bar.alwaysVisible) or type(bar.alwaysVisible) ~= "boolean" then
    bar.alwaysVisible = true
  end
  if reset or issecretvalue(bar.showStacks) or type(bar.showStacks) ~= "boolean" then
    bar.showStacks = true
  end
  if reset or issecretvalue(bar.showTicks) or type(bar.showTicks) ~= "boolean" then
    bar.showTicks = true
  end
  if reset or not IsMediaName(bar.fontFamily) or bar.fontFamily == "Default" then
    bar.fontFamily = DEFAULT_FONT_FAMILY
  end
  for key, options in pairs(CHOICES) do
    if reset or not IsChoice(key, bar[key]) then
      bar[key] = options[1].value
    end
  end

  NormalizeStackColors(bar, reset, legacyDense)
end

local function IsAlignedToStep(value, definition)
  local steps = (value - definition.min) / definition.step
  return steps == math.floor(steps)
end

local function Clamp(value, minimum, maximum)
  if value < minimum then
    return minimum
  end
  if value > maximum then
    return maximum
  end
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

  -- Add appearance fields before advancing the schema, preserving valid choices
  local legacyDense = IsFiniteNumber(root.schemaVersion) and root.schemaVersion < 5
  NormalizeAppearance(root.bar, false, legacyDense)

  if
    not IsFiniteNumber(root.schemaVersion)
    or root.schemaVersion ~= math.floor(root.schemaVersion)
    or root.schemaVersion <= CURRENT_SCHEMA_VERSION
  then
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
  if
    not database
    or not DEFAULT_COLORS[key]
    or not IsFiniteNumber(r)
    or r < 0
    or r > 1
    or not IsFiniteNumber(g)
    or g < 0
    or g > 1
    or not IsFiniteNumber(b)
    or b < 0
    or b > 1
    or not IsFiniteNumber(a)
    or a < 0
    or a > 1
  then
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
  if not database or not TEXTURE_KEYS[key] or not IsMediaName(name) or name == "Default" then
    return false
  end
  database.bar[key] = name
  return true
end

function Config.GetDefaultTexture()
  return DEFAULT_TEXTURE
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

function Config.GetShowStacks()
  return database and database.bar.showStacks or false
end

function Config.SetShowStacks(value)
  if not database or issecretvalue(value) or type(value) ~= "boolean" then
    return false
  end
  database.bar.showStacks = value
  return true
end

function Config.GetShowTicks()
  return database and database.bar.showTicks or false
end

function Config.SetShowTicks(value)
  if not database or issecretvalue(value) or type(value) ~= "boolean" then
    return false
  end
  database.bar.showTicks = value
  return true
end

function Config.GetFontFamily()
  return database and database.bar.fontFamily
end

function Config.GetDefaultFontFamily()
  return DEFAULT_FONT_FAMILY
end

function Config.SetFontFamily(name)
  if not database or not IsMediaName(name) or name == "Default" then
    return false
  end
  database.bar.fontFamily = name
  return true
end

function Config.GetChoiceOptions(key)
  return CHOICES[key]
end

function Config.GetChoice(key)
  return database and CHOICES[key] and database.bar[key] or nil
end

function Config.SetChoice(key, value)
  if not database or not IsChoice(key, value) then
    return false
  end
  database.bar[key] = value
  return true
end

function Config.GetMaximumStackColors()
  return MAXIMUM_STACK_COLORS
end

function Config.GetStackColorCount()
  if not database then
    return 0
  end
  local count = 0
  for index = 1, MAXIMUM_STACK_COLORS do
    if database.bar.stackColors[index] then
      count = count + 1
    end
  end
  return count
end

local function StackColor(index)
  if not database or not IsFiniteNumber(index) or index ~= math.floor(index) or index < 1 or index > MAXIMUM_STACK_COLORS then
    return nil
  end
  return database.bar.stackColors[index]
end

function Config.GetStackThresholds()
  local thresholds = {}
  if database then
    for index = 1, MAXIMUM_STACK_COLORS do
      if database.bar.stackColors[index] then
        thresholds[#thresholds + 1] = index
      end
    end
  end
  return thresholds
end

function Config.HasStackColor(index)
  return StackColor(index) ~= nil
end

function Config.GetStackColor(index)
  local color = StackColor(index)
  if color then
    return color.r, color.g, color.b, color.a
  end
end

function Config.SetStackColor(index, r, g, b, a)
  local color = StackColor(index)
  if
    not color
    or not IsFiniteNumber(r)
    or r < 0
    or r > 1
    or not IsFiniteNumber(g)
    or g < 0
    or g > 1
    or not IsFiniteNumber(b)
    or b < 0
    or b > 1
    or not IsFiniteNumber(a)
    or a < 0
    or a > 1
  then
    return false
  end
  color.r, color.g, color.b, color.a = r, g, b, a
  return true
end

local function InheritedStackColor(index)
  for threshold = math.min(index, MAXIMUM_STACK_COLORS), 1, -1 do
    local color = database.bar.stackColors[threshold]
    if color then
      return color
    end
  end
  return database.bar.barColor
end

function Config.AddStackColor(index)
  if
    not database
    or not IsFiniteNumber(index)
    or index ~= math.floor(index)
    or index < 1
    or index > MAXIMUM_STACK_COLORS
    or StackColor(index)
  then
    return false
  end
  database.bar.stackColors[index] = NormalizeColor(nil, InheritedStackColor(index))
  return index
end

function Config.RemoveStackColor(index)
  if not StackColor(index) then
    return false
  end
  database.bar.stackColors[index] = nil
  return true
end

function Config.GetBarColor(stackCount, progress)
  local mode = Config.GetChoice("barColorMode")
  if mode == "CLASS" then
    local color = C_ClassColor.GetClassColor("DRUID")
    if color then
      local r, g, b = color:GetRGB()
      return r, g, b, 1
    end
  elseif mode == "STACKS" and IsFiniteNumber(stackCount) and stackCount >= 1 and stackCount == math.floor(stackCount) then
    local color = InheritedStackColor(stackCount)
    return color.r, color.g, color.b, color.a
  elseif mode == "DURATION" and IsFiniteNumber(progress) and progress >= 0 and progress <= 1 then
    if progress > 0.5 then
      return Config.GetColor("durationHighColor")
    elseif progress > 0.25 then
      return Config.GetColor("durationMediumColor")
    end
    return Config.GetColor("durationLowColor")
  end
  return Config.GetColor("barColor")
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
