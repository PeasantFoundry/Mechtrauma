MT.F = {}
CentralComputer = {}
CentralComputer.online = true

LuaUserData.RegisterTypeBarotrauma("Items.Components.SimpleGenerator")

-- Hull:Condition ratio for oxygen is 2333:1 and a player breaths 700 oxygen per second. 
-- human breaths 700 oxygen/second and that requires to 0.3 

    --combustionMax
    --combustionEfficieny
    --combustionTarget
function MT.F.relayIgnition(item)    
    local ignition = item.GetComponentString("RelayComponent").IsOn
    return ignition
end

function MT.F.sGeneratorIgnition(item)
    local ignition = MT.HF.findComponent(item, "SimpleGenerator").IsActive
    return ignition
end

--table for dieselEngine models
MT.DE = {
    s5000D={
        maxHorsePower=5000,
        oilSlots=2,
        filterSlots=1,
        dieselFuelSlots=6,
        auxOxygenSlots=3,
        name="s5000D",
        ignitionType=MT.F.relayIgnition
    },
    s3000D={
        maxHorsePower=3000,
        oilSlots=1,
        filterSlots=1,
        dieselFuelSlots=4,
        auxOxygenSlots=2,
        name="s3000D",
        ignitionType=MT.F.relayIgnition
    },
    sC2500Da={
        maxHorsePower=2500,
        oilSlots=2,
        filterSlots=1,
        dieselFuelSlots=3,
        auxOxygenSlots=3,
        name="s2500Da",
        ignitionType=MT.F.relayIgnition
    },
    sC2500Db={
        maxHorsePower=2500,
        oilSlots=2,
        filterSlots=1,
        dieselFuelSlots=3,
        auxOxygenSlots=3,
        name="s2500Db",
        ignitionType=MT.F.sGeneratorIgnition
    },
    PDG250={
        maxHorsePower=250,
        oilSlots=1,
        filterSlots=1,
        dieselFuelSlots=1,
        auxOxygenSlots=1,
        name="PDG250",
        ignitionType=MT.F.relayIgnition
    }
}

function MT.F.dieselGenerator(item)
    -- debig printing: print(item.GetComponentString("RelayComponent").DisplayLoad)
    -- convert load(kW) to targetPower(HP) 1.341022
    print(item.Name)
    -- print(item.GetComponentString("Powered").PowerOut.Grid.Load)
    --print(item.GetComponentString(Barotrauma.Items.Components.SimpleGenerator).PowerOut.Grid.Load)
  

    local simpleGenerator = MT.HF.findComponent(item, "SimpleGenerator")
    
    

    print(simpleGenerator)
    print("IsActive")
    print(simpleGenerator.IsActive)
    
    print("Load: " .. tostring(simpleGenerator.GridLoad))
    --print("PowerOut: " .. tostring(simpleGenerator.PowerOut.Grid.Power))
    

    local targetPower = simpleGenerator.GridLoad

    -- check for a series index
    if MT.DE[item.Prefab.Identifier.Value] ~= nil then
        -- combustion
        local result = MT.F.dieselEngine(item, MT.DE[item.Prefab.Identifier.Value].ignitionType(item), MT.DE[item.Prefab.Identifier.Value], targetPower)
        --print("dieslengine.combustion", dieselEngine.combustion)
        --print("Horse Power Generated!", result.powerGenerated)
        --print((result.powerGenerated * .75) / 60)
        
        --print(item," BEFORE: ", item.GetComponentString("PowerContainer").Charge)
        simpleGenerator.PowerConsumption = -result.powerGenerated
        --item.GetComponentString("PowerContainer").Charge = item.GetComponentString("PowerContainer").Charge + ((result.powerGenerated) / 60)
        --print("AFTER: ", item.GetComponentString("PowerContainer").Charge)
        -- DEBUG PRINTING
        --print("result.powerGenerated:", result.powerGenerated )
        --print("result.powergenerated processed:", (result.powerGenerated) / 60) 
    else
        --possibly create a new dieselSeries or support some tag based series
        print(item.Prefab.Identifier.Value, " DOES NOT EXIST!")
    end
end

