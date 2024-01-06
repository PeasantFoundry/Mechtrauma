
MT.HF = {} -- Helperfunctions (using HF instead of MT.HF might conflict with neurotraumas use of the term)
MT.Net = {}
-- LuaUserData.MakeFieldAccessible(Descriptors["Barotrauma.Items."], "isWire")
-- Mechtrauma exclusive functions:

--[[ split string by delimiter - need to figure out why this dosent work
function MT.HF.string:split( inSplitPattern, outResults )
    if not outResults then
      outResults = { }
    end
    local theStart = 1
    local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
    while theSplitStart do
      table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
    end
    table.insert( outResults, string.sub( self, theStart ) )
    return outResults
  end 
  --]]

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

function MT.Net.SendEvent(item)
  local LuaDispatcher = MTUtils.GetComponentByName(item, "Mechtrauma.LuaNetEventDispatcher")
  if LuaDispatcher ~= nil then
    LuaDispatcher.SendEvent()
  end
end

function MT.Net.ServerEventRead(component, message, client)
    if component.Name == "DieselGenerator" then
        local generator = MTUtils.GetComponentByName(component.item, "Mechtrauma.SimpleGenerator")        
        generator.DiagnosticMode = message.ReadBoolean()
        generator.IsOn = message.ReadBoolean()
        generator.PowerToGenerate = message.ReadSingle()
        component.SendEvent()
    end
end

function MT.Net.ServerEventWrite(component, message, client)
    if component.Name == "DieselGenerator" then        
        local generator = MTUtils.GetComponentByName(component.item, "Mechtrauma.SimpleGenerator")
        message.WriteBoolean(generator.DiagnosticMode)
        message.WriteBoolean(generator.IsOn)
        message.WriteSingle(generator.PowerToGenerate)

    end
end

function MT.Net.ClientEventRead(component, message, sendingTime)
    if component.Name == "DieselGenerator" then
        local generator = MTUtils.GetComponentByName(component.item, "Mechtrauma.SimpleGenerator")
        generator.DiagnosticMode = message.ReadBoolean()
        generator.IsOn = message.ReadBoolean()
        generator.PowerToGenerate = message.ReadSingle()
    end
end

function MT.Net.ClientEventWrite(component, message, extradata)
    if component.Name == "DieselGenerator" then
        local generator = MTUtils.GetComponentByName(component.item, "Mechtrauma.SimpleGenerator")
        message.WriteBoolean(generator.DiagnosticMode)
        message.WriteBoolean(generator.IsOn)
        message.WriteSingle(generator.PowerToGenerate)
    end
end

-- -------------------------------------------------------------------------- --
--                        this is going to get so full                        --
-- -------------------------------------------------------------------------- --

-- -------------------------------------------------------------------------- --
--                                QOL shortcuts                               --
-- -------------------------------------------------------------------------- --


-- -------------------------------------------------------------------------- --
--                                 FORMATTING                                 --
-- -------------------------------------------------------------------------- --

function MT.HF.formatNumber(n)
    return tostring(math.floor(n)):reverse():gsub("(%d%d%d)","%1,")
                                  :gsub(",(%-?)$","%1"):reverse()
  end

function MT.HF.setLength(inputString, length)
    local formattedString = string.format("%-" .. length .. "s", inputString)
    return formattedString:gsub(" ", ".")
end


-- -------------------------------------------------------------------------- --
--                                   PARSING                                  --
-- -------------------------------------------------------------------------- --

-- split string by delimiter
function MT.HF.Split(string, inSplitPattern, outResults )
    if not outResults then
      outResults = { }
    end
    local theStart = 1
    local theSplitStart, theSplitEnd = string.find( string, inSplitPattern, theStart )
    while theSplitStart do
      table.insert( outResults, string.sub( string, theStart, theSplitStart-1 ) )
      theStart = theSplitEnd + 1
      theSplitStart, theSplitEnd = string.find( string, inSplitPattern, theStart )
    end
    table.insert( outResults, string.sub( string, theStart ) )
    return outResults
  end


