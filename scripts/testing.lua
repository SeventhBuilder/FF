-- ============================================================
--  FF Hub
--  Original by SeventhBuilder
-- ============================================================

local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Anti-SimpleSpy
for _, descendant in pairs(CoreGui:GetDescendants()) do
	if descendant.Name == "SimpleSpy2" then
		descendant:Destroy()
		Players.LocalPlayer:Kick("Unstable connection detected")
	end
end

-- Destroy previous instance if re-running
if CoreGui:FindFirstChild("RayfieldLibrary") then
	CoreGui:FindFirstChild("RayfieldLibrary"):Destroy()
end
getgenv().scriptRunning = false
task.wait(0.1)
getgenv().scriptRunning = true

local speaker = Players.LocalPlayer
local Mouse = speaker:GetMouse()

-- ===================== STATE VARIABLES =====================
-- Movement
local walkspeed = 18
local jumppower = 81.5
local gravity = Workspace.Gravity
local sangle = 56
local flyspeed = 1
local iyflyspeed = flyspeed

-- Farm flags
local ffarm = false
local bfarm = false
local dfarm = false
local lfarm = false
local longwait = false
local shortwait = false
local randomboth = true
local amountEmptyInventory = 20

-- Notification toggles (per-feature)
local notif = {
	present  = true,
	frog     = true,
	cosmic   = true,
	gambler  = true,
	firefly  = true,
	birdnest = true,
}

-- ESP
local pESP = false
local plants = {}
local plantNames = {}
local loweredPlantNames = {}

-- Noclip / Fly
local Clip = false
local Noclipping = nil
local FLYING = false
local flyKeyDown, flyKeyUp

-- ===================== GOTO =====================
local function goto(pos)
	repeat task.wait() until speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
	if not Workspace.HOLE:FindFirstChild("HoleTPEntrance") then
		repeat
			local prev = speaker.Character.HumanoidRootPart.CFrame
			speaker.Character.HumanoidRootPart.CFrame = CFrame.new(1304,96,-525)
			task.wait()
			speaker.Character.HumanoidRootPart.CFrame = prev
			task.wait(1)
		until Workspace.HOLE:FindFirstChild("HoleTPEntrance")
	end

	local hrp = speaker.Character.HumanoidRootPart
	if (hrp.Position - pos).Magnitude < 200 then
		hrp.CFrame = CFrame.new(pos)
		task.wait(0.3)
	else
		local hole = Workspace.HOLE.HoleTPEntrance
		local oPos, oSize = hole.Position, hole.Size
		hole.Size = Vector3.new(1,1,1)
		hole.Transparency = 1
		hole.CFrame = hrp.CFrame
		repeat hole.Position = hrp.Position task.wait() until (hole.Position - hrp.Position).Magnitude < 10
		hole.Position = oPos
		hole.Size = oSize
		repeat task.wait() until (hrp.Position - Vector3.new(430,441,102)).Magnitude < 10
		for i = 1, 4 do
			hrp.Anchored = true
			hrp.CFrame = CFrame.new(pos)
			task.wait(0.1)
		end
		hrp.Anchored = false
	end
end

local function checkTP()
	if not Workspace.HOLE:FindFirstChild("HoleTPEntrance") then
		repeat
			local prev = speaker.Character.HumanoidRootPart.CFrame
			speaker.Character.HumanoidRootPart.CFrame = CFrame.new(1304,96,-525)
			task.wait()
			speaker.Character.HumanoidRootPart.CFrame = prev
			task.wait(1)
		until Workspace.HOLE:FindFirstChild("HoleTPEntrance")
	end
end

-- ===================== GOTO FIREFLY =====================
local function gotofirefly(firefly)
	local hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	checkTP()
	local hole = Workspace.HOLE.HoleTPEntrance

	if (hrp.Position - firefly.Position).Magnitude >= 200 then
		hole.Size = Vector3.new(1,1,1)
		hole.Transparency = 1
		hole.CFrame = hrp.CFrame
		repeat hole.Position = hrp.Position task.wait() until (hole.Position - hrp.Position).Magnitude < 10
		hole.Position = Vector3.new(1318,85,-527)
		hole.Size = Vector3.new(14,5,17)
		repeat task.wait() until (hrp.Position - Vector3.new(430,441,102)).Magnitude < 10
		for i = 1, 5 do
			hrp.Anchored = true
			hrp.CFrame = firefly.CFrame + Vector3.new(0,3,0)
			task.wait(0.1)
		end
	end

	task.wait()
	if firefly.Parent then
		repeat
			if not ffarm then break end
			hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
			if not hrp then break end
			hrp.Anchored = true
			hrp.CFrame = firefly.CFrame + Vector3.new(0,3,0)
			hrp.Anchored = false
			task.wait()
			if firefly:FindFirstChild("CollectEvent") then
				firefly.CollectEvent:FireServer()
			end
			task.wait(0.08)
		until firefly.Parent == nil
	end

	if hrp then hrp.Anchored = false end
end

-- ===================== DELI HELPERS =====================
local function ringBell()
	pcall(function()
		ReplicatedStorage.Events.Deli:FireServer("RingBell")
		Players.LocalPlayer.PlayerGui.DeliGui.BellButton.Visible = false
	end)
	task.wait()
end

local function hideNotifications()
	pcall(function()
		if Players.LocalPlayer.PlayerGui.Notification.Enabled then
			Players.LocalPlayer.PlayerGui.Notification.Enabled = false
		end
	end)
	task.wait()
end

local function sitAtDeliBooth()
	pcall(function() Workspace.Deli.Booth1.InteractEvent:FireServer() end)
	task.wait()
end

local function hideDialogs()
	pcall(function()
		if Players.LocalPlayer.PlayerGui.Dialog.Main.Visible then
			Players.LocalPlayer.PlayerGui.Dialog.Main.Visible = false
		end
	end)
	task.wait()
end

local function skipInitialDeliDialog()
	pcall(function()
		Workspace.Deli.Booth1.WaiterLocation.Dialog2.D.D1.D1.E.RE1:FireServer()
	end)
	task.wait()
end

-- ===================== SELL LOST ITEMS =====================
local LOST_ITEM_IDS = {
	982,2223,2224,2225,2276,2228,2229,825,2233,2239,2240,2241,
	2280,2246,2247,2249,2250,2251,2252,2254,2256,2257,2258,203,
	2260,2261,2262,1435,205,407
}

local function sellLostItems()
	for _, id in pairs(LOST_ITEM_IDS) do
		pcall(function()
			ReplicatedStorage.Events.SellShop:FireServer(id, Workspace.Shops.Sellers, 1)
		end)
	end
end

