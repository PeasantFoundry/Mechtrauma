-- -------------------------------------------------------------------------- --
--                                  MTOS CLI                                  --
-- -------------------------------------------------------------------------- --
-- my beloved Mechtrauma Operating System / Command Line Interface
-- the depth and breadth of this implementation is entierly unecessary
-- I regret nothing - Ahab Hadrada

MT.CLI = {}

-- move to program and... nah probably just delete this, its slowwww
function MT.CLI.cleanShip(item, terminal, mtc, message, command, argument, size)
    -- call the clean function
    MT.HF.MechtraumaClean()
end

-- ------------------------ MTOS GENERIC EXIT COMMAND ----------------------- --
function MT.CLI.exit(item, terminal, mtc, message, command, argument, size)
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
-- ------------------------ MTOS DIAGNOSTICS COMMAND ------------------------ --
-- largely outdated and replaced by the show command
function MT.CLI.diagnostics(item, terminal, mtc, message, command, argument, size)
  -- if there is no argument

  -- convert the argument to a boolean
  if not argument or argument == "on" or argument == "true" then argument = true
  elseif argument == "off" or argument == "false" then argument = false end

  if argument ~= true and argument ~= false then terminal.SendMessage("INVALID ARGUMENT: " .. argument, Color(250,100,60,255)) return end

  -- need to account for other items besides simplegenerators having diagnostic mode
  MTUtils.GetComponentByName(item, "Mechtrauma.DieselEngine").DiagnosticMode = argument
  if MTUtils.GetComponentByName(item, "Mechtrauma.DieselEngine").DiagnosticMode == argument then
    if argument then terminal.SendMessage("Diagnostics enabled.") end
    if not argument then terminal.SendMessage("Diagnostics disabled.") end
  end
end
-- -------------------------------------------------------------------------- --
--                                MTC CLI HELP                                --
-- -------------------------------------------------------------------------- --
function MT.CLI.help(item, terminal, mtc, message, command, argument, size)
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
          --string.format("%-15s", dieselEngine.fuelTime .. "m")
          --[[
          terminal.SendMessage("—— —— —— —— —— " .. string.upper(terminalCommand) .. " —— —— —— —— —— ", Color(250,100,60,255))
          terminal.SendMessage("ARGUMENTS: " .. v.help .. "", Color(250,100,60,255))
          terminal.SendMessage("EXAMPLE: ".. v.helpExample, Color(250,100,60,255))
          terminal.SendMessage("• ".. v.helpDetails, Color(250,100,60,255))
          ]]
          terminal.SendMessage(string.upper(terminalCommand) .. " —— —— —— —— —— ", Color(250,100,60,255))
        end

      --elseif argument == "examples" and v.helpExample then
        --terminal.SendMessage("•" .. terminalCommand .. ": " .. v.help, Color(250,100,60,255))
      else
        terminal.SendMessage("•" .. terminalCommand .. ": " .. v.help, Color(250,100,60,255))
      end
    end
  end
end

-- --------------------------- MTOS READER COMMAND -------------------------- --
-- reads record such as SMS or TXT
function MT.CLI.read(item, terminal, mtc, message, command, argument, size)
  -- -------------------------------------------------------------------------- --
  --                                 VALIDATION                                 --
  -- -------------------------------------------------------------------------- --

  -- validate current directory
  MT.CLI.BTR(item)
  -- validate target file
  if not MT.C.HD[item].MTC.cd[argument] then
    -- index match failed, check for a name match
    local foundNameMatch = false
    for k,v in pairs(MT.C.HD[item].MTC.cd) do
      if v.name and string.lower(v.name) == string.lower(argument) then
        argument = k -- set the argument to the key
        foundNameMatch = true
        break
       end
    end
    if not foundNameMatch then
      terminal.SendMessage("FILE NOT FOUND: " .. MT.C.HD[item].MTC.cdp .. "." .. argument, Color(250,100,60,255))
      return
    end
  end

  -- -------------------------------------------------------------------------- --
  --                          READ DOCUMENT (TXT, ETC)                          --
  -- -------------------------------------------------------------------------- --
  -- probably needs to be broken out into its own module like pBank
  local type = MT.C.HD[item].MTC.cd[argument].type

  --// header
  MT.CLI.header(item, terminal, size.displayWCH)

  -- VALIDATION: file type
  if type == "TXT" or type == "SYS" then
   -- ---------------------------- DISPLAY: DOCUMENT --------------------------- --
   local filePath = MT.C.HD[item].MTC.cdp.."/"..argument.."."..type
   local file = MT.C.HD[item].MTC.cd[argument]

    terminal.SendMessage(MT.CLI.textCenter(filePath,  size.displayWCH, " "))
    if file.registeredName and file.registeredID then
      terminal.SendMessage(MT.CLI.textCenter("[Device Registered to: " .. file.registeredName .. " | ID: " .. file.registeredID .."]",  size.displayWCH, " "))
    end

    for k, v in pairs(MT.C.HD[item].MTC.cd[argument]) do
      if k ~= "type" and k ~= "name" and k ~= "registeredName" and k ~= "registeredID" then -- this is going to get out of hand, quickly.
        terminal.SendMessage(tostring(k) .. ": " .. v)
      end
      --terminal.SendMessage(tostring(k) .. ": " .. v)
    end

  elseif MT.C.HD[item].MTC.cd[argument].type == "SMS" then

  -- -------------------------------------------------------------------------- --
  --                              READ SMS MESSAGE                              --
  -- -------------------------------------------------------------------------- --
  local index = argument
  local sms
    -- might be duplicate validation now...
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
end

