-- Ironfur Tracker: bar presentation and geometry
local _, ns = ...

local Bar = {}
ns.Bar = Bar

local BORDER_SIZE = 1
local TICK_WIDTH = 2

local frame
local stackText
local tickLayer
local tickTextures = {}

local function IsUsableNumber(value)
    if issecretvalue and issecretvalue(value) then
        return false
    end
    return type(value) == "number"
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
end

local function Clamp(value, minimum, maximum)
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function HideTickTextures(startIndex)
    for index = startIndex or 1, #tickTextures do
        tickTextures[index]:Hide()
    end
end

local function UpdateTickTextureSizes(height)
    local tickHeight = math.max(1, height - (BORDER_SIZE * 2))
    for _, texture in ipairs(tickTextures) do
        texture:SetSize(TICK_WIDTH, tickHeight)
    end
end

local function AcquireTickTexture(index)
    local texture = tickTextures[index]
    if texture then
        return texture
    end

    texture = tickLayer:CreateTexture(nil, "ARTWORK", nil, 1)
    texture:SetColorTexture(1, 0.94, 0.72, 1)
    local _, height = ns.Config.GetBarValues()
    texture:SetSize(TICK_WIDTH, math.max(1, height - (BORDER_SIZE * 2)))

    if texture.SetSnapToPixelGrid then
        texture:SetSnapToPixelGrid(false)
    end
    if texture.SetTexelSnappingBias then
        texture:SetTexelSnappingBias(0)
    end

    tickTextures[index] = texture
    return texture
end

function Bar.Initialize()
    if frame then
        return frame
    end

    frame = CreateFrame("StatusBar", nil, UIParent)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(10)
    frame:SetMinMaxValues(0, 1)
    frame:SetValue(0)
    frame:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    frame:SetStatusBarColor(0.91, 0.38, 0.08, 0.92)
    frame:SetMovable(false)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(false)
    frame:Hide()

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetColorTexture(0.055, 0.065, 0.08, 0.92)

    tickLayer = CreateFrame("Frame", nil, frame)
    tickLayer:SetAllPoints(frame)
    tickLayer:SetFrameLevel(frame:GetFrameLevel() + 1)

    local textLayer = CreateFrame("Frame", nil, frame)
    textLayer:SetAllPoints(frame)
    textLayer:SetFrameLevel(frame:GetFrameLevel() + 2)

    local borderLayer = CreateFrame("Frame", nil, frame)
    borderLayer:SetAllPoints(frame)
    borderLayer:SetFrameLevel(frame:GetFrameLevel() + 3)

    stackText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    stackText:SetPoint("CENTER", textLayer, "CENTER", 0, 0)
    stackText:SetTextColor(1, 0.96, 0.86, 1)
    stackText:SetText("")

    local function CreateBorder()
        local border = borderLayer:CreateTexture(nil, "OVERLAY", nil, 7)
        border:SetColorTexture(0.01, 0.01, 0.015, 1)
        return border
    end

    local topBorder = CreateBorder()
    topBorder:SetPoint("TOPLEFT", borderLayer, "TOPLEFT", 0, 0)
    topBorder:SetPoint("TOPRIGHT", borderLayer, "TOPRIGHT", 0, 0)
    topBorder:SetHeight(BORDER_SIZE)

    local bottomBorder = CreateBorder()
    bottomBorder:SetPoint("BOTTOMLEFT", borderLayer, "BOTTOMLEFT", 0, 0)
    bottomBorder:SetPoint("BOTTOMRIGHT", borderLayer, "BOTTOMRIGHT", 0, 0)
    bottomBorder:SetHeight(BORDER_SIZE)

    local leftBorder = CreateBorder()
    leftBorder:SetPoint("TOPLEFT", borderLayer, "TOPLEFT", 0, 0)
    leftBorder:SetPoint("BOTTOMLEFT", borderLayer, "BOTTOMLEFT", 0, 0)
    leftBorder:SetWidth(BORDER_SIZE)

    local rightBorder = CreateBorder()
    rightBorder:SetPoint("TOPRIGHT", borderLayer, "TOPRIGHT", 0, 0)
    rightBorder:SetPoint("BOTTOMRIGHT", borderLayer, "BOTTOMRIGHT", 0, 0)
    rightBorder:SetWidth(BORDER_SIZE)

    Bar.ApplyGeometry()
    return frame