-- -------------------------------------------------------------------------- --
--                           MATHIMATICAL OPERATINS                           --
-- -------------------------------------------------------------------------- --

-- subtracts single amount from a list of items sequentially  
function MT.HF.subFromListSeq (amount, list)
    local targetedItems ={}
    for k, item in pairs(list) do
        if amount > item.Condition then
            amount = amount - item.Condition
            item.Condition = 0
            table.insert(targetedItems, item)
        else
            item.Condition = item.Condition - amount
            table.insert(targetedItems, item)
            amount = 0
            break
        end
    end
    return targetedItems -- should we only return if requested?
end

-- subtracts amount from list by dispursing/sharing it equally
function MT.HF.subFromListDis (amount, list)
    for k, item in pairs(list) do
        item.Condition = item.Condition - (amount / #list)        
    end
end

-- subtracts single amount from every item in a list
function MT.HF.subFromListAll (amount, list)
    for k, item in pairs(list) do
        item.Condition = item.Condition - amount
    end
end

-- general mathy functions:

function MT.HF.Lerp(a, b, t)
	return a + (b - a) * t
end

function MT.HF.Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- restricts an output to a range
function MT.HF.Clamp(num, min, max)
    if(num<min) then
        num = min 
    elseif(num>max) then 
        num = max 
    end
    return num
end

-- returns num if num > min, else defaultvalue
function MT.HF.Minimum(num, min, defaultvalue)
    if(num<min) then num=(defaultvalue or 0) end
    return num
end

-- -------------------------------------------------------------------------- --
--                                 PROBABILITY                                --
-- -------------------------------------------------------------------------- --
function MT.HF.Tolerance(tolerance)
    -- randomly select a modifier from a rage based on tolerance %. EX: 95% accuracy creates a range from -5 to 5 that becomes a .95 to 1.05 modifier
    local lowRange = (100 - tolerance) *-1
    local highRange = (100 - tolerance)
    local result = (math.random(lowRange,highRange) * 0.003 + 1)
    return result
end
-- % chance - math.random with no arguments return a random float between .1 and 1.0
function MT.HF.Chance(chance)
    return math.random() < chance
end

-- eventsTrue / totalEvents = probability ex: 1 in 1000 chance or a 7 in 51 chance or 1 in 18000 chance
function MT.HF.Probability( eventsTrue, totalEvents)
    return math.random(1,totalEvents) <= eventsTrue
end

-- Function to generate a weighted random index based on weights provided
function MT.HF.weightedRandom(weights)
    -- Calculate total weight
    local totalWeight = 0
    for _, weight in ipairs(weights) do
        totalWeight = totalWeight + weight
    end

    -- Generate a random number between 0 and totalWeight
    local randomValue = math.random() * totalWeight

    -- Find the index corresponding to the random value
    local currentIndex = 1
    local cumulativeWeight = weights[currentIndex]

    while randomValue > cumulativeWeight do
        currentIndex = currentIndex + 1
        cumulativeWeight = cumulativeWeight + weights[currentIndex]
    end

    return currentIndex
end

-- returns an unrounded random number
function MT.HF.RandomRange(min,max) 
    return min+math.random()*(max-min)
end

--[[-- Example usage
math.randomseed(os.time()) -- Seed the random number generator

local weights = {3, 1, 2, 4} -- Example weights
local selectedIndex = weightedRandom(weights)
print("Selected index:", selectedIndex)
]]

-- -------------------------------------------------------------------------- --
--                            BAROTRAUMA FUNCTIONS                            --
-- -------------------------------------------------------------------------- --
-- PhysObj depth and Nav Terminal "depth" are different. Nav Terminal includes the start depth of the level.
-- There isn't a level in the sub editor test, so for client side we will only use PhysObj depth.
function MT.HF.GetItemDepth(item)
  if SERVER then
    -- use server method
    return Level.Loaded.GetRealWorldDepth(item.WorldPosition.Y)
    else
    -- use client method
    return item.WorldPosition.Y * Physics.DisplayToRealWorldRatio
    end
end

  -- shouldn't this be depricated?
function MT.HF.findComponent(item, value)
for comp in item.Components do      
    if tostring(comp) == "Barotrauma.Items.Components." .. value then
    return comp 
    end
end
return nil
end

-- add function for removing useless lag causing items broken fuses,filters,emptycrates,
function MT.HF.MechtraumaClean()
    for k, item in pairs(Item.ItemList) do        
        local pickableComponent = MTUtils.GetComponentByName(item, ".Pickable") 
        if pickableComponent and pickableComponent.IsAttached == false and item.parentInventory == nil and not MTUtils.GetComponentByName(item, ".Wire") and item.container == nil and not item.HasTag("door") and not item.HasTag("ductblock") and item.ConditionPercentage < 1 then
            print("Item is cleanable: ", item)
            MT.HF.RemoveItem(item)
            print("REMOVED: ", item)

        end
    end
    print("CLEANUP COMPLETE")
end

-- print blank lines to terminal in place of a functioning clear command
function MT.HF.BlankTerminalLines(terminal, lines)
    local counter = 0
    while counter < lines do
        counter = counter + 1
        terminal.ShowMessage = "-"
    end
end

-- DEPRICATED: colored terminal message 
function MT.HF.SendTerminalColorMessage(item, terminal, color, message)
    local terminalOrgiginalColor = terminal.TextColor -- save the current terminal color
    local property = terminal.SerializableProperties[Identifier("TextColor")]
  
            terminal.TextColor = color
            if SERVER then Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(property, terminal)) end
   
            terminal.ShowMessage = message
            if SERVER then terminal.SyncHistory()  end
    --Timer.Wait(function() end,  10000) -- 100 = .1 second       
