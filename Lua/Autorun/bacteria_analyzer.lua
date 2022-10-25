
local fungusPrefab = ItemPrefab.GetItemPrefab("spore_fungus")
local samplePrefab = ItemPrefab.GetItemPrefab("bacterial_sample_a4")

Hook.Add("mechtraumaBacteriaAnalyze.OnUse", "examples.Mechtrauma", function(effect, deltaTime, item, targets, worldPosition, client)
            
        local outcome = math.random(250)
        local terminal = item.GetComponentString("Terminal")


        if outcome > 0 then
        --print("sucess, spawning an item with an outcome of:", outcome)
            Entity.Spawner.AddItemToSpawnQueue(samplePrefab, item.OwnInventory, nil, nil, function(item) end)
            terminal.ShowMessage = "*******POSITIVE*******"
            terminal.ShowMessage = "Compound A4 has been identified in sample tube."             
                        
            if SERVER then
                terminal.SyncHistory()
            end
            
          
        else
            terminal.ShowMessage = "*******NEGATIVE*******"
            terminal.ShowMessage = "No known compound has been identified."    

        print("failure, not spawning an item with an outcome of:", outcome)
        print(item.GetComponentString("ItemContainer"))      
        end    
  
end)

