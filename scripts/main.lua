local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local descendants = CoreGui:GetDescendants()

for _, descendant in pairs(descendants) do
	if descendant.Name == "SimpleSpy2" then
		descendant:Destroy()
		Players.LocalPlayer:Kick("Unstable connection detected")
	end
end

StarterGui:SetCore("SendNotification", {
	Title = "FF";
	Text = "FF"
})
-- variables
local themes = {
	Background = Color3.fromRGB(128, 200, 128), 
	Glow = Color3.fromRGB(128, 200, 128), 
	Accent = Color3.fromRGB(70, 120, 70), 
	LightContrast = Color3.fromRGB(108, 180, 108), 
	DarkContrast = Color3.fromRGB(88, 140, 88),  
	TextColor = Color3.fromRGB(200, 255, 200)
}

local speaker = Players.LocalPlayer
Mouse = Players.LocalPlayer:GetMouse()
local playerChildren = Players:GetChildren()
if CoreGui:FindFirstChild("FF") then
	getgenv().scriptRunning = false
	CoreGui:FindFirstChild("FF"):Destroy()
end
getgenv().scriptRunning = true
local noFog = false

-- init
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bardium/venyx/main/main"))()
--local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bardium/venyx/main/maintwo"))()
--local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/bardium/venyx/main/testing"))()
--local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Stefanuk12/Venyx-UI-Library/main/source.lua"))()

local venyx = library.new("FF", 5013109572)
function goto(pos)
	local active = true
	if not workspace.HOLE:FindFirstChild("HoleTPEntrance") then
		repeat
			local prevPos = Players.LocalPlayer.Character.HumanoidRootPart.CFrame
			Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(1304,96,-525)
			task.wait()
			Players.LocalPlayer.Character.HumanoidRootPart.CFrame = prevPos
			task.wait(1)
		until workspace.HOLE:FindFirstChild("HoleTPEntrance")
	end

	if (Players.LocalPlayer.Character.HumanoidRootPart.Position - pos).magnitude < 200 then
		Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
		task.wait(.3)
		local active = false
	else
		local hole = workspace.HOLE.HoleTPEntrance
		local oPos = hole.Position
		local oSize = hole.Size

		hole.Size = Vector3.new(1,1,1)
		hole.Transparency = 1
		hole.CFrame = Players.LocalPlayer.Character.HumanoidRootPart.CFrame
		repeat hole.Position = Players.LocalPlayer.Character.HumanoidRootPart.Position task.wait() until (hole.Position - Players.LocalPlayer.Character.HumanoidRootPart.Position).magnitude < 10
		hole.Position = oPos
		hole.Size = oSize
		repeat task.wait() until (Players.LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(430,441,102)).magnitude < 10
		for i=1, 4 do
			Players.LocalPlayer.Character.HumanoidRootPart.Anchored = true
			Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
			task.wait(.1)
		end
		task.wait(.1)
		Players.LocalPlayer.Character.HumanoidRootPart.Anchored = false
		local active = false
	end
end

-- first page
local PlayerPage = venyx:addPage("Player", 5012544693)
local TeleporstsPage = venyx:addPage("Teleports", 5012543481)
local MainPage = venyx:addPage("Features", 5012544092)
local ESPPage = venyx:addPage("ESP", 5012543246)
local SettingsPage = venyx:addPage("Settings", 5012544372)
local Teleports = TeleporstsPage:addSection("Locations")

Teleports:addDropdown("Overworld Teleports", {"A Frontier Of Dragons", "Abandoned Orchard", "Ancient Forest", "Blackrock Mountain", "Blue Ogre Camp", "Celestial Field", "Celestial Peak", "Clamstack Cave", "Coral Bay", "Farm Fortress", "Frigid Waste (PvP)", "Gnome Magic School", "Great Pine Forest", "Greenhorn Grove", "Hoodlum Falls", "Matumada", "Otherworld Tower", "Pebble Bay", "Petrified Grassland", "Pit Depths", "Rabbit Hole", "Red Ant Cove", "Rubble Spring", "Starry Point", "Strangeman's Domain", "The Deep Forest", "The Forgotten Lands", "The Long Coast", "The Maze Wood", "The Pits", "The Quiet Field", "The Rolling Road", "The Spider's Nest", "The Town of Right and Wrong", "Topple Hill", "Topple Lake", "Topple Town", "Twinkling Meadow", "Upper Island"}, function(overworldteleport)
	if overworldteleport == "A Frontier Of Dragons" then
		goto(Vector3.new(1184, 91, -2823))
	end
	if overworldteleport == "Abandoned Orchard" then
		goto(Vector3.new(271, 88, -1840))
	end
	if overworldteleport == "Ancient Forest" then
		goto(Vector3.new(676, 236, -1246))
	end
	if overworldteleport == "Blackrock Mountain" then
		goto(Vector3.new(-594, 140, -612))
	end
	if overworldteleport == "Blue Ogre Camp" then
		goto(Vector3.new(-865, 57, -1546))
	end
	if overworldteleport == "Celestial Field" then
		goto(Vector3.new(1534, 92, -2899))
	end
	if overworldteleport == "Celestial Peak" then
		goto(Vector3.new(1473, 195, -2483))
	end
	if overworldteleport == "Clamstack Cave" then
		goto(Vector3.new(565, 158, -952))
	end
	if overworldteleport == "Coral Bay" then
		goto(Vector3.new(1867, 1, -2765))
	end
	if overworldteleport == "Farm Fortress" then
		goto(Vector3.new(166, 53, 415))
	end
	if overworldteleport == "Frigid Waste (PvP)" then
		goto(Vector3.new(-1737, 155, -785))
	end
	if overworldteleport == "Gnome Magic School" then
		goto(Vector3.new(789, 240, -574))
	end
	if overworldteleport == "Great Pine Forest" then
		goto(Vector3.new(-13, 73, -1274))
	end
	if overworldteleport == "Greenhorn Grove" then
		goto(Vector3.new(296, 73, -217))
	end
	if overworldteleport == "Hoodlum Falls" then
		goto(Vector3.new(1777, 61, -997))
	end
	if overworldteleport == "Matumada" then
		goto(Vector3.new(-978, 1, -2486))
	end
	if overworldteleport == "Otherworld Tower" then
		goto(Vector3.new(1178, 86, -3352))
	end
	if overworldteleport == "Pebble Bay" then
		goto(Vector3.new(-44, 2, 719))
	end
	if overworldteleport == "Petrified Grassland" then
		goto(Vector3.new(1655, 73, -1331))
	end
	if overworldteleport == "Pit Depths" then
		goto(Vector3.new(1183, -59, -2080))
	end
	if overworldteleport == "Rabbit Hole" then
		goto(Vector3.new(-3233, 245, -2623))
	end
	if overworldteleport == "Red Ant Cove" then
		goto(Vector3.new(886, 63, 362))
	end
	if overworldteleport == "Rubble Spring" then
		goto(Vector3.new(1062, 73, -534))
	end
	if overworldteleport == "Starry Point" then
		goto(Vector3.new(2265, 5, 481))
	end
	if overworldteleport == "Strangeman's Domain" then
		goto(Vector3.new(-4778, 267, 732))
	end
	if overworldteleport == "The Deep Forest" then
		goto(Vector3.new(1585, 73, 112))
	end
	if overworldteleport == "The Forgotten Lands" then
		goto(Vector3.new(-779, 92, -1200))
	end
	if overworldteleport == "The Long Coast" then
		goto(Vector3.new(-1172, 3, -1303))
	end
	if overworldteleport == "The Maze Wood" then
		goto(Vector3.new(692, 89, -2388))
	end
	if overworldteleport == "The Pits" then
		goto(Vector3.new(1320, 89, -2430))
	end
	if overworldteleport == "The Quiet Field" then
		goto(Vector3.new(2013, 111, -447))
	end
	if overworldteleport == "The Rolling Road" then
		goto(Vector3.new(1731, 92, -2404))
	end
	if overworldteleport == "The Spider's Nest" then
		goto(Vector3.new(1500, 209, -3701))
	end
	if overworldteleport == "The Town of Right and Wrong" then
		goto(Vector3.new(1115, 92, -3134))
	end
	if overworldteleport == "Topple Hill" then
		goto(Vector3.new(777, 199, -312))
	end
	if overworldteleport == "Topple Lake" then
		goto(Vector3.new(615, 256, -757))
	end
	if overworldteleport == "Topple Town" then
		goto(Vector3.new(685, 226, -461))
	end
	if overworldteleport == "Twinkling Meadow" then
		goto(Vector3.new(92, 73, -752))
	end
	if overworldteleport == "Upper Island" then
		goto(Vector3.new(-1361, 35, -2278))
	end
end)