-- ===================== TELEPORT TABLES =====================
local OVERWORLD_TP = {
	["A Frontier Of Dragons"]      = Vector3.new(1184,91,-2823),
	["Abandoned Orchard"]          = Vector3.new(271,88,-1840),
	["Ancient Forest"]             = Vector3.new(676,236,-1246),
	["Blackrock Mountain"]         = Vector3.new(-594,140,-612),
	["Blue Ogre Camp"]             = Vector3.new(-865,57,-1546),
	["Celestial Field"]            = Vector3.new(1534,92,-2899),
	["Celestial Peak"]             = Vector3.new(1473,195,-2483),
	["Clamstack Cave"]             = Vector3.new(565,158,-952),
	["Coral Bay"]                  = Vector3.new(1867,1,-2765),
	["Farm Fortress"]              = Vector3.new(166,53,415),
	["Frigid Waste (PvP)"]         = Vector3.new(-1737,155,-785),
	["Gnome Magic School"]         = Vector3.new(789,240,-574),
	["Great Pine Forest"]          = Vector3.new(-13,73,-1274),
	["Greenhorn Grove"]            = Vector3.new(296,73,-217),
	["Hoodlum Falls"]              = Vector3.new(1777,61,-997),
	["Matumada"]                   = Vector3.new(-978,1,-2486),
	["Otherworld Tower"]           = Vector3.new(1178,86,-3352),
	["Pebble Bay"]                 = Vector3.new(-44,2,719),
	["Petrified Grassland"]        = Vector3.new(1655,73,-1331),
	["Pit Depths"]                 = Vector3.new(1183,-59,-2080),
	["Rabbit Hole"]                = Vector3.new(-3233,245,-2623),
	["Red Ant Cove"]               = Vector3.new(886,63,362),
	["Rubble Spring"]              = Vector3.new(1062,73,-534),
	["Starry Point"]               = Vector3.new(2265,5,481),
	["Strangeman's Domain"]        = Vector3.new(-4778,267,732),
	["The Deep Forest"]            = Vector3.new(1585,73,112),
	["The Forgotten Lands"]        = Vector3.new(-779,92,-1200),
	["The Long Coast"]             = Vector3.new(-1172,3,-1303),
	["The Maze Wood"]              = Vector3.new(692,89,-2388),
	["The Pits"]                   = Vector3.new(1320,89,-2430),
	["The Quiet Field"]            = Vector3.new(2013,111,-447),
	["The Rolling Road"]           = Vector3.new(1731,92,-2404),
	["The Spider's Nest"]          = Vector3.new(1500,209,-3701),
	["The Town of Right and Wrong"]= Vector3.new(1115,92,-3134),
	["Topple Hill"]                = Vector3.new(777,199,-312),
	["Topple Lake"]                = Vector3.new(615,256,-757),
	["Topple Town"]                = Vector3.new(685,226,-461),
	["Twinkling Meadow"]           = Vector3.new(92,73,-752),
	["Upper Island"]               = Vector3.new(-1361,35,-2278),
}

local RATBOY_TP = {
	["Back of The Theatre"]   = Vector3.new(7799,172,-3629),
	["Blue Button"]           = Vector3.new(7285,172,-2549),
	["Blue Door"]             = Vector3.new(7149,169,-1621),
	["Cyan (Teal) Button"]    = Vector3.new(7203,244,2235),
	["Cyan (Teal) Door"]      = Vector3.new(7794,204,2212),
	["End of the Road"]       = Vector3.new(10779,375,-12512),
	["Fish Hall"]             = Vector3.new(12905,205,5036),
	["Green Button"]          = Vector3.new(7926,157,-3546),
	["Green Door"]            = Vector3.new(7298,171,-2543),
	["Inside"]                = Vector3.new(7311,171,-2558),
	["Maze of the Root"]      = Vector3.new(13132,191,7532),
	["Meeting Place"]         = Vector3.new(7514,237,-4952),
	["MYSTERY STORE"]         = Vector3.new(6765,200,-2545),
	["Orange Button"]         = Vector3.new(7129,143,-1587),
	["Orange Door"]           = Vector3.new(6985,141,-1635),
	["Pink Button"]           = Vector3.new(7208,154,-1717),
	["Pink Door"]             = Vector3.new(7163,168,-1742),
	["Purple Button"]         = Vector3.new(7297,147,-1701),
	["Purple Door"]           = Vector3.new(7021,141,-1689),
	["Red Button"]            = Vector3.new(7261,200,-2147),
	["Red Door"]              = Vector3.new(7229,168,-814),
	["The Back Area"]         = Vector3.new(7206,244,2122),
	["The Ballroom"]          = Vector3.new(11825,318,2432),
	["The Deli"]              = Vector3.new(7070,140,-1621),
	["The Grand Hall"]        = Vector3.new(5928,211,4845),
	["The Hidden Library"]    = Vector3.new(8170,187,-949),
	["The Library of Riddles"]= Vector3.new(7332,157,-1636),
	["The Lost"]              = Vector3.new(5858,157,4904),
	["The Mansion"]           = Vector3.new(7003,140,-1639),
	["The Old Cave"]          = Vector3.new(13099,174,6944),
	["The Old Mansion"]       = Vector3.new(7242,168,-2114),
	["The Plant Room"]        = Vector3.new(7066,159,-855),
	["The Road"]              = Vector3.new(10759,201,8595),
	["The Supermarket"]       = Vector3.new(7252,202,2269),
	["The Theatre"]           = Vector3.new(7510,147,-3613),
	["The Vault"]             = Vector3.new(5740,224,-3178),
	["Waiting Room"]          = Vector3.new(12398,284,-5296),
	["Yellow Button"]         = Vector3.new(8510,214,-1242),
	["Yellow Door"]           = Vector3.new(7195,168,-1638),
}

local HOUSING_TP = {
	["Black Tower (Celestial Field)"] = Vector3.new(1387,137,-3217),
	["Boathouse (Long Coast)"]        = Vector3.new(-484,4,-1692),
	["Castle (Topple Town)"]          = Vector3.new(589,312,-678),
	["Ice Spire (Matumada)"]          = Vector3.new(-2169,40,-1229),
	["Starter House (Topple Town)"]   = Vector3.new(641,237,-462),
	["Two Story House (Topple Town)"] = Vector3.new(626,258,-552),
	["White Tower (Quiet Field)"]     = Vector3.new(2092,121,-458),
}

local VENDOR_TP = {
	["Amy Thistlewitch"] = Vector3.new(-2937,228,-665),
	["Arbewhy"]          = Vector3.new(-2939,230,-1156),
	["Archaeologist"]    = Vector3.new(1553,72,-1632),
}

-- ===================== RAYFIELD INIT =====================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "FF Hub",
	LoadingTitle = "FF Hub",
	LoadingSubtitle = "by SeventhBuilder",
	Theme = "Default",
	ConfigurationSaving = {Enabled = true, FileName = "FFHub_Config"},
	KeySystem = false,
})

local PlayerTab    = Window:CreateTab("Player",    5012544693)
local TeleportsTab = Window:CreateTab("Teleports", 5012543481)
local FeaturesTab  = Window:CreateTab("Features",  5012544092)
local AutoFarmTab  = Window:CreateTab("AutoFarm",  5012543246)
local ESPTab       = Window:CreateTab("ESP",       5012543246)
local ShopsTab     = Window:CreateTab("Shops",     5012544372)
local SettingsTab  = Window:CreateTab("Settings",  5012544372)

StarterGui:SetCore("SendNotification", {Title = "FF Hub", Text = "Loaded! by SeventhBuilder"})

-- ===================== PRESENT FINDER =====================
local LatestPresent = nil

local function markPresent(part)
	if part:FindFirstChild("parttrace") then return end
	local epic = Instance.new("Part")
	epic.Name = "parttrace"
	epic.Parent = part
	epic.Position = part.Position
	epic.Size = Vector3.new(0.3,0.3,0.3)
	epic.Anchored = true
	epic.Transparency = 1
	epic.CanCollide = false

	local billgui = Instance.new("BillboardGui", epic)
	billgui.Name = "ESP"
	billgui.Adornee = epic
	billgui.AlwaysOnTop = true
	billgui.ExtentsOffset = Vector3.new(0,1,0)
	billgui.Size = UDim2.new(0,200,0,50)

	local textlab = Instance.new("TextLabel", billgui)
	textlab.BackgroundTransparency = 1
	textlab.Size = UDim2.new(1,0,1,0)
	textlab.Font = Enum.Font.GothamBold
	textlab.TextSize = 18
	textlab.Text = "🎁 PRESENT"
	textlab.TextColor3 = Color3.fromRGB(255,80,80)
	textlab.TextStrokeTransparency = 0.4
	textlab.TextStrokeColor3 = Color3.new(0,0,0)
	textlab.ZIndex = 10
