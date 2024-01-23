
--[[
Hook.Add("item.equip", "MT.advTerminalEquipped", function(item, character)

    local terminal = MTUtils.GetComponentByName(item, "Mechtrauma.AdvancedTerminal")
    if terminal then
        print(terminal.MessageHistoryBox.Rect.X)
        print(terminal.MessageHistoryBox.Rect.y)
        terminal.CGUIX = terminal.MessageHistoryBox.Rect.X -- the magic, the, beauty, the horror
        terminal.CGUIY = terminal.MessageHistoryBox.Rect.y -- height in pixels
        print("hook results: ", terminal.CGUIX)
        print("hook results: ", terminal.CGUIY)
        MT.Net.SendEvent(item)
    end


end)]]

-- -------------------------------------------------------------------------- --
--                          MTC terminal command hook                         --
-- -------------------------------------------------------------------------- --
-- todo, move this hook from shared to client code
-- this is a client side only hook
-- in multiplayer all terminal commands are synced to server for execution
Hook.Add("Mechtrauma.AdvancedTerminal::NewPlayerMessage", "playerTerminalCommand", function(terminal, message, color, width, height)
    -- for ease of use, all MTC CLI messages are converted to lower case before parsing out the command and argument
    --local formattedMessage = string.lower(message)
    local mtc = MTUtils.GetComponentByName(terminal.item, "Mechtrauma.MTC")
    if not mtc then mtc = MTUtils.GetComponentByName(terminal.item.OwnInventory.GetItemAt(0), "Mechtrauma.MTC") end
    --  print(mtc)
    if mtc then
      if Game.IsMultiplayer then
        local dispatcher = MTUtils.GetComponentByName(terminal.item, "Mechtrauma.LuaNetEventDispatcher")
        if dispatcher then
              -- process regular command
              MT.commandCache.message[terminal.item.ID]=message
              MT.commandCache.width[terminal.item.ID]=width
              MT.commandCache.height[terminal.item.ID]=height
              dispatcher.SendEvent()
        end
      else
        -- singleplayer
        -- process regular command
        MT.CLI.terminalCommand(terminal.item, terminal, mtc, message, width, height)
      end
    end
  end)
