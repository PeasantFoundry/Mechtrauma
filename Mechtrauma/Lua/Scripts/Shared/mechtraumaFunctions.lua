MT.F = {}
CentralComputer = {}
CentralComputer.online = true

LuaUserData.RegisterTypeBarotrauma("Items.Components.SimpleGenerator")

-- Hull:Condition ratio for oxygen is 2333:1 and a player breaths 700 oxygen per second. 
-- human breaths 700 oxygen/second and that requires to 0.3 

-- DIVINGSUIT: updates deterioration and extended pressure protection. 
function MT.F.divingSuit(item)
    -- only update if equipped
    if MT.HF.ItemIsWornInOuterClothesSlot(item) then
        -- DETERIORATION: 
        -- execute if divingsuit is equipped and deterioration or extended pressure protection is enabled.
        if (MT.Config.divingSuitServiceLife > 0.0 or MT.Config.divingSuitEPP > 1.0) then
            local itemDepth = MT.HF.GetItemDepth(item)
            local pressureProtectionMultiplier = itemDepth / item.ParentInventory.Owner.PressureProtection -- quotient of depth and pressure protection
            local pressureDamagePD = 0 -- per delta        
            local deteriorationDamagePD = 0 -- per delta
            -- calculate deterioration damage if deterioration is enabled
            if MT.Config.divingSuitServiceLife > 0.0 then deteriorationDamagePD = (item.MaxCondition / (MT.Config.divingSuitServiceLife * 60) * MT.Deltatime) end

            -- EXTENDED PRESSURE PROTECTION: Protects up to 2x max pressure but damages the diving suit.
            if pressureProtectionMultiplier <= 2 and item.Condition > 1 then --if you're past 2x pressure you deserve what you get.   
                item.ParentInventory.Owner.AddAbilityFlag(AbilityFlags.ImmuneToPressure) -- guardian angel on             
            else
                item.ParentInventory.Owner.RemoveAbilityFlag(AbilityFlags.ImmuneToPressure) -- guardian angel off
            end
            -- damage the suit if exceeding pressure rating while outside the sub or in a leathal pressure hull.
            if pressureProtectionMultiplier > 1 and (item.ParentInventory.Owner.AnimController.CurrentHull == null or item.ParentInventory.Owner.AnimController.CurrentHull.LethalPressure >= 80.0) then
                pressureDamagePD = pressureProtectionMultiplier^4 -- make pressure damage exponential                            
            end
            -- low poressure (<= 2500 protection) diving suits receive 50% deterioration dammage per delta
            if item.ParentInventory.Owner.PressureProtection <= 2500 then deteriorationDamagePD = deteriorationDamagePD * 0.5 end
            -- apply deterioration and pressure damage to divingsuit for this update. 
            item.Condition = item.Condition - (deteriorationDamagePD + pressureDamagePD)
        end
    end
end

