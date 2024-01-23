-- -------------------------------------------------------------------------- --
--                      WELCOME TO PEASANT FINANCIAL BANK                     --
-- -------------------------------------------------------------------------- --

function MT.C.pBankWelcome(item, terminal, mtc, response, size)
    terminal.TextColor = Color(50,200,75,255)
    mtc.IsWaiting = true
    mtc.WaitingFunction = "MT.C.pBank"
      -- ----------------------------- WELCOME SCREEN: ---------------------------- --
      -- head
      MT.C.pBankHeader(item, terminal, size.displayWCH)
      --/head


        if size.displayWCH > 35 then
          terminal.SendMessage(MT.CLI.textCenter("╔═══════════════════════════════╗", size.displayWCH))
          terminal.SendMessage(MT.CLI.textCenter("║        _                 _    ║", size.displayWCH))
          terminal.SendMessage(MT.CLI.textCenter("║       | |               | |   ║", size.displayWCH))
          terminal.SendMessage(MT.CLI.textCenter("║  _ __ | |__   __ _ _ __ | | __║", size.displayWCH))
          terminal.SendMessage(MT.CLI.textCenter("║ | '_ \\| '_ \\ / _` | '_ \\| |/ /║", size.displayWCH))
          terminal.SendMessage(MT.CLI.textCenter("║ | |_) | |_) | (_| | | | |   < ║", size.displayWCH))
          terminal.SendMessage(MT.CLI.textCenter("║ | .__/|_.__/ \\__,_|_| |_|_|\\_\\║", size.displayWCH))
          terminal.SendMessage(MT.CLI.textCenter("║ | |                           ║", size.displayWCH))
          terminal.SendMessage(MT.CLI.textCenter("║ |_|                           ║", size.displayWCH))
          terminal.SendMessage(MT.CLI.textCenter("╚═══════════════════════════════╝", size.displayWCH))
          terminal.SendMessage(MT.CLI.textCenter("Welcome to Peasant Financial Bank!", size.displayWCH))
          terminal.SendMessage(MT.CLI.textCenter("(press any key to continue)", size.displayWCH), Color.Gray)
        else
          terminal.SendMessage("")
          terminal.SendMessage(string.rep("_", size.displayWCH))
          terminal.SendMessage(MT.CLI.textCenter("Welcome to Peasant Financial Bank!", size.displayWCH))
          terminal.SendMessage(MT.CLI.textCenter("(press any key to continue)", size.displayWCH), Color.Gray)
        end
end

