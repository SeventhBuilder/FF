-- ============================================================
--  FF Hub  |  Original by SeventhBuilder  |  v5
-- ============================================================

local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")
local Lighting          = game:GetService("Lighting")

for _, d in pairs(CoreGui:GetDescendants()) do
	if d.Name == "SimpleSpy2" then d:Destroy(); Players.LocalPlayer:Kick("Unstable connection detected") end
end
if CoreGui:FindFirstChild("RayfieldLibrary") then CoreGui:FindFirstChild("RayfieldLibrary"):Destroy() end
getgenv().scriptRunning = false; task.wait(0.1); getgenv().scriptRunning = true

local speaker = Players.LocalPlayer
local Mouse   = speaker:GetMouse()

-- =====================================================================
-- STATE  (Rayfield declared early so all functions can reference it)
-- =====================================================================
local Rayfield  -- assigned after loadstring below

local walkspeed = 18; local jumppower = 81.5; local gravity = Workspace.Gravity
local sangle = 56; local flyspeed = 1; local iyflyspeed = 1
local ffarm = false; local bfarm = false; local dfarm = false; local lfarm = false
local longwait = false; local shortwait = false; local randomboth = true
local amountEmptyInventory = 20
local Clip = false; local Noclipping = nil
local FLYING = false; local flyKeyDown, flyKeyUp

local enabled = { present=false, frog=false, strangeman=false, pitfall=false, rabbithole=false, cosmic=false, gambler=false }
local notif   = { present=true, frog=true, cosmic=true, gambler=true, firefly=true, birdnest=true, strangeman=true, rabbithole=true, pitfall=true }
local autoCollect = { present=false, frog=false }
local espToggles  = { plants=false, present=false, frog=true, strangeman=true, rabbithole=true, pitfall=true }

local plants = {}; local plantNames = {}; local loweredPlantNames = {}
local shopPositionCache = {}; local selectedShopName = nil
local watchedShopItems  = {}; local shopItemParagraph = nil
local entranceESPTracker = {}

-- Entity watchers (animals, collectibles, monsters, travelers)
local entityWatchList = {}     -- [instanceName] = {label, active, type}
local travelerWatchList = {}   -- [instanceName] = {label, active, isNight}

-- Paragraph UI elements
local presentStatusParagraph = nil
local frogStatusParagraph    = nil
local entranceParagraphs     = {}   -- [key] = paragraph element

