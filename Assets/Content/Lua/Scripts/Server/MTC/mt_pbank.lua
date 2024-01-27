-- -------------------------------------------------------------------------- --
--                      WELCOME TO PEASANT FINANCIAL BANK                     --
-- -------------------------------------------------------------------------- --

function MT.C.pBankWelcome(item, terminal, mtc, response, command, argument, size)
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

function MT.C.pBank(item, terminal, mtc, response, command, argument, size)
  -- some pBank color
    terminal.TextColor = Color(50,200,75,255)

    -- ----------------- ACCOUNT DETAILS: owner, profile, pbank ----------------- --
    local profile = MT.CLI.getProfile(item)
    if not profile then terminal.SendMessage("You must register this device to use pBank.") mtc.IsWaiting = false return end
    local owner = Entity.FindEntityByID(tonumber(profile.registeredID)) -- this needs to be changed to the player accessing the terminal...
    local pbank = MT.C.getpBank(item)



    -- VALIDATION: if no pbank account, make one
    -- need to add an auto generated account number
    if not pbank.balance then
      -- create a pbank balance
      pbank["balance"] = 0
      pbank["transactions"] = {}


    end

    --Character.Wallet.Balance

    -- claim the waiting function
    mtc.IsWaiting = true
    mtc.WaitingFunction = "MT.C.pBank"

    if response == nil or response == "" then --
      if not Game.IsMultiplayer then terminal.SendMessage("pBank balance is not available in singleplayer.", Color(200,100,50,255)) mtc.IsWaiting = false return end
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
      MT.C.pBankBalance(item, terminal, mtc, nil, nil, nil, size)

    elseif response == "2" then
      MT.C.pBankDeposit(item, terminal, mtc, nil, profile, owner, size)
    elseif response == "3" then
      terminal.SendMessage("Who would you like to transfer funds to?")
      --mtc.IsWaiting = true
      --mtc.WaitingFunction = "MT.C.pBank"
    elseif response == "4" then
      MT.C.pBankTransactions(item, terminal, mtc, nil, nil, nil, size)
    elseif response == "5" then
      terminal.SendMessage("Your current investments are as follows:")
      --mtc.IsWaiting = true
      --mtc.WaitingFunction = "MT.C.pBank"
    elseif response == "6" then
        terminal.SendMessage("Your current loans are as follows:")
        --mtc.IsWaiting = true
        --mtc.WaitingFunction = "MT.C.pBank"
    elseif response == "7" then
      MT.C.pBankSuccessor(item, terminal, mtc, nil, nil, nil, size)
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




  -- -------------------------------------------------------------------------- --
  --                            pBANK MENU FUNCTIONS                            --
  -- -------------------------------------------------------------------------- --


  -- -------------------------------- 1 Balance ------------------------------- --
  function MT.C.pBankBalance(item, terminal, mtc, response, command, argument, size)
    -- claim the waiting function
    mtc.IsWaiting = true
    mtc.WaitingFunction = "MT.C.pBankBalance"
    -- get profile an owner
    local profile = MT.CLI.getProfile(item)
    local pbank = MT.C.getpBank(item)
    local owner = Entity.FindEntityByID(tonumber(profile.registeredID))
    --// header
    MT.C.pBankHeader(item, terminal, size.displayWCH)
    --// body
    -- default behavior
    if response == nil or response == "" then
      --// sub-header
      MT.C.pBankSubHeader(terminal, size.displayWCH, "BALANCE")
      --terminal.SendMessage("BALANCE" .. string.rep("-", size.displayWCH - 7))
      terminal.SendMessage("Your current pBank balance is: $" .. tostring(pbank.balance))
      terminal.SendMessage("There is $" .. tostring(owner.Wallet.Balance) .. " in your wallet.")
      terminal.SendMessage("(press any key to return to the main menu)", Color.Gray)
      mtc.IsWaiting = true
      mtc.WaitingFunction = "MT.C.pBank"
    end
  end

  -- -------------------------------- 2 Deposit ------------------------------- --
  function MT.C.pBankDeposit(item, terminal, mtc, response, profile, owner, size)
    -- claim the waiting function
    mtc.IsWaiting = true
    mtc.WaitingFunction = "MT.C.pBankDeposit"
    -- get profile an owner
    local profile = MT.CLI.getProfile(item)
    local pbank = MT.C.getpBank(item)
    local owner = Entity.FindEntityByID(tonumber(profile.registeredID))
    --// header
    MT.C.pBankHeader(item, terminal, size.displayWCH)
    --// body

    -- muliplayer check (wallet balance errors in single player mode)
    if not Game.IsMultiplayer then
      terminal.SendMessage("ERROR: Wallet unavailable in singleplayer.")
      terminal.SendMessage("(press any key to return to the main menu)", Color.Gray)
      mtc.IsWaiting = true
      mtc.WaitingFunction = "MT.C.pBank"
      return
    end

    -- default behavior
    if response == nil or response == "" then
      MT.C.pBankSubHeader(terminal, size.displayWCH, "DEPOSIT")
      terminal.SendMessage("Your current wallet balance is: $" .. tostring(owner.Wallet.Balance))
      terminal.SendMessage("How much would you like to deposit to your pBank account?")
    else
      -- return to main menu
      if response == "exit" or response == "cancel" then
        terminal.SendMessage("Transaction cancelled.")
        MT.C.pBank(item, terminal, mtc, nil, nil, nil, size)

      -- VALIDATION: a number was not found in the response
      elseif not MT.HF.extractNumber(response) then
        MT.C.pBankSubHeader(terminal, size.displayWCH, "DEPOSIT")
        terminal.SendMessage("!INVALID RESPONSE!", Color(250,100,60,255))
        terminal.SendMessage("(press any key to return to the main menu)", Color.Gray)
        mtc.WaitingFunction = "MT.C.pBank"

      -- VALIDATION: a number was found in the response
      elseif MT.HF.extractNumber(response) then
        local amount = tonumber(MT.HF.extractNumber(response))
        local newBalance = owner.Wallet.Balance - amount

        --// sub-header
        MT.C.pBankSubHeader(terminal, size.displayWCH, "DEPOSIT")

        -- VALIDATION: check for enough money in wallet
        if amount > owner.Wallet.Balance then
          terminal.SendMessage("You do not have enough money to deposit: $" .. amount .. " to your pBank account.")
          terminal.SendMessage("Your current wallet balance is: $" .. owner.Wallet.Balance)
          terminal.SendMessage("(press any key to return to the main menu)", Color.Gray)
          mtc.WaitingFunction = "MT.C.pBank"
          return
        end
        -- ------------ VALIDATION: check for transactions table in pbank ----------- --
        if not pbank.transactions then pbank.transactions = {} end

        -- ------------- EXECUTION: move the money from wallet to pBank ------------- --
        owner.Wallet.Balance = newBalance -- take money from wallet
        pbank.balance = pbank.balance + amount -- deposit money to pBank
        terminal.SendMessage("You have successfully deposited: $" .. MT.HF.extractNumber(response) .. " to your pBank account.")

        -- ----------------- EXECUTION: add deposit to transactions ----------------- --
        table.insert(pbank.transactions, {type="deposit", amount=amount, time=Game.GameScreen.GameTime, owner=owner.name})
        --owner.SetMoney(newBalance)
        terminal.SendMessage("Success! Your new balance is: $" .. owner.Wallet.Balance)
        terminal.SendMessage("(press any key to return to the main menu)", Color.Gray)
        mtc.WaitingFunction = "MT.C.pBank"

      -- failstate
      else
        terminal.SendMessage("!INVALID RESPONSE!", Color(250,100,60,255))
        terminal.SendMessage("(press any key to return to the main menu)", Color.Gray)
        mtc.WaitingFunction = "MT.C.pBank"
      end
    end
    --MT.HF.extractNumber(response)
  end
