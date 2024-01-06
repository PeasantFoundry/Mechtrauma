MT.CLI = {}

-- move to program
function MT.CLI.cleanShip(item, terminal, message, command, argument)
    -- call the clean function
    MT.HF.MechtraumaClean()
  end

function MT.CLI.diagnostics(item, terminal, message, command, argument)
    -- convert the argument to a boolean
    if argument == "on" or argument == "true" then argument = true
    elseif argument == "off" or argument == "false" then argument = false end

    -- need to account for other items besides simplegenerators having diagnostic mode 
    MTUtils.GetComponentByName(item, "Mechtrauma.SimpleGenerator").DiagnosticMode = argument
    MT.Net.SendEvent(item)
  
    if MTUtils.GetComponentByName(item, "Mechtrauma.SimpleGenerator").DiagnosticMode == argument then
      if argument then terminal.SendMessage("Diagnostics enabled.") end
      if not argument then terminal.SendMessage("Diagnostics disabled.") end
    end
    
      --MT.HF.SyncToClient("DiagnosticMode", item)
    -- OLD? set the result for the item in the item cache
    --MT.itemCache[item].diagnostics = argument
  end

  function MT.CLI.help(item, terminal, message, command, argument)
    -- loop through the commands and display the help text
    for terminalCommand, v in pairs(MT.CLI.commands) do
      -- only include commands with help text
      if v.help then terminal.SendMessage(terminalCommand .. "-----" .. v.help, Color(250,100,60,255)) end
    end
  end

-- -------------------------------------------------------------------------- --
--                               SHELL COMMANDS                               --
-- -------------------------------------------------------------------------- --

-- This is where the magic happens
function MT.CLI.ls(item, terminal, message, command, argument)
    -- make sure this device has a storage cache
    if MT.itemCache[item] and MT.itemCache[item].MTC and MT.itemCache[item].MTC.root then
      
      -- if there is no current directory, boot to root
      if not MT.itemCache[item].MTC.cd then
        MT.itemCache[item].MTC.cd = MT.itemCache[item].MTC.root -- 
        MT.itemCache[item].MTC.cdp = "/MTC/root" -- we segregate the main table location from the directory path so that we can dynamically consruct the table path later
      end
      MT.HF.BlankTerminalLines(terminal, 10)
      terminal.SendMessage("@" .. tostring(item))
      
      -- display contents (if any)
      if next(MT.itemCache[item].MTC.cd) ~= nil then
        local recordCount = 0
        local dir = {}
        local exe = {}
        for record, v in pairs(MT.itemCache[item].MTC.cd) do
            if v.type and v.type == "DIR" then
                recordCount = recordCount + 1
                table.insert(dir, record)
            elseif v.type and v.type == "EXE" then
                recordCount = recordCount + 1
                table.insert(exe, record)
            end
        end
        for record, v in pairs(dir) do 
            terminal.SendMessage("<DIR>...| " .. v ..  "/")
        end        
        for record, v in pairs(exe) do 
            terminal.SendMessage("<EXE>..| " .. v ..  "/")
        end
        -- footer
        terminal.SendMessage(tostring(recordCount) .. " files")
        MT.HF.BlankTerminalLines(terminal, 1)
        terminal.SendMessage("@" .. MT.itemCache[item].MTC.cdp)
    else
        -- empty (no contents)
        terminal.SendMessage("0 records found")
    end
    else
        -- no data cache
        terminal.SendMessage("!ERROR! No harddrive detected.")
    end
  
      --MT.HF.BlankTerminalLines(terminal, 1)
      --terminal.SendMessage("@" .. MT.itemCache[item].MTC.cdp)
      --MT.HF.BlankTerminalLines(terminal, 5)
      --terminal.SendMessage("!ERROR! No harddrive detected.")
end

