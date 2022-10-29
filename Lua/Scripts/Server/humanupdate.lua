
MT.UpdateCooldown = 0
MT.UpdateInterval = 120
MT.Deltatime = MT.UpdateInterval/60 -- Time in seconds that transpires between updates

Hook.Add("think", "MT.update", function()
    if MT.HF.GameIsPaused() then return end

    MT.UpdateCooldown = MT.UpdateCooldown-1
    if (MT.UpdateCooldown <= 0) then
        MT.UpdateCooldown = MT.UpdateInterval
        MT.Update()
    end
end)

-- gets run once every two seconds
function MT.Update()

    local updateHumans = {}
    local amountHumans = 0

    -- fetch characters to update
    for key, character in pairs(Character.CharacterList) do
        if (character.IsHuman and not character.IsDead) then
            table.insert(updateHumans, character)
            amountHumans = amountHumans + 1
        end
    end

    -- we spread the characters out over the duration of an update so that the load isnt done all at once
    for key, value in pairs(updateHumans) do
        -- make sure theyre still alive and human
        if (value ~= nil and not value.Removed and value.IsHuman and not value.IsDead) then
            Timer.Wait(function ()
                if (value ~= nil and not value.Removed and value.IsHuman and not value.IsDead) then
                MT.UpdateHuman(value) end
            end, ((key + 1) / amountHumans) * MT.Deltatime * 1000)
        end
    end
end

-- some local functions to avoid code duplicates
local limbtypes = {
    LimbType.Torso,
    LimbType.Head,
    LimbType.LeftArm,
    LimbType.RightArm,
    LimbType.LeftLeg,
    LimbType.RightLeg,
}

-- define all the afflictions and their update functions
MT.Afflictions = {
    
    -- That dastardly spore infection of yours
    spore_infection={max=400,update=function(c,i)
        if c.stats.stasis then return end -- don't do anything if in stasis
        if c.afflictions[i].strength < 1 then return end -- don't do anything if the affliction isn't present

        -- if this line wasnt commented out, it would adjust the affliction strength
        -- of whoever has it by "gain" per second
        -- this is better for performance than the XML method of strengthchange,
        -- because it only happens once every 2 seconds and doesn't require additional networking
        -- of the interval timers

        -- c.afflictions[i].strength = c.afflictions[i].strength + gain * MT.Deltatime
        

        -- this is where we *properly* cause symptoms!
        if NTC ~= nil then
            -- shortness of breath (and all other bad stuff) starts at 100 strength
            if c.afflictions[i].strength > 100 then
                NTC.SetSymptomTrue(c.character,"dyspnea",2)
            
                local respiratoryArrestChance = ((c.afflictions[i].strength-100)/150) * 0.02
                local seizureChance = ((c.afflictions[i].strength-100)/150) * 0.05

                if MT.HF.Chance(respiratoryArrestChance) then
                    NTC.SetSymptomTrue(c.character,"triggersym_respiratoryarrest",1)
                end

                if MT.HF.Chance(seizureChance) then
                    NTC.SetSymptomTrue(c.character,"triggersym_seizure",1)
                end
            end
        else
            -- consider giving some adverse effects in case neurotrauma isnt enabled
        end
    end
    },
    -- co2 poisoning
    co2_poisoning={max=1000,update=function(c,i)
        if c.stats.stasis then return end -- don't do anything if in stasis
        if c.afflictions[i].strength < 1 then return end -- don't do anything if the affliction isn't present

        -- shortness of breath (and all other bad stuff) starts at 50 strength
        if c.afflictions[i].strength > 50 then
            if NTC ~= nil then
                NTC.SetSymptomTrue(c.character,"dyspnea",2)
            end
        
            -- i recommend doing some research on what co2 poisoning does irl
            -- it definitely doesnt suck the oxygen out of your blood (your implementation used to give hypoxemia)
            MT.HF.AddAffliction(c.character,"oxygenlow",MT.HF.Clamp(
                (c.afflictions[i].strength-50)/10,
                0,20
            ))
        end
    end
    }
}
-- define all the limb specific afflictions and their update functions
MT.LimbAfflictions = {
    --[[
    example={update=function(c,limbaff,i,type)
        -- removes itself 1% per second
        limbaff[i].strength = limbaff[i].strength-1*MT.Deltatime
    end
    }
    ]]
}
-- define the stats, states and multipliers
MT.CharStats = {
    stasis={getter=function(c) return NT~=nil and MT.HF.HasAffliction(c.character,"stasis") end}
}


function MT.UpdateHuman(character)

    local charData = {character=character,afflictions={},stats={}}

    -- fetch all the current affliction data
    for identifier,data in pairs(MT.Afflictions) do
        local strength = MT.HF.GetAfflictionStrength(character,identifier,data.default or 0)
        charData.afflictions[identifier] = {prev=strength,strength=strength}
    end
    -- fetch and calculate all the current stats
    for identifier,data in pairs(MT.CharStats) do
        if data.getter ~= nil then charData.stats[identifier] = data.getter(charData)
        else charData.stats[identifier] = data.default or 1 end
    end
    -- update non-limb-specific afflictions
    for identifier,data in pairs(MT.Afflictions) do
        if data.update ~= nil then
        data.update(charData,identifier) end
    end
    

    -- update and apply limb specific stuff
    local function FetchLimbData(type)
        local keystring = tostring(type).."afflictions"
        charData[keystring] = {}
        for identifier,data in pairs(MT.LimbAfflictions) do
            local strength = MT.HF.GetAfflictionStrengthLimb(character,type,identifier,data.default or 0)
            charData[keystring][identifier] = {prev=strength,strength=strength}
        end
    end
    local function UpdateLimb(type)
        local keystring = tostring(type).."afflictions"
        for identifier,data in pairs(MT.LimbAfflictions) do
            if data.update ~= nil then
            data.update(charData,charData[keystring],identifier,type) end
        end
    end
    local function ApplyLimb(type)
        local keystring = tostring(type).."afflictions"
        for identifier,data in pairs(charData[keystring]) do
            local newval = MT.HF.Clamp(
            data.strength,
            MT.LimbAfflictions[identifier].min or 0,
            MT.LimbAfflictions[identifier].max or 100)
            if newval ~= data.prev then
                if MT.LimbAfflictions[identifier].apply == nil then
                    MT.HF.SetAfflictionLimb(character,identifier,type,newval)
                else
                    MT.LimbAfflictions[identifier].apply(charData,identifier,type,newval)
                end
            end
        end
    end

    -- stasis completely halts activity in limbs
    if not charData.stats.stasis then
        for type in limbtypes do
            FetchLimbData(type)
        end
        for type in limbtypes do
            UpdateLimb(type)
        end
        for type in limbtypes do
            ApplyLimb(type)
        end
    end

    -- non-limb-specific late update (useful for things that use stats that are altered by limb specifics)
    for identifier,data in pairs(MT.Afflictions) do
        if data.lateupdate ~= nil then
        data.lateupdate(charData,identifier) end
    end

    -- apply non-limb-specific changes
    for identifier,data in pairs(charData.afflictions) do
        local newval = MT.HF.Clamp(
            data.strength,
            MT.Afflictions[identifier].min or 0,
            MT.Afflictions[identifier].max or 100)
        if newval ~= data.prev then
            if MT.Afflictions[identifier].apply == nil then
                MT.HF.SetAffliction(character,identifier,newval)
            else
                MT.Afflictions[identifier].apply(charData,identifier,newval)
            end
        end
    end
end