Teleports:addDropdown("Ratboy's Nightmare Teleports", {"Back of The Theatre", "Blue Button", "Blue Door", "Cyan (Teal) Button", "Cyan (Teal) Door", "End of the Road", "Fish Hall", "Green Button", "Green Door", "Inside", "Maze of the Root", "Meeting Place", "MYSTERY STORE", "Orange Button", "Orange Door", "Pink Button", "Pink Door", "Purple Button", "Purple Door", "Red Button", "Red Door", "The Back Area", "The Ballroom", "The Deli", "The Grand Hall", "The Hidden Library", "The Library of Riddles", "The Lost", "The Mansion", "The Old Cave", "The Old Mansion", "The Plant Room", "The Road", "The Supermarket", "The Theatre", "The Vault", "Waiting Room", "Yellow Button", "Yellow Door"}, function(ratboyteleport)
	if ratboyteleport== "Back of The Theatre" then
		goto(Vector3.new(7799, 172, -3629))
	end
	if ratboyteleport== "Blue Button" then
		goto(Vector3.new(7285, 172, -2549))
	end
	if ratboyteleport== "Blue Door" then
		goto(Vector3.new(7149, 169, -1621))
	end
	if ratboyteleport== "Cyan (Teal) Button" then
		goto(Vector3.new(7203, 244, 2235))
	end
	if ratboyteleport== "Cyan (Teal) Door" then
		goto(Vector3.new(7794, 204, 2212))
	end
	if ratboyteleport== "End of the Road" then
		goto(Vector3.new(10779, 375, -12512))
	end
	if ratboyteleport== "Fish Hall" then
		goto(Vector3.new(12905, 205, 5036))
	end
	if ratboyteleport== "Green Button" then
		goto(Vector3.new(7926, 157, -3546))
	end
	if ratboyteleport== "Green Door" then
		goto(Vector3.new(7298, 171, -2543))
	end
	if ratboyteleport== "Inside" then
		goto(Vector3.new(7311, 171, -2558))
	end
	if ratboyteleport== "Maze of the Root" then
		goto(Vector3.new(13132, 191, 7532))
	end
	if ratboyteleport== "Meeting Place" then
		goto(Vector3.new(7514, 237, -4952))
	end
	if ratboyteleport== "MYSTERY STORE" then
		goto(Vector3.new(6765, 200, -2545))
	end
	if ratboyteleport== "Orange Button" then
		goto(Vector3.new(7129, 143, -1587))
	end
	if ratboyteleport== "Orange Door" then
		goto(Vector3.new(6985, 141, -1635))
	end
	if ratboyteleport== "Pink Button" then
		goto(Vector3.new(7208, 154, -1717))
	end
	if ratboyteleport== "Pink Door" then
		goto(Vector3.new(7163, 168, -1742))
	end
	if ratboyteleport== "Purple Button" then
		goto(Vector3.new(7297, 147, -1701))
	end
	if ratboyteleport== "Purple Door" then
		goto(Vector3.new(7021, 141, -1689))
	end
	if ratboyteleport== "Red Button" then
		goto(Vector3.new(7261, 200, -2147))
	end
	if ratboyteleport== "Red Door" then
		goto(Vector3.new(7229, 168, -814))
	end
	if ratboyteleport== "The Back Area" then
		goto(Vector3.new(7206, 244, 2122))
	end
	if ratboyteleport== "The Ballroom" then
		goto(Vector3.new(11825, 318, 2432))
	end
	if ratboyteleport== "The Deli" then
		goto(Vector3.new(7070, 140, -1621))
	end
	if ratboyteleport== "The Grand Hall" then
		goto(Vector3.new(5928, 211, 4845))
	end
	if ratboyteleport== "The Hidden Library" then
		goto(Vector3.new(8170, 187, -949))
	end
	if ratboyteleport== "The Library of Riddles" then
		goto(Vector3.new(7332, 157, -1636))
	end
	if ratboyteleport== "The Lost" then
		goto(Vector3.new(5858, 157, 4904))
	end
	if ratboyteleport== "The Mansion" then
		goto(Vector3.new(7003, 140, -1639))
	end
	if ratboyteleport== "The Old Cave" then
		goto(Vector3.new(13099, 174, 6944))
	end
	if ratboyteleport== "The Old Mansion" then
		goto(Vector3.new(7242, 168, -2114))
	end
	if ratboyteleport== "The Plant Room" then
		goto(Vector3.new(7066, 159, -855))
	end
	if ratboyteleport== "The Road" then
		goto(Vector3.new(10759, 201, 8595))
	end
	if ratboyteleport== "The Supermarket" then
		goto(Vector3.new(7252, 202, 2269))
	end
	if ratboyteleport== "The Theatre" then
		goto(Vector3.new(7510, 147, -3613))
	end
	if ratboyteleport== "The Vault" then
		goto(Vector3.new(5740, 224, -3178))
	end
	if ratboyteleport== "Waiting Room" then
		goto(Vector3.new(12398, 284, -5296))
	end
	if ratboyteleport== "Yellow Button" then
		goto(Vector3.new(8510, 214, -1242))
	end
	if ratboyteleport== "Yellow Door" then
		goto(Vector3.new(7195, 168, -1638))
	end
end)


Teleports:addDropdown("Housing Telports", {"Black Tower (Celestial Field)", "Boathouse (Long Coast)", "Castle (Topple Town)", "Ice Spire (Matumada)", "Starter House (Topple Town)", "Two Story House (Topple Town)", "White Tower (Quiet Field)"}, function(houseteleport)
	if houseteleport== "Black Tower (Celestial Field)" then
		goto(Vector3.new(1387, 137, -3217))
	end
	if houseteleport== "Boathouse (Long Coast)" then
		goto(Vector3.new(-484, 4, -1692))
	end
	if houseteleport== "Castle (Topple Town)" then
		goto(Vector3.new(589, 312, -678))
	end
	if houseteleport== "Ice Spire (Matumada)" then
		goto(Vector3.new(-2169, 40, -1229))
	end
	if houseteleport== "Starter House (Topple Town)" then
		goto(Vector3.new(641, 237, -462))
	end
	if houseteleport== "Two Story House (Topple Town)" then
		goto(Vector3.new(626, 258, -552))
	end
	if houseteleport== "White Tower (Quiet Field)" then
		goto(Vector3.new(2092, 121, -458))
	end
end)

