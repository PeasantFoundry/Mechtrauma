
MT.HF = {} -- Helperfunctions (using HF instead of MT.HF might conflict with neurotraumas use of the term)

-- Mechtrauma exclusive functions:

-- subtracts single amount from a list of items sequentially  
function MT.HF.subFromListSeq (amount, list)
    for k, item in pairs(list) do
        if amount > item.Condition then 
            amount = amount - item.Condition
            item.Condition = 0
        else
            item.Condition = item.Condition - amount
            amount = 0
        end
    end
end

-- subtracts amount from list by dividing it equally
function MT.HF.subFromListEqu (amount, list)
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

-- print blank lines to terminal in place of a functioning clear command
function MT.HF.BlankTerminalLines(terminal, lines)
    local counter = 0
    while counter < lines do
        counter = counter + 1
        terminal.ShowMessage = "-"
    end    
end

-- colored terminal message
function MT.HF.SendTerminalColorMessage(item, terminal, color, message)
    local terminalOrgiginalColor = terminal.TextColor -- save the current terminal color
    local property = terminal.SerializableProperties[Identifier("TextColor")]
  
            terminal.TextColor = color    
            if SERVER then Networking.CreateEntityEvent(item, Item.ChangePropertyEventData(property)) end
   
            terminal.ShowMessage = message
            if SERVER then terminal.SyncHistory()  end

   

    --Timer.Wait(function() end,  10000) -- 100 = .1 second    
   
end

-- utility for checking there are missing items from the cache
function MT.HF.VerifyItemCache()  
    print(" MT.itemCache BEFORE update: ",  MT.itemCacheCount)
    -- flag the round as started    
        -- loop through the item list and find items for the cache
        for k, item in pairs(Item.ItemList) do  
           if item.HasTag("mtu") or (item.HasTag("diving") and item.HasTag("deepdiving")) then            
                if  MT.itemCache[item] then 
                    print("Item Already Exists: ", item)                                     
                else 
                    print("Found a missing item: ", item, "adding it to the cache")                    
                     MT.itemCache[item] = true
                     MT.itemCacheCount =  MT.itemCacheCount + 1
                end                 
           end  
       end       
       print(" MT.itemCache AFTER update: ",  MT.itemCacheCount)
       
end

-- fucked by Hadrada on 11/12/22
-- unfucked by Mannatu on 11/13/22
function MT.HF.ItemIsWornInOuterClothesSlot(item)
    if item.ParentInventory == nil then return false end 
    if not LuaUserData.IsTargetType(item.ParentInventory, "Barotrauma.CharacterInventory") then return false end
    if item.ParentInventory.GetItemInLimbSlot(InvSlotType.OuterClothes) ~= item then return false end

  return true
  end
--this is a testing function for damaging machines 
  function MT.HF.damageFocusedItem(amount)
    local item = Client.ClientList[1].Character.FocusedItem
    item.condition = item.condition - amount
    end

-- Mechtrauma medical helper functions
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

-- Neurotrauma complementary functions:  

-- general mathy functions:

function MT.HF.Lerp(a, b, t)
	return a + (b - a) * t
end

function MT.HF.Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

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

-- /// misc ///

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

function MT.HF.Chance(chance)
    return math.random() < chance
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

--sadly, Game.RoundStarted does not work for singleplayer (sub editor)
function MT.HF.GameIsRunning()
    if SERVER then return false end

    if Game.Paused or not Game.RoundStarted then return false end

    return true
    
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

-- returns an unrounded random number
function MT.HF.RandomRange(min,max) 
    return min+math.random()*(max-min)
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