-- =====================================================================
-- UTILITY: Number formatting  (1000000 -> "1,000,000")
-- =====================================================================
local function formatNumber(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local result = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return result
end

-- =====================================================================
-- TELEPORT
-- =====================================================================
local function teleportTo(pos)
	repeat task.wait() until speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
	if not Workspace.HOLE:FindFirstChild("HoleTPEntrance") then
		repeat
			local prev = speaker.Character.HumanoidRootPart.CFrame
			speaker.Character.HumanoidRootPart.CFrame = CFrame.new(1304,96,-525)
			task.wait(); speaker.Character.HumanoidRootPart.CFrame = prev; task.wait(1)
		until Workspace.HOLE:FindFirstChild("HoleTPEntrance")
	end
	local hrp = speaker.Character.HumanoidRootPart
	if (hrp.Position - pos).Magnitude < 200 then
		hrp.CFrame = CFrame.new(pos); task.wait(0.3)
	else
		local hole = Workspace.HOLE.HoleTPEntrance
		local oPos, oSize = hole.Position, hole.Size
		hole.Size = Vector3.new(1,1,1); hole.Transparency = 1; hole.CFrame = hrp.CFrame
		repeat hole.Position = hrp.Position task.wait() until (hole.Position - hrp.Position).Magnitude < 10
		hole.Position = oPos; hole.Size = oSize
		repeat task.wait() until (hrp.Position - Vector3.new(430,441,102)).Magnitude < 10
		for _ = 1,4 do hrp.Anchored = true; hrp.CFrame = CFrame.new(pos); task.wait(0.1) end
		hrp.Anchored = false
	end
end

local function checkTP()
	if not Workspace.HOLE:FindFirstChild("HoleTPEntrance") then
		repeat
			local prev = speaker.Character.HumanoidRootPart.CFrame
			speaker.Character.HumanoidRootPart.CFrame = CFrame.new(1304,96,-525)
			task.wait(); speaker.Character.HumanoidRootPart.CFrame = prev; task.wait(1)
		until Workspace.HOLE:FindFirstChild("HoleTPEntrance")
	end
end

-- =====================================================================
-- ESP HELPERS
-- =====================================================================
local function addHighlightESP(adornee, fillColor, outlineColor, tag)
	if not adornee or adornee:FindFirstChild(tag.."_HL") then return end
	local hl = Instance.new("Highlight")
	hl.Name = tag.."_HL"; hl.Adornee = adornee
	hl.FillColor = fillColor or Color3.fromRGB(0,255,128)
	hl.OutlineColor = outlineColor or Color3.fromRGB(0,200,100)
	hl.FillTransparency = 0.4; hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = adornee
end

local function addBillboardESP(part, text, color, tag)
	if not part or part:FindFirstChild(tag.."_BB") then return end
	local anchor = Instance.new("Part")
	anchor.Name = tag.."_BB"; anchor.Size = Vector3.new(0.1,0.1,0.1)
	anchor.Anchored = true; anchor.CanCollide = false; anchor.Transparency = 1
	anchor.CFrame = part.CFrame + Vector3.new(0,3,0); anchor.Parent = part
	local bg = Instance.new("BillboardGui", anchor)
	bg.AlwaysOnTop = true; bg.Size = UDim2.new(0,200,0,50); bg.StudsOffset = Vector3.new(0,2,0)
	local lbl = Instance.new("TextLabel", bg)
	lbl.BackgroundTransparency = 1; lbl.Size = UDim2.new(1,0,1,0)
	lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 16; lbl.Text = text
	lbl.TextColor3 = color or Color3.fromRGB(255,255,255)
	lbl.TextStrokeTransparency = 0.3; lbl.TextStrokeColor3 = Color3.new(0,0,0)
end

local function removeESP(instance, tag)
	if not instance then return end
	local hl = instance:FindFirstChild(tag.."_HL"); if hl then hl:Destroy() end
	for _, child in pairs(instance:GetDescendants()) do
		if child.Name == tag.."_BB" then child:Destroy() end
	end
end

local function applyEntranceESP(entrance, tag, color, label)
	if not entrance then return end
	local part = entrance:IsA("BasePart") and entrance or entrance:FindFirstChildWhichIsA("BasePart", true)
	addHighlightESP(entrance, color, Color3.new(1,1,1), tag)
	if part then addBillboardESP(part, label, color, tag) end
	entranceESPTracker[tag] = entrance
end

local function clearEntranceESP(tag)
	local e = entranceESPTracker[tag]; if e then removeESP(e, tag) end
	entranceESPTracker[tag] = nil
end

local function updateParagraph(paraRef, title, content)
	if not paraRef then return end
	pcall(function() paraRef:Set({Title=title, Content=content}) end)
end

-- =====================================================================
-- ENTRANCE DEFINITIONS
-- =====================================================================
local ENTRANCES = {
	{
		key="strangeman", label="👺 Strangeman",
		color=Color3.fromRGB(180,50,255),
		getEntrance=function()
			local ok,r = pcall(function() return Workspace.SM.Door_SMEntrance end)
			return ok and r or nil
		end,
	},
	{
		key="rabbithole", label="🐇 Rabbit Hole",
		color=Color3.fromRGB(255,200,0),
		getEntrance=function()
			local ok,r = pcall(function() return Workspace.RabbitholeEntrance end)
			return ok and r or nil
		end,
	},
	{
		key="pitfall", label="🕳 Pitfall",
		color=Color3.fromRGB(255,80,0),
		getEntrance=function()
			local ok,r = pcall(function() return Workspace.PitfallEntrance end)
			return ok and r or nil
		end,
	},
}

-- Apply ESP for an entrance and update its paragraph
local function refreshEntranceStatus(ev)
	local entrance = ev.getEntrance()
	local para = entranceParagraphs[ev.key]
	if entrance then
		if enabled[ev.key] and espToggles[ev.key] then
			applyEntranceESP(entrance, ev.key, ev.color, ev.label)
		end
		local part = entrance:IsA("BasePart") and entrance or entrance:FindFirstChildWhichIsA("BasePart", true)
		local posStr = part and ("%.0f, %.0f, %.0f"):format(part.Position.X, part.Position.Y, part.Position.Z) or "Unknown"
		updateParagraph(para, ev.label, "✅ Available — Position: "..posStr)
	else
		updateParagraph(para, ev.label, "❌ Not available right now.")
	end
end

local function teleportEntrance(ev)
	if not enabled[ev.key] then
		Rayfield:Notify({Title=ev.label, Content="Enable it first in Features.", Duration=3}) return
	end
	local entrance = ev.getEntrance()
	if not entrance then Rayfield:Notify({Title=ev.label, Content="Not available right now.", Duration=3}) return end
	local part = entrance:IsA("BasePart") and entrance or entrance:FindFirstChildWhichIsA("BasePart", true)
	if part then teleportTo(part.Position + Vector3.new(0,5,0))
	else Rayfield:Notify({Title=ev.label, Content="Entrance has no teleport part.", Duration=3}) end
end

local function onNightBeginEntrances()
	for _, ev in pairs(ENTRANCES) do
		clearEntranceESP(ev.key)
		task.spawn(function()
			task.wait(1) -- brief wait for workspace to settle
			refreshEntranceStatus(ev)
			if enabled[ev.key] then
				local entrance = ev.getEntrance()
				if entrance and notif[ev.key] then
					local bindable = Instance.new("BindableFunction")
					bindable.OnInvoke = function() teleportEntrance(ev) end
					StarterGui:SetCore("SendNotification", {
						Title=ev.label.." Available!", Text="Entrance appeared.",
						Duration=20, Callback=bindable, Button1="Teleport",
					})
				end
			end
		end)
	end
end

-- =====================================================================
-- TRAVELER NPC DEFINITIONS
-- =====================================================================
local TRAVELERS_NIGHT = {
	{name="NPC_Strangeman",   label="Strangeman"},
	{name="NPC_GreenGolem",   label="Green Golem"},
	{name="NPC_ToasterJosh",  label="Toaster Josh"},
}
local TRAVELERS_DAY = {
	{name="NPC_Stick",        label="Stick"},
	{name="NPC_Construct",    label="Construct"},
	{name="NPC_Giver",        label="Interdimensional Traveler"},
	{name="NPC_Junkman",      label="Junkman"},
	{name="NPC_Vhitmire",     label="Vhitmire"},
}

local function findNPCInWorkspace(npcName)
	local npcs = Workspace:FindFirstChild("NPCS")
	if npcs then
		local found = npcs:FindFirstChild(npcName)
		if found then return found end
	end
	return Workspace:FindFirstChild(npcName)
end

local function notifyAndTeleportNPC(npcName, label)
	local entry = travelerWatchList[npcName]
	if not entry or not entry.active then return end
	local npc = findNPCInWorkspace(npcName)
	if npc then
		local part = npc:IsA("BasePart") and npc or npc:FindFirstChildWhichIsA("BasePart", true)
		local bindable = Instance.new("BindableFunction")
		bindable.OnInvoke = function()
			if part then teleportTo(part.Position + Vector3.new(0,5,0)) end
		end
		StarterGui:SetCore("SendNotification", {
			Title="🧭 "..label.." Available!",
			Text="Traveler spotted. Click to teleport.",
			Duration=20, Callback=bindable, Button1="Teleport",
		})
	end
end

local function checkAllTravelers(list)
	for _, t in pairs(list) do
		notifyAndTeleportNPC(t.name, t.label)
	end
end

-- =====================================================================
-- ENTITY WATCHER  (animals, nightmare collectibles, world monsters)
-- =====================================================================
-- Single notification helper for generic entities
local function notifyEntity(instance, label, entityType)
	local part = instance:IsA("BasePart") and instance or instance:FindFirstChildWhichIsA("BasePart", true)
	local bindable = Instance.new("BindableFunction")
	bindable.OnInvoke = function()
		if part and part.Parent then teleportTo(part.Position + Vector3.new(0,5,0)) end
	end
	StarterGui:SetCore("SendNotification", {
		Title="["..entityType.."] "..label.." spotted!",
		Text="Click to teleport.",
		Duration=15, Callback=bindable, Button1="Teleport",
	})
end

local function onInstanceAdded(instance)
	local entry = entityWatchList[instance.Name]
	if entry and entry.active then
		task.spawn(notifyEntity, instance, entry.label, entry.entityType)
	end
	local tEntry = travelerWatchList[instance.Name]
	if tEntry and tEntry.active then
		task.spawn(notifyAndTeleportNPC, instance.Name, tEntry.label)
	end
end

-- Connect watchers to workspace and NPCS folder
local function connectEntityWatchers()
	Workspace.ChildAdded:Connect(onInstanceAdded)
	local npcs = Workspace:FindFirstChild("NPCS")
	if npcs then npcs.ChildAdded:Connect(onInstanceAdded) end
	-- Also watch for NPCS folder being added
	Workspace.ChildAdded:Connect(function(child)
		if child.Name == "NPCS" then
			child.ChildAdded:Connect(onInstanceAdded)
		end
	end)
end
connectEntityWatchers()

-- =====================================================================
-- FIREFLY GOTO
-- =====================================================================
local function teleportToFirefly(firefly)
	local hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	checkTP()
	local hole = Workspace.HOLE.HoleTPEntrance
	if (hrp.Position - firefly.Position).Magnitude >= 200 then
		hole.Size = Vector3.new(1,1,1); hole.Transparency = 1; hole.CFrame = hrp.CFrame
		repeat hole.Position = hrp.Position task.wait() until (hole.Position - hrp.Position).Magnitude < 10
		hole.Position = Vector3.new(1318,85,-527); hole.Size = Vector3.new(14,5,17)
		repeat task.wait() until (hrp.Position - Vector3.new(430,441,102)).Magnitude < 10
		for _ = 1,5 do hrp.Anchored = true; hrp.CFrame = firefly.CFrame + Vector3.new(0,3,0); task.wait(0.1) end
	end
	task.wait()
	if firefly.Parent then
		repeat
			if not ffarm then break end
			hrp = speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
			if not hrp then break end
			hrp.Anchored = true; hrp.CFrame = firefly.CFrame + Vector3.new(0,3,0); hrp.Anchored = false
			task.wait()
			if firefly:FindFirstChild("CollectEvent") then firefly.CollectEvent:FireServer() end
			task.wait(0.08)
		until firefly.Parent == nil
	end
	if hrp then hrp.Anchored = false end
end

-- =====================================================================
-- FROG HELPER
-- =====================================================================
local function updateFrogParagraph()
	if not frogStatusParagraph then return end
	if not enabled.frog then
		updateParagraph(frogStatusParagraph, "🐸 Frog Status", "Frog feature is disabled.")
		return
	end
	local spawner = Workspace.Spawners:FindFirstChild("The Sprutle Frog Expansion_Updated")
	if not spawner then
		updateParagraph(frogStatusParagraph, "🐸 Frog Status", "❌ Frog spawner not found.")
		return
	end
	local frogSpawner = spawner:FindFirstChild("Spawner_GratefulFrogs")
	if not frogSpawner then
		updateParagraph(frogStatusParagraph, "🐸 Frog Status", "❌ Spawner_GratefulFrogs not found.")
		return
	end
	local collectible = frogSpawner:FindFirstChild("Collectible")
	if collectible then
		local part = collectible:FindFirstChildWhichIsA("BasePart")
		if part then
			local pos = ("%.0f, %.0f, %.0f"):format(part.Position.X, part.Position.Y, part.Position.Z)
			updateParagraph(frogStatusParagraph, "🐸 Frog Status", "✅ Frog is available!\nPosition: "..pos)
		else
			updateParagraph(frogStatusParagraph, "🐸 Frog Status", "⚠️ Frog exists but not fully loaded yet.")
		end
	else
		updateParagraph(frogStatusParagraph, "🐸 Frog Status", "❌ No frog right now.")
	end
end

local function tryCollectFrog(doCollect)
	if not enabled.frog then
		if Rayfield then Rayfield:Notify({Title="Frog", Content="Enable Grateful Frog first.", Duration=2}) end
		return
	end
	local spawner = Workspace.Spawners:FindFirstChild("The Sprutle Frog Expansion_Updated")
	if not spawner then
		if Rayfield then Rayfield:Notify({Title="Frog Finder", Content="Frog spawner folder not found.", Duration=3}) end
		return
	end
	local frogSpawner = spawner:FindFirstChild("Spawner_GratefulFrogs")
	if not frogSpawner then
		if Rayfield then Rayfield:Notify({Title="Frog Finder", Content="Spawner_GratefulFrogs not found.", Duration=3}) end
		return
	end
	local collectible = frogSpawner:FindFirstChild("Collectible")
	if collectible then
		local part = collectible:FindFirstChildWhichIsA("BasePart")
		if espToggles.frog and part then
			addHighlightESP(collectible, Color3.fromRGB(0,255,80), Color3.fromRGB(0,200,60), "FrogESP")
			addBillboardESP(part, "🐸 FROG", Color3.fromRGB(0,255,80), "FrogESP")
		end
		if part then
			if notif.frog and Rayfield then Rayfield:Notify({Title="Frog Finder", Content="Frog found! Teleporting...", Duration=3}) end
			teleportTo(part.Position)
			if doCollect then
				for _ = 1,50 do
					task.wait()
					if frogSpawner:FindFirstChild("Collectible") and frogSpawner.Collectible:FindFirstChild("InteractEvent") then
						frogSpawner.Collectible.InteractEvent:FireServer()
					end
				end
				if notif.frog and Rayfield then Rayfield:Notify({Title="Frog Finder", Content="Collection attempt done!", Duration=3}) end
			end
		else
			if notif.frog and Rayfield then Rayfield:Notify({Title="Frog Finder", Content="Frog not loaded. Moving to spawn...", Duration=4}) end
			local tries = 0
			repeat
				local sb = frogSpawner.SpawnLocations:FindFirstChild("SpawnBrick")
				if not sb then break end
				teleportTo(sb.Position + Vector3.new(0,10,0))
				task.wait(0.5); tries += 1
			until frogSpawner.Collectible:FindFirstChildWhichIsA("BasePart")
				or not frogSpawner.SpawnLocations:FindFirstChild("SpawnBrick")
				or tries > 20
			local rp = frogSpawner.Collectible:FindFirstChildWhichIsA("BasePart")
			if rp then
				teleportTo(rp.Position)
				if doCollect then
					for _ = 1,50 do
						task.wait()
						if frogSpawner:FindFirstChild("Collectible") and frogSpawner.Collectible:FindFirstChild("InteractEvent") then
							frogSpawner.Collectible.InteractEvent:FireServer()
						end
					end
					if notif.frog and Rayfield then Rayfield:Notify({Title="Frog Finder", Content="Frog collected!", Duration=3}) end
				end
			else
				if notif.frog and Rayfield then Rayfield:Notify({Title="Frog Finder", Content="Frog failed to load.", Duration=4}) end
			end
		end
	else
		if Rayfield then Rayfield:Notify({Title="Frog Finder", Content="No frog right now.", Duration=3}) end
	end
	updateFrogParagraph()
end

-- =====================================================================
-- DELI HELPERS
-- =====================================================================
local function ringBell() pcall(function() ReplicatedStorage.Events.Deli:FireServer("RingBell"); Players.LocalPlayer.PlayerGui.DeliGui.BellButton.Visible = false end) task.wait() end
local function hideNotifications() pcall(function() if Players.LocalPlayer.PlayerGui.Notification.Enabled then Players.LocalPlayer.PlayerGui.Notification.Enabled = false end end) task.wait() end
local function sitAtDeliBooth() pcall(function() Workspace.Deli.Booth1.InteractEvent:FireServer() end) task.wait() end
local function hideDialogs() pcall(function() if Players.LocalPlayer.PlayerGui.Dialog.Main.Visible then Players.LocalPlayer.PlayerGui.Dialog.Main.Visible = false end end) task.wait() end
local function skipInitialDeliDialog() pcall(function() Workspace.Deli.Booth1.WaiterLocation.Dialog2.D.D1.D1.E.RE1:FireServer() end) task.wait() end

-- =====================================================================
-- SELL LOST ITEMS
-- =====================================================================
local LOST_ITEM_IDS = {982,2223,2224,2225,2276,2228,2229,825,2233,2239,2240,2241,2280,2246,2247,2249,2250,2251,2252,2254,2256,2257,2258,203,2260,2261,2262,1435,205,407}
local function sellLostItems() for _, id in pairs(LOST_ITEM_IDS) do pcall(function() ReplicatedStorage.Events.SellShop:FireServer(id, Workspace.Shops.Sellers, 1) end) end end

-- =====================================================================
-- TELEPORT TABLES
-- =====================================================================
local OVERWORLD_TP = {
	["A Frontier Of Dragons"]=Vector3.new(1184,91,-2823), ["Abandoned Orchard"]=Vector3.new(271,88,-1840),
	["Ancient Forest"]=Vector3.new(676,236,-1246), ["Blackrock Mountain"]=Vector3.new(-594,140,-612),
	["Blue Ogre Camp"]=Vector3.new(-865,57,-1546), ["Celestial Field"]=Vector3.new(1534,92,-2899),
	["Celestial Peak"]=Vector3.new(1473,195,-2483), ["Clamstack Cave"]=Vector3.new(565,158,-952),
	["Coral Bay"]=Vector3.new(1867,1,-2765), ["Farm Fortress"]=Vector3.new(166,53,415),
	["Frigid Waste (PvP)"]=Vector3.new(-1737,155,-785), ["Gnome Magic School"]=Vector3.new(789,240,-574),
	["Great Pine Forest"]=Vector3.new(-13,73,-1274), ["Greenhorn Grove"]=Vector3.new(296,73,-217),
	["Hoodlum Falls"]=Vector3.new(1777,61,-997), ["Matumada"]=Vector3.new(-978,1,-2486),
	["Otherworld Tower"]=Vector3.new(1178,86,-3352), ["Pebble Bay"]=Vector3.new(-44,2,719),
	["Petrified Grassland"]=Vector3.new(1655,73,-1331), ["Pit Depths"]=Vector3.new(1183,-59,-2080),
	["Rabbit Hole"]=Vector3.new(-3233,245,-2623), ["Red Ant Cove"]=Vector3.new(886,63,362),
	["Rubble Spring"]=Vector3.new(1062,73,-534), ["Starry Point"]=Vector3.new(2265,5,481),
	["Strangeman's Domain"]=Vector3.new(-4778,267,732), ["The Deep Forest"]=Vector3.new(1585,73,112),
	["The Forgotten Lands"]=Vector3.new(-779,92,-1200), ["The Long Coast"]=Vector3.new(-1172,3,-1303),
	["The Maze Wood"]=Vector3.new(692,89,-2388), ["The Pits"]=Vector3.new(1320,89,-2430),
	["The Quiet Field"]=Vector3.new(2013,111,-447), ["The Rolling Road"]=Vector3.new(1731,92,-2404),
	["The Spider's Nest"]=Vector3.new(1500,209,-3701), ["The Town of Right and Wrong"]=Vector3.new(1115,92,-3134),
	["Topple Hill"]=Vector3.new(777,199,-312), ["Topple Lake"]=Vector3.new(615,256,-757),
	["Topple Town"]=Vector3.new(685,226,-461), ["Twinkling Meadow"]=Vector3.new(92,73,-752),
	["Upper Island"]=Vector3.new(-1361,35,-2278),
}
local RATBOY_BUTTONS_TP = {
	["Blue Button"]=Vector3.new(7285,172,-2549), ["Cyan (Teal) Button"]=Vector3.new(7203,244,2235),
	["Green Button"]=Vector3.new(7926,157,-3546), ["Orange Button"]=Vector3.new(7129,143,-1587),
	["Pink Button"]=Vector3.new(7208,154,-1717), ["Purple Button"]=Vector3.new(7297,147,-1701),
	["Red Button"]=Vector3.new(7261,200,-2147), ["Yellow Button"]=Vector3.new(8510,214,-1242),
}
local RATBOY_DOORS_TP = {
	["Blue Door"]=Vector3.new(7149,169,-1621), ["Cyan (Teal) Door"]=Vector3.new(7794,204,2212),
	["Green Door"]=Vector3.new(7298,171,-2543), ["Orange Door"]=Vector3.new(6985,141,-1635),
	["Pink Door"]=Vector3.new(7163,168,-1742), ["Purple Door"]=Vector3.new(7021,141,-1689),
	["Red Door"]=Vector3.new(7229,168,-814), ["Yellow Door"]=Vector3.new(7195,168,-1638),
}
local RATBOY_LOC_TP = {
	["Back of The Theatre"]=Vector3.new(7799,172,-3629), ["End of the Road"]=Vector3.new(10779,375,-12512),
	["Fish Hall"]=Vector3.new(12905,205,5036), ["Inside"]=Vector3.new(7311,171,-2558),
	["Maze of the Root"]=Vector3.new(13132,191,7532), ["Meeting Place"]=Vector3.new(7514,237,-4952),
	["MYSTERY STORE"]=Vector3.new(6765,200,-2545), ["The Back Area"]=Vector3.new(7206,244,2122),
	["The Ballroom"]=Vector3.new(11825,318,2432), ["The Deli"]=Vector3.new(7070,140,-1621),
	["The Grand Hall"]=Vector3.new(5928,211,4845), ["The Hidden Library"]=Vector3.new(8170,187,-949),
	["The Library of Riddles"]=Vector3.new(7332,157,-1636), ["The Lost"]=Vector3.new(5858,157,4904),
	["The Mansion"]=Vector3.new(7003,140,-1639), ["The Old Cave"]=Vector3.new(13099,174,6944),
	["The Old Mansion"]=Vector3.new(7242,168,-2114), ["The Plant Room"]=Vector3.new(7066,159,-855),
	["The Road"]=Vector3.new(10759,201,8595), ["The Supermarket"]=Vector3.new(7252,202,2269),
	["The Theatre"]=Vector3.new(7510,147,-3613), ["The Vault"]=Vector3.new(5740,224,-3178),
	["Waiting Room"]=Vector3.new(12398,284,-5296),
}
local HOUSING_TP = {
	["Black Tower (Celestial Field)"]=Vector3.new(1387,137,-3217), ["Boathouse (Long Coast)"]=Vector3.new(-484,4,-1692),
	["Castle (Topple Town)"]=Vector3.new(589,312,-678), ["Ice Spire (Matumada)"]=Vector3.new(-2169,40,-1229),
	["Starter House (Topple Town)"]=Vector3.new(641,237,-462), ["Two Story House (Topple Town)"]=Vector3.new(626,258,-552),
	["White Tower (Quiet Field)"]=Vector3.new(2092,121,-458),
}
local VENDOR_TP = {
	["Amy Thistlewitch"]=Vector3.new(-2937,228,-665), ["Arbewhy"]=Vector3.new(-2939,230,-1156),
	["Archaeologist"]=Vector3.new(1553,72,-1632),
}

-- =====================================================================
-- REFERENCE LISTS  (for watchlist dropdowns)
-- =====================================================================
local ANIMAL_NAMES = {
	"Red Bird","Owl","Rednal","Looter's Bird","Black Bird","Red Beaked Clown Bird","Money Bird","Glider Bird",
	"Greenal","Laurel Bird","Kooma Bird","Linter Bird","Glowbird","Frester","Red Dragon Bird","Bluenal",
	"Dust Raptor","Dark Owl","Black Dragon Bird","Weather Bird","BigBeakedPotatoBird","Gelidbird","Beach Bird",
	"Applestack Bird","Keemal","Speeven","Gull","Fallbird","Polewatcher","Preobird","Spirit Bird","GhostBat",
	"Bat","MonsterBird","Red-Tipped Bulwark","Woodnal","Moving Cogger","NPC_Deer","RabbitNPC",
}
local NIGHTMARE_COLLECTIBLE_NAMES = {
	"BadDust","BookofCorruptedTales","ChangingMachine","Clock","CollectionBox","ConcentrationCube",
	"CopperLabyrinth","CrumblingRoot","CursedCards","DangerHead","DreamDust","DreamMushroom","FreedomCube",
	"LiquidMaze","NightmareFlower","Plugstack","PowerLamp","ReplicationFear","RoadRadio","ShoppingRadio",
	"TheatreTicket","TwigScreech","PlasticShell","BrainToothpaste","JerkToothpaste","TexturedTeakettle",
	"TinyClownDoll","Produce","MegaSupremePotentEnergy","FakePowerLamp","CaughtManNPC","RunnerNPC","RunningManNPC",
}
local MONSTER_NPC_NAMES = {
	"OgreNPC","ScarecrowNPC","AltFantasticDragonNPC","FloatingHeadNPC","LittleAntNPC","BrickfaceNPC",
	"HammerKnightNPC","CrocNPC","IronAncientKnightNPC","MountainWolfNPC","FrogNPC","RedOgreNPC",
	"MagmaWormNPC_Beast","GoldAncientKnightNPC","FantasticDragonNPC","GolemGiantNPC","InfernoBatNPC",
	"MagmaBeastNPC","RoboHopperNPC","CobaltAncientKnightNPC","BlackBearNPC","SnibberNPC",
	"ForestProtectorNPC","ForestGiantNPC","SlimeWormNPC","BeachWalkerNPC","LegendMonstrosityNPC",
	"BigCrocNPC","MountainProtectorNPC","AppleBatNPC","EyeballAlienNPC","MonstrosityNPC","BlackAntNPC",
	"MountainGiantNPC","RatdogNPC","MunskNPC","AntNPC","RedLanternNPC","InspectorNPC","PurpleOgreNPC",
	"BluemanNPC","YellowmanNPC","SnowyOnyxAncientKnightNPC","FrostKnightNPC","DirtShlashkNPC","RedPirateNPC",
	"BlueLanternNPC","YellowPirateNPC","AlienKnightNPC","GreenFloatingHeadNPC","FireMageNPC","OceanGiantNPC",
	"TitaniumAncientKnightNPC","Bandit1NPC","MandrakeNPC","BanditSpiderNPC","GumboNPC","DarkFloatingHeadNPC",
	"ShellMouthNPC","ForestWalkerNPC","DollNPC","DarkSnibberNPC","OrangeMaskedMunsklinNPC","BushMoleNPC",
	"MushroomNPC","RatboyNPC","Bandit3NPC","Bandit2NPC","Bandit4NPC","ForestTrollNPC","FarNorthBluemanNPC",
	"WhispererNPC","LHSlimeWormNPC","BluePirateNPC","FunkyDriftingLandNPC","ToonMoleNPC","BearNPC","JesterNPC",
	"ShlashkNPC","LongBearNPC","BossWalkerNPC","YellowGoonNPC","CricketNPC","GhostLanternNPC","IndustryGiantNPC",
	"NightmareWolfNPC","LifeScarecrowNPC","PhantomKnightNPC","PhantomNPC","CandleStickNPC","PathGamblerNPC",
	"CorruptGoldKnightNPC","CorruptOnyxKnightNPC","DataMiteNPC","DemocanNPC","FlyingClownNPC","GanglySpiderNPC",
	"GolemBaronNPC","Goon1NPC","Goon2NPC","Goon3NPC","YellerNPC","SpikerNPC","BoomerNPC","TrafficBusterNPC",
	"DarkRedOgreNPC","YellowOgreNPC","ClownBuggyNPC","CircusNPC","EggCrocNPC","RedmanNPC","MaroonAntNPC",
	"FirstKnightNPC","GreenPirateNPC","RedFloatingMonsterHeadNPC","CosmicFloatingMonsterHeadNPC",
}

-- =====================================================================
-- SHOP HELPERS
-- =====================================================================
local function getShopNames()
	local names = {}
	if not Workspace:FindFirstChild("Shops") then return names end
	for _, shop in pairs(Workspace.Shops:GetChildren()) do
		if shop:FindFirstChild("Slots") then table.insert(names, shop.Name) end
	end
	table.sort(names); return names
end

local function getShopPosition(shopName)
	if shopPositionCache[shopName] then return shopPositionCache[shopName] end
	local shops = Workspace:FindFirstChild("Shops"); if not shops then return nil end
	local shop = shops:FindFirstChild(shopName); if not shop then return nil end
	local part = shop:FindFirstChildWhichIsA("BasePart", true)
	if part then shopPositionCache[shopName] = part.Position; return part.Position end
	return nil
end

local function getShopItems(shopName)
	local shops = Workspace:FindFirstChild("Shops"); if not shops then return {} end
	local shop = shops:FindFirstChild(shopName)
	if not shop or not shop:FindFirstChild("Slots") then return {} end
	local result = {}
	for _, slot in pairs(shop.Slots:GetChildren()) do
		local itemSlot = slot:FindFirstChild("Item"); local priceSlot = slot:FindFirstChild("Price")
		if itemSlot then
			local itemId = tonumber(itemSlot.Value)
			local price  = priceSlot and formatNumber(priceSlot.Value) or "?"
			for _, info in pairs(ReplicatedStorage.ItemInfo:GetChildren()) do
				if tonumber(info.Name) == itemId then
					local fn = info:FindFirstChild("FullName")
					if fn then table.insert(result, {name=fn.Value, price=price, id=itemId}) end
					break
				end
			end
		end
	end
	return result
end

local function findWatchedItemsInShops()
	local found = {}; local shops = Workspace:FindFirstChild("Shops"); if not shops then return found end
	for _, watched in pairs(watchedShopItems) do
		if watched.active then
			for _, shop in pairs(shops:GetChildren()) do
				if shop:FindFirstChild("Slots") then
					for _, slot in pairs(shop.Slots:GetChildren()) do
						local iSlot = slot:FindFirstChild("Item"); local pSlot = slot:FindFirstChild("Price")
						if iSlot and tonumber(iSlot.Value) == watched.id then
							table.insert(found, {itemName=watched.name, shopName=shop.Name, price=pSlot and formatNumber(pSlot.Value) or "?"})
						end
					end
				end
			end
		end
	end
	return found
end

local function notifyShopItem(itemName, shopName, price)
	local bindable = Instance.new("BindableFunction")
	bindable.OnInvoke = function()
		local pos = getShopPosition(shopName)
		if pos then teleportTo(pos + Vector3.new(0,5,0)); Rayfield:Notify({Title="Teleported", Content="Arrived at "..shopName, Duration=3}) end
	end
	StarterGui:SetCore("SendNotification", {
		Title="🛒 "..itemName.." in stock!", Text=shopName.." — "..price.."g",
		Icon="rbxassetid://1053360438", Duration=15, Callback=bindable, Button1="Teleport to Shop",
	})
end

local function refreshShopWatcher()
	local hits = findWatchedItemsInShops()
	for _, hit in pairs(hits) do notifyShopItem(hit.itemName, hit.shopName, hit.price); task.wait(0.3) end
end

local function buildShopItemsDisplay(shopName)
	if not shopItemParagraph then return end
	if not shopName or shopName == "No shops found" then
		updateParagraph(shopItemParagraph, "Shop Items", "Select a shop above."); return
	end
	local items = getShopItems(shopName)
	if #items == 0 then
		updateParagraph(shopItemParagraph, shopName, "Empty or items couldn't be read."); return
	end
	local lines = {}
	for _, item in pairs(items) do table.insert(lines, "• "..item.name.."  —  "..item.price.."g") end
	updateParagraph(shopItemParagraph, "🛒 "..shopName.." ("..#items.." items)", table.concat(lines, "\n"))
end

-- =====================================================================
-- PRESENT HELPERS
-- =====================================================================
local LatestPresent = nil; local LatestPresentModel = nil

local function updatePresentParagraph()
	if not presentStatusParagraph then return end
	if not enabled.present then
		updateParagraph(presentStatusParagraph, "🎁 Present Status", "Present feature is disabled."); return
	end
	if LatestPresent and LatestPresent.Parent then
		local pos = ("%.0f, %.0f, %.0f"):format(LatestPresent.Position.X, LatestPresent.Position.Y, LatestPresent.Position.Z)
		updateParagraph(presentStatusParagraph, "🎁 Present Status", "✅ Present available!\nPosition: "..pos)
	else
		updateParagraph(presentStatusParagraph, "🎁 Present Status", "❌ No present detected yet.")
	end
end

local function markPresent(part)
	if not espToggles.present then return end
	if part:FindFirstChild("PresentESP_BB") then return end
	addBillboardESP(part, "🎁 PRESENT", Color3.fromRGB(255,80,80), "PresentESP")
	addHighlightESP(part.Parent or part, Color3.fromRGB(255,50,50), Color3.new(1,1,1), "PresentESP")
end

local presentBindable = Instance.new("BindableFunction")
presentBindable.OnInvoke = function()
	if not enabled.present then return end
	if LatestPresent and LatestPresent.Parent then
		teleportTo(LatestPresent.Position)
		if autoCollect.present then
			task.wait(0.3)
			local m = LatestPresentModel; local attempts = 0
			repeat
				pcall(function()
					local ie = m:FindFirstChild("InteractEvent") or m:FindFirstChildOfClass("RemoteEvent")
					if ie then ie:FireServer() end
				end)
				task.wait(0.1); attempts += 1
			until not m or not m.Parent or not autoCollect.present or attempts > 100
		end
		Rayfield:Notify({Title="Teleported!", Content="Arrived at present.", Duration=3})
	end
end

local function onPresentFound(present)
	repeat task.wait() until present:FindFirstChild("PP")
	local part = present:FindFirstChildOfClass("Part")
	if not part then return end
	markPresent(part)
	LatestPresent = part; LatestPresentModel = present
	updatePresentParagraph()
	if not enabled.present then return end
	if notif.present then
		StarterGui:SetCore("SendNotification", {
			Title="🎁 Present Found!", Text="A new present has spawned!",
			Icon="rbxassetid://1053360438", Duration=10, Callback=presentBindable, Button1="Teleport to Present",
		})
	end
end

for _, child in pairs(Workspace:GetChildren()) do
	if string.sub(string.lower(child.Name),1,7) == "present" and #child.Name == 8 then task.spawn(onPresentFound, child) end
end
Workspace.ChildAdded:Connect(function(child)
	if string.sub(string.lower(child.Name),1,7) == "present" and #child.Name == 8 then task.spawn(onPresentFound, child) end
end)

-- =====================================================================
-- RAYFIELD INIT
-- =====================================================================
Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name="FF Hub", LoadingTitle="FF Hub", LoadingSubtitle="by SeventhBuilder",
	Theme="Default", DisableRayfieldPrompts=false,
	ConfigurationSaving={Enabled=true, FileName="FFHub_Config"}, KeySystem=false,
})