end

-- synce serialized property
-- be sure to pass property as a string 
function MT.HF.SyncToClient(property, target)
                Networking.CreateEntityEvent(target, Item.ChangePropertyEventData(target.SerializableProperties[Identifier(property)], target))
end


-- fucked by Hadrada on 11/12/22
-- unfucked by Mannatu on 11/13/22
function MT.HF.ItemIsWornInOuterClothesSlot(item)
    if item.ParentInventory == nil then return false end 
    if not LuaUserData.IsTargetType(item.ParentInventory, "Barotrauma.CharacterInventory") then return false end
    if item.ParentInventory.GetItemInLimbSlot(InvSlotType.OuterClothes) ~= item then return false end

  return true
  end


-- -------------------------------------------------------------------------- --
--                           TESTING AND VALIDATION                           --
-- -------------------------------------------------------------------------- --

--this is a testing function for damaging machines during a round 
function MT.HF.DamageFocusedItem(amount)
    local item = Client.ClientList[1].Character.FocusedItem
    item.condition = item.condition - amount
end

-- utility for checking there are missing items from the cache
function MT.HF.VerifyItemCache()
    print(" MT.itemCache BEFORE update: ", MT.itemCacheCount)
    -- flag the round as started    
        -- loop through the item list and find items for the cache
        for k, item in pairs(Item.ItemList) do  
           if item.HasTag("mtu") or (item.HasTag("diving") and item.HasTag("deepdiving")) then            
                if  MT.itemCache[item] then
                    print("Item Already Exists: ", item)
                else
                    print("Found a missing item: ", item, "adding it to the cache")                    
                     MT.itemCache[item] = true
                     MT.itemCache[item].counter = 0
                     MT.itemCacheCount =  MT.itemCacheCount + 1
                end
           end
       end
       print(" MT.itemCache AFTER update: ",  MT.itemCacheCount)
       
end


-- -------------------------------------------------------------------------- --
--                     Mechtrauma medical helper functions                    --
-- -------------------------------------------------------------------------- --