end

function Bar.ApplyGeometry()
    if not frame then
        return
    end

    local width, height, offsetX, offsetY = ns.Config.GetBarValues()
    local parentWidth = UIParent:GetWidth()
    local parentHeight = UIParent:GetHeight()

    if IsUsableNumber(parentWidth) and parentWidth > 0 then
        local maxOffsetX = math.max(0, (parentWidth - width) / 2)
        offsetX = Clamp(offsetX, -maxOffsetX, maxOffsetX)
    end
    if IsUsableNumber(parentHeight) and parentHeight > 0 then
        local maxOffsetY = math.max(0, (parentHeight - height) / 2)
        offsetY = Clamp(offsetY, -maxOffsetY, maxOffsetY)
    end

    ns.Config.SetPosition(offsetX, offsetY)
    _, _, offsetX, offsetY = ns.Config.GetBarValues()

    frame:SetSize(width, height)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    UpdateTickTextureSizes(height)
end

function Bar.CaptureCenterOffsets()
    if not frame then
        return nil
    end

    local centerX, centerY = frame:GetCenter()
    local parentCenterX, parentCenterY = UIParent:GetCenter()
    if not IsUsableNumber(centerX) or not IsUsableNumber(centerY)
        or not IsUsableNumber(parentCenterX) or not IsUsableNumber(parentCenterY) then
        local _, _, offsetX, offsetY = ns.Config.GetBarValues()
        Bar.ApplyGeometry()
        return offsetX, offsetY
    end

    ns.Config.SetPosition(centerX - parentCenterX, centerY - parentCenterY)
    Bar.ApplyGeometry()
    local _, _, offsetX, offsetY = ns.Config.GetBarValues()
    return offsetX, offsetY
end

function Bar.RenderLive(ticks, now)
    if not frame or #ticks == 0 then
        Bar.Hide()
        return
    end

    local width = frame:GetWidth()
    local height = frame:GetHeight()
    local tickHeight = math.max(1, height - (BORDER_SIZE * 2))
    local travelWidth = math.max(0, width - (BORDER_SIZE * 2) - TICK_WIDTH)
    local maxProgress = 0

    for index, tick in ipairs(ticks) do
        local progress = ns.Tracker.CalculateTickProgress(tick.expiresAt, tick.duration, now)
        local xOffset = BORDER_SIZE + (TICK_WIDTH / 2) + (progress * travelWidth)
        local texture = AcquireTickTexture(index)
        texture:SetSize(TICK_WIDTH, tickHeight)
        texture:ClearAllPoints()
        texture:SetPoint("CENTER", tickLayer, "LEFT", xOffset, 0)
        texture:Show()

        if progress > maxProgress then
            maxProgress = progress
        end
    end

    HideTickTextures(#ticks + 1)
    frame:SetValue(maxProgress)
    stackText:SetText(#ticks)
    frame:Show()
end

function Bar.RenderPreview()
    if not frame then
        return
    end
    HideTickTextures()
    frame:SetValue(0)
    stackText:SetText("")
    frame:Show()
end

function Bar.Hide()
    if not frame then
        return
    end
    HideTickTextures()
    frame:SetValue(0)
    stackText:SetText("")
    frame:Hide()
end

function Bar.GetFrame()
    return frame
end

function Bar._GetPresentationSnapshot()
    local textures = {}
    for index, texture in ipairs(tickTextures) do
        textures[index] = {
            shown = texture:IsShown(),
            width = texture:GetWidth(),
            height = texture:GetHeight(),
            point = { texture:GetPoint() },
        }
    end

    return {
        stackText = stackText and stackText:GetText() or "",
        tickTextures = textures,
    }
end