-- ------------------------ MTOS SMS MESSAGE COMMAND ------------------------ --
-- send a text message to another device by ID
function MT.CLI.text(item, terminal, mtc, message, command, argument, size)

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
   if MT.C.HD[item].MTC.root.messages.sent == nil then MT.C.HD[item].MTC.root.messages.sent = MT.C.Sample.messages.sent end

  -- check for target messages/received folder - create if missing
  if not MT.C.HD[targetItem].MTC.root.messages then MT.C.HD[targetItem].MTC.root.messages = MT.C.Sample.messages end
  if MT.C.HD[targetItem].MTC.root.messages.received == nil then MT.C.HD[targetItem].MTC.root.messages.received = MT.C.Sample.messages.received end

  -- -------------------------------------------------------------------------- --
  --                          ADD OUTGOING SMS MESSAGE                          --
  -- -------------------------------------------------------------------------- --
  MT.C.HD[item].MTC.counters.smsOUT = MT.C.HD[item].MTC.counters.smsOUT + 1
  MT.C.HD[item].MTC.root.messages.sent[tostring(MT.C.HD[item].MTC.counters.smsOUT)] = {type="SMS", to=tostring(targetItem.ID), from=tostring(item.ID), message=textMessage, at=tostring(textMessageTime)}

  terminal.SendMessage("- MESSAGE SENT -")
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
function MT.CLI.save(item, terminal, mtc, message, command, argument, size)
  if terminal then
    terminal.SendMessage("creating backup...", Color.Gray)
    Timer.Wait(function() terminal.SendMessage("*BACKUP CREATED*") end, 1500)
  end
  MT.C.HD[item].MTC.cdp = nil
  MT.C.HD[item].MTC.cd = nil
  File.Write(MT.Path .. "/MTCHD/MTCHD-" .. tostring(item.ID) .. ".json", json.serialize(MT.C.HD[item]))
end

-- partial utility function for testing JSON serializer and loading from file
function MT.CLI.load(item, terminal, mtc, message, command, argument, size)
  if terminal then terminal.SendMessage("restoring backup...", Color.Gray) end

  local success, fileContent = pcall(function()
    return File.Read(MT.Path .. "/MTCHD/MTCHD-" .. tostring(item.ID) .. ".json")
  end)

  if success then
    -- File read successfully, parse JSON and proceed
    MT.C.HD[item] = json.parse(fileContent)
    MT.CLI.BTR(item, true)

    if terminal then Timer.Wait(function() terminal.SendMessage("*BACKUP RESTORED*", Color(250,100,60,255)) end, 1500) end
  else
    if terminal then terminal.SendMessage("*FAILED: BACKUP MISSING OR CORRUPTED*", Color(250,100,60,255)) end
  end
end

-- ------------------------ MTOS SCREEN LOCK COMMAND ------------------------ --
-- locks the screen with a password for registered devices
function MT.CLI.lock(item, terminal, mtc, message, command, argument, size)
  local profile = MT.CLI.getProfile(item)
  local user = "USER" if profile then user = profile.registeredName end
  local encodedPIN = MT.CLI.encode(message)

  if not profile then terminal.SendMessage("OPERATION FAILED: DEVICE NOT REGISTERED.", Color(250,100,60,255)) return end

  -- ------------------------------ LOCK SCREEN: ------------------------------ --
  -- head
  MT.CLI.header(item, terminal, size.displayWCH)
  -- /head

  -- body
  if encodedPIN and encodedPIN == MT.C.HD[item].MTC.root.user.profile.password then
    terminal.SendMessage("•WELCOME, " .. user .. "!•", Color(75,150,250,255))
    MT.HF.BlankTerminalLines(terminal, 1, "")
    mtc.IsWaiting = false -- reset the waiting flag
  else
    terminal.SendMessage(MT.CLI.textCenter("ENTER PIN:", size.displayWCH))
    if mtc.IsWaiting and encodedPIN ~= MT.C.HD[item].MTC.root.profile.user.password then
      terminal.SendMessage(MT.CLI.textCenter("!INCORRECT PIN!.", size.displayWCH), Color(250,100,60,255))
    else
      terminal.SendMessage(MT.CLI.textCenter("— . — . — . — ", size.displayWCH))
    end
    mtc.IsWaiting = true -- set the waiting flag
    mtc.WaitingFunction = "MT.CLI.lock"
  end
  -- /body

  -- foot
  MT.CLI.footer(item, terminal, size.displayWCH)
  -- /foot

end
-- --------------------- MTOS AUTOMATIC READOUT COMMAND --------------------- --
function MT.CLI.show(item, terminal, mtc, message, command, argument, size)
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

