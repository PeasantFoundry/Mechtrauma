MT.F = {}
CentralComputer = {}
CentralComputer.online = true

-- LuaUserData.RegisterTypeBarotrauma("Items.Components.SimpleGenerator")

-- Hull:Condition ratio for oxygen is 2333:1 and a player breaths 700 oxygen per second. 
-- human breaths 700 oxygen/second and that requires to 0.3 

-- DIVINGSUIT: updates deterioration and extended pressure protection. 
function MT.F.divingSuit(item)
    -- only update if equipped
    if MT.HF.ItemIsWornInOuterClothesSlot(item) then
        -- DETERIORATION: 
        -- execute if divingsuit is equipped and deterioration or extended pressure protection is enabled.
        if (MT.Config.DivingSuitServiceLife > 0.0 or MT.Config.DivingSuitEPP > 1.0) then
            local itemDepth = MT.HF.GetItemDepth(item)
            local pressureProtectionMultiplier = itemDepth / item.ParentInventory.Owner.PressureProtection -- quotient of depth and pressure protection
            local pressureDamagePD = 0 -- per delta        
            local deteriorationDamagePD = 0 -- per delta
            -- calculate deterioration damage if deterioration is enabled
            if MT.Config.DivingSuitServiceLife > 0.0 then deteriorationDamagePD = (item.MaxCondition / (MT.Config.DivingSuitServiceLife * 60) * MT.Deltatime) end

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
            -- low pressure (<= 2500 protection) diving suits receive 50% deterioration dammage per delta
            if item.ParentInventory.Owner.PressureProtection <= 2500 then deteriorationDamagePD = deteriorationDamagePD * 0.5 end

            -- high pressure (>= 4000) diving suits receive 50% more deterioration damage when NOT in water
            if item.ParentInventory.Owner.PressureProtection >= 4000 and not item.InWater then deteriorationDamagePD = deteriorationDamagePD * 1.5 end

            -- apply deterioration and pressure damage to divingsuit for this delta.
            item.Condition = item.Condition - (deteriorationDamagePD + pressureDamagePD)
        end
    end
end

-- fuse logic
function MT.F.fuseBox(item)        
    local fuseWaterDamage = 0
    local fuseOvervoltDamage = 0
    local fuseDeteriorationDamage = 0    
    local powerComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.PowerTransfer")
    local repairableComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Repairable")
    local relayComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.RelayComponent")
    if powerComponent == nil or repairableComponent == nil then
        return
    end
    local voltage = powerComponent.Voltage
    
    
    --if MT.itemCache[item].counter < 0 then MT.itemCache[item].counter = 10 end
    --print("FUSE COUNTER: ", MT.itemCache[item].counter)
    --MT.itemCache[item].counter = MT.itemCache[item].counter - 1
    
    --CHECK: is there a fuse?
    if item.OwnInventory.GetItemAt(0) ~= nil and item.OwnInventory.GetItemAt(0).ConditionPercentage > 1 then
        
        --fuse present logic
        repairableComponent.DeteriorationSpeed = 0.0 -- disable fuseBfox deterioration
        powerComponent.CanBeOverloaded = false -- disable overvoltage 
        powerComponent.FireProbability = 0.1 -- reduce fire probability 
        -- enable RelayComponent if present
        if relayComponent then relayComponent.SetState(true, false) end

        -- DEBUG PRINTING:
        --if voltage > 1.7 then print(item.name, "voltage: ", voltage) end
        
        -- set water, overvoltage, and deterioration damage amounts
        if item.InWater then fuseWaterDamage = 1.0 end
        
        if powerComponent.PowerLoad ~= 0 then fuseDeteriorationDamage = MT.Config.FuseboxDeterioration * 0.1 end  --detiorate the fuse at 10% of MT.Config.FuseboxDeterioration 

        if voltage > 1.7 then
            -- use the item counter to track how long the item has been overvolted
            MT.itemCache[item].counter = MT.itemCache[item].counter + 1
            -- only apply overvoltage damage if overvoltage has lasted for more than 1 update
            if MT.itemCache[item].counter > 1 then
                fuseOvervoltDamage = MT.Config.FuseboxOvervoltDamage * voltage-- this needs to scale with load overvoltage on 10,000kw should do more damage than on 100kw     
            end
        else
            MT.itemCache[item].counter = 0
        end
        -- apply water, deterioration, and overvoltage damage to the fuse
        item.OwnInventory.GetItemAt(0).Condition = item.OwnInventory.GetItemAt(0).Condition - fuseWaterDamage - fuseOvervoltDamage - fuseDeteriorationDamage
                
    else
        
        -- fuseBox: if the fuse is missing enable deterioration, overvoltage, and fires.         
        repairableComponent.DeteriorationSpeed = MT.Config.FuseboxDeterioration --enable deterioration        
        powerComponent.CanBeOverloaded = true -- enable overvoltage
        powerComponent.FireProbability = 0.9 -- increase fire probability 
        -- disable RelayComponent if present
        if relayComponent then relayComponent.SetState(false, false) end  
        -- DEBUG PRINTING:
        -- print("ITEM: ", item.name)
        -- print("deterioration speed: ", item.name, repairableComponent.DeteriorationSpeed)
        -- print("condition percentage: ", item.ConditionPercentage) 
    end
