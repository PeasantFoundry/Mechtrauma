MT.F = {}
MT.F.reportTypes = {}
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

-- STEAM HEATSINK:
function MT.F.steamHeatsink(item)
    local relayComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.RelayComponent")
    local controllerComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Controller")
    local powerComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.PowerTransfer")
    -- if the controller swtich is on, open the valve
end


-- ********** REPORTS: **********
function MT.F.reportTypes.fuse(item, terminal, message, command, argument)
     -- terminal goodness
  local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
  local property = terminal.SerializableProperties[Identifier("TextColor")]

  local fuseList = {}
  local weakFuses = 0
  local fuseYellowCondition = 50
  local fuseRedCondition = 10 --
  local fuseBoxCount = 0
  local fuseLocation = "ERROR" -- inca
  --local hull
  MT.HF.BlankTerminalLines(terminal, 20)
  if CentralComputer.online then
    terminal.SendMessage("*******REPORT: FUSE STATUS*******", Color(0, 255, 0, 255))
    -- loop through the item list to find our fuse boxes(later make this loop through mtuItems?)
    for k, item in pairs(Item.ItemList) do
      
      -- CHECK: does the item have a fusebox?
      if item.HasTag("fusebox") then 
        fuseBoxCount = fuseBoxCount + 1
      -- check for a fuse
        if item.OwnInventory.GetItemAt(0) ~= nil then -- this assumes that items with fuseboxes always put the fuse in slot 0. This is currently true but somewhat brittle.
          -- if true - add the item to the fuseList
          table.insert(fuseList, item.OwnInventory.GetItemAt(0))                             
        else
          -- if false - report a missing fuse 
          if item.FindHull() ~= nil then fuseLocation = item.FindHull().DisplayName.Value else fuseLocation = "UNKNOWN" end              
            terminal.SendMessage("[!NO FUSE!] Fixture: " .. item.name .. " Location: " .. fuseLocation, Color(255, 69, 0, 255))
        end
      end
    end

    table.sort(fuseList, function (k1, k2) return k1.ConditionPercentage >  k2.ConditionPercentage end )

    -- loop through the fuseList
    for k, fuse in pairs(fuseList) do
      
      -- CHECK: does the item have a hull? if false - report fuseLocation as "UNKNOWN"
      if fuse.FindHull() ~= nil then fuseLocation = fuse.FindHull().DisplayName.Value else fuseLocation = "UNKNOWN" end  
      -- CHECK: what condition is the fuse in? count weak fuses and set report color.
      if fuse.ConditionPercentage < fuseRedCondition then
        --weak fuse 
        terminal.SendMessage("Fuse at: " .. MT.HF.Round(fuse.ConditionPercentage, 2) .. "% in: " .. fuseLocation, Color(255, 69, 0, 255))
        weakFuses = weakFuses + 1        
      elseif fuse.ConditionPercentage < fuseYellowCondition then
        -- bad fuse
        terminal.SendMessage("Fuse at: " .. MT.HF.Round(fuse.ConditionPercentage, 2) .. "% in: " .. fuseLocation, Color.Yellow)
      else
        -- good fuse
        terminal.SendMessage("Fuse at: " .. MT.HF.Round(fuse.ConditionPercentage, 2) .. "% in: " .. fuseLocation, Color.Lime)        
      end
    end
    terminal.SendMessage("------------------------------", Color.Lime)
    terminal.SendMessage("TOTAL FUSE BOXES:" .. fuseBoxCount, Color.Lime)
    if weakFuses > 0 then terminal.SendMessage("FUSES WEAK:" .. weakFuses, Color(255, 69, 0, 255)) else terminal.SendMessage("FUSES WEAK:" .. weakFuses, Color.Lime) end
    if fuseBoxCount - #fuseList > 1 then terminal.SendMessage("FUSES MISSING:" .. fuseBoxCount - #fuseList, Color(255, 69, 0, 255)) else terminal.SendMessage("FUSES MISSING:" .. fuseBoxCount - #fuseList, Color.Lime) end
   
    terminal.SendMessage("**************END REPORT**************", Color(255, 69, 0, 255))
  else
    terminal.SendMessage("**************NO CONNECTION**************", Color.Red)
  end

end

