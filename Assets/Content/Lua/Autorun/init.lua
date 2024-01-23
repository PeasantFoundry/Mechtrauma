-- -------------------------------------------------------------------------- --
--                          MECHTRAUMA INITIALIZATION                         --
-- -------------------------------------------------------------------------- --
MT = {} -- Mechtrauma
BT = {} -- Biotrauma

MT.Name="Mechtrauma"
MT.Version = "1.3.2.4 UNSTABLE"
MT.VersionNum = 01020000 -- seperated into groups of two digits: 01020304 -> 1.2.3h4; major, minor, patch, hotfix
MT.Path = table.pack(...)[1]
MT.M = {} -- Mechtrauma modules

-- register mechtrauma as a neurotrauma "expansion"
MT.MinNTVersion = "A1.8.1"
MT.MinNTVersionNum = 01080100
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(MT) end end,1)

MT.Config = MTConfig; -- load the moddingtoolkit config


-- ------------- ADD CONSOLE COMMAND: reload mechtrauma modules ------------- --
-- function Game.AddCommand(name, help, onExecute, getValidArgs, isCheat) end
Game.AddCommand("mtreload", "reload mt lua", function ()
    if (Game.IsMultiplayer and CLIENT) then return end
    -- reload the shared modules
    for k, v in pairs(MT.M.Shared) do
        print("Re-Loading module:", k, v)
        MT.loadModule(v)
    end

    -- reload the server modules
    for k, v in pairs(MT.M.Server) do
        print("Re-Loading module:", k, v)
        MT.loadModule(v)
    end
end)

-- ---------------------- FUNCTION: reload lua modules ---------------------- --
function MT.loadModule(filename)
     -- purge the loaded module (if any)
    package.loaded[filename] = nil
     -- attempt to load the module
    local success, result = pcall(dofile, filename)
    -- ERROR HANDLING
    if not success then
        printerror("ERROR: Failed loading Mechtrauma module: ", filename)
        printerror(result)
    end
    return result
end

-- -------------------------------------------------------------------------- --
--                                  [CLIENT]                                  --
-- -------------------------------------------------------------------------- --
-- client only

if CLIENT then
    dofile(MT.Path.."/Lua/Scripts/Client/mt_client.lua")
end

-- -------------------------------------------------------------------------- --
--                                  [SHARED]                                  --
-- -------------------------------------------------------------------------- --
-- client/server



MT.M.Shared = {
    -- MTC modules
    helperFunctions = MT.Path .. "/Lua/Scripts/Shared/helperFunctions.lua",
    mechtraumaFunctions = MT.Path .. "/Lua/Scripts/Shared/mechtraumaFunctions.lua",
    mechtraumaNetwork = MT.Path .. "/Lua/Scripts/Shared/mechtraumaNetwork.lua",
    mechtraumaTools = MT.Path .. "/Lua/Scripts/Shared/mechtraumaTools.lua"
}

-- -------------------------- LOAD: shared modules -------------------------- --
for k, v in pairs(MT.M.Shared) do
    print("Loading module:", k, v)
    MT.loadModule(v)
end

--[[ functions
dofile(MT.Path.."/Lua/Scripts/Shared/helperFunctions.lua")
dofile(MT.Path.."/Lua/Scripts/Shared/mechtraumaFunctions.lua")
dofile(MT.Path.."/Lua/Scripts/Shared/mechtraumaNetwork.lua")
dofile(MT.Path.."/Lua/Scripts/Shared/mechtraumaTools.lua")]]

-- -------------------------------------------------------------------------- --
--                                  [SERVER]                                  --
-- -------------------------------------------------------------------------- --
-- server only