end

-- CENTRAL COMPUTER: Ships computer
--MT.tagKeys.centralComputer = function(item)
function MT.F.centralComputer(item)
    if item.ConditionPercentage > 1 and MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Powered").Voltage > 0.5 then
        CentralComputer.online  = true
        MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.RelayComponent").SetState(true, false)        
        --print("Central computer online.")
    else
        CentralComputer.online  = false
        MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.RelayComponent").SetState(false, false)
        --print("Central computer offline.")
    end
end

function MT.F.keyIgnition(item)

end 


-- CENTRAL COMPUTER: Ships computer
function MT.F.centralComputerNeeded(item)
    if CentralComputer.online  then
        if MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Steering") ~= nil then MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Steering").CanBeSelected = true end
        if MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Sonar") ~= nil then MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Sonar").CanBeSelected = true end
        if MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.CustomInterface") ~= nil then MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.CustomInterface").CanBeSelected = true end
        if MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.MiniMap") ~= nil then MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.MiniMap").CanBeSelected = true end
        if MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Fabricator") ~= nil then MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Fabricator").CanBeSelected = true end     
    elseif not CentralComputerOnline then        
        if MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Steering") ~= nil then MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Steering").CanBeSelected = false end
        if MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Sonar") ~= nil then MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Sonar").CanBeSelected = false end
        if MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.CustomInterface") ~= nil then MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.CustomInterface").CanBeSelected = false end
        if MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.MiniMap") ~= nil then MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.MiniMap").CanBeSelected = false end
        if MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Fabricator") ~= nil then MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Fabricator").CanBeSelected = false end
    end
end

