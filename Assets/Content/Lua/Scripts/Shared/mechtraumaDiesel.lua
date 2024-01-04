MT.DF = {}

function MT.DF.airFilterCheck(item, dieselSeries, airFilter)
    local airFilterCheck = true -- defaults to true for dieselSeries with no airFilter

    -- did I get wet?
    if item.InWater and airFilter ~= nil then
        airFilter.AddTag("water")
        MT.itemCache[airFilter].counter = 15 -- airFilter will dry out after ~30 seconds
    end

    if dieselSeries.airFilterLocation and item.InWater == false then
        -- airFilter required
        if airFilter == nil then
            table.insert(MT.itemCache[item].diagnosticData.warningCodes, "*DC1011: NO AIR FILTER*")
            airFilterCheck = false
        elseif airFilter.ConditionPercentage < 1 or airFilter.HasTag("blocked") then
            airFilterCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1012: AIR FILTER BLOCKED*")
        elseif airFilter.HasTag("water") then
            airFilterCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1012: AIR FILTER BLOCKED*")
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1013: AIR FILTER WET*")
        end
    end
    return airFilterCheck
end

function MT.DF.compressionCheck(item, dieselSeries, engineBlock, cylinderHead, crankAssembly)
    local compressionCheck = true -- defaults to true for dieselSeries with no engineBlock
    if dieselSeries.engineBlockLocation then
        if engineBlock == nil or cylinderHead == nil or crankAssembly == nil then
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1018: FAILED COMPRESSION CHECK*")
            compressionCheck = false
        elseif engineBlock.ConditionPercentage < 1 or engineBlock.HasTag("cracked") or cylinderHead.ConditionPercentage < 1 or crankAssembly.ConditionPercentage < 1 then
            compressionCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1018: FAILED COMPRESSION CHECK*")
        end
    end
    return compressionCheck
end

-- (DTC) P0385 stands for “Crankshaft Position Sensor B Circuit Malfunction.”
function MT.DF.dcmCheck(item, dieselSeries, dcm, oxygenSensor, pressureSensor)
    local dcmCheck = {dcm = true, oxygenSensor = true, pressureSensor = true} -- defualt to true for dieselSeries with no dcm
    if dcm == nil or dcm.ConditionPercentage < 1 then
        dcmCheck.dcm = false
        dcmCheck.oxygenSensor = false
        dcmCheck.pressureSensor = false
    else
        if oxygenSensor == nil or oxygenSensor.ConditionPercentage < 1 then dcmCheck.oxygenSensor = false end
        if pressureSensor == nil or pressureSensor.ConditionPercentage < 1 then dcmCheck.pressureSensor = false end
    end
    return dcmCheck
end

function MT.DF.exhaustCheck(item, dieselSeries, exhaustManifold, exhaustManifoldGasket)
    local exhaustCheck
    -- exhaustCheck - this needs to be moved to after combustion...
    if dieselSeries.exhaustManifoldLocation then
        if exhaustManifold == nil then
            --no exhaustManifold - vent exhaust into hull
            table.insert(MT.itemCache[item].diagnosticData.warningCodes, "*DC1016: EXHAUST LEAK - LARGE*")
        elseif exhaustManifold.ConditionPercentage < 30 and exhaustManifold.ConditionPercentage > 5 then
            table.insert(MT.itemCache[item].diagnosticData.warningCodes, "*DC1017: EXHAUST LEAK*")
        elseif exhaustManifold.ConditionPercentage < 5 then
            table.insert(MT.itemCache[item].diagnosticData.warningCodes, "*DC1016: EXHAUST LEAK - LARGE*")
        else
            -- no leak
        end
        if exhaustManifoldGasket == nil then
            -- no exhaustManifoldGasket
            table.insert(MT.itemCache[item].diagnosticData.warningCodes, "*DC1017: EXHAUST LEAK*")
        elseif exhaustManifoldGasket.ConditionPercentage < 50 then
            -- exhaustManifoldGasket leak
            table.insert(MT.itemCache[item].diagnosticData.warningCodes, "*DC1018: EXHAUST LEAK - SMALL*")
        else
            -- no exhaustManifoldGasket leak
        end
    end
    return exhaustCheck
end

function MT.DF.dieselCheck(item, dieselVol, dieselFuelNeededCL)
    local dieselCheck = false
    if dieselVol > dieselFuelNeededCL then
        dieselCheck = true
    else
        table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1060: INSUFFICIENT FUEL*")
    end
    return dieselCheck
end

