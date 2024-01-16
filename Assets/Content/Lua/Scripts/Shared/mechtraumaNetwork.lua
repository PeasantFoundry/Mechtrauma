
-- -------------------------------------------------------------------------- --
--                                   NETWORK                                  --
-- -------------------------------------------------------------------------- --
-- vanilla bt: IReadMessage.cs and IWriteMessage.cs
-- IReadMessage functions:

--bool ReadBoolean();
--void ReadPadBits();
--byte ReadByte();
--byte PeekByte();
--UInt16 ReadUInt16();
--Int16 ReadInt16();
--UInt32 ReadUInt32();
--Int32 ReadInt32();
--UInt64 ReadUInt64();
--Int64 ReadInt64();
--Single ReadSingle();
--Double ReadDouble();
--UInt32 ReadVariableUInt32();
--String ReadString();
--Identifier ReadIdentifier();
--Microsoft.Xna.Framework.Color ReadColorR8G8B8();
--Microsoft.Xna.Framework.Color ReadColorR8G8B8A8();
--int ReadRangedInteger(int min, int max);
--Single ReadRangedSingle(Single min, Single max, int bitCount);
--byte[] ReadBytes(int numberOfBytes);

--Hook.Add("mtMoblie_readTags.OnUse", "MT.moblie", function(effect, deltaTime, item, targets, worldPosition, client) end)

Hook.Add("Mechtrauma.LuaNetEventDispatcher::ServerRead", "MT.Net.SR", function(component, message, client)
    print("WE MADE IT TO SR")
    print(tostring(component))
    print(tostring(message))
    print(tostring(client))
    if component.Name == "DieselEngine" then
        local generator = MTUtils.GetComponentByName(component.item, "Mechtrauma.SimpleGenerator")
        local dieselEngine = MTUtils.GetComponentByName(component.item, "Mechtrauma.DieselEngine")
        generator.DiagnosticMode = message.ReadBoolean()
        generator.IsOn = message.ReadBoolean()
        generator.PowerToGenerate = message.ReadSingle()
        dieselEngine.DiagnosticMode = message.ReadBoolean()
        dieselEngine.ShowStatus = message.ReadBoolean()
        dieselEngine.ShowLevels = message.ReadBoolean()
        dieselEngine.ShowTemps = message.ReadBoolean()
        component.SendEvent()
    end
end)

Hook.Add("Mechtrauma.LuaNetEventDispatcher::ServerWrite", "MT.Net.SW", function(component, message, client, extradata)
    print("WE MADE IT TO SW")
    if component.Name == "DieselEngine" then
    
        local generator = MTUtils.GetComponentByName(component.item, "Mechtrauma.SimpleGenerator")
        local dieselEngine = MTUtils.GetComponentByName(component.item, "Mechtrauma.DieselEngine")
        message.WriteBoolean(generator.DiagnosticMode)
        message.WriteBoolean(generator.IsOn)
        message.WriteSingle(generator.PowerToGenerate)
        message.WriteBoolean(dieselEngine.DiagnosticMode)
        message.WriteBoolean(dieselEngine.ShowStatus)
        message.WriteBoolean(dieselEngine.ShowLevels)
        message.WriteBoolean(dieselEngine.ShowTemps)
    end

end)

Hook.Add("Mechtrauma.LuaNetEventDispatcher::ClientRead", "MT.Net.CR", function(component, message, sendingTime)
    print("WE MADE IT TO CR")
    if component.Name == "DieselEngine" then
    
        local generator = MTUtils.GetComponentByName(component.item, "Mechtrauma.SimpleGenerator")
        local dieselEngine = MTUtils.GetComponentByName(component.item, "Mechtrauma.DieselEngine")
        generator.DiagnosticMode = message.ReadBoolean()
        generator.IsOn = message.ReadBoolean()
        generator.PowerToGenerate = message.ReadSingle()
        dieselEngine.DiagnosticMode = message.ReadBoolean()
        dieselEngine.ShowStatus = message.ReadBoolean()
        dieselEngine.ShowLevels = message.ReadBoolean()
        dieselEngine.ShowTemps = message.ReadBoolean()
    end
end)

Hook.Add("Mechtrauma.LuaNetEventDispatcher::ClientWrite", "MT.Net.CW", function(component, message, extradata)
    print("WE MADE IT TO CW")    
    print("name: " .. tostring(component.name))
    if component.Name == "DieselEngine" then
    
        local generator = MTUtils.GetComponentByName(component.item, "Mechtrauma.SimpleGenerator")
        local dieselEngine = MTUtils.GetComponentByName(component.item, "Mechtrauma.DieselEngine")
        message.WriteBoolean(generator.DiagnosticMode)
        message.WriteBoolean(generator.IsOn)
        message.WriteSingle(generator.PowerToGenerate)
        message.WriteBoolean(dieselEngine.DiagnosticMode)
        message.WriteBoolean(dieselEngine.ShowStatus)
        message.WriteBoolean(dieselEngine.ShowLevels)
        message.WriteBoolean(dieselEngine.ShowTemps)
    end
end)