local FeaturesTab  = Window:CreateTab("Features",  5012544092)
local AutoFarmTab  = Window:CreateTab("AutoFarm",  5012543246)
local TeleportsTab = Window:CreateTab("Teleports", 5012543481)
local PlayerTab    = Window:CreateTab("Player",    5012544693)
local ShopsTab     = Window:CreateTab("Shops",     4483345998)
local SettingsTab  = Window:CreateTab("Settings",  5012544372)

StarterGui:SetCore("SendNotification", {Title="FF Hub", Text="Loaded! by SeventhBuilder"})

-- Night/Day event hooks
ReplicatedStorage.Events.NightBegin.OnClientEvent:Connect(function()
	shopPositionCache = {}
	task.wait(2)
	onNightBeginEntrances()
	refreshShopWatcher()
	checkAllTravelers(TRAVELERS_NIGHT)
	if selectedShopName then buildShopItemsDisplay(selectedShopName) end
end)

pcall(function()
	ReplicatedStorage.Events.DayBegin.OnClientEvent:Connect(function()
		task.wait(2)
		checkAllTravelers(TRAVELERS_DAY)
	end)
end)

-- =====================================================================
-- FEATURES TAB
-- =====================================================================

-- ── Present ──────────────────────────────────────────────────────────
FeaturesTab:CreateSection("🎁 Present")
FeaturesTab:CreateToggle({Name="Enable Present", CurrentValue=false, Flag="EnablePresent",
	Callback=function(v)
		enabled.present = v
		updatePresentParagraph()
		Rayfield:Notify({Title="Present", Content=v and "Enabled" or "Disabled", Duration=2})
	end})