function MT.HF.Fibrillate(character,amount)
    -- tachycardia (increased heartrate) ->
    -- fibrillation (irregular heartbeat) ->
    -- cardiacarrest

    -- fetch values
    local tachycardia = MT.HF.GetAfflictionStrength(character,"tachycardia",0)
    local fibrillation = MT.HF.GetAfflictionStrength(character,"fibrillation",0)
    local cardiacarrest = MT.HF.GetAfflictionStrength(character,"cardiacarrest",0)

    -- already in cardiac arrest? don't do anything
    if cardiacarrest > 0 then return end

    -- determine total amount of fibrillation, then determine afflictions from that
    local previousAmount = tachycardia/5
    if fibrillation > 0 then previousAmount = fibrillation+20 end
    local newAmount = previousAmount + amount
  
    -- 0-20: 0-100% tachycardia
    -- 20-120: 0-100% fibrillation
    -- >120: cardiac arrest

    if newAmount < 20 then
        -- 0-20: 0-100% tachycardia
        tachycardia = newAmount*5
        fibrillation = 0
    elseif newAmount < 120 then
        -- 20-120: 0-100% fibrillation
        tachycardia = 0
        fibrillation = newAmount-20
    else
        -- >120: cardiac arrest
        tachycardia = 0
        fibrillation = 0
        MT.HF.SetAffliction(character,"cardiacarrest",10)
    end

    MT.HF.SetAffliction(character,"tachycardia",tachycardia)
    MT.HF.SetAffliction(character,"fibrillation",fibrillation)
    print("total current tachycardia: ", tachycardia)
    print("total current fibrillation: ", fibrillation)
end

-- -------------------------------------------------------------------------- --
--                    Neurotrauma complementary functions:                    --
-- -------------------------------------------------------------------------- --


-- /// affliction magic ///
-- i'm sure you'll have some use for these
------------------------------
function MT.HF.GetAfflictionStrength(character,identifier,defaultvalue)
    if character==nil or character.CharacterHealth==nil then return defaultvalue end

    local aff = character.CharacterHealth.GetAffliction(identifier)
    local res = defaultvalue or 0
    if(aff~=nil) then
        res = aff.Strength
    end
    return res
end

function MT.HF.GetAfflictionStrengthLimb(character,limbtype,identifier,defaultvalue)
    if character==nil or character.CharacterHealth==nil or character.AnimController==nil then return defaultvalue end
    local limb = character.AnimController.GetLimb(limbtype)
    if limb==nil then return defaultvalue end
    
    local aff = character.CharacterHealth.GetAffliction(identifier,limb)
    local res = defaultvalue or 0
    if(aff~=nil) then
        res = aff.Strength
    end
    return res
end

function MT.HF.HasAffliction(character,identifier,minamount)
    if character==nil or character.CharacterHealth==nil then return false end

    local aff = character.CharacterHealth.GetAffliction(identifier)
    local res = false
    if(aff~=nil) then
        res = aff.Strength >= (minamount or 0.5)
    end
    return res
end

function MT.HF.HasAfflictionLimb(character,identifier,limbtype,minamount)
    local limb = character.AnimController.GetLimb(limbtype)
    if limb==nil then return false end
    local aff = character.CharacterHealth.GetAffliction(identifier,limb)
    local res = false
    if(aff~=nil) then
        res = aff.Strength >= (minamount or 0.5)
    end
    return res
end

function MT.HF.SetAffliction(character,identifier,strength,aggressor,prevstrength)
    MT.HF.SetAfflictionLimb(character,identifier,LimbType.Torso,strength,aggressor,prevstrength)
end

-- the main "mess with afflictions" function
function MT.HF.SetAfflictionLimb(character,identifier,limbtype,strength,aggressor,prevstrength)
    local prefab = AfflictionPrefab.Prefabs[identifier]
    local resistance = character.CharacterHealth.GetResistance(prefab)
    if resistance >= 1 then return end

    local strength = strength*character.CharacterHealth.MaxVitality/100/(1-resistance)
    local affliction = prefab.Instantiate(
        strength
        ,aggressor)

    character.CharacterHealth.ApplyAffliction(character.AnimController.GetLimb(limbtype),affliction,false)