-- --------------------------- MTOS REPORT COMMAND -------------------------- --
function MT.CLI.report(item, terminal, mtc, message, command, argument, size)
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
      MT.CLI.commands.report.reportTypes[argument].functionToCall(item, terminal, mtc, message, command, argument, size)
    else
      terminal.SendMessage("***** REPORT NOT INSTALLED *****", Color(250,100,60,255))
    end
  -- invalid report type
  else
    MT.CLI.error("invalidReport", terminal, argument, Color(250,100,60,255))
  end
end

-- -------------------------------------------------------------------------- --
--                               SHELL COMMANDS                               --
-- -------------------------------------------------------------------------- --

-- This is where the magic happens
function MT.CLI.ls(item, terminal, mtc, message, command, argument, size)
    -- make sure this device has a storage cache
    if MT.C.HD[item] and MT.C.HD[item].MTC and MT.C.HD[item].MTC.root then

      -- if there is no current directory, boot to root
      MT.CLI.BTR(item)
      terminal.ClearHistory()
      terminal.SendMessage("@" .. tostring(item))

      -- -------------------------------------------------------------------------- --
      --                             DIRECTORY CONTENTS                             --
      -- -------------------------------------------------------------------------- --
      -- I loops them scoops them into tables first because I wants to sort them.
      if next(MT.C.HD[item].MTC.cd) ~= nil then
        local recordCount = 0
        local dir = {}
        local exe = {}
        local sms = {}
        local sys = {}
        local txt = {}
        -- ------------------------------- CATEGORIZE ------------------------------- --
        for record, v in pairs(MT.C.HD[item].MTC.cd) do
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
        -- --------------------------------- DISPLAY -------------------------------- --

        -- directories
        for record, v in pairs(dir) do
            --terminal.SendMessage("<DIR>...| " .. v.name ..  "/")
            terminal.SendMessage(v.name ..  "/" .. string.rep(".", string.len(tostring(item)) - string.len(v.name) - 5) .. "<DIR> ")
        end
        -- executables
        for record, v in pairs(exe) do
            --terminal.SendMessage("<EXE>..| " .. v.name .. "/")
            terminal.SendMessage(v.name ..  "/" .. string.rep(".", string.len(tostring(item)) - string.len(v.name) - 5) .. "<EXE> ")
        end
        -- messages
        for id, sms in pairs(sms) do
          if item.hasTag("narrowDisplay") then -- narrow terminal
            -- terminal.SendMessage("<SMS>..| " .. record .. " | " .. string.sub(v.message, 1, 10) .. "...")
            terminal.SendMessage("<SMS>..| " .. id .. " | T:".. sms.to .. " | F:".. sms.from .. " | L:" .. string.len(sms.message))
          else
            terminal.SendMessage("<SMS>..| " .. id .. " | TO: ".. sms.to .. " | FROM:" .. sms.from .. " | " ..  string.sub(sms.message, 1, 30) .. "...")
          end
        end
        -- system files
        for record, v in pairs(sys) do
          -- terminal.SendMessage("<SYS>...| " .. v.name)
          terminal.SendMessage(v.name ..  "/" .. string.rep(".", string.len(tostring(item)) - string.len(v.name) - 5) .. "<SYS> ")
        end
        -- documents
        for record, v in pairs(txt) do
          -- terminal.SendMessage("<TXT>..| " .. v.name)
          terminal.SendMessage(v.name ..  "/" .. string.rep(".", string.len(tostring(item)) - string.len(v.name) - 5) .. "<TXT> ")
        end

        -- --------------------------------- FOOTER --------------------------------- --
        terminal.SendMessage(tostring(recordCount) .. " records")
        MT.HF.BlankTerminalLines(terminal, 1)
        terminal.SendMessage("@" .. MT.C.HD[item].MTC.cdp)
      else
        -- empty (no contents)
        terminal.SendMessage("0 records found")
        MT.HF.BlankTerminalLines(terminal, 1)
        terminal.SendMessage("@" .. MT.C.HD[item].MTC.cdp)
      end
    else
        -- no data cache
        terminal.SendMessage("!ERROR! No harddrive detected.")
    end
end

-- -------------------- MTOS CLI CHANGE DIRECTORY COMMAND ------------------- --
function MT.CLI.cd(item, terminal, mtc, message, command, argument, size)
  if message == "cd" and not argument then terminal.SendMessage("!NO DIRECTORY SPECIFIED!", Color(250,100,60,255)) return end
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

-- -------------------------- MTOS CLI COPY COMMAND ------------------------- --
-- the copy command just piggybacks off the move command
function MT.CLI.copy(item, terminal, mtc, message, command, argument, size)
  MT.CLI.mv(item, terminal, mtc, message, command, argument, true)
end

function MT.CLI.mkdir(item, terminal, mtc, message, command, argument, size)
    -- check for a storage cache
    if MT.itemCache[item] and MT.C.HD[item].MTC and MT.C.HD[item].MTC.root then
        -- if there is no current directory - default to root
       MT.CLI.BTR(item)

      --local newDirectory = MT.CLI.getDirectory(MT.itemCache[item], argument)
      if MT.C.HD[item].MTC.cd[argument] then
        terminal.SendMessage("!ERROR! FILE ALREADY EXISTS", Color(250,100,60,255))
        else
          MT.C.HD[item].MTC.cd[argument] = {type="DIR", name=argument}
          MT.CLI.ls(item, terminal)
        end
    else
        -- no storage cache
        terminal.SendMessage("!ERROR! No harddrive detected.")
    end
