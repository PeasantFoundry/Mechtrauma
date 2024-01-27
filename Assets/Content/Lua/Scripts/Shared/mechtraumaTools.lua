-- TODO add some comments and clean up the code, this is bad for now lol
-- add split up to funcion's file and the file with hooks and shit

--local findtarget = dofile(... .. "/Lua/findtarget.lua")
local findtarget = {}
MT.T = {}

-- ---------------------------- linking functions --------------------------- --
local function LinkAdd(target, otherTarget)
    target.AddLinked(otherTarget)
    otherTarget.AddLinked(target)
    otherTarget.DisplaySideBySideWhenLinked = true
    target.DisplaySideBySideWhenLinked = true
end

local function LinkRemove(target, otherTarget)
    target.RemoveLinked(otherTarget)
    otherTarget.RemoveLinked(target)
end
-- messages
local function AddMessage(text, client)
    local message = ChatMessage.Create("Lua Linker", text, ChatMessageType.Default, nil, nil)
    message.Color = Color(60, 100, 255)

    if CLIENT then
        Game.ChatBox.AddMessage(message)
    else
        Game.SendDirectChatMessage(message, client)
    end
end

local links = {}


if CLIENT and Game.IsMultiplayer then
    Networking.Receive("lualinker.add", function (msg)
        local target = Entity.FindEntityByID(msg.ReadUInt16())
        local otherTarget = Entity.FindEntityByID(msg.ReadUInt16())
        LinkAdd(target, otherTarget)
    end)

    Networking.Receive("lualinker.remove", function (msg)
        local target = Entity.FindEntityByID(msg.ReadUInt16())
        local otherTarget = Entity.FindEntityByID(msg.ReadUInt16())
        LinkRemove(target, otherTarget)
    end)
end

-- -------------------------------------------------------------------------- --
--                                    HOOKS                                   --
-- -------------------------------------------------------------------------- --

-- infared themometer
Hook.Add("mtThermometer.onUse", "mtLinker.mtLinker", function(statusEffect, delta, item)
    local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
    local target =  item.ParentInventory.Owner.FocusedItem

    if CLIENT and Game.IsMultiplayer then
        return
    end

   --SoundPlayer.PlaySound("%ModDir%/Sound/receipt1.ogg", target.WorldPosition)
    if target == nil then
        terminal.SendMessage("TOO FAST", Color(255,100,50,255))
        return
    else
        local thermal = MTUtils.GetComponentByName(target, "Mechtrauma.Thermal")
        if  thermal and thermal.Temperature ~= nil then
            terminal.SendMessage(MT.HF.Round(thermal.Temperature, 0) .. "F", Color(255,100,50,255))
        end
    end

    --print (tostring(target))
    --if thermal then print("Target has a temperature of " .. thermal.Temperature) end

end)

Hook.Add("mtMoblie_readTags.OnUse", "MT.moblie", function(effect, deltaTime, item, targets, worldPosition, client)
    local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
    local targetItem
    if item.OwnInventory.GetItemAt(0) ~= nil then
        targetItem = item.OwnInventory.GetItemAt(0)
    elseif item.ParentInventory.Owner.FocusedItem ~= nil then
        targetItem = item.ParentInventory.Owner.FocusedItem
    else
        -- nothing to diagnose
      terminal.TextColor = Color(250,100,60,255)
      terminal.SendMessage("*DIAGNOSTICS RESULT*")
      terminal.SendMessage("!NO TARGET!")
      terminal.SendMessage("****END REPORT****")
      return
    end

    terminal.TextColor = Color.Gray
    MT.HF.BlankTerminalLines(terminal, 10)
    terminal.SendMessage("PROCESSING REQUEST...", Color.Gray)
    MT.HF.BlankTerminalLines(terminal, 1)
    terminal.TextColor = Color(250,100,60,255)

    local tagTable = MT.HF.Split(string.lower(targetItem.Tags),",")
    --terminal.TextColor = Color(250,100,60,255)
    terminal.SendMessage("*DIAGNOSTIC RESULT*")
    terminal.SendMessage("TARGET: " .. targetItem.name, Color(250,100,60,255))
    for k, tag in pairs(tagTable) do
        terminal.SendMessage(" TAG: " .. tag, Color(250,100,60,255))
    end
    terminal.SendMessage("****END REPORT****")

  end)