-- --------------------------- 4 View Transactions -------------------------- --
function MT.C.pBankTransactions(item, terminal, mtc, response, command, argument, size)
    -- claim the waiting function
    mtc.IsWaiting = true
    mtc.WaitingFunction = "MT.C.pBankTransactions"
    -- get profile and owner
    local profile = MT.CLI.getProfile(item)
    local pbank = MT.C.getpBank(item)
    local owner = Entity.FindEntityByID(tonumber(profile.registeredID))
    --// header
    MT.C.pBankHeader(item, terminal, size.displayWCH)
    --// body
    -- default behavior
        terminal.SendMessage("")
        terminal.SendMessage(string.format("%-3s", "#") .. string.format("%-7s", "TYPE") .. "   " .. string.format("%-7s", "AMOUNT") .. "   " .. string.format("%-7s", "TIME") .. "   " .. string.format("%-7s", "AUTH"))
        terminal.SendMessage(string.rep("-", size.displayWCH))
        for k, v in pairs(pbank.transactions) do
            terminal.SendMessage(string.format("%-3s", tostring(k)) .. string.format("%-7s", v.type) .. " . $" .. string.format("%-6s",v.amount) .. " . " .. string.format("%-7s", MT.HF.Round(v.time, 2)) .. " . " .. string.format("%-7s", v.owner))
        end
        terminal.SendMessage("(press any key to return to the main menu)", Color.Gray)
        mtc.WaitingFunction = "MT.C.pBank"
end
  -- ------------------------------- 7 Successor ------------------------------ --