-- STEAM Boiler: the beloved steam boiler...
function MT.F.steamBoiler(item)
    local index = 0

    -- OPERATION: if operational (condition) and operating (powered)
    if item.ConditionPercentage > 0 and MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Powered").Voltage > 0.5 then
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
        MT.HF.subFromListAll(MT.Config.CirculatorDPS * MT.Deltatime, curculatorItems) -- apply deterioration to each filters independently
        -- counteract pressureDamage
        pressureDamage = pressureDamage - pressureDamage / curculatorSlots * #curculatorItems
        -- apply pressureDamage
        item.Condition = item.Condition - pressureDamage

        -- check for leaks
        if item.ConditionPercentage <= 50 then
            --print(item.CurrentHull.WaterVolume)
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
    if item.ConditionPercentage > 1 and MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Powered").Voltage > 0.5 then
        local bearingItems = {}
        local bladeCount = 0
        local bearingSlots = 4 -- temporarily hardcoded
        local frictionDamage = MT.Config.FrictionBaseDPS * bearingSlots * MT.Deltatime

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
        MT.HF.subFromListAll(MT.Config.BearingDPS * MT.Deltatime, bearingItems) -- apply deterioration to each bearings independently
        -- counteract frictionDamage
        frictionDamage = frictionDamage - frictionDamage / bearingSlots * #bearingItems     
        -- apply frictionDamage
        item.Condition = item.Condition - frictionDamage

        -- <!-- DISABLE: Cannot transmit power without turbine blades, right? -->       
        MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.RelayComponent").SetState(bladeCount >= 4, false)
       
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
    if item.ConditionPercentage > 1 and MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Powered").Voltage > 0.5 then
        -- oil
        local oilItems = {}
        local oilVol = 0 -- stored in centiliters
        local oilSlots = 4 -- temporarily hardcoded, need to fix
        local oilCapacity = oilSlots * 400 -- shouldn't this be in l?
        local oilLevel = 0
        -- filtration
        local oilFiltrationItems = {}
        local oilFiltrationSlots = 2 -- temporarily hardcoded, need machine table or handle in loop
        -- Damage and Reduction
        local frictionDamage = MT.Config.FrictionBaseDPS * MT.Deltatime * oilSlots -- convert baseDPS to DPD and multiply for oil capacity    
        local oilDeterioration = MT.Config.OilBaseDPS * MT.Deltatime * oilSlots -- convert baseDPS to DPD and multiply for capacity
        local oilDeteriorationPS = oilDeterioration / oilFiltrationSlots
        local driveGears = {}
        -- Possible overdrive mode?
        --print(MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Repairable").IsTinkering)
        local forceStrength = MT.HF.Round(MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Engine").Force, 2)        
        if forceStrength < 0 then forceStrength = forceStrength * -1 end

        --loop through the Reduction Gear inventory        
        while(index < item.OwnInventory.Capacity) do
            -- make sure the slot isn't empty
            if item.OwnInventory.GetItemAt(index) ~= nil then
                local containedItem = item.OwnInventory.GetItemAt(index)
                -- check for drive gears
                if containedItem.Prefab.Identifier.Value == "drive_gear" and containedItem.Condition > 0 then
                    table.insert(driveGears, containedItem)
                    -- seriously damage the gears if the condition is below 25 and if the propeller is engaged                     
                    if item.ConditionPercentage < 40 and forceStrength ~= 0 then containedItem.Condition = containedItem.Condition - forceStrength^0.5 end -- make this damage exponential to force someday                    
                             
                    -- disable hot swapping
                    item.OwnInventory.GetItemAt(index).HiddenInGame = true
                    if SERVER then MT.HF.SyncToClient("HiddenInGame", item.OwnInventory.GetItemAt(index)) end

                -- check for oil    
                elseif containedItem.HasTag("oil") and containedItem.Condition > 0 then
                    table.insert(oilItems, containedItem)
                    oilVol = oilVol + containedItem.Condition
                    oilLevel = oilVol / oilCapacity * 100

                    -- LUBRICATE: reduce *possible* friction damage for this oil slot  
                    frictionDamage = frictionDamage - MT.Config.FrictionBaseDPS * MT.Deltatime
                
                -- check for filters
                elseif containedItem.HasTag("oilfilter") and containedItem.Condition > 0 then
                    table.insert(oilFiltrationItems, containedItem)
                    -- FILTER: reduce oil damage for this filter slot  
                    oilDeterioration = oilDeterioration - (((MT.Config.OilBaseDPS * MT.Deltatime * oilSlots) * MT.Config.OilFiltrationM) / oilFiltrationSlots)
                end
            end
            index = index + 1
        end

        -- deteriorate oil        
        MT.HF.subFromListEqu(oilDeterioration, oilItems) -- total oilDeterioration is spread across all oilItems. (being low on oil will make the remaining oil deteriorate faster)
        -- deteriorate filter(s)
        MT.HF.subFromListAll(MT.Config.OilFilterDPS * MT.Deltatime, oilFiltrationItems) -- apply deterioration to each filters independently, they have already reduced oil deteriorate
        -- grind the gears - but only while we're moving
        if forceStrength ~= 0 then MT.HF.subFromListAll((oilLevel^-0.5)*10-1, driveGears) end
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

-- MECHANICAL CLUTCH:
function MT.F.mechanicalClutch(item)
    local relayComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.RelayComponent")
    local controllerComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Controller")
    local powerComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.PowerTransfer")
    -- if the controller swtich is on, engage the clutch
    if controllerComponent.state == true then
        --print(" Clutch powered load:", powerComponent.PowerLoad)
        --print(" Clutch relay load:", relayComponent.DisplayLoad)
        --print(" Clutch relay power out:", relayComponent.powerOut)
        relayComponent.SetState(true, false)
    -- if the controller swtich is off, disengage the clutch
    else
        --print("clutch is off!")
        relayComponent.SetState(false, false)
    end

end

-- STEAM VALVE:
function MT.F.steamValve(item)
    local relayComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.RelayComponent")
    local controllerComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Controller")
    local powerComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.PowerTransfer")
    -- if the controller swtich is on, open the valve
    if controllerComponent.state == true then   
        relayComponent.SetState(true, false)
    
        -- if the controller swtich is off, close the valve
    else        
        relayComponent.SetState(false, false)
    end

end

-- ELECTRICAL DISCONEECT:
function MT.F.electricalDisconnect(item)
    local relayComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.RelayComponent")
    local controllerComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Controller")
    local powerComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.PowerTransfer")
    -- if the controller swtich is on, connect the power
    if controllerComponent.state == true then   
        relayComponent.SetState(true, false)
    
        -- if the controller swtich is off, disconnect the power
    else        
        relayComponent.SetState(false, false)
    end

end