-- hand truck
Hook.Add("mtHandTruck.onUse", "MT.handTruck", function(statusEffect, delta, item)
    local target =  item.ParentInventory.Owner.FocusedItem
    -- move the target into the hand truck, if you can
    if target ~= nil then item.OwnInventory.TryPutItem(target, owner) end

    if CLIENT and Game.IsMultiplayer then
        return
    end

end)

-- hand cuffs
Hook.Add("mtHandCuff.onUse", "MT.cuffs", function(statusEffect, delta, item)
    local source = item.ParentInventory.Owner
    local target = item.ParentInventory.Owner.FocusedCharacter
    if not target then return end -- abort if there is no target

    print("Source: ", tostring(source.name))
    print("Target: ", tostring(target.name))


    if CLIENT and Game.IsMultiplayer then
        return
    end

    -- HANDCUFFS LOGIC
    if item.HasTag("handcuffs") then
        if target ~= nil and target.IsKnockedDown then
            target.Inventory.TryPutItem(item, nil, {InvSlotType.Any}, true)
            item.AddTag("locked") -- lock the handcuffs (XML statusEffect locks the characters hands)
            item.HiddenInGame = true -- stop the handcuffs from bring removed without being unlocked
            Timer.Wait(function()  print(target.name .. " LockHands == ", target.LockHands) end, 1000)

        end
    -- HANDCUFFS KEY LOGIC
    elseif item.HasTag("handcuffskey") then
        local handcuffs = target.Inventory.FindItemByTag("handcuffs")
        handcuffs.HiddenInGame = false -- make the handcuffs moveable again
        handcuffs.ReplaceTag("locked","") -- unlock the hand cuffs so that they are safe to hold.
        source.Inventory.TryPutItem(handcuffs, nil, {InvSlotType.Any}, true)
    end
end)

-- ----------------------------- MT ITEM LINKER ----------------------------- --
Hook.Add("mtLinker.onUse", "mtLinker.mtLinker", function(effect, deltaTime, item, targets, worldPosition, client)
    MT.T.Linker(item)
end)

-- ----------------------------- ONE WAY LINKER ----------------------------- --
function MT.T.diagnosticLink(item, diagnosticProgram)
    local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
    local mtc = MTUtils.GetComponentByName(item, "Mechtrauma.MTC")
    local target = findtarget.findtarget(item)

    --local target = findtarget.findtarget(item)

    -- SERVER ONLY
    if CLIENT and Game.IsMultiplayer then return end
    local owner = findtarget.FindClientCharacter(item.ParentInventory.Owner)

    -- NO TARGET
    if target == nil then
        if terminal then terminal.SendMessage("NO TARGET", Color(255,100,50,255)) else AddMessage("No item found", owner) end
        return
    end

    local otherTarget = item

    --// clear any previous diagnostic links
    if MT.C.HD[item].MTC.cd.dieseldoctor then
        -- set the diagnostic link to the target
        MT.C.HD[item].MTC.cd.dieseldoctor.diagnosticLinkID = target.ID
        terminal.SendMessage("Diagnostic link set to " .. tostring(target), Color(255,100,50,255))
    end
end