Teleports:addDropdown("Vendor Teleports", {"Amy Thistlewitch", "Arbewhy", "Archaeologist"}, function(vendorteleport)
	if vendorteleport== "Amy Thistlewitch" then
		goto(Vector3.new(-2937, 228, -665))
	end
	if vendorteleport== "Arbewhy" then
		goto(Vector3.new(-2939, 230, -1156))
	end
	if vendorteleport== "Archaeologist" then
		goto(Vector3.new(1553, 72, -1632))
	end
end)

-- second page
local theme = SettingsPage
local colors = SettingsPage:addSection("Hub Colors")

for theme, color in pairs(themes) do -- all in one theme changer, i know, Denosaur's cool
	colors:addColorPicker(theme, color, function(color3)
		venyx:setTheme(theme, color3)
	end)
end

-- section 2
local Abilities = MainPage:addSection("Abilities")
local Universal = PlayerPage:addSection("Player")
local Humanoid = Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid", true)
repeat task.wait(0.01) until Humanoid
repeat task.wait(0.01) until Humanoid.WalkSpeed ~= 0
local walkspeed = Humanoid.WalkSpeed
local jumppower = Humanoid.JumpPower
local gravity = workspace.Gravity
local sangle = Humanoid.MaxSlopeAngle
local flyspeed = 1

function isNumber(str)
	if tonumber(str) ~= nil or str == 'inf' then
		return true
	end
end

Abilities:addButton("Remove All Trees", function()
	for index, instance in pairs(workspace:GetDescendants()) do
		if instance:IsA("BasePart") or instance:IsA("Model") or instance:IsA("Folder") then
			if instance.Name == "PostTrees" then
				instance:Destroy()
			end
		end
	end
end)
local npcsFolder = workspace:FindFirstChild("NPCS")
Abilities:addButton("Get Grateful Frog", function()
	if workspace.Spawners["The Sprutle Frog Expansion_Updated"]:FindFirstChild("Spawner_GratefulFrogs") then
		if workspace.Spawners["The Sprutle Frog Expansion_Updated"]["Spawner_GratefulFrogs"]:FindFirstChild("Collectible") then
			venyx:Notify("Frog Finder","Frog found!","rbxassetid://912824766")
			task.wait(.1)
			if workspace.Spawners["The Sprutle Frog Expansion_Updated"]["Spawner_GratefulFrogs"].Collectible:FindFirstChildWhichIsA("BasePart") then
				venyx:Notify("Frog Finder","Teleported to frog.","rbxassetid://912824766")
				goto(workspace.Spawners["The Sprutle Frog Expansion_Updated"]["Spawner_GratefulFrogs"].Collectible:FindFirstChildWhichIsA("BasePart").Position)
				task.wait(.01)
				for p = 1, 50 do
					task.wait()
					workspace.Spawners["The Sprutle Frog Expansion_Updated"]["Spawner_GratefulFrogs"].Collectible.InteractEvent:FireServer()
				end
				venyx:Notify("Frog Finder","Tried collecting frog.","rbxassetid://912824766")
			else
				venyx:Notify("Frog Finder","Can't teleport to frog, so character is moving around the map until it can teleport to frog. Hub disabled until frog found.","rbxassetid://912824766")
				repeat
					if CoreGui:FindFirstChild("FF") then
						if CoreGui:FindFirstChild("FF"):FindFirstChild("Main") then
							CoreGui:FindFirstChild("FF"):FindFirstChild("Main").Visible = false
						end
					end
					workspace.Spawners["The Sprutle Frog Expansion_Updated"]["Spawner_GratefulFrogs"].SpawnLocations.SpawnBrick.Name = "lol"
					goto(workspace.Spawners["The Sprutle Frog Expansion_Updated"]["Spawner_GratefulFrogs"].SpawnLocations.SpawnBrick.Position + Vector3.new(0,10,0))
					task.wait(.5)
				until workspace.Spawners["The Sprutle Frog Expansion_Updated"]["Spawner_GratefulFrogs"].Collectible:FindFirstChildWhichIsA("BasePart") or not workspace.Spawners["The Sprutle Frog Expansion_Updated"]["Spawner_GratefulFrogs"].SpawnLocations:FindFirstChild("SpawnBrick")
				if not workspace.Spawners["The Sprutle Frog Expansion_Updated"]["Spawner_GratefulFrogs"].SpawnLocations:FindFirstChild("SpawnBrick") then
					Players.LocalPlayer:Kick("Server is laggy or something glitched. It is recommended that you use this hub only in a private server.")
				else
					venyx:Notify("Frog Finder","Frog found!","rbxassetid://912824766")
					task.wait(.1)
					goto(workspace.Spawners["The Sprutle Frog Expansion_Updated"]["Spawner_GratefulFrogs"].Collectible:FindFirstChildWhichIsA("BasePart").Position)
					venyx:Notify("Frog Finder","Teleported to frog.","rbxassetid://912824766")
					task.wait(.01)
					for p = 1, 50 do
						task.wait()
						if workspace.Spawners["The Sprutle Frog Expansion_Updated"]["Spawner_GratefulFrogs"]:FindFirstChild("Collectible") then
							if workspace.Spawners["The Sprutle Frog Expansion_Updated"]["Spawner_GratefulFrogs"]:FindFirstChild("Collectible"):FindFirstChild("InteractEvent") then
								workspace.Spawners["The Sprutle Frog Expansion_Updated"]["Spawner_GratefulFrogs"].Collectible.InteractEvent:FireServer()
							end
						end
					end
					venyx:Notify("Frog Finder","Tried collecting frog.","rbxassetid://912824766")
					if CoreGui:FindFirstChild("FF") then
						if CoreGui:FindFirstChild("FF"):FindFirstChild("Main") then
							CoreGui:FindFirstChild("FF"):FindFirstChild("Main").Visible = true
						end
					end
				end
			end
		else
			venyx:Notify("Frog Finder","No frog found.","rbxassetid://912824766")
		end    
	else
		venyx:Notify("Frog Finder","No frog found.","rbxassetid://912824766")
	end    
end)

Abilities:addButton("Check For Cosmic Ghost", function()
	if npcsFolder:FindFirstChild("CosmicFloatingMonsterHeadNPC") then
		venyx:Notify("Status","Cosmic Ghost found.","rbxassetid://3069125725")
		if npcsFolder:FindFirstChild("CosmicFloatingMonsterHeadNPC"):FindFirstChildWhichIsA("BasePart",true) then
			goto(npcsFolder:FindFirstChild("CosmicFloatingMonsterHeadNPC"):FindFirstChildWhichIsA("BasePart",true).Position + Vector3.new(10,10,10))
			task.wait(.25)
			venyx:Notify("Status","Teleported to Cosmic Ghost.","rbxassetid://3069125725")
		else
			venyx:Notify("Status","Cosmic Ghost found but is not loaded. Try moving around matumada to load it.","rbxassetid://3069125725")
		end
	else
		venyx:Notify("Status","Cosmic Ghost not found.","rbxassetid://3069125725")
	end
end)

