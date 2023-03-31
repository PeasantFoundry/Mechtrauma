
local buffer = {} -- signal buffer

Hook.Add("electricalRepair.OnFailure", "MT.electricalRepairFailure", function(effect, deltaTime, item, targets, worldPosition)
  local character
  -- if the human target isn't 10, loop through the targets and find the human
  if tostring(targets[10]) == "Human" then
     character = targets[10]
    else
      for k, v in pairs(targets) do
        if tostring(v) == "Human" then -- instead of looping, would it be possible to make a target indexed table instead of key indexed?          
          character = targets[k] 
          end
      end
  end
  -- what are we holding? this will come in handy later
  local rightHandItem = character.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)
  local leftHandItem = character.Inventory.GetItemInLimbSlot(InvSlotType.LeftHand)

  -- is electrocution enabled?
  if MT.Config.DisableElectrocution == true then
    -- check if you're a junctionbox or a fusepanel   
    if item.HasTag("junctionbox") then -- need to add fuse panel support later  
      -- i don't know why an item would have a junctionbox tag but no PowerTransfer Component but this makes the code harder to break
      local powerComponent = MTUtils.GetComponentByName(item, ".PowerTransfer");
      local electrocutionStrength = MT.HF.Clamp((powerComponent.PowerLoad/100 or 2000) * (powerComponent.Voltage or 1), 1, 200) 
      print("electrocutionStrength: ", electrocutionStrength)
      
      -- explosion
      MT.HF.AddAffliction(character,"stun",0.25)    
      local explosion = Explosion(50, 100, 0, 0, 0, 0, 0)
      explosion.Explode(item.WorldPosition - Vector2(0, 50), item)

      MT.HF.AddAffliction(character,"electrocution", electrocutionStrength)
    end
  else
    -- if not, follow vanilla functionality.
    MT.HF.AddAffliction(character,"burn",5)
    MT.HF.AddAffliction(character,"stun",4)
  end

end)

  --[[ Check the hands for an item with the tag "electricalrepairtool" in sequence.
      if rightHandItem.HasTag("electricalrepairtool") then
        NT.TraumamputateLimb(targets[8],LimbType.RightArm)
      elseif leftHandItem.HasTag("electricalrepairtool") then
        NT.TraumamputateLimb(targets[8],LimbType.LeftArm)    
      end]]


Hook.Add("mechtraumaAmputation.OnFailure", "MT.amputation", function(effect, deltaTime, item, targets, worldPosition)
  
  local character
  -- if the human target isn't 6, loop through the targets and find the human
  if tostring(targets[6]) == "Human" then
     character = targets[6]
    else
      for k, v in pairs(targets) do
        if tostring(v) == "Human" then -- instead of looping, would it be possible to make a target indexed table instead of key indexed?                    
          character = targets[k] 
          end
      end
  end
  -- what are we holding?
  local rightHandItem = character.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)
  local leftHandItem = character.Inventory.GetItemInLimbSlot(InvSlotType.LeftHand)

  -- Check to see if NT is enabled
  if NT and not character.IsBot then -- Yes? Neurotrauma amputation time!     
    -- Check the hands for an item with the tag "mechanicalrepairtool" in sequence to avoid cutting off both arms at once. We are merciful. 
    if rightHandItem.HasTag("mechanicalrepairtool") then
      NT.TraumamputateLimb(character,LimbType.RightArm)
    elseif leftHandItem.HasTag("mechanicalrepairtool") then
      NT.TraumamputateLimb(character,LimbType.LeftArm)    
    end
  else
      --No? do something vanilla
      if rightHandItem.HasTag("mechanicalrepairtool") then        
        MT.HF.AddAfflictionLimb(character,"lacerations",LimbType.RightArm,100)
      elseif leftHandItem.HasTag("mechanicalrepairtool") then
        MT.HF.AddAfflictionLimb(character,"lacerations",LimbType.LeftArm,100)
      end
  end

end)

