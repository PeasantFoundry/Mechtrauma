
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

 -- -------------------------------------------------------------------------- --
 --                      Writing Messages - IWriteMessage                      --
 -- -------------------------------------------------------------------------- --

--[[ void WriteBoolean(bool val);
void WritePadBits();
void WriteByte(byte val);
void WriteInt16(Int16 val);
void WriteUInt16(UInt16 val);
void WriteInt32(Int32 val); // <== whole numbers
void WriteUInt32(UInt32 val);
void WriteInt64(Int64 val);
void WriteUInt64(UInt64 val);
void WriteSingle(Single val); // <== decimal places
void WriteDouble(Double val);
void WriteColorR8G8B8(Microsoft.Xna.Framework.Color val); // Color as RGB
void WriteColorR8G8B8A8(Microsoft.Xna.Framework.Color val); // Color as RGBA
void WriteVariableUInt32(UInt32 val);
void WriteString(string val); // text
void WriteIdentifier(Identifier val);
void WriteRangedInteger(int val, int min, int max);
void WriteRangedSingle(Single val, Single min, Single max, int bitCount);
void WriteBytes(byte[] val, int startIndex, int length); ]]


Hook.Add("Mechtrauma.LuaNetEventDispatcher::ServerRead", "MT.Net.SR", function(component, message, client)
    -- --------------------------- SERVER READ EVENTS --------------------------- --
    -- debug printing: print("WE MADE IT TO SR")
    if component.Name == "DieselEngine" then
        local generator = MTUtils.GetComponentByName(component.item, "Mechtrauma.SimpleGenerator")
        local dieselEngine = MTUtils.GetComponentByName(component.item, "Mechtrauma.DieselEngine")
        generator.IsOn = message.ReadBoolean()
        generator.PowerToGenerate = message.ReadSingle()
        component.SendEvent()

    elseif component.Name == "MTC" then
        local cliCommand = message.ReadString()
        local width = message.ReadInt32()
        local height = message.ReadInt32()
        local terminal = MTUtils.GetComponentByName(component.item, "Mechtrauma.AdvancedTerminal")
        local mtc = MTUtils.GetComponentByName(component.item, "Mechtrauma.MTC")

        --if not terminal.MessagesHistory.Count then return end -- nil check
        --local lastMessage = terminal.MessagesHistory[terminal.MessagesHistory.Count-0]

        -- -------- THIS WONT WORK FOR MULTIPLE TERMINAL COMPONENTS - RIGHT? -------- --
        --[[if terminal then
        component.SendEvent()]]
        -- ok this is getting messy, I take it back. I do want multiple dispatcher components per item
        if terminal and message ~= nil then
            MT.CLI.terminalCommand(terminal.item, terminal, mtc, cliCommand, width, height)
        end
    end
end)

Hook.Add("Mechtrauma.LuaNetEventDispatcher::ServerWrite", "MT.Net.SW", function(component, message, client, extradata)
    -- --------------------------- SERVER WRITE EVENTS -------------------------- --
     -- debug printing: print("WE MADE IT TO CR")
    -- possibly depricated
    if component.Name == "DieselEngine" then
        local generator = MTUtils.GetComponentByName(component.item, "Mechtrauma.SimpleGenerator")
        local dieselEngine = MTUtils.GetComponentByName(component.item, "Mechtrauma.DieselEngine")
        message.WriteBoolean(generator.IsOn)
        message.WriteSingle(generator.PowerToGenerate)
        --[[
            elseif component.Name == "MTC" then
            local terminal = MTUtils.GetComponentByName(component.item, "Mechtrauma.AdvancedTerminal")
            local mtc = MTUtils.GetComponentByName(component.item, "Mechtrauma.MTC")
        ]]
    end

end)

Hook.Add("Mechtrauma.LuaNetEventDispatcher::ClientRead", "MT.Net.CR", function(component, message, sendingTime)
    -- --------------------------- CLIENT READ EVENTS --------------------------- --
    -- debug printing: print("WE MADE IT TO CR")

    -- possibly depricated
    if component.Name == "DieselEngine" then

        local generator = MTUtils.GetComponentByName(component.item, "Mechtrauma.SimpleGenerator")
        local dieselEngine = MTUtils.GetComponentByName(component.item, "Mechtrauma.DieselEngine")
        generator.IsOn = message.ReadBoolean()
        generator.PowerToGenerate = message.ReadSingle()
        --[[
            elseif component.Name == "MTC" then
            local terminal = MTUtils.GetComponentByName(component.item, "Mechtrauma.AdvancedTerminal")
            local mtc = MTUtils.GetComponentByName(component.item, "Mechtrauma.MTC")
        ]]

    end
end)

Hook.Add("Mechtrauma.LuaNetEventDispatcher::ClientWrite", "MT.Net.CW", function(component, message, extradata)
    -- --------------------------- CLIENT WRITE EVENTS -------------------------- --
    --print("WE MADE IT TO CW")

        -- ----------------------- MTC TERMINAL COMMAND CACHE ----------------------- --
    -- player terminal commands are cached by the Mechtrauma.AdvancedTerminal::NewPlayerMessage hook
    -- the lua event dispatcher then syncs the cached command to the server for execution
    if component.Name == "MTC" then
        local terminal = MTUtils.GetComponentByName(component.item, "Mechtrauma.AdvancedTerminal")
        message.WriteString(MT.commandCache.message[component.item.ID])
        message.WriteInt32(MT.commandCache.width[component.item.ID])
        message.WriteInt32(MT.commandCache.height[component.item.ID])
    -- possibly deprecated
    elseif component.Name == "DieselEngine" then
        local generator = MTUtils.GetComponentByName(component.item, "Mechtrauma.SimpleGenerator")
        local dieselEngine = MTUtils.GetComponentByName(component.item, "Mechtrauma.DieselEngine")
        message.WriteBoolean(generator.IsOn)
        message.WriteSingle(generator.PowerToGenerate)
    end
end)