end
    -- turn target aggressive if damaging
--    if(aggressor ~= nil and character~=aggressor) then 
--        if prevstrength == nil then prevstrength = 0 end
--
--        local dmg = affliction.GetVitalityDecrease(character.CharacterHealth,strength-prevstrength)
--
--        if (dmg ~= nil and dmg > 0) then
--            MakeAggressive(aggressor,character,dmg)
--        end
--    end



function MT.HF.AddAfflictionLimb(character,identifier,limbtype,strength,aggressor)
    local prevstrength = MT.HF.GetAfflictionStrengthLimb(character,limbtype,identifier,0)
    MT.HF.SetAfflictionLimb(character,identifier,limbtype,
    strength+prevstrength,
    aggressor,prevstrength)
end

function MT.HF.AddAffliction(character,identifier,strength,aggressor)
    local prevstrength = MT.HF.GetAfflictionStrength(character,identifier,0)
    MT.HF.SetAffliction(character,identifier,
    strength+prevstrength,
    aggressor,prevstrength)
end

function MT.HF.AddAfflictionResisted(character,identifier,strength,aggressor)
    local prevstrength = MT.HF.GetAfflictionStrength(character,identifier,0)
    strength = strength * (1-MT.HF.GetResistance(character,identifier))
    MT.HF.SetAffliction(character,identifier,
    strength+prevstrength,
    aggressor,prevstrength)
end

function MT.HF.GetResistance(character,identifier)
    local prefab = AfflictionPrefab.Prefabs[identifier]
    if character == nil or character.CharacterHealth == nil or prefab==nil then return 0 end
    return character.CharacterHealth.GetResistance(prefab)
end

-- -------------------------------------------------------------------------- --
--                                /// misc ///                                --
-- -------------------------------------------------------------------------- --

function PrintChat(msg)
    if SERVER then
        -- use server method
        Game.SendMessage(msg, ChatMessageType.Server) 
    else
        -- use client method
        Game.ChatBox.AddMessage(ChatMessage.Create("", msg, ChatMessageType.Server, nil))
    end

end

function MT.HF.DMClient(client,msg,color)
    if SERVER then
        if(client==nil) then return end

        local chatMessage = ChatMessage.Create("", msg, ChatMessageType.Server, nil)
        if(color~=nil) then chatMessage.Color = color end
        Game.SendDirectChatMessage(chatMessage, client)
    else
        PrintChat(msg)
    end
end



function MT.HF.BoolToNum(val,trueoutput)
    if(val) then return trueoutput or 1 end
    return 0
end

function MT.HF.GetSkillLevel(character,skilltype)
    return character.GetSkillLevel(Identifier(skilltype))
end

function MT.HF.GetBaseSkillLevel(character,skilltype)
    if character == nil or character.Info == nil or character.Info.Job == nil then return 0 end
    return character.Info.Job.GetSkillLevel(Identifier(skilltype))
end

function MT.HF.GetSkillRequirementMet(character,skilltype,requiredamount)
    local skilllevel = MT.HF.GetSkillLevel(character,skilltype)
    return MT.HF.Chance(MT.HF.Clamp(skilllevel/requiredamount,0,1))
end

function MT.HF.GiveSkill(character,skilltype,amount)
    if character ~= nil and character.Info ~= nil then
        character.Info.IncreaseSkillLevel(Identifier(skilltype), amount)
    end
end

function MT.HF.GiveItem(character,identifier)
    if SERVER then
        -- use server spawn method
        Game.SpawnItem(identifier,character.WorldPosition,true,character)
    else
        -- use client spawn method
        character.Inventory.TryPutItem(Item(ItemPrefab.GetItemPrefab(identifier), character.WorldPosition), nil, {InvSlotType.Any})
    end
end