end
-- ---------------------- MTOS CLI DELETE FILE COMMAND ---------------------- --
function MT.CLI.delete(item, terminal, mtc, message, command, argument, size)

    MT.CLI.BTR(item)-- if there there is no current directory then boot to root
    -- purge records
    if MT.C.HD[item].MTC.cd[argument] and MT.C.HD[item].MTC.cd[argument].type ~= "DIR" then
      -- need to convert from .name to table....
      MT.C.HD[item].MTC.cd[argument] = nil
      terminal.SendMessage("*PURGE SUCCESFUL*")
      return
    end

    -- loop through and try to find a name match...
    for k,v in pairs(MT.C.HD[item].MTC.cd) do
      if v.name and string.lower(v.name) == string.lower(argument) then
        MT.C.HD[item].MTC.cd[k] = nil
        terminal.SendMessage("*PURGE SUCCESFUL*")
        return
      end
    end

    -- no matches found
    MT.CLI.ls(item, terminal)
    terminal.SendMessage("*no such file*")
end

-- -------------------- MTOS CLI DELETE DIRECTORY COMMAND ------------------- --
function MT.CLI.rmdir(item, terminal, mtc, message, command, argument, size)
    if MT.itemCache[item] and MT.C.HD[item].MTC and MT.C.HD[item].MTC.root then
      MT.CLI.BTR(item)-- if there there is no current directory then boot to root
      -- purge records
      if MT.C.HD[item].MTC.cd[argument] and MT.C.HD[item].MTC.cd[argument].type == "DIR" then
        MT.C.HD[item].MTC.cd[argument] = nil
        MT.CLI.ls(item, terminal)
        terminal.SendMessage("*PURGE SUCCESFUL*")
      else
        MT.CLI.ls(item, terminal)
        terminal.SendMessage("*no such directory*")
      end
    else
        MT.HF.BlankTerminalLines(terminal, 5)
        terminal.SendMessage("!ERROR! NO DRIVE FOUND")
    end
end


-- -------------------------- MTOS CLI MOVE COMMAND ------------------------- --
-- ex: mv textcolor.exe /MTC/root
function MT.CLI.mv(item, terminal, mtc, message, command, argument, copy)
  -- -------------------------------------------------------------------------- --
  --                             INITIAL VALIDATION                             --
  -- -------------------------------------------------------------------------- --
  if not copy then copy = false end -- default to move operation
  -- validate current directory
  MT.CLI.BTR(item)
  -- validate target file
  if not MT.C.HD[item].MTC.cd[argument] then
    -- index match failed, check for a name match
    local foundNameMatch = false
    for k,v in pairs(MT.C.HD[item].MTC.cd) do
      if v.name and string.lower(v.name) == string.lower(argument) then
        argument = k -- set the argument to the key
        foundNameMatch = true
        break
       end
    end
    if not foundNameMatch then
      terminal.SendMessage("FILE NOT FOUND: " .. MT.C.HD[item].MTC.cdp .. "." .. argument, Color(250,100,60,255))
      return
    end
  end

  local source -- primary argument is the record to be moved or copied
  local destinationPartialPath -- secondary argument is the destination partial path

  -- ARGUMENTS: reparse the original message to get the secondary argument
  if message ~= nil then
      local messageTable = MT.HF.Split(message," ")
      source = messageTable[2]
      destinationPartialPath = messageTable[3]
  end
  -- VALIDATION: check for missing arguments
  if command == nil or source == nil or destinationPartialPath == nil then terminal.SendMessage("MISSING ARGUMENT(S)", Color(250,100,60,255)) return end

  -- VALIDATION: check if we've created a valid path
  if MT.CLI.getDirectory(MT.C.HD[item].MTC.root, destinationPartialPath) then
      -- ARGUMENTS: convert the partial path to a table loaction
      local destinationPath = MT.CLI.getDirectory(MT.C.HD[item].MTC.root, destinationPartialPath)
      -- EXECUTION: clone the source to the destination
      destinationPath[source] = MT.C.HD[item].MTC.cd[source]
      -- EXECUTION: delete the source
      if MT.C.HD[item].MTC.cd[argument] then
        if copy == false then MT.C.HD[item].MTC.cd[argument] = nil end
              MT.CLI.ls(item, terminal)
              terminal.SendMessage("*OPERATION SUCCESFUL*")
              terminal.SendMessage("your file is now located at...", Color.Gray)
      else
              MT.CLI.ls(item, terminal)
              terminal.SendMessage("*OPERATION FAILED*")
              terminal.SendMessage("directory not found...", Color.Gray)
      end
  else
      terminal.SendMessage("INVALID PATH", Color(250,100,60,255))
  end
end

  -- ---------------------- MTOS CLI EXECUTABLES COMMAND ---------------------- --
