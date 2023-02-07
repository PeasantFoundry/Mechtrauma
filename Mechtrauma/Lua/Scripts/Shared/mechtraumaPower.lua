MT.GridUpdateCooldown = 0
MT.GridUpdateInterval = 1
MT.gridCyclestime = MT.GridUpdateInterval/60 -- Time in seconds that transpires between updates

-- engine ignition types
function MT.F.relayIgnition(item)
    local ignition = item.GetComponentString("RelayComponent").IsOn
    return ignition
end

function MT.F.sGeneratorIgnition(item)
    local ignition = MT.HF.findComponent(item, "SimpleGenerator").IsOn
    return ignition
end

--table for dieselEngine models
MT.DE = {
    s5000D={
        maxHorsePower=5000*1.5,
        oilSlots=2,
        filterSlots=1,
        dieselFuelSlots=6,
        auxOxygenSlots=3,
        name="s5000D",
        ignitionType=MT.F.sGeneratorIgnition
    },
    s3000D={
        maxHorsePower=3000*1.5,
        oilSlots=1,
        filterSlots=1,
        dieselFuelSlots=4,
        auxOxygenSlots=2,
        name="s3000D",
        ignitionType=MT.F.sGeneratorIgnition
    },
    sC2500Da={
        maxHorsePower=2500*1.5,
        oilSlots=2,
        filterSlots=1,
        dieselFuelSlots=3,
        auxOxygenSlots=3,
        name="s2500Da",
        ignitionType=MT.F.sGeneratorIgnition
    },
    sC2500Db={
        maxHorsePower=2500*1.5,
        oilSlots=2,
        filterSlots=1,
        dieselFuelSlots=3,
        auxOxygenSlots=3,
        name="s2500Db",
        ignitionType=MT.F.sGeneratorIgnition
    },
    s1500D={
        maxHorsePower=1500*1.5,
        oilSlots=1,
        filterSlots=1,
        dieselFuelSlots=3,
        auxOxygenSlots=1,
        name="s1500D",
        ignitionType=MT.F.sGeneratorIgnition
    },
    PDG500={
        maxHorsePower=500*1.5,
        oilSlots=1,
        filterSlots=1,
        dieselFuelSlots=1,
        auxOxygenSlots=1,
        name="PDG500",
        ignitionType=MT.F.sGeneratorIgnition
    },
    PDG250={
        maxHorsePower=250*1.5,
        oilSlots=1,
        filterSlots=1,
        dieselFuelSlots=1,
        auxOxygenSlots=1,
        name="PDG250",
        ignitionType=MT.F.sGeneratorIgnition
    }
}

-- called by updateItems
function MT.F.dieselGenerator(item)
    -- convert load(kW) to targetPower(HP) 1.341022   
    local simpleGenerator = MT.HF.findComponent(item, "SimpleGenerator")
    local powered = item.GetComponentString("Powered")
    local targetPower = simpleGenerator.GridLoad
    
    -- print(simpleGenerator.IsOn)
    -- print("Load: " .. tostring(simpleGenerator.GridLoad))
    -- print("PowerOut: " .. tostring(simpleGenerator.PowerOut.Grid.Power))

    -- check for a diesel series index
    if MT.DE[item.Prefab.Identifier.Value] ~= nil then
        -- Results: Pass the ingition type, diesel series, and target power to the dieslEngine function to attempt combustion
        local result = MT.F.dieselEngine(item, MT.DE[item.Prefab.Identifier.Value].ignitionType(item), MT.DE[item.Prefab.Identifier.Value], targetPower)
        
        -- Generate Power: need to add the HP to kW conversion at some point
        
        -- set the power consumpition for the server        
        simpleGenerator.PowerConsumption = -result.powerGenerated
        
        -- set power to generate and send it to clients
        simpleGenerator.PowerToGenerate = result.powerGenerated 
        if SERVER then Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(simpleGenerator.SerializableProperties[Identifier("PowerToGenerate")], simpleGenerator)) end

    else
        -- invalid diesel series index
        print(item.Prefab.Identifier.Value, " - !IS NOT A VALID DIESEL SERIES!")
    end