function MT.F.dieselEngine(item, ignition, dieselSeries, targetPower)
    --ADVANCED DIESEL DESIGN
    -- HP:kW = 1:0.75
    -- HP:diesel(l) 1:0.2
    print(ignition)
    local dieselEngine = {}

    --depricated powerconversion calculation  
    --local dieselFuelNeededCL = targetPower / ((MT.Config.DieselPowerRatioCL * 3600) * MT.Config.DieselGeneratorEfficiency)  -- liters
    -- if targetPower > dieselSeries.maxHorsePower then targetPower = dieselSeries.maxHorsePower       
    -- print("Target horsePower:", MT.HF.Clamp(targetPower * 1.35, 100, dieselSeries.maxHorsePower))
    local dieselFuelNeededCL = MT.Config.DieselHorsePowerRatioCL * MT.HF.Clamp(targetPower, 100, dieselSeries.maxHorsePower) / 3600 * MT.Deltatime -- min power is idle speed
    local oxygenNeeded = dieselFuelNeededCL * MT.Config.DieselOxygenRatioCL -- this is where we cheat and pretend that 1 condition of oxygen is equal to 1 condtion of diesel    

    -- oxygen    
    local auxOxygenItems = {}
    local auxOxygenVol = 0
    local hullOxygenPercentage = 0
    -- this errors when a portable dieselEngine is outside of a hull...
     if item.InWater == false then hullOxygenPercentage = item.FindHull().OxygenPercentage else hullOxygenPercentage = 0 end

    -- diesel
    local dieselFuelItems = {}
    local dieselFuelVol = 0
    -- oil
    local oilItems = {}
    local oilVol = 0
    -- filtration
    local oilFiltrationItems = {}
    local oilfiltrationSlots = dieselSeries.filterSlots
    local oilFiltrationVol = 0
    -- Damage and Reduction
    local frictionDamage = MT.Config.FrictionBaseDPS * MT.Deltatime * dieselSeries.oilSlots -- convert baseDPS to DPD and multiply for oil capacity    
    local oilDeterioration = MT.Config.OilBaseDPS * MT.Deltatime * dieselSeries.oilSlots -- convert baseDPS to DPD and multiply for capacity

    local index = 0
    -- INVENTORY: loop through the inventory and see what we have
    while(index < item.OwnInventory.Capacity) do
    if item.OwnInventory.GetItemAt(index) ~= nil then 
        local containedItem = item.OwnInventory.GetItemAt(index)
        -- get diesel item(s)
        if containedItem.HasTag("diesel_fuel") and containedItem.Condition > 0 then
            table.insert(dieselFuelItems, containedItem)
            dieselFuelVol = dieselFuelVol + containedItem.Condition            
        -- get oil item(s)    
        elseif containedItem.HasTag("oil") and containedItem.Condition > 0 then
            table.insert(oilItems, containedItem)
            oilVol = oilVol + containedItem.Condition
            frictionDamage = frictionDamage - MT.Config.FrictionBaseDPS * MT.Deltatime -- LUBRICATE: reduce *possible* friction damage for this oil slot  
        -- get oil filtration item(s)
        elseif containedItem.HasTag("oilfilter") and containedItem.Condition > 0 then
            table.insert(oilFiltrationItems, containedItem)            
            oilDeterioration = oilDeterioration - oilDeterioration * (MT.Config.OilFiltrationM / oilfiltrationSlots) -- FILTER: reduce *possible* oil damage for this filter slot  
            oilFiltrationVol = oilFiltrationVol + containedItem.Condition
        -- get aux oxygen item(s)    
        elseif containedItem.HasTag("refillableoxygensource") and containedItem.Condition > 0 then 
            table.insert(auxOxygenItems, containedItem)
            auxOxygenVol = auxOxygenVol + containedItem.Condition
        end
    end
    index = index + 1
    end
         
    -- fuelCheck
    if dieselFuelVol > dieselFuelNeededCL then dieselEngine.fuelCheck = true end
    -- oxygenCheck
    if hullOxygenPercentage > 75 or auxOxygenVol > oxygenNeeded then dieselEngine.oxygenCheck = true end
    
    -- attempt combustion
    if item.Condition > 0 and ignition and dieselEngine.fuelCheck and dieselEngine.oxygenCheck  then
        dieselEngine.combustion = true
    
        -- burn oxygen       
        if item.FindHull().OxygenPercentage >= 75 then  -- burn hull oxygen when above 75%
            item.FindHull().Oxygen = item.FindHull().Oxygen - (oxygenNeeded * 2250) -- 2250 hull oxygen ~= 1 oxygen condition                     
        else
            MT.HF.subFromListSeq (oxygenNeeded, auxOxygenItems) -- burn auxOxygen
        end
        -- burn diesel
        MT.HF.subFromListSeq (dieselFuelNeededCL, dieselFuelItems) -- burn diesel sequentially, improves resource management 
        -- burn oil
        MT.HF.subFromListEqu(oilDeterioration, oilItems) -- total oilDeterioration is spread across all oilItems. (being low on oil will make the remaining oil deteriorate faster)
        -- deteriorate filter(s)
        MT.HF.subFromListAll((MT.Config.OilFilterDPS * MT.Deltatime), oilFiltrationItems) -- apply deterioration to each filters independently, they have already reduced oil deteriorate
        -- friction damage
        item.Condition = item.Condition - frictionDamage

        -- set the generated amount to be returned
        dieselEngine.powerGenerated = MT.HF.Clamp(targetPower, 100, dieselSeries.maxHorsePower)
        -- restrict max output to to dieselEngine.powerGenerated. This prevents powerfluctations 
        --item.GetComponentString("PowerContainer").MaxOutPut = dieselSeries.maxHorsePower
        --item.GetComponentString("RelayComponent").maxOutput = dieselSeries.maxHorsePower
        --item.GetComponentString("RelayComponent").MaxPower = dieselSeries.maxHorsePower
        --dieselEngine.powerGenerated
       
        --print("MAX OUTPUT: ", item.GetComponentString("PowerContainer").MaxOutPut, " for: ", item)
        --print("MAX POWER: ",  item.GetComponentString("RelayComponent").MaxPower)

       --[[ for k, connection in pairs(item.Connections) do
            print("Found one!")
            print(item.Connections)
            print(connection.DisplayName)
            
        end]]
        --public override PowerRange MinMaxPowerOut(Connection connection, float load = 0)

        -- DEBUG PRINTING: print("Diesel Fuel will last for: ",(dieselFuelVol / dieselFuelNeededCL) * 2 / 60, " minutes.")  
        -- DEBUG PRINTING: print("Oil will last for: ", oilVol / oilDeterioration * MT.Deltatime / 60)
        -- DEBUG PRINTING: print("Filration will last for: ", oilFiltrationVol / MT.Config.OilFilterDPS  / 60 )

        -- combustion sound: this sorta works, need to just move sounds to sound items, unfortunately. 
        for k, item in pairs(item.Components) do            
            if tostring(item) == "Barotrauma.Items.Components.LightComponent" then item.IsOn = true end
            -- print(item,": ", item.IsOn)
        end

        return dieselEngine
    else
        
        dieselEngine.powerGenerated = 0
        dieselEngine.combustion = false
       
        for k, item in pairs(item.Components) do            
            if tostring(item) == "Barotrauma.Items.Components.LightComponent" then item.IsOn = false end
            -- print(item,": ", item.IsOn) 
        end
            
        return dieselEngine
    end 
    