-- Average Component hook
Hook.Add("signalReceived.average_component", "MT.averageComponent", function(signal, connection)
    if buffer[connection.Item] == nil then buffer[connection.Item] = {} end

    local itemBuffer = buffer[connection.Item]
    local connectionSum = 0
    local connectionCount = 0
    if connection.Name == "*input_1" then
      itemBuffer[1] = signal.value
    end

    if connection.Name == "input_2" then
      itemBuffer[2] = signal.value
    end

    if connection.Name == "input_3" then
      itemBuffer[3] = signal.value
    end

    if connection.Name == "input_4" then
      itemBuffer[4] = signal.value
    end

    if connection.Name == "input_5" then
      itemBuffer[5] = signal.value
    end

    if connection.Name == "input_6" then
      itemBuffer[6] = signal.value
    end
  
  -- *input_1 is the trigger signal, we will only calculate and send the output when the trigger signal is received
  if itemBuffer[1] ~= nil then
    for k, v in pairs(itemBuffer) do        
      connectionSum = connectionSum + v
      connectionCount = connectionCount + 1
    end
    connection.Item.SendSignal(tostring(math.floor(connectionSum / connectionCount)), "output")
  end
  -- clear input_1 from storage so that the output will not be triggered until *input_1 is received again
  itemBuffer[1] = nil
end)


-- MEDICAL TABLET: Hematology Report
Hook.Add("medicalTablet_hR.OnUse", "MT.hematologyReport", function(effect, deltaTime, item, targets, worldPosition, client)
  --local containedItem = item.OwnInventory.GetItemAt(0)
  local terminal = MTUtils.GetComponentByName(item, ".Terminal")
  local bloodBankInventory = {}
  if CentralComputer.online then
    MT.HF.BlankTerminalLines(terminal, 20) -- create some space
    -- begin report
    MT.HF.SendTerminalColorMessage(item, terminal, Color(255, 35, 35, 255), "*******REPORT: HEMATOLOGY*******")        

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

  if SERVER then
    terminal.SyncHistory()
end

end)

-- MEDICAL TABLET: Pharmacy Report
Hook.Add("medicalTablet_pR.OnUse", "MT.pharmacyReport", function(effect, deltaTime, item, targets, worldPosition, client)
  --local containedItem = item.OwnInventory.GetItemAt(0)  
  local terminal = MTUtils.GetComponentByName(item, ".Terminal")
  local pharmacyInventory = {}
  --local itemStack = {}
  if CentralComputer.online then
    MT.HF.BlankTerminalLines(terminal, 20) -- create some space
    -- begin report
    MT.HF.SendTerminalColorMessage(item, terminal, Color(200, 35, 35, 255), "*******REPORT: PHARMACY*******")        
    
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

end)


-- MAINTENANCE TABLET
Hook.Add("maintenanceTablet_pcr.OnUse", "MT.powerConsumptionReport", function(effect, deltaTime, item, targets, worldPosition, client)
 
  local terminal = MTUtils.GetComponentByName(item, ".Terminal")
  local poweredList = {}
  local totalPowerConsumption = 0
  local hull = "ERROR"
  --print(item.GetComponent.Powered())
  
  if CentralComputer.online then
    MT.HF.BlankTerminalLines(terminal, 20)
    MT.HF.SendTerminalColorMessage(item, terminal, Color(0, 255, 0, 255), "*******REPORT: GRID POWER CONSUMPTION*******")
  
    for k, item in pairs(Item.ItemList) do
      if item.FindHull() ~= nil then hull = item.FindHull().DisplayName.Value else hull = "EXTERIOR"  end    
      local poweredComponent = MTUtils.GetComponentByName(item, "Powered")
      if poweredComponent ~= nil and poweredComponent.CurrPowerConsumption > 0.5 and item.HasTag("fusebox") == false then
        totalPowerConsumption = totalPowerConsumption + poweredComponent.CurrPowerConsumption           
        table.insert(poweredList, item)
      end 
    end

    table.sort(poweredList, function (k1, k2) return MTUtils.GetComponentByName(k1, ".Powered").CurrPowerConsumption < MTUtils.GetComponentByName(k2, "Powered").CurrPowerConsumption end )

    for k, item in pairs(poweredList) do
      hull = "ERROR"
      if item.FindHull() ~= nil then hull = item.FindHull().DisplayName.Value end      
      terminal.ShowMessage = "[Power: " .. MT.HF.Round(MTUtils.GetComponentByName(item, ".Powered").CurrPowerConsumption, 2) .. "kW | Fixture: " .. item.name .. " | Location: " .. hull .. "]"            
    end
    
    terminal.TextColor = Color(255, 69, 0, 255)
    terminal.ShowMessage = "-----------------TOTAL-----------------"
    terminal.ShowMessage = "ESTIMATED POWER CONSUMPTION:" .. MT.HF.Round(totalPowerConsumption, 2) .. "kW"
    terminal.ShowMessage = "**************END REPORT**************"
    terminal.TextColor = Color.Lime
  else
    terminal.ShowMessage = "**************NO CONNECTION**************"
  end

  if SERVER then
    terminal.SyncHistory()
end

end)