Abilities:addButton("Check For Path Gambler", function()
	if npcsFolder:FindFirstChild("PathGamblerNPC") then
		venyx:Notify("Status","Path Gambler found.","rbxassetid://2463293241")
		if npcsFolder:FindFirstChild("PathGamblerNPC"):FindFirstChildWhichIsA("BasePart",true) then
			goto(npcsFolder:FindFirstChild("PathGamblerNPC"):FindFirstChildWhichIsA("BasePart",true).Position + Vector3.new(0,4,0))
			task.wait(.25)
			venyx:Notify("Status","Teleported to Path Gambler.","rbxassetid://2463293241")
		else
			venyx:Notify("Status","Path Gambler found but is not loaded. Try teleporting around Ratboy's Nightmare to load it.","rbxassetid://2463293241")
		end
	else
		venyx:Notify("Status","Path Gambler not found.","rbxassetid://2463293241")
	end
end)

Abilities:addButton("Faster Kills", function()
	loadstring(game:HttpGet(("https://raw.githubusercontent.com/SeventhBuilder/FF/refs/heads/main/scripts/faster-kills.lua")))()
end)

Abilities:addButton("Auto Find Presents", function()
	loadstring(game:HttpGet(("https://raw.githubusercontent.com/SeventhBuilder/FF/refs/heads/main/scripts/auto-find-presents.lua")))()
end)

Abilities:addText("Fast Regen Stamina will kill your character so store valueables in a chest.")
Abilities:addButton("Fast Regen Stamina", function()
	loadstring(game:HttpGet(("https://raw.githubusercontent.com/SeventhBuilder/FF/refs/heads/main/scripts/fast-regen-stamina.lua")))()
end)

local spawnersFolder = workspace.Spawners
for i,v in pairs (spawnersFolder:GetDescendants()) do
	if v.Name == "PlantBoxHandleAdornment" or v.Name == "PlantBeam" then
		v:Destroy()
	end
end
Abilities:addButton("Remove Fog", function()
	local player = Players.LocalPlayer
	if player:FindFirstChild("PlayerScripts") then
		if player:FindFirstChild("PlayerScripts"):FindFirstChild("Fog") then
			player.PlayerScripts.Fog:Destroy()
		end
	end
	if player.Character:FindFirstChild("Fogbox") then
		if player.Character:FindFirstChild("Fogbox"):FindFirstChild("Ring1") then
			player.Character.Fogbox.Ring1:Destroy()
		end
		if player.Character:FindFirstChild("Fogbox"):FindFirstChild("Ring2") then
			player.Character.Fogbox.Ring2:Destroy()
		end
		if player.Character:FindFirstChild("Fogbox"):FindFirstChild("Ring3") then
			player.Character.Fogbox.Ring3:Destroy()
		end
	end
end)
function randomString()
	local length = math.random(10,20)
	local array = {}
	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end
	return table.concat(array)
end
local ESPs = ESPPage:addSection("ESPs")
local pESP = false
local plants = {}
local plantNames = {}
local loweredPlantNames = {}

ESPs:addToggle("Plant ESP", false, function(value)
	if value == true then
		pESP = true
		venyx:Notify("Status","Plant ESP enabled.","rbxassetid://751305395")
	else
		pESP = false
		for i,v in pairs (spawnersFolder:GetDescendants()) do
			if v.Name == "PlantBoxHandleAdornment" or v.Name == "PlantBeam" then
				v:Destroy()
			end
		end
		venyx:Notify("Status","Plant ESP disabled.","rbxassetid://751305395")
	end
end)

ESPs:addTextbox("Add Plant ESP Name", "Insert Plant Name Here", function(value,focusLost)
	if focusLost and value ~= nil and value ~= "" then
		for i,v in pairs (ReplicatedStorage.ItemInfo:GetDescendants()) do
			if v.Name == "FullName" then
				if not table.find(plants, tostring(v.Parent.Name)) and string.lower(v.Value) == string.lower(value) then
					table.insert(plants, tonumber(v.Parent.Name))
					table.insert(plantNames, tostring(v.Value))
					table.insert(loweredPlantNames, string.lower(tostring(v.Value)))
					local newstring = ""
					for i, v in pairs(plantNames) do
						if i > 1 then
							newstring = newstring .. ", "
						end
						newstring = newstring .. tostring(v)
					end
					if (next(plants) ~= nil) then
						venyx:Notify("Status","Added "..tostring(v.Value).." to plant ESP searching!".." Current Plants: "..newstring,"rbxassetid://751305395")
					else
						venyx:Notify("Status","Added "..tostring(v.Value).." to plant ESP searching!".." No plants selected.","rbxassetid://751305395")
					end
				end
			end
		end
	end
end)

ESPs:addTextbox("Remove Plant ESP Name", "Insert Plant Name Here", function(value,focusLost)
	if focusLost and value ~= nil and value ~= "" then
		for i,v in pairs (ReplicatedStorage.ItemInfo:GetDescendants()) do
			if v.Name == "FullName" then
				if string.lower(v.Value) == string.lower(value) then
					--print("yes plant found")
					if table.find(loweredPlantNames, string.lower(value)) then
						--print("plant found in table")
						local pPlantId = tonumber(v.Parent.Name)
						local plantId = table.find(plants, pPlantId)
						if plantId then
							table.remove(plants,plantId)
						else
							print(pPlantId)
						end

						local pFullName = tostring(v.Value)
						local fullName = table.find(plantNames,pFullName)
						if fullName then
							table.remove(plantNames, fullName)
						else
							print(pFullName)
						end

						local plPlantName = string.lower(tostring(v.Value))
						local lPlantName = table.find(plantNames,plPlantName)
						if lPlantName then
							table.remove(plantNames, lPlantName)
						else
							print(plPlantName)
						end

						local newstring = ""
						for i, v in pairs(plantNames) do
							if i > 1 then
								newstring = newstring .. ", "
							end
							newstring = newstring .. tostring(v)
						end
						local newstring2 = ""
						for i, v in pairs(plants) do
							if i > 1 then
								newstring2 = newstring2 .. ", "
							end
							newstring2 = newstring2 .. tostring(v)
						end
						--print(plants)
						for i,v in pairs (spawnersFolder:GetDescendants()) do
							if v.Name == "PlantBoxHandleAdornment" or v.Name == "PlantBeam" then
								v:Destroy()
							end
						end
						if (next(plants) ~= nil) then
							venyx:Notify("Status","Removed "..tostring(v.Value).." from plant ESP searching! ".." Current Plants: "..newstring,"rbxassetid://751305395")
						else
							venyx:Notify("Status","Removed "..tostring(v.Value).." from plant ESP searching!".." No plants selected.","rbxassetid://751305395")
						end
					end
				end
			end
		end
	end
end)
repeat task.wait(0.01) until Humanoid.WalkSpeed ~= 0
Universal:addSlider("Walk Speed Changer", Humanoid.WalkSpeed, 0, 100, function(value)
	walkspeed = value
end)


Universal:addSlider("Jump Power Changer", Humanoid.JumpPower, 0, 300, function(value)
	jumppower = value
end)

if math.floor(tonumber(workspace.Gravity)) == 196 then
	Universal:addSlider("Gravity Changer", 196.2, 0, 900, function(value)
		gravity = value
	end)
else
	Universal:addSlider("Gravity Changer", workspace.Gravity, 0, 900, function(value)
		gravity = value
	end)
