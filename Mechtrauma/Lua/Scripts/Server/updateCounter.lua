
MT.UpdateCooldown = 0
MT.UpdateInterval = 120
MT.Deltatime = MT.UpdateInterval/60 -- Time in seconds that transpires between updates

Hook.Add("think", "MT.update", function()
    if MT.HF.GameIsPaused() then return end

    MT.UpdateCooldown = MT.UpdateCooldown-1
    if (MT.UpdateCooldown <= 0) then
        MT.UpdateCooldown = MT.UpdateInterval
        MT.updateHumans()
        MT.updateItems() 
    end
end)