Hook.Add("maintenanceTablet_csr.OnUse", "MT.co2FilterStatusReport", function(effect, deltaTime, item, targets, worldPosition, client)
  --local containedItem = item.OwnInventory.GetItemAt(0)
  local terminal = MTUtils.GetComponentByName(item, ".Terminal")
  local co2FilterList = {}
  local co2FilterCount = 0
  local co2FilterExpiredCount = 0
  local oxygenVentCount = 0
  local filterLocation
  
  
  if CentralComputer.online then
    MT.HF.BlankTerminalLines(terminal, 20) -- create some space
    -- begin report
    MT.HF.SendTerminalColorMessage(item, terminal, Color(0, 255, 0, 255), "*******REPORT: CO2 FILTER STATUS*******")        
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

    terminal.TextColor = Color.Lime
    terminal.ShowMessage = "------------------------------"
    terminal.ShowMessage = "TOTAL FILTERED OXYGEN VENTS:" .. oxygenVentCount
    terminal.ShowMessage = "Co2 FILTERS EXPIRED:" .. co2FilterExpiredCount
    terminal.ShowMessage = "Co2 FILTERS MISSING:" .. oxygenVentCount - co2FilterCount
    terminal.ShowMessage = "**************END REPORT**************"
  

  else
    terminal.ShowMessage = "**************NO CONNECTION**************"
  end

  if SERVER then
    terminal.SyncHistory()
end

end)

Hook.Add("maintenanceTablet_pr.OnUse", "MT.ballastPumpReport", function(effect, deltaTime, item, targets, worldPosition, client)
  --local containedItem = item.OwnInventory.GetItemAt(0)
  local terminal = MTUtils.GetComponentByName(item, ".Terminal")
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
    MT.HF.SendTerminalColorMessage(item, terminal, Color(65, 115, 205, 255), "*******REPORT: WATER PUMP STATUS*******")    
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

  if SERVER then
    terminal.SyncHistory()
end
end)


Hook.Add("maintenanceTablet_fsr.OnUse", "MT.fuseStatusReport", function(effect, deltaTime, item, targets, worldPosition, client)
  -- terminal goodness
  local terminal = MTUtils.GetComponentByName(item, ".Terminal")
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
    MT.HF.SendTerminalColorMessage(item, terminal, Color(0, 255, 0, 255), "*******REPORT: FUSE STATUS*******")    
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
            terminal.TextColor = Color(255, 69, 0, 255)
            terminal.ShowMessage = "[!NO FUSE!] Fixture: " .. item.name .. " Location: " .. fuseLocation  
            terminal.TextColor = Color.Lime
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
        terminal.TextColor = Color(255, 69, 0, 255)
        weakFuses = weakFuses + 1 
      elseif fuse.ConditionPercentage < fuseYellowCondition then
        terminal.TextColor = Color.Yellow
      else
        terminal.TextColor = Color.Lime
      end

      terminal.ShowMessage = "Fuse at: " .. MT.HF.Round(fuse.ConditionPercentage, 2) .. "% in: " .. fuseLocation      
    end
    terminal.TextColor = Color.Lime
    terminal.ShowMessage = "------------------------------"
    terminal.ShowMessage = "TOTAL FUSE BOXES:" .. fuseBoxCount
    if weakFuses > 0 then  terminal.TextColor = Color(255, 69, 0, 255) end
    terminal.ShowMessage = "FUSES WEAK:" .. weakFuses
    if fuseBoxCount - #fuseList > 1 then  terminal.TextColor = Color(255, 69, 0, 255) else  terminal.TextColor = Color.Lime end
    terminal.ShowMessage = "FUSES MISSING:" .. fuseBoxCount - #fuseList
    terminal.TextColor = Color(255, 69, 0, 255)
    terminal.ShowMessage = "**************END REPORT**************"    
  else
    terminal.ShowMessage = "**************NO CONNECTION**************"
  end
 
  if SERVER then    
    terminal.SyncHistory()
end

end)


--[[
Timer.Wait(function()
  if NTCyb ~= nil then
      NTCyb.ItemMethods.mechweldingtool = NTCyb.ItemMethods.weldingtool
  end
end,1000)
]]