-- fuse logic
function MT.F.fuseBox(item)        
    local fuseWaterDamage = 0
    local fuseOvervoltDamage = 0
    local fuseDeteriorationDamage = 0    
    local voltage = item.GetComponentString("PowerTransfer").Voltage
    
    
    --if MT.itemCache[item].counter < 0 then MT.itemCache[item].counter = 10 end
    --print("FUSE COUNTER: ", MT.itemCache[item].counter)
    --MT.itemCache[item].counter = MT.itemCache[item].counter - 1
    
    --CHECK: is there a fuse?
    if item.OwnInventory.GetItemAt(0) ~= nil and item.OwnInventory.GetItemAt(0).ConditionPercentage > 1 then
        
        --fuse present logic
        item.GetComponentString("Repairable").DeteriorationSpeed = 0.0 -- disable fuseBfox deterioration
        item.GetComponentString("PowerTransfer").CanBeOverloaded = false -- disable overvoltage 
        item.GetComponentString("PowerTransfer").FireProbability = 0.1 -- reduce fire probability 
        -- enable RelayComponent if present
        if item.GetComponentString("RelayComponent") then item.GetComponentString("RelayComponent").SetState(true, false) end

        -- DEBUG PRINTING:
        if voltage > 1.7 then print(item.name, "voltage: ", voltage) end
        
        -- set water, overvoltage, and deterioration damage amounts
        if item.InWater then fuseWaterDamage = 1.0 end
        
        if item.GetComponentString("PowerTransfer").PowerLoad ~= 0 then fuseDeteriorationDamage = MT.Config.fusBoxDeterioration * 0.1 end  --detiorate the fuse at 10% of MT.Config.fusBoxDeterioration 

        if voltage > 1.7 then
            -- use the item counter to track how long the item has been overvolted
            MT.itemCache[item].counter = MT.itemCache[item].counter + 1
            -- only apply overvoltage damage if overvoltage has lasted for more than 1 update
            if MT.itemCache[item].counter > 1 then
                fuseOvervoltDamage = MT.Config.fuseOvervoltDamage * voltage-- this needs to scale with load overvoltage on 10,000kw should do more damage than on 100kw     
            end         
        else
            MT.itemCache[item].counter = 0
        end
        -- apply water, deterioration, and overvoltage damage to the fuse
        item.OwnInventory.GetItemAt(0).Condition = item.OwnInventory.GetItemAt(0).Condition - fuseWaterDamage - fuseOvervoltDamage - fuseDeteriorationDamage
                
    else
        
        -- fuseBox: if the fuse is missing enable deterioration, overvoltage, and fires.         
        item.GetComponentString("Repairable").DeteriorationSpeed = MT.Config.fusBoxDeterioration --enable deterioration        
        item.GetComponentString("PowerTransfer").CanBeOverloaded = true -- enable overvoltage
        item.GetComponentString("PowerTransfer").FireProbability = 0.9 -- increase fire probability 
        -- disable RelayComponent if present
        if item.GetComponentString("RelayComponent") then item.GetComponentString("RelayComponent").SetState(false, false) end  
        -- DEBUG PRINTING:
        -- print("ITEM: ", item.name)
        -- print("deterioration speed: ", item.name, item.GetComponentString("Repairable").DeteriorationSpeed)
        -- print("condition percentage: ", item.ConditionPercentage) 
    end
end

-- CENTRAL COMPUTER: Ships computer
--MT.tagKeys.centralComputer = function(item)
function MT.F.centralComputer(item)
    if item.ConditionPercentage > 1 and item.GetComponentString("Powered").Voltage > 0.5 then
        CentralComputer.online  = true
        item.GetComponentString("RelayComponent").SetState(true, false)        
        --print("Central computer online.")
    else
        CentralComputer.online  = false
        item.GetComponentString("RelayComponent").SetState(false, false)
        --print("Central computer offline.")
    end
end

function MT.F.keyIgnition(item)

end 


-- CENTRAL COMPUTER: Ships computer
function MT.F.centralComputerNeeded(item)
    print("found a: ", item.name)
    if CentralComputer.online  then
        if item.GetComponentString("Steering") ~= nil then item.GetComponentString("Steering").CanBeSelected = true end
        if item.GetComponentString("Sonar") ~= nil then item.GetComponentString("Sonar").CanBeSelected = true end
        if item.GetComponentString("CustomInterface") ~= nil then item.GetComponentString("CustomInterface").CanBeSelected = true end
        if item.GetComponentString("MiniMap") ~= nil then item.GetComponentString("MiniMap").CanBeSelected = true end
        if item.GetComponentString("Fabricator") ~= nil then item.GetComponentString("Fabricator").CanBeSelected = true end     
    elseif not CentralComputerOnline then        
        if item.GetComponentString("Steering") ~= nil then item.GetComponentString("Steering").CanBeSelected = false end
        if item.GetComponentString("Sonar") ~= nil then item.GetComponentString("Sonar").CanBeSelected = false end
        if item.GetComponentString("CustomInterface") ~= nil then item.GetComponentString("CustomInterface").CanBeSelected = false end
        if item.GetComponentString("MiniMap") ~= nil then item.GetComponentString("MiniMap").CanBeSelected = false end
        if item.GetComponentString("Fabricator") ~= nil then item.GetComponentString("Fabricator").CanBeSelected = false end
    end
end