end

-- BindableFunction lets the OS notification button actually teleport (from old script)
local presentBindable = Instance.new("BindableFunction")
presentBindable.OnInvoke = function()
	if LatestPresent and LatestPresent.Parent then
		goto(LatestPresent.Position)
		Rayfield:Notify({Title="Teleported!", Content="Arrived at present.", Duration=3})
	else
		Rayfield:Notify({Title="Error", Content="Present no longer exists.", Duration=3})
	end
end

local function onPresentFound(present)
	repeat task.wait() until present:FindFirstChild("PP")
	local part = present:FindFirstChildOfClass("Part")
	if not part then return end
	markPresent(part)
	LatestPresent = part

	if notif.present then
		-- This fires the OS notification with a teleport button (old script style)
		StarterGui:SetCore("SendNotification", {
			Title    = "🎁 Present Found!",
			Text     = "A new present has spawned!",
			Icon     = "rbxassetid://1053360438",
			Duration = 8,
			Callback = presentBindable,
			Button1  = "Teleport to Present",
		})
	end
end

-- Scan existing and watch for new presents
for _, child in pairs(Workspace:GetChildren()) do
	if string.sub(string.lower(child.Name),1,7) == "present" and string.len(child.Name) == 8 then
		task.spawn(onPresentFound, child)
	end
end
Workspace.ChildAdded:Connect(function(child)
	if string.sub(string.lower(child.Name),1,7) == "present" and string.len(child.Name) == 8 then
		task.spawn(onPresentFound, child)
	end
end)

-- ===================== FEATURES TAB =====================
FeaturesTab:CreateSection("Present Finder")

FeaturesTab:CreateToggle({
	Name = "Present Notifications",
	CurrentValue = true,
	Flag = "PresentNotif",
	Callback = function(v)
		notif.present = v
		Rayfield:Notify({Title="Present Finder", Content=v and "Notifications ON" or "Notifications OFF", Duration=3})
	end
})
FeaturesTab:CreateButton({
	Name = "Teleport to Latest Present",
	Callback = function()
		if LatestPresent and LatestPresent.Parent then
			goto(LatestPresent.Position)
			Rayfield:Notify({Title="Success", Content="Teleported to present!", Duration=3})
		else
			Rayfield:Notify({Title="No Present", Content="No present detected yet.", Duration=4})
		end
	end
})

FeaturesTab:CreateSection("NPC Finders")

FeaturesTab:CreateToggle({
	Name = "Frog Finder Notifications",
	CurrentValue = true,
	Flag = "FrogNotif",
	Callback = function(v)
		notif.frog = v
		Rayfield:Notify({Title="Frog Finder", Content=v and "Notifications ON" or "Notifications OFF", Duration=3})
	end
})
FeaturesTab:CreateButton({Name = "Get Grateful Frog", Callback = function()
	local spawner = Workspace.Spawners["The Sprutle Frog Expansion_Updated"]
	if not spawner then
		if notif.frog then Rayfield:Notify({Title="Frog Finder", Content="Frog spawner not found.", Duration=3}) end
		return
	end
	local frogSpawner = spawner:FindFirstChild("Spawner_GratefulFrogs")
	if not frogSpawner then
		if notif.frog then Rayfield:Notify({Title="Frog Finder", Content="No frog spawner.", Duration=3}) end
		return
	end
	if frogSpawner:FindFirstChild("Collectible") then
		local part = frogSpawner.Collectible:FindFirstChildWhichIsA("BasePart")
		if part then
			if notif.frog then Rayfield:Notify({Title="Frog Finder", Content="Frog found! Teleporting...", Duration=3}) end
			goto(part.Position)
			for p = 1, 50 do
				task.wait()
				if frogSpawner:FindFirstChild("Collectible") and frogSpawner.Collectible:FindFirstChild("InteractEvent") then
					frogSpawner.Collectible.InteractEvent:FireServer()
				end
			end
			if notif.frog then Rayfield:Notify({Title="Frog Finder", Content="Collection attempt done!", Duration=3}) end
		else
			-- Frog not loaded yet — move around spawn to load it
			if notif.frog then
				Rayfield:Notify({Title="Frog Finder", Content="Frog present but not loaded. Moving to spawn...", Duration=5})
			end
			repeat
				local spawnBrick = frogSpawner.SpawnLocations:FindFirstChild("SpawnBrick")
				if not spawnBrick then break end
				goto(spawnBrick.Position + Vector3.new(0,10,0))
				task.wait(0.5)
			until frogSpawner.Collectible:FindFirstChildWhichIsA("BasePart")
				or not frogSpawner.SpawnLocations:FindFirstChild("SpawnBrick")

			if frogSpawner.Collectible:FindFirstChildWhichIsA("BasePart") then
				goto(frogSpawner.Collectible:FindFirstChildWhichIsA("BasePart").Position)
				for p = 1, 50 do
					task.wait()
					if frogSpawner:FindFirstChild("Collectible") and frogSpawner.Collectible:FindFirstChild("InteractEvent") then
						frogSpawner.Collectible.InteractEvent:FireServer()
					end
				end
				if notif.frog then Rayfield:Notify({Title="Frog Finder", Content="Frog collected!", Duration=3}) end
			else
				if notif.frog then Rayfield:Notify({Title="Frog Finder", Content="Frog failed to load.", Duration=4}) end
			end
		end
	else
		if notif.frog then Rayfield:Notify({Title="Frog Finder", Content="No frog found.", Duration=3}) end
	end
end})

FeaturesTab:CreateToggle({
	Name = "Cosmic Ghost Notifications",
	CurrentValue = true,
	Flag = "CosmicNotif",
	Callback = function(v)
		notif.cosmic = v
		Rayfield:Notify({Title="Cosmic Ghost", Content=v and "Notifications ON" or "Notifications OFF", Duration=3})
	end
})
FeaturesTab:CreateButton({Name = "Check For Cosmic Ghost", Callback = function()
	local npcs = Workspace:FindFirstChild("NPCS")
	if npcs and npcs:FindFirstChild("CosmicFloatingMonsterHeadNPC") then
		local part = npcs.CosmicFloatingMonsterHeadNPC:FindFirstChildWhichIsA("BasePart", true)
		if part then
			if notif.cosmic then Rayfield:Notify({Title="Cosmic Ghost", Content="Found! Teleporting...", Duration=3}) end
			goto(part.Position + Vector3.new(10,10,10))
		else
			if notif.cosmic then Rayfield:Notify({Title="Cosmic Ghost", Content="Found but not loaded. Move around Matumada.", Duration=5}) end
		end
	else
		if notif.cosmic then Rayfield:Notify({Title="Cosmic Ghost", Content="Cosmic Ghost not found.", Duration=3}) end
	end
end})

