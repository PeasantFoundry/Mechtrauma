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
        autoStart = false, -- (NI)
        maxHorsePower = 3000, -- includes overdrive
        maxCooling = 150000, -- 3000hp * 1.25 * 40 - can cool 125% of maxHP
        maxOverdive = 1.5,
        engineBlockLocation = 0,
        cylinderHeadLocation = 0,
        crankAssemblyLocation = 1,
        oilSlots = 1,
        oilFilterSlots = 1,
        dieselFuelSlots = 0,
        --heatExchangerLocation=3,
        independentHeatExchanger=true,
        fuelFilterLocation = 4,
        fuelPumpLocation = 5,
        batteryLocation = 6, -- container slot in XML
        starterMotorLocation = 7,
        dcmLocation = 8,
        exhaustManifoldLocation = 9,
        airFilterLocation = 11,
        auxOxygenSlots= 1,
        name="s3000Da",
        maxReliability = 90,
        maxEfficiency = 1.0,
        
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
    local DieselEngine = MTUtils.GetComponentByName(item, "Mechtrauma.DieselEngine")
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
        DieselEngine.IsRunning = false -- this tells if the generator is already running at the time of request so that ignition can be bypassed
        -- SOUND / LIGHT - dieselEngine sound is controlled by an XML light so it will toggle with the light(s)
        for k, item in pairs(item.Components) do
            if tostring(item) == "Barotrauma.Items.Components.LightComponent" then item.IsOn = false end
        end
    end
end

-- -------------------------------------------------------------------------- --
--                          MY BELOVED DIESEL ENGINE                          --
-- -------------------------------------------------------------------------- --
-- DESIGN NOTES:
-- HP:kW = 1:0.75
-- HP:BTU/h 1:2500 
-- HP:BTU 1:40 ~ 
-- HP:diesel(l) 1:0.2   


