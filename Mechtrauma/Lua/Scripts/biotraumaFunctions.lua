BT.F = {}

-- FUNGUS: Spawn fungus
function BT.F.oxygenVentSpawn(item)
    
    local fungusPrefab = ItemPrefab.GetItemPrefab("spore_fungus")
    --print(item.GetComponentString("Vent").OxygenFlow)
    --if disabled, do nothing.    
    if MT.Config.ventSpawnRate > 0 and item.GetComponentString("Vent").OxygenFlow > 0 then
        -- spawn events take OxygenVentCount into consideration because spawn events are calculated per vent every update
        -- probability: target spawns per hour / spawn chances per hour
        print(MT.Config.ventSpawnRate,"/",(3600 / MT.Deltatime * OxygenVentCount))
        if MT.HF.Probability(MT.Config.ventSpawnRate, (3600 / MT.Deltatime * OxygenVentCount)) then
            Entity.Spawner.AddItemToSpawnQueue(fungusPrefab, item.OwnInventory, nil, nil, function(item) end)
            print("SPAWNED FUNGUS!")
        end
    end
end