-- (DTC) P228C indicates “Fuel Pressure Regulator 1 Exceeded Control Limits – Pressure Too Low.”
function MT.DF.fuelPressureCheck(item, dieselSeries, fuelFilter, fuelPump)
    local fuelPressureCheck = true

    -- check fuelFilter
    if dieselSeries.fuelFilterLocation then
        if fuelFilter == nil then
            fuelPressureCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1090: LOW FUEL PRESSURE*")
        elseif fuelFilter.ConditionPercentage < 1 or fuelFilter.HasTag("blocked") then
            fuelPressureCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1010: LOW FUEL PRESSURE*")
        end
    end
    -- check fuelPump
    if dieselSeries.fuelPumpLocation then
        if fuelPump == nil then
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1014: LOW FUEL PRESSURE*")
            fuelPressureCheck = false
        elseif fuelPump.ConditionPercentage < 1 or fuelPump.HasTag("blocked") then
            fuelPressureCheck = false
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1015: LOW FUEL PRESSURE*")
        end
    end
    return fuelPressureCheck
end

function MT.DF.oxygenCheck(item, hullOxygenPercentage, auxOxygenVol, oxygenNeeded)
    local oxygenCheck -- oxygenCheck
    if hullOxygenPercentage > 75 or auxOxygenVol > oxygenNeeded then        
        oxygenCheck = true
    else
        table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1050: INSUFFICIENT OXYGEN*")
    end
    return oxygenCheck
end
-- ----------------------------- !voltageCheck! ----------------------------- --
function MT.DF.voltageCheck(item, dieselSeries, battery)
    local voltageCheck = true -- default to true for diesel series without batteries 

    -- check battery
    if dieselSeries.batteryLocation then -- do I need a battery?           
        if battery and battery.Condition > 9 then
            voltageCheck = true
        elseif battery == nil then
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1070: NO BATTERY CONNECTED*") -- no battery should disable the DCM
            voltageCheck = false
        else
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1080: LOW VOLTAGE*")
            voltageCheck = false
        end
    end
    return voltageCheck
end

-- ------------------------------ starterCheck ------------------------------ --
function MT.DF.starterCheck(item, dieselSeries,starterMotor)
    local starterCheck = true -- default to true for diesel series without starters
    
    -- starterMotorCheck
    if dieselSeries.starterMotorLocation then -- do I need a starterMotor?        
        if starterMotor and starterMotor.Condition > 0 then
            starterCheck = true
        elseif not starterMotor then
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1016: NO STARTER MOTOR INSTALLED*")
            starterCheck = false
        else
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1017: STARTER MOTOR FAILED*")
            starterCheck = false
        end
    end
    return starterCheck
end

function MT.DF.getFluids(item, dieselSeries)
    local index = 0
    local fluids = {oilItems = {}, oilVol = 0, frictionReduction = 0}

    -- DYNAMIC INVENTORY: loop through the inventory and see what we have    
    while(index < item.OwnInventory.Capacity) do
    if item.OwnInventory.GetItemAt(index) ~= nil then
        local containedItem = item.OwnInventory.GetItemAt(index)
        if containedItem.HasTag("oil") and containedItem.Condition > 0 then
            table.insert(fluids.oilItems, containedItem)
            fluids.oilVol = fluids.oilVol + containedItem.Condition
            -- LUBRICATE: reduce *possible* friction damage for this oil slot  
            fluids.frictionReduction = fluids.frictionReduction + (MT.Config.FrictionBaseDPS * MT.Deltatime)
        end
    end
    index = index + 1
    end
    return fluids
end

function MT.DF.getFuels(item, DieselSeries)
    local index = 0
    local fuels = {dieselItems = {}, dieselVol = 0, auxOxygenItems = {}, auxOxygenVol = 0}
    -- DYNAMIC INVENTORY: auxDiesel
    if item.linkedTo ~= nil then
        for k, linkedItem in pairs(item.linkedTo) do
            while(index < linkedItem.OwnInventory.Capacity) do
                if linkedItem.OwnInventory.GetItemAt(index) ~= nil then
                    local containedItem = linkedItem.OwnInventory.GetItemAt(index)
                    -- get diesel item(s) - need to add support for linked tanks
                    if containedItem.HasTag("diesel_fuel") and containedItem.Condition > 0 then
                        table.insert(fuels.dieselItems, containedItem)
                        fuels.dieselVol = fuels.dieselVol + containedItem.Condition
                    end
                end
                index = index + 1
            end
        end
    end

    -- DYNAMIC INVENTORY: local diesel 
    index = 0
    while(index < item.OwnInventory.Capacity) do
        if item.OwnInventory.GetItemAt(index) ~= nil then
            local containedItem = item.OwnInventory.GetItemAt(index)
            -- get diesel item(s) - need to add support for linked tanks
            if containedItem.HasTag("diesel_fuel") and containedItem.Condition > 0 then
                table.insert(fuels.dieselItems, containedItem)
                fuels.dieselVol = fuels.dieselVol + containedItem.Condition
            -- get aux oxygen item(s)    
            elseif containedItem.HasTag("refillableoxygensource") and containedItem.Condition > 0 then
                table.insert(fuels.auxOxygenItems, containedItem)
                fuels.auxOxygenVol = fuels.auxOxygenVol + containedItem.Condition
            end
        end
    index = index + 1
    end
    return fuels