-- ----------------------------- TWO WAY LINKER ----------------------------- --
function MT.T.Linker(effect, deltaTime, item, targets, worldPosition, client)
    local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
    local target = findtarget.findtarget(item)
    --local target = findtarget.findtarget(item)

    -- SERVER ONLY
    if CLIENT and Game.IsMultiplayer then return end
    local owner = findtarget.FindClientCharacter(item.ParentInventory.Owner)

    -- NO TARGET
    if target == nil then
        if terminal then terminal.SendMessage("NO TARGET", Color(255,100,50,255)) else AddMessage("No item found", owner) end
        return
    end


    if links[item] == nil then
        links[item] = target
        -- terminal vs chat message
        if terminal then terminal.SendMessage("Link Start: " .. target.Name, Color(255,100,50,255)) else AddMessage(string.format("Link Start: \"%s\"", target.Name), owner) end
        findtarget.currsor_pos = 0
    else
        local otherTarget = links[item]
        if otherTarget == target then
            AddMessage("The linked items cannot be the same", owner)
            links[item] = nil
            return
        end

        for key, value in pairs(target.linkedTo) do
            if value == otherTarget then
                LinkRemove(target, otherTarget)

                AddMessage(string.format("Removed link from \"%s\" and \"%s\"", target.Name, otherTarget.Name), owner)
				links[item] = nil

                if SERVER then
                    -- lets send a net message to all clients so they remove our link
                    local msg = Networking.Start("lualinker.remove")
                    msg.WriteUInt16(UShort(target.ID))
                    msg.WriteUInt16(UShort(otherTarget.ID))
                    Networking.Send(msg)
                end

                return
            end
        end

        LinkAdd(target, otherTarget)

        local text = string.format("Linked \"%s\" into \"%s\"", otherTarget.Name, target.Name)
        AddMessage(text, owner)

        if SERVER then
            -- lets send a net message to all clients so they add our link
            local msg = Networking.Start("lualinker.add")
            msg.WriteUInt16(UShort(target.ID))
            msg.WriteUInt16(UShort(otherTarget.ID))
            Networking.Send(msg)
        end

        links[item] = nil
        findtarget.currsor_pos = 0
    end
end
-- -------------------------------------------------------------------------- --
--                               more functions                               --
-- -------------------------------------------------------------------------- --

    -- findowner
    findtarget.FindClientCharacter = function(character)
        if CLIENT then return nil end

        for key, value in pairs(Client.ClientList) do
            if value.Character == character then
                return value
            end
        end
    end
-- wonder what this does?  run once on init? dosen't seem to be in a function...
    findtarget.cursor_pos = Vector2(0, 0)
    findtarget.cursor_updated = false

    -- -------------------------------------------------------------------------- --
    --                                  functions                                 --
    -- -------------------------------------------------------------------------- --
    local function FindClosestItem(submarine, position)
        local closest = nil
        for key, value in pairs(submarine and submarine.GetItems(false) or Item.ItemList) do
            if value.Linkable and not value.HasTag("notlualinkable") and not value.HasTag("crate") and not value.HasTag("ammobox") and not value.HasTag("door") and not value.HasTag("smgammo") and not value.HasTag("hmgammo") and value.NonInteractable == false then
                -- check if placable or if it does not have holdable component
                local check_if_p_or_nh = false
                local holdable = value.GetComponentString("Holdable")
                if holdable == nil then
                    check_if_p_or_nh = true
                else
                    if holdable.attachable == true then
                        check_if_p_or_nh = true
                    end
                end
                if check_if_p_or_nh == true then
                    if Vector2.Distance(position, value.WorldPosition) < 100 then
                        if closest == nil then closest = value end
                        if Vector2.Distance(position, value.WorldPosition) <
                            Vector2.Distance(position, closest.WorldPosition) then
                            -- this should prevent items that are inside inventories from being linkable
                            if value.ParentInventory == nil then
                                closest = value
                            end
                        end
                    end
                end
            end
        end
        return closest
    end

    findtarget.findtarget = function(item)
        if CLIENT and Game.IsMultiplayer then
            -- for better accuracy
            local client_cursor_pos = (item.ParentInventory.Owner).CursorWorldPosition
            local msg = Networking.Start("lualinker.clientsidevalue")
            msg.WriteSingle(client_cursor_pos.X)
            msg.WriteSingle(client_cursor_pos.Y)
            Networking.Send(msg)
            return
        end

        -- SinglePlayer
        if not Game.IsMultiplayer then
            findtarget.cursor_pos = item.ParentInventory.Owner.CursorWorldPosition
        end
        -- fallback
        if not findtarget.cursor_updated and Game.IsMultiplayer then
            findtarget.cursor_pos = item.WorldPosition
        end

        if item.ParentInventory == nil or item.ParentInventory.Owner == nil then return end

        local target = FindClosestItem(item.Submarine, findtarget.cursor_pos)
        return target
    end

    Networking.Receive("lualinker.clientsidevalue", function(msg)
        local position = Vector2(msg.ReadSingle(), msg.ReadSingle())
        findtarget.cursor_pos = position
        findtarget.cursor_updated = true
    end)

    return findtarget

