MT.CLI = {}

-- move to program and... probably just delete, its slowwww
function MT.CLI.cleanShip(item, terminal, mtc, message, command, argument)
    -- call the clean function
    MT.HF.MechtraumaClean()
end

function MT.CLI.claim(item, terminal, mtc, message, command, argument)
  print("claim this biatcho!")
  -- assign device ownership
  -- add profile.txt
  if MT.C.HD[item].MTC.root then print("I AM THEREFOR I AM!") end
  MT.C.HD[item].MTC.root.profile = {type="TXT", name="profile"}

end

function MT.CLI.exit(item, terminal, mtc, message, command, argument)
  -- generic function for disabling automatic readouts to stop the terminal from being clogged

  if item.HasTag("DieselEngine") then
    local DieselEngine = MTUtils.GetComponentByName(item, "Mechtrauma.DieselEngine")
    -- disable the diesel readouts
    DieselEngine.DiagnosticMode = false
    DieselEngine.ShowStatus = false
    DieselEngine.ShowLevels = false
    DieselEngine.ShowTemps = false
    --MT.Net.SendEvent(item)
    terminal.SendMessage("CLEARING READOUTS")
  end
end

function MT.CLI.diagnostics(item, terminal, mtc, message, command, argument)
  -- if there is no argument

  -- convert the argument to a boolean
  if not argument or argument == "on" or argument == "true" then argument = true
  elseif argument == "off" or argument == "false" then argument = false end

  if argument ~= true and argument ~= false then terminal.SendMessage("INVALID ARGUMENT: " .. argument, Color(250,100,60,255)) return end

  -- need to account for other items besides simplegenerators having diagnostic mode 
  MTUtils.GetComponentByName(item, "Mechtrauma.DieselEngine").DiagnosticMode = argument
  
  print("ARGUMENT: " .. tostring(argument) .. " RESULT = DIAGNOSTIC MODE: " ..  tostring(MTUtils.GetComponentByName(item, "Mechtrauma.DieselEngine").DiagnosticMode))
  if MTUtils.GetComponentByName(item, "Mechtrauma.DieselEngine").DiagnosticMode == argument then
    if argument then terminal.SendMessage("Diagnostics enabled.") end
    if not argument then terminal.SendMessage("Diagnostics disabled.") end
  end
end
-- -------------------------------------------------------------------------- --
--                                MTC CLI HELP                                --
-- -------------------------------------------------------------------------- --
function MT.CLI.help(item, terminal, mtc, message, command, argument)
  -- HELP REQUESTED: SINGLE COMMAND
  if MT.CLI.commands[argument] then
    local command = MT.CLI.commands[argument]
    -- AUTHORIZATION   
    if not MT.CLI.commandAllowed(item, terminal, argument) then
      -- command is valid but not allowed on your device
      terminal.SendMessage("THE COMMAND -" .. string.upper(argument) .. "- IS NOT AVAILABLE. PLEASE CONTACT YOUR SYSTEM ADMINISTRATOR.", Color(250,100,60,255))
      return
    end

    if item.HasTag("narrowDisplay") then
      terminal.SendMessage("——— " .. string.upper(argument) .. " ——— ", Color(250,100,60,255))
      terminal.SendMessage("ARGs: " .. command.help .. "", Color(250,100,60,255))
      terminal.SendMessage("EX: ".. command.helpExample, Color(250,100,60,255))
      terminal.SendMessage("• ".. command.helpDetails, Color(250,100,60,255))
    else
      terminal.SendMessage("—— —— —— —— —— " .. string.upper(argument) .. " —— —— —— —— —— ", Color(250,100,60,255))
      terminal.SendMessage("ARGUMENTS: " .. command.help .. "", Color(250,100,60,255))
      terminal.SendMessage("EXAMPLE: ".. command.helpExample, Color(250,100,60,255))
      terminal.SendMessage("• ".. command.helpDetails, Color(250,100,60,255))
    end
    return
  end
  -- help requested for all allowed commands.
  terminal.SendMessage("COMMAND | ARGUMENTS", Color(250,100,60,255))
  for terminalCommand, v in pairs(MT.CLI.commands) do
    -- only include commands with help text and that are allowed on this item    
    if v.help and MT.CLI.commandAllowed(item, nil, terminalCommand) then
      -- comand/arguments
      -- terminal.SendMessage("•" .. terminalCommand .. ": " .. v.help, Color(250,100,60,255))
      -- include details
      if argument == "details" and v.helpDetails then
        if item.HasTag("narrowDisplay") then
          terminal.SendMessage("——— " .. string.upper(terminalCommand) .. " ——— ", Color(250,100,60,255))
          terminal.SendMessage("ARGs: " .. v.help .. "", Color(250,100,60,255))
          terminal.SendMessage("EX: ".. v.helpExample, Color(250,100,60,255))
          terminal.SendMessage("• ".. v.helpDetails, Color(250,100,60,255))
        else
          terminal.SendMessage("—— —— —— —— —— " .. string.upper(terminalCommand) .. " —— —— —— —— —— ", Color(250,100,60,255))
          terminal.SendMessage("ARGUMENTS: " .. v.help .. "", Color(250,100,60,255))
          terminal.SendMessage("EXAMPLE: ".. v.helpExample, Color(250,100,60,255))
          terminal.SendMessage("• ".. v.helpDetails, Color(250,100,60,255))
        end

      --elseif argument == "examples" and v.helpExample then
        --terminal.SendMessage("•" .. terminalCommand .. ": " .. v.help, Color(250,100,60,255))      
      else
        terminal.SendMessage("•" .. terminalCommand .. ": " .. v.help, Color(250,100,60,255))
      end
    end
  end
