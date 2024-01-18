local write, writeIndent, writers, refCount;

Persistence =
{
	store = function (path, ...)
		local file, e = io.open(path, "w");
		if not file then
			return error(e);
		end
		local n = select("#", ...);
		-- Count references
		local objRefCount = {}; -- Stores reference that will be exported
		for i = 1, n do
			refCount(objRefCount, (select(i,...)));
		end;
		-- Export Objects with more than one ref and assign name
		-- First, create empty tables for each
		local objRefNames = {};
		local objRefIdx = 0;
		file:write("-- Persistent Data\n");
		file:write("local multiRefObjects = {\n");
		for obj, count in pairs(objRefCount) do
			if count > 1 then
				objRefIdx = objRefIdx + 1;
				objRefNames[obj] = objRefIdx;
				file:write("{};"); -- table objRefIdx
			end;
		end;
		file:write("\n} -- multiRefObjects\n");
		-- Then fill them (this requires all empty multiRefObjects to exist)
		for obj, idx in pairs(objRefNames) do
			for k, v in pairs(obj) do
				file:write("multiRefObjects["..idx.."][");
				write(file, k, 0, objRefNames);
				file:write("] = ");
				write(file, v, 0, objRefNames);
				file:write(";\n");
			end;
		end;
		-- Create the remaining objects
		for i = 1, n do
			file:write("local ".."obj"..i.." = ");
			write(file, (select(i,...)), 0, objRefNames);
			file:write("\n");
		end
		-- Return them
		if n > 0 then
			file:write("return obj1");
			for i = 2, n do
				file:write(" ,obj"..i);
			end;
			file:write("\n");
		else
			file:write("return\n");
		end;
		if type(path) == "string" then
			file:close();
		end;
	end;

	load = function (path)
		local f, e;
		if type(path) == "string" then
			f, e = loadfile(path);
		else
			f, e = path:read('*a')
		end
		if f then
			return f();
		else
			return nil, e;
		end;
	end;
}

-- Private methods

-- write thing (dispatcher)
write = function (file, item, level, objRefNames)
	writers[type(item)](file, item, level, objRefNames);
end;

-- write indent
writeIndent = function (file, level)
	for i = 1, level do
		file:write("\t");
	end;
end;

-- recursively count references
refCount = function (objRefCount, item)
	-- only count reference types (tables)
	if type(item) == "table" then
		-- Increase ref count
		if objRefCount[item] then
			objRefCount[item] = objRefCount[item] + 1;
		else
			objRefCount[item] = 1;
			-- If first encounter, traverse
			for k, v in pairs(item) do
				refCount(objRefCount, k);
				refCount(objRefCount, v);
			end;
		end;
	end;
end;

-- Format items for the purpose of restoring
writers = {
	["nil"] = function (file, item)
			file:write("nil");
		end;
	["number"] = function (file, item)
			file:write(tostring(item));
		end;
	["string"] = function (file, item)
			file:write(string.format("%q", item));
		end;
	["boolean"] = function (file, item)
			if item then
				file:write("true");
			else
				file:write("false");
			end
		end;
	["table"] = function (file, item, level, objRefNames)
			local refIdx = objRefNames[item];
			if refIdx then
				-- Table with multiple references
				file:write("multiRefObjects["..refIdx.."]");
			else
				-- Single use table
				file:write("{\n");
				for k, v in pairs(item) do
					writeIndent(file, level+1);
					file:write("[");
					write(file, k, level+1, objRefNames);
					file:write("] = ");
					write(file, v, level+1, objRefNames);
					file:write(";\n");
				end
				writeIndent(file, level);
				file:write("}");
			end;
		end;
	["function"] = function (file, item)
			-- Does only work for "normal" functions, not those
			-- with upvalues or c functions
            print(tostring(item))
			local dInfo = debug.getinfo(item, "uS");
			if dInfo.nups > 0 then
				file:write("nil --[[functions with upvalue not supported]]");
			elseif dInfo.what ~= "Lua" then
				file:write("nil --[[non-lua function not supported]]");
			else
				local r, s = pcall(string.dump,item);
				if r then
					file:write(string.format("loadstring(%q)", s));
				else
					file:write("nil --[[function could not be dumped]]");
				end
			end
		end;
	["thread"] = function (file, item)
			file:write("nil --[[thread]]\n");
		end;
	["userdata"] = function (file, item)
			file:write("nil --[[userdata]]\n");
		end;
}


