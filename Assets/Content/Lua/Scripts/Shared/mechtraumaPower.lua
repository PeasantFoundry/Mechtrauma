MT.GridUpdateCooldown = 0
MT.GridUpdateInterval = 1
MT.gridCyclestime = MT.GridUpdateInterval/60 -- Time in seconds that transpires between updates

-- engine ignition types
function MT.F.relayIgnition(item)
    return MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.RelayComponent").IsOn
end

function MT.F.sGeneratorIgnition(item)
    return MTUtils.GetComponentByName(item, "Mechtrauma.SimpleGenerator").IsOn
end

--table for dieselEngine models
MT.DE = {
    s5000D={
        maxHorsePower=5000*1.5,
        oilSlots=2,
        oilFilterSlots=1,
        dieselFuelSlots=6,
        auxOxygenSlots=3,
        name="s5000D",
        maxReliability = 90,
        maxEfficiency = 95,
        ignitionType=MT.F.sGeneratorIgnition
    },
    s3000D={
        maxHorsePower=3000*1.5,
        oilSlots=1,
        oilFilterSlots=1,
        dieselFuelSlots=4,
        auxOxygenSlots=2,
        name="s3000D",
        maxReliability = 90,
        maxEfficiency = 95,
        ignitionType=MT.F.sGeneratorIgnition
    },
    s3000Da={
        maxHorsePower=3000*1.5,
        engineBlockLocation = 0,
        oilSlots = 1,
        oilFilterSlots = 1,
        dieselFuelSlots = 1,
        fuelFilterLocation = 4,
        fuelPumpLocation = 5,
        batteryLocation = 6, -- container slot in XML
        starterMotorLocation = 7,
        exhaustManifoldLocation = 9,
        airFilterLocation = 11,
        auxOxygenSlots= 1,
        name="s3000Da",
        maxReliability = 90,
        maxEfficiency = 95,
        ignitionType=MT.F.sGeneratorIgnition
    },
    sC2500Da={
        maxHorsePower=2500*1.5,
        oilSlots=2,
        oilFilterSlots=1,
        dieselFuelSlots=3,
        auxOxygenSlots=3,
        name="s2500Da",
        maxReliability = 100,
        maxEfficiency = 100,
        ignitionType=MT.F.sGeneratorIgnition
    },
    sC2500Db={
        maxHorsePower=2500*1.5,
        oilSlots=2,
        oilFilterSlots=1,
        dieselFuelSlots=3,
        auxOxygenSlots=3,
        name="s2500Db",
        maxReliability = 100,
        maxEfficiency = 100,
        ignitionType=MT.F.sGeneratorIgnition
    },
        sC2500Dc={
        maxHorsePower=2500*1.5,
        oilSlots=2,
        oilFilterSlots=1,
        dieselFuelSlots=3,
        auxOxygenSlots=3,
        name="s2500Dc",
        maxReliability = 100,
        maxEfficiency = 100,
        ignitionType=MT.F.sGeneratorIgnition
    },
    s1500D={
        maxHorsePower=1500*1.5,
        oilSlots=1,
        oilFilterSlots=1,
        dieselFuelSlots=3,
        auxOxygenSlots=1,
        name="s1500D",
        maxReliability = 100,
        maxEfficiency = 100,
        ignitionType=MT.F.sGeneratorIgnition
    },
    PDG500={
        maxHorsePower=500*1.5,
        oilSlots=1,
        oilFilterSlots=1,
        dieselFuelSlots=1,
        auxOxygenSlots=1,
        name="PDG500",
        maxReliability = 100,
        maxEfficiency = 100,
        ignitionType=MT.F.sGeneratorIgnition
    },
    PDG250={
        maxHorsePower=250*1.5,
        oilSlots=1,
        oilFilterSlots=1,
        dieselFuelSlots=1,
        auxOxygenSlots=1,
        name="PDG250",
        maxReliability = 100,
        maxEfficiency = 100,
        ignitionType=MT.F.sGeneratorIgnition
    }
}