FeaturesTab:CreateToggle({
	Name = "Path Gambler Notifications",
	CurrentValue = true,
	Flag = "GamblerNotif",
	Callback = function(v)
		notif.gambler = v
		Rayfield:Notify({Title="Path Gambler", Content=v and "Notifications ON" or "Notifications OFF", Duration=3})
	end
})
FeaturesTab:CreateButton({Name = "Check For Path Gambler", Callback = function()
	local npcs = Workspace:FindFirstChild("NPCS")
	if npcs and npcs:FindFirstChild("PathGamblerNPC") then
		local part = npcs.PathGamblerNPC:FindFirstChildWhichIsA("BasePart", true)
		if part then
			if notif.gambler then Rayfield:Notify({Title="Path Gambler", Content="Found! Teleporting...", Duration=3}) end
			goto(part.Position + Vector3.new(0,4,0))
		else
			if notif.gambler then Rayfield:Notify({Title="Path Gambler", Content="Found but not loaded. Explore Ratboy's Nightmare.", Duration=5}) end
		end
	else
		if notif.gambler then Rayfield:Notify({Title="Path Gambler", Content="Path Gambler not found.", Duration=3}) end
	end
end})

FeaturesTab:CreateSection("Performance")

FeaturesTab:CreateButton({Name = "Remove All Trees", Callback = function()
	local trees = {"PostTrees", "Tree_A_1", "Tree_B_1", "Tree_B_2", "Tree_C_1", "Tree_D_1", "Tree_D_2"}
	for _, obj in pairs(Workspace:GetDescendants()) do
		for _, name in pairs(trees) do
			if obj.Name == name then
				obj:Destroy()
			end
		end
	end
	Rayfield:Notify({Title="Status", Content="All trees removed!", Duration=3})
end})

FeaturesTab:CreateButton({Name = "Remove All Vegetation ", Callback = function()
	local vegetations = {"GrassyRootSystemPart", "BushLeafPart", "LilyPadPart", "FlowerPart", "BushPart", "CropPartSQ", "GrassPart", "TallGrassPartSmall", "DeadShrubPart", "PlantPart", "Trunk", "Root", "Leaves", "LeafPart", "WeedPart"}
	for _, obj in pairs(Workspace:GetDescendants()) do
		for _, name in pairs(vegetations) do
			-- if obj.Parent:IsA("Model") and obj.Parent.Name == "Model" then
			-- 	obj.Parent:Destroy()
			-- end
			if obj.Name == name then
				obj:Destroy()
			end
		end
		if obj:IsA("MeshPart") and obj.MeshId == "rbxassetid://511992639" then
			obj:Destroy()	
		end
	end
	Rayfield:Notify({Title="Status", Content="All vegetation removed!", Duration=3})
end})

FeaturesTab:CreateButton({Name = "Remove All Rocks", Callback = function()
	local rocks = {"LargeRockPart", "RockPart"} --, "Rock_A_1", "Rock_A_2", "Rock_A_3"}
	for _, obj in pairs(Workspace:GetDescendants()) do
		for _, name in pairs(rocks) do
			if obj.Name == name then
				obj:Destroy()
			end
		end
	end
	Rayfield:Notify({Title="Status", Content="All rocks removed!", Duration=3})
end})

FeaturesTab:CreateSection("Abilities")

FeaturesTab:CreateButton({Name = "Remove Fog", Callback = function()
	pcall(function()
		if speaker.PlayerScripts:FindFirstChild("Fog") then
			speaker.PlayerScripts.Fog:Destroy()
		end
		if speaker.Character:FindFirstChild("Fogbox") then
			for _, ring in pairs({"Ring1","Ring2","Ring3"}) do
				local r = speaker.Character.Fogbox:FindFirstChild(ring)
				if r then r:Destroy() end
			end
		end
	end)
	Rayfield:Notify({Title="Status", Content="Fog removed!", Duration=3})
end})

FeaturesTab:CreateButton({Name = "Faster Kills", Callback = function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/SeventhBuilder/FF/main/scripts/faster-kills.lua"))()
end})
FeaturesTab:CreateButton({Name = "Fast Regen Stamina", Callback = function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/SeventhBuilder/FF/main/scripts/fast-regen-stamina.lua"))()
end})
FeaturesTab:CreateButton({Name = "Bring Spider Boss Closer", Callback = function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/JustApstl/FF/refs/heads/main/scripts/bring-spider-boss-closer-to-topple-town.lua"))()
end})
FeaturesTab:CreateButton({Name = "Teleport to Uncollected Ratboy Token", Callback = function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/JustApstl/FF/refs/heads/main/scripts/teleport-to-uncollected-ratboy-token.lua"))()
end})

-- ===================== AUTOFARM TAB =====================
AutoFarmTab:CreateSection("Firefly Stones")
AutoFarmTab:CreateToggle({
	Name = "Firefly Notifications",
	CurrentValue = true,
	Flag = "FireflyNotif",
	Callback = function(v) notif.firefly = v end
})
AutoFarmTab:CreateToggle({
	Name = "Firefly Stones AutoFarm",
	CurrentValue = false,
	Flag = "FireflyFarm",
	Callback = function(v)
		ffarm = v
		if v then
			checkTP()
			if notif.firefly then Rayfield:Notify({Title="AutoFarm", Content="Firefly Stones ENABLED", Duration=3}) end
		else
			if notif.firefly then Rayfield:Notify({Title="AutoFarm", Content="Firefly Stones DISABLED", Duration=3}) end
		end
	end
})

AutoFarmTab:CreateSection("Bird Nests")
AutoFarmTab:CreateToggle({
	Name = "Bird Nest Notifications",
	CurrentValue = true,
	Flag = "BirdNotif",
	Callback = function(v) notif.birdnest = v end
})
AutoFarmTab:CreateToggle({
	Name = "Bird Nests AutoFarm",
	CurrentValue = false,
	Flag = "BirdFarm",
	Callback = function(v)
		bfarm = v
		if v then
			goto(Vector3.new(-1405,325,-2271))
			task.wait(1)
			checkTP()
			if notif.birdnest then Rayfield:Notify({Title="AutoFarm", Content="Bird Nests ENABLED", Duration=3}) end
		else
			Rayfield:Notify({Title="AutoFarm", Content="Bird Nests DISABLED", Duration=3})
		end
	end
})

AutoFarmTab:CreateSection("Deli")
AutoFarmTab:CreateDropdown({
	Name = "Deli AutoFarm Mode",
	Options = {"Both (Random)", "Short Wait", "Long Wait"},
	CurrentOption = {"Both (Random)"},
	Flag = "DeliMode",
	Callback = function(opt)
		local mode = opt[1]
		if mode == "Short Wait" then
			shortwait = true; longwait = false; randomboth = false
		elseif mode == "Long Wait" then
			longwait = true; shortwait = false; randomboth = false
		else
			randomboth = true; shortwait = false; longwait = false
		end
		Rayfield:Notify({Title="Deli", Content="Mode: "..mode, Duration=3})
	end
})
AutoFarmTab:CreateToggle({
	Name = "Deli AutoFarm",
	CurrentValue = false,
	Flag = "DeliFarm",
	Callback = function(v)
		dfarm = v
		if v then
			goto(Vector3.new(7066,144,-1621))
			task.wait(3)
			Rayfield:Notify({Title="AutoFarm", Content="Deli ENABLED", Duration=3})
		else
			Rayfield:Notify({Title="AutoFarm", Content="Deli DISABLED", Duration=3})
		end
	end
})