end
Universal:addSlider("Slope Angle Changer", Humanoid.MaxSlopeAngle, 0, 90, function(value)
	sangle = value
end)
local amountEmptyInventory = 20
local Noclipping = nil
Clip = false
Universal:addToggle("Noclip", false, function(value)
	if value == true then
		Clip = false
		task.wait(0.1)
		local function NoclipLoop()
			if Clip == false and speaker.Character ~= nil then
				for _, child in pairs(speaker.Character:GetDescendants()) do
					if child:IsA("BasePart") and child.CanCollide == true then
						child.CanCollide = false
					end
				end
			end
		end
		Noclipping = RunService.Stepped:Connect(NoclipLoop)
	elseif value == false then
		if Noclipping then
			Noclipping:Disconnect()
		end
		Clip = true
	end
end)

function isNumber(str)
	if tonumber(str) ~= nil or str == 'inf' then
		return true
	end
end

FLYING = false
QEfly = true
iyflyspeed = flyspeed
vehicleflyspeed = 1
function sFLY(vfly)
	repeat task.wait() until Players.LocalPlayer and Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	repeat task.wait() until Mouse
	if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect() flyKeyUp:Disconnect() end

	local T = Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local SPEED = 0

	local function FLY()
		FLYING = true
		local BG = Instance.new('BodyGyro')
		local BV = Instance.new('BodyVelocity')
		BG.P = 9e4
		BG.Parent = T
		BV.Parent = T
		BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
		BG.cframe = T.CFrame
		BV.velocity = Vector3.new(0, 0, 0)
		BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
		task.spawn(function()
			repeat task.wait()
				if not vfly and Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
					Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
				end
				if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
					SPEED = 50
				elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
					SPEED = 0
				end
				if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
					BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).Position) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
					lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
				elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
					BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).Position) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
				else
					BV.velocity = Vector3.new(0, 0, 0)
				end
				BG.cframe = workspace.CurrentCamera.CoordinateFrame
			until not FLYING
			CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			SPEED = 0
			BG:Destroy()
			BV:Destroy()
			if Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
				Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
			end
		end)
	end
	flyKeyDown = Mouse.KeyDown:Connect(function(KEY)
		if KEY:lower() == 'w' then
			CONTROL.F = (vfly and vehicleflyspeed or iyflyspeed)
		elseif KEY:lower() == 's' then
			CONTROL.B = - (vfly and vehicleflyspeed or iyflyspeed)
		elseif KEY:lower() == 'a' then
			CONTROL.L = - (vfly and vehicleflyspeed or iyflyspeed)
		elseif KEY:lower() == 'd' then
			CONTROL.R = (vfly and vehicleflyspeed or iyflyspeed)
		end
		pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
	end)
	flyKeyUp = Mouse.KeyUp:Connect(function(KEY)
		if KEY:lower() == 'w' then
			CONTROL.F = 0
		elseif KEY:lower() == 's' then
			CONTROL.B = 0
		elseif KEY:lower() == 'a' then
			CONTROL.L = 0
		elseif KEY:lower() == 'd' then
			CONTROL.R = 0
		end
	end)
	FLY()
end

function NOFLY()
	FLYING = false
	if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect() flyKeyUp:Disconnect() end
	if Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
		Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
	end
	pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

Universal:addSlider("Fly Speed Changer", 1, 0, 3, function(value)
	if FLYING then
		flyspeed = value
		NOFLY()
		task.wait()
		sFLY()
		iyflyspeed = flyspeed
	else
		flyspeed = value
		NOFLY()
		iyflyspeed = flyspeed
	end
end)

args1 = flyspeed
Universal:addToggle("Fly", false, function(value)
	if value == true then
		NOFLY()
		task.wait()
		sFLY()
		if args1 and isNumber(args1) then
			iyflyspeed = args1
		end
	elseif value == false then
		NOFLY()
	end
end)

function getRoot(char)
	local rootPart = char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
	return rootPart
end
IYMouse = Players.LocalPlayer:GetMouse()

local speakahChar = speaker.Character
local speakerHum = speakahChar:FindFirstChild("Humanoid")
repeat task.wait() until speakahChar:FindFirstChild("HumanoidRootPart")
local speakahHRP = speakahChar.HumanoidRootPart


local ffarm = false
local root = workspace[Players.LocalPlayer.Name].HumanoidRootPart
function checkTP()
	if not workspace.HOLE:FindFirstChild("HoleTPEntrance") then
		repeat
			local prevPos = root.CFrame
			root.CFrame = CFrame.new(1304,96,-525)
			task.wait()
			root.CFrame = prevPos
			task.wait(1)
		until workspace.HOLE:FindFirstChild("HoleTPEntrance")
	end
end
checkTP()

function gotofirefly(firefly)
	local hole = workspace.HOLE
	if hole:FindFirstChild("HoleTPEntrance") then
		hole = workspace.HOLE.HoleTPEntrance
		if (root.Position - firefly.Position).magnitude < 200 then
		else
			hole.Size = Vector3.new(1,1,1)
			hole.Transparency = 1
			hole.CFrame = root.CFrame
			repeat hole.Position = root.Position task.wait() until (hole.Position - root.Position).magnitude < 10
			hole.Position = Vector3.new(1318,85,-527)
			hole.Size = Vector3.new(14,5,17)
			repeat task.wait() until (root.Position - Vector3.new(430,441,102)).magnitude < 10
			local preframe = root.CFrame
			for i=1, 5 do
				root.Anchored = true
				root.CFrame = firefly.CFrame + Vector3.new(0,3,0)
				task.wait(.1)
			end
		end
		task.wait()
		if firefly.Parent then
			repeat
				if not ffarm then return end
				root.Anchored = true
				root.CFrame = firefly.CFrame + Vector3.new(0,3,0)
				root.Anchored = false
				task.wait()
				if firefly:FindFirstChild("CollectEvent") then
					firefly.CollectEvent:FireServer()
				end
				task.wait(.08)
			until firefly.Parent == nil
		end
		root.Anchored = false
	else
		checkTP()
		if (root.Position - firefly.Position).magnitude < 200 then
		else
			hole.Size = Vector3.new(1,1,1)
			hole.Transparency = 1
			hole.CFrame = root.CFrame
			repeat hole.Position = root.Position task.wait() until (hole.Position - root.Position).magnitude < 10
			hole.Position = Vector3.new(1318,85,-527)
			hole.Size = Vector3.new(14,5,17)
			repeat task.wait() until (root.Position - Vector3.new(430,441,102)).magnitude < 10
			local preframe = root.CFrame
			for i=1, 5 do
				root.Anchored = true
				root.CFrame = firefly.CFrame + Vector3.new(0,3,0)
				task.wait(.1)
			end
		end
		task.wait()
		if firefly.Parent then
			repeat
				if not ffarm then return end
				root.Anchored = true
				root.CFrame = firefly.CFrame + Vector3.new(0,3,0)
				root.Anchored = false
				task.wait()
				if firefly:FindFirstChild("CollectEvent") then
					firefly.CollectEvent:FireServer()
				end
				task.wait(.08)
			until firefly.Parent == nil
		end
		root.Anchored = false
	end
