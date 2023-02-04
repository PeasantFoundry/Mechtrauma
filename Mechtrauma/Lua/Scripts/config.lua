-- Availability: CLIENT AND SERVER
-- Simplest verion
local mySimpleVar = ConfigManager.AddConfigBool(
    "MyVarName1",   -- [REQUIRED] Variable name
    "Mechtrauma",    -- [REQUIRED] Mod name, used for the config file name.
    false           -- [REQUIRED] Default value.
)

-- Set your value
mySimpleVar.Value = true

-- Access your value
print(mySimpleVar.Value)

-- Save your value to file/disk
ModdingToolkit.Config.ConfigManager.Save(mySimpleVar)

-- Want to access it somewhere else?
local myVar2 = ModdingToolkit.Config.ConfigManager.GetConfigMember("MyModName","MyVarName1")