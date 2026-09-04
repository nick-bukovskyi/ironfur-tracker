-- Ironfur Tracker: bar presentation and geometry
local _, ns = ...

local Bar = {}
ns.Bar = Bar

local TICK_INSET = 1
local MINIMUM_INTERIOR = 6
local PREVIEW_PROGRESS = { 0.25, 0.5, 0.75 }

local frame
local borderLayer
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
    local tickWidth = ns.Config.GetNumber("tickWidth")
    local tickHeight = math.max(1, height - (TICK_INSET * 2))
    for _, texture in ipairs(tickTextures) do
        texture:SetSize(tickWidth, tickHeight)
    end
end

local function AcquireTickTexture(index)
    local texture = tickTextures[index]
    if texture then
        return texture
    end

    texture = tickLayer:CreateTexture(nil, "ARTWORK", nil, 1)
    texture:SetColorTexture(ns.Config.GetColor("tickColor"))

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
    frame:SetMovable(false)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(false)
    frame:Hide()

    local background = frame:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(frame)
    background:SetColorTexture(0.055, 0.065, 0.08, 0.92)

    tickLayer = CreateFrame("Frame", nil, frame)
    tickLayer:SetAllPoints(frame)
    tickLayer:SetFrameLevel(frame:GetFrameLevel() + 2)

    local textLayer = CreateFrame("Frame", nil, frame)
    textLayer:SetAllPoints(frame)
    textLayer:SetFrameLevel(frame:GetFrameLevel() + 3)

    borderLayer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    borderLayer:SetFrameLevel(frame:GetFrameLevel() + 1)
    borderLayer:EnableMouse(false)

    stackText = textLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    stackText:SetPoint("CENTER", textLayer, "CENTER", 0, 0)
    stackText:SetTextColor(1, 0.96, 0.86, 1)
    stackText:SetText("")

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
    UpdateTickTextureSizes(height)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", offsetX, offsetY)
    Bar.ApplyAppearance()
end

function Bar.ApplyAppearance()
    if not frame then
        return
    end

    frame:SetStatusBarTexture(ns.Media.Resolve("statusbar", ns.Config.GetTexture("barTexture")))
    frame:SetStatusBarColor(ns.Config.GetColor("barColor"))

    local r, g, b, a = ns.Config.GetColor("tickColor")
    for _, texture in ipairs(tickTextures) do
        texture:SetColorTexture(r, g, b, a)
    end

    local width, height = frame:GetWidth(), frame:GetHeight()
    local minimumDimension = math.min(width, height)
    local offset = math.max(ns.Config.GetNumber("borderOffset"), (MINIMUM_INTERIOR + 2 - minimumDimension) / 2)
    local size = math.min(ns.Config.GetNumber("borderSize"), (minimumDimension + offset * 2 - MINIMUM_INTERIOR) / 2)
    borderLayer:ClearAllPoints()
    borderLayer:SetPoint("TOPLEFT", frame, "TOPLEFT", -offset, offset)
    borderLayer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", offset, -offset)
    ns.Media.ApplyBorder(borderLayer, ns.Config.GetTexture("borderTexture"), size, ns.Config.GetColor("borderColor"))
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

local function RenderTick(index, progress, tickWidth, height, travelWidth)
    local texture = AcquireTickTexture(index)
    texture:SetSize(tickWidth, math.max(1, height - TICK_INSET * 2))
    texture:ClearAllPoints()
    texture:SetPoint("CENTER", tickLayer, "LEFT", TICK_INSET + tickWidth / 2 + progress * travelWidth, 0)
    texture:Show()
end

function Bar.RenderLive(ticks, now)
    if not frame then
        return
    end

    local height = frame:GetHeight()
    local tickWidth = ns.Config.GetNumber("tickWidth")
    local travelWidth = math.max(0, frame:GetWidth() - (TICK_INSET * 2) - tickWidth)
    local maxProgress = 0

    for index, tick in ipairs(ticks) do
        local progress = ns.Tracker.CalculateTickProgress(tick.expiresAt, tick.duration, now)
        RenderTick(index, progress, tickWidth, height, travelWidth)

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
    local height = frame:GetHeight()
    local tickWidth = ns.Config.GetNumber("tickWidth")
    local travelWidth = math.max(0, frame:GetWidth() - (TICK_INSET * 2) - tickWidth)
    for index, progress in ipairs(PREVIEW_PROGRESS) do
        RenderTick(index, progress, tickWidth, height, travelWidth)
    end
    HideTickTextures(#PREVIEW_PROGRESS + 1)
    frame:SetValue(PREVIEW_PROGRESS[#PREVIEW_PROGRESS])
    stackText:SetText(#PREVIEW_PROGRESS)
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
