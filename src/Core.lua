-- Ironfur Tracker: bootstrap, game boundary, and presentation coordination
local ADDON_NAME, ns = ...

local Core = {}
ns.Core = Core

local DRUID_CLASS_TOKEN = "DRUID"
local GUARDIAN_SPECIALIZATION_ID = 104
local CAT_FORM_ID = 1
local BEAR_FORM_ID = 5

local FORM_BEAR = "BEAR"
local FORM_RETAIN_HIDDEN = "RETAIN_HIDDEN"
local FORM_CLEAR = "CLEAR"
local FORM_UNKNOWN = "UNKNOWN"

local initialized = false
local runtimeEventsRegistered = false
local updateDriver

local playerState = {
    guardian = nil,
    formDisposition = FORM_UNKNOWN,
}

local function IsSecret(value)
    return issecretvalue ~= nil and issecretvalue(value)
end

local function ReadKnownSpell(spellID)
    if not C_SpellBook or not C_SpellBook.IsSpellKnown then
        return nil
    end

    local known = C_SpellBook.IsSpellKnown(spellID)
    if IsSecret(known) or known == nil then
        return nil
    end
    return known and true or false
end

local function ReadGuardianEligibility()
    local _, classToken = UnitClass("player")
    if IsSecret(classToken) or classToken == nil then
        return nil
    end
    if classToken ~= DRUID_CLASS_TOKEN then
        return false
    end

    if not C_SpecializationInfo
        or not C_SpecializationInfo.GetSpecialization
        or not C_SpecializationInfo.GetSpecializationInfo then
        return nil
    end

    local specializationIndex = C_SpecializationInfo.GetSpecialization()
    if IsSecret(specializationIndex) or type(specializationIndex) ~= "number" then
        return nil
    end

    local specializationID = C_SpecializationInfo.GetSpecializationInfo(specializationIndex)
    if IsSecret(specializationID) or type(specializationID) ~= "number" then
        return nil
    end
    return specializationID == GUARDIAN_SPECIALIZATION_ID
end

local function ReadFormDisposition()
    if not GetShapeshiftFormID then
        return FORM_UNKNOWN
    end

    local formID = GetShapeshiftFormID()
    if IsSecret(formID) then
        return FORM_UNKNOWN
    end
    if formID == BEAR_FORM_ID then
        return FORM_BEAR
    end
    if formID == CAT_FORM_ID then
        local hasWildshapeMastery = ReadKnownSpell(ns.Tracker.GetSpellIDs().WILDSHAPE_MASTERY)
        if hasWildshapeMastery == nil then
            return FORM_UNKNOWN
        end
        if hasWildshapeMastery then
            return FORM_RETAIN_HIDDEN
        end
    end
    return FORM_CLEAR
end

local function UpdateDriverState()
    if not updateDriver then
        return
    end
    if ns.Tracker.HasActiveTicks() then
        updateDriver:Show()
    else
        updateDriver:Hide()
    end
end

local function RefreshPresentation(now)
    if not initialized then
        return
    end

    now = now or GetTime()
    ns.Tracker.Prune(now)
    UpdateDriverState()

    if ns.EditMode.IsPreviewActive() then
        ns.Bar.RenderPreview()
    elseif playerState.guardian == true
        and playerState.formDisposition == FORM_BEAR
        and ns.Tracker.HasActiveTicks() then
        ns.Bar.RenderLive(ns.Tracker.GetTicks(), now)
    else
        ns.Bar.Hide()
    end
end

local function UpdatePlayerState()
    local guardian = ReadGuardianEligibility()
    local formDisposition = FORM_UNKNOWN

    if guardian == true then
        formDisposition = ReadFormDisposition()
        if formDisposition == FORM_CLEAR then
            ns.Tracker.Clear()
        end
    elseif guardian == false then
        ns.Tracker.Clear()
    end

    playerState.guardian = guardian
    playerState.formDisposition = formDisposition
    ns.EditMode.SetEligible(guardian == true)
end

