
local buffer = {} -- signal buffer

Hook.Add("item.equip", "MT.hotItemEquipped", function(item, character)
  local thermal = MTUtils.GetComponentByName(item, "Mechtrauma.Thermal")

  -- burn the fool holding this
  if thermal and thermal.Temperature ~= nil then
    if thermal.Temperature > 150 then
      --MT.HF.AddAffliction(character,"burn",5)
    end
  end

  if item.HasTag("engineblock") then
    print("THIS IS TOO HEAVY YOU CANOT HOLD IT")
    if item.InWater == false then
      --MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.ItemContainer").KeepOpenWhenEquipped = true
      --MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.ItemContainer").KeepOpenWhenEquippedBy(item.GetRootInventoryOwner())
      item.Drop()
    else
      print("Why would this run?")
      --MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.ItemContainer").KeepOpenWhenEquipped = false
      --MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.ItemContainer").KeepOpenWhenEquippedBy(item.GetRootInventoryOwner())
    end
  end

end)

Hook.Add("Mechtrauma.PlayerLadderDetector::OnLadderValueUpdate","MT.LadCheck", function(component, character)
  if component.IsOnLadder then
    character.SpeedMultiplier = MT.SpeedTable[component.Id].LadderSpeed
  else
    if character ~= nil then
      character.SpeedMultiplier = MT.SpeedTable[component.Id].NormalSpeed
    end
  end
end)

Hook.Add("electricalRepair.OnFailure", "MT.electricalRepairFailure", function(effect, deltaTime, item, targets, worldPosition)
  local character
  -- if the human target isn't 10, loop through the targets and find the human
  if tostring(targets[10]) == "Human" then
     character = targets[10]
    else
      for k, v in pairs(targets) do
        if tostring(v) == "Human" then -- instead of looping, would it be possible to make a target indexed table instead of key indexed?
          character = targets[k]
          end
      end
  end
  -- what are we holding? this will come in handy later
  local rightHandItem = character.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)
  local leftHandItem = character.Inventory.GetItemInLimbSlot(InvSlotType.LeftHand)

  -- is electrocution enabled?
  if MT.Config.DisableElectrocution == true then
    -- check if you're a junctionbox or a fusepanel
    if item.HasTag("junctionbox") then -- need to add fuse panel support later
      -- i don't know why an item would have a junctionbox tag but no PowerTransfer Component but this makes the code harder to break
      local powerComponent = MTUtils.GetComponentByName(item, ".PowerTransfer");
      local electrocutionStrength = MT.HF.Clamp((powerComponent.PowerLoad/100 or 2000) * (powerComponent.Voltage or 1), 1, 200)
      print("electrocutionStrength: ", electrocutionStrength)

      -- explosion
      MT.HF.AddAffliction(character,"stun",0.25)
      local explosion = Explosion(50, 100, 0, 0, 0, 0, 0)
      explosion.Explode(item.WorldPosition - Vector2(0, 50), item)

      MT.HF.AddAffliction(character,"electrocution", electrocutionStrength)
    end
  else
    -- if not, follow vanilla functionality.
    MT.HF.AddAffliction(character,"burn",5)
    MT.HF.AddAffliction(character,"stun",4)
  end

end)

  --[[ Check the hands for an item with the tag "electricalrepairtool" in sequence.
      if rightHandItem.HasTag("electricalrepairtool") then
        NT.TraumamputateLimb(targets[8],LimbType.RightArm)
      elseif leftHandItem.HasTag("electricalrepairtool") then
        NT.TraumamputateLimb(targets[8],LimbType.LeftArm)
      end]]