function MT.CLI.run(item, terminal, mtc, message, command, argument, size)
    local formattedArgument = argument:match("([^%.]*)%.?.*$")
    if string.lower(MT.C.HD[item].MTC.cd[formattedArgument].type) ~= "exe" then terminal.SendMessage("INVALID FILE TYPE: " .. MT.C.HD[item].MTC.cdp .. "/" .. formattedArgument .. "." .. MT.C.HD[item].MTC.cd[formattedArgument].type, Color(250,100,60,255)) return end
    local execute = function()
      local functionToRun = MT.C.HD[item].MTC.cd[formattedArgument].functionToCall
      -- Load the function
      local loadedFunction, errorMessage = load("return " .. functionToRun)

      -- Check if there were any errors during loading
      if not loadedFunction then
          print("Error loading code: " .. errorMessage)
      else
          -- Execute the loaded function
          loadedFunction()(item, terminal, mtc, nil, size)
          -- 'result' will contain the result of the executed function
      end
    end

    -- I don't remember what this does 1/19/24
    if formattedArgument == "" then
        formattedArgument = argument
    end

    -- if there is no current directory - boot us to root
    MT.CLI.BTR(item)
    terminal.ClearHistory()
    terminal.SendMessage("finding file...", Color.Gray)
    Timer.Wait(function()
    if not MT.C.HD[item].MTC.cd[formattedArgument] then
      terminal.SendMessage("file not found: " .. MT.C.HD[item].MTC.cdp .. "." .. formattedArgument .. ".EXE", Color(250,100,60,255))
    else
      terminal.SendMessage("attempting execution...", Color.Gray)
      Timer.Wait(function() execute() end, 1500)
    end
    end, 1000)

    --MT.C.HD[item].MTC.cdp = "/MTC/root"
    --MT.CLI.EXE[argument].functionToCall(item, terminal)
end


-- registers a MTC to a user (this is how player claim devices)
function MT.CLI.register(item, terminal, mtc, response, size)
  -- check for an existing profile
  local profile = MT.CLI.getProfile(item)
  if profile then
    terminal.SendMessage("This device is already registered to: " .. profile.registeredName)
    terminal.SendMessage("terminating program... ", Color.Gray)
    return
  end

  -- assign device ownership

  local user = item.GetRootInventoryOwner()
  mtc.IsWaiting = true

  terminal.ClearHistory()
  -- head
  MT.CLI.header(item, terminal, size.displayWCH)
  MT.HF.BlankTerminalLines(terminal, 1, "")
  -- /head

    if response == nil then -- there sh


      -- body
        terminal.SendMessage(MT.CLI.textCenter("•WELCOME, " .. user.name .. "!•", size.displayWCH), Color(75,150,250,255))
        terminal.SendMessage(MT.CLI.textCenter("To register this device, pleae enter a 4 digit pin code:", size.displayWCH), Color(75,150,250,255))
        mtc.IsWaiting = true -- set the waiting flag
        mtc.WaitingFunction = "MT.CLI.register"
      elseif MT.CLI.validatePin(response) then
        -- check for the user directory, if it doesn't exist, create it
        if not MT.C.HD[item].MTC.root.user then MT.C.HD[item].MTC.root.user = {type="DIR", name="user"} end
        -- at long last, add profile.txt
        MT.C.HD[item].MTC.root.user.profile = {type="TXT", name="profile", registeredName=user.name, registeredID=tostring(user.ID), password=MT.CLI.encode(response)}
        terminal.SendMessage(MT.CLI.textCenter("REGISTRATION COMPLETE!", size.displayWCH), Color(75,150,250,255))
        terminal.SendMessage(MT.CLI.textCenter("exiting program...", size.displayWCH), Color.Gray)

        mtc.IsWaiting = false
        Timer.Wait(function() MT.CLI.dWelcome(item, terminal, size) end, 2000)
      else
              terminal.SendMessage(MT.CLI.textCenter("!INVALID RESPONSE!", size.displayWCH), Color(250,100,60,255))
              terminal.SendMessage(MT.CLI.textCenter("Pleae enter a 4 digit pin code:", size.displayWCH), Color(75,150,250,255))
              --MT.HF.BlankTerminalLines(terminal, 1, "")
      end
      -- /body

  -- foot
  MT.HF.BlankTerminalLines(terminal, 1, "")
  MT.CLI.footer(item, terminal, size.displayWCH)
  -- /foot
end

-- password protected lock screen for registered MTCs
function MT.CLI.lockScreen(item, terminal, response)
  if response == nil then
      terminal.SendMessage("*****PRESS ANY KEY*****")
  end
end
-- sets target power on a simple generator
function MT.CLI.setPower(item, terminal, mtc, message, command, argument, size)
local simpleGenerator = MTUtils.GetComponentByName(item, "Mechtrauma.SimpleGenerator")
simpleGenerator.PowerToGenerate = MT.HF.Clamp(tonumber(argument), 0, simpleGenerator.MaxPowerOut)
terminal.SendMessage("Power target set to: " .. MT.HF.Clamp(tonumber(argument), 0, simpleGenerator.MaxPowerOut), Color.Lime)
end
-- --------------------- PROTOTYPE ERROR STANDARDIZATION -------------------- --
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
--                          MTC EXECUTABLE FUNCTIONS                          --
-- -------------------------------------------------------------------------- --
function MT.CLI.textcolor(item, terminal, mtc, response, size)

    if response == nil then -- there sh
        terminal.SendMessage("What color would you like? Green or Red")
        mtc.IsWaiting = true
        mtc.WaitingFunction = "MT.CLI.textcolor"
    else
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

