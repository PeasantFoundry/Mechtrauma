local mtRoundStarted

Hook.Add("roundStart", "MT.roundStart", function()
    mtRoundStarted = true
    print("MT ROUND STARTED:", mtRoundStarted)
    
    -- this is how many items we found in the MT.itemCache
    print("There are: ", MT.itemCacheCount, " items in the MT.itemCache.") 
   
    -- check how many oxygenvents there are so that we only do it once per round. 
    for k, item in pairs(Item.ItemList) do   
        if item.Prefab.Identifier.Value == "oxygen_vent" then 
            OxygenVentCount = OxygenVentCount + 1            
        end
    end       
end)

--table of tag functions - this is for mapping items to update functions
MT.tagfunctions = {
    divingSuit={
        tags={"deepdiving","diving"},
        update=MT.F.divingSuit,        
    },
    centralComputer={
        tags={"centralcomputer"},
        update=MT.F.centralComputer
    },
    centralComputerNeeded={
        tags={"ccn"},
        update=MT.F.centralComputerNeeded
    },
    steamTurbine={
        tags={"steamturbine"},
        update=MT.F.steamTurbine
    },
    oxygenVentSpawn={ --move to BT function table some day
        tags={"oxygenVentSpawn"},
        update=BT.F.oxygenVentSpawn,        
    }
  }

-- gets run once every two seconds
function MT.updateItems()    
    local updateItemsCounter = 0
    if Game.GameSession == nil or MT.HF.GameIsPaused()then return end
   
   -- we spread the item updates out over the duration of an update so that the load isnt done all at once
    for key, value in pairs(MT.itemCache) do
        -- make sure the items still exists 
        if (key ~= nil and not key.Removed) then
            Timer.Wait(function ()
                if (key ~= nil and not key.Removed) then 
                    MT.UpdateItem(key) 
                    updateItemsCounter = updateItemsCounter + 1
                end

            end, ((updateItemsCounter + 1) / MT.itemCacheCount) * MT.Deltatime * 1000)
        end
    end
end

-- this function is called once for each item in MT.itemCache every two seconds
function MT.UpdateItem(item)
    -- loop through the tag functions to see if we have a matching function for the item tag(s)
    for tagfunctiondata in MT.tagfunctions do
        -- see if all required tags are present on the item
        local hasalltags = true
        for tag in tagfunctiondata.tags do
            if not item.HasTag(tag) then
                hasalltags = false
                break
            end
        end
        -- call the function if all required tags are present
        if hasalltags then            
            tagfunctiondata.update(item)
        end
    end

end    

-- check new items and add matches to the MT.itemCache
Hook.add("item.created", "MT.newItem", function(item) 
      -- check if this item should be added to the item cache     
        if item.HasTag("mtu") then
            if not MT.itemCache[item] then 
                MT.itemCache[item] = true
                MT.itemCacheCount = MT.itemCacheCount + 1
            end
        elseif item.HasTag("diving") and item.HasTag("deepdiving") then -- I don't like this
            if not MT.itemCache[item] then 
                MT.itemCache[item] = true 
                MT.itemCacheCount = MT.itemCacheCount + 1
            end                        
        end  
end)

-- end of round housekeeping
Hook.Add("roundEnd", "MT.roundEnd", function()
    -- clear the update item cache so we don't carry anything over accidentally
    MT.itemCache = {}    
    MT.itemCacheCount = 0
    -- track that the round is over
    mtRoundStarted = false
end)