-- Lost is patched currently - will look for alternative soon
AutoFarmTab:CreateSection("The Lost (Requires Hidden Key)")
AutoFarmTab:CreateToggle({
	Name = "Lost AutoFarm(PATCHED)",
	CurrentValue = false,
	Flag = "LostFarm",
	Callback = function(v)
		if v then
			-- Verify Hidden Key in inventory
			local hasKey = false
			pcall(function()
				local invFrame = Players.LocalPlayer.PlayerGui.Container.Main["INV_SF"]
				for _, item in pairs(invFrame:GetDescendants()) do
					if item.Name == "ItemCode" and item.Value == 2025 then
						hasKey = true
						break
					end
				end
			end)
			if hasKey then
				amountEmptyInventory = 20
				lfarm = true
				goto(Vector3.new(5857,157,4907))
				task.wait(1.5)
				Rayfield:Notify({Title="AutoFarm", Content="Lost Farm ENABLED", Duration=3})
			else
				lfarm = false
				Rayfield:Notify({Title="AutoFarm", Content="❌ Hidden Key required! Farm not started.", Duration=5})
			end
		else
			lfarm = false
			amountEmptyInventory = 20
			Rayfield:Notify({Title="AutoFarm", Content="Lost Farm DISABLED", Duration=3})
		end
	end
})

-- ===================== TELEPORTS TAB =====================
TeleportsTab:CreateSection("Overworld")
TeleportsTab:CreateDropdown({
	Name = "Overworld Teleports",
	Options = {
		"A Frontier Of Dragons","Abandoned Orchard","Ancient Forest","Blackrock Mountain",
		"Blue Ogre Camp","Celestial Field","Celestial Peak","Clamstack Cave","Coral Bay",
		"Farm Fortress","Frigid Waste (PvP)","Gnome Magic School","Great Pine Forest",
		"Greenhorn Grove","Hoodlum Falls","Matumada","Otherworld Tower","Pebble Bay",
		"Petrified Grassland","Pit Depths","Rabbit Hole","Red Ant Cove","Rubble Spring",
		"Starry Point","Strangeman's Domain","The Deep Forest","The Forgotten Lands",
		"The Long Coast","The Maze Wood","The Pits","The Quiet Field","The Rolling Road",
		"The Spider's Nest","The Town of Right and Wrong","Topple Hill","Topple Lake",
		"Topple Town","Twinkling Meadow","Upper Island"
	},
	CurrentOption = {""},
	MultipleOptions = false,
	Callback = function(opt)
		if OVERWORLD_TP[opt[1]] then goto(OVERWORLD_TP[opt[1]]) end
	end
})

TeleportsTab:CreateSection("Ratboy's Nightmare")
TeleportsTab:CreateDropdown({
	Name = "Ratboy's Nightmare Teleports",
	Options = {
		"Back of The Theatre","Blue Button","Blue Door","Cyan (Teal) Button","Cyan (Teal) Door",
		"End of the Road","Fish Hall","Green Button","Green Door","Inside","Maze of the Root",
		"Meeting Place","MYSTERY STORE","Orange Button","Orange Door","Pink Button","Pink Door",
		"Purple Button","Purple Door","Red Button","Red Door","The Back Area","The Ballroom",
		"The Deli","The Grand Hall","The Hidden Library","The Library of Riddles","The Lost",
		"The Mansion","The Old Cave","The Old Mansion","The Plant Room","The Road",
		"The Supermarket","The Theatre","The Vault","Waiting Room","Yellow Button","Yellow Door"
	},
	CurrentOption = {""},
	MultipleOptions = false,
	Callback = function(opt)
		if RATBOY_TP[opt[1]] then goto(RATBOY_TP[opt[1]]) end
	end
})

TeleportsTab:CreateSection("Housing & Vendors")
TeleportsTab:CreateDropdown({
	Name = "Housing Teleports",
	Options = {
		"Black Tower (Celestial Field)","Boathouse (Long Coast)","Castle (Topple Town)",
		"Ice Spire (Matumada)","Starter House (Topple Town)","Two Story House (Topple Town)",
		"White Tower (Quiet Field)"
	},
	CurrentOption = {""},
	MultipleOptions = false,
	Callback = function(opt)
		if HOUSING_TP[opt[1]] then goto(HOUSING_TP[opt[1]]) end
	end
})
TeleportsTab:CreateDropdown({
	Name = "Vendor Teleports",
	Options = {"Amy Thistlewitch","Arbewhy","Archaeologist"},
	CurrentOption = {""},
	MultipleOptions = false,
	Callback = function(opt)
		if VENDOR_TP[opt[1]] then goto(VENDOR_TP[opt[1]]) end
	end
})

-- ===================== PLAYER TAB =====================
PlayerTab:CreateSection("Movement")
PlayerTab:CreateSlider({Name="Walk Speed",  Range={0,100}, Increment=1,   CurrentValue=18,    Flag="WalkSpeed",  Callback=function(v) walkspeed=v end})
PlayerTab:CreateSlider({Name="Jump Power",  Range={0,300}, Increment=1,   CurrentValue=81.5,  Flag="JumpPower",  Callback=function(v) jumppower=v end})
PlayerTab:CreateSlider({Name="Gravity",     Range={0,900}, Increment=1,   CurrentValue=196.2, Flag="Gravity",    Callback=function(v) gravity=v end})
PlayerTab:CreateSlider({Name="Slope Angle", Range={0,90},  Increment=1,   CurrentValue=56,    Flag="SlopeAngle", Callback=function(v) sangle=v end})
PlayerTab:CreateSlider({Name="Fly Speed",   Range={1,100}, Increment=1,   CurrentValue=1,     Flag="FlySpeed",   Callback=function(v) flyspeed=v; iyflyspeed=v end})

PlayerTab:CreateToggle({Name="Noclip", CurrentValue=false, Flag="Noclip", Callback=function(v)
	Clip = not v
	if v then
		Noclipping = RunService.Stepped:Connect(function()
			if not Clip and speaker.Character then
				for _, child in pairs(speaker.Character:GetDescendants()) do
					if child:IsA("BasePart") and child.CanCollide then
						child.CanCollide = false
					end
				end
			end
		end)
	else
		if Noclipping then Noclipping:Disconnect() end
	end
end})

PlayerTab:CreateToggle({Name="Fly", CurrentValue=false, Flag="Fly", Callback=function(v)
	if v then NOFLY() task.wait() sFLY()
	else NOFLY() end
end})

