MT.F = {}
CentralComputerOnline = true
OxygenVentCount = 0

function MT.F.dieselEngine(item)
    --ADVANCED DIESEL DESIGN

    local oxygen
    local fuel

    --COMBUSTION
    if item.HasTag("combustion") then  
        --print("This item has combustion!")
    end

        --COMPRESSION
        --FUEL
        --OXYGEN        
            -- PRIMARY: HULL - Not underwater Hull oxygen > 75%            
            if item.HullOxygenPercentage > 75.0 and not item.InWater then                
            --print(item.HullOxygenPercentage)

            end
            -- AUXILLARY: O2 TANK - underwater or hull oxygen <= 75%

    --parts, oil, oil filter, fuel filter, fuel pump, engine. 
end

-- DIVINGSUIT: updates deterioration and extended pressure protection. 
function MT.F.divingSuit(item)
    -- proceed if divingsuit is equipped and deterioration or extended pressure protection is enabled.
    if MT.HF.ItemIsWornInOuterClothesSlot(item) and (MT.Config.divingSuitServiceLife > 0.0 or MT.Config.divingSuitEPP > 1.0) then
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
        -- low poressure (less than 2500 protection) diving suits receive 50% deterioration dammage per delta
        if item.ParentInventory.Owner.PressureProtection <= 2500 then deteriorationDamagePD = deteriorationDamagePD * 0.5 end
        -- apply deterioration and pressure damage to divingsuit for this update. 
        item.Condition = item.Condition - (deteriorationDamagePD + pressureDamagePD)
    end
end

-- fuse logic
function MT.F.fuseBox(item)        
    local fuseWaterDamage = 0
    local fuseOvervoltDamage = 0
    local fuseDeteriorationDamage = MT.Config.fusBoxDeterioration * 0.1  --detiorate the fuse at 10% of MT.Config.fusBoxDeterioration  
    local voltage = item.GetComponentString("PowerTransfer").Voltage

    --CHECK: is there a fuse?
    if item.OwnInventory.GetItemAt(0) ~= nil and item.OwnInventory.GetItemAt(0).ConditionPercentage > 1 then
        --fuse present logic
        item.GetComponentString("Repairable").DeteriorationSpeed = 0.0 -- enable deterioration
        item.GetComponentString("PowerTransfer").CanBeOverloaded = false -- enable overvoltage 
        item.GetComponentString("PowerTransfer").FireProbability = 0.1 -- reduce fire probability 
        
        if item.InWater then fuseWaterDamage = 1.0 end
        --print(voltage)
        --print(MT.Config.fuseOvervoltDamage)
        if voltage > 1 then fuseOvervoltDamage = MT.Config.fuseOvervoltDamage * voltage end
           
        -- fuse deterioration - we piggy back water and voltage
        if voltage > 1 then print(item.name, "voltage: ", voltage) end
        item.OwnInventory.GetItemAt(0).Condition = item.OwnInventory.GetItemAt(0).Condition - fuseWaterDamage - fuseOvervoltDamage - fuseDeteriorationDamage

    else
        -- fuseBox: if the fuse is missing enable deterioration, overvoltage, and fires. 
        item.GetComponentString("Repairable").DeteriorationSpeed = MT.Config.fusBoxDeterioration --enable deterioration        
        item.GetComponentString("PowerTransfer").CanBeOverloaded = true -- enable overvoltage
        item.GetComponentString("PowerTransfer").FireProbability = 0.9 -- increase fire probability 
 
     --debug printing
     --print("ITEM: ", item.name)
     --print("deterioration speed: ", item.name, item.GetComponentString("Repairable").DeteriorationSpeed)
     --print("condition percentage: ", item.ConditionPercentage)
 
 
    end
end

-- CENTRAL COMPUTER: Ships computer
--MT.tagKeys.centralComputer = function(item)
function MT.F.centralComputer(item)
    if item.ConditionPercentage > 1 and item.GetComponentString("Powered").Voltage > 0.5 then
        CentralComputerOnline = true
        --print("Central computer online.")
    else
        CentralComputerOnline = false
        --print("Central computer offline.")
    end
end

-- CENTRAL COMPUTER: Ships computer
function MT.F.centralComputerNeeded(item)    
    if CentralComputerOnline then
        if item.GetComponentString("Steering") ~= nil then item.GetComponentString("Steering").CanBeSelected = true end
        if item.GetComponentString("Sonar") ~= nil then item.GetComponentString("Sonar").CanBeSelected = true end
        if item.GetComponentString("CustomInterface") ~= nil then item.GetComponentString("CustomInterface").CanBeSelected = true end
        if item.GetComponentString("MiniMap") ~= nil then item.GetComponentString("MiniMap").CanBeSelected = true end
     
    elseif not CentralComputerOnline then        
        if item.GetComponentString("Steering") ~= nil then item.GetComponentString("Steering").CanBeSelected = false end
        if item.GetComponentString("Sonar") ~= nil then item.GetComponentString("Sonar").CanBeSelected = false end
        if item.GetComponentString("CustomInterface") ~= nil then item.GetComponentString("CustomInterface").CanBeSelected = false end
        if item.GetComponentString("MiniMap") ~= nil then item.GetComponentString("MiniMap").CanBeSelected = false end
    end
        
end

-- STEAM TURBINE: No more hot swapping those bearings!  
function MT.F.steamTurbine(item)
    local index = 0
    if item.ConditionPercentage > 1 and item.GetComponentString("Powered").Voltage > 0.5 then
        
        while(index < item.OwnInventory.Capacity) do
            if item.OwnInventory.GetItemAt(index) ~= nil then item.OwnInventory.GetItemAt(index).HiddenInGame = false end
            index = index + 1
        end

    else
        while(index < item.OwnInventory.Capacity) do
            if item.OwnInventory.GetItemAt(index) ~= nil then item.OwnInventory.GetItemAt(index).HiddenInGame = false end
            index = index + 1
        end      
    end
end