end

-- reads record such as SMS or TXT
function MT.CLI.read(item, terminal, mtc, message, command, argument)
local index = argument
-- figure out if were reading an SMS or a TXT record
  local sms
  local txt
-- if there is no current directory - boot us to root
  if not MT.C.HD[item].MTC.cd then
    MT.C.HD[item].MTC.cd = MT.C.HD[item].MTC.root -- MT.CLI.getDirectory(MT.itemCache[item], MT.C.HD[item].MTC.cdp)      
    MT.C.HD[item].MTC.cdp = "/MTC/root"
  end

  if not MT.C.HD[item].MTC.cd[index] or not MT.C.HD[item].MTC.cd[index].type then
    terminal.SendMessage("FILE NOT FOUND: " .. MT.C.HD[item].MTC.cdp .. "." .. argument, Color(250,100,60,255))
  end
  if MT.C.HD[item].MTC.cd[index].type == "SMS" then
    -- attempt to open SMS message
    terminal.ClearHistory()
    terminal.SendMessage("opening message...", Color.Gray)
    if not MT.C.HD[item].MTC.cd[index] then
        terminal.SendMessage("Message not found: " .. MT.C.HD[item].MTC.cdp .. "." .. argument .. ".SMS", Color(250,100,60,255))
    else
      if item.HasTag("narrowDisplay") then
        sms = MT.C.HD[item].MTC.cd[index]
        terminal.SendMessage("[" .. sms.type .. " | ID:" .. argument .. "] - [@:" .. sms.at .. ".T]")
        terminal.SendMessage("[TO: #" .. sms.to .. " | FROM: #" .. sms.from .. "]")
        terminal.SendMessage("••••••••••••••••••••••••••••••••")
        terminal.SendMessage("[MESSAGE]")
        terminal.SendMessage(sms.message)
        terminal.SendMessage("[/MESSAGE]")
        terminal.SendMessage("••••••••••••••••••••••••••••••••")
      else
        sms = MT.C.HD[item].MTC.cd[index]
        terminal.SendMessage("[" .. sms.type .. " | ID:" .. argument .. "] - [@:" .. sms.at .. ".T] " .. " [TO: #" .. sms.to .. " | FROM: #" .. sms.from .. "]")
        terminal.SendMessage("••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••")
        terminal.SendMessage("[MESSAGE]")
        terminal.SendMessage(sms.message)
        terminal.SendMessage("[/MESSAGE]")
        terminal.SendMessage("••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••")
      end
    end
  elseif MT.C.HD[item].MTC.cd[index].type == "TXT" then
    -- TXT reading
    terminal.SendMessage("opening document...", Color.Gray)
  else
    terminal.SendMessage("*UNKNOWN FILE TPYE* ", Color(250,100,60,255))
  end
end