PlayerTab:CreateSection("Tools")
PlayerTab:CreateButton({Name="Telekinesis", Callback=function()

	-- Q & E - bring closer and further
	-- R - Roates Block
	-- T - Tilts Block
	-- Y - Throws Block
	local function a(b, c)
		local d = getfenv(c)
		local e =
			setmetatable(
				{},
				{__index = function(self, f)
					if f == "script" then
					return b
				else
					return d[f]
				end
				end}
			)
		setfenv(c, e)
		return c
	end
	local g = {}
	local h = Instance.new("Model", Lighting)
	local i = Instance.new("Tool")
	local j = Instance.new("Part")
	local k = Instance.new("Script")
	local l = Instance.new("LocalScript")
	local m = sethiddenproperty or set_hidden_property
	i.Name = "Telekinesis"
	i.Parent = h
	i.Grip = CFrame.new(0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0)
	i.GripForward = Vector3.new(-0, -1, -0)
	i.GripRight = Vector3.new(0, 0, 1)
	i.GripUp = Vector3.new(1, 0, 0)
	j.Name = "Handle"
	j.Parent = i
	j.CFrame = CFrame.new(-17.2635937, 15.4915619, 46, 0, 1, 0, 1, 0, 0, 0, 0, -1)
	j.Orientation = Vector3.new(0, 180, 90)
	j.Position = Vector3.new(-17.2635937, 15.4915619, 46)
	j.Rotation = Vector3.new(-180, 0, -90)
	j.Color = Color3.new(0.0666667, 0.0666667, 0.0666667)
	j.Transparency = 1
	j.Size = Vector3.new(1, 1.20000005, 1)
	j.BottomSurface = Enum.SurfaceType.Weld
	j.BrickColor = BrickColor.new("Really black")
	j.Material = Enum.Material.Metal
	j.TopSurface = Enum.SurfaceType.Smooth
	j.brickColor = BrickColor.new("Really black")
	k.Name = "LineConnect"
	k.Parent = i
	table.insert(
		g,
		a(
			k,
			function()
				task.wait()
				local n = script.Part2
				local o = script.Part1.Value
				local p = script.Part2.Value
				local q = script.Par.Value
				local color = script.Color
				local r = Instance.new("Part")
				r.TopSurface = 0
				r.BottomSurface = 0
				r.Reflectance = .5
				r.Name = "Laser"
				r.Locked = true
				r.CanCollide = false
				r.Anchored = true
				r.formFactor = 0
				r.Size = Vector3.new(1, 1, 1)
				local s = Instance.new("BlockMesh")
				s.Parent = r
				while true do
					if n.Value == nil then
						break
					end
					if o == nil or p == nil or q == nil then
						break
					end
					if o.Parent == nil or p.Parent == nil then
						break
					end
					if q.Parent == nil then
						break
					end
					local t = CFrame.new(o.Position, p.Position)
					local dist = (o.Position - p.Position).magnitude
					r.Parent = q
					r.BrickColor = color.Value.BrickColor
					r.Reflectance = color.Value.Reflectance
					r.Transparency = color.Value.Transparency
					r.CFrame = CFrame.new(o.Position + t.lookVector * dist / 2)
					r.CFrame = CFrame.new(r.Position, p.Position)
					s.Scale = Vector3.new(.25, .25, dist)
					task.wait()
				end
				r:remove()
				script:remove()
			end
		)
	)
	k.Disabled = true
	l.Name = "MainScript"
	l.Parent = i
	table.insert(
		g,
		a(
			l,
			function()
				task.wait()
				tool = script.Parent
				lineconnect = tool.LineConnect
				object = nil
				mousedown = false
				found = false
				BP = Instance.new("BodyPosition")
				BP.maxForce = Vector3.new(math.huge * math.huge, math.huge * math.huge, math.huge * math.huge)
				BP.P = BP.P * 1.1
				dist = nil
				point = Instance.new("Part")
				point.Locked = true
				point.Anchored = true
				point.formFactor = 0
				point.Shape = 0
				point.BrickColor = BrickColor.Black()
				point.Size = Vector3.new(1, 1, 1)
				point.CanCollide = false
				local s = Instance.new("SpecialMesh")
				s.MeshType = "Sphere"
				s.Scale = Vector3.new(.7, .7, .7)
				s.Parent = point
				handle = tool.Handle
				front = tool.Handle
				color = tool.Handle
				objval = nil
				local u = false
				local v = BP:clone()
				v.maxForce = Vector3.new(30000, 30000, 30000)
				function LineConnect(o, p, q)
					local w = Instance.new("ObjectValue")
					w.Value = o
					w.Name = "Part1"
					local x = Instance.new("ObjectValue")
					x.Value = p
					x.Name = "Part2"
					local y = Instance.new("ObjectValue")
					y.Value = q
					y.Name = "Par"
					local z = Instance.new("ObjectValue")
					z.Value = color
					z.Name = "Color"
					local A = lineconnect:clone()
					A.Disabled = false
					w.Parent = A
					x.Parent = A
					y.Parent = A
					z.Parent = A
					A.Parent = workspace
					if p == object then
						objval = x
					end
				end
				function onButton1Down(B)
					if mousedown == true then
						return
					end
					mousedown = true
					coroutine.resume(
						coroutine.create(
							function()
								local C = point:clone()
								C.Parent = tool
								LineConnect(front, C, workspace)
								while mousedown == true do
									C.Parent = tool
									if object == nil then
										if B.Target == nil then
											local t = CFrame.new(front.Position, B.Hit.p)
											C.CFrame = CFrame.new(front.Position + t.lookVector * 1000)
										else
											C.CFrame = CFrame.new(B.Hit.p)
										end
									else
										LineConnect(front, object, workspace)
										break
									end
									task.wait()
								end
								C:remove()
							end
						)
					)
					while mousedown == true do
						if B.Target ~= nil then
							local D = B.Target
							if D.Anchored == false then
								object = D
								dist = (object.Position - front.Position).magnitude
								break
							end
						end
						task.wait()
					end
					while mousedown == true do
						if object.Parent == nil then
							break
						end
						local t = CFrame.new(front.Position, B.Hit.p)
						BP.Parent = object
						BP.position = front.Position + t.lookVector * dist
						task.wait()
					end
					BP:remove()
					object = nil
					objval.Value = nil
				end
				function onKeyDown(E, B)
					local E = E:lower()
					local F = false
					if E == "q" then
						if dist >= 5 then
							dist = dist - 10
						end
					end
					if E == "r" then
						if object == nil then
							return
						end
						for G, H in pairs(object:children()) do
							if H.className == "BodyGyro" then
								return nil
							end
						end
						BG = Instance.new("BodyGyro")
						BG.maxTorque = Vector3.new(math.huge, math.huge, math.huge)
						BG.cframe = CFrame.new(object.CFrame.p)
						BG.Parent = object
						repeat
							task.wait()
						until object.CFrame == CFrame.new(object.CFrame.p)
						BG.Parent = nil
						if object == nil then
							return
						end
						for G, H in pairs(object:children()) do
							if H.className == "BodyGyro" then
								H.Parent = nil
							end
						end
						object.Velocity = Vector3.new(0, 0, 0)
						object.RotVelocity = Vector3.new(0, 0, 0)
						object.Orientation = Vector3.new(0, 0, 0)
					end
					if E == "e" then
						dist = dist + 10
					end
					if E == "t" then
						if dist ~= 10 then
							dist = 10
						end
					end
					if E == "y" then
						if dist ~= 200 then
							dist = 200
						end
					end
					if E == "=" then
						BP.P = BP.P * 1.5
					end
					if E == "-" then
						BP.P = BP.P * 0.5
					end
				end
				function onEquipped(B)
					keymouse = B
					local I = tool.Parent
					human = I.Humanoid
					human.Changed:connect(
						function()
							if human.Health == 0 then
								mousedown = false
								BP:remove()
								point:remove()
								tool:remove()
							end
						end
					)
					B.Button1Down:connect(
						function()
							onButton1Down(B)
						end
					)
					B.Button1Up:connect(
						function()
							mousedown = false
						end
					)
					B.KeyDown:connect(
						function(E)
							onKeyDown(E, B)
						end
					)
					B.Icon = "rbxasset://textures\\GunCursor.png"
				end
				tool.Equipped:connect(onEquipped)
			end
		)
	)
	for J, H in pairs(h:GetChildren()) do
		H.Parent = Players.LocalPlayer.Backpack
		pcall(
			function()
				H:MakeJoints()
			end
		)
	end
	h:Destroy()
	for J, H in pairs(g) do
		spawn(
			function()
				pcall(H)
			end
		)
	end
	Rayfield:Notify({Title="Telekinesis", Content="Telekinesis added to backpack!", Duration=3})
end})

PlayerTab:CreateButton({Name="B-Tools", Callback=function()
	for _, v in pairs(Workspace:GetDescendants()) do
		if v:IsA("BasePart") then v.Locked = false end
	end
	for i = 1, 4 do
		local Tool = Instance.new("HopperBin")
		Tool.BinType = i
		Tool.Parent = speaker:FindFirstChildOfClass("Backpack")
	end
	Rayfield:Notify({Title="B-Tools", Content="Tools added to backpack!", Duration=3})
end})