Hook.Add("mechtraumaAmputation.OnFailure", "MT.amputation", function(effect, deltaTime, item, targets, worldPosition)

  local character
  -- if the human target isn't 6, loop through the targets and find the human
  if tostring(targets[6]) == "Human" then
     character = targets[6]
    else
      for k, v in pairs(targets) do
        if tostring(v) == "Human" then
          character = targets[k]
          end
      end
  end
  -- what are we holding?
  local rightHandItem = character.Inventory.GetItemInLimbSlot(InvSlotType.RightHand)
  local leftHandItem = character.Inventory.GetItemInLimbSlot(InvSlotType.LeftHand)

  -- Check to see if NT is enabled
  if NT and not character.IsBot then -- Yes? Neurotrauma amputation time!
    -- Check the hands for an item with the tag "mechanicalrepairtool" in sequence to avoid cutting off both arms at once. We are merciful.
    if rightHandItem.HasTag("mechanicalrepairtool") then
      NT.TraumamputateLimb(character,LimbType.RightArm)
    elseif leftHandItem.HasTag("mechanicalrepairtool") then
      NT.TraumamputateLimb(character,LimbType.LeftArm)
    end
  else
      --No? do something vanilla
      if rightHandItem.HasTag("mechanicalrepairtool") then
        MT.HF.AddAfflictionLimb(character,"lacerations",LimbType.RightArm,100)
      elseif leftHandItem.HasTag("mechanicalrepairtool") then
        MT.HF.AddAfflictionLimb(character,"lacerations",LimbType.LeftArm,100)
      end
  end

end)

-- Average Component hook
Hook.Add("signalReceived.average_component", "MT.averageComponent", function(signal, connection)
    if buffer[connection.Item] == nil then buffer[connection.Item] = {} end

    local itemBuffer = buffer[connection.Item]
    local connectionSum = 0
    local connectionCount = 0
    if connection.Name == "*input_1" then
      itemBuffer[1] = signal.value
    end

    if connection.Name == "input_2" then
      itemBuffer[2] = signal.value
    end

    if connection.Name == "input_3" then
      itemBuffer[3] = signal.value
    end

    if connection.Name == "input_4" then
      itemBuffer[4] = signal.value
    end

    if connection.Name == "input_5" then
      itemBuffer[5] = signal.value
    end

    if connection.Name == "input_6" then
      itemBuffer[6] = signal.value
    end

  -- *input_1 is the trigger signal, we will only calculate and send the output when the trigger signal is received
  if itemBuffer[1] ~= nil then
    for k, v in pairs(itemBuffer) do
      connectionSum = connectionSum + v
      connectionCount = connectionCount + 1
    end
    connection.Item.SendSignal(tostring(math.floor(connectionSum / connectionCount)), "output")
  end
  -- clear input_1 from storage so that the output will not be triggered until *input_1 is received again
  itemBuffer[1] = nil
end)

-- DIESEL GENERATOR: Engine On - wtf is this? 12/31/23
--[[Hook.Add("dieselGenerator_on.OnUse", "MT.dieselGenerator_on", function(effect, deltaTime, item, targets, worldPosition, client)
  -- call the blood report function
  MT.F.reportTypes.blood(item)

end)
]]
-- MEDICAL TABLET: Hematology Report
Hook.Add("medicalTablet_hR.OnUse", "MT.hematologyReport", function(effect, deltaTime, item, targets, worldPosition, client)
  -- call the blood report function
  MT.F.reportTypes.blood(item)

end)

-- MEDICAL TABLET: Pharmacy Report
Hook.Add("medicalTablet_pR.OnUse", "MT.pharmacyReport", function(effect, deltaTime, item, targets, worldPosition, client)
  -- call the pharmacy report function
  MT.F.reportTypes.pharmacy(item)

end)