-- -------------------------------------------------------------------------- --
--                            MTC EXECUTABLES TABLE                           --
-- -------------------------------------------------------------------------- --
-- currently depricated
-- move it MT computers??

MT.CLI.EXE = {
    textcolor={ -- changes text color
        functionToCall = MT.CLI.textcolor
    },
    register={ -- registers device to user
      functionToCall = MT.CLI.register
    },
    text={-- registers MTC for texting
      functiontocall = MT.CLI.textcolor
    },
    pbank={-- registers MTC for texting
    functiontocall = MT.C.pBankWelcome
  }
}

-- -------------------------------------------------------------------------- --
--                           MTOS SYSTEM FILES TABLE                          --
-- -------------------------------------------------------------------------- --
-- MTOS CLI commands rely on .SYS files to funcition
-- move it MT computers??

MT.CLI.SYS = {
  cli={
    type="SYS",
    name="MT_CLI",
    version = 1,0,
    key="UNREGISTERED",
  },
  help={
    type="SYS",
    name="help",
    version = 1,0,
    key="UNREGISTERED",
  },
  read={
    type="SYS",
    name="reader",
    version = 1,0,
    key="UNREGISTERED",
  },
  run={
    type="SYS",
    name="run",
    version = 1,0,
    key="UNREGISTERED",
  },
  show={
    type="SYS",
    name="readouts",
    version = 1,0,
    key="UNREGISTERED",
  },
  text={
    type="SYS",
    name="MTMSG_SMS",
    version = 1,0,
    key="UNREGISTERED",
  },
}


-- -------------------------------------------------------------------------- --
--                             MTC ERROR MESSAGES                             --
-- -------------------------------------------------------------------------- --
-- an attempt at standardizing validation - kinda wish I had finished this

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
        requireSYS = "cli",
        requireSYSv = 1.0,
        functionToCall = MT.CLI.cd,
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
    copy = {
      help = "[target record] [destination path]",
      helpDetails = "Copies a record (and all contents) from the current directory to the target directory",
      helpExample = "mv program /home",
      altCommands = {"clone","twin"},
      requireCCN = false,
      requireARG = true,
      requireSYS = "cli",
      requireSYSv = 1.0,
      functionToCall = MT.CLI.copy,
      allowedItems = {"mtc"}
  },
    delete = {
      help = "[file]",
      helpDetails = "Enables / disables diagnostic mode.",
      helpExample = "'diagnostics on'",
      altCommands = {"diag", "diagnostic"},
      requireCCN = false,
      requireARG = true,
      requireSYS = "cli",
      requireSYSv = 1.0,
      functionToCall = MT.CLI.delete,
      allowedItems = {"mtc", "mtmobile"}
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
        requireSYS = "help",
        requireSYSv = 1.6,
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
        requireSYS = "cli",
        requireSYSv = 1.0,
        functionToCall = MT.CLI.ls,
        allowedItems = {"mtc"}
    },
    load = {
        help = "n/a",
        helpDetails = "Loads harddrive data.",
        helpExample = "'load'",
        altCommands = {"restore"},
        requireCCN = false,
        requireARG = false,
        functionToCall = MT.CLI.load,
        allowedItems = {"mtc"}
    },
    lock = {
      help = "n/a",
      helpDetails = "Lock device.",
      helpExample = "'lock'",
      altCommands = {"loc,lok"},
      requireCCN = false,
      requireARG = false,
      functionToCall = MT.CLI.lock,
      allowedItems = {"mtc","mtmobile"}
    },
    mkdir = {
        help = "[new directory name]",
        helpDetails = "Create a new sub-directory in the current directory.",
        helpExample = "mkdir myfolder",
        altCommands = {"makedir"},
        requireCCN = false,
        requireARG = true,
        requireSYS = "cli",
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
        requireSYS = "cli",
        requireSYSv = 1.0,
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
      requireSYS = "read",
      requireSYSv = 0.5,
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
        requireSYS = "cli",
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
        requireSYS = "run",
        functionToCall = MT.CLI.run,
        allowedItems = {"mtc"}
    },
    save = { -- probably should be disabled in game
        help = "n/a",
        helpDetails = "Creates backup of MTC data.",
        helpExample = "'save'",
        altCommands = {"backup"},
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
        --requireSYS = "show",
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
        requireSYS = "text",
        functionToCall = MT.CLI.text,
        allowedItems = {"MTC", "terminal"}
    },
}


-- -------------------------------------------------------------------------- --
--                                MTC TERMINAL                                --
-- -------------------------------------------------------------------------- --
-- case agnostic CLI
-- supports waiting programs
-- supports permissions (item based)
-- supports system commands depending on .SYS files
-- other stuff

-- -------------------------------------------------------------------------- --
--                        MTC COMMAND LINE INTERPRETOR                        --
-- -------------------------------------------------------------------------- --

