
Hook.Add("item.applyTreatment", "MT.itemused", function(item, usingCharacter, targetCharacter, limb)
    
    if -- invalid use, dont do anything
        item == nil or
        usingCharacter == nil or
        targetCharacter == nil or
        limb == nil 
    then return end
    
    local identifier = item.Prefab.Identifier.Value

    local methodtorun = MT.ItemMethods[identifier] -- get the function associated with the identifer
    if(methodtorun~=nil) then 
         -- run said function
        methodtorun(item, usingCharacter, targetCharacter, limb)
        return
    end

    -- startswith functions
    for key,value in pairs(MT.ItemStartsWithMethods) do 
        if HF.StartsWith(identifier,key) then
            value(item, usingCharacter, targetCharacter, limb)
            return
        end
    end

end)

-- storing all of the item-specific functions in a table
MT.ItemMethods = {} -- with the identifier as the key
MT.ItemStartsWithMethods = {} -- with the start of the identifier as the key


-- misc

--[[
MT.ItemMethods.exampleidentifier = function(item, usingCharacter, targetCharacter, limb) 
    HF.AddAffliction(targetCharacter,"radiationsickness",1,usingCharacter)
end
]]

-- startswith region begins

-- none yet

