
MT.UpdateCooldown = 0
MT.UpdateInterval = 120
MT.Deltatime = MT.UpdateInterval/60 -- Time in seconds that transpires between updates

-- define the cache table and counter
local mtuItems = {}
local mtuItemsCount = 0
local roundStatus = 0
local debugA = 1 
Hook.Add("roundStart", "MT.mtuItemCache", function()
    roundStatus = 1
 
    
    -- loop through the item list and find mtu update items
    for k, item in pairs(Item.ItemList) do              
        if item.HasTag("mtu") then
            table.insert(mtuItems, item)
            mtuItemsCount = mtuItemsCount + 1
        end    
    end

    -- this is how many we found
    print("There are: ",mtuItemsCount, " mtu items.") 
    
    --[[ these are the item names
    for k, v in pairs(mtuItems) do
        print(v.name)        
    end]]

end)
  
Hook.Add("think", "MT.updateItems", function()   
    if roundStatus == 0 then return end
       
    --if debugA == 1 then print("MT.updateItems hook is responding") end
    --debugA = debugA +1 
    
    MT.UpdateCooldown = MT.UpdateCooldown-1
    if (MT.UpdateCooldown <= 0) then
        MT.UpdateCooldown = MT.UpdateInterval
        MT.updateItems() 
    end
 
end)

-- gets run once every two seconds
function MT.updateItems()  
    print("--thinking--")
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
    -- some harmless debugging 
    --print("MT.UpdateItem function call successufl for item: ", item.name)
        -- We are going to have a furious amount of checks here. 


        -- CHECK pump_gate
        if item.HasTag("pumpgate") then
            
            --deteriorate the gate
            item.condition = item.condition -10 -- this works, but strangely -10 results in -4 every 2 seconds.
        end
                   
        if item.HasTag("deepdiving") then            
            if MT.HF.ItemIsWornInOuterClothesSlot(item) then          
                    print("We have a diving/deepdiving item! ", item.name)        
                    print("condition: ", item.condition)
                    item.condition = item.condition -1
            end  
        end       
end    
