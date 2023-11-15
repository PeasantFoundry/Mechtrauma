MT = {} -- Mechtrauma
BT = {} -- Biotrauma


MT.Name="Mechtrauma"
MT.Version = "1.2.0"
MT.VersionNum = 01020000 -- seperated into groups of two digits: 01020304 -> 1.2.3h4; major, minor, patch, hotfix
MT.Path = table.pack(...)[1]

-- register mechtrauma as a neurotrauma "expansion"
MT.MinNTVersion = "A1.8.1"
MT.MinNTVersionNum = 01080100
Timer.Wait(function() if NTC ~= nil and NTC.RegisterExpansion ~= nil then NTC.RegisterExpansion(MT) end end,1)

MT.Config = MTConfig;

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

-- SHARED: client/server code

-- functions
dofile(MT.Path.."/Lua/Scripts/Shared/helperFunctions.lua")
dofile(MT.Path.."/Lua/Scripts/Shared/biotraumaFunctions.lua")
dofile(MT.Path.."/Lua/Scripts/Shared/mechtraumaFunctions.lua")

-- SHARED: client/server code
dofile(MT.Path.."/Lua/Scripts/Shared/mechtraumaPower.lua")


-- SERVER: server-side code (also run in singleplayer)
if (Game.IsMultiplayer and SERVER) or not Game.IsMultiplayer then

    -- Version and expansion display
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

    -- this is where we run all the other lua files    
    dofile(MT.Path.."/Lua/Scripts/Server/treatmentItems.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/mechtrauma.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/biotrauma.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/updateCounter.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/updateItems.lua")
    dofile(MT.Path.."/Lua/Scripts/Server/updateHumans.lua")
    dofile(MT.Path.."/Lua/Scripts/testing.lua")
end

-- CLIENT: side-code
if CLIENT then
    --dofile(MT.Path.."/Lua/Scripts/Client/csluacheck.lua")
end

-- PERFORMANCE FIX:
Hook.Add("roundStart", "MT.roundStart", function()
    -- DO NOT REMOVE - corrects power grid desyncs from the performance fix mod
    Game.poweredUpdateInterval = 1    
end)
