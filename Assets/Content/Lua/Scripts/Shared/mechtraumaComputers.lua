MT.C = {}
-- validates the argument of the report command and runs the requested report (if allowed)
function MT.C.report(item, terminal, message, command, argument)
  local reportInstalled
  
  -- check if this is a valid report
  if MT.terminalCommands.report.reportTypes[argument] then
    -- check if this report is allowd on this item   
    for k, v in pairs(MT.terminalCommands.report.reportTypes[argument].allowedItems) do
      if item.Prefab.Identifier.Value == v then
        reportInstalled = true
        break
      else
        reportInstalled = false
      end
    end
    -- prevent "INVALID REPORT TYPE" from printing for every item identifier
    if reportInstalled then
      MT.terminalCommands.report.reportTypes[argument].functionToCall(item, terminal, message, command, argument)
    else
      terminal.SendMessage("***** REPORT NOT INSTALLED *****", Color.Red)
    end
  -- invalid report type  
  else
    terminal.SendMessage("INVALID REPORT TYPE: " .. argument, Color.Red)
  end
end

function MT.C.help(item, terminal, message, command, argument)
  -- loop through the commands and 
  for terminalCommand, v in pairs(MT.terminalCommands) do
    terminal.SendMessage(terminalCommand .. "-----" .. v.help, Color.Red)
  end
end

--table of terminal commands functions - this is for mapping items to update functions
MT.terminalCommands = {
  sample={
    help="SAMPLE",
    commands={"sample","samp"}, -- idea here is to allow different versions of the command?
    arguments={"test1","test2"},
    identifiers={}, -- idea here is to limit certain commands by item identifier 
    requireCCN=true,
    functionToCall=MT.C.report
  },
  report={
    help="runs a report. Example: report > pump",
    commands={"report"},
    allowedItems={},
    requireCCN=true,
    functionToCall=MT.C.report,
    reportTypes={
      c02={
        functionToCall=MT.F.reportTypes.c02,
        allowedItems={"mt_maintenance_tablet","terminal"},
      },
      pump={
        allowedItems={"mt_maintenance_tablet","terminal"},
        functionToCall=MT.F.reportTypes.pump
      },
      power={
        allowedItems={"mt_maintenance_tablet","terminal"},
        functionToCall=MT.F.reportTypes.power
      },
      fuse={
        allowedItems={"mt_maintenance_tablet","terminal"},
        functionToCall=MT.F.reportTypes.fuse
      },
      pharmacy={
        functionToCall=MT.F.reportTypes.pharmacy,
        allowedItems={"mt_medical_tablet","terminal"},
      },
      blood={
        functionToCall=MT.F.reportTypes.blood,
        allowedItems={"mt_medical_tablet","terminal"},
      },
    },
  },
  help={
    help="YOU ARE HERE.",
    commands={"help"},
    requireCCN=false,
    functionToCall=MT.C.help
}
}

-- split string by delimiter
function string:split( inSplitPattern, outResults )
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end


-- advanced terminal command hook
Hook.Add("Mechtrauma.AdvancedTerminal::NewPlayerMessage", "terminalCommand", function(terminal, message, color)
  local messageTable = message:split(" > ")
  local command = messageTable[1]
  local argument = messageTable[2]
  
  MT.HF.BlankTerminalLines(terminal, 5) -- create some space
  terminal.SendMessage("PROCESSING REQUEST...", Color.Gray)
  -- check too see if the terminal message includes a valid command
  if MT.terminalCommands[command] then
    -- give a little validation 
    -- terminal.SendMessage(command .. " command recognized.", Color.Lime)

    -- check if the command requires the central computer to be online
    if MT.terminalCommands[command].requireCCN then
      -- check if the central computer is online
      if CentralComputer.online then
        -- if the central computer is online, run the command            
        MT.terminalCommands[command].functionToCall(terminal.item, terminal, message, command, argument)
      else
        -- the central computer is offline
        terminal.SendMessage("**************NO CONNECTION**************", Color.Red)
      end
          
    else
      -- the central computer isn't required, run the command
      MT.terminalCommands[command].functionToCall(terminal.item, terminal, message, command, argument)  
    end
      -- the command wasn't valid  
  else
    terminal.SendMessage("INVALID COMMAND: " .. command, Color.Red)
  end
end)


--[[ called once for each terminal message sent by a player
function MT.C.terminalCommand(item, terminal, message, command, argument)
  -- loop through the tag functions to see if we have a matching function for the item tag(s)

  if MT.terminalCommands[command] then
    terminal.SendMessage("This is a good valid command.", Color.Lime)

    print(command)
    print(MT.terminalCommands[command.update])
    
    MT.C.report(item, terminal, message, command, argument)
    
  else
    terminal.SendMessage("-" .. command .. "- is NOT a bad valid command.", Color.Red)
  end


end ]]

