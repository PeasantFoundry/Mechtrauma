MT.F = {}
MT.F.reportTypes = {}
CentralComputer = {}
CentralComputer.online = true
-- Establish Mechtrauma item cache
MT.itemCache = {}
MT.itemCacheCount = 0
MT.inventoryCache = {parts={}}
MT.inventoryCacheCount = 0
MT.PriorityItemCache = {}
MT.ambientTemperature = 60


-- LuaUserData.RegisterTypeBarotrauma("Items.Components.SimpleGenerator")

-- Hull:Condition ratio for oxygen is 2333:1 and a player breaths 700 oxygen per second. 
-- human breaths 700 oxygen/second and that requires to 0.3 


-- thermal part: part thermal: probably move to diesel functions?
function MT.F.thermalPartTemp(item, thermal)
    local rootOwner = item.GetRootInventoryOwner()
    local rootOwnerIsCharacter = LuaUserData.IsTargetType(rootOwner, "Barotrauma.Character")
    --local rootOwnerThermal = MTUtils.GetComponentByName(rootOwner, "Mechtrauma.Thermal")
    if thermal.Temperature == nil then thermal.Temperature = MT.ambientTemperature end -- correct any nil temps

    if item.ParentInventory == nil then
        -- im not in an item, adjust my temperature
        if not MT.HF.approxEquals(thermal.Temperature, MT.ambientTemperature) then thermal.Temperature = MT.HF.getNewTemp(thermal.Temperature, MT.ambientTemperature, item.InWater) end

    -- don't use the root inventory owner here so that it wont burn someone if it's in hand truck 
    elseif LuaUserData.IsTargetType(item.ParentInventory, "Barotrauma.CharacterInventory") then
        -- adjust to ambientTemperature
        if not MT.HF.approxEquals(thermal.Temperature, MT.ambientTemperature) then thermal.Temperature = MT.HF.getNewTemp(thermal.Temperature, MT.ambientTemperature, item.InWater) end
        -- oh, and burn the fool holding me
        if thermal.Temperature > 200 then MT.HF.AddAffliction(item.ParentInventory.Owner,"burn", 5) end
    elseif not rootOwnerIsCharacter and rootOwner.HasTag("DieselEngine") then
        local DieselEngine = MTUtils.GetComponentByName(rootOwner, "Mechtrauma.DieselEngine")
        if DieselEngine and DieselEngine.IsRunning then
            -- do nothing, the engine will manage my temperature
            return
        else
            -- im in a diesel engine but its off. (need to port this for the item to still control ambient temperature)
            if not MT.HF.approxEquals(thermal.Temperature, MT.ambientTemperature) then thermal.Temperature = MT.HF.getNewTemp(thermal.Temperature, MT.ambientTemperature, item.InWater) end
        end
    elseif not rootOwnerIsCharacter and rootOwner.HasTag("heatExchanger") then -- holy god this is ugly, I hate it
        if rootOwner.linkedTo ~= nil then
            for k, linkedItem in pairs(rootOwner.linkedTo) do
                if linkedItem.HasTag("DieselEngine") then
                    if linkedItem and MTUtils.GetComponentByName(linkedItem, "Mechtrauma.DieselEngine").IsRunning then
                        -- do nothing, the engine will manage my temperature
                        return
                    else
                        -- im in heat exchanged that is linked to a diesel engine but its off. 
                        if not MT.HF.approxEquals(thermal.Temperature, MTUtils.GetComponentByName(linkedItem, "Mechtrauma.Thermal").Temperature) then thermal.Temperature = MT.HF.getNewTemp(thermal.Temperature, MTUtils.GetComponentByName(linkedItem, "Mechtrauma.Thermal").Temperature, item.InWater) end
                    end
                return
                end
            end
        end
    -- ugh, need to sort this out
    else
        -- im in an item that isn't a character or dosen't control item temperature, adjust to ambientTemperature
        if not MT.HF.approxEquals(thermal.Temperature, MT.ambientTemperature) then thermal.Temperature = MT.HF.getNewTemp(thermal.Temperature, MT.ambientTemperature, item.InWater) end
    end