-- STEAM Boiler: the beloved steam boiler...
function MT.F.steamBoiler(item)
    local index = 0

    -- OPERATION: if operational (condition) and operating (powered)
    if item.ConditionPercentage > 1 and item.GetComponentString("Powered").Voltage > 0.5 then
        local curculatorItems = {}
        local curculatorSlots = 2 -- temporarily hardcoded        
        local circulatorCount = 0
        local pressureDamage = 1 * MT.Deltatime

        --loop through the Boiler inventory        
        while(index < item.OwnInventory.Capacity) do
            if item.OwnInventory.GetItemAt(index) ~= nil then                
                local containedItem = item.OwnInventory.GetItemAt(index)               
                if containedItem.HasTag("circulatorPump") and containedItem.Condition > 0 then
                    table.insert(curculatorItems, containedItem)         
                    circulatorCount = circulatorCount + 1                    
                end
            end
            index = index + 1
        end

        -- deteriorate Circulator Pumps
        MT.HF.subFromListAll(MT.Config.circulatorDPS * MT.Deltatime, curculatorItems) -- apply deterioration to each filters independently
        -- counteract pressureDamage
        pressureDamage = pressureDamage - pressureDamage / curculatorSlots * #curculatorItems
        -- apply pressureDamage
        item.Condition = item.Condition - pressureDamage

        -- check for leaks
        if item.ConditionPercentage <= 50 then
            print(item.CurrentHull.WaterVolume)
            item.CurrentHull.WaterVolume = item.CurrentHull.WaterVolume + 3000
        end
    else
      -- nothing to see here
    end
end

-- STEAM TURBINE: the beloved steam turbine...
function MT.F.steamTurbine(item)

    -- <!-- DISABLE: Cannot transmit power without turbine blades, right? -->
    -- Would it be possible to have max power output be per turbine? So that one failing meaning -25% output not -100%

    --<!-- Deteriorate the bearings -->
    -- -0.05 deterioration per 2 second when powered
    local index = 0
    -- if operational (condition) and operating (powered)
    if item.ConditionPercentage > 1 and item.GetComponentString("Powered").Voltage > 0.5 then
        local bearingItems = {}
        local bladeCount = 0
        local bearingSlots = 4 -- temporarily hardcoded
        local frictionDamage = MT.Config.frictionBaseDPS * bearingSlots * MT.Deltatime

        --loop through the Turbine inventory        
        while(index < item.OwnInventory.Capacity) do
            if item.OwnInventory.GetItemAt(index) ~= nil then
                -- DEBUG PRINTING
                -- print(item.OwnInventory.GetItemAt(index),item.OwnInventory.GetItemAt(index).HiddenInGame)
                local containedItem = item.OwnInventory.GetItemAt(index)
                if containedItem.Prefab.Identifier.Value == "turbine_blade" then
                    bladeCount = bladeCount + 1
                    -- damage the blades if the condition is below 25
                    if item.ConditionPercentage < 25 then containedItem.Condition = containedItem.Condition -10.0 end -- make this exponential damage
                    containedItem.HiddenInGame = true -- cannot remove while operational
                end
                if containedItem.Prefab.Identifier.Value == "bearing" and containedItem.Condition > 0 then
                    table.insert(bearingItems, containedItem)
                
                    -- disable hot swapping parts
                    item.OwnInventory.GetItemAt(index).HiddenInGame = true
                    if SERVER then MT.HF.SyncToClient("HiddenInGame", item.OwnInventory.GetItemAt(index)) end
                end

                -- disable hot swapping parts
                item.OwnInventory.GetItemAt(index).HiddenInGame = true 
                if SERVER then MT.HF.SyncToClient("HiddenInGame", item.OwnInventory.GetItemAt(index)) end
                
            end
            index = index + 1
        end
        
    
        -- deteriorate Thrust Bearings
        MT.HF.subFromListAll(MT.Config.bearingDPS * MT.Deltatime, bearingItems) -- apply deterioration to each bearings independently
        -- counteract frictionDamage
        frictionDamage = frictionDamage - frictionDamage / bearingSlots * #bearingItems     
        -- apply frictionDamage
        item.Condition = item.Condition - frictionDamage

        -- <!-- DISABLE: Cannot transmit power without turbine blades, right? -->       
        item.GetComponentString("RelayComponent").SetState(bladeCount >= 4, false)
       
    else 
       
        -- machine is off - all parts can now be swapped
        while(index < item.OwnInventory.Capacity) do
            if item.OwnInventory.GetItemAt(index) ~= nil then
                item.OwnInventory.GetItemAt(index).HiddenInGame = false
                if SERVER then MT.HF.SyncToClient("HiddenInGame", item.OwnInventory.GetItemAt(index)) end                
            end
            index = index + 1
            end
        end
