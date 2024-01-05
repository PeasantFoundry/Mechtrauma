-- centralized counter for both human and item updates
MT.UpdateCooldown = 0
MT.UpdateInterval = 120
MT.Deltatime = MT.UpdateInterval/60 -- Time in seconds that transpires between updates

MT.PriorityUpdateCooldown = 0
MT.PriorityUpdateInterval = 15
MT.PriorityDeltatime = MT.UpdateInterval/60 -- Time in seconds that transpires between updates


Hook.Add("think", "MT.update", function()
    
    

    -- only run updates if the game is running        
    if MT.HF.GameIsRunning() then

        MT.PriorityUpdateCooldown = MT.PriorityUpdateCooldown-1
        if (MT.PriorityUpdateCooldown <= 0) then
            MT.PriorityUpdateCooldown = MT.PriorityUpdateInterval
            MT.updatePriorityItems()
end
        MT.UpdateCooldown = MT.UpdateCooldown-1
        if (MT.UpdateCooldown <= 0) then
            MT.UpdateCooldown = MT.UpdateInterval
            MT.updateHumans()
            MT.updateItems()

        end
    end
end)