end
local bfarm = false
local dfarm = false
local lfarm = false
local longwait = false
local shortwait = false
local randomboth = true
task.wait()
local Autofarmsection = MainPage:addSection("AutoFarms")
task.wait(.025)
Autofarmsection:addButton("Toggle Bird Nests AutoFarm", function()
	if bfarm then
		bfarm = false
		venyx:Notify("Status","Bird nests autofarm disabled.","rbxassetid://3069123676")
	else if not bfarm then
			goto(Vector3.new(-1405, 325, -2271))
			task.wait(1)
			bfarm = true
			venyx:Notify("Status","Bird nests autofarm enabled.","rbxassetid://3069123676")
			checkTP()
		end
	end
end)
task.wait(.025)
Autofarmsection:addButton("Toggle Lost AutoFarm(PATCHED)", function()
	if lfarm then
		amountEmptyInventory = 20
		lfarm = false
		venyx:Notify("Status","Lost autofarm disabled.")
	else if not lfarm then
			amountEmptyInventory = 20
			venyx:Notify("Status","Hidden key is required.","rbxassetid://2452981255")
			local invFrame = Players.LocalPlayer.PlayerGui.Container.Main["INV_SF"]
			for i,v in pairs (invFrame:GetDescendants()) do
				if v.Name == "ItemCode" then
					if v.Value == 2025 then
						venyx:Notify("Status","Hidden key found.","rbxassetid://2452981255")
						goto(Vector3.new(5857, 157, 4907))
						task.wait(1.5)
						lfarm = true
						venyx:Notify("Status","Lost autofarm enabled.")
						amountEmptyInventory = 20
						break
					end
				end
			end
		end
	end
end)
task.wait(.025)
Autofarmsection:addButton("Toggle Firefly Stones AutoFarm (Denosaur)", function()
	if ffarm then
		ffarm = false
		venyx:Notify("Status","Firefly stones autofarm disabled.","rbxassetid://1227584028")
	else if not ffarm then
			ffarm = true
			venyx:Notify("Status","Firefly stones autofarm enabled.","rbxassetid://1227584028")
			checkTP()
		end
	end
end)
task.wait(.025)
Autofarmsection:addDropdown("Deli AutoFarm Mode", {"Long Wait", "Short Wait", "Both"}, function(mode)
	if mode == "Long Wait" then
		longwait = true
		randomboth = false
		shortwait = false
		venyx:Notify("Status","Long wait selected.","rbxassetid://2458363356")
	end
	if mode == "Short Wait" then
		shortwait = true
		longwait = false
		randomboth = false
		venyx:Notify("Status","Short wait selected.","rbxassetid://2458363356")
	end
	if mode == "Both" then
		randomboth = true
		shortwait = false
		longwait = false
		venyx:Notify("Status","Both waits selected. (Picks one randomly each time.)","rbxassetid://2458363356")
	end
end)
task.wait(.025)
Autofarmsection:addButton("Toggle Deli AutoFarm", function()
	if dfarm then
		dfarm = false
		venyx:Notify("Status","Deli autofarm disabled.","rbxassetid://2458363356")
	else if not dfarm then
			dfarm = true
			-- Short Wait: workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C1.D1.E.RE1:FireServer()
			-- Long Wait: workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C2.D1.E.RE2:FireServer()
			venyx:Notify("Status","Deli autofarm enabled.","rbxassetid://2458363356")
			goto(Vector3.new(7066, 144, -1621))
			task.wait(3)
		end
	end
end)


task.wait(.025)
Universal:addButton("Telekinesis", function()
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
end)

Universal:addButton("B-Tools", function()
	for i,v in pairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Locked = false
		end
	end
	for i = 1, 4 do
		local Tool = Instance.new("HopperBin")
		Tool.BinType = i
		Tool.Name = randomString()
		Tool.Parent = speaker:FindFirstChildOfClass("Backpack")
	end
end)

Universal:addButton("Infinite Yield", function()
	loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
end)

function espFunction(BodyPart,color,text)
	local ESPPartparent = BodyPart
	local highlight = Instance.new("Highlight")
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = color
	highlight.FillTransparency = 0.25
	highlight.OutlineTransparency = 0.5
	highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
	highlight.Adornee = BodyPart
	highlight.Parent = BodyPart
	local Billboard = Instance.new("BillboardGui")
	Billboard.Name = "TextPart"
	Billboard.AlwaysOnTop = true
	Billboard.Size = UDim2.fromScale(18, 6)
	Billboard.StudsOffset = Vector3.new(0,5,0)
	Billboard.Parent = ESPPartparent
	if text ~= nil then
		local Text = Instance.new("TextLabel")
		Text.Name = "ESPTextPart"
		Text.Parent = Billboard
		Text.RichText = true
		Text.TextScaled = true
		Text.Text = text
		Text.Size = UDim2.fromScale(1, 1)
		Text.Font = "SourceSans"
		Text.TextColor3 = Color3.new(0,0,0)
		Text.TextStrokeColor3 = Color3.new(1,1,1)
		Text.TextStrokeTransparency = 0
		Text.BackgroundTransparency = 1
	end
end
Abilities:addButton("Bring Spider Boss Closer To Topple Town", function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/JustApstl/FF/refs/heads/main/scripts/bring-spider-boss-closer-to-topple-town.lua"))()
end)

Abilities:addButton("Teleport To Uncollected Ratboy Token", function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/JustApstl/FF/refs/heads/main/scripts/teleport-to-uncollected-ratboy-token.lua"))()
end)

local exitGui = SettingsPage:addSection("Exit Gui")
exitGui:addButton("Exit Gui", function()
	local descendants = CoreGui:GetDescendants()


	for _, descendant in pairs(descendants) do
		if descendant.Name == "SimpleSpy2" then
			descendant:Destroy()
			Players.LocalPlayer:Kick("Unstable connection detected")
		end
	end
	for i,v in pairs (spawnersFolder:GetDescendants()) do
		if v.Name == "PlantBoxHandleAdornment" or v.Name == "PlantBeam" then
			v:Destroy()
		end
	end
	dfarm = false
	lfarm = false
	amountEmptyInventory = 20
	ffarm = false
	plants = {}
	pESP = false
	noFog = false
	sangle = 56
	jumppower = 81.5
	walkspeed = 18
	speaker.Character.Humanoid.MaxSlopeAngle = 56
	speaker.Character.Humanoid.JumpPower = 81.5
	speaker.Character.Humanoid.WalkSpeed = 18
	getgenv().scriptRunning = false
	if CoreGui:FindFirstChild("FF") then
		CoreGui:FindFirstChild("FF"):Destroy()
	end
end)

task.wait(.1)
-- load

task.wait(1)

local descendants = CoreGui:GetDescendants()


for _, descendant in pairs(descendants) do
	if descendant.Name == "SimpleSpy2" then
		descendant:Destroy()
		Players.LocalPlayer:Kick("Unstable connection detected")
	end
end

function ringBell()
	task.wait()
	ReplicatedStorage.Events.Deli:FireServer("RingBell")
	--print("rung bell")
	Players.LocalPlayer.PlayerGui.DeliGui.BellButton.Visible = false
	task.wait()	
end
function hideNotifications()
	task.wait()
	if Players.LocalPlayer.PlayerGui.Notification.Enabled == true then
		Players.LocalPlayer.PlayerGui.Notification.Enabled = false
	end
	task.wait()
end
function sitAtDeliBooth()
	task.wait()
	workspace.Deli.Booth1.InteractEvent:FireServer()
	task.wait()
