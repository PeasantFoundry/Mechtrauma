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

function MT.C.cleanShip(item, terminal, message, command, argument)
  -- call the clean function
  MT.HF.MechtraumaClean()
end

function MT.C.help(item, terminal, message, command, argument)
  -- loop through the commands and display the help text
  for terminalCommand, v in pairs(MT.terminalCommands) do
    -- only include commands with help text
    if v.help then terminal.SendMessage(terminalCommand .. "-----" .. v.help, Color.Red) end
  end
end

function MT.C.setPower(item, terminal, message, command, argument)
  local simpleGenerator = MTUtils.GetComponentByName(item, "Mechtrauma.SimpleGenerator")
  simpleGenerator.PowerToGenerate = MT.HF.Clamp(tonumber(argument), 0, simpleGenerator.MaxPowerOut)
  terminal.SendMessage("Power target set to: " .. MT.HF.Clamp(tonumber(argument), 0, simpleGenerator.MaxPowerOut), Color.Lime)
end

function MT.C.diagnostics(item, terminal, message, command, argument)
  -- convert the argument to a boolean 
  print(GlobalTest)
  print(item)
  if argument == "on" or argument == "true" then argument = true
  elseif argument == "off" or argument == "false" then argument = false end

  MTUtils.GetComponentByName(item, "Mechtrauma.SimpleGenerator").DiagnosticMode = argument
    --MT.HF.SyncToClient("DiagnosticMode", item)
  -- OLD? set the result for the item in the item cache
  --MT.itemCache[item].diagnostics = argument
  
end
--table of terminal commands functions - this is for mapping items to update functions
MT.terminalCommands = {
  diagnostics={
    help="Enable/Disable diagnostics - Ex: diagnostics > on",
    commands={"report"},
    requireCCN=false,
    functionToCall=MT.C.diagnostics,
  },
  cleanship={
    commands={"cleanship", "clean ship"},
    requireCCN=false,
    functionToCall=MT.C.cleanShip,
    allowedItems={"mt_maintenance_tablet"},
  },
  setpower={
    help="Power to be generated. Ex: setpower > 1000",
    commands={"report"},
    allowedItems={"mt_reactor_pf5000"},
    requiredComponent="simpleGenerator",
    requireCCN=false,
    functionToCall=MT.C.setPower,
  },
  report={
    help="runs a report. Example: report > pump",
    commands={"report"},
    allowedItems={},
    requireCCN=true,
    functionToCall=MT.C.report,  
    reportTypes={
      parts={
        functionToCall=MT.F.reportTypes.parts,
        allowedItems={"mt_maintenance_tablet","terminal"},
      },
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
  MT.C.terminalCommand(terminal.item, terminal, message)
end)


--called once for each terminal message sent by a player
function MT.C.terminalCommand(item, terminal, message)
  -- convert the message to lower case and parse out the command and argument 
  message = string.lower(message)
  local messageTable = message:split(" > ")
  local command = messageTable[1]
  local argument = messageTable[2]

  MT.HF.BlankTerminalLines(terminal, 1) -- create some space
  terminal.SendMessage("PROCESSING REQUEST...", Color.Gray)
  -- check too see if the terminal message includes a valid command
  if MT.terminalCommands[command] then
    -- check if the command requires the central computer to be online
    if MT.terminalCommands[command].requireCCN then
      -- check if the central computer is online
      if CentralComputer.online then
        -- if the central computer is online, run the command            
        MT.terminalCommands[command].functionToCall(item, terminal, message, command, argument)
      else
        -- the central computer is required and is offline
        terminal.SendMessage("**************NO CONNECTION**************", Color.Red)
      end
          
    else
      -- the central computer isn't required, just run the command
      MT.terminalCommands[command].functionToCall(item, terminal, message, command, argument)
    end
      -- the command wasn't valid  
  else
    terminal.SendMessage("INVALID COMMAND: " .. command, Color.Red)
  end

end

-- ----- REPORT PARTS -----
Hook.Add("maintenanceTablet_rparts.OnUse", "MT.partsInventoryReport", function(effect, deltaTime, item, targets, worldPosition, client)
  MT.F.reportTypes.parts(item)
end)