FeaturesTab:CreateToggle({Name="Auto Collect on Teleport", CurrentValue=false, Flag="PresentAutoCollect",
	Callback=function(v) autoCollect.present = v end})
FeaturesTab:CreateButton({Name="Teleport to Latest Present", Callback=function()
	if not enabled.present then Rayfield:Notify({Title="Present", Content="Enable Present first.", Duration=2}); return end
	if LatestPresent and LatestPresent.Parent then
		teleportTo(LatestPresent.Position)
		if autoCollect.present then
			task.wait(0.3); local m = LatestPresentModel; local attempts = 0
			repeat
				pcall(function()
					local ie = m:FindFirstChild("InteractEvent") or m:FindFirstChildOfClass("RemoteEvent")
					if ie then ie:FireServer() end
				end)
				task.wait(0.1); attempts += 1
			until not m or not m.Parent or not autoCollect.present or attempts > 100
		end
	else Rayfield:Notify({Title="Present", Content="No present detected yet.", Duration=3}) end
end})
-- Paragraph: live present status (assigned when section is created)
presentStatusParagraph = FeaturesTab:CreateParagraph({Title="🎁 Present Status", Content="Enable Present to begin tracking."})

-- ── Grateful Frog ─────────────────────────────────────────────────────
FeaturesTab:CreateSection("🐸 Grateful Frog")
FeaturesTab:CreateToggle({Name="Enable Grateful Frog", CurrentValue=false, Flag="EnableFrog",
	Callback=function(v)
		enabled.frog = v
		updateFrogParagraph()
		if v then
			-- Apply ESP immediately if frog exists
			local spawner = Workspace.Spawners:FindFirstChild("The Sprutle Frog Expansion_Updated")
			if spawner then
				local fs = spawner:FindFirstChild("Spawner_GratefulFrogs")
				if fs and fs:FindFirstChild("Collectible") and espToggles.frog then
					local part = fs.Collectible:FindFirstChildWhichIsA("BasePart")
					if part then
						addHighlightESP(fs.Collectible, Color3.fromRGB(0,255,80), Color3.fromRGB(0,200,60), "FrogESP")
						addBillboardESP(part, "🐸 FROG", Color3.fromRGB(0,255,80), "FrogESP")
					end
				end
			end
		end
		Rayfield:Notify({Title="Frog", Content=v and "Enabled" or "Disabled", Duration=2})
	end})
FeaturesTab:CreateToggle({Name="Auto Collect on Teleport", CurrentValue=false, Flag="FrogAutoCollect",
	Callback=function(v) autoCollect.frog = v end})
FeaturesTab:CreateButton({Name="Teleport & Get Grateful Frog", Callback=function()
	task.spawn(tryCollectFrog, autoCollect.frog)
end})
frogStatusParagraph = FeaturesTab:CreateParagraph({Title="🐸 Frog Status", Content="Enable Frog to begin tracking."})

-- ── Monsters ──────────────────────────────────────────────────────────
FeaturesTab:CreateSection("🧟 Monsters")
FeaturesTab:CreateToggle({Name="Enable Cosmic Ghost", CurrentValue=false, Flag="EnableCosmic",
	Callback=function(v) enabled.cosmic=v; Rayfield:Notify({Title="Cosmic Ghost", Content=v and "Enabled" or "Disabled", Duration=2}) end})
FeaturesTab:CreateButton({Name="Check Cosmic Ghost", Callback=function()
	if not enabled.cosmic then Rayfield:Notify({Title="Cosmic Ghost", Content="Enable it first.", Duration=2}); return end
	local npcs = Workspace:FindFirstChild("NPCS")
	if npcs and npcs:FindFirstChild("CosmicFloatingMonsterHeadNPC") then
		local part = npcs.CosmicFloatingMonsterHeadNPC:FindFirstChildWhichIsA("BasePart", true)
		Rayfield:Notify({Title="Cosmic Ghost", Content=part and "Found! Use Teleport." or "Found but not loaded.", Duration=4})
	else Rayfield:Notify({Title="Cosmic Ghost", Content="Not in this server.", Duration=3}) end
end})
FeaturesTab:CreateButton({Name="Teleport to Cosmic Ghost", Callback=function()
	if not enabled.cosmic then Rayfield:Notify({Title="Cosmic Ghost", Content="Enable it first.", Duration=2}); return end
	local npcs = Workspace:FindFirstChild("NPCS")
	if npcs and npcs:FindFirstChild("CosmicFloatingMonsterHeadNPC") then
		local part = npcs.CosmicFloatingMonsterHeadNPC:FindFirstChildWhichIsA("BasePart", true)
		if part then teleportTo(part.Position + Vector3.new(10,10,10))
		else Rayfield:Notify({Title="Cosmic Ghost", Content="Not loaded yet.", Duration=3}) end
	else Rayfield:Notify({Title="Cosmic Ghost", Content="Not found.", Duration=3}) end
end})

FeaturesTab:CreateToggle({Name="Enable Path Gambler", CurrentValue=false, Flag="EnableGambler",
	Callback=function(v) enabled.gambler=v; Rayfield:Notify({Title="Path Gambler", Content=v and "Enabled" or "Disabled", Duration=2}) end})
FeaturesTab:CreateButton({Name="Check Path Gambler", Callback=function()
	if not enabled.gambler then Rayfield:Notify({Title="Path Gambler", Content="Enable it first.", Duration=2}); return end
	local npcs = Workspace:FindFirstChild("NPCS")
	if npcs and npcs:FindFirstChild("PathGamblerNPC") then
		local part = npcs.PathGamblerNPC:FindFirstChildWhichIsA("BasePart", true)
		Rayfield:Notify({Title="Path Gambler", Content=part and "Found! Use Teleport." or "Found but not loaded.", Duration=4})
	else Rayfield:Notify({Title="Path Gambler", Content="Not in this server.", Duration=3}) end
end})
FeaturesTab:CreateButton({Name="Teleport to Path Gambler", Callback=function()
	if not enabled.gambler then Rayfield:Notify({Title="Path Gambler", Content="Enable it first.", Duration=2}); return end
	local npcs = Workspace:FindFirstChild("NPCS")
	if npcs and npcs:FindFirstChild("PathGamblerNPC") then
		local part = npcs.PathGamblerNPC:FindFirstChildWhichIsA("BasePart", true)
		if part then teleportTo(part.Position + Vector3.new(0,4,0))
		else Rayfield:Notify({Title="Path Gambler", Content="Not loaded yet.", Duration=3}) end
	else Rayfield:Notify({Title="Path Gambler", Content="Not found.", Duration=3}) end
end})