end

-- called by MT.F.dieselGenerator: calculates if and how much power an engine should be producing
function MT.F.dieselEngine(item, ignition, dieselSeries, targetPower)
    --ADVANCED DIESEL DESIGN
    -- HP:kW = 1:0.75
    -- HP:diesel(l) 1:0.2        
    local gridCycles = 60
    local dieselEngine = {}
    local dieselFuelNeededCL = MT.Config.DieselHorsePowerRatioCL * MT.HF.Clamp(targetPower, 100, dieselSeries.maxHorsePower) / 3600 * MT.Deltatime --min power is idle speed
    local oxygenNeeded = dieselFuelNeededCL * MT.Config.DieselOxygenRatioCL -- this is where we cheat and pretend that 1 condition of oxygen is equal to 1 condtion of diesel    
    
    -- oxygen    
    local auxOxygenItems = {}
    local auxOxygenVol = 0
    local hullOxygenPercentage = 0
    -- set hullOxygenPercentage to 0 when submerged or outside of a hull.
    if item.InWater == false and item.FindHull() ~= nil then hullOxygenPercentage = item.FindHull().OxygenPercentage else hullOxygenPercentage = 0 end

    -- diesel
    local dieselFuelItems = {}
    local dieselFuelVol = 0
    -- oil
    local oilItems = {}
    local oilVol = 0
    -- filtration
    local oilFiltrationItems = {}
    local oilfiltrationSlots = dieselSeries.filterSlots
    local oilFiltrationVol = 0
    -- Damage and Reduction
    local frictionDamage = MT.Config.FrictionBaseDPS * MT.Deltatime * dieselSeries.oilSlots -- convert baseDPS to DPD and multiply for oil capacity    
    local oilDeterioration = MT.Config.OilBaseDPS * MT.Deltatime * dieselSeries.oilSlots -- convert baseDPS to DPD and multiply for capacity    


    -- INVENTORY: loop through the inventory and see what we have
    local index = 0
    while(index < item.OwnInventory.Capacity) do
    if item.OwnInventory.GetItemAt(index) ~= nil then 
        local containedItem = item.OwnInventory.GetItemAt(index)
        -- get diesel item(s)
        if containedItem.HasTag("diesel_fuel") and containedItem.Condition > 0 then
            table.insert(dieselFuelItems, containedItem)
            dieselFuelVol = dieselFuelVol + containedItem.Condition
        -- get oil item(s)    
        elseif containedItem.HasTag("oil") and containedItem.Condition > 0 then
            table.insert(oilItems, containedItem)
            oilVol = oilVol + containedItem.Condition
            frictionDamage = frictionDamage - MT.Config.FrictionBaseDPS * MT.Deltatime -- LUBRICATE: reduce *possible* friction damage for this oil slot  
        -- get oil filtration item(s)
        elseif containedItem.HasTag("oilfilter") and containedItem.Condition > 0 then
            table.insert(oilFiltrationItems, containedItem)
            oilDeterioration = oilDeterioration - oilDeterioration * (MT.Config.OilFiltrationM / oilfiltrationSlots) -- FILTER: reduce *possible* oil damage for this filter slot  
            oilFiltrationVol = oilFiltrationVol + containedItem.Condition
        -- get aux oxygen item(s)    
        elseif containedItem.HasTag("refillableoxygensource") and containedItem.Condition > 0 then 
            table.insert(auxOxygenItems, containedItem)
            auxOxygenVol = auxOxygenVol + containedItem.Condition
        end
    end
    index = index + 1
    end
         
    -- fuelCheck
    if dieselFuelVol > dieselFuelNeededCL then dieselEngine.fuelCheck = true print("FUEL CHECK: PASSED!") end
    -- oxygenCheck
    if hullOxygenPercentage > 75 or auxOxygenVol > oxygenNeeded then dieselEngine.oxygenCheck = true print("O2 CHECK: PASSED! Hull O2: ", hullOxygenPercentage, "AUX O2 Volume: ", auxOxygenVol) 
    
    else
        print("O2 CHECK: FAILED! Hull O2: ", hullOxygenPercentage, " AUX O2 Volume: ", auxOxygenVol, " O2 NEEDED: ", oxygenNeeded)
    end
    
    -- attempt combustion
    if item.Condition > 0 and ignition and dieselEngine.fuelCheck and dieselEngine.oxygenCheck  then
        -- combustion succeeded
        dieselEngine.combustion = true
        -- set the generated amount to be returned
        dieselEngine.powerGenerated = MT.HF.Clamp(targetPower, 0, dieselSeries.maxHorsePower)

        -- DETERIORATION: 
        -- burn oxygen       
        if hullOxygenPercentage >= 75 then  -- burn hull oxygen when above 75%
            item.FindHull().Oxygen = item.FindHull().Oxygen - (oxygenNeeded * 2250) -- 2250 hull oxygen ~= 1 oxygen condition                     
        else
            MT.HF.subFromListSeq (oxygenNeeded, auxOxygenItems) -- burn auxOxygen
        end
        -- burn diesel
        MT.HF.subFromListSeq (dieselFuelNeededCL, dieselFuelItems) -- burn diesel sequentially, improves resource management 
        -- burn oil
        MT.HF.subFromListEqu(oilDeterioration, oilItems) -- total oilDeterioration is spread across all oilItems. (being low on oil will make the remaining oil deteriorate faster)
        -- deteriorate filter(s)
        MT.HF.subFromListAll((MT.Config.OilFilterDPS * MT.Deltatime), oilFiltrationItems) -- apply deterioration to each filters independently, they have already reduced oil deterioration
        -- friction damage
        item.Condition = item.Condition - frictionDamage

        -- DEBUG PRINTING: print("Diesel Fuel will last for: ",(dieselFuelVol / dieselFuelNeededCL) * MT.Deltatime/ 60, " minutes.")
        -- DEBUG PRINTING: print("Oil will last for: ", oilVol / oilDeterioration * MT.Deltatime / 60)
        -- DEBUG PRINTING: print("Filration will last for: ", (oilFiltrationVol / MT.Config.OilFilterDPS) / 60 ) -- no need to calculate the deltaTime here since calc is in dps

        -- SOUND / LIGHT - dieselEngine sound is controlled by an XML light so it will toggle with the light(s)
        for k, item in pairs(item.Components) do
            if tostring(item) == "Barotrauma.Items.Components.LightComponent" then item.IsOn = true end
            -- print(item,": ", item.IsOn)
        end

        return dieselEngine
    else
        -- combustion failed        
        dieselEngine.combustion = false
        dieselEngine.powerGenerated = 0

        -- SOUND / LIGHT - dieselEngine sound is controlled by an XML light so it will toggle with the light(s)
        for k, item in pairs(item.Components) do
            if tostring(item) == "Barotrauma.Items.Components.LightComponent" then item.IsOn = false end
        end

        return dieselEngine
    end

end

Hook.Patch(
  "Barotrauma.Items.Components.SimpleGenerator",
  "GetCurrentPowerConsumption",
  function(instance, ptable)
    instance.PowerConsumption = 0
  
    -- Return -1 if the generator should provide power
    if instance.IsOn then
      return -1
    end
    return 0
  end, Hook.HookMethodType.After)

Hook.Patch(
  "Barotrauma.Items.Components.SimpleGenerator",
  "MinMaxPowerOut",
  function(instance, ptable)
    load = ptable["load"]
    
    -- Set power consumption from PowerToGenerate    
    instance.PowerConsumption = -instance.PowerToGenerate
    
  end, Hook.HookMethodType.Before)
