# Optional off-client contract check against the exact target client's UI source
# Run from the addon root: powershell -File tests/native_source_check.ps1
$ErrorActionPreference = 'Stop'
$sourceRoot = 'https://raw.githubusercontent.com/Gethe/wow-ui-source/8ea15b61e45c0ed4eba01439c90757f86eb78d34/'
$sourceVersion = (Invoke-WebRequest -UseBasicParsing ($sourceRoot + 'version.txt')).Content.Trim()
if ($sourceVersion -ne '12.1.0.69587') { throw "Unexpected source build: $sourceVersion" }
$magnetismSource = (Invoke-WebRequest -UseBasicParsing ($sourceRoot + 'Interface/AddOns/Blizzard_EditMode/Shared/EditModeUtil.lua')).Content
$systemSource = (Invoke-WebRequest -UseBasicParsing ($sourceRoot + 'Interface/AddOns/Blizzard_EditMode/Shared/EditModeSystemTemplates.lua')).Content
$geometryStart = $systemSource.IndexOf('function EditModeSystemMixin:HasValidSelectionRect()')
$geometryEnd = $systemSource.IndexOf('function EditModeSystemMixin:AddSnappedFrame(')
if ($geometryStart -lt 0 -or $geometryEnd -le $geometryStart) { throw 'Native geometry boundaries changed' }
$geometrySource = $systemSource.Substring($geometryStart, $geometryEnd - $geometryStart)
$movementStart = $systemSource.IndexOf('function EditModeSystemMixin:ProcessMovementKey(')
$movementEnd = $systemSource.IndexOf('function EditModeSystemMixin:PrepareForSave(')
if ($movementStart -lt 0 -or $movementEnd -le $movementStart) { throw 'Native keyboard boundaries changed' }
$movementSource = $systemSource.Substring($movementStart, $movementEnd - $movementStart)

$bootstrap = @'
dofile("tests/wow_stubs.lua")
abs = math.abs
function CalculateDistanceSq(x1, y1, x2, y2)
    return (x2 - x1)^2 + (y2 - y1)^2
end
local objectHook = hooksecurefunc
hooksecurefunc = function(name, callback)
    assert(name == "UpdateUIParentPosition" and type(callback) == "function")
end
'@
$checks = @'
hooksecurefunc = objectHook
local ns = dofile("tests/bootstrap.lua").LoadAddon(_G)
_FireEvent("ADDON_LOADED", "IronfurTracker")
EditModeManagerFrame:EnterEditMode()
EditModeManagerFrame:SetEnableSnap(true)
local bar = ns.Bar.GetFrame()
local selection = ns.EditMode._GetTestState().selection
local magnetism = EditModeMagnetismManager
magnetism:UpdateTopLevelParentPoints()

local function equal(actual, expected, label)
    assert(math.abs(actual - expected) < 0.000001, label .. ": expected " .. expected .. ", got " .. actual)
end
local function place(x, y)
    _RunFrameScript(selection, "OnDragStart")
    _SetFrameCenter(bar, x, y)
    _RunFrameScript(ns.EditModeSnap._GetTestState().previewFrame, "OnUpdate", 0.016)
    _RunFrameScript(selection, "OnDragStop")
    local _, relativeTo = bar:GetPoint()
    assert(relativeTo == UIParent, "snap created a linked anchor")
    return bar:GetCenter()
end

magnetism:RegisterGrid()
magnetism:RegisterGridLine({}, true, 80)
magnetism:RegisterGridLine({}, false, 120)
local x, y = place(1036, 664)
equal(x, 1040, "double grid X")
equal(y, 660, "double grid Y")
magnetism:UnregisterGrid()
x, y = place(146, 300)
equal(x, 152, "screen padding")
equal(y, 300, "unconstrained axis")

local target = CreateFrame("Frame", nil, UIParent)
target:SetSize(100, 40)
_SetFrameCenter(target, 1200, 700)
target.Selection = CreateFrame("Frame", nil, target)
target.Selection:SetAllPoints(target)
for name, method in pairs(EditModeSystemMixin) do target[name] = method end
magnetism:RegisterFrame(target)
x, y = place(995, 700)
equal(x, 996, "native edge padding")
equal(y, 700, "native edge Y")
x, y = place(995, 713)
equal(x, 996, "native corner X")
equal(y, 711, "native corner Y")
x = place(990, 700)
equal(x, 990, "outside native threshold")
UIParent._scale = 0.75
x = place(990, 700)
equal(x, 996, "UI scale affects native threshold")
UIParent._scale = 1
target._scale = 0.8
target:SetSize(100, 50)
_SetFrameCenter(target, 1500, 875)
x, y = place(1005, 700)
equal(x, 1006.4, "scaled target and fractional padding")
equal(y, 700, "scaled target Y")
_SetFrameCenter(target, 400, 400)
equal(bar:GetCenter(), 1006.4, "independent position after target movement")
target:SetScale(1)
target:SetSize(100, 40)
_SetFrameCenter(target, 1200, 700)
target.Selection._rectOverride = { 1138, 674, 124, 52 }
target.Selection:SetPoint("TOPLEFT", target, "TOPLEFT", -12, 6)
target.Selection:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", 12, -6)
x, y = place(983, 700)
equal(x, 984, "expanded selection padding")
equal(y, 700, "expanded selection Y")
assert(magnetism.magneticFrames[bar] == nil, "addon registered a magnetic frame")
assert(ns.EditModeSnap._GetTestState().previewFrame:GetScript("OnUpdate") == nil, "idle preview work")
print("Pinned Blizzard 12.1.0.69587 source: 8 placement scenarios passed (off-client only)")

-- Compare addon movement with the actual native key handlers, intercepting only
-- the native frame operations that would otherwise alter a Blizzard system
local native = setmetatable({}, { __index = EditModeSystemMixin })
function native:CanBeMoved() return true end
function native:ClearFrameSnap() self.snapCleared = true end
function native:StopMovingOrSizing() self.movementStopped = true end
function native:BreakFrameSnap(deltaX, deltaY)
    assert(self.snapCleared and self.movementStopped, "native movement lifecycle changed")
    self.deltaX, self.deltaY = deltaX, deltaY
end
local panel = ns.Settings._GetTestState().panel
for _, shiftKey in ipairs({ false, "LSHIFT", "RSHIFT" }) do
    for _, key in ipairs({ "UP", "DOWN", "LEFT", "RIGHT" }) do
        native:ClearDownKeys()
        native.snapCleared, native.movementStopped = false, false
        if shiftKey then native:OnKeyDown(shiftKey) end
        native:OnKeyDown(key)
        ns.Config.SetPosition(12.25, -34.75)
        ns.Bar.ApplyGeometry()
        _G._stubShiftKeyDown = shiftKey ~= false
        _RunFrameScript(panel, "OnKeyDown", key)
        equal(IronfurTrackerDB.bar.offsetX, 12.25 + native.deltaX, "native arrow X")
        equal(IronfurTrackerDB.bar.offsetY, -34.75 + native.deltaY, "native arrow Y")
        assert(not panel:GetPropagateKeyboardInput(), "movement key was not consumed")
        native:OnKeyUp(key)
        _RunFrameScript(panel, "OnKeyUp", key)
    end
end
print("Pinned Blizzard 12.1.0.69587 source: 12 keyboard comparisons passed (off-client only)")
'@

$luaScript = $bootstrap + "`n" + $magnetismSource + "`n" + $geometrySource + "`n" + $movementSource + "`n" + $checks
$luaScript | & lua -
if ($LASTEXITCODE -ne 0) { throw 'Native-source contract checks failed' }