function MT.F.reportTypes.power(item, terminal, message, command, argument)

    local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
    local poweredList = {}
    local totalPowerConsumption = 0
    local hull = "ERROR"
    --print(item.GetComponent.Powered())

    if CentralComputer.online then
        
        terminal.SendMessage("*******REPORT: GRID POWER CONSUMPTION*******", Color(0, 255, 0, 255))

        for k, item in pairs(Item.ItemList) do
        if item.FindHull() ~= nil then hull = item.FindHull().DisplayName.Value else hull = "EXTERIOR"  end
        local poweredComponent = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Powered")
        if poweredComponent ~= nil and poweredComponent.CurrPowerConsumption > 0.5 and item.HasTag("fusebox") == false then
            totalPowerConsumption = totalPowerConsumption + poweredComponent.CurrPowerConsumption           
            table.insert(poweredList, item)
        end
        end

        table.sort(poweredList, function (k1, k2) return MTUtils.GetComponentByName(k1, "Barotrauma.Items.Components.Powered").CurrPowerConsumption < MTUtils.GetComponentByName(k2, "Barotrauma.Items.Components.Powered").CurrPowerConsumption end )

        for k, item in pairs(poweredList) do
        hull = "ERROR"
        if item.FindHull() ~= nil then hull = item.FindHull().DisplayName.Value end      
        terminal.SendMessage("[Power: " .. MT.HF.Round(MTUtils.GetComponentByName(item, ".Barotrauma.Items.Components.Powered").CurrPowerConsumption, 2) .. "kW | Fixture: " .. item.name .. " | Location: " .. hull .. "]", Color(0, 255, 0, 255))
        end

        --terminal.TextColor = Color(255, 69, 0, 255)
        terminal.SendMessage("-----------------TOTAL-----------------", Color(255, 69, 0, 255))
        terminal.SendMessage("ESTIMATED POWER CONSUMPTION:" .. MT.HF.Round(totalPowerConsumption, 2) .. "kW", Color(255, 69, 0, 255))
        terminal.SendMessage("**************END REPORT**************", Color(255, 69, 0, 255))

    else
        terminal.SendMessage("**************NO CONNECTION**************", Color(255, 69, 0, 255))
    end

end

function MT.F.reportTypes.blood(item, terminal, message, command, argument)
     --local containedItem = item.OwnInventory.GetItemAt(0)
  local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
  local bloodBankInventory = {}
  if CentralComputer.online then
    MT.HF.BlankTerminalLines(terminal, 20) -- create some space
    -- begin report
    terminal.SendMessage("*******REPORT: HEMATOLOGY*******", Color.Blue)

    -- Do nothing if NT isn't enabled
    if not NT then return end

    -- populate the bloodBank
    for k, item in pairs(item.ItemList) do
      -- identify by tag
      if item.HasTag("container") and item.HasTag("bloodbank") then
        local index = 0
        while(index < item.OwnInventory.Capacity) do
          -- make sure the slot isn't empty
          if item.OwnInventory.GetItemAt(index) ~= nil then
            -- grab all the items in the slot            
            for bloodpack, value in (item.OwnInventory.GetItemsAt(index)) do
              -- if the blood IS NOT in the bloodBankInventory, add it
              if not bloodBankInventory[bloodpack.name] then
                bloodBankInventory[bloodpack.name] = {}
                bloodBankInventory[bloodpack.name].count = 1
              else
                -- if the pharmaceutical IS in the pharmacyInventory, increase the count
                bloodBankInventory[bloodpack.name].count = bloodBankInventory[bloodpack.name].count + 1                
              end
            end
          end
          -- increment the slot index
          index = index + 1
        end
      end
        end

    -- HEMATOLOGY REPORT
    terminal.ShowMessage = "-------------CREW MANIFEST-------------"
    for k, character in pairs(Character.CharacterList) do
      -- CHECK: for donor card
      if character.Inventory.GetItemInLimbSlot(InvSlotType.Card).OwnInventory.GetItemAt(0) ~= nil then bloodType = character.Inventory.GetItemInLimbSlot(InvSlotType.Card).OwnInventory.GetItemAt(0).name else bloodType = "UNKNOWN" end      
      terminal.ShowMessage = "NAME: " .. character.Name  .. " | " .. "BLOOD TYPE: " .. bloodType
    end    
    terminal.ShowMessage = "-------------BLOOD BANK-------------"
    for bloodpack, value in pairs(bloodBankInventory) do      
      terminal.ShowMessage = "BLOODPACK: " .. bloodpack .. " | x"  .. bloodBankInventory[bloodpack].count
    end    
    terminal.ShowMessage = "------------------------------"
    terminal.ShowMessage = "**************END REPORT**************"
  else
    terminal.ShowMessage = "**************NO CONNECTION**************"
  end
