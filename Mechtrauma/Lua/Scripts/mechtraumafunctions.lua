MT.F = {}
CentralComputerOnline = false
OxygenVentCount = 0

function MT.F.dieselEngine(item)
    --ADVANCED DIESEL DESIGN

    local oxygen
    local fuel

    --COMBUSTION
    if item.HasTag("combustion") then  
        --print("This item has combustion!")
    end

        --COMPRESSION
        --FUEL
        --OXYGEN        
            -- PRIMARY: HULL - Not underwater Hull oxygen > 75%            
            if item.HullOxygenPercentage > 75.0 and not item.InWater then                
            --print(item.HullOxygenPercentage)

            end
            -- AUXILLARY: O2 TANK - underwater or hull oxygen <= 75%

    --parts, oil, oil filter, fuel filter, fuel pump, engine. 
end

-- DIVINGSUIT: Deterioration and extended pressure protection. 
function MT.F.divingSuit(item)
    if MT.HF.ItemIsWornInOuterClothesSlot(item) then
        local itemDepth = MT.HF.GetItemDepth(item)
        local pressurePenalty = 0
        -- print(item.ConditionPercentage)
        -- Extended pressure protection: 
        -- We aren't going to change the pressure protection of the diving suit because we don't want to hardcode the original value. 
        -- This leaves the door open for others to make Mechtrauma suits.
        -- So instead, we will make the character ImmuneToPressure until we're ready to release them to fate. 
    
        -- If they've disabled deterioration, we will exclude extended pressure protection as well, it's only fair.
        if MT.Config.diveSuitDeteriorateRate > 0.0 then
            -- EXTENDED PRESSURE PROTECTION: If you're past 2x pressure with a half borken suit you deserve what you get.   
            if itemDepth < item.ParentInventory.Owner.PressureProtection * 2 and item.ConditionPercentage > 50 then 
                item.ParentInventory.Owner.AddAbilityFlag(AbilityFlags.ImmuneToPressure) -- we are merciful            
            else
                item.ParentInventory.Owner.RemoveAbilityFlag(AbilityFlags.ImmuneToPressure)
            end

            -- Now that we've saved them from certain death it is time to punish the diving suit instead. But lets make it proportionate to the excess pressure. 
            if itemDepth / item.ParentInventory.Owner.PressureProtection - 1 > 0.0 then
                -- Only damage the suit if outside the sub or in a leathal hull.
                if   item.ParentInventory.Owner.AnimController.CurrentHull == null or item.ParentInventory.Owner.AnimController.CurrentHull.LethalPressure >= 80.0 then
                    pressurePenalty = 10.0 * (itemDepth / item.ParentInventory.Owner.PressureProtection - 1)
                    --- debug print("pressurePenalty: ", pressurePenalty)
                end
            end

            -- Deteriorate the divingsuits. 0.2 is the seed deterioration rate that is modifed by the config, then tack the pressurePenalty on the end. 
            item.Condition = item.Condition - (0.2 * MT.Config.diveSuitDeteriorateRate + pressurePenalty) -- (item.WorldPosition.Y)
        end
    


            -- This is where will will reduce suits max depth based on condition. 11/15/22 But will we really?
            -- note: 11/13/22 must find more secure place to store our evil plans.
    end
end

-- CENTRAL COMPUTER: Ships computer
--MT.tagKeys.centralComputer = function(item)
function MT.F.centralComputer(item)
    if item.ConditionPercentage > 1 and item.GetComponentString("Powered").Voltage > 0.5 then
        CentralComputerOnline = true
        --print("Central computer online.")
    else
        CentralComputerOnline = false
        --print("Central computer offline.")
    end
end

-- CENTRAL COMPUTER: Ships computer
function MT.F.centralComputerNeeded(item)    
    if CentralComputerOnline then
        if item.GetComponentString("Steering") ~= nil then item.GetComponentString("Steering").CanBeSelected = true end
        if item.GetComponentString("Sonar") ~= nil then item.GetComponentString("Sonar").CanBeSelected = true end
        if item.GetComponentString("CustomInterface") ~= nil then item.GetComponentString("CustomInterface").CanBeSelected = true end
        if item.GetComponentString("MiniMap") ~= nil then item.GetComponentString("MiniMap").CanBeSelected = true end
     
    elseif not CentralComputerOnline then        
        if item.GetComponentString("Steering") ~= nil then item.GetComponentString("Steering").CanBeSelected = false end
        if item.GetComponentString("Sonar") ~= nil then item.GetComponentString("Sonar").CanBeSelected = false end
        if item.GetComponentString("CustomInterface") ~= nil then item.GetComponentString("CustomInterface").CanBeSelected = false end
        if item.GetComponentString("MiniMap") ~= nil then item.GetComponentString("MiniMap").CanBeSelected = false end
    end
        
end

-- STEAM TURBINE: No more hot swapping those bearings!  
function MT.F.steamTurbine(item)
    local index = 0
    if item.ConditionPercentage > 1 and item.GetComponentString("Powered").Voltage > 0.5 then
        
        while(index < item.OwnInventory.Capacity) do
            if item.OwnInventory.GetItemAt(index) ~= nil then item.OwnInventory.GetItemAt(index).HiddenInGame = false end
            index = index + 1
        end

    else
        while(index < item.OwnInventory.Capacity) do
            if item.OwnInventory.GetItemAt(index) ~= nil then item.OwnInventory.GetItemAt(index).HiddenInGame = false end
            index = index + 1
        end      
    end
end