-- I'm sorry for the eyes of anyone looking at the GUI code... again.
if SERVER then return end -- we don't want server to run GUI code.

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
local config = MT.Config
local function DetermineDifficulty()
    

    local difficulty = 0
    local res = ""

    -- default difficulty: 5
    difficulty=difficulty
        + MT.HF.Clamp(config.dieselDrainRate*5,0,20)
        + MT.HF.Clamp(config.pumpGateDeteriorateRate*5,0,20)
        + MT.HF.Clamp(config.diveSuitDeteriorateRate*5,0,20)
        

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

    --local frame1 = GUI.Frame(GUI.RectTransform(Vector2(0.03, 0.35), GUI.Canvas))
    local frame = GUI.Frame(GUI.RectTransform(Vector2(0.5, 0.8), GUI.Screen.Selected.Frame.RectTransform, GUI.Anchor.Center)) -- styles: "OuterGlowCircular"  "InnerFrame" DigitalFrameLight- this is pea green - UpgradeUIFrame decent but bland rounded corners InnerFrameRed - use this as divider yo HorizontalLine - GUIFrameTop yes! has the bottom part I want
    MT.GUIFrame = frame
    frame.CanBeFocused = true

    -- padding frames
    local innerFrame = GUI.Frame(GUI.RectTransform(Vector2(0.95, 0.95), frame.RectTransform, GUI.Anchor.Center),"DeviceSliderSeeThrough") 
    local innerFrame2 = GUI.Frame(GUI.RectTransform(Vector2(0.95, 0.95), innerFrame.RectTransform, GUI.Anchor.Center),"DeviceSliderSeeThrough")

    -- config section
    local config = GUI.ListBox(GUI.RectTransform(Vector2(1.0, 0.25), innerFrame2.RectTransform, GUI.Anchor.TopCenter),false, Color.Red, "GUIFrameListBox")

    -- category section
    local category = GUI.ListBox(GUI.RectTransform(Vector2(1.0, 0.7), innerFrame2.RectTransform, GUI.Anchor.BottomCenter),false, nil, "GUIFrameListBox")
    category.KeepSpaceForScrollBar = true
    category.ScrollBarVisible = true

    -- save / close section
    --local menu = GUI.ListBox(GUI.RectTransform(Vector2(1.0, 0.55), innerFrame2.RectTransform, GUI.Anchor.BottomCenter),false, nil, "GUIFrameListBox")
    
    local closebtn = GUI.Button(GUI.RectTransform(Vector2(0.1, 0.1), innerFrame2.RectTransform, GUI.Anchor.TopRight), "X", GUI.Alignment.Center, "GUIButtonLarge")
    closebtn.OnClicked = function ()
        MT.ToggleGUI()
    end
    
    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Mechtrauma Config", nil, nil, GUI.Alignment.Center)
    
    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.4), config.Content.RectTransform), "Note: Only the host can edit the servers config. Enter \"reloadlua\" in console to apply changes. For dedicated servers you need to edit the file config.json, this GUI wont work.", nil, nil, GUI.Alignment.Center, true)
    
    --local difficultyText = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), config.Content.RectTransform), "Calculated difficulty rating: "..DetermineDifficulty(), nil, nil, GUI.Alignment.Center)
    local function OnChanged()
        --difficultyText.Text = "Calculated difficulty rating: "..DetermineDifficulty()
    end
    OnChanged()

    local savebtn = GUI.Button(GUI.RectTransform(Vector2(1, 0.2), config.Content.RectTransform), "Save Config", GUI.Alignment.Center, "GUIButtonLarge")
    savebtn.OnClicked = function ()
        File.Write(MT.Path .. "/config.json", json.serialize(MT.Config))
    end

    
    --local imageFrame = GUI.Frame(GUI.RectTransform(Point(65, 65), menuList.Content.RectTransform), "GUITextBox")
    --frame.RectTransform.MinSize = Point(0, 65)

    -- Drop down for selecting config Category
    local configCategory = GUI.DropDown(GUI.RectTransform(Vector2(1, 0.15), config.Content.RectTransform), "Select Category", 4, nil, false)
    category.OnSelected = function(component, object)
        return false
      end
    configCategory.AddItem("General Balance", 0)
    configCategory.AddItem("Advanced Balance", 1)
    configCategory.AddItem("Experiemental Features ", 2)
    configCategory.AddItem("Biotrauma", 3)
    --configCategory.AddItem("BANNER", 4)


    configCategory.OnSelected = function (guiComponent, object)        
       
        -----------| GENERAL BALANCE |-------------|
        if object == 0 then
            -- clear the previous results 
            ClearElements(category.Content, true)

            -- DivingSuit: Service Life Description
            GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), category.Content.RectTransform), "Diving Suit Service Life (min)", nil, nil, GUI.Alignment.Center, true).ToolTip = 
            "How long it takes for a diving suit to deteriorate from 100 to 0 condition. Low pressure diving suits last twice as long A service life 0.0 will disable deterioration and extended pressure protection."
            -- divingSuitServiceLife group
            local divingSuitServiceLifeG = GUI.LayoutGroup(GUI.RectTransform(Vector2(1.0, 0.1), category.Content.RectTransform), true, GUI.Anchor.TopLeft)
            --divingSuitServiceLife sprite
            local divingSuitServiceLifeS = ItemPrefab.GetItemPrefab("divingsuit").InventoryIcon
            local image = GUI.Image(GUI.RectTransform(Vector2(0.1,1.0), divingSuitServiceLifeG.RectTransform), divingSuitServiceLifeS)
            image.ToolTip = "Standard Diving Suit"            
            -- DivingSuit: Service Life Setting (minutes)
            local divingSuitServiceLife = GUI.NumberInput(GUI.RectTransform(Vector2(0.9,0.1), divingSuitServiceLifeG.RectTransform), NumberType.Float)
            divingSuitServiceLife.valueStep = 10.0
            divingSuitServiceLife.MinValueFloat = 0.0
            divingSuitServiceLife.MaxValueFloat = 120
            divingSuitServiceLife.FloatValue = MT.Config.divingSuitServiceLife 
            divingSuitServiceLife.OnValueChanged = function ()
                MT.Config.divingSuitServiceLife = divingSuitServiceLife.FloatValue
                OnChanged()
            end

            -- DivingSuit: Extended Pressure Protection Description
            GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), category.Content.RectTransform), "Diving Suits: Extended Pressure Protection (multiplier)", nil, nil, GUI.Alignment.Center, true).ToolTip = 
            "EPP allowed players to exceed max pressure of a diving suit resulting in exponential damage to the suit. Setting this to 1.0 will disable this feature."
             -- divingSuitEPP group
             local divingSuitEPPG = GUI.LayoutGroup(GUI.RectTransform(Vector2(1.0, 0.1), category.Content.RectTransform), true, GUI.Anchor.TopLeft)
            --divingSuitEPP sprite
            local divingSuitServiceLifeS = ItemPrefab.GetItemPrefab("dry_suit").InventoryIcon
            local image = GUI.Image(GUI.RectTransform(Vector2(0.1,1.0), divingSuitEPPG.RectTransform), divingSuitServiceLifeS)
            image.ToolTip = "Standard Low Pressure Suit"
            -- DivingSuit: Extended Pressure Protection Setting (multiplier)
            local divingSuitEPP = GUI.NumberInput(GUI.RectTransform(Vector2(0.9,0.1), divingSuitEPPG.RectTransform), NumberType.Float)
            divingSuitEPP.valueStep = 0.1
            divingSuitEPP.MinValueFloat = 1.0
            divingSuitEPP.MaxValueFloat = 2.5
            divingSuitEPP.FloatValue = MT.Config.divingSuitEPP
            divingSuitEPP.OnValueChanged = function ()
                MT.Config.divingSuitEPP = divingSuitEPP.FloatValue
                OnChanged()
            end
            

            -- SteamBoiler: Circulator Pump Service Life 
            GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), category.Content.RectTransform), "Standard Circulator Pump Service Life (min)", nil, nil, GUI.Alignment.Center, true).ToolTip = 
            "Standard Circulator Pump Service Life (min)"
            -- circulatorServiceLife group
            local circulatorServiceLifeG = GUI.LayoutGroup(GUI.RectTransform(Vector2(1.0, 0.1), category.Content.RectTransform), true)
            --bearing sprite
            local circulatorServiceLifeS = ItemPrefab.GetItemPrefab("circulator_pump").InventoryIcon
            local image = GUI.Image(GUI.RectTransform(Vector2(0.1,1.0), circulatorServiceLifeG.RectTransform), circulatorServiceLifeS)
            image.ToolTip = "Bearing"
            -- DivingSuit: Extended Pressure Protection Setting (multiplier)
            local circulatorServiceLife = GUI.NumberInput(GUI.RectTransform(Vector2(0.9,0.1), circulatorServiceLifeG.RectTransform), NumberType.Float)
            circulatorServiceLife.valueStep = 0.5
            circulatorServiceLife.MinValueFloat = 0.5
            circulatorServiceLife.MaxValueFloat = 60.0
            circulatorServiceLife.FloatValue = MT.Config.circulatorServiceLife
            circulatorServiceLife.OnValueChanged = function ()
                MT.Config.circulatorServiceLife = circulatorServiceLife.FloatValue
                MT.Config.circulatorDPS = 100 / (MT.Config.circulatorServiceLife * 60)
                OnChanged()
            end

             -- Thrust Bearing Deterioration
             GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), category.Content.RectTransform), "Standard Thrust Bearing Service Life (min)", nil, nil, GUI.Alignment.Center, true).ToolTip = 
             "10"
             -- bearingServiceLife group
             local bearingServiceLifeG = GUI.LayoutGroup(GUI.RectTransform(Vector2(1.0, 0.1), category.Content.RectTransform), true, GUI.Anchor.TopLeft)
             --bearing sprite
             local bearingServiceLifeS = ItemPrefab.GetItemPrefab("bearing").InventoryIcon
             local image = GUI.Image(GUI.RectTransform(Vector2(0.1,1.0), bearingServiceLifeG.RectTransform), bearingServiceLifeS)
             image.ToolTip = "Bearing"
             -- DivingSuit: Extended Pressure Protection Setting (multiplier)
             local bearingServiceLife = GUI.NumberInput(GUI.RectTransform(Vector2(0.9,0.1), bearingServiceLifeG.RectTransform), NumberType.Float)
             bearingServiceLife.valueStep = 0.5
             bearingServiceLife.MinValueFloat = 0.5
             bearingServiceLife.MaxValueFloat = 60
             bearingServiceLife.FloatValue = MT.Config.bearingServiceLife
             bearingServiceLife.OnValueChanged = function ()
                MT.Config.bearingServiceLife = bearingServiceLife.FloatValue
                MT.Config.bearingDPS = 100 / (MT.Config.bearingServiceLife * 60)                 
                 OnChanged()
             end
       
              -- oilFilter Standard Service Life (min)
              GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), category.Content.RectTransform), "Standard Oil Filter Service Life (min)", nil, nil, GUI.Alignment.Center, true).ToolTip = 
              "Service Life (mins) for a standard oil filter (100 condition)."
              -- oilFilter Service Life group
              local oilFilterServiceLifeG = GUI.LayoutGroup(GUI.RectTransform(Vector2(1.0, 0.1), category.Content.RectTransform), true, GUI.Anchor.TopLeft)
              --oilFilter sprite
              local oilFilterServiceLifeS = ItemPrefab.GetItemPrefab("oil_filter").InventoryIcon
              local image = GUI.Image(GUI.RectTransform(Vector2(0.1,1.0), oilFilterServiceLifeG.RectTransform), oilFilterServiceLifeS)
              image.ToolTip = "Oil Filter"
              -- oilFilter Deterioration Setting (multiplier)
              local oilFilterServiceLife = GUI.NumberInput(GUI.RectTransform(Vector2(0.9,0.1), oilFilterServiceLifeG.RectTransform), NumberType.Float)
              oilFilterServiceLife.valueStep = 0.5
              oilFilterServiceLife.MinValueFloat = 0.5
              oilFilterServiceLife.MaxValueFloat = 60
              oilFilterServiceLife.FloatValue = MT.Config.oilFilterServiceLife
              oilFilterServiceLife.OnValueChanged = function ()
                  MT.Config.oilFilterServiceLife = oilFilterServiceLife.FloatValue
                  MT.Config.oilFilterDPS = 100 / (MT.Config.oilFilterServiceLife * 60)
                  OnChanged()
              end

            -- oil Filtration Efficieny / Oil Deterioration Modifier
            GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), category.Content.RectTransform), "Oil Filtration Efficiency Rating (%)", nil, nil, GUI.Alignment.Center, true).ToolTip = 
            "This determines how long filtered oil will last in machines. A 100% efficiency rating will eliminate oil deterioration."
            -- oil Deterioration group
            local oilFiltrationEPG = GUI.LayoutGroup(GUI.RectTransform(Vector2(1.0, 0.1), category.Content.RectTransform), true, GUI.Anchor.TopLeft)
            --oil sprite
            local oilFiltrationES = ItemPrefab.GetItemPrefab("oil_can").InventoryIcon
            local image = GUI.Image(GUI.RectTransform(Vector2(0.1,1.0), oilFiltrationEPG.RectTransform), oilFiltrationES)
            image.ToolTip = "Oil Can"
            -- oil Deterioration Setting (multiplier)
            local oilFiltrationEP = GUI.NumberInput(GUI.RectTransform(Vector2(0.9,0.1), oilFiltrationEPG.RectTransform), NumberType.Float)
            oilFiltrationEP.valueStep = 1.0
            oilFiltrationEP.MinValueFloat = 1.0
            oilFiltrationEP.MaxValueFloat = 100.0
            oilFiltrationEP.FloatValue = MT.Config.oilFiltrationEP
            oilFiltrationEP.OnValueChanged = function ()
                MT.Config.oilFiltrationEP = oilFiltrationEP.FloatValue
                MT.Config.oilFiltrationM = MT.Config.oilFiltrationEP / 100
                OnChanged()
            end
        -----------| ADVANCED BALANCE |-------------| 
        elseif object == 1 then
            -- clear the previous results 
            ClearElements(category.Content, true)
            
             -- Diesel Generator Efficiency
             GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), category.Content.RectTransform), "Diesel Generator Efficiency ", nil, nil, GUI.Alignment.Center, true).ToolTip =
             "How much energy is lost ."

             -- dieselGeneratorEfficiency
            local dieselGeneratorEfficiencyG = GUI.LayoutGroup(GUI.RectTransform(Vector2(1.0, 0.1), category.Content.RectTransform), true, GUI.Anchor.TopLeft)
            -- dieselGeneratorEfficiency sprite
            local dieselGeneratorEfficiencyS = ItemPrefab.GetItemPrefab("s1500D").InventoryIcon
            local image = GUI.Image(GUI.RectTransform(Vector2(0.1,1.0), dieselGeneratorEfficiencyG.RectTransform), dieselGeneratorEfficiencyS)
            image.ToolTip = "Diesel fuel can."

            local dieselGeneratorEfficiency = GUI.NumberInput(GUI.RectTransform(Vector2(0.9, 0.1), dieselGeneratorEfficiencyG.RectTransform), NumberType.Float)
            dieselGeneratorEfficiency.valueStep = 1.0
            dieselGeneratorEfficiency.MinValueFloat = 20.0
            dieselGeneratorEfficiency.MaxValueFloat = 1
            dieselGeneratorEfficiency.FloatValue = MT.Config.dieselGeneratorEfficiency
            dieselGeneratorEfficiency.OnValueChanged = function ()
                MT.Config.dieselGeneratorEfficiency = dieselGeneratorEfficiency.FloatValue
                OnChanged()
            end

              -- Diesel (condition) to Power Ratio
              GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), category.Content.RectTransform), "Conversion Ratio: HorsePower:DieselFuel(1L)", nil, nil, GUI.Alignment.Center, true).ToolTip =
              "kWh of power contained within 1 liter of diesel."
 
              -- dieselPowerRatio group
             local dieselHorsePowerRatioG = GUI.LayoutGroup(GUI.RectTransform(Vector2(1.0, 0.1), category.Content.RectTransform), true, GUI.Anchor.TopLeft)
             --dieselPowerRatio sprite
             local dieselHorsePowerRatioS = ItemPrefab.GetItemPrefab("diesel_fuel_can").InventoryIcon
             local image = GUI.Image(GUI.RectTransform(Vector2(0.1,1.0), dieselHorsePowerRatioG.RectTransform), dieselHorsePowerRatioS)
             image.ToolTip = "Diesel fuel can."
 
             local dieselHorsePowerRatioL = GUI.NumberInput(GUI.RectTransform(Vector2(0.9, 0.1), dieselHorsePowerRatioG.RectTransform), NumberType.Float)
             dieselHorsePowerRatioL.valueStep = 0.1
             dieselHorsePowerRatioL.MinValueFloat = 0.2
             dieselHorsePowerRatioL.MaxValueFloat = 25
             dieselHorsePowerRatioL.FloatValue = MT.Config.dieselHorsePowerRatioL
             dieselHorsePowerRatioL.OnValueChanged = function ()
                 MT.Config.dieselHorsePowerRatioL = dieselHorsePowerRatioL.FloatValue
                 MT.Config.dieselHorsePowerRatioDL = MT.Config.dieselHorsePowerRatioL * 10
                 MT.Config.dieselHorsePowerRatioCL = MT.Config.dieselHorsePowerRatioL * 100
                 OnChanged()
             end

             -- Diesel (condition) to Oxygen combustion Ratio. (Devices with a fuseBox.)
             GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), category.Content.RectTransform), "Conversion Ratio: OxygenUnit:DieselFuel(1L)  ", nil, nil, GUI.Alignment.Center, true).ToolTip =
             "Diesel engine air to fuel ratio. The units of oxygen required to combust 1 liter of diesel. 7:1 air to fuel is default for Mechtrauma. A LOWER NUMBER MEANS THE DIESEL USE LESS OXYGEN. "

             -- dieselOxygenRatio group
            local dieselOxygenRatioG = GUI.LayoutGroup(GUI.RectTransform(Vector2(1.0, 0.1), category.Content.RectTransform), true, GUI.Anchor.TopLeft)
            --dieselPowerRatio sprite
            local dieselOxygenRatioS = ItemPrefab.GetItemPrefab("diesel_fuel_can").InventoryIcon
            local image = GUI.Image(GUI.RectTransform(Vector2(0.1,1.0), dieselOxygenRatioG.RectTransform), dieselOxygenRatioS)
            image.ToolTip = "Diesel fuel can."

            local dieselOxygenRatioL = GUI.NumberInput(GUI.RectTransform(Vector2(0.9, 0.1), dieselOxygenRatioG.RectTransform), NumberType.Float)
            dieselOxygenRatioL.valueStep = 1.0
            dieselOxygenRatioL.MinValueFloat = 1.0
            dieselOxygenRatioL.MaxValueFloat = 14
            dieselOxygenRatioL.FloatValue = MT.Config.dieselOxygenRatioL
            dieselOxygenRatioL.OnValueChanged = function ()
                MT.Config.dieselOxygenRatioL = dieselOxygenRatioL.FloatValue
                MT.Config.dieselOxygenRatioDL = MT.Config.dieselOxygenRatioL * 10
                MT.Config.dieselOxygenRatioCL = MT.Config.dieselOxygenRatioL * 100
                OnChanged()
            end

             -- Electrical device detirioration. (Devices with a fuseBox.)
             GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), category.Content.RectTransform), "fuseBox device deterioration (rate) ", nil, nil, GUI.Alignment.Center, true).ToolTip =
             "The deterioration rate fuseBox will suffer if it does not have a fuse in it. Fueses will deteriorate at 10% the speed of this rate"

             -- fusBoxDeterioration group
            local fusBoxDeteriorationG = GUI.LayoutGroup(GUI.RectTransform(Vector2(1.0, 0.1), category.Content.RectTransform), true, GUI.Anchor.TopLeft)
            --fusBoxDeterioration sprite
            local fusBoxDeteriorationS = ItemPrefab.GetItemPrefab("electrical_panel").InventoryIcon
            local image = GUI.Image(GUI.RectTransform(Vector2(0.1,1.0), fusBoxDeteriorationG.RectTransform), fusBoxDeteriorationS)
            image.ToolTip = "Example fuseBox device."

            local fusBoxDeterioration = GUI.NumberInput(GUI.RectTransform(Vector2(0.9, 0.1), fusBoxDeteriorationG.RectTransform), NumberType.Float)
            fusBoxDeterioration.valueStep = 0.05
            fusBoxDeterioration.MinValueFloat = 0.0
            fusBoxDeterioration.MaxValueFloat = 1
            fusBoxDeterioration.FloatValue = MT.Config.fusBoxDeterioration
            fusBoxDeterioration.OnValueChanged = function ()
                MT.Config.fusBoxDeterioration = fusBoxDeterioration.FloatValue
                OnChanged()
            end
 
            -- Fuse overvoltage base damage
            GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), category.Content.RectTransform), "fuseOvervoltDamage base damage", nil, nil, GUI.Alignment.Center, true)

            -- fuseOvervoltDamage group
            local fuseOvervoltDamageG = GUI.LayoutGroup(GUI.RectTransform(Vector2(1.0, 0.1), category.Content.RectTransform), true, GUI.Anchor.TopLeft)
            --fuseSpite
            local fuseSprite = ItemPrefab.GetItemPrefab("fuse").InventoryIcon
            local image = GUI.Image(GUI.RectTransform(Vector2(0.1,1.0), fuseOvervoltDamageG.RectTransform), fuseSprite)
            image.ToolTip = "Mechtrauma Fuse."           
            
            -- fuseOvervoltDamage setting
            local fuseOvervoltDamage = GUI.NumberInput(GUI.RectTransform(Vector2(0.9, 0.1), fuseOvervoltDamageG.RectTransform), NumberType.Float)
            fuseOvervoltDamage.valueStep = 1
            fuseOvervoltDamage.MinValueFloat = 0.0
            fuseOvervoltDamage.MaxValueFloat = 10
            fuseOvervoltDamage.FloatValue = MT.Config.fuseOvervoltDamage
            fuseOvervoltDamage.OnValueChanged = function ()
                MT.Config.fuseOvervoltDamage = fuseOvervoltDamage.FloatValue
                OnChanged()
            end
        
        -----------| EXPERIMENTAL FEATURES |-------------|
        elseif object == 2 then
                      
           -- clear the previous results 
           ClearElements(category.Content, true)

           local disableElectrocution = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), category.Content.RectTransform), "Enable Electrocution Mechanic (unbalanced)")
           disableElectrocution.Selected = MT.Config.disableElectrocution
           disableElectrocution.OnSelected = function ()
               MT.Config.disableElectrocution = disableElectrocution.State == 3               
               OnChanged()

           end


           --[[
           GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), category.Content.RectTransform), "Diesel consumption rate multiplier (NYI)", nil, nil, GUI.Alignment.Center, true).ToolTip = "Diesel is pretty cool!"  
           local dieselGroup = GUI.LayoutGroup(GUI.RectTransform(Vector2(1.0, 0.1), category.Content.RectTransform), true)
           
           local dieselsprite = ItemPrefab.GetItemPrefab("diesel_fuel_barrel").InventoryIcon
           local image = GUI.Image(GUI.RectTransform(Vector2(0.1,1.5), dieselGroup.RectTransform), dieselsprite)
           image.ToolTip = "Diesel is pretty cool!"
           local dieselDrainRate = GUI.NumberInput(GUI.RectTransform(Vector2(0.9, 1.0), dieselGroup.RectTransform), NumberType.Float)
           
           dieselDrainRate.ToolTip = "Diesel is pretty cool!"
           dieselDrainRate.valueStep = 0.1
           dieselDrainRate.MinValueFloat = 0
           dieselDrainRate.MaxValueFloat = 100
           dieselDrainRate.FloatValue = MT.Config.dieselDrainRate
           dieselDrainRate.OnValueChanged = function ()
               MT.Config.dieselDrainRate = dieselDrainRate.FloatValue
               OnChanged()
           end  ]]
       
           GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), category.Content.RectTransform), "Pump Gate deterioration rate multiplier", nil, nil, GUI.Alignment.Center, true)
           local pumpGateDeteriorateRate = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), category.Content.RectTransform), NumberType.Float)
           pumpGateDeteriorateRate.valueStep = 0.1
           pumpGateDeteriorateRate.MinValueFloat = 0
           pumpGateDeteriorateRate.MaxValueFloat = 100
           pumpGateDeteriorateRate.FloatValue = MT.Config.pumpGateDeteriorateRate
           pumpGateDeteriorateRate.OnValueChanged = function ()
               MT.Config.pumpGateDeteriorateRate = pumpGateDeteriorateRate.FloatValue
               OnChanged()
           end
     
        -----------| BIOTRAUMA |-------------|
        elseif object == 3 then 
            -- clear the previous results 
            ClearElements(category.Content, true)
            GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), category.Content.RectTransform), "Biotrauma Config", nil, nil, GUI.Alignment.Center)

            -- Fungus spawn rate. 
            GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), category.Content.RectTransform), "Fungus Spawn Rate", nil, nil, GUI.Alignment.Center, true)
            local ventSpawnRate = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), category.Content.RectTransform), NumberType.Float)
            ventSpawnRate.valueStep = 0.1
            ventSpawnRate.MinValueFloat = 0.0
            ventSpawnRate.MaxValueFloat = 10
            ventSpawnRate.FloatValue = MT.Config.ventSpawnRate
            ventSpawnRate.OnValueChanged = function ()
                MT.Config.ventSpawnRate = MT.HF.Round(ventSpawnRate.FloatValue, 2)
                OnChanged()
            end
        -----------| TEST |-------------|        
        elseif object == 4 then
             --clear the previous results 
             ClearElements(category.Content, true)
           
            local mechtraumaBanner = Sprite(MT.Path .. "/images/mechtrauma_eys.png")
            GUI.Image(GUI.RectTransform(Vector2(.75,.75), category.Content.RectTransform, GUI.Anchor.Center), mechtraumaBanner)

            -- Diesel Generator Efficiency
            GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.1), category.Content.RectTransform), "Oil base DPS ", nil, nil, GUI.Alignment.Center, true).ToolTip =
            "How much energy is lost ."

            -- dieselGeneratorEfficiency
            local oilBaseDPSG = GUI.LayoutGroup(GUI.RectTransform(Vector2(1.0, 0.1), category.Content.RectTransform), true)
            -- dieselGeneratorEfficiency sprite
            local oilBaseDPSS = ItemPrefab.GetItemPrefab("oil_can").InventoryIcon
            local image = GUI.Image(GUI.RectTransform(Vector2(0.1,1.0), oilBaseDPSG.RectTransform), oilBaseDPSS)
            image.ToolTip = "Diesel fuel can."

            local oilBaseDPS = GUI.NumberInput(GUI.RectTransform(Vector2(0.9, 0.1), oilBaseDPSG.RectTransform), NumberType.Float)
            oilBaseDPS.valueStep = 1.0
            oilBaseDPS.MinValueFloat = 20.0
            oilBaseDPS.MaxValueFloat = 1
            oilBaseDPS.FloatValue = MT.Config.oilBaseDPS
            oilBaseDPS.OnValueChanged = function ()
                MT.Config.oilBaseDPS = oilBaseDPS.FloatValue
                OnChanged()
            end
        end       
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
