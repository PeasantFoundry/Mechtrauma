-- TODO add some comments and clean up the code, this is bad for now lol
-- add split up to funcion's file and the file with hooks and shit

--local findtarget = dofile(... .. "/Lua/findtarget.lua")
local findtarget = {}

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
    
   
   SoundPlayer.PlaySound("%ModDir%/Sound/receipt1.ogg", target.WorldPosition)
    
    if target == nil then
        terminal.SendMessage("ERR", Color(255,100,50,255))
        return
    else
        local thermal = MTUtils.GetComponentByName(target, "Mechtrauma.Thermal")
        if  thermal and thermal.Temperature ~= nil then
            terminal.SendMessage(MT.HF.Round(thermal.Temperature, 0) .. "F", Color(255,100,50,255))
        end
    end

    if CLIENT and Game.IsMultiplayer then
        return
    end

    --print (tostring(target))
    --if thermal then print("Target has a temperature of " .. thermal.Temperature) end

end)

-- handtruck 
Hook.Add("mtHandtruck.onUse", "mtLinker.mtLinker", function(statusEffect, delta, item)
    local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
    local target =  item.ParentInventory.Owner.FocusedItem
    -- move the target into the hand truck, if you can
    if target ~= nil then item.OwnInventory.TryPutItem(target, owner) end

    if CLIENT and Game.IsMultiplayer then
        return
    end

end)


Hook.Add("mtLinker.onUse", "mtLinker.mtLinker", function(statusEffect, delta, item)
    
    --local target = findtarget.findtarget(item)
    local target = findtarget.findtarget(item)

    if CLIENT and Game.IsMultiplayer then
        return
    end
    local owner = findtarget.FindClientCharacter(item.ParentInventory.Owner)

    if target == nil then
        AddMessage("No item found", owner)
        return
    end
 
    if links[item] == nil then
        links[item] = target
        AddMessage(string.format("Link Start: \"%s\"", target.Name), owner)
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
end)


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
    
    