-- called by updateItems
function MT.F.dieselGenerator(item)
    -- convert load(kW) to targetPower(HP) 1.341022   
    local simpleGenerator = MTUtils.GetComponentByName(item, "Mechtrauma.SimpleGenerator")
    local targetPower = MT.HF.Clamp(simpleGenerator.GridLoad, 0, simpleGenerator.MaxPowerOut)
    local dieselSeries = MT.DE[item.Prefab.Identifier.Value]

    -- cap the efficiency of the generator
    -- simpleGenerator.Efficiency = MT.HF.Clamp(simpleGenerator.Efficiency, simpleGenerator.Efficiency, dieselSeries.maxEfficiency)

    -- GENERATOR ON
    if simpleGenerator.IsOn then

      -- check for a valid diesel series index
      if dieselSeries ~= nil then
        
        -- DIESEL ENGINE: call dieselEngine and store the results
        local result = MT.F.dieselEngine(item, dieselSeries, targetPower)
        
        -- Generate Power: need to add the HP to kW conversion at some point
        
        -- set the power consumpition for the server        
        simpleGenerator.PowerConsumption = -result.powerGenerated
        --connection.Item.SendSignal(tostring(result.powerGenerated), "powergenerated")
        for k, connection in pairs(item.Connections) do
         if connection.name == "power_generated" then connection.Item.SendSignal(tostring(result.powerGenerated), "powergenerated") end
        end
        
        -- set power to generate and send it to clients
        simpleGenerator.PowerToGenerate = result.powerGenerated
        if SERVER then Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(simpleGenerator.SerializableProperties[Identifier("PowerToGenerate")], simpleGenerator)) end

        else
            -- invalid diesel series index
            print(item.Prefab.Identifier.Value, " - !IS NOT A VALID DIESEL SERIES!")
        end

    -- GENERATOR OFF
    else
        MT.itemCache[item].isRunning = false -- this tells if the generator is already running at the time of request so that ignition can be bypassed
        -- SOUND / LIGHT - dieselEngine sound is controlled by an XML light so it will toggle with the light(s)
        for k, item in pairs(item.Components) do
            if tostring(item) == "Barotrauma.Items.Components.LightComponent" then item.IsOn = false end
        end
    end
end