-- send a text message to another device by ID
function MT.CLI.text(item, terminal, mtc, message, command, argument)
  if tonumber(argument) == nil then terminal.SendMessage("INVALID NUMBER: " .. argument) return end
  local targetItem = Entity.FindEntityByID(tonumber(argument))
  local targetTerminal = MTUtils.GetComponentByName(targetItem, "Mechtrauma.AdvancedTerminal")
  local textMessage
  local textMessageTime = MT.HF.Round(Game.GameScreen.GameTime, 0)
  local _, textMessageStart = string.find(message, argument) -- Find the position where the number argument starts in the string
  local textmessageTable

  if not targetItem or not MT.C.HD[targetItem] then terminal.SendMessage("INVALID NUMBER: " .. argument) return end
  -- Check if the argument was found
  if textMessageStart then
      -- Extract everything after argument
      textMessage = string.sub(message, textMessageStart + 2)  -- Adjust the index to skip "126"        
  else
    textMessage = "UNKNOWN MESSAGE"
  end
  -- -------------------------------------------------------------------------- --
  --                         CHECK FOR REQUIRED FOLDERS                         --
  -- -------------------------------------------------------------------------- --

   -- check for local messages/sent folder - create if missing
   if not MT.C.HD[item].MTC.root.messages then MT.C.HD[item].MTC.root.messages = MT.C.Sample.messages end
   if MT.C.HD[item].MTC.root.messages.sent == nil then print("sent was nil, readding") MT.C.HD[item].MTC.root.messages.sent = MT.C.Sample.messages.sent end

  -- check for target messages/received folder - create if missing
  if not MT.C.HD[targetItem].MTC.root.messages then MT.C.HD[targetItem].MTC.root.messages = MT.C.Sample.messages end
  if MT.C.HD[targetItem].MTC.root.messages.received == nil then MT.C.HD[targetItem].MTC.root.messages.received = MT.C.Sample.messages.received end

  -- -------------------------------------------------------------------------- --
  --                          ADD OUTGOING SMS MESSAGE                          --
  -- -------------------------------------------------------------------------- --
  MT.C.HD[item].MTC.counters.smsOUT = MT.C.HD[item].MTC.counters.smsOUT + 1
  MT.C.HD[item].MTC.root.messages.sent[tostring(MT.C.HD[item].MTC.counters.smsOUT)] = {type="SMS", to=tostring(targetItem.ID), from=tostring(item.ID), message=textMessage, at=tostring(textMessageTime)}

  -- -------------------------------------------------------------------------- --
  --                          ADD INCOMING SMS MESSAGE                          --
  -- -------------------------------------------------------------------------- --
  MT.C.HD[targetItem].MTC.counters.smsIN = MT.C.HD[targetItem].MTC.counters.smsIN + 1
  MT.C.HD[targetItem].MTC.root.messages.received[tostring(MT.C.HD[targetItem].MTC.counters.smsIN)] = {type="SMS", to=tostring(targetItem.ID), from=tostring(item.ID), message=textMessage, at=tostring(textMessageTime)}

  -- -------------------------------------------------------------------------- --
  --                             DISPLAY SMS MESSAGE                            --
  -- -------------------------------------------------------------------------- --

  if targetTerminal then
    if item.HasTag("narrowDisplay") then
      -- narrowDisplay
      targetTerminal.SendMessage("- MESSAGE RECEIVED -")
      targetTerminal.SendMessage("[@" .. textMessageTime .. ".T | FROM: (" .. item.ID .. ")]")
      targetTerminal.SendMessage(textMessage)
      targetTerminal.SendMessage("-- END OF MESSAGE --")
    else
      -- standardDisplay
      targetTerminal.SendMessage("- MESSAGE RECEIVED -")
      targetTerminal.SendMessage("@" .. textMessageTime .. ".T - FROM: (" .. item.ID .. ")")
      targetTerminal.SendMessage(textMessage)
      targetTerminal.SendMessage("-- END OF MESSAGE --")

    end

  end

end

-- -------------------------------------------------------------------------- --
--                   TABLE PERSISTENCE VIA JSON SERIALIZTION                  --
-- -------------------------------------------------------------------------- --

-- partial utility function for testing JSON serializer and saving to file
function MT.CLI.save(item, terminal, mtc, message, command, argument)
  terminal.SendMessage("*SAVING TO DISK*")
  MT.C.HD[item].MTC.cdp = nil
  MT.C.HD[item].MTC.cd = nil
  File.Write(MT.Path .. "/MTCHD/MTCHD-" .. tostring(item.ID) .. ".json", json.serialize(MT.C.HD[item]))
end

-- partial utility function for testing JSON serializer and loading from file
function MT.CLI.load(item, terminal, mtc, message, command, argument)
  terminal.SendMessage("*LOADING FROM DISK*")
  MT.C.HD[item] = json.parse(File.Read(MT.Path .. "/MTCHD/MTCHD-" .. tostring(item.ID) .. ".json"))
  MT.CLI.BTR(item, true)
end

-- command to enable automatic readouts
function MT.CLI.show(item, terminal, mtc, message, command, argument)
  -- currently, only diesel has diagnostic mode
  if item.HasTag("DieselEngine") then
    local DieselEngine = MTUtils.GetComponentByName(item, "Mechtrauma.DieselEngine")
    
    if argument == "nothing" or argument == nil then
      -- disable current automatic readout
      MT.CLI.exit(item, terminal)

    elseif argument == "diagnostics" or argument == "diagnostic" or argument == "diag" then
      MT.CLI.exit(item, terminal) -- disable current automatic readout
      DieselEngine.DiagnosticMode = true
      --MT.Net.SendEvent(item)
      terminal.SendMessage("DIAGNOSTIC MODE ENABLED")

    elseif argument == "status" then
      MT.CLI.exit(item, terminal) -- disable current automatic readout
      DieselEngine.ShowStatus = true
      --MT.Net.SendEvent(item)
      terminal.SendMessage("STATUS DISPLAY ENABLED")

    elseif argument == "levels" or argument == "level" then
      MT.CLI.exit(item, terminal) -- disable current automatic readout
      DieselEngine.ShowLevels = true
      --MT.Net.SendEvent(item)
      terminal.SendMessage("STATUS DISPLAY ENABLED")

    elseif argument == "temps" or argument == "temp" then
      MT.CLI.exit(item, terminal) -- disable current automatic readout
      DieselEngine.ShowTemps = true
      --MT.Net.SendEvent(item)
      terminal.SendMessage("TEMPERATURE DISPLAY ENABLED")

    else
      terminal.SendMessage("INVALID READOUT: ", argument, Color(250,100,60,255))
    end
  end
end

-- -------------------------------------------------------------------------- --
--                               SHELL COMMANDS                               --
-- -------------------------------------------------------------------------- --