function MT.C.pBank(item, terminal, mtc, response, size)
    -- some pBank color
    terminal.TextColor = Color(50,200,75,255)

    local profile = MT.CLI.getProfile(item)
    -- nil check
    if not profile then terminal.SendMessage("You must register this device to use pBank.") mtc.IsWaiting = false return end
    local owner = Entity.FindEntityByID(tonumber(profile.registeredID))
    local width = 30 -- (terminal.CGUIX / 10.8) -- width in pixels / the magic beauty
    --local height = terminal.CGUIY -- height in pixels
    --Character.Wallet.Balance

    -- claim the waiting function
    mtc.IsWaiting = true
    mtc.WaitingFunction = "MT.C.pBank"

    if response == nil or response == "" then --

        -- head
            MT.C.pBankHeader(item, terminal, size.displayWCH)
        --/head


      -- body
    --terminal.SendMessage("Welcome to pBank, " .. owner.name .. "!")
      MT.HF.BlankTerminalLines(terminal, 1, "")
      if size.displayWCH > 45 then

        terminal.SendMessage("•Please select an option:")
        terminal.SendMessage(MT.CLI.textCenter(string.format("%-20s", "(1) Balance") .. "  " .. string.format("%-20s", "(2) Deposit"), size.displayWCH))
        terminal.SendMessage(MT.CLI.textCenter(string.format("%-20s", "(3) Transfer") .. "  " .. string.format("%-20s", "(4) Transacitions"), size.displayWCH))
        terminal.SendMessage(MT.CLI.textCenter(string.format("%-20s", "(5) Investments") .. "  " .. string.format("%-20s", "(6) Loans"), size.displayWCH))
        terminal.SendMessage(MT.CLI.textCenter(string.format("%-20s", "(7) Successor") .. "  " .. string.format("%-20s", "(8) EXIT"), size.displayWCH))
      else
        terminal.SendMessage("Select an option:")
        terminal.SendMessage("(1) - Check Balance")
        terminal.SendMessage("(2) - Make Deposit")
        terminal.SendMessage("(3) - Transfer Funds")
        terminal.SendMessage("(4) - View Transacitions")
        terminal.SendMessage("(5) - Investments")
        terminal.SendMessage("(6) - Loans")
        terminal.SendMessage("(7) - Assign Successor")
        terminal.SendMessage("(8) - EXIT")
      end
      -- /body

      -- foot
        MT.C.pBankFooter(item, terminal, size.displayWCH)
      -- /foot
    elseif response == "1" then
      terminal.SendMessage("Your current balance is: ") -- .. owner.Wallet.Balance, Color.Lime
    elseif response == "2" then
      terminal.SendMessage("How much would you like to deposit?")
      --mtc.IsWaiting = true
      --mtc.WaitingFunction = "MT.C.pBank"
    elseif response == "3" then
      terminal.SendMessage("Who would you like to transfer funds to?")
      --mtc.IsWaiting = true
      --mtc.WaitingFunction = "MT.C.pBank"
    elseif response == "4" then
      terminal.SendMessage("Your transaction history is as follows:")
      --mtc.IsWaiting = true
      --mtc.WaitingFunction = "MT.C.pBank"
    elseif response == "5" then
      terminal.SendMessage("Your current investments are as follows:")
      --mtc.IsWaiting = true
      --mtc.WaitingFunction = "MT.C.pBank"
    elseif response == "6" then
        terminal.SendMessage("Your current loans are as follows:")
        --mtc.IsWaiting = true
        --mtc.WaitingFunction = "MT.C.pBank"
    elseif response == "7" then
      MT.C.pBankSuccessor(item, terminal, mtc, nil, size)
    elseif response == "8" or string.lower(response) == "exit"  then
      mtc.IsWaiting = false
      terminal.SendMessage("-Terminating Program-")
      -- reset color....
      --terminal.TextColor = Color(255,255,255,255)
      MT.CLI.dWelcome(item, terminal, size)
    else
        print("reponse: " .. response)
      terminal.SendMessage("!INVALID RESPONSE!", Color(250,100,60,255))
    end
  end

  -- ----------------------------- HEADER DISPLAY ----------------------------- --


  -- -------------------------------------------------------------------------- --
  --                            pBANK MENU FUNCTIONS                            --
  -- -------------------------------------------------------------------------- --

  -- ------------------------------- 7 Successor ------------------------------ --
function MT.C.pBankSuccessor(item, terminal, mtc, response, size)
    local profile = MT.CLI.getProfile(item)
    --print(profile.successorID)
    --print(profile.name)
    -- update the waiting function
    mtc.IsWaiting = true
    mtc.WaitingFunction = "MT.C.pBankSuccessor"
    -- header
    MT.C.pBankHeader(item, terminal, size.displayWCH)
        --if profile.successorID == nil then print(profile.successorID .. " is nil.... WFT?") end
        if profile.successorName ~= nil then
            terminal.SendMessage("Your current successor is: " .. profile.successorName )
            terminal.SendMessage(MT.CLI.textCenter("Please select an option:", size.displayWCH))

            terminal.SendMessage("(1) - Remove Successor ")
            terminal.SendMessage("(2) - Keep Successor")

            -- footer
            MT.C.pBankFooter(item, terminal, size.displayWCH)

            -- -------------------------------- response -------------------------------- --
            if response == "1" or response == "yes" then
                -- remove successor
                terminal.SendMessage(profile.successorName .. " has been removed as you successor.")
                profile.successorName = nil
                profile.successorID = nil
                Timer.Wait(function() MT.C.pBank(item, terminal, mtc, nil, size) end, 2500)
            elseif response == "2" or response == "no" then
                -- keep successor
                terminal.SendMessage(profile.successorName .. " will remian as your successor.")
                terminal.SendMessage("returning to main menu...", Color.Gray)
                Timer.Wait(function() MT.C.pBank(item, terminal, mtc, nil, size) end, 2500)
            elseif response == "7" or response == "" or response == nil then
                -- do nothing
                return
            else
                terminal.SendMessage("!INVALID RESPONSE!", Color(250,100,60,255))
            end
        else
            -- if there is no successor, skip to assigning one
            MT.C.pBankChangeSuccessor(item, terminal, mtc, response, size)
        end
end

