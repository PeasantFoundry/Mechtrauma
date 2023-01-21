
-- Establish Mechtrauma item cache
MT.itemCache = {}
MT.itemCacheCount = 0
MT.oxygenVentCount = 0

--table of tag functions - this is for mapping items to update functions
MT.tagfunctions = {
    divingSuit={
        tags={"deepdiving","diving"},
        update=MT.F.divingSuit      
    },
    fuseBox={ 
        tags={"fusebox"},
        update=MT.F.fuseBox
    },
    oxygenVentSpawn={ --move to BT function table some day
        tags={"oxygenventspawn"},
        update=BT.F.oxygenVentSpawn
    },
    centralComputerNeeded={
        tags={"ccn"},
        update=MT.F.centralComputerNeeded
    },
    --dieselGenerator={
    --    tags={"dieselGenerator"},
    --    update=MT.F.dieselGenerator
    --},
    steamBoiler={
        tags={"steamBoiler"},
        update=MT.F.steamBoiler
    },
    steamTurbine={
        tags={"steamturbine"},
        update=MT.F.steamTurbine
    },
    reductionGear={
        tags={"reductionGear"},
        update=MT.F.reductionGear
    },
    centralComputer={
        tags={"centralcomputer"},
        update=MT.F.centralComputer
    },
    keyIgnition={
        tags={"keyignition"},
        update=MT.F.keyIgnition
    }
}

-- run once per MT.Deltatime (2 seconds) by updateCounter.lua
function MT.updateItems()
    local updateItemsCounter = 0

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

-- called once for each item in MT.itemCache 
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

-- adds eligible items to the item cache
function MT.CacheItem(item)
    
    if not MT.itemCache[item] then
        -- CHECK: should this item be in the cache
       if item.HasTag("mtu") or item.HasTag("mtupdate") then
        -- CHECK: if the item is already in the cache, if not - add it.   
            MT.itemCache[item] = {}
            MT.itemCache[item].counter = 0
            MT.itemCacheCount = MT.itemCacheCount + 1

            -- this is here so that we don't double up execute on initialization and item creation
            if item.Prefab.Identifier.Value == "oxygen_vent" then 
                -- count the oxygen vents when you populate the cache               
                MT.oxygenVentCount = MT.oxygenVentCount + 1
            end

        elseif item.HasTag("diving") and item.HasTag("deepdiving") then -- I don't like this but it's for compatability
                MT.itemCache[item] = {}
                MT.itemCache[item].counter = 0
                MT.itemCacheCount = MT.itemCacheCount + 1        
        end
        
    end
end


    -- INITIALIZATION: loop through the item list and and cache eligible items
    for k, item in pairs(Item.ItemList) do
        MT.CacheItem(item)
    end
 
    --[[ INITIALIZATION: loop through the item list and count the oxygen vents
    for k, item in pairs(Item.ItemList) do
        if item.Prefab.Identifier.Value == "oxygen_vent" then 
            print(item)
            oxygenVentCount = oxygenVentCount + 1
        end
    end]]
    


 Hook.Add("roundStart", "MT.roundStart2", function()
    
    -- this is how many items we found in the MT.itemCache
    print("There are: ", MT.itemCacheCount, " items in the MT.itemCache.")     
    print("There are: ", MT.oxygenVentCount, " oxygen vents.")
 end)

 -- check new items and add matches to the MT.itemCache
 Hook.add("item.created", "MT.newItem", function(item)
     MT.CacheItem(item)
 end)
 
 -- end of round housekeeping
 Hook.Add("roundEnd", "MT.roundEnd", function()
     -- clear the update item cache so we don't carry anything over accidentally
     MT.itemCache = {}
     MT.itemCacheCount = 0
     -- track that the round is over
     
 end)
 