end

function MT.F.reportTypes.pharmacy(item, terminal, message, command, argument)

--local containedItem = item.OwnInventory.GetItemAt(0)  
local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
local pharmacyInventory = {}
--local itemStack = {}
if CentralComputer.online then
  MT.HF.BlankTerminalLines(terminal, 20) -- create some space
  -- begin report
  terminal.SendMessage("*******REPORT: PHARMACY*******", Color(200, 35, 35, 255))
  
  -- look for Pharmacy Containers
  for k, item in pairs(item.ItemList) do
    -- identify by tag
    if item.HasTag("container") and item.HasTag("pharmacy") then
      local index = 0
      while(index < item.OwnInventory.Capacity) do
        -- make sure the slot isn't empty
        if item.OwnInventory.GetItemAt(index) ~= nil then
          -- grab all the items in the slot            
          for pharmaceutical, value in (item.OwnInventory.GetItemsAt(index)) do
            -- if the pharmaceutical IS NOT in the pharmacyInventory, add it
            if not pharmacyInventory[pharmaceutical.name] then
              pharmacyInventory[pharmaceutical.name] = {}
              pharmacyInventory[pharmaceutical.name].count = 1
            else
              -- if the pharmaceutical IS in the pharmacyInventory, increase the count
              pharmacyInventory[pharmaceutical.name].count = pharmacyInventory[pharmaceutical.name].count + 1                
            end
          end
        end
        -- increment the slot index
        index = index + 1
      end
    end
  end

  -- PHARMACY REPORT    
  for pharmaceutical, value in pairs(pharmacyInventory) do      
    terminal.ShowMessage = "PHARMACEUTICAL: " .. pharmaceutical .. " | x"  .. pharmacyInventory[pharmaceutical].count
  end    
  terminal.ShowMessage = "------------------------------"
  terminal.ShowMessage = "**************END REPORT**************"
  else
  terminal.ShowMessage = "**************NO CONNECTION**************"
end

if SERVER then
  terminal.SyncHistory()
end
end
function MT.F.reportTypes.pump(item, terminal, message, command, argument)
    --local containedItem = item.OwnInventory.GetItemAt(0)
    local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
    local terminalItem = item
    local property = terminal.SerializableProperties[Identifier("TextColor")]
    local pumpList = {}
    local electricMotorList = {}
    local mtPumpCount = 0
    local pumpGateCount = 0
    local pumpGateCondition = 0
    local electricMotorCount = 0
    local brokenElectricMotorCount = 0  
    local pumpLocation

    if CentralComputer.online then    
        MT.HF.BlankTerminalLines(terminal, 20) -- create some space
        -- begin report
        terminal.SendMessage("*******REPORT: WATER PUMP STATUS*******", Color(65, 115, 205, 255))
        for k, item in pairs(Item.ItemList) do   
            -- CHECK: Is this item Mechtrauma pump? Avoiding identifiers for compatibility.
            if item.HasTag("mtpump") then
            mtPumpCount = mtPumpCount + 1

            -- look for an Electric Motor in slot 0
                if item.OwnInventory.GetItemAt(0) ~= nil then
                    electricMotorCount = electricMotorCount + 1
                        if item.OwnInventory.GetItemAt(0).ConditionPercentage == 0 then brokenElectricMotorCount = brokenElectricMotorCount + 1 end
                        table.insert(pumpList, item)
                else
                    -- report missing electric motor
                    if item.FindHull() ~= nil then pumpLocation = item.FindHull().DisplayName.Value else pumpLocation = "UNKNOWN" end
                    terminal.ShowMessage = "[!ELECTIC MOTOR MISSING!] For: " .. item.Name .. " in " .. pumpLocation          
                end
            -- Check for a mechtrauma pump gate tag. Avoiding identifiers for compatibility.
            elseif item.HasTag("pumpgate") then
                pumpGateCount = pumpGateCount + 1
                pumpGateCondition = pumpGateCondition + item.ConditionPercentage
            end
        end

        table.sort(pumpList, function (k1, k2) return k1.ConditionPercentage >  k2.ConditionPercentage end )

        -- loop through the pumpList
        for k, item in pairs(pumpList) do      
            -- CHECK: does the item have a hull? if false - report fuseLocation as "UNKNOWN"
            if item.FindHull() ~= nil then pumpLocation = item.FindHull().DisplayName.Value else pumpLocation = "UNKNOWN" end  
            terminal.ShowMessage = "[" .. MT.HF.Round(item.ConditionPercentage, 0) .. "% PUMP | " .. MT.HF.Round(item.OwnInventory.GetItemAt(0).ConditionPercentage, 0) .. "% EM]" .. " - [" .. item.Name .. " in " .. pumpLocation .. "]"
            
        end
  
        terminal.ShowMessage = "-----------------PUMPS-----------------"
        terminal.ShowMessage = "TOTAL WATER PUMPS:" .. mtPumpCount
        terminal.ShowMessage = "FAILED ELECTRIC MOTORS:" .. brokenElectricMotorCount
        terminal.ShowMessage = "MISSING ELECTRIC MOTORS: " .. mtPumpCount - electricMotorCount
        terminal.ShowMessage = "-----------------GATES-----------------"
        terminal.ShowMessage = "TOTAL PUMP GATES: " .. pumpGateCount
        terminal.ShowMessage = "AVERAGE CONDITION: " .. MT.HF.Round(pumpGateCondition / pumpGateCount, 2) .. "%"
        terminal.ShowMessage = "PUMP CAPCITY REDUCED BY: " ..  MT.HF.Round(pumpGateCondition / pumpGateCount - 100, 2) .. "%"
        terminal.ShowMessage = "**************END REPORT**************"
    else
        terminal.ShowMessage = "**************NO CONNECTION**************"
    end