function MT.C.pBankSuccessor(item, terminal, mtc, response, command, argument, size)
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
                terminal.SendMessage("(press any key to continue)", Color.Gray)
                mtc.WaitingFunction = "MT.C.pBank"
            elseif response == "2" or response == "no" then
                -- keep successor
                terminal.SendMessage(profile.successorName .. " will remian as your successor.")
                terminal.SendMessage("(press any key to continue)", Color.Gray)
                mtc.WaitingFunction = "MT.C.pBank"
            elseif response == "7" or response == "" or response == nil then
                -- do nothing
                return
            else
                terminal.SendMessage("!INVALID RESPONSE!", Color(250,100,60,255))
            end
        else
            -- if there is no successor, skip to assigning one
            MT.C.pBankChangeSuccessor(item, terminal, mtc, response, command, argument, size)
        end
end

-- -------------------------------------------------------------------------- --
--                            7.1 CHANGE SUCCESSOR                            --
-- -------------------------------------------------------------------------- --
function MT.C.pBankChangeSuccessor(item, terminal, mtc, response, command, argument, size)
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
        for _, character in pairs(Character.CharacterList) do
          if character.IsPlayer or character.IsOnPlayerTeam then
            terminal.SendMessage("(" .. character.ID .. ") " .. character.name)
          end
        end
    MT.C.pBankFooter(item, terminal, size.displayWCH)

    -- EXIT: to main menu
    elseif string.lower(response) == "exit" or string.lower(response) == "cancel" then
        mtc.WaitingFunction = "MT.C.pBank"
        MT.C.pBank(item, terminal, mtc, nil, nil, nil, size)
    -- VALIDATION: is the response a number?
    elseif not tonumber(response) then
        terminal.SendMessage("!INVALID RESPONSE!", Color(250,100,60,255))
        terminal.SendMessage("(press any key to continue)", Color.Gray)
        mtc.WaitingFunction = "MT.C.pBankChangeSuccessor"
    -- VALIDATION: is the response a valid entity?
    elseif Entity.FindEntityByID(tonumber(response)) then
        -- VALIDATION: entity is a character, proceed with assignment
        if LuaUserData.IsTargetType(Entity.FindEntityByID(tonumber(response)), "Barotrauma.Character") then
            local successor = Entity.FindEntityByID(tonumber(response))
            profile.successorID = tostring(successor.ID)
            profile.successorName = successor.name
            MT.C.pBankHeader(item, terminal, size.displayWCH)
            terminal.SendMessage("You have successfully assigned " .. successor.name .. " as your successor.")
            MT.C.pBankFooter(item, terminal, size.displayWCH)

            terminal.SendMessage("(press any key to continue)", Color.Gray)
            mtc.WaitingFunction = "MT.C.pBank"
        -- VALIDATION: entitiy is not a character, return to initial display
        else
            terminal.SendMessage("!INVALID RESPONSE! " .. Entity.FindEntityByID(tonumber(response)).name .. "is not an appropriate successor.", Color(250,100,60,255))
            terminal.SendMessage("(press any key to continue)", Color.Gray)
            mtc.WaitingFunction = "MT.C.pBankChangeSuccessor"
        end
    -- VALIDATION: unknown response is not valid
    else
        terminal.SendMessage("!INVALID RESPONSE!", Color(250,100,60,255))
        terminal.SendMessage("(press any key to continue)", Color.Gray)
        mtc.WaitingFunction = "MT.C.pBankChangeSuccessor"
    end
end

-- -------------------------------------------------------------------------- --
--                          pBANK DISLPAY COMPONENETS                         --
-- -------------------------------------------------------------------------- --

-- ----------------------------- HEADER DISPLAY ----------------------------- --
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


function MT.C.pBankSubHeader(terminal, displayWCH, subheader)
  --// subheader
  terminal.SendMessage(MT.CLI.textCenter(subheader, displayWCH, "-"))
end


function MT.C.pBankFooter(item, terminal, displayWCH)
    -- foot
    --MT.HF.BlankTerminalLines(terminal, 1, "")
    terminal.SendMessage(string.rep("_", displayWCH))
    -- /foot
end

-- -------------------------------------------------------------------------- --
--                           pBANK HELPER FUNCTIONS                           --
-- -------------------------------------------------------------------------- --

function MT.C.getpBank(item)
  -- VALIDATION: check for a user directory in root
  if not MT.C.HD[item].MTC.root.user then
    return nil -- no user directory in root
  else
    -- VALIDATION: check for a pbank.exe in the user directory
    if MT.C.HD[item].MTC.root.user.pbank then
      -- found it!
      return MT.C.HD[item].MTC.root.user.pbank
    else
      return nil -- no pbank.exe in user directory
    end
  end
end