function MT.HF.GiveItemAtCondition(character,identifier,condition)
    if SERVER then
        -- use server spawn method
        local prefab = ItemPrefab.GetItemPrefab(identifier)
        Entity.Spawner.AddItemToSpawnQueue(prefab, character.WorldPosition, nil, nil, function(item)
            item.Condition = condition
            character.Inventory.TryPutItem(item, nil, {InvSlotType.Any})
        end)
    else
        -- use client spawn method
        local item = Item(ItemPrefab.GetItemPrefab(identifier), character.WorldPosition)
        item.Condition = condition
        character.Inventory.TryPutItem(item, nil, {InvSlotType.Any})
    end
end

-- for use with items
function MT.HF.SpawnItemPlusFunction(identifier,func,params,inventory,targetslot,position)
    local prefab = ItemPrefab.GetItemPrefab(identifier)
    if params == nil then params = {} end
    
    if SERVER then
        Entity.Spawner.AddItemToSpawnQueue(prefab, position or inventory.Container.Item.WorldPosition, nil, nil, function(newitem)
            if inventory~=nil then
                inventory.TryPutItem(newitem, targetslot,true,true,nil)
            end
            params["item"]=newitem
            if func ~= nil then func(params) end
        end)
    else
        local newitem = Item(prefab, position or inventory.Container.Item.WorldPosition)
        if inventory~=nil then
            inventory.TryPutItem(newitem, targetslot,true,true,nil)
        end
        params["item"]=newitem
        if func ~= nil then func(params) end
    end
end

-- for use with characters
function MT.HF.GiveItemPlusFunction(identifier,func,params,character)
    local prefab = ItemPrefab.GetItemPrefab(identifier)
    if params == nil then params = {} end
    
    if SERVER then
        Entity.Spawner.AddItemToSpawnQueue(prefab, character.WorldPosition, nil, nil, function(newitem)
            if character.Inventory~=nil then
                character.Inventory.TryPutItem(newitem, nil, {InvSlotType.Any})
            end
            params["item"]=newitem
            func(params)
        end)
    else
        local newitem = Item(prefab, character.WorldPosition)
        if character.Inventory~=nil then
            character.Inventory.TryPutItem(newitem, nil, {InvSlotType.Any})
        end
        params["item"]=newitem
        func(params)
    end
end

function MT.HF.SpawnItemAt(identifier,position)
    if SERVER then
        -- use server spawn method
        Game.SpawnItem(identifier,position,false,nil)
    else
        -- use client spawn method
        Item(ItemPrefab.GetItemPrefab(identifier), position)
    end
end

function MT.HF.RemoveItem(item)
    if item == nil or item.Removed then return end
    
    if SERVER then
        -- use server remove method
        Entity.Spawner.AddEntityToRemoveQueue(item)
    else
        -- use client remove method
        item.Remove()
    end
end

