
local fungusPrefab = ItemPrefab.GetItemPrefab("spore_fungus")

Hook.Add("mechtraumaVentInterval.OnActive", "examples.Mechtrauma", function(effect, deltaTime, item, targets, worldPosition, client)
        
    
        local outcome = math.random(10000)

        if outcome == 666 then
       -- print("sucess, spawning an item with an outcome of:", outcome)
            Entity.Spawner.AddItemToSpawnQueue(fungusPrefab, item.OwnInventory, nil, nil, function(item) end)
        else
             
       -- print("failure, not spawning an item with an outcome of:", outcome)
       -- print(item.GetComponentString("ItemContainer"))      
        end    
  
end)