end

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
            -- low poressure (less than 2500 protection) diving suits receive 50% deterioration dammage per delta
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
        if voltage > 1.7 then fuseOvervoltDamage = MT.Config.FuseOvervoltDamage * voltage end
        if item.GetComponentString("PowerTransfer").PowerLoad ~= 0 then fuseDeteriorationDamage = MT.Config.FuseboxDeterioration * 0.1 end  --detiorate the fuse at 10% of MT.Config.FuseboxDeterioration 
  
        -- apply water, deterioration, and overvoltage damage to the fuse
        item.OwnInventory.GetItemAt(0).Condition = item.OwnInventory.GetItemAt(0).Condition - fuseWaterDamage - fuseOvervoltDamage - fuseDeteriorationDamage
                
    else
        
        -- fuseBox: if the fuse is missing enable deterioration, overvoltage, and fires.         
        item.GetComponentString("Repairable").DeteriorationSpeed = MT.Config.FuseboxDeterioration --enable deterioration        
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

    --<!-- Deteriorate the Circulator Pumps -->
    -- -0.05 deterioration per 2 second when powered
    local index = 0
    -- if operational (condition) and operating (powered)
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
                    -- disable hot swapping parts
                    containedItem.HiddenInGame = true -- cannot remove while operational
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
        local frictionDamage = MT.Config.FrictionBaseDPS * MT.Deltatime * oilSlots -- convert baseDPS to DPD and multiply for oil capacity    
        local oilDeterioration = MT.Config.OilBaseDPS * MT.Deltatime * oilSlots -- convert baseDPS to DPD and multiply for capacity
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
                    frictionDamage = frictionDamage - MT.Config.FrictionBaseDPS * MT.Deltatime -- LUBRICATE: reduce *possible* friction damage for this oil slot  
                
                    -- check for filters
                elseif containedItem.HasTag("oilfilter") then
                    table.insert(oilFiltrationItems, containedItem)
                    oilDeterioration =  oilDeterioration - MT.Config.OilBaseDPS * MT.Config.OilFiltrationM / oilfiltrationSlots -- LUBRICATE: reduce *possible* oil damage for this filter slot  
                end
            end
            index = index + 1
        end

        -- deteriorate oil
        MT.HF.subFromListEqu(oilDeterioration, oilItems) -- total oilDeterioration is spread across all oilItems. (being low on oil will make the remaining oil deteriorate faster)
        -- deteriorate filter(s)
        MT.HF.subFromListAll(MT.Config.OilFilterDPS * MT.Deltatime, oilFiltrationItems) -- apply deterioration to each filters independently, they have already reduced oil deteriorate

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