end

function MT.DF.getTemperatureZone(temperature, desiredOutput)
    local result
    if desiredOutput == nil then desiredOutput = "temp" end
    -- temperature zone
    if desiredOutput == "color" then
        if temperature >= 300 then result = Color(255,0,0,255)
        elseif temperature > 260 then result = Color(200,20,10,255)
        elseif temperature > 240 then result = Color(255,80,40,255)
        elseif temperature > 220 then result = Color(255,120,40,255)
        elseif temperature > 180 then result = Color(240,255,50,255)
        elseif temperature > 32 then result = Color(50,255,150,255)
        else result = Color(50,255,150,255)
        end
        return result
    else
        if temperature >= 300 then result = "failure"
        elseif temperature > 260 then result = "critical"
        elseif temperature > 240 then result = "over"
        elseif temperature > 220 then result = "high"
        elseif temperature > 180 then result = "operating"
        elseif temperature > 32 then result = "low"
        else result = "freezing"
        end
        return result
    end
end

function MT.DF.partFaultEvents(item, dieselSeries, parts, engineReliability) -- get or set part failures?
    -- fuelFilter fault events 
    if parts.fuelFilter then
        if MT.DF.partFaultProbability(parts.fuelFilter,MT.Config.FuelFilterSLD, engineReliability) then
            parts.fuelFilter.AddTag("blocked") -- add a blockage - in the future make it more likely when diesel tanks are damaged / submerged / contain cheap diesel.
        end
    end
    -- fuelPump fault events 
    if parts.fuelPump then        
        if MT.DF.partFaultProbability(parts.fuelPump, MT.Config.FuelPumpSLD, engineReliability) then
            local faultEvents = {}-- blocked
            parts.fuelPump.AddTag("blocked") -- in the future make it more likely when diesel tanks are damaged / submerged / contain cheap diesel.
            -- water - but I need to add a weighted random selection
        end
    end
    -- airFilter fault events
    if parts.airFilter then
        local extraModifier = 1.0
        if parts.airFilter.HasTag("mold") then extraModifier = 0.5 end -- increase fungus spawn rate 
        if MT.DF.partFaultProbability(parts.airFilter, MT.Config.FuelPumpSLD, engineReliability, extraModifier) then -- piggy backing on fuelPump servicelife for the moment            
            Entity.Spawner.AddItemToSpawnQueue(ItemPrefab.GetItemPrefab("spore_fungus"), parts.airFilter.OwnInventory, nil, nil, function(item) end) -- daww, its back!
        end
    end
    -- overheating fault events
    if parts.engine then
    -- 
    end

end
-- calculate the probability of a part fault event
-- this calculation makes the assumption, that, under perfect conditions, the part will experience one fault (on average) once during its serviceLife.
-- this isn't the case as engine reliability and part deterioration increase the probability by decreasing the max probability range
-- extraModifier: this allows for increasing or decreasing the probability at the time of the function call.
function MT.DF.partFaultProbability(part, serviceLife, reliability, extraModifier)
    if extraModifier == nil then extraModifier = 1.0 end
    return MT.HF.Probability(1, MT.HF.Round( serviceLife * reliability * (part.ConditionPercentage / 100) * MT.Config.PartFaultRangeModifier * extraModifier, 0))
end