PlayerTab:CreateButton({Name="Infinite Yield", Callback=function()
	loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end})

-- ===================== ESP TAB =====================
local spawnersFolder = Workspace.Spawners

-- Cleanup leftover ESP on script load
for _, v in pairs(spawnersFolder:GetDescendants()) do
	if v.Name == "PlantBoxHandleAdornment" or v.Name == "PlantBeam" then v:Destroy() end
end

ESPTab:CreateSection("Plant ESP")
ESPTab:CreateToggle({Name="Plant ESP", CurrentValue=false, Flag="PlantESP", Callback=function(v)
	pESP = v
	if not v then
		for _, item in pairs(spawnersFolder:GetDescendants()) do
			if item.Name == "PlantBoxHandleAdornment" or item.Name == "PlantBeam" then
				item:Destroy()
			end
		end
	end
	Rayfield:Notify({Title="Plant ESP", Content=v and "Enabled" or "Disabled", Duration=3})
end})
ESPTab:CreateInput({
	Name = "Add Plant",
	PlaceholderText = "Plant name...",
	RemoveTextAfterFocus = true,
	Callback = function(value)
		if value and value ~= "" then
			local found = false
			for _, v in pairs(ReplicatedStorage.ItemInfo:GetDescendants()) do
				if v.Name == "FullName" and string.lower(v.Value) == string.lower(value) then
					local id = tonumber(v.Parent.Name)
					if not table.find(plants, id) then
						table.insert(plants, id)
						table.insert(plantNames, v.Value)
						table.insert(loweredPlantNames, string.lower(v.Value))
						Rayfield:Notify({Title="Plant ESP", Content="Added: "..v.Value, Duration=3})
					else
						Rayfield:Notify({Title="Plant ESP", Content="Already tracking: "..v.Value, Duration=3})
					end
					found = true
					break
				end
			end
			if not found then
				Rayfield:Notify({Title="Plant ESP", Content="Plant not found: "..value, Duration=3})
			end
		end
	end
})
ESPTab:CreateInput({
	Name = "Remove Plant",
	PlaceholderText = "Plant name...",
	RemoveTextAfterFocus = true,
	Callback = function(value)
		if value and value ~= "" then
			for _, v in pairs(ReplicatedStorage.ItemInfo:GetDescendants()) do
				if v.Name == "FullName" and string.lower(v.Value) == string.lower(value) then
					local id = tonumber(v.Parent.Name)
					local idx = table.find(plants, id)
					if idx then
						table.remove(plants, idx)
						local n = table.find(plantNames, v.Value)
						if n then table.remove(plantNames, n) end
						local l = table.find(loweredPlantNames, string.lower(v.Value))
						if l then table.remove(loweredPlantNames, l) end
						-- Clean rendered ESPs
						for _, item in pairs(spawnersFolder:GetDescendants()) do
							if item.Name == "PlantBoxHandleAdornment" or item.Name == "PlantBeam" then
								item:Destroy()
							end
						end
						Rayfield:Notify({Title="Plant ESP", Content="Removed: "..v.Value, Duration=3})
					end
					break
				end
			end
		end
	end
})

-- ===================== SHOPS TAB =====================
ShopsTab:CreateSection("Item Browser")
ShopsTab:CreateButton({Name="Refresh All Shops", Callback=function()
	repeat task.wait(0.05) until Workspace:FindFirstChild("Shops")
	for _, shop in pairs(Workspace.Shops:GetChildren()) do
		if shop:FindFirstChild("Slots") then
			local lines = {}
			for _, slot in pairs(shop.Slots:GetChildren()) do
				for _, item in pairs(ReplicatedStorage.ItemInfo:GetChildren()) do
					if tonumber(item.Name) == tonumber(slot.Item.Value) then
						table.insert(lines, item.FullName.Value.." — "..slot.Price.Value.."g")
					end
				end
			end
			if #lines > 0 then
				Rayfield:Notify({
					Title   = shop.Name,
					Content = table.concat(lines, "\n"),
					Duration = 12,
				})
				task.wait(0.3)
			end
		end
	end
end})

-- ===================== SETTINGS TAB =====================
SettingsTab:CreateSection("UI")
SettingsTab:CreateDropdown({
	Name = "Theme",
	Options = {"Default","Ocean","AmberGlow","Light","Amethyst","Green","Bloom","DarkBlue","Serenity"},
	CurrentOption = {"Default"},
	Flag = "Theme",
	Callback = function(opt) Window:SetTheme(opt[1]) end
})

SettingsTab:CreateSection("Exit")
SettingsTab:CreateButton({Name = "Exit Hub", Callback = function()
	getgenv().scriptRunning = false
	-- Stop all farms
	ffarm = false; bfarm = false; dfarm = false; lfarm = false; pESP = false
	plants = {}; plantNames = {}; loweredPlantNames = {}
	-- Reset humanoid
	pcall(function()
		local hum = speaker.Character:FindFirstChildWhichIsA("Humanoid")
		if hum then hum.WalkSpeed=16; hum.JumpPower=50; hum.MaxSlopeAngle=89 end
		Workspace.Gravity = 196.2
		NOFLY()
		if Noclipping then Noclipping:Disconnect() end
	end)
	-- Clean ESPs
	for _, v in pairs(spawnersFolder:GetDescendants()) do
		if v.Name == "PlantBoxHandleAdornment" or v.Name == "PlantBeam" then v:Destroy() end
	end
	Rayfield:Destroy()
end})

-- ===================== FLY FUNCTIONS =====================
function sFLY()
	repeat task.wait() until speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
	if flyKeyDown then flyKeyDown:Disconnect() end
	if flyKeyUp then flyKeyUp:Disconnect() end

	local T = speaker.Character.HumanoidRootPart
	local CONTROL = {F=0,B=0,L=0,R=0}
	local SPEED = 0
	local BG = Instance.new("BodyGyro")
	local BV = Instance.new("BodyVelocity")
	BG.P = 9e4
	BG.maxTorque = Vector3.new(9e9,9e9,9e9)
	BG.Parent = T
	BV.maxForce = Vector3.new(9e9,9e9,9e9)
	BV.Parent = T
	FLYING = true

	local hum = speaker.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = true end

	flyKeyDown = Mouse.KeyDown:Connect(function(KEY)
		KEY = KEY:lower()
		if     KEY=="w" then CONTROL.F = iyflyspeed
		elseif KEY=="s" then CONTROL.B = -iyflyspeed
		elseif KEY=="a" then CONTROL.L = -iyflyspeed
		elseif KEY=="d" then CONTROL.R = iyflyspeed
		end
	end)
	flyKeyUp = Mouse.KeyUp:Connect(function(KEY)
		KEY = KEY:lower()
		if     KEY=="w" then CONTROL.F=0
		elseif KEY=="s" then CONTROL.B=0
		elseif KEY=="a" then CONTROL.L=0
		elseif KEY=="d" then CONTROL.R=0
		end
	end)

	task.spawn(function()
		repeat task.wait()
			iyflyspeed = flyspeed
			if CONTROL.L+CONTROL.R ~= 0 or CONTROL.F+CONTROL.B ~= 0 then SPEED=50 else SPEED=0 end
			BV.velocity = (
				(Workspace.CurrentCamera.CoordinateFrame.lookVector * (CONTROL.F+CONTROL.B))
				+ ((Workspace.CurrentCamera.CoordinateFrame * CFrame.new(CONTROL.L+CONTROL.R,0,0).Position)
				   - Workspace.CurrentCamera.CoordinateFrame.Position)
			) * SPEED
			BG.CFrame = Workspace.CurrentCamera.CoordinateFrame
		until not FLYING
		BG:Destroy()
		BV:Destroy()
		local h2 = speaker.Character and speaker.Character:FindFirstChildOfClass("Humanoid")
		if h2 then h2.PlatformStand = false end
	end)
