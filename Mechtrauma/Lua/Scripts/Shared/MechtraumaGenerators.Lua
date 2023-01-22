local test_start = nil
local update_cycles = 0
local time_elapsed = 0
local counter = 0

MT.GridUpdateCooldown = 0
MT.GridUpdateInterval = 1
MT.GridDeltatime = MT.GridUpdateInterval/60 -- Time in seconds that transpires between updates



Hook.Patch(
  "Barotrauma.Items.Components.SimpleGenerator",
  "GetCurrentPowerConsumption",
  function(instance, ptable)
    instance.PowerConsumption = 0
  
    -- Return -1 if the generator should provide power
    if instance.IsOn then
      return -1
    end
    return 0
  end, Hook.HookMethodType.After)

Hook.Patch(
  "Barotrauma.Items.Components.SimpleGenerator",
  "MinMaxPowerOut",
  function(instance, ptable)
    load = ptable["load"]
    
    -- Set power consumption
    if MT.itemCache[instance.item].PowerConsumption ~= nil then
        instance.PowerConsumption = MT.itemCache[instance.item].PowerConsumption
    else
        instance.PowerConsumption = 0
    end
    
  end, Hook.HookMethodType.Before)


--[[
  MT.GridUpdateCooldown = MT.GridUpdateCooldown-1
  if (MT.GridUpdateCooldown <= 0) then
      MT.GridUpdateCooldown = MT.GridUpdateInterval
  end        ]]

   --[[ debug testing
   if test_start == nil then test_start = os.time() else time_elapsed = (test_start - os.time()) * -1 end
   print("TIME ELAPSED: ", MT.HF.Round(test_start - os.time(), 2)*-1)
   update_cycles = update_cycles + 1
   print("UPDATE CYCLES - EXPECTED/ACTUAL: ", MT.HF.Round(time_elapsed * 60,0), "/", update_cycles)
   
   ]]