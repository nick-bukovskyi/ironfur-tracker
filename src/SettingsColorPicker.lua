-- Ironfur Tracker: native color-picker ownership and reversible previews
local _, ns = ...

local Picker = {}
ns.SettingsColorPicker = Picker

local canEdit, onChanged
local session
local hideHooked = false

local function ReadColor(key, index)
    if index then return ns.Config.GetStackColor(index) end
    return ns.Config.GetColor(key)
end

local function WriteColor(edit, r, g, b, a)
    if edit.index then return ns.Config.SetStackColor(edit.index, r, g, b, a) end
    return ns.Config.SetColor(edit.key, r, g, b, a)
end

function Picker.Cancel()
    local edit = session
    if not edit then return end
    session = nil
    if WriteColor(edit, edit.r, edit.g, edit.b, edit.a) then
        onChanged(edit.key, edit.index)
    end
    if ColorPickerFrame:GetExtraInfo() == edit then ColorPickerFrame:Hide() end
end

function Picker.Open(key, index)
    if not canEdit() then return end
    if index and not ns.Config.HasStackColor(index) then return end
    Picker.Cancel()
    if not hideHooked then
        ColorPickerFrame:HookScript("OnHide", function()
            if session and ColorPickerFrame:GetExtraInfo() == session then session = nil end
        end)
        hideHooked = true
    end
    local r, g, b, a = ReadColor(key, index)
    local edit = { key = key, index = index, r = r, g = g, b = b, a = a, initializing = true }
    session = edit
    local function ApplyPreview()
        if session ~= edit or edit.initializing or not canEdit()
            or ColorPickerFrame:GetExtraInfo() ~= edit then return end
        local nr, ng, nb = ColorPickerFrame:GetColorRGB()
        if WriteColor(edit, nr, ng, nb, ColorPickerFrame:GetColorAlpha()) then
            onChanged(key, index)
        end
    end
    ColorPickerFrame:SetupColorPickerAndShow({
        r = r, g = g, b = b, opacity = a, hasOpacity = true, extraInfo = edit,
        swatchFunc = ApplyPreview,
        opacityFunc = ApplyPreview,
        cancelFunc = function()
            if session == edit and ColorPickerFrame:GetExtraInfo() == edit then Picker.Cancel() end
        end,
    })
    edit.initializing = false
end

function Picker.Initialize(editCheck, colorChanged)
    canEdit, onChanged = editCheck, colorChanged
end

function Picker._GetSession()
    return session
end