end

function NOFLY()
	FLYING = false
	if flyKeyDown then flyKeyDown:Disconnect() end
	if flyKeyUp then flyKeyUp:Disconnect() end
	local hum = speaker.Character and speaker.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.PlatformStand = false end
end

-- ===================== MAIN LOOPS =====================

-- Stats + basic logic loop
task.spawn(function()
	while getgenv().scriptRunning do
		task.wait()
		local hum = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
		if hum then
			hum.MaxSlopeAngle = sangle
			hum.WalkSpeed = walkspeed
			hum.JumpPower = jumppower
		end
		Workspace.Gravity = gravity
	end
end)

-- AutoFarm loop (Firefly, Bird Nest, Deli)
task.spawn(function()
	while getgenv().scriptRunning do
		task.wait()

		-- Firefly
		if ffarm then
			local fly = Workspace.Fireflies:FindFirstChild("FireflyServer")
			if fly then gotofirefly(fly) end
			task.wait(0.1)
		end

		-- Deli
		if dfarm then
			sitAtDeliBooth()
			hideNotifications()
			ringBell()
			hideDialogs()
			skipInitialDeliDialog()
			pcall(function()
				if Workspace.Deli.Booth1:FindFirstChild("WaiterLocation") then
					if shortwait then
						Workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C1.D1.E.RE1:FireServer()
						hideDialogs()
					elseif longwait then
						Workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C2.D1.E.RE2:FireServer()
						hideDialogs()
					elseif randomboth then
						task.wait(0.05)
						Workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C2.D1.E.RE2:FireServer()
						hideDialogs()
						task.wait(0.05)
						Workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C1.D1.E.RE1:FireServer()
						hideDialogs()
						task.wait(0.05)
					end
				end
			end)
		end

		-- Bird Nest
		if bfarm then
			local birdSpawner = Workspace.Spawners.Island:FindFirstChild("Spawner_BirdsNest")
			if birdSpawner then
				if birdSpawner:FindFirstChild("Collectible") then
					local part = birdSpawner.Collectible:FindFirstChildWhichIsA("BasePart")
					if part then
						if notif.birdnest then Rayfield:Notify({Title="Bird Nests", Content="Nest found! Collecting...", Duration=3}) end
						goto(part.Position)
						task.wait(0.05)
						birdSpawner.Collectible.InteractEvent:FireServer()
						for i = 0, 50 do
							ReplicatedStorage.Events.OpenSlot:FireServer(i)
						end
						task.wait(3)
					else
						if notif.birdnest then Rayfield:Notify({Title="Bird Nests", Content="Nest not loaded. Moving to spawn...", Duration=3}) end
						for i = 0, 50 do ReplicatedStorage.Events.OpenSlot:FireServer(i) end
						local spawnBrick = birdSpawner.SpawnLocations:FindFirstChild("SpawnBrick")
						if spawnBrick then
							birdSpawner.SpawnLocations.SpawnBrick.Name = "lol"
							goto(birdSpawner.SpawnLocations:FindFirstChild("lol").Position + Vector3.new(0,10,0))
						end
						task.wait(3)
					end
				else
					task.wait(3)
				end
			end
		end
	end
end)

-- Lost AutoFarm loop
task.spawn(function()
	while getgenv().scriptRunning do
		task.wait()
		if lfarm then
			amountEmptyInventory = 20
			task.wait(0.3)
			for i = 0, 100, 10 do
				task.wait()
				pcall(function()
					Workspace.Guttermouth["Door_GuttermouthPhantom (Hidden Key)"].InteractEvent:FireServer(true)
				end)
			end
			task.wait(4.5)
			pcall(function()
				for _, v in pairs(Workspace.Guttermouth.GuttermouthRoom4.Monsters:GetChildren()) do
					if v and v:FindFirstChild("Humanoid") then v.Humanoid.Health = 0 end
				end
			end)
			task.wait(4)
			goto(Vector3.new(12546,252,-2359))
			repeat task.wait() until Workspace:FindFirstChild("GuttermouthChest")
			pcall(function() Workspace.Guttermouth.GuttermouthRoom4.ClaimRewards:InvokeServer(true) end)
			task.wait(0.5)
			if Workspace:FindFirstChild("GuttermouthChest") then
				Workspace.GuttermouthChest:Destroy()
			end
			goto(Vector3.new(12529,252,-2350))
			-- Count empty slots
			pcall(function()
				local invFrame = Players.LocalPlayer.PlayerGui.Container.Main["INV_SF"]
				for _, v in pairs(invFrame:GetDescendants()) do
					if v.Name == "HoverText" and v.Value ~= "" then
						amountEmptyInventory = amountEmptyInventory - 1
					end
				end
			end)
			if amountEmptyInventory <= 0 then
				task.wait(1)
				goto(Vector3.new(713,228,-483))
				for i = 0, 10 do sellLostItems() task.wait(0.3) end
				task.wait(1)
				amountEmptyInventory = 20
				goto(Vector3.new(12524,252,-2349))
				for i = 0, 100, 10 do
					task.wait(0.01)
					pcall(function() Workspace.Guttermouth.GuttermouthRoom4.GutterExit.InteractEvent:FireServer(true) end)
				end
				task.wait(1)
			end
			for i = 0, 100, 10 do
				task.wait()
				pcall(function() Workspace.Guttermouth.GuttermouthRoom4.GutterExit.InteractEvent:FireServer(true) end)
			end
			task.wait(0.3)
		end
	end
end)

-- Plant ESP loop
task.spawn(function()
	while getgenv().scriptRunning do
		task.wait(1)
		if pESP and #plants > 0 then
			for _, v in pairs(spawnersFolder:GetDescendants()) do
				if v and v:IsA("IntValue") and v.Name == "Item" and v.Parent and v.Parent.Name == "Info" then
					if table.find(plants, tonumber(v.Value)) then
						local plantModel = v.Parent.Parent
						local hitbox = plantModel:FindFirstChild("HitBox")
						if hitbox then
							if not hitbox:FindFirstChild("PlantBoxHandleAdornment") then
								local adorn = Instance.new("BoxHandleAdornment")
								adorn.Name = "PlantBoxHandleAdornment"
								adorn.Adornee = hitbox
								adorn.AlwaysOnTop = true
								adorn.ZIndex = 0
								adorn.Size = hitbox.Size + Vector3.new(2,2,2)
								adorn.Transparency = 0.3
								adorn.Color3 = Color3.fromRGB(0,255,128)
								adorn.Parent = hitbox
							end
							if not hitbox:FindFirstChild("PlantBeam") then
								local beam = Instance.new("Beam")
								beam.Name = "PlantBeam"
								beam.Color = ColorSequence.new(Color3.fromRGB(0,255,128))
								beam.Width0 = 0.1
								beam.Width1 = 0.1
								local att0 = Instance.new("Attachment")
								att0.Parent = speaker.Character:WaitForChild("HumanoidRootPart")
								local att1 = Instance.new("Attachment")
								att1.Parent = hitbox
								beam.Attachment0 = att0
								beam.Attachment1 = att1
								beam.Parent = hitbox
							end
						end
					end
				end
			end
		end
	end
end)
