MT.F = {}


function MT.F.dieselEngine(item)
    --ADVANCED DIESEL DESIGN

    local oxygen
    local fuel

    --COMBUSTION
    if item.HasTag("combustion") then  
        print("This item has combustion!")
    end


        --COMPRESSION
        --FUEL
        --OXYGEN        
            -- PRIMARY: HULL - Not underwater Hull oxygen > 75%            
            if item.HullOxygenPercentage > 75.0 and not item.InWater then                
            print(item.HullOxygenPercentage)

            end
            -- AUXILLARY: O2 TANK - underwater or hull oxygen <= 75%

    --parts, oil, oil filter, fuel filter, fuel pump, engine. 
end

-- DETERIORATION: Diving Suits
function MT.F.divingSuit(item)
    local itemDepth = MT.HF.GetItemDepth(item)
    local pressurePenalty = 0

    -- Extended pressure protection: 
    -- We aren't going to change the pressure protection of the diving suit because we don't want to hardcode the original value. 
    -- This leaves the door open for others to make Mechtrauma suits.
    -- So instead, we will make the character ImmuneToPressure until we're ready to release them to fate. 
    if itemDepth < item.ParentInventory.Owner.PressureProtection * 2 and item.condition > 50 then -- if you're past 2x pressure with a half borken suit you deserve what you get.   
        item.ParentInventory.Owner.AddAbilityFlag(AbilityFlags.ImmuneToPressure)
        -- need to check if they are exposed to pressure. The depth does not tell us if they are in the ship. 
    else
        item.ParentInventory.Owner.RemoveAbilityFlag(AbilityFlags.ImmuneToPressure)
    end

    -- Now that we've saved them from certain death it is time to punish the diving suit. But lets make it proportionate to the excess pressure. 
    if itemDepth / item.ParentInventory.Owner.PressureProtection - 1 > 0.0 then
        -- Only damage the suit if outside the sub or in a leathal hull.
        if   item.ParentInventory.Owner.AnimController.CurrentHull == null or item.ParentInventory.Owner.AnimController.CurrentHull.LethalPressure >= 80.0 then
            pressurePenalty = 10.0 * (itemDepth / item.ParentInventory.Owner.PressureProtection - 1)
            print("pressurePenalty: ", pressurePenalty)
        end
    end

      -- Deteriorate the divingsuits 0.2 is the seed deterioration rate that is modifed by the config. 
      item.condition = item.condition - (0.2 * MT.Config.diveSuitDeteriorateRate + pressurePenalty) -- (item.WorldPosition.Y)


        -- This is where will will reduce suits max depth based on condition. 11/15/22 But will we really?
        -- note: 11/13/22 must find more secure place to store our evil plans.
  
  end