-- Ironfur Tracker: authoritative Ironfur timer state
local _, ns = ...

local Tracker = {}
ns.Tracker = Tracker

local SPELL_IDS = {
    IRONFUR = 192081,
    MANGLE = 33917,
    FRENZIED_REGENERATION = 22842,
    URSOCS_ENDURANCE = 393611,
    GUARDIAN_OF_ELUNE = 155578,
    WILDSHAPE_MASTERY = 441678,
}

local IRONFUR_BASE_DURATION = 7
local URSOCS_ENDURANCE_BONUS = 2
local GUARDIAN_OF_ELUNE_BONUS = 3
local GUARDIAN_OF_ELUNE_WINDOW = 15

local activeTicks = {}
local guardianOfEluneExpiresAt = 0

function Tracker.GetSpellIDs()
    return SPELL_IDS
end

function Tracker.CalculateIronfurDuration(hasUrsocsEndurance, hasGuardianOfElune)
    local duration = IRONFUR_BASE_DURATION
    if hasUrsocsEndurance then
        duration = duration + URSOCS_ENDURANCE_BONUS
    end
    if hasGuardianOfElune then
        duration = duration + GUARDIAN_OF_ELUNE_BONUS
    end
    return duration
end

function Tracker.CalculateTickProgress(expiresAt, duration, now)
    if duration <= 0 then
        return 0
    end

    local progress = (expiresAt - now) / duration
    if progress < 0 then return 0 end
    if progress > 1 then return 1 end
    return progress
end

function Tracker.HandleSpellcast(spellID, now, talents)
    if spellID == SPELL_IDS.MANGLE then
        if talents.guardianOfElune then
            guardianOfEluneExpiresAt = now + GUARDIAN_OF_ELUNE_WINDOW
        else
            guardianOfEluneExpiresAt = 0
        end
        return false
    end

    if spellID == SPELL_IDS.FRENZIED_REGENERATION then
        guardianOfEluneExpiresAt = 0
        return false
    end

    if spellID ~= SPELL_IDS.IRONFUR then
        return false
    end

    local hasGuardianOfElune = talents.guardianOfElune
        and guardianOfEluneExpiresAt > now
    local duration = Tracker.CalculateIronfurDuration(
        talents.ursocsEndurance,
        hasGuardianOfElune
    )

    if hasGuardianOfElune then
        guardianOfEluneExpiresAt = 0
    end

    activeTicks[#activeTicks + 1] = {
        duration = duration,
        expiresAt = now + duration,
    }
    return true
end

function Tracker.Prune(now)
    local changed = false
    for index = #activeTicks, 1, -1 do
        if activeTicks[index].expiresAt <= now then
            table.remove(activeTicks, index)
            changed = true
        end
    end
    return changed
end

function Tracker.Clear()
    for index = #activeTicks, 1, -1 do
        activeTicks[index] = nil
    end
    guardianOfEluneExpiresAt = 0
end

function Tracker.ClearProcState()
    guardianOfEluneExpiresAt = 0
end

function Tracker.GetTicks()
    return activeTicks
end

function Tracker.HasActiveTicks()
    return #activeTicks > 0
end

function Tracker._GetSnapshot()
    local ticks = {}
    for index, tick in ipairs(activeTicks) do
        ticks[index] = {
            duration = tick.duration,
            expiresAt = tick.expiresAt,
        }
    end

    return {
        count = #activeTicks,
        guardianOfEluneExpiresAt = guardianOfEluneExpiresAt,
        ticks = ticks,
    }
end