-- This is where the magic happens
function MT.CLI.ls(item, terminal, mtc, message, command, argument)
    -- make sure this device has a storage cache    
    if MT.C.HD[item] and MT.C.HD[item].MTC and MT.C.HD[item].MTC.root then
      
      -- if there is no current directory, boot to root
      MT.CLI.BTR(item)
      terminal.ClearHistory()
      terminal.SendMessage("@" .. tostring(item))
      
      -- display contents (if any)
      if next(MT.C.HD[item].MTC.cd) ~= nil then
        local recordCount = 0
        local dir = {}
        local exe = {}
        local sms = {}
        local sys = {}
        local txt = {}
        for record, v in pairs(MT.C.HD[item].MTC.cd) do
          print(record, v)
            if v.type and v.type == "DIR" then
                recordCount = recordCount + 1
                table.insert(dir, v)
            elseif v.type and v.type == "EXE" then
                recordCount = recordCount + 1
                table.insert(exe, v)
            elseif v.type and v.type == "SMS" then
              recordCount = recordCount + 1
              table.insert(sms, v)
            elseif v.type and v.type == "SYS" then
              recordCount = recordCount + 1
              table.insert(sys, v)
            elseif v.type and v.type == "TXT" then
              recordCount = recordCount + 1
              table.insert(txt, v)
            end
        end
        for record, v in pairs(dir) do
            terminal.SendMessage("<DIR>...| " .. v.name ..  "/")
        end
        for record, v in pairs(exe) do
            terminal.SendMessage("<EXE>..| " .. v.name .. "/")
        end
        for id, sms in pairs(sms) do
          print(id,sms)
          if item.hasTag("narrowDisplay") then -- narrow terminal 
            -- terminal.SendMessage("<SMS>..| " .. record .. " | " .. string.sub(v.message, 1, 10) .. "...")
            terminal.SendMessage("<SMS>..| " .. id .. " | T:".. sms.to .. " | F:".. sms.from .. " | L:" .. string.len(sms.message))
          else
            terminal.SendMessage("<SMS>..| " .. id .. " | TO: ".. sms.to .. " | FROM:" .. sms.from .. " | " ..  string.sub(sms.message, 1, 30) .. "...")
          end
        end
        for record, v in pairs(sys) do
          terminal.SendMessage("<SYS>...| " .. v.name ..  "/")
        end
        for record, v in pairs(txt) do
          terminal.SendMessage("<TXT>..| " .. v.name )
        end
        -- footer
        terminal.SendMessage(tostring(recordCount) .. " files")
        MT.HF.BlankTerminalLines(terminal, 1)
        terminal.SendMessage("@" .. MT.C.HD[item].MTC.cdp)
      else
          -- empty (no contents)
          terminal.SendMessage("0 records found")
      end
    else
        -- no data cache
        terminal.SendMessage("!ERROR! No harddrive detected.")
    end
  
      --MT.HF.BlankTerminalLines(terminal, 1)
      --terminal.SendMessage("@" .. MT.C.HD[item].MTC.cdp)
      --MT.HF.BlankTerminalLines(terminal, 5)
      --terminal.SendMessage("!ERROR! No harddrive detected.")
end

function MT.CLI.cd(item, terminal, mtc, message, command, argument)
  -- check for a storage cache
  if MT.itemCache[item] and MT.C.HD[item].MTC and MT.C.HD[item].MTC.root then
    -- if there is no current directory - boot us to root
    MT.CLI.BTR(item)
    
    -- <- go back one directory
    if argument == "-" or argument == ".." or message == "cd.." and MT.C.HD[item].MTC.cdp ~= "/MTC/root" then
      MT.C.HD[item].MTC.cdp = MT.CLI.getParentDirectoryPath(MT.C.HD[item].MTC.cdp) -- update current path to parent path
      MT.C.HD[item].MTC.cd = MT.CLI.getDirectory(MT.C.HD[item].MTC.root, MT.C.HD[item].MTC.cdp) -- update current table reference to partent table reference
      MT.CLI.ls(item, terminal, "ls", "ls", "")

    -- <-- go to root directory
    elseif argument == "/" or message == "cd\\" then
      MT.CLI.BTR(item, true) -- force boot to root
      MT.CLI.ls(item, terminal)

    -- open directory ->
    elseif MT.C.HD[item].MTC.cd[argument] ~= nil and MT.C.HD[item].MTC.cd[argument].type == "DIR" then -- check if directory exists        
      MT.C.HD[item].MTC.cdp = MT.C.HD[item].MTC.cdp .. "/" .. argument -- extend the current directory path
      MT.C.HD[item].MTC.cd =  MT.C.HD[item].MTC.cd[argument] -- update the current directory      
      MT.CLI.ls(item, terminal, "ls", "ls", "") -- automatically list new directory

    else
      terminal.SendMessage("INVALID DIRECTORY: " .. MT.C.HD[item].MTC.cdp .. "/" .. argument, Color(250,100,60,255))
    end
  else
    -- no storage cache
    terminal.SendMessage("!ERROR! No harddrive detected.")
  end
end

