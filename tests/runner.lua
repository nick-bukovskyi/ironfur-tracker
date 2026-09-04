-- Strict off-client test runner for Ironfur Tracker.
-- Usage: lua tests/runner.lua

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
            tolerance = tolerance or 0.000001
            if type(actual) ~= "number" or math.abs(actual - expected) > tolerance then
                error(string.format("expected %s within %s, got %s", expected, tolerance, tostring(actual)), 2)
            end
        end,
    }
end

dofile("tests/wow_stubs.lua")

local addonName = "IronfurTracker"
local namespace = {}
local tocMetadata = {}
local addonFiles = {}

for line in io.lines("IronfurTracker.toc") do
    line = line:gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" then
        local key, value = line:match("^##%s*([^:]+):%s*(.-)%s*$")
        if key then
            tocMetadata[key] = value
        elseif not line:match("^#") then
            local path = line:gsub("\\", "/")
            if not path:match("%.lua$") then
                error("test runner does not support TOC entry: " .. path)
            end
            addonFiles[#addonFiles + 1] = path
        end
    end
end

if tocMetadata.SavedVariables ~= "IronfurTrackerDB" then
    error("IronfurTracker.toc must declare exactly ## SavedVariables: IronfurTrackerDB")
end
if #addonFiles == 0 then
    error("IronfurTracker.toc contains no runtime Lua files")
end

IronfurTrackerDB = nil
for _, path in ipairs(addonFiles) do
    local chunk, loadError = loadfile(path)
    if not chunk then
        error("unable to load " .. path .. ": " .. tostring(loadError))
    end
    chunk(addonName, namespace)
end

_G._loadedAddonFiles = addonFiles
_G._tocMetadata = tocMetadata
_G._test_ns = namespace

-- SavedVariables exist before file execution, while ADDON_LOADED is the add-on's
-- initialization boundary. A foreign add-on event must not initialize this one.
_G._FireEvent("ADDON_LOADED", "SomeOtherAddon")
if namespace.Core.IsInitialized() then
    error("Ironfur Tracker initialized for another add-on's ADDON_LOADED event")
end
_G._FireEvent("ADDON_LOADED", addonName)
if not namespace.Core.IsInitialized() then
    error("Ironfur Tracker did not initialize at its ADDON_LOADED boundary")
end

dofile("tests/tracker_spec.lua")
dofile("tests/appearance_spec.lua")
dofile("tests/tick_visibility_spec.lua")
dofile("tests/backdrop_spec.lua")
dofile("tests/font_color_spec.lua")
dofile("tests/highlight_spec.lua")
dofile("tests/eqol_dialog_spec.lua")

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