end

function MT.F.reportTypes.c02(item, terminal, message, command, argument)
  --local containedItem = item.OwnInventory.GetItemAt(0)
  local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
  local co2FilterList = {}
  local co2FilterCount = 0
  local co2FilterExpiredCount = 0
  local oxygenVentCount = 0
  local filterLocation

  MT.HF.BlankTerminalLines(terminal, 20) -- create some space
  if CentralComputer.online then
    -- begin report
    terminal.SendMessage("*******REPORT: CO2 FILTER STATUS*******", Color.Lime)
    -- find the vents and filters
    for k, item in pairs(Item.ItemList) do   
      if item.Prefab.Identifier.Value == "oxygen_vent" then 
        oxygenVentCount = oxygenVentCount + 1        
        if item.OwnInventory.GetItemAt(0) ~= nil then 
          co2FilterCount = co2FilterCount + 1
          table.insert(co2FilterList, item.OwnInventory.GetItemAt(0))
          if item.OwnInventory.GetItemAt(0).ConditionPercentage < 1 then co2FilterExpiredCount = co2FilterExpiredCount + 1 end
        else 
          if item.FindHull() ~= nil then filterLocation = item.FindHull().DisplayName.Value else filterLocation = "ERROR" end
          terminal.ShowMessage = "[!Co2 FILTER MISSING!] " .. filterLocation  
        end
      end
    end

    table.sort(co2FilterList, function (k1, k2) return k1.ConditionPercentage > k2.ConditionPercentage end)

    for k, co2Filter in pairs(co2FilterList) do
      if co2Filter.FindHull() ~= nil then filterLocation = co2Filter.FindHull().DisplayName.Value else filterLocation = "ERROR" end
      terminal.ShowMessage = "Co2 Filter at: " .. MT.HF.Round(co2Filter.ConditionPercentage, 2) .. "% in: " .. filterLocation  
      
    end

    
    terminal.SendMessage("------------------------------", Color.Lime)
    terminal.SendMessage("TOTAL FILTERED OXYGEN VENTS:" .. oxygenVentCount, Color.Lime)
    terminal.SendMessage("Co2 FILTERS EXPIRED:" .. co2FilterExpiredCount, Color.Lime)
    terminal.SendMessage("Co2 FILTERS MISSING:" .. oxygenVentCount - co2FilterCount, Color.Lime)
    terminal.SendMessage("**************END REPORT**************", Color.Lime)
  

  else
    terminal.ShowMessage = "**************NO CONNECTION**************"
  end
  -- legacy?
  if SERVER then
    terminal.SyncHistory()
  end
end