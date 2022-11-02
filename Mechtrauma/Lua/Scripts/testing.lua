
-- set the below variable to true to enable debug and testing features
MT.TestingEnabled = true

Hook.Add('chatMessage', 'MT.testing', function(msg, client)
    
    if(msg=="mt1") then
        if not MT.TestingEnabled then return end
        -- insert testing stuff here
        
        print("only fools do read this")

        return true
    elseif(msg=="mt2") then
        if not MT.TestingEnabled then return end
        -- insert other testing stuff here
        
        print("sussy baka")

        return true
    end
end)