FeaturesTab:CreateSection("🔍 Monster Spawn Watcher")
FeaturesTab:CreateLabel("Select a monster below to add it to your spawn notification list.")
FeaturesTab:CreateDropdown({Name="Add Monster to Watch", Options=MONSTER_NPC_NAMES,
	CurrentOption={""}, MultipleOptions=false, SearchEnabled=true,
	Callback=function(opt)
		local name = opt[1]
		if name == "" then return end
		if entityWatchList[name] then
			Rayfield:Notify({Title="Monster Watcher", Content="Already watching: "..name, Duration=3}); return
		end
		local entry = {label=name, active=true, entityType="Monster"}
		entityWatchList[name] = entry
		FeaturesTab:CreateToggle({Name="👾 "..name, CurrentValue=true,
			Callback=function(v) entry.active = v end})
		Rayfield:Notify({Title="Monster Watcher", Content="Now watching: "..name, Duration=3})
	end})

-- ── Entrances ─────────────────────────────────────────────────────────
FeaturesTab:CreateSection("🚪 Entrances")
for _, ev in pairs(ENTRANCES) do
	local evRef = ev
	FeaturesTab:CreateToggle({
		Name="Enable "..ev.label, CurrentValue=false, Flag="Enable_"..ev.key,
		Callback=function(v)
			enabled[evRef.key] = v
			if not v then
				clearEntranceESP(evRef.key)
				updateParagraph(entranceParagraphs[evRef.key], evRef.label, "Disabled.")
			else
				-- Immediately check and apply ESP
				refreshEntranceStatus(evRef)
			end
			Rayfield:Notify({Title=evRef.label, Content=v and "Enabled" or "Disabled", Duration=2})
		end})
	-- Paragraph viewer instead of Check button
	entranceParagraphs[ev.key] = FeaturesTab:CreateParagraph({Title=ev.label, Content="Enable above to check status."})
	FeaturesTab:CreateButton({Name="Teleport to "..ev.label, Callback=function() teleportEntrance(evRef) end})
end

-- ── Travelers ─────────────────────────────────────────────────────────
FeaturesTab:CreateSection("🧭 Traveler NPCs — Night")
FeaturesTab:CreateLabel("Checked travelers fire a notification when they appear at NightBegin.")
for _, t in pairs(TRAVELERS_NIGHT) do
	travelerWatchList[t.name] = {label=t.label, active=false, isNight=true}
	FeaturesTab:CreateToggle({Name=t.label, CurrentValue=false,
		Callback=function(v) travelerWatchList[t.name].active = v end})
	FeaturesTab:CreateButton({Name="Teleport to "..t.label, Callback=function()
		local npc = findNPCInWorkspace(t.name)
		if npc then
			local part = npc:IsA("BasePart") and npc or npc:FindFirstChildWhichIsA("BasePart", true)
			if part then teleportTo(part.Position + Vector3.new(0,5,0))
			else Rayfield:Notify({Title=t.label, Content="Found but not loaded.", Duration=3}) end
		else Rayfield:Notify({Title=t.label, Content="Not available right now.", Duration=3}) end
	end})
end

FeaturesTab:CreateSection("🧭 Traveler NPCs — Day")
for _, t in pairs(TRAVELERS_DAY) do
	travelerWatchList[t.name] = {label=t.label, active=false, isNight=false}
	FeaturesTab:CreateToggle({Name=t.label, CurrentValue=false,
		Callback=function(v) travelerWatchList[t.name].active = v end})
	FeaturesTab:CreateButton({Name="Teleport to "..t.label, Callback=function()
		local npc = findNPCInWorkspace(t.name)
		if npc then
			local part = npc:IsA("BasePart") and npc or npc:FindFirstChildWhichIsA("BasePart", true)
			if part then teleportTo(part.Position + Vector3.new(0,5,0))
			else Rayfield:Notify({Title=t.label, Content="Found but not loaded.", Duration=3}) end
		else Rayfield:Notify({Title=t.label, Content="Not available right now.", Duration=3}) end
	end})
end

-- ── Animals ───────────────────────────────────────────────────────────
FeaturesTab:CreateSection("🐦 Animal Spawn Watcher")
FeaturesTab:CreateLabel("Select an animal below to get notified when it spawns nearby.")
FeaturesTab:CreateDropdown({Name="Add Animal to Watch", Options=ANIMAL_NAMES,
	CurrentOption={""}, MultipleOptions=false, SearchEnabled=true,
	Callback=function(opt)
		local name = opt[1]; if name == "" then return end
		if entityWatchList[name] then
			Rayfield:Notify({Title="Animal Watcher", Content="Already watching: "..name, Duration=3}); return
		end
		local entry = {label=name, active=true, entityType="Animal"}
		entityWatchList[name] = entry
		FeaturesTab:CreateToggle({Name="🐦 "..name, CurrentValue=true,
			Callback=function(v) entry.active = v end})
		Rayfield:Notify({Title="Animal Watcher", Content="Now watching: "..name, Duration=3})
	end})

-- ── Nightmare Collectibles ─────────────────────────────────────────────
FeaturesTab:CreateSection("💀 Nightmare Collectible Watcher")
FeaturesTab:CreateLabel("Select a collectible to get notified when it spawns.")
FeaturesTab:CreateDropdown({Name="Add Collectible to Watch", Options=NIGHTMARE_COLLECTIBLE_NAMES,
	CurrentOption={""}, MultipleOptions=false, SearchEnabled=true,
	Callback=function(opt)
		local name = opt[1]; if name == "" then return end
		if entityWatchList[name] then
			Rayfield:Notify({Title="Collectible Watcher", Content="Already watching: "..name, Duration=3}); return
		end
		local entry = {label=name, active=true, entityType="Collectible"}
		entityWatchList[name] = entry
		FeaturesTab:CreateToggle({Name="💀 "..name, CurrentValue=true,
			Callback=function(v) entry.active = v end})
		Rayfield:Notify({Title="Collectible Watcher", Content="Now watching: "..name, Duration=3})
	end})

-- ── Performance & Abilities ────────────────────────────────────────────
FeaturesTab:CreateSection("⚡ Performance")
FeaturesTab:CreateButton({Name="Remove All Trees", Callback=function()
	for _, obj in pairs(Workspace:GetDescendants()) do
		for _, n in pairs({"PostTrees","Tree_A_1","Tree_B_1","Tree_B_2","Tree_C_1","Tree_D_1","Tree_D_2"}) do
			if obj.Name == n then obj:Destroy() end
		end
	end
	Rayfield:Notify({Title="Performance", Content="Trees removed!", Duration=3})
end})
FeaturesTab:CreateButton({Name="Remove All Vegetation", Callback=function()
	for _, obj in pairs(Workspace:GetDescendants()) do
		for _, n in pairs({"GrassyRootSystemPart","BushLeafPart","LilyPadPart","FlowerPart","BushPart","CropPartSQ","GrassPart","TallGrassPartSmall","DeadShrubPart","PlantPart","Trunk","Root","Leaves","LeafPart","WeedPart"}) do
			if obj.Name == n then obj:Destroy() end
		end
		if obj:IsA("MeshPart") and obj.MeshId == "rbxassetid://511992639" then obj:Destroy() end
	end
	Rayfield:Notify({Title="Performance", Content="Vegetation removed!", Duration=3})
end})
FeaturesTab:CreateButton({Name="Remove All Rocks", Callback=function()
	for _, obj in pairs(Workspace:GetDescendants()) do
		if obj.Name == "LargeRockPart" or obj.Name == "RockPart" then obj:Destroy() end
	end
	Rayfield:Notify({Title="Performance", Content="Rocks removed!", Duration=3})
end})