function MT.CLI.mkdir(item, terminal, mtc, message, command, argument)
    -- check for a storage cache
    if MT.itemCache[item] and MT.C.HD[item].MTC and MT.C.HD[item].MTC.root then
        -- if there is no current directory - default to root
       MT.CLI.BTR(item)

      --local newDirectory = MT.CLI.getDirectory(MT.itemCache[item], argument)
      if MT.C.HD[item].MTC.cd[argument] then
        terminal.SendMessage("!ERROR! FILE ALREADY EXISTS", Color(250,100,60,255))
        else
          print("ARGUMENT: " .. argument)
          --table.insert(MT.C.HD[item].MTC.cd, {type="DIR", name=argument})
          MT.C.HD[item].MTC.cd[argument] = {type="DIR", name=argument}
          MT.CLI.ls(item, terminal)
          if MT.C.HD[item].MTC.cd[argument] then print(" MT.C.HD[item].MTC.cd[argument] DOES EXIST WTF") end
        end
    else
        -- no storage cache
        terminal.SendMessage("!ERROR! No harddrive detected.")
    end
end

function MT.CLI.rmdir(item, terminal, mtc, message, command, argument)
    if MT.itemCache[item] and MT.C.HD[item].MTC and MT.C.HD[item].MTC.root then
        -- if there there is no current directory then boot to root
        if not MT.C.HD[item].MTC.cd then
            MT.C.HD[item].MTC.cd = MT.C.HD[item].MTC.root -- MT.CLI.getDirectory(MT.itemCache[item], MT.C.HD[item].MTC.cdp)      
            MT.C.HD[item].MTC.cdp = "/MTC/root"
        end
        -- purge records
        if MT.C.HD[item].MTC.cd[argument] then
            MT.C.HD[item].MTC.cd[argument] = nil      
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
function MT.CLI.mv(item, terminal, mtc, message, command, argument)
    if MT.itemCache[item] and MT.C.HD[item].MTC and MT.C.HD[item].MTC.root then
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

        -- VALIDATION: check if we've created a valid path
        if MT.CLI.getDirectory(MT.C.HD[item].MTC.root, destinationPartialPath) then
            -- create the table path as a function variable
            print("destinationPartialPath == " .. destinationPartialPath)
            local destinationPath = MT.CLI.getDirectory(MT.C.HD[item].MTC.root, destinationPartialPath)
            -- close the source to the destination
            destinationPath[source] = MT.C.HD[item].MTC.cd[source]
            -- purge records
            if MT.C.HD[item].MTC.cd[argument] then
                    MT.C.HD[item].MTC.cd[argument] = nil
                    MT.CLI.ls(item, terminal, "ls", "ls", "")
                    terminal.SendMessage("*MOVE SUCCESFUL*")
            else
                    MT.CLI.ls(item, terminal, "ls", "ls", "")
                    terminal.SendMessage("*no such directory*")
            end
        else
            --print(destinationPartialPath)
            terminal.SendMessage("INVALID PATH", Color(250,100,60,255))
        end
    else
        MT.HF.BlankTerminalLines(terminal, 5)
        terminal.SendMessage("!ERROR! NO DRIVE FOUND")
    end
end

  function MT.CLI.report(item, terminal, mtc, message, command, argument)
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
        MT.CLI.commands.report.reportTypes[argument].functionToCall(item, terminal, mtc, message, command, argument)
      else
        terminal.SendMessage("***** REPORT NOT INSTALLED *****", Color(250,100,60,255))
      end
    -- invalid report type  
    else
      MT.CLI.error("invalidReport", terminal, argument, Color(250,100,60,255))
    end
  end
-- CLI executables
function MT.CLI.run(item, terminal, mtc, message, command, argument)
    local formattedArgument = argument:match("([^%.]*)%.?.*$")

    if formattedArgument == "" then
        formattedArgument = argument
    end
  
    -- if there is no current directory - boot us to root
    if not MT.C.HD[item].MTC.cd then
        MT.C.HD[item].MTC.cd = MT.C.HD[item].MTC.root -- MT.CLI.getDirectory(MT.itemCache[item], MT.C.HD[item].MTC.cdp)      
        MT.C.HD[item].MTC.cdp = "/MTC/root"
    end
    terminal.SendMessage("finding file...", Color.Gray)
    if not MT.C.HD[item].MTC.cd[formattedArgument] then
        terminal.SendMessage("file not found: " .. MT.C.HD[item].MTC.cdp .. "." .. formattedArgument .. ".EXE", Color(250,100,60,255))
    else
        
      local functionToRun = MT.C.HD[item].MTC.cd[formattedArgument].functionToCall

      -- Load the function
      local loadedFunction, errorMessage = load("return " .. functionToRun)

      -- Check if there were any errors during loading
      if not loadedFunction then
          print("Error loading code: " .. errorMessage)
      else
          -- Execute the loaded function
          loadedFunction()(item, terminal, mtc)
          -- 'result' will contain the result of the executed function
      end
    end
    
    --MT.C.HD[item].MTC.cdp = "/MTC/root" 
    --MT.CLI.EXE[argument].functionToCall(item, terminal)
end