function MT.CLI.cd(item, terminal, message, command, argument)
    -- check for a storage cache
    if MT.itemCache[item] and MT.itemCache[item].MTC and MT.itemCache[item].MTC.root then
      -- if there is no current directory - boot us to root
      if not MT.itemCache[item].MTC.cd then
        MT.itemCache[item].MTC.cd = MT.itemCache[item].MTC.root -- MT.CLI.getDirectory(MT.itemCache[item], MT.itemCache[item].MTC.cdp)      
        MT.itemCache[item].MTC.cdp = "/MTC/root"
      end
  
      -- go back one directory
      if argument == "-" and MT.itemCache[item].MTC.cdp ~= "/MTC/root" then
        MT.itemCache[item].MTC.cdp = MT.CLI.getParentDirectoryPath(MT.itemCache[item].MTC.cdp)
        MT.itemCache[item].MTC.cd = MT.CLI.getDirectory(MT.itemCache[item], MT.itemCache[item].MTC.cdp)
        
        MT.CLI.ls(item, terminal, "ls", "ls", "")
  
      -- open directory 
      elseif MT.itemCache[item].MTC.cd[argument] ~= nil and MT.itemCache[item].MTC.cd[argument] then -- check if directory exists        
        MT.itemCache[item].MTC.cdp = MT.itemCache[item].MTC.cdp .. "/" .. argument -- extend the current directory path
        MT.itemCache[item].MTC.cd =  MT.itemCache[item].MTC.cd[argument] -- update the current directory
        MT.CLI.ls(item, terminal, "ls", "ls", "")
      else
        terminal.SendMessage("INVALID ARGUMENT: ", argument, Color(250,100,60,255))
      end
    else
      -- no storage cache
      terminal.SendMessage("!ERROR! No harddrive detected.")
    end
end


function MT.CLI.mkdir(item, terminal, message, command, argument)
    -- check for a storage cache
    if MT.itemCache[item] and MT.itemCache[item].MTC and MT.itemCache[item].MTC.root then
        -- if there is no current directory - default to root
        if not MT.itemCache[item].MTC.cd then
        MT.itemCache[item].MTC.cdp = "/MTC/root"
        MT.itemCache[item].MTC.cd = MT.CLI.getDirectory(MT.itemCache[item], MT.itemCache[item].MTC.cdp)
        end

        --local newDirectory = MT.CLI.getDirectory(MT.itemCache[item], argument)
        if MT.itemCache[item].MTC.cd[argument] then
            terminal.SendMessage("!ERROR! FILE ALREADY EXISTS", Color(250,100,60,255))
        else
            MT.itemCache[item].MTC.cd[argument] = {}
            MT.itemCache[item].MTC.cd[argument].type = "DIR"
            MT.CLI.ls(item, terminal, "ls", "ls", "")
        end
    else
        -- no storage cache
        terminal.SendMessage("!ERROR! No harddrive detected.")
    end
end

function MT.CLI.rmdir(item, terminal, message, command, argument)
    if MT.itemCache[item] and MT.itemCache[item].MTC and MT.itemCache[item].MTC.root then
        -- if there there is no current directory then boot to root
        if not MT.itemCache[item].MTC.cd then
            MT.itemCache[item].MTC.cd = MT.itemCache[item].MTC.root -- MT.CLI.getDirectory(MT.itemCache[item], MT.itemCache[item].MTC.cdp)      
            MT.itemCache[item].MTC.cdp = "/MTC/root"
        end
        -- purge records
        if MT.itemCache[item].MTC.cd[argument] then
            MT.itemCache[item].MTC.cd[argument] = nil      
            MT.CLI.ls(item, terminal, "ls", "ls", "")
            terminal.SendMessage("*PURGE SUCCESFUL*")
        else
            MT.CLI.ls(item, terminal, "ls", "ls", "")
            terminal.SendMessage("*no such directory*")
        end
    else
        MT.HF.BlankTerminalLines(terminal, 5)
        terminal.SendMessage("!ERROR! NO DRIVE FOUND")
    end
end

