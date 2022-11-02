
-- a Lua table to put the connection.Item object into.
local buffer = {}
local t = {}

Hook.Add("signalReceived.water_pump", "examples.Mechtrauma", function(signal, connection, item)
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


Hook.Add("mechtraumaAmputation.OnFailure", "scripts.Mechtrauma", function(effect, deltaTime, item, targets, worldPosition)
  --At long last! A lua amputation!
  
  NT.TraumamputateLimb(targets[8],LimbType.RightArm)

end)

-- Average Component hook
Hook.Add("signalReceived.average_component", "scripts.Mechtrauma", function(signal, connection)
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