-- little program to change color of terminal
function MT.CLI.textcolor(item, terminal, mtc, response) -- all argument portions of run functions have to be lower case because the terminal does not respect it.  
  print("MT.CLI.textcolor - mtc.IsWaiting: " .. tostring(mtc.IsWaiting))
  mtc.IsWaiting = true
    if response == nil then -- there sh
        terminal.SendMessage("What color would you like? Green or Red")
        mtc.IsWaiting = true
        print("MT.CLI.textcolor - response == nil - mtc.IsWaiting: " .. tostring(mtc.IsWaiting))
        mtc.WaitingFunction = "MT.CLI.textcolor"
    else
        print("RESPONSE WAS NOT NULL!")
        if response == "red" then
            terminal.TextColor = Color(255,100,50,255)
            terminal.SendMessage("Success! exiting program.")
            mtc.IsWaiting = false
            return
            elseif response == "green" then
                terminal.TextColor = Color.Lime
                terminal.SendMessage("Success! exiting program.")
                mtc.IsWaiting = false                
                return

                elseif response == "exit" then
                  mtc.IsWaiting = false
                    terminal.SendMessage("-Terminating Program-")
                    return
        else
            terminal.SendMessage("!INVALID COLOR: " .. response .. " . To cancel, type exit.", Color(250,100,60,255))
        end
    end
end

function MT.CLI.lockScreen(item, terminal, response) 
    if response == nil then
        terminal.SendMessage("*****PRESS ANY KEY*****")
    end