-- called by MT.F.dieselGenerator: calculates if and how much power an engine should be producing
function MT.F.dieselEngine(item, dieselSeries, targetPower)
    --ADVANCED DIESEL DESIGN
    -- HP:kW = 1:0.75
    -- HP:diesel(l) 1:0.2   
    -- general         
    local gridCycles = 60
    local simpleGenerator = MTUtils.GetComponentByName(item, "Mechtrauma.SimpleGenerator")
    local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
    local dieselEngine = {}
    local dieselFuelNeededCL = MT.Config.DieselHorsePowerRatioCL * MT.HF.Clamp(targetPower, 100, dieselSeries.maxHorsePower) / 3600 * MT.Deltatime -- 100 min hp is idle speed
    local oxygenNeeded = dieselFuelNeededCL * MT.Config.DieselOxygenRatioCL -- this is where we cheat and pretend that 1 condition of oxygen is equal to 1 condtion of diesel    
    local ignition
    -- oxygen    
    local hullOxygenPercentage = 0
    -- set hullOxygenPercentage to 0 when submerged or outside of a hull.
    if item.InWater == false and item.FindHull() ~= nil then hullOxygenPercentage = item.FindHull().OxygenPercentage else hullOxygenPercentage = 0 end

    -- INVENTORY
    local fluids = MT.DF.getFluids(item, dieselSeries)
    local fuels = MT.DF.getFuel(item, dieselSeries)
    local parts = MT.DF.getParts(item, dieselSeries)
    
    -- damage and reduction
    -- need to rework friction damage to apply to enginge block items instead of the generator itself    
    local frictionDamage = (MT.Config.FrictionBaseDPS * MT.Deltatime * dieselSeries.oilSlots) - fluids.frictionReduction
    -- calculates total possible oil deterioration and then reduces for each viable filter
    local oilDeterioration = MT.HF.Round((MT.Config.OilBaseDPS * MT.Deltatime * dieselSeries.oilSlots) - (MT.Config.OilBaseDPS * MT.Deltatime * MT.Config.OilFiltrationM * parts.oilFilterCount),0)

    -- diagnostics
    MT.itemCache[item].diagnosticData = nil -- clear out the old codes
    MT.itemCache[item].diagnosticData ={errorCodes={},warningCodes={},statusCodes={}} -- redefine the item 

    -- CHECK FUELS
    dieselEngine.oxygenCheck = MT.DF.oxygenCheck(item, hullOxygenPercentage, fuels.auxOxygenVol, oxygenNeeded)
    dieselEngine.fuelCheck = MT.DF.fuelCheck(item, fuels.dieselVol, dieselFuelNeededCL)

    -- CHECK FLUIDS

    -- CHECK: PARTS 
    dieselEngine.airFilterCheck = MT.DF.airFilterCheck(item, dieselSeries, parts.airFilter)
    dieselEngine.compressionCheck = MT.DF.compressionCheck(item, dieselSeries, parts.engineBlock)
    dieselEngine.exhaustCheck = MT.DF.exhaustCheck(item, dieselSeries, parts.exhaustManifold, parts.exhaustManifoldGasket)
    dieselEngine.fuelPressureCheck = MT.DF.fuelPressureCheck(item, dieselSeries, parts.fuelFilter, parts.fuelPump)

    -- reset ignition if the generator is off    
    if MT.itemCache[item].isRunning == false then dieselEngine.ignition = false end
    local batteryCheck
    local starterMotorCheck
    -- ***** ATTEMPT IGNITION *****    
    -- batteryCheck
    if dieselSeries.batteryLocation and dieselEngine.ignition == false then -- do I need a battery?           
        if parts.battery and parts.battery.Condition > 9 then
            if parts.starterMotor and parts.starterMotor.Condition > 0 then parts.battery.Condition = parts.battery.condition - 10 end --drain the battery if there is a working starter
            batteryCheck = true
        elseif not parts.battery then
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1070: NO BATTERY CONNECTED*")
            batteryCheck = false
        else
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1080: DEAD BATTERY CONNECTED*")
            batteryCheck = false
        end
    end
    -- starterMotorCheck
    if dieselSeries.starterMotorLocation and dieselEngine.ignition == false then -- do I need a starterMotor?        
        if parts.starterMotor and parts.starterMotor.Condition > 0 then
            if parts.battery and parts.battery.Condition > 9 then parts.starterMotor.Condition = parts.starterMotor.Condition - 1 end -- deteriorate the starterMotor if there is a charged battery
            starterMotorCheck = true
        elseif not parts.starterMotor then
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1016: NO STARTER MOTOR INSTALLED*")
            starterMotorCheck = false
        else
            table.insert(MT.itemCache[item].diagnosticData.errorCodes, "*DC1017: STARTER MOTOR FAILED*")
            starterMotorCheck = false
        end
    end
    -- ignitionCheck
    if dieselSeries.batteryLocation and dieselSeries.starterMotorLocation and dieselEngine.ignition == false then
        if batteryCheck and starterMotorCheck then
            dieselEngine.ignition = true
        else
            dieselEngine.ignition = false
        end
    else
        dieselEngine.ignition = true -- ignition always true if batter and starterMotor are not required
    end

    -- ***** ATTEMPT COMBUSTION *****
    if item.Condition > 0 and
       dieselEngine.ignition and
       dieselEngine.airFilterCheck and
       dieselEngine.fuelCheck and
       dieselEngine.oxygenCheck and
       dieselEngine.fuelPressureCheck and
       dieselEngine.compressionCheck
    then
        -- ***** COMBUSTION SUCCEDED *****
        MT.itemCache[item].isRunning = true
        dieselEngine.combustion = true
        
        --[[
        print("accuracy: ", simpleGenerator.Accuracy)
        print("efficiency: ", simpleGenerator.Efficiency)
        print("reliability: ", simpleGenerator.Reliability)        
        simpleGenerator.Accuracy = 50
        simpleGenerator.Efficiency = simpleGenerator.Efficiency - 5
        simpleGenerator.Reliability = simpleGenerator.Reliability - 5
        ]]
        
        -- adjust the targetPower based on the generator accuracy (over or under produce power)
        targetPower = targetPower * MT.HF.Tolerance(simpleGenerator.Accuracy)
        
        -- GENERATE POWER:        
        dieselEngine.powerGenerated = MT.HF.Round(MT.HF.Clamp(targetPower, 0, dieselSeries.maxHorsePower), 2)         
        if parts.battery then parts.battery.Condition = parts.battery.condition + 0.1 end -- charge the battery (if any)
        
        -- CONSUMPTION AND DETERIORATION: 

        -- burn oxygen       
        if hullOxygenPercentage >= 75 then  -- burn hull oxygen when above 75%
            item.FindHull().Oxygen = item.FindHull().Oxygen - (oxygenNeeded * 2250) -- 2250 hull oxygen ~= 1 oxygen condition                     
        else
            MT.HF.subFromListSeq (oxygenNeeded, fuels.auxOxygenItems) -- burn auxOxygen
        end
        -- burn diesel
        MT.HF.subFromListSeq (dieselFuelNeededCL, fuels.dieselItems) -- burn diesel sequentially, improves resource management 
        -- deteriorate oil
        MT.HF.subFromListEqu(oilDeterioration, fluids.oilItems) -- total oilDeterioration is spread across all oilItems. (being low on oil will make the remaining oil deteriorate faster)
        -- deteriorate oil filter(s)
        MT.HF.subFromListAll((MT.Config.OilFilterDPS * MT.Deltatime), parts.oilFilterItems) -- apply deterioration to each filters independently, they have already reduced oil deterioration
        if dieselSeries.fuelFilterLocation and parts.fuelFilter ~= nil then -- deteriorate fuel filter
            parts.fuelFilter.Condition = parts.fuelFilter.Condition - (MT.Config.FuelFilterDPS * MT.Deltatime) end
        if dieselSeries.fuelPumpLocation and parts.fuelFilter ~= nil then -- deteriorate fuel pump
            parts.fuelPump.Condition = parts.fuelPump.Condition - (MT.Config.FuelPumpDPS * MT.Deltatime) end
        if dieselSeries.engineBlockLocation and parts.engineBlock ~= nil then -- deteriorate engineBlock
            parts.engineBlock.Condition = parts.engineBlock.Condition - (MT.Config.EngineBlockDPS * MT.Deltatime) end
        if dieselSeries.exhaustManifoldLocation and parts.exhaustManifold ~= nil then -- deteriorate exhaustManifold (if any)
            parts.exhaustManifold.Condition = parts.exhaustManifold.Condition - (MT.Config.exhaustManifoldDPS * MT.Deltatime) end
        if dieselSeries.exhaustManifoldLocation and parts.exhaustManifoldGasket ~= nil then -- deteriorate exhaustGasket (if any)
            parts.exhaustManifoldGasket.Condition = parts.exhaustManifoldGasket.Condition - (MT.Config.exhaustManifoldGasketDPS * MT.Deltatime) end
        -- item damage - this needs to be reqworked
        item.Condition = item.Condition - frictionDamage

        -- SOUND / LIGHT - dieselEngine sound is controlled by an XML light so it will toggle with the light(s)
        for k, component in pairs(item.Components) do
            if tostring(component) == "Barotrauma.Items.Components.LightComponent" then component.IsOn = true end
        end

        -- calculate consumables time remaining
        dieselEngine.fuelTime = MT.HF.Round((fuels.dieselVol / dieselFuelNeededCL) * MT.Deltatime / 60, 1)
        dieselEngine.oilTime = MT.HF.Round((fluids.oilVol / oilDeterioration) * MT.Deltatime / 60, 1)
        dieselEngine.filterTime = MT.HF.Round((parts.oilFilterVol / MT.Config.OilFilterDPS) / 60, 1) -- no need to calculate the deltaTime here since calc is already in dps
        dieselEngine.oxygenTime = MT.HF.Round((fuels.auxOxygenVol / oxygenNeeded) * MT.Deltatime / 60, 1)

    else
        -- ***** COMBUSTION FAILED *****      
        dieselEngine.combustion = false
        dieselEngine.powerGenerated = 0
        -- turn off generator when combustion fails 
        simpleGenerator.IsOn = false
        -- SOUND / LIGHT - dieselEngine sound is controlled by an XML light so it will toggle with the light(s)
        for k, item in pairs(item.Components) do
            if tostring(item) == "Barotrauma.Items.Components.LightComponent" then item.IsOn = false end
        end
    end
    -- ***** DIAGNOSTICS ***** 
    if terminal and simpleGenerator.diagnosticMode then
        MT.HF.BlankTerminalLines(terminal, 10)
        -- DIAGNOSTICS: Status - only display if there is a terminal, ignition is implicit
        if dieselEngine.combustion == true then
            terminal.SendMessage("*COMBUSTION: " .. dieselEngine.powerGenerated .. "kW GENERATED*", Color(250, 125, 15, 255))
            terminal.SendMessage(string.format("%-5s", dieselEngine.fuelTime .. "m") .. " of Diesel Fuel remaining", Color(250, 125, 15, 255))
            terminal.SendMessage(string.format("%-5s", dieselEngine.oilTime .. "m") .. " of Oil remaining.", Color(250, 125, 15, 255))
            terminal.SendMessage(string.format("%-5s", dieselEngine.filterTime .. "m") .. " of Oil Filtration remaining.", Color(250, 125, 15, 255))
            terminal.SendMessage(string.format("%-5s", dieselEngine.oxygenTime .. "m") .. " of Oxygen remaining.", Color(250, 125, 15, 255))
        end
        -- DIAGNOSTICS: Error Codes - only display if the generator IsOn and there are errorCodes
        if next(MT.itemCache[item].diagnosticData.errorCodes) ~= nil then
            terminal.SendMessage("*****COMBUSTION FAILED*****",  Color(255, 35, 35, 255))
            for k, dCode  in pairs(MT.itemCache[item].diagnosticData.errorCodes) do
                terminal.SendMessage(dCode, Color(255, 35, 35,255))
            end
        end
        -- DIAGNOSTICS: Warning Codes - only display if the generator IsOn and there are warningCodes
        if next(MT.itemCache[item].diagnosticData.warningCodes) ~= nil then
            terminal.SendMessage("*****WARNINGS*****",  Color(255, 80, 50, 255))
            for k, dCode in pairs(MT.itemCache[item].diagnosticData.warningCodes) do
                terminal.SendMessage(dCode, Color(255, 80, 50, 255))
            end
        end
    end
    return dieselEngine
end