FeaturesTab:CreateSection("🧰 Abilities")
FeaturesTab:CreateButton({Name="Remove Fog", Callback=function()
	pcall(function()
		if speaker.PlayerScripts:FindFirstChild("Fog") then speaker.PlayerScripts.Fog:Destroy() end
		if speaker.Character:FindFirstChild("Fogbox") then
			for _, ring in pairs({"Ring1","Ring2","Ring3"}) do
				local r = speaker.Character.Fogbox:FindFirstChild(ring); if r then r:Destroy() end
			end
		end
	end)
	Rayfield:Notify({Title="Abilities", Content="Fog removed!", Duration=3})
end})
FeaturesTab:CreateButton({Name="Faster Kills", Callback=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/SeventhBuilder/FF/main/scripts/faster-kills.lua"))() end})
FeaturesTab:CreateButton({Name="Fast Regen Stamina", Callback=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/SeventhBuilder/FF/main/scripts/fast-regen-stamina.lua"))() end})
FeaturesTab:CreateButton({Name="Bring Spider Boss Closer", Callback=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/JustApstl/FF/refs/heads/main/scripts/bring-spider-boss-closer-to-topple-town.lua"))() end})
FeaturesTab:CreateButton({Name="Teleport to Uncollected Ratboy Token", Callback=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/JustApstl/FF/refs/heads/main/scripts/teleport-to-uncollected-ratboy-token.lua"))() end})

-- =====================================================================
-- AUTOFARM TAB
-- =====================================================================
AutoFarmTab:CreateSection("🪲 Firefly Stones")
AutoFarmTab:CreateToggle({Name="Firefly Stones AutoFarm", CurrentValue=false, Flag="FireflyFarm",
	Callback=function(v) ffarm=v; if v then checkTP() end; Rayfield:Notify({Title="AutoFarm", Content="Firefly "..(v and "ON" or "OFF"), Duration=2}) end})

AutoFarmTab:CreateSection("🪺 Bird Nests")
AutoFarmTab:CreateToggle({Name="Bird Nests AutoFarm", CurrentValue=false, Flag="BirdFarm",
	Callback=function(v) bfarm=v; if v then teleportTo(Vector3.new(-1405,325,-2271)); task.wait(1); checkTP() end; Rayfield:Notify({Title="AutoFarm", Content="Bird Nests "..(v and "ON" or "OFF"), Duration=2}) end})

AutoFarmTab:CreateSection("🍔 Deli")
AutoFarmTab:CreateDropdown({Name="Deli Mode", Options={"Both (Random)","Short Wait","Long Wait"},
	CurrentOption={"Both (Random)"}, Flag="DeliMode",
	Callback=function(opt) shortwait=opt[1]=="Short Wait"; longwait=opt[1]=="Long Wait"; randomboth=opt[1]=="Both (Random)" end})
AutoFarmTab:CreateToggle({Name="Deli AutoFarm", CurrentValue=false, Flag="DeliFarm",
	Callback=function(v) dfarm=v; if v then teleportTo(Vector3.new(7066,144,-1621)); task.wait(3) end; Rayfield:Notify({Title="AutoFarm", Content="Deli "..(v and "ON" or "OFF"), Duration=2}) end})

AutoFarmTab:CreateSection("💀 The Lost  (PATCHED — Requires Hidden Key)")
AutoFarmTab:CreateToggle({Name="Lost AutoFarm", CurrentValue=false, Flag="LostFarm",
	Callback=function(v)
		if v then
			local hasKey = false
			pcall(function()
				for _, item in pairs(Players.LocalPlayer.PlayerGui.Container.Main["INV_SF"]:GetDescendants()) do
					if item.Name=="ItemCode" and item.Value==2025 then hasKey=true; break end
				end
			end)
			if hasKey then
				amountEmptyInventory=20; lfarm=true; teleportTo(Vector3.new(5857,157,4907)); task.wait(1.5)
				Rayfield:Notify({Title="AutoFarm", Content="Lost Farm ON", Duration=3})
			else lfarm=false; Rayfield:Notify({Title="AutoFarm", Content="❌ Hidden Key required!", Duration=5}) end
		else lfarm=false; amountEmptyInventory=20; Rayfield:Notify({Title="AutoFarm", Content="Lost Farm OFF", Duration=2}) end
	end})

-- =====================================================================
-- TELEPORTS TAB  (Shops FIRST at top)
-- =====================================================================

-- Shops teleport at the very top
task.spawn(function()
	repeat task.wait(0.2) until Workspace:FindFirstChild("Shops")
	local sNames = getShopNames()
	if #sNames > 0 then
		TeleportsTab:CreateSection("🛒 Shops")
		TeleportsTab:CreateDropdown({Name="Teleport to Shop", SearchEnabled=true,
			CurrentOption={""}, MultipleOptions=false, Options=sNames,
			Callback=function(opt)
				local pos = getShopPosition(opt[1])
				if pos then teleportTo(pos + Vector3.new(0,5,0))
				else Rayfield:Notify({Title="Shops", Content="Can't resolve position for "..opt[1], Duration=3}) end
			end})
	end
end)

TeleportsTab:CreateSection("🌍 Overworld")
TeleportsTab:CreateDropdown({Name="Overworld Location", SearchEnabled=true, CurrentOption={""}, MultipleOptions=false,
	Options={
		"A Frontier Of Dragons","Abandoned Orchard","Ancient Forest","Blackrock Mountain","Blue Ogre Camp",
		"Celestial Field","Celestial Peak","Clamstack Cave","Coral Bay","Farm Fortress","Frigid Waste (PvP)",
		"Gnome Magic School","Great Pine Forest","Greenhorn Grove","Hoodlum Falls","Matumada","Otherworld Tower",
		"Pebble Bay","Petrified Grassland","Pit Depths","Rabbit Hole","Red Ant Cove","Rubble Spring",
		"Starry Point","Strangeman's Domain","The Deep Forest","The Forgotten Lands","The Long Coast",
		"The Maze Wood","The Pits","The Quiet Field","The Rolling Road","The Spider's Nest",
		"The Town of Right and Wrong","Topple Hill","Topple Lake","Topple Town","Twinkling Meadow","Upper Island",
	},
	Callback=function(opt) if OVERWORLD_TP[opt[1]] then teleportTo(OVERWORLD_TP[opt[1]]) end end})

TeleportsTab:CreateSection("👺 Ratboy's Nightmare — Buttons")
TeleportsTab:CreateDropdown({Name="Buttons", SearchEnabled=true, CurrentOption={""}, MultipleOptions=false,
	Options={"Blue Button","Cyan (Teal) Button","Green Button","Orange Button","Pink Button","Purple Button","Red Button","Yellow Button"},
	Callback=function(opt) if RATBOY_BUTTONS_TP[opt[1]] then teleportTo(RATBOY_BUTTONS_TP[opt[1]]) end end})

TeleportsTab:CreateSection("👺 Ratboy's Nightmare — Doors")
TeleportsTab:CreateDropdown({Name="Doors", SearchEnabled=true, CurrentOption={""}, MultipleOptions=false,
	Options={"Blue Door","Cyan (Teal) Door","Green Door","Orange Door","Pink Door","Purple Door","Red Door","Yellow Door"},
	Callback=function(opt) if RATBOY_DOORS_TP[opt[1]] then teleportTo(RATBOY_DOORS_TP[opt[1]]) end end})

TeleportsTab:CreateSection("👺 Ratboy's Nightmare — Locations")
TeleportsTab:CreateDropdown({Name="Locations", SearchEnabled=true, CurrentOption={""}, MultipleOptions=false,
	Options={
		"Back of The Theatre","End of the Road","Fish Hall","Inside","Maze of the Root","Meeting Place","MYSTERY STORE",
		"The Back Area","The Ballroom","The Deli","The Grand Hall","The Hidden Library","The Library of Riddles",
		"The Lost","The Mansion","The Old Cave","The Old Mansion","The Plant Room","The Road",
		"The Supermarket","The Theatre","The Vault","Waiting Room",
	},
	Callback=function(opt) if RATBOY_LOC_TP[opt[1]] then teleportTo(RATBOY_LOC_TP[opt[1]]) end end})

TeleportsTab:CreateSection("🏠 Housing")
TeleportsTab:CreateDropdown({Name="Housing Location", SearchEnabled=true, CurrentOption={""}, MultipleOptions=false,
	Options={"Black Tower (Celestial Field)","Boathouse (Long Coast)","Castle (Topple Town)","Ice Spire (Matumada)","Starter House (Topple Town)","Two Story House (Topple Town)","White Tower (Quiet Field)"},
	Callback=function(opt) if HOUSING_TP[opt[1]] then teleportTo(HOUSING_TP[opt[1]]) end end})

TeleportsTab:CreateSection("🧑‍💼 Vendors")
TeleportsTab:CreateButton({Name="Amy Thistlewitch", Callback=function() teleportTo(VENDOR_TP["Amy Thistlewitch"]) end})
TeleportsTab:CreateButton({Name="Arbewhy",          Callback=function() teleportTo(VENDOR_TP["Arbewhy"]) end})
TeleportsTab:CreateButton({Name="Archaeologist",    Callback=function() teleportTo(VENDOR_TP["Archaeologist"]) end})

TeleportsTab:CreateSection("🚪 Entrances")
for _, ev in pairs(ENTRANCES) do
	local evRef = ev
	TeleportsTab:CreateButton({Name="Teleport to "..ev.label, Callback=function() teleportEntrance(evRef) end})
end

-- =====================================================================
-- PLAYER TAB
-- =====================================================================
PlayerTab:CreateSection("🏃 Movement")
PlayerTab:CreateSlider({Name="Walk Speed",  Range={0,80},  Increment=1, CurrentValue=18,    Flag="WalkSpeed",  Callback=function(v) walkspeed=v end})
PlayerTab:CreateSlider({Name="Jump Power",  Range={0,300}, Increment=1, CurrentValue=81.5,  Flag="JumpPower",  Callback=function(v) jumppower=v end})
PlayerTab:CreateSlider({Name="Gravity",     Range={0,900}, Increment=1, CurrentValue=196.2, Flag="Gravity",    Callback=function(v) gravity=v end})
PlayerTab:CreateSlider({Name="Slope Angle", Range={0,90},  Increment=1, CurrentValue=56,    Flag="SlopeAngle", Callback=function(v) sangle=v end})
PlayerTab:CreateSlider({Name="Fly Speed",   Range={1,5},   Increment=1, CurrentValue=1,     Flag="FlySpeed",   Callback=function(v) flyspeed=v; iyflyspeed=v end})
PlayerTab:CreateToggle({Name="Noclip", CurrentValue=false, Flag="Noclip", Callback=function(v)
	Clip = not v
	if v then
		Noclipping = RunService.Stepped:Connect(function()
			if not Clip and speaker.Character then
				for _, child in pairs(speaker.Character:GetDescendants()) do
					if child:IsA("BasePart") and child.CanCollide then child.CanCollide = false end
				end
			end
		end)
	else if Noclipping then Noclipping:Disconnect() end end
end})
PlayerTab:CreateToggle({Name="Fly", CurrentValue=false, Flag="Fly", Callback=function(v)
	if v then NOFLY(); task.wait(); sFLY() else NOFLY() end
end})

PlayerTab:CreateSection("🛠 Tools")
PlayerTab:CreateButton({Name="Telekinesis  [Hold=Grab | Q/E=Dist | R=Rot | T=Pull | Y=Fling]", Callback=function()
	local function inject(obj, fn)
		local base = getfenv(fn)
		setfenv(fn, setmetatable({}, {__index=function(_,k) return k=="script" and obj or base[k] end}))
		return fn
	end
	local fns={}; local tc=Instance.new("Model",Lighting)
	local tool=Instance.new("Tool"); tool.Name="Telekinesis"; tool.Parent=tc
	tool.Grip=CFrame.new(0,0,0,0,1,0,0,0,1,1,0,0); tool.GripForward=Vector3.new(0,-1,0); tool.GripRight=Vector3.new(0,0,1); tool.GripUp=Vector3.new(1,0,0)
	local handle=Instance.new("Part"); handle.Name="Handle"; handle.Parent=tool
	handle.Size=Vector3.new(1,1.2,1); handle.Transparency=1; handle.CanCollide=false; handle.Anchored=false
	handle.Material=Enum.Material.Metal; handle.BrickColor=BrickColor.new("Really black")
	handle.BottomSurface=Enum.SurfaceType.Weld; handle.TopSurface=Enum.SurfaceType.Smooth
	handle.CFrame=CFrame.new(-17.26,15.49,46,0,1,0,1,0,0,0,0,-1)
	local lcs=Instance.new("Script"); lcs.Name="LineConnect"; lcs.Parent=tool; lcs.Disabled=true
	table.insert(fns,inject(lcs,function()
		task.wait()
		local p2v=script.Part2; local fp=script.Part1.Value; local tp=script.Part2.Value; local ct=script.Par.Value; local cs=script.Color
		local beam=Instance.new("Part"); beam.Name="TelekinesisLaser"; beam.Anchored=true; beam.CanCollide=false; beam.Locked=true; beam.Reflectance=0.5
		beam.TopSurface=Enum.SurfaceType.Smooth; beam.BottomSurface=Enum.SurfaceType.Smooth; beam.Size=Vector3.new(1,1,1); Instance.new("BlockMesh",beam)
		while true do
			if p2v.Value==nil then break end; if not fp or not tp or not ct then break end
			if not fp.Parent or not tp.Parent then break end; if not ct.Parent then break end
			local d=(fp.Position-tp.Position).Magnitude; beam.Parent=ct
			beam.BrickColor=cs.Value.BrickColor; beam.Reflectance=cs.Value.Reflectance; beam.Transparency=cs.Value.Transparency
			beam.CFrame=CFrame.lookAt(fp.Position,tp.Position)*CFrame.new(0,0,-d/2)
			beam:FindFirstChildOfClass("BlockMesh").Scale=Vector3.new(0.25,0.25,d); task.wait()
		end
		beam:Destroy(); script:Destroy()
	end))
	local ms=Instance.new("LocalScript"); ms.Name="MainScript"; ms.Parent=tool
	table.insert(fns,inject(ms,function()
		task.wait(); local tk=script.Parent; local lc=tk.LineConnect
		local grabbed=nil; local mdown=false; local ovRef=nil; local gd=20
		local bp=Instance.new("BodyPosition"); bp.MaxForce=Vector3.new(math.huge,math.huge,math.huge); bp.P=bp.P*1.1
		local cp=Instance.new("Part"); cp.Anchored=true; cp.CanCollide=false; cp.Locked=true; cp.Size=Vector3.new(1,1,1); cp.BrickColor=BrickColor.Black()
		local cm=Instance.new("SpecialMesh",cp); cm.MeshType=Enum.MeshType.Sphere; cm.Scale=Vector3.new(0.7,0.7,0.7)
		local tkh=tk.Handle; local bcs=tk.Handle
		local function spawnBeam(f,t,c)
			local p1=Instance.new("ObjectValue"); p1.Name="Part1"; p1.Value=f
			local p2=Instance.new("ObjectValue"); p2.Name="Part2"; p2.Value=t
			local pr=Instance.new("ObjectValue"); pr.Name="Par"; pr.Value=c
			local co=Instance.new("ObjectValue"); co.Name="Color"; co.Value=bcs
			local bs=lc:Clone(); bs.Disabled=false
			p1.Parent=bs; p2.Parent=bs; pr.Parent=bs; co.Parent=bs; bs.Parent=workspace
			if t==grabbed then ovRef=p2 end
		end
		local function onMD(mouse)
			if mdown then return end; mdown=true
			task.spawn(function()
				local c=cp:Clone(); c.Parent=tk; spawnBeam(tkh,c,workspace)
				while mdown do c.Parent=tk
					if grabbed==nil then
						if mouse.Target==nil then c.CFrame=CFrame.new(tkh.Position+CFrame.lookAt(tkh.Position,mouse.Hit.Position).LookVector*1000)
						else c.CFrame=CFrame.new(mouse.Hit.Position) end
					else spawnBeam(tkh,grabbed,workspace); break end; task.wait()
				end; c:Destroy()
			end)
			while mdown do if mouse.Target and not mouse.Target.Anchored then grabbed=mouse.Target; gd=(grabbed.Position-tkh.Position).Magnitude; break end task.wait() end
			while mdown do if not grabbed or not grabbed.Parent then break end; bp.Parent=grabbed; bp.Position=tkh.Position+CFrame.lookAt(tkh.Position,mouse.Hit.Position).LookVector*gd; task.wait() end
			if bp.Parent then bp:Destroy() end
			bp=Instance.new("BodyPosition"); bp.MaxForce=Vector3.new(math.huge,math.huge,math.huge); bp.P=bp.P*1.1
			if ovRef then ovRef.Value=nil end; grabbed=nil; ovRef=nil
		end
		local function onKD(k) k=k:lower()
			if k=="q" then gd=math.max(10,gd-10)
			elseif k=="e" then gd=gd+10 elseif k=="t" then gd=10 elseif k=="y" then gd=200
			elseif k=="r" then
				if not grabbed then return end
				for _,c in pairs(grabbed:GetChildren()) do if c:IsA("BodyGyro") then return end end
				local bg=Instance.new("BodyGyro"); bg.MaxTorque=Vector3.new(math.huge,math.huge,math.huge); bg.CFrame=CFrame.new(grabbed.CFrame.Position); bg.Parent=grabbed
				task.delay(0.5,function() if bg and bg.Parent then bg:Destroy() end; if grabbed then pcall(function() grabbed.AssemblyAngularVelocity=Vector3.zero; grabbed.Orientation=Vector3.zero end) end end)
			elseif k=="=" then bp.P=bp.P*1.5 elseif k=="-" then bp.P=bp.P*0.5 end
		end
		tk.Equipped:Connect(function(mouse)
			local hum=tk.Parent and tk.Parent:FindFirstChildOfClass("Humanoid")
			if hum then hum.Changed:Connect(function() if hum.Health<=0 then mdown=false; pcall(function() bp:Destroy() end); tk:Destroy() end end) end
			mouse.Button1Down:Connect(function() task.spawn(onMD,mouse) end); mouse.Button1Up:Connect(function() mdown=false end)
			mouse.KeyDown:Connect(onKD); mouse.Icon="rbxasset://textures/GunCursor.png"
		end)
	end))
	for _,item in pairs(tc:GetChildren()) do item.Parent=Players.LocalPlayer.Backpack; pcall(function() item:MakeJoints() end) end
	tc:Destroy(); for _,fn in pairs(fns) do task.spawn(pcall,fn) end
	Rayfield:Notify({Title="Telekinesis", Content="Added to backpack!", Duration=3})
end})

PlayerTab:CreateButton({Name="B-Tools", Callback=function()
	for _,v in pairs(Workspace:GetDescendants()) do if v:IsA("BasePart") then v.Locked=false end end
	for i=1,4 do local t=Instance.new("HopperBin"); t.BinType=i; t.Parent=speaker:FindFirstChildOfClass("Backpack") end
	Rayfield:Notify({Title="B-Tools", Content="Added to backpack!", Duration=3})
end})
PlayerTab:CreateButton({Name="Infinite Yield", Callback=function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end})

-- =====================================================================
-- SHOPS TAB
-- =====================================================================
task.spawn(function()
	repeat task.wait(0.2) until Workspace:FindFirstChild("Shops")
	local shopNames = getShopNames()
	if #shopNames == 0 then shopNames = {"No shops found"} end

	ShopsTab:CreateSection("🛒 Shop Browser")
	ShopsTab:CreateDropdown({Name="Select Shop", Options=shopNames, CurrentOption={shopNames[1]},
		MultipleOptions=false, SearchEnabled=true, Flag="SelectedShop",
		Callback=function(opt) selectedShopName=opt[1]; buildShopItemsDisplay(selectedShopName) end})
	selectedShopName = shopNames[1]

	ShopsTab:CreateButton({Name="Refresh Items", Callback=function() buildShopItemsDisplay(selectedShopName) end})

	-- Inline items display (no notifications)
	shopItemParagraph = ShopsTab:CreateParagraph({Title="Shop Items", Content="Select a shop and click Refresh Items."})

	ShopsTab:CreateButton({Name="📍 Teleport to Selected Shop", Callback=function()
		if not selectedShopName or selectedShopName == "No shops found" then
			Rayfield:Notify({Title="Shops", Content="Select a shop first.", Duration=3}); return
		end
		local pos = getShopPosition(selectedShopName)
		if pos then teleportTo(pos + Vector3.new(0,5,0)); Rayfield:Notify({Title="Teleported", Content="Arrived at "..selectedShopName, Duration=3})
		else Rayfield:Notify({Title="Shops", Content="Can't find "..selectedShopName.."'s position.", Duration=3}) end
	end})

	ShopsTab:CreateSection("🔔 Item Watcher")
	ShopsTab:CreateLabel("Type an item name. A toggle will appear below — uncheck to stop watching.")
	ShopsTab:CreateInput({Name="Watch Item", PlaceholderText="Exact item name...", RemoveTextAfterFocus=true,
		Callback=function(value)
			if not value or value == "" then return end
			for _, info in pairs(ReplicatedStorage.ItemInfo:GetChildren()) do
				local fn = info:FindFirstChild("FullName")
				if fn and string.lower(fn.Value) == string.lower(value) then
					local id = tonumber(info.Name)
					for _, w in pairs(watchedShopItems) do
						if w.id == id then Rayfield:Notify({Title="Watch List", Content="Already watching: "..fn.Value, Duration=3}); return end
					end
					local entry = {id=id, name=fn.Value, active=true}
					table.insert(watchedShopItems, entry)
					ShopsTab:CreateToggle({Name="✓ "..fn.Value, CurrentValue=true,
						Callback=function(v) entry.active = v end})
					Rayfield:Notify({Title="Watch List", Content="Now watching: "..fn.Value, Duration=3}); return
				end
			end
			Rayfield:Notify({Title="Watch List", Content="Item not found: "..value, Duration=3})
		end})
end)

-- =====================================================================
-- SETTINGS TAB
-- =====================================================================
SettingsTab:CreateSection("🔔 Notifications")
SettingsTab:CreateToggle({Name="Present Notifications",    CurrentValue=true, Flag="NotifPresent",    Callback=function(v) notif.present=v end})
SettingsTab:CreateToggle({Name="Frog Notifications",       CurrentValue=true, Flag="NotifFrog",       Callback=function(v) notif.frog=v end})
SettingsTab:CreateToggle({Name="Cosmic Ghost Notifications",CurrentValue=true, Flag="NotifCosmic",    Callback=function(v) notif.cosmic=v end})
SettingsTab:CreateToggle({Name="Path Gambler Notifications",CurrentValue=true, Flag="NotifGambler",   Callback=function(v) notif.gambler=v end})
SettingsTab:CreateToggle({Name="Firefly Notifications",    CurrentValue=true, Flag="NotifFirefly",    Callback=function(v) notif.firefly=v end})
SettingsTab:CreateToggle({Name="Bird Nest Notifications",  CurrentValue=true, Flag="NotifBird",       Callback=function(v) notif.birdnest=v end})
SettingsTab:CreateToggle({Name="Strangeman Notifications", CurrentValue=true, Flag="NotifStrangeman", Callback=function(v) notif.strangeman=v end})
SettingsTab:CreateToggle({Name="Rabbit Hole Notifications",CurrentValue=true, Flag="NotifRabbithole", Callback=function(v) notif.rabbithole=v end})
SettingsTab:CreateToggle({Name="Pitfall Notifications",    CurrentValue=true, Flag="NotifPitfall",    Callback=function(v) notif.pitfall=v end})

local spawnersFolder = Workspace.Spawners
for _, v in pairs(spawnersFolder:GetDescendants()) do
	if v.Name == "PlantBoxHandleAdornment" or v.Name == "PlantBeam" then v:Destroy() end
end

SettingsTab:CreateSection("🎨 ESP — Present")
SettingsTab:CreateToggle({Name="Present ESP", CurrentValue=false, Flag="PresentESP",
	Callback=function(v)
		espToggles.present = v
		if not v and LatestPresent then
			pcall(function() removeESP(LatestPresent.Parent, "PresentESP") end)
			pcall(function() removeESP(LatestPresent, "PresentESP") end)
		elseif v and LatestPresent and LatestPresent.Parent then
			markPresent(LatestPresent)
		end
		Rayfield:Notify({Title="Present ESP", Content=v and "Enabled" or "Disabled", Duration=2})
	end})

SettingsTab:CreateSection("🎨 ESP — Plants")
SettingsTab:CreateToggle({Name="Plant ESP", CurrentValue=false, Flag="PlantESP",
	Callback=function(v)
		espToggles.plants = v
		if not v then for _, i in pairs(spawnersFolder:GetDescendants()) do if i.Name=="PlantBoxHandleAdornment" or i.Name=="PlantBeam" then i:Destroy() end end end
		Rayfield:Notify({Title="Plant ESP", Content=v and "Enabled" or "Disabled", Duration=2})
	end})
SettingsTab:CreateInput({Name="Add Plant", PlaceholderText="Plant name...", RemoveTextAfterFocus=true,
	Callback=function(value)
		if not value or value=="" then return end
		for _,v in pairs(ReplicatedStorage.ItemInfo:GetDescendants()) do
			if v.Name=="FullName" and string.lower(v.Value)==string.lower(value) then
				local id=tonumber(v.Parent.Name)
				if not table.find(plants,id) then
					table.insert(plants,id); table.insert(plantNames,v.Value); table.insert(loweredPlantNames,string.lower(v.Value))
					Rayfield:Notify({Title="Plant ESP", Content="Added: "..v.Value, Duration=3})
				else Rayfield:Notify({Title="Plant ESP", Content="Already tracking: "..v.Value, Duration=3}) end; return
			end
		end
		Rayfield:Notify({Title="Plant ESP", Content="Not found: "..value, Duration=3})
	end})
SettingsTab:CreateInput({Name="Remove Plant", PlaceholderText="Plant name...", RemoveTextAfterFocus=true,
	Callback=function(value)
		if not value or value=="" then return end
		for _,v in pairs(ReplicatedStorage.ItemInfo:GetDescendants()) do
			if v.Name=="FullName" and string.lower(v.Value)==string.lower(value) then
				local id=tonumber(v.Parent.Name); local idx=table.find(plants,id)
				if idx then
					table.remove(plants,idx)
					local n=table.find(plantNames,v.Value); if n then table.remove(plantNames,n) end
					local l=table.find(loweredPlantNames,string.lower(v.Value)); if l then table.remove(loweredPlantNames,l) end
					for _,i in pairs(spawnersFolder:GetDescendants()) do if i.Name=="PlantBoxHandleAdornment" or i.Name=="PlantBeam" then i:Destroy() end end
					Rayfield:Notify({Title="Plant ESP", Content="Removed: "..v.Value, Duration=3})
				end; return
			end
		end
	end})

SettingsTab:CreateSection("🎨 ESP — Frog & Entrances")
SettingsTab:CreateToggle({Name="Frog ESP", CurrentValue=true, Flag="FrogESP",
	Callback=function(v)
		espToggles.frog = v
		if not v then
			pcall(function()
				local s = Workspace.Spawners["The Sprutle Frog Expansion_Updated"].Spawner_GratefulFrogs
				if s and s:FindFirstChild("Collectible") then removeESP(s.Collectible, "FrogESP") end
			end)
		end
		Rayfield:Notify({Title="Frog ESP", Content=v and "Enabled" or "Disabled", Duration=2})
	end})

for _, ev in pairs(ENTRANCES) do
	local evRef = ev
	SettingsTab:CreateToggle({Name=ev.label.." ESP", CurrentValue=true, Flag=ev.key.."ESP",
		Callback=function(v)
			espToggles[evRef.key] = v
			if not v then clearEntranceESP(evRef.key)
			else
				local entrance = evRef.getEntrance()
				if entrance and enabled[evRef.key] then applyEntranceESP(entrance, evRef.key, evRef.color, evRef.label) end
			end
			Rayfield:Notify({Title=evRef.label.." ESP", Content=v and "Enabled" or "Disabled", Duration=2})
		end})
end

SettingsTab:CreateSection("🎨 UI Theme")
SettingsTab:CreateDropdown({Name="Theme", SearchEnabled=true,
	Options={"Default","Ocean","AmberGlow","Light","Amethyst","Green","Bloom","DarkBlue","Serenity"},
	CurrentOption={"Default"}, Flag="Theme",
	Callback=function(opt)
		pcall(function() Rayfield:SetTheme(opt[1]) end)
		pcall(function() Window:SetTheme(opt[1]) end)
	end})

SettingsTab:CreateSection("🚪 Exit")
SettingsTab:CreateButton({Name="Exit Hub", Callback=function()
	getgenv().scriptRunning = false
	ffarm=false; bfarm=false; dfarm=false; lfarm=false; espToggles.plants=false; watchedShopItems={}
	plants={}; plantNames={}; loweredPlantNames={}
	pcall(function()
		local hum = speaker.Character:FindFirstChildWhichIsA("Humanoid")
		if hum then hum.WalkSpeed=16; hum.JumpPower=50; hum.MaxSlopeAngle=89 end
		Workspace.Gravity = 196.2; NOFLY()
		if Noclipping then Noclipping:Disconnect() end
	end)
	for _, v in pairs(spawnersFolder:GetDescendants()) do
		if v.Name=="PlantBoxHandleAdornment" or v.Name=="PlantBeam" then v:Destroy() end
	end
	for _, ev in pairs(ENTRANCES) do clearEntranceESP(ev.key) end
	Rayfield:Destroy()
end})

-- =====================================================================
-- FLY FUNCTIONS
-- =====================================================================
function sFLY()
	repeat task.wait() until speaker.Character and speaker.Character:FindFirstChild("HumanoidRootPart")
	if flyKeyDown then flyKeyDown:Disconnect() end; if flyKeyUp then flyKeyUp:Disconnect() end
	local T=speaker.Character.HumanoidRootPart; local C={F=0,B=0,L=0,R=0}; local S=0
	local BG=Instance.new("BodyGyro"); local BV=Instance.new("BodyVelocity")
	BG.P=9e4; BG.maxTorque=Vector3.new(9e9,9e9,9e9); BG.Parent=T
	BV.maxForce=Vector3.new(9e9,9e9,9e9); BV.Parent=T; FLYING=true
	local hum=speaker.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=true end
	flyKeyDown=Mouse.KeyDown:Connect(function(k) k=k:lower()
		if k=="w" then C.F=iyflyspeed elseif k=="s" then C.B=-iyflyspeed
		elseif k=="a" then C.L=-iyflyspeed elseif k=="d" then C.R=iyflyspeed end end)
	flyKeyUp=Mouse.KeyUp:Connect(function(k) k=k:lower()
		if k=="w" then C.F=0 elseif k=="s" then C.B=0 elseif k=="a" then C.L=0 elseif k=="d" then C.R=0 end end)
	task.spawn(function()
		repeat task.wait()
			iyflyspeed=flyspeed; S=(C.L+C.R~=0 or C.F+C.B~=0) and 50 or 0
			BV.velocity=((Workspace.CurrentCamera.CoordinateFrame.LookVector*(C.F+C.B))+((Workspace.CurrentCamera.CoordinateFrame*CFrame.new(C.L+C.R,0,0)).Position-Workspace.CurrentCamera.CoordinateFrame.Position))*S
			BG.CFrame=Workspace.CurrentCamera.CoordinateFrame
		until not FLYING
		BG:Destroy(); BV:Destroy()
		local h2=speaker.Character and speaker.Character:FindFirstChildOfClass("Humanoid"); if h2 then h2.PlatformStand=false end
	end)
end

function NOFLY()
	FLYING=false
	if flyKeyDown then flyKeyDown:Disconnect() end; if flyKeyUp then flyKeyUp:Disconnect() end
	local hum=speaker.Character and speaker.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=false end
end

-- =====================================================================
-- MAIN LOOPS
-- =====================================================================
task.spawn(function()
	while getgenv().scriptRunning do
		task.wait()
		local hum=speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
		if hum then hum.MaxSlopeAngle=sangle; hum.WalkSpeed=walkspeed; hum.JumpPower=jumppower end
		Workspace.Gravity=gravity
	end
end)

task.spawn(function()
	while getgenv().scriptRunning do
		task.wait()
		if ffarm then
			local fly=Workspace.Fireflies:FindFirstChild("FireflyServer")
			if fly then teleportToFirefly(fly) end; task.wait(0.1)
		end
		if dfarm then
			sitAtDeliBooth(); hideNotifications(); ringBell(); hideDialogs(); skipInitialDeliDialog()
			pcall(function()
				if Workspace.Deli.Booth1:FindFirstChild("WaiterLocation") then
					if shortwait then Workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C1.D1.E.RE1:FireServer(); hideDialogs()
					elseif longwait then Workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C2.D1.E.RE2:FireServer(); hideDialogs()
					elseif randomboth then
						task.wait(0.05); Workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C2.D1.E.RE2:FireServer(); hideDialogs(); task.wait(0.05)
						Workspace.Deli.Booth1.WaiterLocation.Dialog1.D.D1.D1.D1.C1.D1.E.RE1:FireServer(); hideDialogs(); task.wait(0.05)
					end
				end
			end)
		end
		if bfarm then
			local bs=Workspace.Spawners.Island:FindFirstChild("Spawner_BirdsNest")
			if bs then
				if bs:FindFirstChild("Collectible") then
					local part=bs.Collectible:FindFirstChildWhichIsA("BasePart")
					if part then
						if notif.birdnest then Rayfield:Notify({Title="Bird Nests", Content="Nest found!", Duration=3}) end
						teleportTo(part.Position); task.wait(0.05); bs.Collectible.InteractEvent:FireServer()
						for i=0,50 do ReplicatedStorage.Events.OpenSlot:FireServer(i) end; task.wait(3)
					else
						if notif.birdnest then Rayfield:Notify({Title="Bird Nests", Content="Not loaded.", Duration=3}) end
						for i=0,50 do ReplicatedStorage.Events.OpenSlot:FireServer(i) end
						local brick=bs.SpawnLocations:FindFirstChild("SpawnBrick")
						if brick then brick.Name="lol"; teleportTo(bs.SpawnLocations.lol.Position+Vector3.new(0,10,0)) end; task.wait(3)
					end
				else task.wait(3) end
			end
		end
	end
end)

task.spawn(function()
	while getgenv().scriptRunning do
		task.wait()
		if lfarm then
			amountEmptyInventory=20; task.wait(0.3)
			for i=0,100,10 do task.wait() pcall(function() Workspace.Guttermouth["Door_GuttermouthPhantom (Hidden Key)"].InteractEvent:FireServer(true) end) end
			task.wait(4.5)
			pcall(function() for _,v in pairs(Workspace.Guttermouth.GuttermouthRoom4.Monsters:GetChildren()) do if v and v:FindFirstChild("Humanoid") then v.Humanoid.Health=0 end end end)
			task.wait(4); teleportTo(Vector3.new(12546,252,-2359))
			repeat task.wait() until Workspace:FindFirstChild("GuttermouthChest")
			pcall(function() Workspace.Guttermouth.GuttermouthRoom4.ClaimRewards:InvokeServer(true) end); task.wait(0.5)
			if Workspace:FindFirstChild("GuttermouthChest") then Workspace.GuttermouthChest:Destroy() end
			teleportTo(Vector3.new(12529,252,-2350))
			pcall(function()
				for _,v in pairs(Players.LocalPlayer.PlayerGui.Container.Main["INV_SF"]:GetDescendants()) do
					if v.Name=="HoverText" and v.Value~="" then amountEmptyInventory-=1 end
				end
			end)
			if amountEmptyInventory<=0 then
				task.wait(1); teleportTo(Vector3.new(713,228,-483))
				for _=0,10 do sellLostItems(); task.wait(0.3) end
				task.wait(1); amountEmptyInventory=20; teleportTo(Vector3.new(12524,252,-2349))
				for _=0,100,10 do task.wait(0.01) pcall(function() Workspace.Guttermouth.GuttermouthRoom4.GutterExit.InteractEvent:FireServer(true) end) end; task.wait(1)
			end
			for _=0,100,10 do task.wait() pcall(function() Workspace.Guttermouth.GuttermouthRoom4.GutterExit.InteractEvent:FireServer(true) end) end; task.wait(0.3)
		end
	end
end)

-- Plant ESP loop
task.spawn(function()
	while getgenv().scriptRunning do
		task.wait(1)
		if espToggles.plants and #plants > 0 then
			for _,v in pairs(spawnersFolder:GetDescendants()) do
				if v and v:IsA("IntValue") and v.Name=="Item" and v.Parent and v.Parent.Name=="Info" then
					if table.find(plants, tonumber(v.Value)) then
						local hitbox=v.Parent.Parent:FindFirstChild("HitBox")
						if hitbox then
							if not hitbox:FindFirstChild("PlantBoxHandleAdornment") then
								local adorn=Instance.new("BoxHandleAdornment"); adorn.Name="PlantBoxHandleAdornment"
								adorn.Adornee=hitbox; adorn.AlwaysOnTop=true; adorn.ZIndex=0
								adorn.Size=hitbox.Size+Vector3.new(2,2,2); adorn.Transparency=0.3
								adorn.Color3=Color3.fromRGB(0,255,128); adorn.Parent=hitbox
							end
							if not hitbox:FindFirstChild("PlantBeam") then
								local beam=Instance.new("Beam"); beam.Name="PlantBeam"
								beam.Color=ColorSequence.new(Color3.fromRGB(0,255,128)); beam.Width0=0.1; beam.Width1=0.1
								local att0=Instance.new("Attachment", speaker.Character:WaitForChild("HumanoidRootPart"))
								local att1=Instance.new("Attachment", hitbox)
								beam.Attachment0=att0; beam.Attachment1=att1; beam.Parent=hitbox
							end
						end
					end
				end
			end
		end
	end
end)

-- Periodic paragraph refresh loop (frog + present status)
task.spawn(function()
	while getgenv().scriptRunning do
		task.wait(5)
		updateFrogParagraph()
		updatePresentParagraph()
	end
end)

-- Initial checks on load
task.spawn(function()
	task.wait(3)
	onNightBeginEntrances()
	updateFrogParagraph()
	updatePresentParagraph()
	-- Scan for already-existing watched entities
	for name, entry in pairs(entityWatchList) do
		if entry.active then
			local found = Workspace:FindFirstChild(name, true)
			if found then notifyEntity(found, entry.label, entry.entityType) end
		end
	end
end)