function MT.DF.getParts(item, dieselSeries)
    local index = 0
    local parts = {oilFilterItems = {}, oilFilterCount = 0, oilFilterVol = 0}
    parts.oilFiltrationSlots = dieselSeries.oilFilterSlots
    parts.oilFiltrationVol = 0
    parts.frictionParts = {}
    parts.thermalParts = {}

    -- STATIC INVENTORY PARTS: add any staticly located items to the parts inventory

    -- fuelFilter (if any)
    if dieselSeries.fuelFilterLocation and item.OwnInventory.GetItemAt(dieselSeries.fuelFilterLocation) ~= nil then parts.fuelFilter = item.OwnInventory.GetItemAt(dieselSeries.fuelFilterLocation) end
    -- fuelPump (if any)
    if dieselSeries.fuelPumpLocation and item.OwnInventory.GetItemAt(dieselSeries.fuelPumpLocation) ~= nil then parts.fuelPump = item.OwnInventory.GetItemAt(dieselSeries.fuelPumpLocation) end
    -- airFilter (if any)
    if dieselSeries.airFilterLocation and item.OwnInventory.GetItemAt(dieselSeries.airFilterLocation) ~= nil then parts.airFilter = item.OwnInventory.GetItemAt(dieselSeries.airFilterLocation) end
    -- battery (if any)
    if dieselSeries.batteryLocation and item.OwnInventory.GetItemAt(dieselSeries.batteryLocation) ~= nil then parts.battery = item.OwnInventory.GetItemAt(dieselSeries.batteryLocation) end
    -- starterMotor (if any)
    if dieselSeries.starterMotorLocation and item.OwnInventory.GetItemAt(dieselSeries.starterMotorLocation) ~= nil then parts.starterMotor = item.OwnInventory.GetItemAt(dieselSeries.starterMotorLocation) end
    -- exhaustManifold (if any)
    if dieselSeries.exhaustManifoldLocation and item.OwnInventory.GetItemAt(dieselSeries.exhaustManifoldLocation) ~= nil then parts.exhaustManifold = item.OwnInventory.GetItemAt(dieselSeries.exhaustManifoldLocation) end
    -- exhaustManifoldGasket (if any)
    if dieselSeries.exhaustManifoldLocation and parts.exhaustManifold ~= nil and parts.exhaustManifold.OwnInventory.GetItemAt(0) ~= nil then parts.exhaustManifoldGasket = parts.exhaustManifold.OwnInventory.GetItemAt(0) end
    -- dcm (if any)
    if dieselSeries.dcmLocation and item.OwnInventory.GetItemAt(dieselSeries.dcmLocation) ~= nil then
        parts.dcm = item.OwnInventory.GetItemAt(dieselSeries.dcmLocation)
        if parts.dcm.OwnInventory.GetItemAt(2) ~= nil then parts.oxygenSensor = parts.dcm.OwnInventory.GetItemAt(2) end
        if parts.dcm.OwnInventory.GetItemAt(3) ~= nil then parts.pressureSensor = parts.dcm.OwnInventory.GetItemAt(3) end
    end
    -- engineBlock (if any)
    if dieselSeries.engineBlockLocation and item.OwnInventory.GetItemAt(dieselSeries.engineBlockLocation) ~= nil then
        parts.engineBlock = item.OwnInventory.GetItemAt(dieselSeries.engineBlockLocation)
        table.insert(parts.frictionParts, parts.engineBlock) -- add this to the parts list for friction damage
        table.insert(parts.thermalParts, parts.engineBlock)
        if dieselSeries.cylinderHeadLocation and parts.engineBlock.OwnInventory.GetItemAt(dieselSeries.cylinderHeadLocation) then
            parts.cylinderHead = parts.engineBlock.OwnInventory.GetItemAt(dieselSeries.cylinderHeadLocation)
            table.insert(parts.frictionParts, parts.cylinderHead) -- add this to the parts list for friction damage
            table.insert(parts.thermalParts, parts.cylinderHead)
        end
        if dieselSeries.crankAssemblyLocation and parts.engineBlock.OwnInventory.GetItemAt(dieselSeries.crankAssemblyLocation) then
            parts.crankAssembly = parts.engineBlock.OwnInventory.GetItemAt(dieselSeries.crankAssemblyLocation)
            table.insert(parts.frictionParts, parts.crankAssembly) -- add this to the parts list for friction damage
            table.insert(parts.thermalParts, parts.crankAssembly)
        end

    end

    -- DYNAMIC INVENTORY: loop through the inventory and see what we have    
    while(index < item.OwnInventory.Capacity) do
        if item.OwnInventory.GetItemAt(index) ~= nil then
            local containedItem = item.OwnInventory.GetItemAt(index)
            if containedItem.HasTag("oilfilter") and containedItem.Condition > 0 then
                table.insert(parts.oilFilterItems, containedItem)
                parts.oilFilterCount = parts.oilFilterCount + 1
                parts.oilFilterVol = parts.oilFilterVol + containedItem.Condition
            end
        end
            index = index + 1
        end
    return parts
end