--[[
-- set the below variable to true to enable debug and testing features
MT.TestingEnabled = true

if CSActive then   
    print("CS IS ACTIVE!")  
end


    if SERVER then return end -- we don't want server to run GUI code.

    local modPath = ...
    
    local menuOpen = false
    
    -- our main frame where we will put our custom GUI
    local frame = GUI.Frame(GUI.RectTransform(Vector2(1, 1)), nil)
    frame.CanBeFocused = false
    
    -- menu frame
    local menu = GUI.Frame(GUI.RectTransform(Vector2(1, 1), frame.RectTransform, GUI.Anchor.Center), nil)
    menu.CanBeFocused = false
    menu.Visible = false
    
    -- put a button that goes behind the menu content, so we can close it when we click outside
    local closeButton = GUI.Button(GUI.RectTransform(Vector2(1, 1), menu.RectTransform, GUI.Anchor.Center), "", GUI.Alignment.Center, nil)
    closeButton.OnClicked = function ()
        menu.Visible = not menu.Visible
    end
    
    -- a button top right of our screen to open a sub-frame menu
    local button = GUI.Button(GUI.RectTransform(Vector2(0.2, 0.2), frame.RectTransform, GUI.Anchor.TopRight), "Custom GUI Example", GUI.Alignment.Center, "GUIButtonSmall")
    button.RectTransform.AbsoluteOffset = Point(25, 50)
    button.OnClicked = function ()
        menu.Visible = not menu.Visible
    end
    
    local menuContent = GUI.Frame(GUI.RectTransform(Vector2(0.4, 0.6), menu.RectTransform, GUI.Anchor.Center))
    local menuList = GUI.ListBox(GUI.RectTransform(Vector2(1, 1), menuContent.RectTransform, GUI.Anchor.BottomCenter))
    
    GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.05), menuList.Content.RectTransform), "This is a sample text!", nil, nil, GUI.Alignment.Center)
    
    for i = 1, 10, 1 do
        local coloredText = GUI.TextBlock(GUI.RectTransform(Vector2(1, 0.025), menuList.Content.RectTransform), "This is some colored text!", nil, nil, GUI.Alignment.Center)
        coloredText.TextColor = Color(math.random(0, 255), math.random(0, 255), math.random(0, 255))
    end
    
    local textBox = GUI.TextBox(GUI.RectTransform(Vector2(1, 0.2), menuList.Content.RectTransform), "This is a text box")
    textBox.OnTextChangedDelegate = function (textBox)
        print(textBox.Text)
    end
    
    local tickBox = GUI.TickBox(GUI.RectTransform(Vector2(1, 0.2), menuList.Content.RectTransform), "This is a tick box")
    tickBox.Selected = true
    tickBox.OnSelected = function ()
        print(tickBox.State == 3)
    end
    
    local numberInput = GUI.NumberInput(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), NumberType.Float)
    numberInput.MinValueFloat = 0
    numberInput.MaxValueFloat = 1000
    numberInput.valueStep = 1
    numberInput.OnValueChanged = function ()
        print(numberInput.FloatValue)
    end
    
    local scrollBar = GUI.ScrollBar(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), 0.1, nil, "GUISlider")
    scrollBar.Range = Vector2(0, 100)
    scrollBar.BarScrollValue = 50
    scrollBar.OnMoved = function ()
        print(scrollBar.BarScrollValue)
    end
    
    local someButton = GUI.Button(GUI.RectTransform(Vector2(1, 0.1), menuList.Content.RectTransform), "This is a button", GUI.Alignment.Center, "GUIButtonSmall")
    someButton.OnClicked = function ()
        print("button")
    end
    
    local dropDown = GUI.DropDown(GUI.RectTransform(Vector2(1, 0.05), menuList.Content.RectTransform), "This is a dropdown", 3, nil, false)
    dropDown.AddItem("First Item", 0)
    dropDown.AddItem("Second Item", 1)
    dropDown.AddItem("Third Item", 2)
    dropDown.OnSelected = function (guiComponent, object)
        print(object)
    end
    
    local multiDropDown = GUI.DropDown(GUI.RectTransform(Vector2(1, 0.05), menuList.Content.RectTransform), "This is a multi-dropdown", 3, nil, true)
    multiDropDown.AddItem("First Item", 0)
    multiDropDown.AddItem("Second Item", 1)
    multiDropDown.AddItem("Third Item", 2)
    multiDropDown.OnSelected = function (guiComponent, object)
        for value in multiDropDown.SelectedDataMultiple do
            print(value)
        end
    end
    
    local imageFrame = GUI.Frame(GUI.RectTransform(Point(65, 65), menuList.Content.RectTransform), "GUITextBox")
    imageFrame.RectTransform.MinSize = Point(0, 65)
    local sprite = ItemPrefab.GetItemPrefab("bandage").InventoryIcon
    local image = GUI.Image(GUI.RectTransform(Vector2(1, 1), imageFrame.RectTransform, GUI.Anchor.Center), sprite)
    image.ToolTip = "Bandages are pretty cool"
    
    
    local customImageFrame = GUI.Frame(GUI.RectTransform(Point(128, 128), menuList.Content.RectTransform), "GUITextBox")
    customImageFrame.RectTransform.MinSize = Point(138, 138)
    local customSprite = Sprite(modPath .. "/mechtrauma_banner.png")
    GUI.Image(GUI.RectTransform(Point(65, 65), customImageFrame.RectTransform, GUI.Anchor.Center), customSprite)
    
    Hook.Patch("Barotrauma.GameScreen", "AddToGUIUpdateList", function()
        frame.AddToGUIUpdateList()
    end)

Game.AddCommand("mechtraumaclean", "removes *useless* items", function ()
    MT.HF.MechtraumaClean()
end)


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
end)]]
