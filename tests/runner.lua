-- Strict off-client test runner for Ironfur Tracker.
-- Usage: lua tests/runner.lua [tests/example_spec.lua ...]

local passed = 0
local failed = 0
local failures = {}
local currentSuite = ""

function describe(name, callback)
  currentSuite = name
  print("  " .. name)
  callback()
  currentSuite = ""
end

function it(name, callback)
  local ok, err = pcall(callback)
  if ok then
    passed = passed + 1
    print("    [PASS] " .. name)
  else
    failed = failed + 1
    failures[#failures + 1] = {
      suite = currentSuite,
      test = name,
      error = err,
    }
    print("    [FAIL] " .. name)
    print("           " .. tostring(err))
  end
end

local function IsFiniteNumber(value)
  return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function expect(actual)
  return {
    to_equal = function(expected)
      if actual ~= expected then
        error(string.format("expected %s, got %s", tostring(expected), tostring(actual)), 2)
      end
    end,
    to_be_truthy = function()
      if not actual then
        error("expected a truthy value, got " .. tostring(actual), 2)
      end
    end,
    to_be_falsy = function()
      if actual then
        error("expected a falsy value, got " .. tostring(actual), 2)
      end
    end,
    to_be_nil = function()
      if actual ~= nil then
        error("expected nil, got " .. tostring(actual), 2)
      end
    end,
    to_be_close_to = function(expected, tolerance)
      if tolerance == nil then
        tolerance = 0.000001
      end
      if
        not IsFiniteNumber(actual)
        or not IsFiniteNumber(expected)
        or not IsFiniteNumber(tolerance)
        or tolerance < 0
        or math.abs(actual - expected) > tolerance
      then
        error(string.format("expected %s within %s, got %s", expected, tolerance, tostring(actual)), 2)
      end
    end,
  }
end

describe("Numeric assertions", function()
  it("accepts finite close values and rejects invalid numbers and tolerances", function()
    expect(0.5 + 0.0000005).to_be_close_to(0.5)
    expect(0.5).to_be_close_to(0.5, 0)
    expect(0.625).to_be_close_to(0.5, 0.125)
    for _, sample in ipairs({
      { 0.6, 0.5 },
      { 0 / 0, 0.5 },
      { 0.5, 0 / 0 },
      { math.huge, math.huge },
      { -math.huge, -math.huge },
      { "0.5", 0.5 },
      { 0.5, "0.5" },
      { 0.5, 0.5, -1 },
      { 0.5, 0.5, 0 / 0 },
      { 0.5, 0.5, math.huge },
      { 0.5, 0.5, false },
    }) do
      local ok = pcall(function()
        expect(sample[1]).to_be_close_to(sample[2], sample[3])
      end)
      expect(ok).to_equal(false)
    end
  end)
end)

local Bootstrap = dofile("tests/bootstrap.lua")
local suites = {
  "tests/tracker_spec.lua",
  "tests/appearance_spec.lua",
  "tests/tick_visibility_spec.lua",
  "tests/backdrop_spec.lua",
  "tests/font_color_spec.lua",
  "tests/duration_color_spec.lua",
  "tests/highlight_spec.lua",
  "tests/eqol_dialog_spec.lua",
}
if arg and #arg > 0 then
  suites = arg
end
for _, path in ipairs(suites) do
  local environment = Bootstrap.CreateEnvironment()
  local namespace = Bootstrap.LoadAddon(environment)
  environment._FireEvent("ADDON_LOADED", Bootstrap.addonName)
  if not namespace.Core.IsInitialized() then
    error("Ironfur Tracker did not initialize at its ADDON_LOADED boundary")
  end
  environment.dofile(path)
end

print("")
print(string.rep("-", 50))
local total = passed + failed
if failed == 0 then
  print(string.format("All %d tests passed.", total))
else
  print(string.format("%d passed, %d FAILED out of %d tests.", passed, failed, total))
  for _, failure in ipairs(failures) do
    print(string.format("  FAIL: %s > %s", failure.suite, failure.test))
    print("        " .. tostring(failure.error))
  end
end

os.exit(failed > 0 and 1 or 0)
