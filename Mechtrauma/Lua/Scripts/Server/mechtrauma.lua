
-- a Lua table to put the connection.Item object into.
local buffer = {}


Hook.Add("signalReceived.water_pump", "MT.waterpumpGate", function(signal, connection, item)
    -- If the buffer is empty, populate it with connection.item
    if buffer[connection.Item] == nil then buffer[connection.Item] = {} end
    
    local itemBuffer = buffer[connection.Item]
    
    
    if connection.Name == "gate_in" then
        itemBuffer[1] = signal.value
    end

    if itemBuffer[1] ~= nil then
        local gateCondition = (tonumber(itemBuffer[1]) or 0)
        gateCondition = gateCondition * 0.01

        connection.Item.GetComponentString("Pump").MaxFlow = 600 * gateCondition
      --  print("Final maxFlow", connection.Item.GetComponentString("Pump").MaxFlow)
        
      --  print(connection.Item.Tags)
        itemBuffer[1] = nil
    end

    
end)


Hook.Add("mechtraumaAmputation.OnFailure", "MT.amputation", function(effect, deltaTime, item, targets, worldPosition)
  -- Check to see if NT is enabled
  if NT then 

    -- Yes? Neurotrauma amputation time! 
    character = targets[8]
    rightHandItem = character.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)
    leftHandItem = character.Inventory.GetItemInLimbSlot(InvSlotType.LeftHand)
    
    -- Check the hands for an item with the tag "mechanicalrepairtool" in sequence to avoid cutting off both arms at once. We are merciful. 
    if rightHandItem.HasTag("mechanicalrepairtool") then
      NT.TraumamputateLimb(targets[8],LimbType.RightArm)
    elseif leftHandItem.HasTag("mechanicalrepairtool") then
      NT.TraumamputateLimb(targets[8],LimbType.LeftArm)    
    end
  else  
       --No? do something vanilla   
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


Hook.Add("maintenanceTablet_pcr.OnUse", "MT.powerConsumptionReport", function(effect, deltaTime, item, targets, worldPosition, client)
 
  local terminal = item.GetComponentString("Terminal")
  local hull
  local totalPowerConsumption = 0
  --print(item.GetComponent.Powered())
  
  if CentralComputerOnline then
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    for k, item in pairs(Item.ItemList) do   
    if item.FindHull() ~= nil then hull = item.FindHull().DisplayName.Value else hull = "EXTERIOR"  end      
      if item.GetComponentString("Powered") ~= nil and item.GetComponentString("Powered").CurrPowerConsumption >0.5 then
        totalPowerConsumption = totalPowerConsumption + item.GetComponentString("Powered").CurrPowerConsumption           
        terminal.ShowMessage = "[Power: " .. item.GetComponentString("Powered").CurrPowerConsumption .. "| Fixture: " .. item.name .. "Hull: " .. hull .. "]"      
      end 
    end
    terminal.ShowMessage = "Estimated Power Consumption:" .. totalPowerConsumption
  else
    terminal.ShowMessage = "**************NO CONNECTION**************"
  end

  if SERVER then
    terminal.SyncHistory()
end

end)


Hook.Add("maintenanceTablet_csr.OnUse", "MT.co2FilterStatusReport", function(effect, deltaTime, item, targets, worldPosition, client)
  --local containedItem = item.OwnInventory.GetItemAt(0)
  local terminal = item.GetComponentString("Terminal")
  local co2FilterCount = 0
  local co2FilterExpiredCount = 0
  local oxygenVentCount = 0
  local hull
    
  if CentralComputerOnline then
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "*******REPORT: CO2 FILTER STATUS*******"
    for k, item in pairs(Item.ItemList) do   
      if item.Prefab.Identifier.Value == "oxygen_vent" then 
        oxygenVentCount = oxygenVentCount + 1
        if item.OwnInventory.GetItemAt(0) ~= nil then 
          co2FilterCount = co2FilterCount + 1
          if item.OwnInventory.GetItemAt(0).ConditionPercentage < 1 then co2FilterExpiredCount = co2FilterExpiredCount + 1 end
          if item.FindHull() ~= nil then hull = item.FindHull().DisplayName.Value else hull = "ERROR" end  
          terminal.ShowMessage = "Co2 Filter at: " .. MT.HF.Round(item.OwnInventory.GetItemAt(0).ConditionPercentage, 2) .. "% in: " .. hull  
        else 
          terminal.ShowMessage = "Co2 Filter missing in: " .. hull  
        end
      end
    end
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
  local terminal = item.GetComponentString("Terminal")
  local mtPumpCount = 0
  local pumpGateCount = 0
  local pumpGateCondition = 0
  local electricMotorCount = 0
  local brokenElectricMotorCount = 0  
  local hull
  
  if CentralComputerOnline then
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "-"
    terminal.ShowMessage = "*******REPORT: WATER PUMP STATUS*******"
    for k, item in pairs(Item.ItemList) do   
      -- Check for a mechtrauma pump tag. Avoiding identifiers for compatibility.
      if item.HasTag("mtpump") then        
        mtPumpCount = mtPumpCount + 1

        -- look for an Electric Motor in slot 0
        if item.OwnInventory.GetItemAt(0) ~= nil then           
          electricMotorCount = electricMotorCount + 1
          -- check if the Electric Motor is broken
          if item.OwnInventory.GetItemAt(0).ConditionPercentage < 1 then brokenElectricMotorCount = brokenElectricMotorCount + 1 end
          -- If it is sinside the sub grab the hull name, otherwise error.
          if item.FindHull() ~= nil then hull = item.FindHull().DisplayName.Value else hull = "ERROR" end  
          -- print the Pump with Electric Motor to the report
          terminal.ShowMessage = item.name .. ": " .. item.ConditionPercentage .. "% conditon in: " .. hull  
          terminal.ShowMessage = "--->  Electric Motor:" .. MT.HF.Round(item.OwnInventory.GetItemAt(0).ConditionPercentage, 2) .. "% condition."
          
        else 
          -- print the Pump WITHOUT an Electric Motor to the report
          terminal.ShowMessage = item.name .. ": " .. item.ConditionPercentage .. "% conditon in: " .. hull  
          terminal.ShowMessage = "--->  Electric Motor: MISSING"
        end
      -- Check for a mechtrauma pump gate tag. Avoiding identifiers for compatibility.
      elseif item.HasTag("pumpgate") then
        pumpGateCount = pumpGateCount + 1
        pumpGateCondition = pumpGateCondition + item.ConditionPercentage
      end
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



--[[
Timer.Wait(function()
  if NTCyb ~= nil then
      NTCyb.ItemMethods.mechweldingtool = NTCyb.ItemMethods.weldingtool
  end
end,1000)
]]