end

-- REDUCTION GEAR:
function MT.F.reductionGear(item)
    local index = 0
    -- if operational (condition) and operating (powered)
    if item.ConditionPercentage > 1 and item.GetComponentString("Powered").Voltage > 0.5 then
        -- oil
        local oilItems = {}
        local oilVol = 0
        local oilSlots = 4 -- temporarily hardcoded, need to fix
        -- filtration
        local oilFiltrationItems = {}
        local oilfiltrationSlots = 2 -- temporarily hardcoded, need machine table or handle in loop
        -- Damage and Reduction
        local frictionDamage = MT.Config.frictionBaseDPS * MT.Deltatime * oilSlots -- convert baseDPS to DPD and multiply for oil capacity    
        local oilDeterioration = MT.Config.oilBaseDPS * MT.Deltatime * oilSlots -- convert baseDPS to DPD and multiply for capacity
        local driveGearCount = 0

        local forceStrength = MT.HF.Round(item.GetComponentString("Engine").Force, 2)
        if forceStrength < 0 then forceStrength = forceStrength * -1 end

        --loop through the Reduction Gear inventory        
        while(index < item.OwnInventory.Capacity) do
            -- make sure the slot isn't empty
            if item.OwnInventory.GetItemAt(index) ~= nil then
                local containedItem = item.OwnInventory.GetItemAt(index)
                -- check for drive gears
                if containedItem.Prefab.Identifier.Value == "drive_gear" and containedItem.Condition > 0 then
                    driveGearCount = driveGearCount + 1
                    -- damage the gears if the condition is below 25 and if the propeller is engaged 
                    if item.ConditionPercentage < 40 and forceStrength ~= 0 then containedItem.Condition = containedItem.Condition - forceStrength^0.5 end -- make this damage exponential to force someday                    

                    -- disable hot swapping
                    item.OwnInventory.GetItemAt(index).HiddenInGame = true 
                    if SERVER then MT.HF.SyncToClient("HiddenInGame", item.OwnInventory.GetItemAt(index)) end

                -- check for oil    
                elseif containedItem.HasTag("oil") and containedItem.Condition > 0 then
                    table.insert(oilItems, containedItem)
                    oilVol = oilVol + containedItem.Condition
                    frictionDamage = frictionDamage - MT.Config.frictionBaseDPS * MT.Deltatime -- LUBRICATE: reduce *possible* friction damage for this oil slot  
                
                    -- check for filters
                elseif containedItem.HasTag("oilfilter") then
                    table.insert(oilFiltrationItems, containedItem)
                    oilDeterioration =  oilDeterioration - MT.Config.oilBaseDPS * MT.Config.oilFiltrationM / oilfiltrationSlots -- LUBRICATE: reduce *possible* oil damage for this filter slot  
                end
            end
            index = index + 1
        end

        -- deteriorate oil
        MT.HF.subFromListEqu(oilDeterioration, oilItems) -- total oilDeterioration is spread across all oilItems. (being low on oil will make the remaining oil deteriorate faster)
        -- deteriorate filter(s)
        MT.HF.subFromListAll(MT.Config.oilFilterDPS * MT.Deltatime, oilFiltrationItems) -- apply deterioration to each filters independently, they have already reduced oil deteriorate

        -- apply frictionDamage
        item.Condition = item.Condition - frictionDamage

    else
        -- machine is off - all parts can now be swapped
        while(index < item.OwnInventory.Capacity) do
            if item.OwnInventory.GetItemAt(index) ~= nil then
                item.OwnInventory.GetItemAt(index).HiddenInGame = false 
                if SERVER then MT.HF.SyncToClient("HiddenInGame", item.OwnInventory.GetItemAt(index)) end                
            end
            index = index + 1
            end
        end        
end
