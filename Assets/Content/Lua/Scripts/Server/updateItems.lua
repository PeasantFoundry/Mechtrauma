
-- Establish Mechtrauma item cache
--MT.itemCache = {}
--MT.itemCacheCount = 0
--MT.inventoryCache = {parts={}}
--MT.inventoryCacheCount = 0
-- Establish Mechtrauma item cache
MT.itemCache = {}
MT.itemCacheCount = 0
MT.inventoryCache = {parts={}}
MT.inventoryCacheCount = 0
MT.PriorityItemCache = {}
MT.ambientTemperature = 60

MT.oxygenVentCount = 0

--table of tag functions - this is for mapping items to update functions
MT.tagfunctions = {
    airFilter={
        tags={"airFilter"},
        update=MT.UF.airFilter
    },
    centralComputer={
        tags={"centralcomputer"},
        update=MT.UF.centralComputer
    },
    centralComputerNeeded={
        tags={"ccn"},
        update=MT.UF.centralComputerNeeded
    },
    crankAssembly={
        tags={"crankAssembly"},
        update=MT.UF.crankAssembly
    },
    coolant={
        tags={"coolant"},
        update=MT.UF.coolant
    },
    cylinderHead={
        tags={"cylinderHead"},
        update=MT.UF.cylinderHead
    },
    dieselEngine={
        tags={"dieselEngine"},
        update=MT.UF.dieselEngine
    },
    dieselGenerator={
        tags={"dieselGenerator"},
        update=MT.UF.dieselGenerator
    },
    divingSuit={
        tags={"deepdiving","diving"},
        update=MT.UF.divingSuit
    },
    electricalDisconnect={
        tags={"electricalDisconnect"},
        update=MT.UF.electricalDisconnect
    },
    engineBlock={
        tags={"engineBlock"},
        update=MT.UF.engineBlock
    },
    exhaustManifold={
        tags={"exhaustManifold"},
        update=MT.UF.exhaustManifold
    },
    fuseBox={
        tags={"fusebox"},
        update=MT.UF.fuseBox
    },
    gasket={
        tags={"gasket"},
        update=MT.UF.gasket
    },
    heatExchanger={
        tags={"heatExchanger"},
        update=MT.UF.heatExchanger
    },
    heatExchangercore={
        tags={"heatExchangerCore"},
        update=MT.UF.heatExchangerCore
    },
    keyIgnition={
        tags={"keyignition"},
        update=MT.F.keyIgnition
    },
    mechanicalClutch={
        tags={"mechanicalClutch"},
        update=MT.UF.mechanicalClutch
    },
    oxygenVentSpawn={ --move to BT function table some day
        tags={"oxygenventspawn"},
        update=BT.F.oxygenVentSpawn
    },
    reductionGear={
        tags={"reductionGear"},
        update=MT.UF.reductionGear
    },
    steamBoiler={
        tags={"steamBoiler"},
        update=MT.UF.steamBoiler
    },
    steamHeatsink={
        tags={"steamHeatsink"},
        update=MT.UF.steamHeatsink
    },
    steamTurbine={
        tags={"steamturbine"},
        update=MT.UF.steamTurbine
    },
    steamValve={
        tags={"steamValve"},
        update=MT.UF.steamValve
    },
}

MT.itemSpawnEvents = {
    cheapDieselFuel={
        tags={"cheapdieselfuel"},
        update=MT.F.purchasedItemFaults
    }
}
-- run once per MT.PriorityDeltatime (.25 seconds) by updateCounter.lua
function MT.updatePriorityItems()
    local updateItemsCounter = 0
   -- we spread the item updates out over the duration of an update so that the load isnt done all at once
    for key, value in pairs(MT.PriorityItemCache) do
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
    -- populate the item update cache
    if not MT.itemCache[item] then
        -- CHECK: should this item be in the cache
       if item.HasTag("mtu") or item.HasTag("mtupdate") then
        -- CHECK: if the item is already in the cache, if not - add it.
            MT.itemCache[item] = {}
            MT.itemCache[item].counter = 0
            if item.HasTag("diagnostics") then MT.itemCache[item].diagnosticData ={errorCodes={},warningCodes={},statusCodes={}} end
            if item.HasTag("mtc") and not MT.C.HD[item] then

                --MT.C.HD[item].MTC = MT.C.buildMTC(item)
                MT.C.HD[item] = {MTC=MT.C.buildMTC(item)}
                print(tostring(MT.C.HD[item].MTC))
            end
            MT.itemCacheCount = MT.itemCacheCount + 1

            -- this is here so that we don't double up execute on initialization and item creation -- I don't remember why this is a thing 1/5/2024
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
    -- populate the parts inventory
    if not MT.inventoryCache[item] then
        -- add the parts to the inventoryCache
        if item.HasTag("part") then
            MT.inventoryCache.parts[item] = {}
            MT.inventoryCacheCount = MT.inventoryCacheCount + 1
            --print("added ", item.Prefab.Identifier.Value, " to the parts inventory.")
        end
    end
end
-- remove items from the inventoryCache when they are deleted
function MT.RemoveCacheItem(item)
    if MT.inventoryCache[item] then table.remove(MT.inventoryCache,item) end
end

function MT.itemSpawnEvent(item)
    if item.HasTag("spawnevent") then
        print("SPAWN EVENT DETECTED!")
        for itemSpawnEvent in MT.itemSpawnEvents do
            print(tostring(itemSpawnEvent))
            -- see if all required tags are present on the item
            local hasalltags = true
            for tag in itemSpawnEvent.tags do
                if not item.HasTag(tag) then
                    hasalltags = false
                    break
                end
            end
            -- call the function if all required tags are present
            if hasalltags then
                itemSpawnEvent.update(item)
            end
        end
    end
end

-- -------------------------------------------------------------------------- --
--                               INITIALIZATION                               --
-- -------------------------------------------------------------------------- --
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
    -- -------------------------------------------------------------------------- --
    --                            LOAD MTC HARD DRIVES                            --
    -- -------------------------------------------------------------------------- --
    --if File.Exists(MT.Path .. "/MTCHD.json") then MT.C.HD = json.parse(File.Read(MT.Path .. "/MTCHD.json")) end

    -- this is how many items we found in the MT.itemCache
    print("There are: ", MT.itemCacheCount, " items in the MT.itemCache.")
    print("There are: ", MT.oxygenVentCount, " oxygen vents.")
 end)


-- new items
Hook.add("item.created", "MT.newItem", function(item)
    -- maintain the item cache
    MT.CacheItem(item)
    if item.HasTag("spawnevent") then MT.itemSpawnEvent(item) end
 end)

-- item removed
Hook.add("item.removed", "MT.removeItem", function(item)
    -- maintain the item cache
    MT.RemoveCacheItem(item)
end)
 -- end of round housekeeping
 Hook.Add("roundEnd", "MT.roundEnd", function()
     -- clear the update item cache so we don't carry anything over accidentally
     MT.itemCache = {}
     MT.itemCacheCount = 0

    -- -------------------------------------------------------------------------- --
    --                            STORE MTC HARD DRIVES                           --
    -- -------------------------------------------------------------------------- --
    File.Write(MT.Path .. "/MTCHD.json", json.serialize(MT.C.HD))

 end)