-- server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then


    -- (currently not stored as a module because it stores dynamic data that I don't generally want to reload)
    -- ((i'll add an argument to the console command later for this))
    -- ------------------------ LOAD: server data tables ------------------------ --
    dofile(MT.Path.."/Lua/Scripts/Server/mt_dataTables.lua")

    -- ----------------- DISPLAY: Version and expansion details ----------------- --
    Timer.Wait(function() Timer.Wait(function()
        local runstring = "\n/// Running Mechtrauma V "..MT.Version.." ///\n"

        -- add dashes
        local linelength = string.len(runstring)+4
        local i = 0
        while i < linelength do runstring=runstring.."-" i=i+1 end

        -- if you were to ever create mechtrauma expansions then here would be the place
        -- to print them out alongside the mechtrauma version

        print(runstring)
    end,1) end,1)

    -- -------------------------------------------------------------------------- --
    --                              LUA SERVER FILES                              --
    -- -------------------------------------------------------------------------- --
    MT.M.Server = {
        -- MTC modules
        mechtraumaComputers = MT.Path .. "/Lua/Scripts/Server/MTC/mechtraumaComputers.lua",
        mechtraumaCLI = MT.Path .. "/Lua/Scripts/Server/MTC/mechtraumaCLI.lua",
        mtpBank = MT.Path .. "/Lua/Scripts/Server/MTC/mt_pBank.lua",
        -- MT modules
        mechtraumaDiesel = MT.Path .. "/Lua/Scripts/Server/mechtraumaDiesel.lua",
        mechtraumaPower = MT.Path .. "/Lua/Scripts/Server/mechtraumaPower.lua",
        mechtrauma = MT.Path .. "/Lua/Scripts/Server/mechtrauma.lua",
        -- MTM modules (mt medical)
        treatmentItems = MT.Path .. "/Lua/Scripts/Server/treatmentItems.lua",
        -- BT modules
        biotrauma = MT.Path .. "/Lua/Scripts/Server/BT/biotrauma.lua",
        biotraumaFunctions = MT.Path.."/Lua/Scripts/Server/BT/biotraumaFunctions.lua",
        -- MTU modules
        itemUpdaterFunctions = MT.Path .. "/Lua/Scripts/Server/MTU/itemUpdaterFunctions.lua",
        itemUpdater = MT.Path .. "/Lua/Scripts/Server/MTU/itemUpdater.lua",
        updateHumans = MT.Path .. "/Lua/Scripts/Server/MTU/updateHumans.lua",
        updateCounter = MT.Path .. "/Lua/Scripts/Server/MTU/updateCounter.lua",
        --testing = MT.Path .. "/Lua/Scripts/testing.lua"
    }

    -- -------------------------- LOAD: server modules -------------------------- --
    for k, v in pairs(MT.M.Server) do
        print("Loading module:", k, v)
        MT.loadModule(v)
    end
end

-- PERFORMANCE FIX:
Hook.Add("roundStart", "MT.roundStart", function()
    -- DO NOT REMOVE - corrects power grid desyncs from the performance fix mod
    Game.poweredUpdateInterval = 1
end)




-- -------------------------------------------------------------------------- --
--                              SCRAPS AND LEGACY                             --
-- -------------------------------------------------------------------------- --

--[[-- config loading
if not File.Exists(MT.Path .. "/config.json") then

    -- create default config if there is no config file
    --MT.Config = dofile(MT.Path .. "/Lua/defaultconfig.lua")
    --File.Write(MT.Path .. "/config.json", json.serialize(MT.Config))

else

    -- load existing config
    MT.Config = json.parse(File.Read(MT.Path .. "/config.json"))

    -- add missing entries
    local defaultConfig = dofile(MT.Path .. "/Lua/defaultconfig.lua")
    for key, value in pairs(defaultConfig) do
        if MT.Config[key] == nil then
            MT.Config[key] = value
        end
    end
end]]



--dofile(MT.Path.."/Lua/Scripts/Server/updateCounter.lua")
--dofile(MT.Path.."/Lua/Scripts/Server/updateItems.lua")
--dofile(MT.Path.."/Lua/Scripts/Server/updateHumans.lua")
--dofile(MT.Path.."/Lua/Scripts/testing.lua")

--[[
    dofile(MT.Path.."/Lua/Scripts/Server/MTC/mechtraumaComputers.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/MTC/mechtraumaCLI.lua")
    MT.loadModule(MT.Path.."/Lua/Scripts/Server/MTC/mt_pBank.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/mechtraumaUpdateFunctions.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/mechtraumaDiesel.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/mechtraumaPower.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/treatmentItems.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/mechtrauma.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/biotrauma.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/updateCounter.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/updateItems.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/updateHumans.lua")
    dofile(MT.Path.."/Lua/Scripts/testing.lua")
]]