--mv textcolor.exe /MTC/root 
-- command source destination
function MT.CLI.mv(item, terminal, message, command, argument)    
    if MT.itemCache[item] and MT.itemCache[item].MTC and MT.itemCache[item].MTC.root then
        -- check for current directory
        MT.CLI.BTR(item)

        local source
        local destinationPartialPath
        -- reparse the original message to get the secondary argument
        if message ~= nil then
            local messageTable = MT.HF.Split(message," ")
            source = messageTable[2]
            destinationPartialPath = messageTable[3]
        end
        
        if command == nil or source == nil or destinationPartialPath == nil then terminal.SendMessage("MISSING ARGUMENT(S)", Color(250,100,60,255)) return end
        
        
        -- VALIDATION: make it so the user dosen't have to include /MTC or /root
        local rootPos = destinationPartialPath:find("root")
        if rootPos then
            destinationPartialPath = destinationPartialPath:sub(rootPos + 5)  -- Adding 5 to skip 'root'
            print(destinationPartialPath)
        end
        -- VALIDATION: check if we've created a valid path
        if MT.CLI.getDirectory(MT.itemCache[item].MTC.root, destinationPartialPath) then
            -- create the table path as a function variable
            
            local destinationPath = MT.CLI.getDirectory(MT.itemCache[item].MTC.root, destinationPartialPath)
            -- close the source to the destination
            destinationPath[source] = MT.itemCache[item].MTC.cd[source]
            -- purge records
            if MT.itemCache[item].MTC.cd[argument] then
                    MT.itemCache[item].MTC.cd[argument] = nil
                    MT.CLI.ls(item, terminal, "ls", "ls", "")
                    terminal.SendMessage("*MOVE SUCCESFUL*")
            else
                    MT.CLI.ls(item, terminal, "ls", "ls", "")
                    terminal.SendMessage("*no such directory*")
            end
        else
            print(destinationPartialPath)
            terminal.SendMessage("INVALID PATH", Color(250,100,60,255))
        end
    else
        MT.HF.BlankTerminalLines(terminal, 5)
        terminal.SendMessage("!ERROR! NO DRIVE FOUND")
    end
end

  function MT.CLI.report(item, terminal, message, command, argument)
    local reportInstalled
    
    -- check if this is a valid report
    if MT.CLI.commands.report.reportTypes[argument] then
      -- check if this report is allowed on this item   
      for k, v in pairs(MT.CLI.commands.report.reportTypes[argument].allowedItems) do
        if item.Prefab.Identifier.Value == v or item.HasTag(v) then
          reportInstalled = true
          break
        else
          reportInstalled = false
        end
      end
      -- prevent "INVALID REPORT TYPE" from printing for every item identifier
      if reportInstalled then
        MT.CLI.commands.report.reportTypes[argument].functionToCall(item, terminal, message, command, argument)
      else
        terminal.SendMessage("***** REPORT NOT INSTALLED *****", Color(250,100,60,255))
      end
    -- invalid report type  
    else
      MT.CLI.error("invalidReport", terminal, argument, Color(250,100,60,255))
    end
  end
-- CLI executables
function MT.CLI.run(item, terminal, message, command, argument)    
    local formattedArgument = argument:match("([^%.]*)%.?.*$")

    if formattedArgument == "" then
        formattedArgument = argument
    end
                   
    -- if there is no current directory - boot us to root
    if not MT.itemCache[item].MTC.cd then
        MT.itemCache[item].MTC.cd = MT.itemCache[item].MTC.root -- MT.CLI.getDirectory(MT.itemCache[item], MT.itemCache[item].MTC.cdp)      
        MT.itemCache[item].MTC.cdp = "/MTC/root"
    end
    terminal.SendMessage("finding file...", Color.Gray)
    if not MT.itemCache[item].MTC.cd[formattedArgument] then
        terminal.SendMessage("file not found: " .. MT.itemCache[item].MTC.cdp .. "." .. formattedArgument .. ".EXE", Color(250,100,60,255))
    else
        terminal.SendMessage("attempting execution...")
        MT.itemCache[item].MTC.cd[formattedArgument].functionToCall(item, terminal)
    end
    
    --MT.itemCache[item].MTC.cdp = "/MTC/root" 
    --MT.CLI.EXE[argument].functionToCall(item, terminal)
end

-- little program to change color of terminal
function MT.CLI.textcolor(item, terminal, response) -- all argument portions of run functions have to be lower case because the terminal does not respect it.
    if response == nil then
        terminal.SendMessage("What color would you like? Green or Red")
        MT.itemCache[item].MTC.isWaiting = true
        MT.itemCache[item].MTC.waitingFunction = MT.CLI.textcolor
    else
        if response == "red" then 
            terminal.TextColor = Color(255,100,50,255)
            terminal.SendMessage("Success! exiting program.")
            MT.itemCache[item].MTC.isWaiting = false
            return
            elseif response == "green" then 
                terminal.TextColor = Color.Lime
                terminal.SendMessage("Success! exiting program.")
                MT.itemCache[item].MTC.isWaiting = false
                return

                elseif response == "exit" then 
                    MT.itemCache[item].MTC.isWaiting = false
                    terminal.SendMessage("-Terminating Program-")
                    return
        else
            terminal.SendMessage("Invalid Color: " .. response .. " . To cancel, type exit.", Color(250,100,60,255))
        end
    end