end

  function MT.CLI.setPower(item, terminal, mtc, message, command, argument)
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
    textcolor={ -- changes text color
        functionToCall = MT.CLI.textcolor
    },
    text={-- registers MTC for texting
      functiontocall = MT.CLI.textcolor
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
    cd = {
        help = "[target directory]",
        helpDetails = "Opens a sub-directory of the current directory.",
        helpExample = "cd home",
        altCommands = {"goto","cd..","cd\\"},
        requireCCN = false,
        requireARG = false,
        functionToCall = MT.CLI.cd,
        allowedItems = {"mtc"}
    },
    claim = {
      help = "N/A",
      helpDetails = "Claims an MTC device.",
      helpExample = "claim",
      altCommands = {"clai"},
      requireCCN = false,
      requireARG = false,
      functionToCall = MT.CLI.claim,
      allowedItems = {"mtc"}
  },
    cleanship = {
        commands = {"cleanship", "clean ship"},
        altCommands = {},
        requireCCN = false,
        requireARG = false,
        functionToCall = MT.CLI.cleanShip,
        allowedItems = {""},
    },
    diagnostics = {
        help = "'on,off'",
        helpDetails = "Enables / disables diagnostic mode.",
        helpExample = "'diagnostics on'",
        altCommands = {"diag", "diagnostic"},
        requireCCN = false,
        requireARG = false,
        functionToCall = MT.CLI.diagnostics,
        allowedItems = {"diagnostics", "dieselEngine"}
    },
    exit = {
        help = "N/A",
        helpDetails = "Terminates programs and automatic readouts for this device",
        helpExample = "'exit'",
        altCommands = {"ex", "stop", "cancel"},
        requireCCN = false,
        requireARG = false,
        functionToCall = MT.CLI.exit,
        allowedItems = {"dieselEngine", "diagnostics"}
    },
    help = {
        help = "'details,examples'",
        helpDetails = "Shows possible commands for the current device. Optionally include details and exmaples.",
        helpExample = "help details",
        altCommands = {"help!"},
        requireCCN = false,
        requireARG = false,
        functionToCall = MT.CLI.help,
        allowedItems = {"mtc", "terminal", "dieselEngine"}
    },
    ls = {
        help = "N/A",
        helpDetails = "List records in the current directory.",
        helpExample = "ls",
        altCommands = {"dir", "list"},
        requireCCN = false,
        requireARG = false,
        functionToCall = MT.CLI.ls,
        allowedItems = {"mtc"}
    },
    load = {
        help = "n/a",
        helpDetails = "Loads harddrive data.",
        helpExample = "'load'",
        altCommands = {"ld"},
        requireCCN = false,
        requireARG = false,
        functionToCall = MT.CLI.load,
        allowedItems = {"mtc"}
    },
    mkdir = {
        help = "[new directory name]",
        helpDetails = "Create a new sub-directory in the current directory.",
        helpExample = "mkdir myfolder",
        altCommands = {"makedir"},
        requireCCN = false,
        requireARG = true,
        functionToCall = MT.CLI.mkdir,
        allowedItems = {"mtc"}
    },
    mv = {
        help = "[target record] [destination path]",
        helpDetails = "Moves a record (and all contents) from the current directory to the target directory",
        helpExample = "mv program /home",
        altCommands = {"movedir"},
        requireCCN = false,
        requireARG = true,
        functionToCall = MT.CLI.mv,
        allowedItems = {"mtc"}
    },
    read = {
      help = "[SMS ID],[.TXT filename] ",
      helpDetails = "Read a message or document.",
      helpExample = "'read 6'",
      altCommands = {"red", "rad", "re"},
      requireCCN = false,
      requireARG = true,
      functionToCall = MT.CLI.read,
      allowedItems = {"mtc", "mtmobile"}
  },
    report = {
        help = "[report name]",
        helpDetails = "Run a report on the central computer. A connection to the central computer is required.",
        helpExample = "run pump",
        altCommands = {"r", "rep", "repor"},
        allowedItems = {"mtc"},
        requireCCN = true,
        requireARG = true,
        functionToCall = MT.CLI.report,
        reportTypes = {
            blood = {
                functionToCall = MT.F.reportTypes.blood,
                allowedItems = {"mtc", "terminal"},
            },
            c02 = {
                functionToCall = MT.F.reportTypes.c02,
                allowedItems = {"mtc", "terminal"},
            },
            fuse = {
                allowedItems = {"mtc", "terminal"},
                functionToCall = MT.F.reportTypes.fuse
            },
            parts = {
                functionToCall = MT.F.reportTypes.parts,
                allowedItems = {"mtc", "terminal"},
            },
            pharmacy = {
                functionToCall = MT.F.reportTypes.pharmacy,
                allowedItems = {"mtc", "terminal"},
            },
            power = {
                allowedItems = {"mtc", "terminal"},
                functionToCall = MT.F.reportTypes.power
            },
            pump = {
                allowedItems = {"mtc", "terminal"},
                functionToCall = MT.F.reportTypes.pump
            },
        },
    },
    rmdir = {
        help = "[record name]",
        helpDetails = "Deletes a record (and all contents) from the current directory.",
        helpExample = "rmdir programs",
        altCommands = {"removedir", "delete"},
        requireCCN = false,
        requireARG = true,
        functionToCall = MT.CLI.rmdir,
        allowedItems = {"mtc"}
    },
    run = {
        help = "[executable name]",
        helpDetails = "Runs an executable in the current directory.",
        helpExample = "run textcolor",
        altCommands = {"r", "ru"},
        requireCCN = false,
        requireARG = true,
        functionToCall = MT.CLI.run,
        allowedItems = {"mtc"}
    },
    save = {
        help = "n/a",
        helpDetails = "Saves harddrive data.",
        helpExample = "'save'",
        altCommands = {"sv"},
        requireCCN = false,
        functionToCall = MT.CLI.save,
        allowedItems = {"mtc"}
    },
    setpower = {
        help = "[number]",
        helpDetails = "Sets the target power to be generated by this generator.",
        helpExample = "setpower 1500",
        altCommands = {"sp", "setpwr"},
        requiredComponent = "simpleGenerator",
        requireCCN = false,
        requireARG = true,
        functionToCall = MT.CLI.setPower,
        allowedItems = {"mt_reactor_pf5000"},
    },
    show = {
        help = "'levels,status,temps,diagnostics'",
        helpDetails = "Enable an automatic readout for this device.",
        helpExample = "'show status'",
        altCommands = {"display", "sho", "sh"},
        requireCCN = false,
        requireARG = false,
        functionToCall = MT.CLI.show,
        allowedItems = {"dieselEngine", "diagnostics"}
    },
    text = {
        help = "'number','message'",
        helpDetails = "Send a text message to another device.",
        helpExample = "'text 126 Hello friend!'",
        altCommands = {"txt", "t", "ext"},
        requireCCN = true,
        requireARG = true,
        requireSYS = true,
        functionToCall = MT.CLI.text,
        allowedItems = {"MTC", "terminal"}
    },
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
function MT.CLI.terminalCommand(item, terminal, mtc, message)

  -- add terminal waiting logic here as it is server side  
  if mtc and mtc.IsWaiting == true then
    -- -------------------------------------------------------------------------- --
    --                     MTC CLI: IS WAITING FOR A RESPONSE                     --
    -- -------------------------------------------------------------------------- --
    print("MTC is waiting to call: " .. mtc.WaitingFunction)
    local waitingFunction, errorMessage = load("return " .. mtc.WaitingFunction)

    -- Check if there were any errors during loading
    if not waitingFunction then
        print("Error loading code: " .. errorMessage)
    else
        -- Execute the loaded function
        waitingFunction()(item, terminal, mtc, message)
    end
  else
    -- -------------------------------------------------------------------------- --
    --                  MTC CLI: IS *NOT* WAITING FOR A RESPONSE                  --
    -- -------------------------------------------------------------------------- --
    if message ~= nil and message ~= "" then
      local messageTable = MT.HF.Split(string.lower(message)," ")
      local command = MT.HF.getCommand(item, terminal, messageTable[1])
      local argument = messageTable[2]
        
      --MT.HF.BlankTerminalLines(terminal, 1) -- create some space
      --terminal.SendMessage("PROCESSING REQUEST...", Color.Gray)
      --Timer.Wait(function() terminal.SendMessage("REQUEST PROCESSED...", Color.Gray) end, 1000)

      -- -------------------------------------------------------------------------- --
      --                              VALIDATE COMMAND                              --
      -- -------------------------------------------------------------------------- --

      if not MT.CLI.commands[command] then
        -- invalid command        
        terminal.SendMessage("INVALID COMMAND: " .. command, Color(250,100,60,255))
        return
      elseif MT.CLI.commands[command].requireARG == true and not argument or argument == "" then
        terminal.SendMessage("INVALID ARGUMENT: N/A", Color(250,100,60,255))
        return
      end
      -- -------------------------------------------------------------------------- --
      --                              CHECK PERMISSIONS                             --
      -- -------------------------------------------------------------------------- --
      if not MT.CLI.commandAllowed(item, terminal, command) then
          -- command is valid but not allowed on your device
          terminal.SendMessage("THE COMMAND -" .. string.upper(command) .. "- IS NOT ALLOWED. PLEASE CONTACT YOUR SYSTEM ADMINISTRATOR.", Color(250,100,60,255))
          return
      end
      -- -------------------------------------------------------------------------- --
      --                              CHECK REQUIRMENTS                             --
      -- -------------------------------------------------------------------------- --     

      -- check if the command requires the central computer to be online
      if MT.CLI.commands[command].requireCCN == true and not CentralComputer.online then
        terminal.SendMessage("**************NO CONNECTION**************", Color(250,100,60,255))
        return 
      end
        
      -- -------------------------------------------------------------------------- --
      --                               EXECUTE COMMAND                              --
      -- -------------------------------------------------------------------------- --
      --Timer.Wait(function()  MT.CLI.commands[command].functionToCall(item, terminal, mtc, message, command, argument) end, 1000)
      MT.CLI.commands[command].functionToCall(item, terminal, mtc, message, command, argument)

    else
      -- empty message
      -- MT.HF.BlankTerminalLines(terminal, 1)

      terminal.ClearHistory()
      terminal.SendMessage("@" .. tostring(item))
      MT.HF.BlankTerminalLines(terminal, 5, "")
      terminal.SendMessage("• WELCOME! ‰")

    end
  end
end

-- get a valid command
function MT.HF.getCommand(item, terminal, command)
  if MT.CLI.commands[command] then
    -- VALIDATION SUCCEEDED - that was easy
    return command
  else
    -- since we didn't have an exact match, search all known commands for an alternate command match
    for knownCommand, _ in pairs(MT.CLI.commands) do
      for k, altCommand in pairs(MT.CLI.commands[knownCommand].altCommands) do
        if command == altCommand then
          -- VALIDATION SUCCEEDED 
          command = knownCommand -- update the command to a known command
          return command
        end
      end
    end
  end
  return command
end

-- check if the command is allowed on this device
function MT.CLI.commandAllowed(item, terminal, command)
  -- check if this report command is allowed on this item
  local commandAllowed = false
  for k, v in pairs(MT.CLI.commands[command].allowedItems) do
    if item.Prefab.Identifier.Value == v or item.HasTag(v) then
      commandAllowed = true
      break
    end
  end
  if not commandAllowed and terminal then MT.CLI.error("commandRestricted",terminal,command) end
  return commandAllowed
end


-- function that returns the table based on the string location
function MT.CLI.getDirectory(targetTable, partialPath)
    local keys = {}
    -- if root is included in the partial path, remove it
    local rootPos = partialPath:find("root")
    if rootPos then
      partialPath = partialPath:sub(rootPos + 5)  -- Adding 5 to skip 'root'
        --print(destinationPartialPath)
    end

    for key in partialPath:gmatch("[^./]+") do
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
function MT.CLI.BTR(item, force)
    -- we *should* keeping track of the current directory and storing it in the MT item cache
    -- but if that fails for any reason.... WE BOOT TO ROOT!

    if not MT.C.HD[item].MTC.cd or force then
      MT.C.HD[item].MTC.cd = MT.C.HD[item].MTC.root -- MT.CLI.getDirectory(MT.itemCache[item], MT.C.HD[item].MTC.cdp)      
      MT.C.HD[item].MTC.cdp = "/MTC/root"
    end
end

-- -------------------------------------------------------------------------- --
--                          MTC terminal command hook                         --
-- -------------------------------------------------------------------------- --
-- todo, move this hook from shared to client code
-- this is a client side only hook
-- in multiplayer all terminal commands are synced to server for execution
Hook.Add("Mechtrauma.AdvancedTerminal::NewPlayerMessage", "terminalCommand", function(terminal, message, color)
  -- for ease of use, all MTC CLI messages are converted to lower case before parsing out the command and argument 
  --local formattedMessage = string.lower(message)
  local mtc = MTUtils.GetComponentByName(terminal.item, "Mechtrauma.MTC")  

  if mtc then 
    if Game.IsMultiplayer then
      print("MULTIPLAYER COMMAND!")
      local dispatcher = MTUtils.GetComponentByName(terminal.item, "Mechtrauma.LuaNetEventDispatcher")      
      if dispatcher then
          print("Normal command, send it to the commandcache")
            -- process regular command 
            MT.C.commandCache[terminal.item.ID]=message
            dispatcher.SendEvent()
      else
        print("NO DISPATCHER")
      end
        --MT.C.commandCache[terminal.item.ID]=message
        --dispatcher.SendEvent()
    else
      --singleplayer 
          -- process regular command 
          MT.CLI.terminalCommand(terminal.item, terminal, mtc, message)
    end
  end
end)