end
function hideDialogs()
	task.wait()
	if Players.LocalPlayer.PlayerGui.Dialog.Main.Visible == true then
		Players.LocalPlayer.PlayerGui.Dialog.Main.Visible = false
	end
	task.wait()
end
function skipInitialDeliDialog()
	task.wait()
	workspace.Deli.Booth1.WaiterLocation.Dialog2.D.D1.D1.E.RE1:FireServer()
	task.wait()
end

function sellLostItems()
	ReplicatedStorage.Events.SellShop:FireServer(982,workspace.Shops.Sellers,1) -- Bag of Gems
	ReplicatedStorage.Events.SellShop:FireServer(2223,workspace.Shops.Sellers,1) -- Bedrock Helmet
	ReplicatedStorage.Events.SellShop:FireServer(2224,workspace.Shops.Sellers,1) -- Bedrock Chestplate
	ReplicatedStorage.Events.SellShop:FireServer(2225,workspace.Shops.Sellers,1) -- Bedrock Leggings
	ReplicatedStorage.Events.SellShop:FireServer(2276,workspace.Shops.Sellers,1) -- Black Antlers
	ReplicatedStorage.Events.SellShop:FireServer(2228,workspace.Shops.Sellers,1) -- Century Cube
	ReplicatedStorage.Events.SellShop:FireServer(2229,workspace.Shops.Sellers,1) -- Clever Cube
	ReplicatedStorage.Events.SellShop:FireServer(825,workspace.Shops.Sellers,1) -- Clock
	ReplicatedStorage.Events.SellShop:FireServer(2233,workspace.Shops.Sellers,1) -- Criminal's Tallhat 
	ReplicatedStorage.Events.SellShop:FireServer(2239,workspace.Shops.Sellers,1) -- Fire Hood
	ReplicatedStorage.Events.SellShop:FireServer(2240,workspace.Shops.Sellers,1) -- Fire Spellbound Mage Skirt
	ReplicatedStorage.Events.SellShop:FireServer(2241,workspace.Shops.Sellers,1) -- Fire Spellbound Mage Top
	ReplicatedStorage.Events.SellShop:FireServer(2280,workspace.Shops.Sellers,1) -- Gold Antlers
	ReplicatedStorage.Events.SellShop:FireServer(2246,workspace.Shops.Sellers,1) -- Kitchen Cube
	ReplicatedStorage.Events.SellShop:FireServer(2247,workspace.Shops.Sellers,1) -- Maskhat
	ReplicatedStorage.Events.SellShop:FireServer(2249,workspace.Shops.Sellers,1) -- Nightmare Boots
	ReplicatedStorage.Events.SellShop:FireServer(2250,workspace.Shops.Sellers,1) -- Nightmare Prowler Hat
	ReplicatedStorage.Events.SellShop:FireServer(2251,workspace.Shops.Sellers,1) -- Nightmare Prowler Legs
	ReplicatedStorage.Events.SellShop:FireServer(2252,workspace.Shops.Sellers,1) -- Nightmare Prowler Torso
	ReplicatedStorage.Events.SellShop:FireServer(2254,workspace.Shops.Sellers,1) -- Otherworld Boots
	ReplicatedStorage.Events.SellShop:FireServer(2256,workspace.Shops.Sellers,1) -- Pantry Leech Torso
	ReplicatedStorage.Events.SellShop:FireServer(2257,workspace.Shops.Sellers,1) -- Pantry Leech Platelegs
	ReplicatedStorage.Events.SellShop:FireServer(2258,workspace.Shops.Sellers,1) -- Propaganda Head
	ReplicatedStorage.Events.SellShop:FireServer(203,workspace.Shops.Sellers,1) -- Pureblood Dagger
	ReplicatedStorage.Events.SellShop:FireServer(2260,workspace.Shops.Sellers,1) -- Rising Dark Robe Bottoms
	ReplicatedStorage.Events.SellShop:FireServer(2261,workspace.Shops.Sellers,1) -- Rising Dark Robe Top
	ReplicatedStorage.Events.SellShop:FireServer(2262,workspace.Shops.Sellers,1) -- Rising Dark Mask
	ReplicatedStorage.Events.SellShop:FireServer(1435,workspace.Shops.Sellers,1) -- Black Salamander Egg
	ReplicatedStorage.Events.SellShop:FireServer(205,workspace.Shops.Sellers,1) -- Tri-Blade Shifter
	ReplicatedStorage.Events.SellShop:FireServer(407,workspace.Shops.Sellers,1) -- Wicked Junk Spellbook
end

repeat task.wait(0.01) until workspace:FindFirstChild("Shops")
local ShopsPage = venyx:addPage("Shops")

for _, shop in pairs(workspace.Shops:GetChildren()) do
	if shop:FindFirstChild("Slots") then
		task.wait(1)
		local shopSection = ShopsPage:addSection(shop.Name)
		
		shopSection:addButton("Load Items", function()
			if CoreGui:FindFirstChild("FF") then
				if CoreGui:FindFirstChild("FF"):FindFirstChild("Main") then
					local main = CoreGui:FindFirstChild("FF"):FindFirstChild("Main")
					if main:FindFirstChild("Shops") then
						local shopsGui = main:FindFirstChild("Shops")

						if shopsGui:FindFirstChild(shop.Name) then
							local shopGui = shopsGui:FindFirstChild(shop.Name)
							for _, element in pairs(shopGui.Container:GetChildren()) do
								if element.Name == "Text" then
									shopSection:removeText(element)
									element:Destroy()
								end
							end
						end
					end
				end
			end
			task.wait(0.1)
			for _, slot in pairs(shop:FindFirstChild("Slots"):GetChildren()) do
				for _, item in pairs(ReplicatedStorage.ItemInfo:GetChildren()) do
					if tonumber(item.Name) == tonumber(slot.Item.Value) then
						task.wait(0.01)
						shopSection:addText("Item Name: "..item.FullName.Value.." || Price: "..slot.Price.Value)
					end
				end
			end
			task.wait(0.1)
			venyx:SelectPage(venyx.pages[5], true)
			task.wait(0.1)
			venyx:SelectPage(venyx.pages[6], true)
		end)
	end
end

venyx:SelectPage(venyx.pages[3], true)