--called once for each terminal message sent by a player (unless terminal is waiting)
function MT.CLI.terminalCommand(item, terminal, mtc, message, width, height)
  local size = {displayHPX = height, displayHCH = height, displayWPX = width, displayWCH = width / 9.66, fontSize=14, fontW = (14 * .69) }


  -- add terminal waiting logic here as it is server side
  if mtc and mtc.IsWaiting == true then
    -- -------------------------------------------------------------------------- --
    --                     MTC CLI: IS WAITING FOR A RESPONSE                     --
    -- -------------------------------------------------------------------------- --
    local waitingFunction, errorMessage = load("return " .. mtc.WaitingFunction)

    -- Check if there were any errors during loading
    if not waitingFunction then
        print("Error loading code: " .. errorMessage)
    else
        -- Execute the loaded function
        waitingFunction()(item, terminal, mtc, string.lower(message), size)
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
        terminal.SendMessage("***NO CONNECTION***", Color(250,100,60,255))
        return
      -- check if the command requires a .SYS file present and registered.
      elseif MT.CLI.commands[command].requireSYS and not MT.CLI.checkSYS(item, MT.CLI.commands[command].requireSYS) then
        terminal.SendMessage("ERROR: " .. MT.CLI.commands[command].requireSYS .. " module initialization failed.")
        return
      end

      -- -------------------------------------------------------------------------- --
      --                               EXECUTE COMMAND                              --
      -- -------------------------------------------------------------------------- --
      --Timer.Wait(function()  MT.CLI.commands[command].functionToCall(item, terminal, mtc, message, command, argument, size) end, 1000)
      MT.CLI.commands[command].functionToCall(item, terminal, mtc, message, string.lower(command), argument, size)

    else
      -- empty message
     MT.CLI.dWelcome(item, terminal, size)
    end
  end
end

-- -------------------------------------------------------------------------- --
--                            SUPPORTING FUNCTIONS                            --
-- -------------------------------------------------------------------------- --
-- helper functions for the CLI
function MT.CLI.textCenter(string, displayWCH, fillWith)
  local offset = (displayWCH - string.len(string)) / 2
  if fillWith == nil then fillWith = " " end -- nill check, defaults to space filler
  return string.rep(fillWith, offset) .. string
end

-- -------------------------------------------------------------------------- --
--                               DISPLAY SCREENS                              --
-- -------------------------------------------------------------------------- --
-- reusable display screens for the CLI UI

function MT.CLI.header(item, terminal, displayWCH)
  terminal.ClearHistory()
  terminal.SendMessage(string.rep("_", (displayWCH)))
  MT.HF.BlankTerminalLines(terminal, 1, "")
  terminal.SendMessage("@" .. tostring(item))
  terminal.SendMessage("ClockTime: " .. MT.HF.Round(Game.GameScreen.GameTime, 2) .. "T" )
end

function MT.CLI.footer(item, terminal, displayWCH)
  terminal.SendMessage("Mechtrauma OS v" .. tostring(MT.C.HD[item].MTC.root.mtos.kernel.ver))
  terminal.SendMessage(string.rep("_", (displayWCH)))
end

function MT.CLI.dWelcome(item, terminal, size)
  local profile = MT.CLI.getProfile(item)
  local user = "USER" if profile then user = profile.registeredName end
  --local width = terminal.CGUIX / 10.8 -- width in pixels / the magic beauty
  --local height = terminal.CGUIY / 10.8 -- height in pixels
  --if item.HasTag("narrowDisplay") then width = 25 end
  ---print("width: " .. terminal.CGUIX .. " Height: " .. terminal.CGUIY)
  print("widthPX: " .. size.displayWPX .. " HeightPX: " .. size.displayHPX)
  print("widthCH: " .. size.displayWCH .. " HeightCH: " .. size.displayHCH)

  -- ----------------------------- WELCOME SCREEN: ---------------------------- --
  -- head
  MT.CLI.header(item, terminal, size.displayWCH)
  MT.HF.BlankTerminalLines(terminal, 2, "")
  --/head

  -- body
    -- format for narrow displays
    if string.len("•WELCOME, " .. user .. "!•") > size.displayWCH then
      terminal.SendMessage(MT.CLI.textCenter("•WELCOME•", size.displayWCH, " "), Color(75,150,250,255))
      terminal.SendMessage(MT.CLI.textCenter(user, size.displayWCH, " "), Color(75,150,250,255))
    else
      terminal.SendMessage(MT.CLI.textCenter("•WELCOME, " .. user .. "!•",  size.displayWCH," "), Color(75,150,250,255))
      MT.HF.BlankTerminalLines(terminal, 1, "")
    end
  -- /body


  -- foot
  MT.HF.BlankTerminalLines(terminal, 2, "")
  MT.CLI.footer(item, terminal, size.displayWCH)
  -- /foot
end

-- -------------------------------------------------------------------------- --
--                            VALIDATION FUNCTIONS                            --
-- -------------------------------------------------------------------------- --

-- ------------- VALIDATE: COMMAND vs COMMANDS and ALT-COMMANDS ------------- --
-- get a valid command (if any)
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

-- ----------------- VALIDATE: DEVICE PERMISSONS for COMMAND ---------------- --
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