end

function MT.CLI.lockScreen(item, terminal, response) 
    if response == nil then
        
        terminal.SendMessage("*****PRESS ANY KEY*****")
    end
end

  
  function MT.CLI.setPower(item, terminal, message, command, argument)
    local simpleGenerator = MTUtils.GetComponentByName(item, "Mechtrauma.SimpleGenerator")
    simpleGenerator.PowerToGenerate = MT.HF.Clamp(tonumber(argument), 0, simpleGenerator.MaxPowerOut)
    terminal.SendMessage("Power target set to: " .. MT.HF.Clamp(tonumber(argument), 0, simpleGenerator.MaxPowerOut), Color.Lime)
  end
  
  function MT.CLI.error(error,terminal,argument)
    if error == nil then terminal.SendMessage("*****UNKNOWN ERROR******", Color(250,100,60,255)) return end
    if MT.CLI.errors[error] ~= nil then
      if argument ~= nil then
        terminal.SendMessage("*****" .. MT.CLI.errors[error].message .. argument .. "*****", MT.CLI.errors[error].color)
      else
        terminal.SendMessage("*****" .. MT.CLI.errors[error].message .. "*****", MT.CLI.errors[error].color)
      end
    end
  end

  -- -------------------------------------------------------------------------- --
  --                            MTC EXECUTABLES TABLE                           --
  -- -------------------------------------------------------------------------- --
  -- exactubles need to be stores in this table to enable the dynamically constructing function calls
  -- shouldn't this be in the directory structure after type?!

MT.CLI.EXE = {
    textcolor={
        functionToCall = MT.CLI.textcolor
    }
}


-- -------------------------------------------------------------------------- --
--                             MTC ERROR MESSAGES                             --
-- -------------------------------------------------------------------------- --
-- an attempt at standardizing validation

MT.CLI.errors = {
    noRoot={
        code = 0101,
        message = "ROOT MISSING OR CORRUPTED",
        color = Color(250,100,60,255)
    },
    invalidReport={
        code = 0101,
        message = "INVALID REPORT TYPE: ",
        color = Color(250,100,60,255)
    }
  }

  -- -------------------------------------------------------------------------- --
  --                            MTC COMMAND FUNCTIONS                           --
  -- -------------------------------------------------------------------------- --
  -- table of terminal commands functions - permissioned by item/tag (currently)
  MT.CLI.commands = {
    diagnostics={
      help="Enable/Disable diagnostics - Ex: diagnostics > on",
      commands={"diag"},
      requireCCN=false,
      functionToCall=MT.CLI.diagnostics,
    },
    cleanship={
      commands={"cleanship", "clean ship"},
      requireCCN=false,
      functionToCall=MT.CLI.cleanShip,
      allowedItems={"mt_maintenance_tablet"},
    },
    setpower={
      help="Power to be generated. Ex: setpower > 1000",
      commands={"report"},
      allowedItems={"mt_reactor_pf5000"},
      requiredComponent="simpleGenerator",
      requireCCN=false,
      functionToCall=MT.CLI.setPower,
    },
    report={
      help="runs a report. Example: report > pump",
      commands={"report"},
      allowedItems={"mtc"},
      requireCCN=true,
      functionToCall=MT.CLI.report,
      reportTypes={
        parts={
          functionToCall=MT.F.reportTypes.parts,
          allowedItems={"mtc","terminal"},
        },
        c02={
          functionToCall=MT.F.reportTypes.c02,
          allowedItems={"mtc","terminal"},
        },
        pump={
          allowedItems={"mtc","terminal"},
          functionToCall=MT.F.reportTypes.pump
        },
        power={
          allowedItems={"mtc","terminal"},
          functionToCall=MT.F.reportTypes.power
        },
        fuse={
          allowedItems={"mtc","terminal"},
          functionToCall=MT.F.reportTypes.fuse
        },
        pharmacy={
          functionToCall=MT.F.reportTypes.pharmacy,
          allowedItems={"mtc","terminal"},
        },
        blood={
          functionToCall=MT.F.reportTypes.blood,
          allowedItems={"mtc","terminal"},
        },
      },
    },
    ls={
      help="list directories",
      requireCCN=false,
      functionToCall=MT.CLI.ls,
      allowedItems={"mtc"}
    },
    cd={
      help="open directory",
      requireCCN=false,
      functionToCall=MT.CLI.cd,
      allowedItems={"mtc"}
    },
    mkdir={
      help="make directory",
      requireCCN=false,
      functionToCall=MT.CLI.mkdir,
      allowedItems={"mtc"}
    },
    mv={
    help="make directory",
    requireCCN=false,
    functionToCall=MT.CLI.mv,
    allowedItems={"mtc"}
  },
    rmdir={
      help="remove directory",
      requireCCN=false,
      functionToCall=MT.CLI.rmdir,
      allowedItems={"mtc"}
    },
    run={
        help="run executable",
        requireCCN=false,
        functionToCall=MT.CLI.run,
        allowedItems={"mtc"}
      },
    help={
      help="YOU ARE HERE.",
      commands={"help"},
      requireCCN=false,
      functionToCall=MT.CLI.help,
      allowedItems={"mtc,terminal,any"}
    }
  }

  --[[
  MT.CLI.responseCommands = {
    terminalColor={
      --help="Enable/Disable diagnostics - Ex: diagnostics > on",
      --commands={"diag"},
      requireCCN=false,
      --functionToCall=MT.CLI.responses
    },
}]]


