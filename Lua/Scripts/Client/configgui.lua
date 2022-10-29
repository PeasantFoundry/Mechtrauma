-- I'm sorry for the eyes of anyone looking at the GUI code... again.

Game.AddCommand("mechtrauma", "opens mechtrauma config", function ()
    MT.ToggleGUI()
end)

local function ClearElements(guicomponent, removeItself)
    local toRemove = {}

    for value in guicomponent.GetAllChildren() do
        table.insert(toRemove, value)
    end

    for index, value in pairs(toRemove) do
        value.RemoveChild(value)
    end

    if guicomponent.Parent and removeItself then
        guicomponent.Parent.RemoveChild(guicomponent)
    end
end
local function DetermineDifficulty()
    local config = MT.Config

    local difficulty = 0
    local res = ""

    -- default difficulty: 5
    difficulty=difficulty
        + MT.HF.Clamp(config.dieselDrainRate*5,0,20)

    -- normalize to 10
    difficulty = difficulty / 5 * 10

    if difficulty > 23 then res="Impossible"
    elseif difficulty > 16 then res="Very hard"
    elseif difficulty > 11 then res="Hard"
    elseif difficulty > 8 then res="Normal"
    elseif difficulty > 6 then res="Easy"
    elseif difficulty > 4 then res="Very easy"
    elseif difficulty > 2 then res="Barely different"
    else res="Vanilla"
    end

    res = res.." (".. MT.HF.Round(difficulty,1)..")"
    return res
end


Hook.Add("stop", "MT.CleanupGUI", function ()
    if selectedGUIText then
        selectedGUIText.Parent.RemoveChild(selectedGUIText)
    end

    if MT.GUIFrame then
        ClearElements(MT.GUIFrame, true)
    end
end)

MT.ShowGUI = function ()
    local frame = GUI.Frame(GUI.RectTransform(Vector2(0.3, 0.6), GUI.Screen.Selected.Frame.RectTransform, GUI.Anchor.Center))

    MT.GUIFrame = frame

    frame.CanBeFocused = true

    local config = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), frame.RectTransform, GUI.Anchor.BottomCenter))
    
    local closebtn = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.3), frame.RectTransform, GUI.Anchor.TopRight), "X", GUI.Alignment.Center, "GUIButtonSmall")
    closebtn.OnClicked = function ()
        MT.ToggleGUI()
    end

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), "Mechtrauma Config", nil, nil, GUI.Alignment.Center)
    
    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Note: Only the host can edit the servers config. Enter \"reloadlua\" in console to apply changes. For dedicated servers you need to edit the file config.json, this GUI wont work.", nil, nil, GUI.Alignment.Center, true)
    
    local difficultyText = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), "Calculated difficulty rating: "..DetermineDifficulty(), nil, nil, GUI.Alignment.Center)

    local function OnChanged()
        difficultyText.Text = "Calculated difficulty rating: "..DetermineDifficulty()
    end
    OnChanged()

    local savebtn = GUI.Button(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Save Config", GUI.Alignment.Center, "GUIButtonSmall")
    savebtn.OnClicked = function ()
        File.Write(MT.Path .. "/config.json", json.serialize(MT.Config))
    end


    

    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), config.Content.RectTransform), "Diesel consumption rate multiplier (NYI)", nil, nil, GUI.Alignment.Center, true)
    local dieselDrainRate = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), NumberType.Float)
    dieselDrainRate.valueStep = 0.1
    dieselDrainRate.MinValueFloat = 0
    dieselDrainRate.MaxValueFloat = 100
    dieselDrainRate.FloatValue = MT.Config.dieselDrainRate
    dieselDrainRate.OnValueChanged = function ()
        MT.Config.dieselDrainRate = dieselDrainRate.FloatValue
        OnChanged()
    end

    --[[
    local disableBotAlgorithms = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Disable bot treatment algorithms (they're laggy)")
    disableBotAlgorithms.Selected = MT.Config.disableBotAlgorithms
    disableBotAlgorithms.OnSelected = function ()
        MT.Config.disableBotAlgorithms = disableBotAlgorithms.State == 3
        OnChanged()
    end
    ]]
    
end


MT.HideGUI = function()
    if MT.GUIFrame then
        ClearElements(MT.GUIFrame, true)
    end
end

MT.GUIOpen = false
MT.ToggleGUI = function ()
    MT.GUIOpen = not MT.GUIOpen

    if MT.GUIOpen then
        MT.ShowGUI()
    else
        MT.HideGUI()
    end
end