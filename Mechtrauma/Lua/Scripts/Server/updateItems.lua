
-- define the cache table and counter
local mtuItems = {}
local mtuItemsCount = 0
local mtRoundStarted = false


Hook.Add("roundStart", "MT.roundStart", function()
    mtRoundStarted = true
    print("MT ROUND STARTED:", mtRoundStarted)
    
    -- this is how many mtuItems we found
    print("There are: ",#mtuItems, " mtu items.") 
    
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

--[[Biotrauma expansion functions  b
MT.BT.tagfunctions = {
oxygenVentSpawn={
        tags={"oxygenVentSpawn"},
        update=MT.BT.F.oxygenVentSpawn
    }
}
 Add Biotrauma expansion functions to the Mechtrauma tagfunctions table
print("This is happening")
for tagfunctiondata in BT.tagfunctions do
    table.insert(MT.tagfunctions, tagfunctiondata)
    print("Adding:", tagfunctiondata, " to: MT.tagfucntions" )
end]]


-- gets run once every two seconds
function MT.updateItems()  
    if not mtRoundStarted or MT.HF.GameIsPaused() then return end
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

    -- loop through the tag functions to see if we have a matching function for the item tags
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
            --print("found a:", item)
            tagfunctiondata.update(item)
        end
    end
--[[

        -- CHECK centralComputer
          if item.HasTag("centralcomputer") then            
            --print("central computer found: ", item.name)
            MT.F.centralComputer(item)   
            return
        end   
        

        -- CHECK centralComputerNeeded
        if item.HasTag("ccn") then          
            print("central computer needed by: ", item.name)        
            MT.F.centralComputerNeeded(item)   
            return
        end
            
        -- CHECK steam turbine
        if item.HasTag("steamturbine,steam") then            
            --print("steam turbine found: ", item.name)
            MT.F.steamTrubine(item)   
            return
        end

        -- CHECK pump_gate
        if item.HasTag("pumpgate") then            
            --deteriorate the gate
            --print(MT.Config.pumpGateDeteriorateRate)
            item.condition = item.condition - MT.Config.pumpGateDeteriorateRate -- this works, but strangely -10 results in -4 every 2 seconds.            
            return
        end
        -- DieselEngines
        if item.HasTag("dieselengine") then            
            MT.F.dieselEngine(item)
            return
        end

         CHECK: Diving Suit
        if item.HasTag("deepdiving") and MT.HF.ItemIsWornInOuterClothesSlot(item) then
            MT.F.divingSuit(item)
        return
        end  ]]    
end    

Hook.add("item.created", "MT.newItem", function(item) 
    -- loop through the item list and find mtu update items     
        if item.HasTag("mtu") then
            table.insert(mtuItems, item)
            mtuItemsCount = mtuItemsCount + 1
        end      

        if item.HasTag("diving") and item.HasTag("deepdiving") then
            table.insert(mtuItems, item)
            mtuItemsCount = mtuItemsCount + 1
        end      
end)

Hook.Add("roundEnd", "MT.roundEnd", function()
    -- clear the update item cache so we don't carry anything over accidentallu
    mtuItems = {}
    mtuItemsCount = 0
    -- track that the round is over
    mtRoundStarted = false

end)