-- -------------------------------------------------------------------------- --
--                                MTC TERMINAL                                --
-- -------------------------------------------------------------------------- --
-- case agnostic CLI
-- supports waiting programs


-- -------------------------------------------------------------------------- --
--                        MTC COMMAND LINE INTERPRETOR                        --
-- -------------------------------------------------------------------------- --

--called once for each terminal message sent by a player (unless terminal is waiting)
function MT.CLI.terminalCommand(item, terminal, message)
    if message ~= nil then
        local messageTable = MT.HF.Split(message," ")
        local command = messageTable[1]
        local argument = messageTable[2]
        MT.HF.BlankTerminalLines(terminal, 1) -- create some space
        terminal.SendMessage("PROCESSING REQUEST...", Color.Gray)
        -- check too see if the terminal message includes a valid command
        if MT.CLI.commands[command] then
        -- check to see if this command is allowed
        if MT.CLI.commandAllowed(item, terminal, command) then
            -- check if the command requires the central computer to be online
            if MT.CLI.commands[command].requireCCN == false then
            -- CCN is not required 
            MT.CLI.commands[command].functionToCall(item, terminal, message, command, argument)
            elseif MT.CLI.commands[command].requireCCN == true and CentralComputer.online == true then
            -- CCN is required and online
            MT.CLI.commands[command].functionToCall(item, terminal, message, command, argument)
            else
            -- the central computer is required and offline
            terminal.SendMessage("**************NO CONNECTION**************", Color(250,100,60,255))
            end
        else
            -- command is valid but not allowed on your device
            terminal.SendMessage("THE COMMAND -" .. string.upper(command) .. "- IS NOT ALLOWED. PLEASE CONTACT YOUR SYSTEM ADMINISTRATOR.", Color(250,100,60,255))
        end
        else
        -- command is not valid
        terminal.SendMessage("INVALID COMMAND: " .. command, Color(250,100,60,255))
        end
    end
end

function MT.CLI.commandAllowed(item, terminal, command)
    -- check if this report command is allowed on this item   
    for k, v in pairs(MT.CLI.commands[command].allowedItems) do
      if item.Prefab.Identifier.Value == v or item.HasTag(v) then
        return true
        else MT.CLI.error("commandRestricted",terminal,command) end
        return
    end
  end