task.spawn(function()
	while getgenv().scriptRunning == true do
		task.wait()
		local speakerHum2 = Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
		if speakerHum2 then
			task.wait()
			speakerHum2.MaxSlopeAngle = sangle
			speakerHum2.WalkSpeed = walkspeed
			speakerHum2.JumpPower = jumppower
			--print("auto statting")
		end
		workspace.Gravity = gravity
		if ffarm then
			task.wait()
			--print("firefly farming")
			--print("firefly farming")
			local fly = workspace.Fireflies:FindFirstChild("FireflyServer")
			if fly and ffarm then
				gotofirefly(fly)
			end
			task.wait(.1)
		end
		if dfarm then
			task.wait()
			sitAtDeliBooth()
			hideNotifications()
			ringBell()
			hideDialogs()
			skipInitialDeliDialog()
			if shortwait and dfarm then
				task.wait()
				if workspace.Deli.Booth1:FindFirstChild("WaiterLocation") then
					workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C1.D1.E.RE1:FireServer()
				end
				hideDialogs()
			elseif longwait and dfarm then
				task.wait()
				--print("long wait")
				if workspace.Deli.Booth1:FindFirstChild("WaiterLocation") then
					workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C2.D1.E.RE2:FireServer()
				end
				hideDialogs()
			elseif randomboth and dfarm then
				task.wait()
				if workspace.Deli.Booth1:FindFirstChild("WaiterLocation") then
					task.wait(.05)
					workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C2.D1.E.RE2:FireServer()
					hideDialogs()
					task.wait(.05)
					workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C1.D1.E.RE1:FireServer()
					hideDialogs()
					task.wait(.05)
				end
			end
		end
		if bfarm then
			task.wait()
			--print("bird nest farming")
			if workspace.Spawners.Island:FindFirstChild("Spawner_BirdsNest") then
				if workspace.Spawners.Island:FindFirstChild("Spawner_BirdsNest"):FindFirstChild("Collectible") then
					venyx:Notify("Bird Nests AutoFarm","Nest found!","rbxassetid://3069123676")
					if workspace.Spawners.Island:FindFirstChild("Spawner_BirdsNest").Collectible:FindFirstChildWhichIsA("BasePart") then
						venyx:Notify("Bird Nests AutoFarm","Teleported to nest.","rbxassetid://3069123676")
						goto(workspace.Spawners.Island:FindFirstChild("Spawner_BirdsNest").Collectible:FindFirstChildWhichIsA("BasePart").Position)
						task.wait(.05)
						workspace.Spawners.Island:FindFirstChild("Spawner_BirdsNest").Collectible.InteractEvent:FireServer()
						venyx:Notify("Bird Nests AutoFarm","Tried collecting nest.","rbxassetid://3069123676")
						for i = 0, 50, 1 do
							local args = {
								[1] = i
							}

							ReplicatedStorage.Events.OpenSlot:FireServer(unpack(args))
						end
						task.wait(3)
					else
						venyx:Notify("Bird Nests AutoFarm","Can't teleport to nest, so character is moving around the map until it can teleport to nest. Hub disabled until nest found.","rbxassetid://3069123676")
						for i = 0, 50, 1 do
							local args = {
								[1] = i
							}

							ReplicatedStorage.Events.OpenSlot:FireServer(unpack(args))
						end
						workspace.Spawners.Island:FindFirstChild("Spawner_BirdsNest").SpawnLocations.SpawnBrick.Name = "lol"
						goto(workspace.Spawners.Island:FindFirstChild("Spawner_BirdsNest").SpawnLocations.SpawnBrick.Position + Vector3.new(0,10,0))
						task.wait(3)
					end
				else
					task.wait(3)
					venyx:Notify("Bird Nests AutoFarm","No nests found.","rbxassetid://3069123676")
				end
			end
		end
	end
end)

task.spawn(function()
	while getgenv().scriptRunning == true do
		task.wait()
		if lfarm then
			amountEmptyInventory = 20
			task.wait(.3)
			for i = 0, 100, 10 do
				task.wait()
				workspace.Guttermouth["Door_GuttermouthPhantom (Hidden Key)"].InteractEvent:FireServer(true)
			end
			task.wait(4.5)

			for _, v in pairs (workspace.Guttermouth.GuttermouthRoom4.Monsters:GetChildren()) do
				if v ~= nil then
					if v:FindFirstChild("Humanoid") then
						v.Humanoid.Health = 0
					end
				end
			end

			task.wait(4)

			goto(Vector3.new(12546, 252, -2359))
			repeat task.wait() until workspace:FindFirstChild("GuttermouthChest")
			workspace.Guttermouth.GuttermouthRoom4.ClaimRewards:InvokeServer(true)
			task.wait(0.5)
			if workspace:FindFirstChild("GuttermouthChest") then
				workspace.GuttermouthChest:Destroy()
			end
			goto(Vector3.new(12529, 252, -2350))
			local invFrame = Players.LocalPlayer.PlayerGui.Container.Main["INV_SF"]
			for i,v in pairs (invFrame:GetDescendants()) do
				if v.Name == "HoverText" then
					if v.Value ~= "" then
						--print(tostring(v.Value).." empty slots: "..amountEmptyInventory)
						amountEmptyInventory = amountEmptyInventory - 1
					end
				end
			end
			--print(amountEmptyInventory)
			if amountEmptyInventory <= 0 then
				task.wait(1)
				goto(Vector3.new(713, 228, -483))
				for i = 0, 10, 1 do
					sellLostItems()
					task.wait(.3)
				end
				task.wait(1)
				amountEmptyInventory = 20
				goto(Vector3.new(12524, 252, -2349))
				for i = 0, 100, 10 do
					task.wait(.01)
					workspace.Guttermouth.GuttermouthRoom4.GutterExit.InteractEvent:FireServer(true)
				end
				task.wait(1)
			end
			for i = 0, 100, 10 do
				task.wait()
				workspace.Guttermouth.GuttermouthRoom4.GutterExit.InteractEvent:FireServer(true)
			end
			task.wait(.3)
		end
	end
end)

task.spawn(function()
	while getgenv().scriptRunning == true do
		task.wait(1)
		if pESP then
			for i,v in pairs (spawnersFolder:GetDescendants()) do
				if v ~= nil and v:IsA("IntValue") then
					if v.Name == "Item" and v:IsA("IntValue") and v.Parent.Name == "Info" then
						if table.find(plants,tonumber(v.Value)) then
							local plantModel = v.Parent.Parent
							if plantModel:FindFirstChild("HitBox") then
								if not plantModel:FindFirstChild("HitBox"):FindFirstChild("PlantBoxHandleAdornment") then
									local plantBoxHandleAdornment = Instance.new("BoxHandleAdornment")
									plantBoxHandleAdornment.Parent = plantModel:FindFirstChild("HitBox")
									plantBoxHandleAdornment.Adornee = plantModel:FindFirstChild("HitBox")
									plantBoxHandleAdornment.AlwaysOnTop = true
									plantBoxHandleAdornment.ZIndex = 0
									plantBoxHandleAdornment.Size = plantModel:FindFirstChild("HitBox").Size + Vector3.new(2,2,2)
									plantBoxHandleAdornment.Transparency = 0.3
									plantBoxHandleAdornment.Color3 = Color3.fromRGB(0,255,128)
									plantBoxHandleAdornment.Name = "PlantBoxHandleAdornment"
								end
								if not plantModel:FindFirstChild("HitBox"):FindFirstChild("PlantBeam") then
									local plantBeam = Instance.new("Beam")
									plantBeam.Color = ColorSequence.new((Color3.fromRGB(0,255,128)),(Color3.fromRGB(0,255,128)))
									plantBeam.Name = "PlantBeam"
									plantBeam.Width0 = 0.1
									plantBeam.Width1 = 0.1
									local characterAttachment = Instance.new("Attachment")
									local plantAttachment = Instance.new("Attachment")
									characterAttachment.Parent = Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
									plantAttachment.Parent = plantModel:FindFirstChild("HitBox")
									plantBeam.Parent = plantModel:FindFirstChild("HitBox")
									plantBeam.Attachment0 = characterAttachment
									plantBeam.Attachment1 = plantAttachment
								end
							else
								if plantModel ~= nil and plantModel.Parent ~= nil and plantModel.Parent.Name ~= nil then
									venyx:Notify("Status", "Spawner Name: ".. plantModel.Parent.Name.." Plant found but plant is not loaded. Move around the world to load it.","rbxassetid://751305395")
									task.wait(10)
								end
							end
						end
					end
				end
			end
		end
	end
end)
