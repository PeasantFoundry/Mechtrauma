BT.F = {}

-- FUNGUS: Spawn fungus
function BT.F.oxygenVentSpawn(item)
    
    local fungusPrefab = ItemPrefab.GetItemPrefab("spore_fungus")
    
    if MT.Config.ventSpawnRate > 0 then
        -- Scale the range to account for how many spawnable vents each sub has
        -- OxygenVentCount/MT.Deltatime = chances per second
        -- OxygenVentCount/MT.Deltatime * 3600 = chances per hour
        -- 1.0 (Standard) difficulty will target 1 aproxximately fungus spawn per hour (I know there is a differnce statically between 1/4x2 and 1/2x1 but I don't care here.)
        -- local chance = 
        -- local outcome = math.random(range)

        if MT.HF.Chance( 1 / ((3600/MT.Deltatime) * OxygenVentCount) * (2-MT.Config.ventSpawnRate))
  
then
  print("schrooms")
end

        if outcome == 666 then
            --print("sucess, spawning an item with an outcome of:", outcome)
            Entity.Spawner.AddItemToSpawnQueue(fungusPrefab, item.OwnInventory, nil, nil, function(item) end)
        else         
            --print("failure, not spawning an item with an outcome of:", outcome)
            --print(item.GetComponentString("ItemContainer"))      
        end    
    end

end