Hook.Add("securityControl_auth.OnUse", "MT.idScan", function(effect, deltaTime, item, targets, worldPosition, client)
  local terminal = MTUtils.GetComponentByName(item, "Barotrauma.Items.Components.Terminal")

  if item.OwnInventory.GetItemAt(0) ~= nil then
    local scannedItem = item.OwnInventory.GetItemAt(0)
    if scannedItem.Prefab.Identifier.Value == "idcard" then
      local idCard = MTUtils.GetComponentByName(scannedItem, "Barotrauma.Items.Components.IdCard")

      MT.HF.SendTerminalColorMessage(item, terminal, Color(255, 50, 25, 255), "*******AUTHORIZATION REQUEST*******")
      terminal.ShowMessage = MT.HF.Round(Game.GameScreen.GameTime, 0) .. ".T Requestor: " .. idCard.OwnerName
      terminal.ShowMessage = MT.HF.Round(Game.GameScreen.GameTime, 0) .. ".T Employee ID: " .. idCard.SubmarineSpecificID
      terminal.ShowMessage = idCard.OwnerTags
      local linkedItems = {}
      for k, linkedItem in pairs(item.linkedTo) do
        if linkedItem.HasTag("door") then MTUtils.GetComponentByName(linkedItem, "Barotrauma.Items.Components.Door").TrySetState(true, false)
        end
      end

      --terminal.ShowMessage = MT.HF.Round(Game.GameScreen.GameTime, 0) .. ".T Tags: " .. idCard.OwnerTags
      --terminal.ShowMessage = MT.HF.Round(Game.GameScreen.GameTime, 0) .. ".T Description: " .. idCard.Description
      terminal.ShowMessage = idCard.OwnerJob

      item.SendSignal("test", "dataout")
    else
      MT.HF.SendTerminalColorMessage(item, terminal, Color(255, 50, 25, 255), "*******UNKNOWN REQUEST*******")
    end
  -- Request with no ID
  else
    MT.HF.SendTerminalColorMessage(item, terminal, Color(255, 50, 25, 255), "*******INSERT AUTHORIZATION CARD*******")
  end
end)

-- ***** REPAIR KIT  *****

Hook.Add("repairKit_attemptRepair.OnUse", "MT.attemptRepair", function(effect, deltaTime, item, targets, worldPosition, client)
  MT.F.attemptRepair(item, item.OwnInventory.GetItemAt(0))
end)
-- --

-- ***** DIAGNOSTIC TABLET *****

Hook.Add("diagnosticTablet_linkDiagnostics.OnUse", "MT.linkTablet", function(effect, deltaTime, item, targets, worldPosition, client)
  print("WE GOT HERE!")
  terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
  terminal.IsActive = false
end)
-- ----- DIAGNOSE ITEM -----
Hook.Add("diagnosticTablet_diagnoseItem.OnUse", "MT.diagnoseItem", function(effect, deltaTime, item, targets, worldPosition, client)

  MT.C.tabletDiagnoseItem(item, item.OwnInventory.GetItemAt(0))

end)

-- ***** MAINTENANCE TABLET *****

-- ----- REPORT POWER -----
Hook.Add("maintenanceTablet_pcr.OnUse", "MT.powerConsumptionReport", function(effect, deltaTime, item, targets, worldPosition, client)
  -- call the power report function
  MT.F.reportTypes.power(item)
end)



-- ----- REPORT c02 -----
Hook.Add("maintenanceTablet_csr.OnUse", "MT.co2FilterStatusReport", function(effect, deltaTime, item, targets, worldPosition, client)
  MT.F.reportTypes.c02(item)
end)

-- ----- REPORT PUMP -----
Hook.Add("maintenanceTablet_pr.OnUse", "MT.ballastPumpReport", function(effect, deltaTime, item, targets, worldPosition, client)
  MT.F.reportTypes.pump(item)
end)


Hook.Add("maintenanceTablet_fsr.OnUse", "MT.fuseStatusReport", function(effect, deltaTime, item, targets, worldPosition, client)
  -- call the fuse report function
  MT.F.reportTypes.fuse(item)
end)


--[[
Timer.Wait(function()
  if NTCyb ~= nil then
      NTCyb.ItemMethods.mechweldingtool = NTCyb.ItemMethods.weldingtool
  end
end,1000)
]]