-- -------------------------------------------------------------------------- --
--                            7.1 CHANGE SUCCESSOR                            --
-- -------------------------------------------------------------------------- --
function MT.C.pBankChangeSuccessor(item, terminal, mtc, response, size)
    local profile = MT.CLI.getProfile(item)

    -- claim the waiting function
    mtc.IsWaiting = true
    mtc.WaitingFunction = "MT.C.pBankChangeSuccessor"

    -- -------------------------------- REPONSES -------------------------------- --

    -- START: initial display
    if response == nil or response == "" then
        MT.C.pBankHeader(item, terminal, size.displayWCH)
        terminal.SendMessage("In the event of your death, who would you like to assign as your successor?")
        --print(GameSession.GetSessionCrewCharacters(CharacterType.Player))
        MT.HF.BlankTerminalLines(terminal, 1, "")
        terminal.SendMessage("Please select an option:")
        for k, v in pairs(Character.CharacterList) do
            terminal.SendMessage("(" .. v.ID .. ") " .. v.name)
        end
    MT.C.pBankFooter(item, terminal, size.displayWCH)

    -- EXIT: to main menu
    elseif string.lower(response) == "exit" or string.lower(response) == "cancel" then
        mtc.WaitingFunction = "MT.C.pBank"
        MT.C.pBank(item, terminal, mtc, nil, size)
    -- VALIDATION: is the response a number?
    elseif not tonumber(response) then
        terminal.SendMessage("!INVALID RESPONSE!", Color(250,100,60,255))
        Timer.Wait(function() MT.C.pBankChangeSuccessor(item, terminal, mtc, nil, size) end, 1500)
    -- VALIDATION: is the response a valid entity?
    elseif Entity.FindEntityByID(tonumber(response)) then
        -- VALIDATION: entity is a character, proceed with assignment
        if LuaUserData.IsTargetType(Entity.FindEntityByID(tonumber(response)), "Barotrauma.Character") then
            local successor = Entity.FindEntityByID(tonumber(response))
            profile.successorID = tostring(successor.ID)
            profile.successorName = successor.name
            MT.C.pBankHeader(item, terminal, size.displayWCH)
            terminal.SendMessage("You have successfully assigned " .. successor.name .. " as your successor.")
            terminal.SendMessage("returning to main menu...", Color.Gray)
            MT.C.pBankFooter(item, terminal, size.displayWCH)
            Timer.Wait(function() MT.C.pBank(item, terminal, mtc, nil, size) end, 2500)
        -- VALIDATION: entitiy is not a character, return to initial display
        else
            terminal.SendMessage("!INVALID RESPONSE! " .. Entity.FindEntityByID(tonumber(response)).name .. "is not an appropriate successor.", Color(250,100,60,255))
            Timer.Wait(function() MT.C.pBankChangeSuccessor(item, terminal, mtc, nil, size) end, 2500)
        end
    -- VALIDATION: unknown response is not valid
    else
        terminal.SendMessage("!INVALID RESPONSE!", Color(250,100,60,255))
        Timer.Wait(function() MT.C.pBankChangeSuccessor(item, terminal, mtc, response, size) end, 1500)
    end
end

-- -------------------------------------------------------------------------- --
--                          pBANK DISLPAY COMPONENETS                         --
-- -------------------------------------------------------------------------- --
function MT.C.pBankHeader(item, terminal, displayWCH)
    local profile = MT.CLI.getProfile(item)
    local time = MT.HF.Round(Game.GameScreen.GameTime, 2)
    local timeLength = string.len(tostring(time))
    local account = profile.registeredID
    local accountLength = string.len(tostring(account))
    -- head
    terminal.ClearHistory()
    if displayWCH > 30 then
      terminal.SendMessage(string.rep("_", displayWCH))
      terminal.SendMessage("@" .. tostring(item) .. string.rep(" ", displayWCH - string.len(tostring(item)) - 14 ) ..  " | P. F. Bank")
      terminal.SendMessage("ClockTime: " .. time .. "T" .. string.rep(" ", displayWCH - timeLength - accountLength - 17) .. "ACC# " .. account)
    else
      terminal.SendMessage("@" .. tostring(item))
      terminal.SendMessage("ClockTime: " .. time .. "T")
      terminal.SendMessage("P. F. Bank | ACC# " .. account)
    end

    --/head
end

function MT.C.pBankFooter(item, terminal, displayWCH)
    -- foot
    --MT.HF.BlankTerminalLines(terminal, 1, "")
    terminal.SendMessage(string.rep("_", displayWCH))
    -- /foot
end