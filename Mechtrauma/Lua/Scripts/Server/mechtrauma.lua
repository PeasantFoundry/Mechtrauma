
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

--[[
Timer.Wait(function()
  if NTCyb ~= nil then
      NTCyb.ItemMethods.mechweldingtool = NTCyb.ItemMethods.weldingtool
  end
end,1000)
]]