function MT.HF.StartsWith(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

function MT.HF.SplitString (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function MT.HF.HasAbilityFlag(character,flagtype)
    return character.HasAbilityFlag(flagtype)
end

function MT.HF.CharacterToClient(character)

    if not SERVER then return nil end

    for key,client in pairs(Client.ClientList) do
        if client.Character == character then 
            return client
        end
    end

    return nil
end

function MT.HF.ClientFromName(name)

    if not SERVER then return nil end

    for key,client in pairs(Client.ClientList) do
        if client.Name == name then 
            return client
        end
    end

    return nil
end

function MT.HF.GameIsPaused()
    if SERVER then return false end

    return Game.Paused
end

-- should be depricated, no?
--sadly, Game.RoundStarted does not work for singleplayer (sub editor)
function MT.HF.GameIsRunning()
    if SERVER then
            
        return Game.RoundStarted
    
    else
        
        if Game.Paused then return false end
        
        -- return true
        return Game.GameSession and Game.GameSession.IsRunning
    end
end

function MT.HF.TableContains(table, value)
    for i, v in ipairs(table) do
        if v == value then
            return true
        end
    end

    return false
end

function MT.HF.PutItemInsideItem(container,identifier,index)
    if index==nil then index = 0 end

    local inv = container.OwnInventory
    if inv == nil then return end

    local previtem = inv.GetItemAt(index)
    if previtem ~= nil then
        inv.ForceRemoveFromSlot(previtem, index)
        previtem.Drop()
    end

    Timer.Wait(function() 
        if SERVER then
            -- use server spawn method
            local prefab = ItemPrefab.GetItemPrefab(identifier)
            Entity.Spawner.AddItemToSpawnQueue(prefab, container.WorldPosition, nil, nil, function(item)
                inv.TryPutItem(item, nil, {index}, true, true)
            end)
        else
            -- use client spawn method
            local item = Item(ItemPrefab.GetItemPrefab(identifier), container.WorldPosition)
            inv.TryPutItem(item, nil, {index}, true, true)
        end
    end,
    10)
end

function MT.HF.HasTalent(character,talentidentifier) 

    local talents = character.Info.UnlockedTalents

    for value in talents do
        if value.Value == talentidentifier then return true end
    end

    return false
end

function MT.HF.CharacterDistance(char1,char2) 
    return MT.HF.Distance(char1.WorldPosition,char2.WorldPosition)
end

function MT.HF.Distance(v1,v2)
    return Vector2.Distance(v1,v2)
end

function MT.HF.GetOuterWearIdentifier(character) 
    return MT.HF.GetCharacterInventorySlotIdentifer(character,4)
end
function MT.HF.GetInnerWearIdentifier(character) 
    return MT.HF.GetCharacterInventorySlotIdentifer(character,3)
end
function MT.HF.GetHeadWearIdentifier(character) 
    return MT.HF.GetCharacterInventorySlotIdentifer(character,2)
end

function MT.HF.GetCharacterInventorySlotIdentifer(character,slot) 
    local item = character.Inventory.GetItemAt(slot)
    if item==nil then return nil end
    return item.Prefab.Identifier.Value
end

function MT.HF.GetItemInRightHand(character) 
    return MT.HF.GetCharacterInventorySlot(character,6)
end
function MT.HF.GetItemInLeftHand(character) 
    return MT.HF.GetCharacterInventorySlot(character,5)
end
function MT.HF.GetOuterWear(character) 
    return MT.HF.GetCharacterInventorySlot(character,4)
end
function MT.HF.GetInnerWear(character) 
    return MT.HF.GetCharacterInventorySlot(character,3)
end
function MT.HF.GetHeadWear(character) 
    return MT.HF.GetCharacterInventorySlot(character,2)
end

function MT.HF.GetCharacterInventorySlot(character,slot) 
    return character.Inventory.GetItemAt(slot)
end

-- WTF is this? - 1/2/2024
function MT.HF.ItemHasTag(item,tag)
    if item==nil then return false end
    return item.HasTag(tag)
end

function MT.HF.CombineArrays(arr1,arr2)
    local res = {}
    for _,v in ipairs(arr1) do
        table.insert(res, v) end
    for _,v in ipairs(arr2) do
        table.insert(res, v) end
    return res
end

function MT.HF.SendTextBox(header,msg,client)
    if SERVER then
        Game.SendDirectChatMessage(header, msg, nil, 7, client)
    else
        GUI.MessageBox(header, msg)
    end
end

function MT.HF.ReplaceString(original,find,replace)
    return string.gsub(original,find,replace)
end

function MT.HF.Explode(entity,range,force,damage,structureDamage,itemDamage,empStrength,ballastFloraStrength)
    
    range = range or 0
    force = force or 0
    damage = damage or 0
    structureDamage = structureDamage or 0
    itemDamage = itemDamage or 0
    empStrength = empStrength or 0
    ballastFloraStrength = ballastFloraStrength or 0

    local explosion = Explosion(range, force, damage, structureDamage,
        itemDamage, empStrength, ballastFloraStrength)
    explosion.Explode(entity.WorldPosition, nil);

    MT.HF.SpawnItemAt("ntvfx_explosion",entity.WorldPosition)
end

