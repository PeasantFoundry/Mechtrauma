
-- define the cache table and counter
local mtuItems = {}
local mtuItemsCount = 0
local mtroundStarted = false

Hook.Add("roundStart", "MT.mtuItemCache", function()
    mtroundStarted = true
    print("MT ROUND STARTED:", mtroundStarted)
    -- loop through the item list and find mtu update items
    for k, item in pairs(Item.ItemList) do              
        if item.HasTag("mtu") then
            table.insert(mtuItems, item)
            mtuItemsCount = mtuItemsCount + 1
        end    
    end

    -- this is how many we found
    print("There are: ",mtuItemsCount, " mtu items.") 
       
end)

-- gets run once every two seconds
function MT.updateItems()  
    --print("--thinking--")
    
    -- we spread the *items* out over the duration of an update so that the load isnt done all at once
    for key, value in pairs(mtuItems) do
        -- make sure the items still exists 
        if (value ~= nil and not value.Removed) then
            Timer.Wait(function ()
                if (value ~= nil and not value.Removed) then
                MT.UpdateItem(value) end
            end, ((key + 1) / mtuItemsCount) * MT.Deltatime * 1000)
        end
    end
end

-- this function is called in a per item basis
function MT.UpdateItem(item)
        -- We are going to have a furious amount of checks here. Try to put the most common at the top? Probably could do some data logging later to see what's the most common.
        
        -- CHECK pump_gate
        if item.HasTag("pumpgate") then            
            --deteriorate the gate
            --print(MT.Config.pumpGateDeteriorateRate)
            item.condition = item.condition - MT.Config.pumpGateDeteriorateRate -- this works, but strangely -10 results in -4 every 2 seconds.            
            return
        end
        -- DieselEngines
        if item.HasTag("DieselEngine") then            
            MT.F.dieselEngine(item)
            return
        end

        -- CHECK: Diving Suit
        if item.HasTag("deepdiving") and MT.HF.ItemIsWornInOuterClothesSlot(item) then
            MT.F.divingSuit(item)
        return
        end       
end    

Hook.Add("roundEnd", "MT.mtuItemCacheClear", function()
    
    mtuItems = {}
    mtuItemsCount = 0
    mtroundStarted = false

end)