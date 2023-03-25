BT.F = {}

-- FUNGUS: Spawn fungus
function BT.F.oxygenVentSpawn(item)
    
    local fungusPrefab = ItemPrefab.GetItemPrefab("spore_fungus")
    
    --if disabled in config do nothing.    
    if MT.Config.VentSpawnRate > 0 and MTUtils.GetComponentByName(item, "Vent").OxygenFlow > 0 then
        -- spawn events take MT.oxygenVentCount into consideration because spawn event probability is shared between the vents
        -- probability: target spawns per hour / spawn chances per hour
        
        -- DEBUG PRINTING:
        -- print(MT.Config.ventSpawnRate,"/",(3600 / MT.Deltatime * MT.oxygenVentCount))
        if MT.HF.Probability(MT.Config.VentSpawnRate, (3600 / MT.Deltatime * MT.oxygenVentCount)) then
            Entity.Spawner.AddItemToSpawnQueue(fungusPrefab, item.OwnInventory, nil, nil, function(item) end)
            
        end
    end
end