-- Create a function that returns the table based on the string location
function MT.CLI.getDirectory(targetTable, partialLocation)
    local keys = {}

    for key in partialLocation:gmatch("[^./]+") do
      table.insert(keys, key)
    end

    local currentTable = targetTable
    for _, key in ipairs(keys) do
        currentTable = currentTable[key]
        if type(currentTable) ~= "table" then
            return nil  -- Key does not lead to a table
        end
    end
    return currentTable
  end

  -- using
  function MT.CLI.getParentDirectoryTable(rootDirectory, path)
    local lastSlashIndex = path:find("[^/]+/$") -- Find the index of the last key and slash combination
    if lastSlashIndex then
      return MT.CLI.getDirectory(rootDirectory, path:sub(1, lastSlashIndex - 1)) -- Remove everything after the last key and slash
    else
        return path -- Return the path as is if no keys or slashes found
    end
  end
  
  function MT.CLI.getParentDirectoryPath(path)
    local keys = {}
    for key in path:gmatch("[^/]+") do
        table.insert(keys, key)
    end
  
    if #keys > 1 then
        table.remove(keys, #keys)
    end
  
    return "/" .. table.concat(keys, "/")
  end
  
  
  function MT.CLI.getDirectoryPath(tableLocation)
    local path = ""
    local currentItem = tableLocation
    local itemCache = MT.itemCache
  
    -- Reverse search the table hierarchy to construct the path
    local keys = {}
    for key, value in pairs(itemCache) do
        if value == currentItem then
            table.insert(keys, key)
            currentItem = key
            break
        end
    end
  
    while currentItem ~= nil do
        local parentFound = false
        for key, value in pairs(itemCache) do
            if value[currentItem] ~= nil then
                table.insert(keys, currentItem)
                currentItem = value[currentItem]
                parentFound = true
                break
            end
        end
        if not parentFound then
            currentItem = nil
        end
    end
  
    if #keys > 0 then
        path = "/" .. table.concat(keys, "/")
    end
  
    return path
  end
  
  
  -- ---------------------------------- path ---------------------------------- --
  --[[
  function MT.CLI.getDirectory(tbl, partialLocation)
    local keys = {}
  
    -- Split the partial location string into keys
    for key in partialLocation:gmatch("[^./]+") do
        table.insert(keys, key)
    end
  
    local currentTable = tbl
    for _, key in ipairs(keys) do
        currentTable = currentTable[key]
        if type(currentTable) ~= "table" then
            return nil  -- Key does not lead to a table
        end
    end
  
    local mtcIndex = partialLocation:find("MTC") -- Find the index where "MTC" ends
    if mtcIndex then
        local keysAfterMTC = partialLocation:sub(mtcIndex + 4) -- Extract keys after "MTC" (skip 4 characters)
        local formattedKeys = keysAfterMTC:gsub("[^.]+", "/%0") -- Prepend "/" before each key
        return formattedKeys
    else
        return "" -- Return an empty string if "MTC" is not found
    end
  end]]

-- -------------------------------------------------------------------------- --
--                              HELPER FUNCTIONS                              --
-- -------------------------------------------------------------------------- --

-- boot to root 
function MT.CLI.BTR(item)
    -- we *should* keeping track of the current directory and storing it in the MT item cache
    -- but if that fails for any reason.... WE BOOT TO ROOT!
    if not MT.itemCache[item].MTC.cd then
        MT.itemCache[item].MTC.cd = MT.itemCache[item].MTC.root -- MT.CLI.getDirectory(MT.itemCache[item], MT.itemCache[item].MTC.cdp)      
        MT.itemCache[item].MTC.cdp = "/MTC/root"
    end
end

 -- -------------------------------------------------------------------------- --
 --                          MTC terminal command hook                         --
 -- -------------------------------------------------------------------------- --

  Hook.Add("Mechtrauma.AdvancedTerminal::NewPlayerMessage", "terminalCommand", function(terminal, message, color)
    -- for ease of use, all MTC CLI messages are converted to lower case before parsing out the command and argument 
    local formattedMessage = string.lower(message)
    -- am I waiting for a response?
    if MT.itemCache[terminal.item].MTC.isWaiting == true then 
        MT.itemCache[terminal.item].MTC.waitingFunction(terminal.item, terminal, formattedMessage)
    else
        -- process regular command 
        MT.CLI.terminalCommand(terminal.item, terminal, formattedMessage)
    end
  end)
