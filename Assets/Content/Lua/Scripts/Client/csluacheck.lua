--[[
    This example shows how to create a basic custom GUI. The GUI will appear top right of your in game screen.
--]]

if SERVER then return end -- we don't want server to run GUI code.

if not CSActive then   
local menuOpen = false

-- our main frame where we will put our custom GUI
local frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
frame.CanBeFocused = false

-- menu frame
local menu = GUI.Frame(GUI.RectTransform(Vector2(1, 1), frame.RectTransform, GUI.Anchor.Center), nil)
menu.CanBeFocused = false
menu.Visible = true

-- put a button that goes behind the menu content, so we can close it when we click outside
local closeButton = GUI.Button(GUI.RectTransform(Vector2(1, 1), menu.RectTransform, GUI.Anchor.Center), "", GUI.Alignment.Center, nil)
closeButton.OnClicked = function ()
    menu.Visible = not menu.Visible
end

-- a button top right of our screen to open a sub-frame menu
local button = GUI.Button(GUI.RectTransform(Vector2(0.2, 0.2), frame.RectTransform, GUI.Anchor.TopRight), "!PROBLEM! CsForBarotrauma is not enabled!", GUI.Alignment.Center, "GUIButtonSmall")
button.RectTransform.AbsoluteOffset = Point(25, 50)
button.OnClicked = function ()
    menu.Visible = not menu.Visible
end

local menuContent = GUI.Frame(GUI.RectTransform(Vector2(0.4, 0.2), menu.RectTransform, GUI.Anchor.Center))
local menuList = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), menuContent.RectTransform, GUI.Anchor.BottomCenter))

local coloredText = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.2), menuList.Content.RectTransform), "!PROBLEM! CsForBarotrauma is not enabled!", nil, nil, GUI.Alignment.Center) coloredText.TextColor = Color(255, 0, 0)

local coloredText = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.2), menuList.Content.RectTransform), "CsForBarotrauma is not enabled! This is a required mod and Mechtrauma will not function without it!", nil, nil, GUI.Alignment.Center) coloredText.TextColor = Color(255, 0, 0)
local coloredText = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.2), menuList.Content.RectTransform), "Make sure that you are subscribed to CsForBarotrauma the steam workshop and that it is enabled.", nil, nil, GUI.Alignment.Center) coloredText.TextColor = Color(255, 0, 0)
        


Hook.Patch("Barotrauma.GameScreen", "AddToGUIUpdateList", function()
    frame.AddToGUIUpdateList()
end)
end