local function HandlePlayerSpellcast(spellID)
    if IsSecret(spellID) or type(spellID) ~= "number" then
        return
    end
    if playerState.guardian ~= true then
        return
    end

    local spellIDs = ns.Tracker.GetSpellIDs()
    if spellID ~= spellIDs.IRONFUR
        and spellID ~= spellIDs.MANGLE
        and spellID ~= spellIDs.FRENZIED_REGENERATION then
        return
    end

    local talents
    if spellID == spellIDs.IRONFUR then
        talents = {
            ursocsEndurance = ReadKnownSpell(spellIDs.URSOCS_ENDURANCE) == true,
            guardianOfElune = ReadKnownSpell(spellIDs.GUARDIAN_OF_ELUNE) == true,
        }
    elseif spellID == spellIDs.MANGLE then
        talents = {
            ursocsEndurance = false,
            guardianOfElune = ReadKnownSpell(spellIDs.GUARDIAN_OF_ELUNE) == true,
        }
    else
        talents = {
            ursocsEndurance = false,
            guardianOfElune = false,
        }
    end

    if ns.Tracker.HandleSpellcast(spellID, GetTime(), talents) then
        RefreshPresentation()
    end
end

local function OnUpdate()
    local now = GetTime()
    local changed = ns.Tracker.Prune(now)

    if playerState.guardian == true
        and playerState.formDisposition == FORM_BEAR
        and ns.Tracker.HasActiveTicks()
        and not ns.EditMode.IsPreviewActive() then
        ns.Bar.RenderLive(ns.Tracker.GetTicks(), now)
    elseif changed then
        RefreshPresentation(now)
    end

    if changed then
        UpdateDriverState()
    end
end

local function RegisterRuntimeEvents(eventFrame)
    if runtimeEventsRegistered then
        return
    end

    eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
    eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    eventFrame:RegisterEvent("PLAYER_DEAD")
    eventFrame:RegisterEvent("PLAYER_ALIVE")
    eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
    eventFrame:RegisterEvent("UI_SCALE_CHANGED")
    runtimeEventsRegistered = true
end

local function Initialize(eventFrame)
    if initialized then
        return
    end

    ns.Config.Initialize(_G.IronfurTrackerDB)
    ns.Bar.Initialize()

    updateDriver = CreateFrame("Frame")
    updateDriver:SetScript("OnUpdate", OnUpdate)
    updateDriver:Hide()

    initialized = true
    ns.EditMode.Initialize(RefreshPresentation)
    ns.EditMode.SetCombatLocked(InCombatLockdown and InCombatLockdown() or false)
    RegisterRuntimeEvents(eventFrame)
    UpdatePlayerState()
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if IsSecret(loadedAddon) then
            return
        end
        if loadedAddon == ADDON_NAME then
            Initialize(self)
        elseif loadedAddon == "Blizzard_EditMode" and initialized then
            ns.EditMode.TryAttachManager()
        end
        return
    end

    if not initialized then
        return
    end

    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, _, spellID = ...
        if IsSecret(unitTarget) or unitTarget ~= "player" then
            return
        end
        HandlePlayerSpellcast(spellID)
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unitTarget = ...
        if not IsSecret(unitTarget) and (unitTarget == nil or unitTarget == "player") then
            UpdatePlayerState()
        end
    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
        ns.Tracker.ClearProcState()
        UpdatePlayerState()
    elseif event == "UPDATE_SHAPESHIFT_FORM" then
        UpdatePlayerState()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_DEAD" or event == "PLAYER_ALIVE" then
        ns.Tracker.Clear()
        UpdatePlayerState()
    elseif event == "PLAYER_REGEN_DISABLED" then
        ns.EditMode.SetCombatLocked(true)
    elseif event == "PLAYER_REGEN_ENABLED" then
        ns.EditMode.SetCombatLocked(false)
        UpdatePlayerState()
    elseif event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then
        ns.Bar.ApplyGeometry()
        RefreshPresentation()
    end
end)
eventFrame:RegisterEvent("ADDON_LOADED")

function Core.IsInitialized()
    return initialized
end

function Core._GetPlayerState()
    return {
        guardian = playerState.guardian,
        formDisposition = playerState.formDisposition,
    }
end

-- Test access stays private to the module and creates no public globals.
function Core._GetEventFrame()
    return eventFrame
end

function Core._GetUpdateDriver()
    return updateDriver
end