-- called by MT.F.dieselGenerator: calculates if and how much power an engine should be producing
function MT.F.dieselEngine(item, dieselSeries, targetPower)

    local gridCycles = 60
    local simpleGenerator = MTUtils.GetComponentByName(item, "Mechtrauma.SimpleGenerator")
    local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
    local DieselEngine = MTUtils.GetComponentByName(item, "Mechtrauma.DieselEngine")
    local thermal = MTUtils.GetComponentByName(item, "Mechtrauma.Thermal")
    local dieselEngine = {}
    local dieselFuelNeededCL = MT.Config.DieselHorsePowerRatioCL * MT.HF.Clamp(targetPower, 100, dieselSeries.maxHorsePower) / 3600 * MT.Deltatime -- 100 min hp is idle speed
    local oxygenNeeded = dieselFuelNeededCL * MT.Config.DieselOxygenRatioCL -- this is where we cheat and pretend that 1 condition of oxygen is equal to 1 condition of diesel    

    -- oxygen - TO DO: move to get fuels     
    local hullOxygenPercentage = 0
    -- set hullOxygenPercentage to 0 when submerged or outside of a hull.
    if item.InWater == false and item.FindHull() ~= nil then hullOxygenPercentage = item.FindHull().OxygenPercentage else hullOxygenPercentage = 0 end


    -- -------------------------------------------------------------------------- --
    --                             ESTABLISH INVENTORY                            --
    -- -------------------------------------------------------------------------- --
    local parts = MT.DF.getParts(item, dieselSeries)
    local fluids = MT.DF.getFluids(item, DieselEngine, parts) -- we need the parts because they may contain fludis 
    local fuels = MT.DF.getFuels(item, dieselSeries)


    -- damage and reduction
    local frictionDamage = (MT.Config.FrictionBaseDPS * MT.Deltatime * dieselSeries.oilSlots) - fluids.frictionReduction
    -- calculates total possible oil deterioration and then reduces for each viable filter
    local oilDeterioration = MT.HF.Round((MT.Config.OilBaseDPS * MT.Deltatime * dieselSeries.oilSlots) - (MT.Config.OilBaseDPS * MT.Deltatime * MT.Config.OilFiltrationM * parts.oilFilterCount),0)

    -- DIAGNOSTICS
    MT.itemCache[item].diagnosticData = nil -- clear out the old codes
    MT.itemCache[item].diagnosticData ={errorCodes={},warningCodes={},statusCodes={}} -- redefine the item 

    -- -------------------------------------------------------------------------- --
    --                          !CHECK IGNITION SYSTEMS!                          --
    -- -------------------------------------------------------------------------- --

    -- if the engine isn't running, reset the ignition and check the ignition systems
    if DieselEngine.IsRunning == false then
        dieselEngine.ignition = false -- switch the ignition off if the engine has stalled/shutdown

        -- CHECK: IGNITION SYSTEMS 
        dieselEngine.starterCheck = MT.DF.starterCheck(item, dieselSeries, parts.starterMotor)
        dieselEngine.voltageCheck = MT.DF.voltageCheck(item, dieselSeries, parts.battery)
    end

    -- -------------------------------------------------------------------------- --
    --                        ***** ATTEMPT IGNITION *****                        --
    -- -------------------------------------------------------------------------- --

    -- ignitionCheck -- need to add probability of failure
    if dieselSeries.batteryLocation and dieselSeries.starterMotorLocation and dieselEngine.ignition == false then
        if dieselEngine.voltageCheck and dieselEngine.starterCheck then
            parts.starterMotor.Condition = parts.starterMotor.Condition - 1 -- deteriorate the starterMotor
            parts.battery.Condition = parts.battery.condition - 10 -- drain the battery 

            dieselEngine.ignition = true
        else
            dieselEngine.ignition = false
        end
    else
        dieselEngine.ignition = true -- ignition always true if battery and starterMotor are not required
    end

    -- -------------------------------------------------------------------------- --
    --                         !CHECK COMBUSTION SYSTEMS!                         --
    -- -------------------------------------------------------------------------- --

    -- CHECK: FUELS
    dieselEngine.oxygenCheck = MT.DF.oxygenCheck(item, hullOxygenPercentage, fuels.auxOxygenVol, oxygenNeeded)
    dieselEngine.dieselCheck = MT.DF.dieselCheck(item, fuels.dieselVol, dieselFuelNeededCL)

    -- CHECK: FLUIDS
        -- Oil
        -- Coolant

    -- CHECK: SYSTEMS
    dieselEngine.airFilterCheck = MT.DF.airFilterCheck(item, dieselSeries, parts.airFilter)
    dieselEngine.compressionCheck = MT.DF.compressionCheck(item, dieselSeries, parts.engineBlock, parts.cylinderHead, parts.crankAssembly)
    dieselEngine.dcmCheck = MT.DF.dcmCheck(item, dieselSeries, parts.dcm, parts.oxygenSensor, parts.pressureSensor)
    dieselEngine.exhaustCheck = MT.DF.exhaustCheck(item, dieselSeries, parts.exhaustManifold, parts.exhaustManifoldGasket)
    dieselEngine.fuelPressureCheck = MT.DF.fuelPressureCheck(item, dieselSeries, parts.fuelFilter, parts.fuelPump)
    dieselEngine.coolingCheck = MT.DF.coolingCheck(item, dieselSeries, DieselEngine, parts.heatExchanger)


    -- -------------------------------------------------------------------------- --
    --                       ***** ATTEMPT COMBUSTION *****                       --
    -- -------------------------------------------------------------------------- --
    if item.Condition > 0 and
       dieselEngine.ignition and
       dieselEngine.airFilterCheck and
       dieselEngine.dieselCheck and
       dieselEngine.oxygenCheck and
       dieselEngine.fuelPressureCheck and
       dieselEngine.compressionCheck
    then

    -- -------------------------------------------------------------------------- --
    --                       ***** COMBUSTION *****                               --
    -- -------------------------------------------------------------------------- --
        DieselEngine.IsRunning = true
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

        -- calculate efficiency
        simpleGenerator.Efficiency = dieselSeries.maxEfficiency
        if not dieselEngine.dcmCheck.oxygenSensor then simpleGenerator.Efficiency = simpleGenerator.Efficiency - 0.5 end -- need to make this fluctuate         
        oxygenNeeded = oxygenNeeded * (1 - simpleGenerator.Efficiency + 1)
        dieselFuelNeededCL = dieselFuelNeededCL * (1 - simpleGenerator.Efficiency + 1)

        -- calculate reliability
        simpleGenerator.Reliability = item.ConditionPercentage / 100

        -- GENERATE POWER:        
        dieselEngine.powerGenerated = MT.HF.Round(MT.HF.Clamp(targetPower, 0, dieselSeries.maxHorsePower), 2)
        if parts.battery then parts.battery.Condition = parts.battery.condition + 0.1 end -- charge the battery (if any)

        -- -------------------------------------------------------------------------- --
        --                           TEMPERATURE AND COOLING                          --
        -- -------------------------------------------------------------------------- --
        --  range      |        zone            | effects
        --   60f       | default temperature    |   
        -- < 180       | low temperature        | reduced efficiency
        -- > 180 - 220 | operating temperature  |    
        -- > 220 - 240 | high temperature       | reduced efficiency        
        -- > 240 - 260 | over temperature       | risk engine damage   
        -- > 260 - 300 | critical temperatue    | risk engine failure  
        -- = 300       | critical failure       | engine destroyed 

        -- iron block, diesel fuel,

        -- -------------------------------------------------------------------------- --
        --                           !CHECK COOLING SYSTEMS!                          --
        -- -------------------------------------------------------------------------- --
        -- this is a hack
        
        -- TO DO: move to function call 
        if thermal.Temperature == nil then thermal.Temperature = 60 end -- default temp
        
        --[[set temperature for the parts. 
        for _, part in pairs(parts.thermalParts) do
            local partThermal = MTUtils.GetComponentByName(part, "Mechtrauma.Thermal")
            partThermal.Temperature = MT.HF.Round(thermal.Temperature, 0)
            if part.HasTag("exhaustManifold") then partThermal.Temperature = partThermal.Temperature * 1.25 end
            --print(part , " temperature is " ..  partThermal.Temperature)
        end]]

        --dieselEngine.operatingTemperature = 200 
        DieselEngine.HeatGenerated = dieselEngine.powerGenerated * 120 -- HP:BTU is 1:40 but toal heat output is 3x HP             
        DieselEngine.CoolingNeeded = dieselEngine.powerGenerated * 40 -- only 1/3 of BTU goes to coolant, 1/3 goes out ehaust and 1/3 goes into HP        
        DieselEngine.HeatSurplus = MT.HF.Clamp(DieselEngine.CoolingNeeded - DieselEngine.CoolingAvailable, 0, 1000000)

        if DieselEngine.HeatSurplus > 0 then
            DieselEngine.CoolingNeeded = DieselEngine.CoolingNeeded - DieselEngine.CoolingAvailable
            -- overheat engine
            thermal.Temperature = thermal.Temperature + (305 - thermal.Temperature) / 10 * MT.HF.Round(DieselEngine.HeatSurplus / DieselEngine.CoolingCapacity, 2)
            -- apply to thermal parts
            for k, part in pairs(parts.thermalParts) do
                local partThermal = MTUtils.GetComponentByName(part, "Mechtrauma.Thermal")
                partThermal.Temperature = partThermal.Temperature + (305 - partThermal.Temperature) / 10 * MT.HF.Round(DieselEngine.HeatSurplus / DieselEngine.CoolingCapacity, 2)
            end
        else
            -- normal operations            
            if thermal.Temperature < 200 then
                -- increase temperature
                thermal.Temperature = MT.HF.Round(thermal.Temperature + (DieselEngine.OperatingTemperature - thermal.Temperature) / 10 + 1, 2)
                  -- apply to thermal parts
                for k, part in pairs(parts.thermalParts) do
                    local partThermal = MTUtils.GetComponentByName(part, "Mechtrauma.Thermal")
                    partThermal.Temperature = MT.HF.Round(partThermal.Temperature + (DieselEngine.OperatingTemperature - partThermal.Temperature) / 10 + 1, 2)
                end
            else
                -- decrease temperature
                thermal.Temperature = MT.HF.Round(thermal.Temperature - ((DieselEngine.OperatingTemperature - thermal.Temperature) / 10 + - 1)*-1, 2)
                -- apply to thermal parts
                for k, part in pairs(parts.thermalParts) do
                    local partThermal  = MTUtils.GetComponentByName(part, "Mechtrauma.Thermal")
                    partThermal.Temperature =  MT.HF.Round(partThermal.Temperature - ((DieselEngine.OperatingTemperature - partThermal.Temperature) / 10 + - 1)*-1, 2)
                end
            end
        end
        -- -------------------------------------------------------------------------- --
        --                       CONSUMPTION AND DETERIORATION:                       --
        -- -------------------------------------------------------------------------- --

        -- burn oxygen       
        if hullOxygenPercentage >= 75 then  -- burn hull oxygen when above 75%
            item.FindHull().Oxygen = item.FindHull().Oxygen - (oxygenNeeded * 2250) -- 2250 hull oxygen ~= 1 oxygen condition                     
        else
            MT.HF.subFromListSeq (oxygenNeeded, fuels.auxOxygenItems) -- burn auxOxygen
        end
        -- burn diesel        
        MT.itemCache[item].fuelBurned = MT.HF.subFromListSeq (dieselFuelNeededCL, fuels.dieselItems) -- burn diesel sequentially, improves resource management         
        -- deteriorate oil
        MT.HF.subFromListDis(oilDeterioration, fluids.oilItems) -- total oilDeterioration is spread across all oilItems. (being low on oil will make the remaining oil deteriorate faster)
        -- deteriorate oil filter(s)
        MT.HF.subFromListAll((MT.Config.OilFilterDPS * MT.Deltatime), parts.oilFilterItems) -- apply deterioration to each filters independently, they have already reduced oil deterioration
        -- deteriorate others? I guess others
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

        -- frictionDamage - damages the item in classic generators, damages the engine parts in the advanced generators
        if next(parts.frictionParts) ~= nil then MT.HF.subFromListAll(frictionDamage * 10, parts.frictionParts) else item.Condition = item.Condition - frictionDamage end

        -- calculate part fault events
        MT.DF.partFaultEvents(item, dieselSeries, parts, simpleGenerator.Reliability)

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
    -- -------------------------------------------------------------------------- --
    --                        ***** COMBUSTION FAILED *****                       --
    -- -------------------------------------------------------------------------- --

        -- shutdown procedure
        dieselEngine.combustion = false
        DieselEngine.IsRunning = false -- shut it down
        dieselEngine.powerGenerated = 0
        simpleGenerator.IsOn = false -- switch off to prevent battery drain (later reimplement autoStart )
        dieselEngine.ignition = false -- reset ignition

        -- SOUND / LIGHT - dieselEngine sound is controlled by an XML light so it will toggle with the light(s)
        for k, item in pairs(item.Components) do
            if tostring(item) == "Barotrauma.Items.Components.LightComponent" then item.IsOn = false end
        end
    end

    -- -------------------------------------------------------------------------- --
    --                             ***** STATUS *****                             --
    -- -------------------------------------------------------------------------- --
    if terminal and DieselEngine.ShowStatus and parts.dcm ~= nil and parts.dcm.ConditionPercentage > 1 then
        terminal.ClearHistory()
        -- SHOW: Status - only display if there is a terminal, ignition is implicit
        if dieselEngine.combustion == true then
            terminal.SendMessage("*COMBUSTION: " .. dieselEngine.powerGenerated .. "kW GENERATED*", Color(255,100,50,255))
            terminal.SendMessage("Temperature: " .. MT.HF.Round(thermal.Temperature, 0) .. "F", MT.DF.getTemperatureZone(thermal.Temperature, "color"))
            terminal.SendMessage(string.format("%-5s", dieselEngine.fuelTime .. "m") .. " of Diesel Fuel remaining", Color(250,250,25,255))
            terminal.SendMessage(string.format("%-5s", dieselEngine.oilTime .. "m") .. " of Oil remaining.", Color(150,130,100,255))
            terminal.SendMessage(string.format("%-5s", dieselEngine.filterTime .. "m") .. " of Oil Filtration remaining.", Color(150,130,100,255))
            terminal.SendMessage(string.format("%-5s", dieselEngine.oxygenTime .. "m") .. " of Oxygen remaining.", Color(150,225,255,255))
        end
    end

    -- -------------------------------------------------------------------------- --
    --                             ***** LEVELS *****                             --
    -- -------------------------------------------------------------------------- --
    if terminal and DieselEngine.ShowLevels and parts.dcm ~= nil and parts.dcm.ConditionPercentage > 1 then
        terminal.ClearHistory()        
        -- SHOW: Status - only display if there is a terminal, ignition is implicit
        if dieselEngine.combustion == true then
            terminal.SendMessage("*COMBUSTION: " .. dieselEngine.powerGenerated .. "kW GENERATED*", Color(255,100,50,255))
            terminal.SendMessage("Temperature: " .. MT.HF.Round(thermal.Temperature, 0) .. "F", MT.DF.getTemperatureZone(thermal.Temperature, "color"))
            terminal.SendMessage(string.format("%-5s", MT.HF.Round(DieselEngine.CoolantLevel * 100, 1) .. "%") .. " coolant.", Color(150,255,175,255))
            --terminal.SendMessage(string.format("%-5s", dieselEngine.oilTime .. "m") .. " of Oil remaining.", Color(150,130,100,255))
            --terminal.SendMessage(string.format("%-5s", dieselEngine.filterTime .. "m") .. " of Oil Filtration remaining.", Color(150,130,100,255))
            --terminal.SendMessage(string.format("%-5s", dieselEngine.oxygenTime .. "m") .. " of Oxygen remaining.", Color(150,225,255,255))
        end
    end
    -- -------------------------------------------------------------------------- --
    --                           ***** DIAGNOSTICS *****                          --
    -- -------------------------------------------------------------------------- --
    if terminal and DieselEngine.DiagnosticMode and parts.dcm ~= nil and parts.dcm.ConditionPercentage > 1 then
        terminal.ClearHistory()
        -- DIAGNOSTICS: Status - only display if there is a terminal, ignition is implicit
        if dieselEngine.combustion == true then
            terminal.SendMessage("*COMBUSTION: " .. dieselEngine.powerGenerated .. "kW GENERATED*", Color(255,100,50,255))
            terminal.SendMessage("Temperature: " .. MT.HF.Round(thermal.Temperature, 0) .. "F", MT.DF.getTemperatureZone(thermal.Temperature, "color"))
            terminal.SendMessage("Heat Generated: " .. MT.HF.formatNumber(MT.HF.Round(DieselEngine.HeatGenerated, 0)) .. "BTU", Color(255,100,50,255))
            terminal.SendMessage("Cooling Needed: " .. MT.HF.formatNumber(MT.HF.Round(DieselEngine.CoolingNeeded, 0)) .. "BTU", Color.Gray)
            terminal.SendMessage("Cooling Available: " .. MT.HF.formatNumber(MT.HF.Round(DieselEngine.CoolingAvailable, 0)) .. "BTU", Color.Gray)
            terminal.SendMessage("Heat Surplus: " .. MT.HF.formatNumber(MT.HF.Round(DieselEngine.HeatSurplus, 0)) .. "BTU", Color.Gray)
           
            --terminal.SendMessage(string.format("%-5s", dieselEngine.fuelTime .. "m") .. " of Diesel Fuel remaining", Color(255,150,0,255))
            --terminal.SendMessage(string.format("%-5s", dieselEngine.oilTime .. "m") .. " of Oil remaining.", Color(255,150,0,255))
            --terminal.SendMessage(string.format("%-5s", dieselEngine.filterTime .. "m") .. " of Oil Filtration remaining.", Color(255,150,0,255))
            --terminal.SendMessage(string.format("%-5s", dieselEngine.oxygenTime .. "m") .. " of Oxygen remaining.", Color(255,150,0,255))
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