end

-- -------------------------------------------------------------------------- --
--                                   ACTIONS                                  --
-- -------------------------------------------------------------------------- --

function MT.F.attemptRepair (item, targetItem)
    local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
    if targetItem == nil then
        terminal.SendMessage("*!CANNOT REPAIR!*")
        terminal.SendMessage("- nothing to repair")
    elseif targetItem ~= nil and item.ParentInventory.Owner ~= nil then
        local character = item.ParentInventory.Owner
        local mechanicalSkill = MT.HF.Round(character.GetSkillLevel("mechanical"), 0)
        local tagTable = MT.HF.Split(string.lower(targetItem.Tags),",")
        local repairsNeeded = false
        local originalCondition = targetItem.ConditionPercentage -- yeah yeah

        -- get the tags
        for k, tag in pairs(tagTable) do
            -- can any of these tags be fixed?
            if MT.C.diagnosticTags[tag] and MT.C.diagnosticTags[tag].fixable == true and targetItem.Condition > 0 then
                repairsNeeded = true
                -- attemptRepair - mechanical
                if MT.C.diagnosticTags[tag].fixSkill == "mechanical" then
                    -- need to make this calculation account for the required skill and possibly item type 
                    -- (IE, it's easier to remove a blockage from a rubberhose than a fuelfilter or pump).
                    if MT.HF.Chance(mechanicalSkill / 100) then
                        terminal.SendMessage("Attempt to repair the " .. MT.C.diagnosticTags[tag].tag .. " " .. targetItem.Name .. "  was successful.")
                        targetItem.ReplaceTag(MT.C.diagnosticTags[tag].tag, "")
                        targetItem.Condition = targetItem.Condition - MT.HF.Clamp(math.random(1,50) - mechanicalSkill, 1,50)
                    else
                        terminal.SendMessage("Attempt to repair the " .. MT.C.diagnosticTags[tag].tag .. " " .. targetItem.Name .. "  has failed and the item has been scrapped.")
                        targetItem.Condition = 0
                    end
                end
            end
        end
        if repairsNeeded == false and targetItem.Condition > 0 then
            terminal.SendMessage("*!CANNOT REPAIR!*")
            terminal.SendMessage("- part is not broken")
        end
        if originalCondition < 1 then
            terminal.SendMessage("*!CANNOT REPAIR!*")
            terminal.SendMessage("- service life expired")
        end
        
    end
end

-- -------------------------------------------------------------------------- --
--                                   REPORTS                                  --
-- -------------------------------------------------------------------------- --
function MT.F.reportTypes.parts(item, terminal, message, command, argument)
    terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
    -- machine parts and crafting items    
    local partsCount = {new = {}, used = {}, broken = {}}
    local partsTotalNew = 0
    local partsTotalUsed = 0
    local partsTotalBroken = 0
    -- count up the parts
    --if MT.inventoryCache.parts then terminal.SendMessage("FOUND THE CACHE!", Color.Lime) end
   
    for k, v in pairs(MT.inventoryCache.parts) do        
        --if k then terminal.SendMessage(tostring(k) .. " | " .. k.Prefab.Identifier.Value, Color.Orange) end
        
        if k.ConditionPercentage > 95 then
            -- new parts
            if partsCount.new[k.Prefab.Identifier.Value] then
                -- part type already exists, increment the totals
                partsCount.new[k.Prefab.Identifier.Value].count = partsCount.new[k.Prefab.Identifier.Value].count + 1
                partsTotalNew = partsTotalNew + 1
            else
                -- new part, add an entry and a counter
                partsCount.new[k.Prefab.Identifier.Value] = {}
                partsCount.new[k.Prefab.Identifier.Value].count = 1
                partsCount.new[k.Prefab.Identifier.Value].name = k.name
                partsTotalNew = 1
            end
        elseif k.ConditionPercentage < 5 then
            -- broken
            if partsCount.broken[k.Prefab.Identifier.Value] then
                -- part type already exists, increment the totals
                partsCount.broken[k.Prefab.Identifier.Value].count = partsCount.broken[k.Prefab.Identifier.Value].count + 1
                partsTotalBroken = partsTotalBroken + 1
            else
                -- new part, add an entry and a counter
                partsCount.broken[k.Prefab.Identifier.Value] = {}
                partsCount.broken[k.Prefab.Identifier.Value].count = 1
                partsCount.broken[k.Prefab.Identifier.Value].name = k.name
                partsTotalBroken = 1
            end
        else
            --used
            if partsCount.used[k.Prefab.Identifier.Value] then
                -- part type already exists, increment the totals
                partsCount.used[k.Prefab.Identifier.Value].count = partsCount.used[k.Prefab.Identifier.Value].count + 1
                partsTotalUsed = partsTotalUsed + 1
            else
                -- new part, add an entry and a counter
                partsCount.used[k.Prefab.Identifier.Value] = {}
                partsCount.used[k.Prefab.Identifier.Value].count = 1
                partsCount.used[k.Prefab.Identifier.Value].name = k.name
                partsTotalUsed = 1
            end

        end
    end
    
    terminal.SendMessage("*******REPORT: PARTS INVENTORY*******", Color(65, 115, 205, 255))
    -- Print totals for new parts
    
        terminal.SendMessage("NEW PARTS:", Color.Lime)
        terminal.SendMessage("-------------------------------------", Color.Lime)        
        for k, v in pairs(partsCount.new) do
            if v.count then terminal.SendMessage(v.count .. " NEW " .. v.name .. "(s)", Color.Lime) end
        end
        terminal.SendMessage("-------------------------------------", Color.Lime)
    
    -- Print totals for used parts
    if partsTotalUsed > 0 then
        terminal.SendMessage("USED PARTS:", Color.Orange)
        terminal.SendMessage("-------------------------------------", Color.Orange)        
        for k, v in pairs(partsCount.used) do        
            if v.count then terminal.SendMessage(v.count .. " USED " .. v.name .. "(s)", Color.Orange) end
        end
        terminal.SendMessage("-------------------------------------", Color.Orange)
    end
    -- Print totals for broken parts
    if partsTotalBroken > 0 then 
        terminal.SendMessage("BROKEN PARTS:", Color(255, 50, 10, 255))
        terminal.SendMessage("-------------------------------------", Color(255, 50, 10, 255))
        for k, v in pairs(partsCount.broken) do
            if v.count then terminal.SendMessage(v.count .. " BROKEN " .. v.name .. "(s)", Color(255, 50, 10, 255)) end
        end
        terminal.SendMessage("-------------------------------------", Color(255, 50, 10, 255))
    end
    terminal.SendMessage("******* END REPORT *******", Color(65, 115, 205, 255))
end
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
end


function MT.F.purchasedItemFaults(item)
    if item.HasTag("cheapdieselfuel") then
        local weights={100,100,100,250}
        local result = MT.HF.weightedRandom(weights)

        if result == 1 then
            print("HERE COMES A PRISONER!")
            item.ReplaceTag("spawnevent", "")
         
            -- and spawn an escaped prisoner
            local info = CharacterInfo("human", "Preston")
            info.Job = Job(JobPrefab.Get("prisoner"))
        
            local submarine = Submarine.MainSub
            local spawnPoint = item.WorldPosition
        
            if spawnPoint == nil then
                -- we should probably do something if it isn't able to find a spawn point
            end
        
            local character = Character.Create(info, spawnPoint, info.Name, 0, true, false)
            character.TeamID = CharacterTeamType.Team2
            character.GiveJobItems()


        elseif result ==2 then
            item.ReplaceTag("spawnevent", "water")
        elseif result == 3 then
            item.ReplaceTag("spawnevent", "contaminated")
        elseif result == 4 then
            item.ReplaceTag("spawnevent", "")
            -- do nothing, good buy!
        end
        -- was working here
    end
end