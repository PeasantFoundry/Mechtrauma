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


-- -------------------------------------------------------------------------- --
--                        MT DIESEL ELECTRIC GENERATOR                        --
-- -------------------------------------------------------------------------- --
-- called by updateItems

function MT.UF.dieselGenerator(item)
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
        local result = MT.DF.combustion(item, dieselSeries, targetPower)

        -- Generate Power: need to add the HP to kW conversion at some point

        -- set the power consumpition for the server
        simpleGenerator.PowerConsumption = -result.GeneratedHP
        --connection.Item.SendSignal(tostring(result.powerGenerated), "powergenerated")
        for k, connection in pairs(item.Connections) do
         if connection.name == "power_generated" then connection.Item.SendSignal(tostring(result.GeneratedHP), "powergenerated") end
        end

        -- set power to generate and send it to clients
        simpleGenerator.PowerToGenerate = result.GeneratedHP

        if SERVER then Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(simpleGenerator.SerializableProperties[Identifier("PowerToGenerate")], simpleGenerator)) end

        else
            -- invalid diesel series index
            print(item.Prefab.Identifier.Value, " - !IS NOT A VALID DIESEL SERIES!")
        end

    -- GENERATOR OFF
    else
        DieselEngine.IsRunning = false -- this tells if the generator is already running at the time of request so that ignition can be bypassed
        -- SOUND / LIGHT - dieselEngine sound is controlled by an XML light so it will toggle with the light(s)
        for k, component in pairs(item.Components) do
            if tostring(component) == "Mechtrauma.MTLight" then component.IsOn = false end
        end
    end
end