-- what a ******** mess! why no lua 5.4 MOONSHARP! (we want save nagivation operator)
-- a series of null checks, I can't remember if they were all necessary but I just didn't want to deal with it.
--MT.CLI.checkSYS(item, MT.CLI.commands[command].requireSYS)
function MT.CLI.checkSYS(item, requiredSYS, targetItem, targetRequiredSYS)
  --print("THIS: " .. MT.CLI.encode(string.lower(requiredSYS) .. tostring(item.ID)))
  --print("THAT: " .. MT.C.HD[item].MTC.root.mtos[requiredSYS].key)

  if not MT.C.HD[item] or not MT.C.HD[item].MTC.root.mtos then
    print("failed here 1")
    return false
  elseif not MT.C.HD[item].MTC.root.mtos[requiredSYS] or not MT.C.HD[item].MTC.root.mtos[requiredSYS].key then
    print("failed here 2")
    return false
  elseif MT.CLI.encode(string.lower(requiredSYS) .. tostring(item.ID)) == MT.C.HD[item].MTC.root.mtos[requiredSYS].key then
    return true
  else
    print("failed here 3")
    return false
  end
end




-- ---------------------- GET DIRECTORY (from partials) --------------------- --
-- combines a start table location with a partial path and returns the final table location
function MT.CLI.getDirectory(startingTable, partialPath)
    local keys = {}
    -- if root is included in the partial path, remove it
    local rootPos = partialPath:find("root")
    if rootPos then
      partialPath = partialPath:sub(rootPos + 5)  -- Adding 5 to skip 'root'
    end
    -- isolate the segments of the path as keys
    for key in partialPath:gmatch("[^./]+") do
      table.insert(keys, key)
    end
    -- construct (and test) the final table location
    local finalTable = startingTable
    for _, key in ipairs(keys) do
      finalTable = finalTable[key]
        if type(finalTable) ~= "table" then
            return nil  -- Key does not lead to a table
        end
    end
    return finalTable
end

-- ------------------- GET PARENT DIRECTORY PATH (partial) ------------------ --
-- gives the partial parent directory path
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

-- possibly depricated
function MT.CLI.getParentDirectoryTable(rootDirectory, path)
  local lastSlashIndex = path:find("[^/]+/$") -- Find the index of the last key and slash combination
  if lastSlashIndex then
    return MT.CLI.getDirectory(rootDirectory, path:sub(1, lastSlashIndex - 1)) -- Remove everything after the last key and slash
  else
      return path -- Return the path as is if no keys or slashes found
  end
end

-- possibly depricated
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



 -- -------------------------- VALIDATE USER PROFILE ------------------------- --
 -- handy function for handling the cursed layered null checks
function MT.CLI.getProfile(item)
  -- VALIDATION: check for a user directory in root
  if not MT.C.HD[item].MTC.root.user then
    return nil -- no user directory in root
  else
    -- VALIDATION: check for a profile.txt in the user directory
    if MT.C.HD[item].MTC.root.user.profile then
      -- found it!
      return MT.C.HD[item].MTC.root.user.profile
    else
      return nil -- no profile.txt in user directory
    end
  end
end

-- ----------------------- VALIDATE CURRENT DIRECTORY ----------------------- --
-- the infamous boot to root function
function MT.CLI.BTR(item, force)
    -- we *should* keeping track of the current directory and storing it in the MT item cache
    -- but if that fails for any reason.... WE BOOT TO ROOT!
    -- force is an override that ignores the current directory and boots to root

    if not MT.C.HD[item].MTC.cd or force then
      MT.C.HD[item].MTC.cd = MT.C.HD[item].MTC.root -- MT.CLI.getDirectory(MT.itemCache[item], MT.C.HD[item].MTC.cdp)
      MT.C.HD[item].MTC.cdp = "/MTC/root"
    end
end

-- -------------------------------------------------------------------------- --
--                                  SECURITY                                  --
-- -------------------------------------------------------------------------- --

-- ---------------------------- SIMPLE ENCRYPTION --------------------------- --
-- encodes a string with simple encryption

  -- This is your secret 67-bit key (any random bits are OK)
  local Key53 = 8186484168865098
  local Key14 = 4887
  local inv256

  function MT.CLI.encode(string)
    if not inv256 then
      inv256 = {}
      for M = 0, 127 do
        local inv = -1
        repeat inv = inv + 2
        until inv * (2*M + 1) % 256 == 1
        inv256[M] = inv
      end
    end
    local K, F = Key53, 16384 + Key14
    return (string:gsub('.',
      function(m)
        local L = K % 274877906944  -- 2^38
        local H = (K - L) / 274877906944
        local M = H % 128
        m = m:byte()
        local c = (m * inv256[M] - (H - M) / 128) % 256
        K = L * F + H + c + m
        return ('%02x'):format(c)
      end
    ))
  end
-- ---------------------------- SIMPLE DECRYPTION --------------------------- --
-- decodes an encoded string
  function MT.CLI.decode(string)
    local K, F = Key53, 16384 + Key14
    return (string:gsub('%x%x',
      function(c)
        local L = K % 274877906944  -- 2^38
        local H = (K - L) / 274877906944
        local M = H % 128
        c = tonumber(c, 16)
        local m = (c + (H - M) / 128) * (2*M + 1) % 256
        K = L * F + H + c + m
        return string.char(m)
      end
    ))
  end

  -- -------------------------------- PIN CODES ------------------------------- --
  function MT.CLI.validatePin(input)
    -- Check if the length is exactly 4 characters
    if #input == 4 then
        -- Check if the string contains only numbers
        if input:match("^[0-9]+$") then
            return true
        end
    end
    return false
end



