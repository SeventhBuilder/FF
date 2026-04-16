-- ============================================================
--  FF Hub  |  Original by SeventhBuilder  |  v11
-- ============================================================

RunService        = game:GetService("RunService")
CoreGui           = game:GetService("CoreGui")
Workspace         = game:GetService("Workspace")
Players           = game:GetService("Players")
UserInputService  = game:GetService("UserInputService")
Lighting			= game:GetService("Lighting")
ReplicatedStorage = game:GetService("ReplicatedStorage")
StarterGui        = game:GetService("StarterGui")

for index, i in ipairs(CoreGui:GetDescendants()) do
	if i.Name == "SimpleSpy2" then
		i:Destroy()
		Players.LocalPlayer:Kick("Unstable connection detected")
		break
	end
	if index % 400 == 0 then
		task.wait()
	end
end

if getgenv().FFHubUnload then pcall(getgenv().FFHubUnload) end
getgenv().scriptRunning = false; task.wait(0.1); getgenv().scriptRunning = true

player = Players.LocalPlayer
Mouse  = player:GetMouse()

-- =====================================================================
-- STATE
-- =====================================================================
local WindUI
local Window
local HUB_VERSION = "v11.4"

local walkspeed = 18; local jumppower = 81.5; local gravity = Workspace.Gravity
local sangle = 56; local flyspeed = 1; local iyflyspeed = 1
local ffarm = false; local bfarm = false; local dfarm = false; local lfarm = false
local longwait = false; local shortwait = false; local randomboth = true
local amountEmptyInventory = 20
local Clip = false; local Noclipping = nil
local FLYING = false; local flyKeyDown, flyKeyUp

local enabled = { present=false, strangeman=false, pitfall=false, rabbithole=false }
local notif   = { present=true, firefly=true, birdnest=true, strangeman=true, rabbithole=true, pitfall=true }
local autoCollect = { present=false }
local autoTeleportState = { present=false }
local espToggles  = { plants=true, present=true, strangeman=true, rabbithole=true, pitfall=true, players=false }

local spawnersFolder = Workspace.Spawners
local plants = {}; local plantNames = {}; local loweredPlantNames = {}
local shopPositionCache = {}; local selectedShopName = nil
local watchedShopItems  = {}; local shopItemParagraph = nil
local entranceESPTracker = {}
local plantOptionLookup = {}
local animalOptionLookup = {}
local monsterOptionLookup = {}
local travelerOptionLookup = {}
local collectibleOptionLookup = {}
local shopItemOptionLookup = {}
local entranceOptionLookup = {}
local trackedPlantEntries = {}
local notifiedInstances = setmetatable({}, {__mode="k"})
local autoCollectedInstances = setmetatable({}, {__mode="k"})
local autoTeleportedInstances = setmetatable({}, {__mode="k"})
local autoTeleportedPresents = setmetatable({}, {__mode="k"})
local spiderBodyMovers = {}
local fastKillsEnabled = false
local fastKillInitialized = false
local fastKillTrackedHumanoids = setmetatable({}, {__mode="k"})
local flyJumpEnabled = false
local flyJumpConnection = nil
local suppressWindowCloseNotice = false
local runtimeConnections = {}
local pendingActionDialogs = {}
local plantRefreshQueued = false
local currentToggleKey = Enum.KeyCode.RightShift
local currentToggleKeyName = "RightShift"
local trackerDropdowns = {}
local trackerSelections = {
	plants = {},
	animals = {},
	monsters = {},
	travelers = {},
	entrances = {},
	collectibles = {},
	shopItems = {},
}
trackedPlantStatusParagraphs = {}
itemInfoCacheBuilt = false
itemInfoEntriesCache = {}
itemInfoById = {}
itemInfoByLowerName = {}
plantScanCache = {}
plantScanDirty = true
plantScanLastRun = 0
shopItemOptionsLoaded = false

-- Entity watchers (animals, collectibles, monsters, travelers)
local entityWatchList = {}     -- [instanceName] = {label, active, notify, esp, entityType}
local travelerWatchList = {}   -- [instanceName] = {label, active, notify, esp, isNight}

-- Paragraph UI elements
local presentStatusParagraph = nil
local entranceParagraphs     = {}   -- [key] = paragraph element
local updateTrackedPlantStatus
local setFlyJump
local cleanupHub

-- =====================================================================
-- UTILITY: Number formatting  (1000000 -> "1,000,000")
-- =====================================================================
function formatNumber(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local result = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return result
end

function notify(opts)
	if not WindUI then return end
	WindUI:Notify({
		Title = opts.Title or "FF Hub",
		Content = opts.Content or "",
		Duration = opts.Duration or 3,
	})
end

function showActionDialog(opts)
	local title = opts.Title or "FF Hub"
	local content = opts.Content or ""
	local actionTitle = opts.ActionTitle or "OK"
	if Window and Window.ShowDialog then
		local ok, dialog = pcall(function()
			return Window:ShowDialog({
				Title = title,
				Content = content,
				Buttons = {
					{
						Title = actionTitle,
						Callback = function()
							if opts.Callback then
								task.spawn(function()
									local ok, err = pcall(opts.Callback)
									if not ok then
										warn("[FF Hub] action dialog callback failed:", err)
										notify({
											Title = title,
											Content = "Action failed: " .. tostring(err),
											Duration = 4,
										})
									end
								end)
							end
						end,
					},
					{
						Title = "Close",
						Variant = "Secondary",
					},
				},
			})
		end)
		if ok and dialog then
			if dialog.Show then
				local showOk = pcall(function()
					dialog:Show()
				end)
				if showOk then
					return
				end
			else
				return
			end
		end
	elseif not Window then
		table.insert(pendingActionDialogs, opts)
		return
	end
	notify({
		Title = title,
		Content = content,
		Duration = opts.Duration or 4,
	})
end

function formatToggleKeyName(keyCode)
	local keyName = tostring(keyCode or currentToggleKey)
	keyName = keyName:gsub("^Enum%.KeyCode%.", "")
	return keyName
end

function getEntityOptionData(selectionKey, label)
	local lookupTable = ({
		animals = animalOptionLookup,
		monsters = monsterOptionLookup,
		travelers = travelerOptionLookup,
		collectibles = collectibleOptionLookup,
	})[selectionKey]
	return lookupTable and lookupTable[label] or nil
end

function fetchRemoteSource(urls)
	local urlList = type(urls) == "table" and urls or {urls}
	for _, remoteUrl in ipairs(urlList) do
		local ok, result = pcall(function()
			return game:HttpGet(remoteUrl)
		end)
		if ok and type(result) == "string" and result ~= "" then
			return result, remoteUrl
		end
	end
	return nil, nil
end

function loadCachedRemote(urls, cachePath)
	if readfile and writefile and isfile then
		local cachedSource = nil
		if isfile(cachePath) then
			pcall(function()
				cachedSource = readfile(cachePath)
			end)
		end
		if cachedSource and cachedSource ~= "" then
			local ok, loaded = pcall(loadstring, cachedSource)
			if ok and loaded then
				local ranOk, cachedResult = pcall(function()
					return loaded()
				end)
				if ranOk then
					task.spawn(function()
						pcall(function()
							local freshSource = fetchRemoteSource(urls)
							if freshSource and freshSource ~= "" then
								writefile(cachePath, freshSource)
							end
						end)
					end)
					return cachedResult
				end
			end
		end

		local source = fetchRemoteSource(urls)
		if type(source) ~= "string" or source == "" then
			error("Failed to load remote source and no valid cache was available.")
		end
		pcall(function()
			local folder = string.match(cachePath, "^(.*)[/\\][^/\\]+$")
			if folder and makefolder and isfolder and not isfolder(folder) then
				makefolder(folder)
			end
			writefile(cachePath, source)
		end)
		return loadstring(source)()
	end

	local source = fetchRemoteSource(urls)
	if type(source) ~= "string" or source == "" then
		error("Failed to load remote source.")
	end
	return loadstring(source)()
end

function connectSignal(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(runtimeConnections, connection)
	return connection
end

function disconnectRuntimeConnections()
	for index = #runtimeConnections, 1, -1 do
		local connection = runtimeConnections[index]
		runtimeConnections[index] = nil
		if connection then
			pcall(function() connection:Disconnect() end)
		end
	end
end

function normalizeSelectionList(value)
	local normalized = {}
	if type(value) == "table" then
		for _, option in ipairs(value) do
			if option and option ~= "" then
				normalized[option] = true
			end
		end
	elseif type(value) == "string" and value ~= "" then
		normalized[value] = true
	end
	return normalized
end

function getSelectionValues(selectionMap)
	local values = {}
	for optionLabel, isSelected in pairs(selectionMap or {}) do
		if isSelected then
			table.insert(values, optionLabel)
		end
	end
	table.sort(values, function(a, b)
		return string.lower(a) < string.lower(b)
	end)
	return values
end

function setDropdownSelection(dropdownKey)
	local dropdown = trackerDropdowns[dropdownKey]
	local values = getSelectionValues(trackerSelections[dropdownKey])
	if dropdown then
		pcall(function()
			dropdown:Select(values)
		end)
	end
end

-- =====================================================================
-- TELEPORT
-- =====================================================================
function teleportTo(pos)
	repeat task.wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not Workspace.HOLE:FindFirstChild("HoleTPEntrance") then
		repeat
			local prev = player.Character.HumanoidRootPart.CFrame
			player.Character.HumanoidRootPart.CFrame = CFrame.new(1304,96,-525)
			task.wait(); player.Character.HumanoidRootPart.CFrame = prev; task.wait(1)
		until Workspace.HOLE:FindFirstChild("HoleTPEntrance")
	end
	local hrp = player.Character.HumanoidRootPart
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

function checkTP()
	if not Workspace.HOLE:FindFirstChild("HoleTPEntrance") then
		repeat
			local prev = player.Character.HumanoidRootPart.CFrame
			player.Character.HumanoidRootPart.CFrame = CFrame.new(1304,96,-525)
			task.wait(); player.Character.HumanoidRootPart.CFrame = prev; task.wait(1)
		until Workspace.HOLE:FindFirstChild("HoleTPEntrance")
	end
end

-- =====================================================================
-- ESP HELPERS
-- =====================================================================
function addHighlightESP(adornee, fillColor, outlineColor, tag)
	if not adornee or adornee:FindFirstChild(tag.."_HL") then return end
	local hl = Instance.new("Highlight")
	hl.Name = tag.."_HL"; hl.Adornee = adornee
	hl.FillColor = fillColor or Color3.fromRGB(0,255,128)
	hl.OutlineColor = outlineColor or Color3.fromRGB(0,200,100)
	hl.FillTransparency = 0.4; hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = adornee
end

function addBillboardESP(part, text, color, tag)
	if not part then return end
	local bg = part:FindFirstChild(tag.."_BB")
	if not bg then
		bg = Instance.new("BillboardGui")
		bg.Name = tag.."_BB"
		bg.AlwaysOnTop = true
		bg.StudsOffset = Vector3.new(0, 3.5, 0)
		bg.Adornee = part
		bg.Parent = part
	end
	bg.Size = UDim2.new(0, 220, 0, string.find(tostring(text or ""), "\n", 1, true) and 68 or 52)

	local lbl = bg:FindFirstChild("Label") or bg:FindFirstChildWhichIsA("TextLabel")
	if not lbl then
		lbl = Instance.new("TextLabel")
		lbl.Name = "Label"
		lbl.BackgroundTransparency = 1
		lbl.Size = UDim2.new(1,0,1,0)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 16
		lbl.TextStrokeTransparency = 0.3
		lbl.TextStrokeColor3 = Color3.new(0,0,0)
		lbl.Parent = bg
	end
	lbl.Text = text
	lbl.TextColor3 = color or Color3.fromRGB(255,255,255)
end

function addTracerESP(part, color, tag)
	if not part or part:FindFirstChild(tag.."_Beam") then return end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local sourceAttachment = hrp:FindFirstChild(tag.."_A0")
	if not sourceAttachment then
		sourceAttachment = Instance.new("Attachment")
		sourceAttachment.Name = tag.."_A0"
		sourceAttachment.Parent = hrp
	end
	local targetAttachment = Instance.new("Attachment")
	targetAttachment.Name = tag.."_A1"
	targetAttachment.Parent = part
	local beam = Instance.new("Beam")
	beam.Name = tag.."_Beam"
	beam.Attachment0 = sourceAttachment
	beam.Attachment1 = targetAttachment
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Brightness = 2
	beam.Width0 = 0.09
	beam.Width1 = 0.09
	beam.Transparency = NumberSequence.new(0.15)
	beam.Color = ColorSequence.new(color or Color3.fromRGB(255,255,255))
	beam.Parent = part
end

function removeESP(instance, tag)
	if instance then
		local hl = instance:FindFirstChild(tag.."_HL")
		if hl then hl:Destroy() end
		for _, child in pairs(instance:GetDescendants()) do
			if child.Name == tag.."_BB"
				or child.Name == tag.."_Beam"
				or child.Name == tag.."_A1" then
				child:Destroy()
			end
		end
	end
end

function queuePlantRefresh(delaySeconds)
	if plantRefreshQueued then
		return
	end
	plantRefreshQueued = true
	task.delay(delaySeconds or 0.15, function()
		plantRefreshQueued = false
		if getgenv().scriptRunning and type(processTrackedPlants) == "function" and next(trackedPlantEntries) ~= nil then
			processTrackedPlants()
		end
	end)
end

function applyEntranceESP(entrance, tag, color, label)
	if not entrance then return end
	local part = entrance:IsA("BasePart") and entrance or entrance:FindFirstChildWhichIsA("BasePart", true)
	addHighlightESP(entrance, color, Color3.new(1,1,1), tag)
	if part then addBillboardESP(part, label, color, tag) end
	entranceESPTracker[tag] = entrance
end

function clearEntranceESP(tag)
	local e = entranceESPTracker[tag]; if e then removeESP(e, tag) end
	entranceESPTracker[tag] = nil
end

function updateParagraph(paraRef, title, content)
	if not paraRef then return end
	pcall(function()
		if paraRef.Set then
			paraRef:Set({Title=title, Content=content})
		else
			if paraRef.SetTitle then paraRef:SetTitle(title) end
			if paraRef.SetDesc then paraRef:SetDesc(content) end
		end
	end)
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
function refreshEntranceStatus(ev)
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

function teleportEntrance(ev)
	if not enabled[ev.key] then
		notify({Title=ev.label, Content="Track it first in the Entrances dropdown.", Duration=3}) return
	end
	local entrance = ev.getEntrance()
	if not entrance then notify({Title=ev.label, Content="Not available right now.", Duration=3}) return end
	local part = entrance:IsA("BasePart") and entrance or entrance:FindFirstChildWhichIsA("BasePart", true)
	if part then teleportTo(part.Position + Vector3.new(0,5,0))
	else notify({Title=ev.label, Content="Entrance has no teleport part.", Duration=3}) end
end

function onNightBeginEntrances()
	for _, ev in pairs(ENTRANCES) do
		clearEntranceESP(ev.key)
		task.spawn(function()
			task.wait(1) -- brief wait for workspace to settle
			refreshEntranceStatus(ev)
			if enabled[ev.key] then
				local entrance = ev.getEntrance()
				if entrance and notif[ev.key] then
					showActionDialog({
						Title = ev.label .. " Available!",
						Content = "Entrance appeared.",
						ActionTitle = "Teleport",
						Callback = function()
							teleportEntrance(ev)
						end,
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
	{name="NPC_ToasterJosh",  label="Toaster Josh"},
	{name="NPC_Stick",        label="Stick"},
	{name="NPC_Junkman",      label="Junkman"},
	{name="NPC_Vhitmire",     label="Vhitmire"},
}
local TRAVELERS_DAY = {
	{name="NPC_GreenGolem",   label="Green Golem"},
	{name="NPC_Construct",    label="Construct"},
	{name="NPC_Giver",        label="Interdimensional Traveler"},
}

function findNPCInWorkspace(npcName)
	local npcs = Workspace:FindFirstChild("NPCS")
	if npcs then
		local found = npcs:FindFirstChild(npcName) or npcs:FindFirstChild(npcName, true)
		if found then return found end
	end
	return Workspace:FindFirstChild(npcName)
end

function notifyAndTeleportNPC(npcName, label)
	local entry = travelerWatchList[npcName]
	if not entry or not entry.active then return end
	local npc = findNPCInWorkspace(npcName)
	if npc then
		if entry.esp then applyTrackedInstanceESP(npc, entry)
		else clearTrackedInstanceESP(npc, entry) end
		if not entry.notify or notifiedInstances[npc] then return end
		notifiedInstances[npc] = true
		local part = getTrackedInstancePart(npc)
		local fallbackPosition = part and part.Position or nil
		showActionDialog({
			Title = "🧭 " .. label .. " Available!",
			Content = part and "Found in workspace and loaded on your client."
				or "Found in workspace, but it is not fully loaded on your client yet.",
			ActionTitle = "Teleport",
			Callback = function()
				local refreshedNpc = findNPCInWorkspace(npcName)
				local refreshedPart = getTrackedInstancePart(refreshedNpc)
				if refreshedPart then
					teleportTo(refreshedPart.Position + Vector3.new(0, 5, 0))
				elseif fallbackPosition then
					teleportTo(fallbackPosition + Vector3.new(0, 5, 0))
				else
					notify({Title=label, Content="Still not fully loaded on your client.", Duration=3})
				end
			end,
		})
	end
end

function checkAllTravelers(list)
	for _, t in pairs(list) do
		notifyAndTeleportNPC(t.name, t.label)
	end
end

-- =====================================================================
-- ENTITY WATCHER  (animals, nightmare collectibles, world monsters)
-- =====================================================================
-- Single notification helper for generic entities
function notifyEntity(instance, label, entityType, workspaceName)
	local part = getTrackedInstancePart(instance)
	local fallbackPosition = part and part.Position or nil
	showActionDialog({
		Title = "[" .. entityType .. "] " .. label .. " spotted!",
		Content = part and "Found in workspace and loaded on your client."
			or "Found in workspace, but it is not fully loaded on your client yet.",
		ActionTitle = "Teleport",
		Callback = function()
			local refreshed = findEntityInWorkspace(workspaceName or instance.Name)
			local refreshedPart = getTrackedInstancePart(refreshed)
			if refreshedPart and refreshedPart.Parent then
				teleportTo(refreshedPart.Position + Vector3.new(0, 5, 0))
			elseif fallbackPosition then
				teleportTo(fallbackPosition + Vector3.new(0, 5, 0))
			else
				notify({Title=label, Content="Still not fully loaded on your client.", Duration=3})
			end
		end,
	})
end

function onInstanceAdded(instance)
	for _, entry in pairs(entityWatchList) do
		if entry.active then
			for _, workspaceName in ipairs(getTrackedWorkspaceNames(entry)) do
				if workspaceName == instance.Name then
					if entry.esp then applyTrackedInstanceESP(instance, entry)
					else clearTrackedInstanceESP(instance, entry) end
					task.spawn(notifyTrackedInstance, instance, entry)
					break
				end
			end
		end
	end
	local tEntry = travelerWatchList[instance.Name]
	if tEntry and tEntry.active then
		task.spawn(notifyAndTeleportNPC, instance.Name, tEntry.label)
	end
end

-- Connect watchers to workspace and NPCS folder
function connectEntityWatchers()
	connectSignal(Workspace.ChildAdded, onInstanceAdded)
	local npcs = Workspace:FindFirstChild("NPCS")
	if npcs then connectSignal(npcs.ChildAdded, onInstanceAdded) end
	-- Also watch for NPCS folder being added
	connectSignal(Workspace.ChildAdded, function(child)
		if child.Name == "NPCS" then
			connectSignal(child.ChildAdded, onInstanceAdded)
		end
	end)
end
connectEntityWatchers()
connectSignal(spawnersFolder.DescendantAdded, function()
	plantScanDirty = true
	queuePlantRefresh(0.2)
end)
connectSignal(spawnersFolder.DescendantRemoving, function()
	plantScanDirty = true
	queuePlantRefresh(0.2)
end)

-- =====================================================================
-- FIREFLY GOTO
-- =====================================================================
function teleportToFirefly(firefly)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
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
			hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
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
function updateFrogParagraph()
	return
end

function tryCollectFrog(doCollect)
	local entry = trackedPlantEntries.GratefulFrogs
	if not entry then return end
	if doCollect then
		collectPlantEntryNow(entry)
		return
	end
	local _, part = findFirstTrackedPlantTarget(entry)
	if part then
		teleportTo(part.Position + Vector3.new(0, 5, 0))
	end
end

function iterateTrackedPlantInstances(entry, callback)
	if not entry then return end
	if entry.special == "frog" then
		local spawner = spawnersFolder:FindFirstChild("The Sprutle Frog Expansion_Updated")
		local frogSpawner = spawner and spawner:FindFirstChild("Spawner_GratefulFrogs")
		local collectible = frogSpawner and frogSpawner:FindFirstChild("Collectible")
		local part = collectible and collectible:FindFirstChildWhichIsA("BasePart")
		if collectible then
			callback(collectible, part)
		end
		return
	end

	local scannedPlants = scanTrackedPlantInstances()
	local bucket = scannedPlants[entry.key]
	if not bucket then return end
	for model, part in pairs(bucket) do
		if model and model.Parent and part and part.Parent then
			callback(model, part)
		end
	end
end

function notifyTrackedPlant(entry, model, part)
	if not entry or not entry.notify or not model or notifiedInstances[model] then return end
	notifiedInstances[model] = true
	local fallbackPosition = part and part.Position or nil
	showActionDialog({
		Title = "[Plant] " .. entry.label .. " found!",
		Content = part and "Found in workspace and loaded on your client."
			or "Found in workspace, but it is not fully loaded on your client yet.",
		ActionTitle = "Teleport",
		Callback = function()
			local _, refreshedPart = findFirstTrackedPlantTarget(entry)
			if refreshedPart and refreshedPart.Parent then
				teleportTo(refreshedPart.Position + Vector3.new(0, 5, 0))
			elseif fallbackPosition then
				teleportTo(fallbackPosition + Vector3.new(0, 5, 0))
			else
				notify({Title=entry.label, Content="Still not fully loaded on your client.", Duration=3})
			end
		end,
	})
end

function autoCollectTrackedPlant(entry, model, part)
	if not entry or not entry.autoCollect or not model or autoCollectedInstances[model] then return end
	autoCollectedInstances[model] = true
	task.spawn(function()
		if part and part.Parent then
			teleportTo(part.Position + Vector3.new(0, 5, 0))
		end
		local remote = model:FindFirstChild("InteractEvent", true) or model:FindFirstChild("CollectEvent", true)
		if remote then
			for _ = 1, 15 do
				pcall(function() remote:FireServer() end)
				task.wait(0.1)
				if not model.Parent then break end
			end
		end
	end)
end

function autoTeleportTrackedTarget(entry, instance, part)
	if not entry or not entry.autoTeleport or not instance or autoTeleportedInstances[instance] then
		return
	end
	if not part or not part.Parent then
		return
	end
	autoTeleportedInstances[instance] = true
	task.spawn(function()
		teleportTo(part.Position + Vector3.new(0, 5, 0))
	end)
end

function processTrackedPlants()
	for _, entry in pairs(trackedPlantEntries) do
		if entry.active then
			local count = 0
			local tag = getPlantESPTag(entry)
			iterateTrackedPlantInstances(entry, function(model, part)
				count += 1
				if entry.esp and espToggles.plants then
					addHighlightESP(model, ENTITY_COLORS.Plant, Color3.new(1, 1, 1), tag)
					if part then
						addBillboardESP(part, entry.label, ENTITY_COLORS.Plant, tag)
						addTracerESP(part, ENTITY_COLORS.Plant, tag)
					end
				else
					removeESP(model, tag)
				end
				notifyTrackedPlant(entry, model, part)
				autoTeleportTrackedTarget(entry, model, part)
				autoCollectTrackedPlant(entry, model, part)
			end)
			updateTrackedPlantStatus(entry, count)
		end
	end
end

-- =====================================================================
-- DELI HELPERS
-- =====================================================================
function ringBell() pcall(function() ReplicatedStorage.Events.Deli:FireServer("RingBell"); Players.LocalPlayer.PlayerGui.DeliGui.BellButton.Visible = false end) task.wait() end
function hideNotifications() pcall(function() if Players.LocalPlayer.PlayerGui.Notification.Enabled then Players.LocalPlayer.PlayerGui.Notification.Enabled = false end end) task.wait() end
function sitAtDeliBooth() pcall(function() Workspace.Deli.Booth1.InteractEvent:FireServer() end) task.wait() end
function hideDialogs() pcall(function() if Players.LocalPlayer.PlayerGui.Dialog.Main.Visible then Players.LocalPlayer.PlayerGui.Dialog.Main.Visible = false end end) task.wait() end
function skipInitialDeliDialog() pcall(function() Workspace.Deli.Booth1.WaiterLocation.Dialog2.D.D1.D1.E.RE1:FireServer() end) task.wait() end

-- =====================================================================
-- SELL LOST ITEMS
-- =====================================================================
local LOST_ITEM_IDS = {982,2223,2224,2225,2276,2228,2229,825,2233,2239,2240,2241,2280,2246,2247,2249,2250,2251,2252,2254,2256,2257,2258,203,2260,2261,2262,1435,205,407}
function sellLostItems() for _, id in pairs(LOST_ITEM_IDS) do pcall(function() ReplicatedStorage.Events.SellShop:FireServer(id, Workspace.Shops.Sellers, 1) end) end end

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
	["Blue Button"]=Vector3.new(7285,172,-2549), ["Cyan Button"]=Vector3.new(7203,244,2235),
	["Green Button"]=Vector3.new(7926,157,-3546), ["Orange Button"]=Vector3.new(7129,143,-1587),
	["Pink Button"]=Vector3.new(7208,154,-1717), ["Purple Button"]=Vector3.new(7297,147,-1701),
	["Red Button"]=Vector3.new(7261,200,-2147), ["Yellow Button"]=Vector3.new(8510,214,-1242),
}
local RATBOY_DOORS_TP = {
	["Blue Door"]=Vector3.new(7149,169,-1621), ["Cyan Door"]=Vector3.new(7794,204,2212),
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

local PLANT_TRACK_NAMES = {
	"Lakethistles","RozierFlowers","LemonFlowers","PearlFlowers","PlumboFlowers","StrangemanFlowers",
	"Clamstacks","SandCorals","Shells","StrangemanShells","Falichen","HungryFlowers","AbandonedFlowers",
	"SunFlowers","MoonFlowers","LoolFlowers","FifeFlowers","Gorbacabbages","FruitStacks","TravelerPlants",
	"TheObjectFromEarth","AngryBushdwellers","GratefulFrogs","BrownMushrooms","FlattyMushrooms",
	"FantasticMushrooms","PortabatoMushrooms","TargetMushrooms","BrainMushrooms","GlowMushrooms",
	"YellowBalloonMushrooms","BobberMushrooms","GrugbugMushrooms","HoneyMushrooms","LumooreMushrooms",
	"PurpleBalloonMushrooms","SprutleMushrooms","MoonMushrooms","SnowballMushrooms","IcemMushrooms",
	"ElephantMushrooms","NightmareMushrooms","MushtacheMushrooms","StrangemanMushrooms",
	"RisingStarMushrooms","BoombaMushrooms","MaroonMushrooms","BirdsNest","Dragonroot","PendulumPlant",
	"EmosMushrooms","AuspiciousCharm","LittleForest","PipeMachine","PlungerColony","Plucky",
	"SmallTitan","MedTitan","LargeTitan",
}

-- =====================================================================
-- DISPLAY HELPERS / CATALOGS
-- =====================================================================
local DISPLAY_NAME_OVERRIDES = {
	FloatingHeadNPC = "Ghost",
	GreenFloatingHeadNPC = "Green Ghost",
	DarkFloatingHeadNPC = "Dark Ghost",
	RedFloatingMonsterHeadNPC = "Plasma Ghost",
	CosmicFloatingMonsterHeadNPC = "Cosmic Ghost",
	PathGamblerNPC = "Path Gambler",
	BanditSpiderNPC = "Spider Boss",
	NPC_Deer = "Deer",
	RabbitNPC = "Rabbit",
	GhostBat = "Ghost Bat",
	MonsterBird = "Monster Bird",
	BigBeakedPotatoBird = "Big Beaked Potato Bird",
	NPC_Strangeman = "Strangeman",
	NPC_ToasterJosh = "Toaster Josh",
	NPC_Stick = "Stick",
	NPC_Junkman = "Junkman",
	NPC_Vhitmire = "Vhitmire",
	NPC_GreenGolem = "Green Golem",
	NPC_Construct = "Construct",
	NPC_Giver = "Interdimensional Traveler",
	GratefulFrogs = "Grateful Frog",
	BirdsNest = "Bird Nest",
	TheObjectFromEarth = "The Object From Earth",
	AngryBushdwellers = "Angry Bushdwellers",
	SmallTitan = "Pebble Totem",
	MedTitan = "Boulder Totem",
	LargeTitan = "Mountain Totem",
}

local ENTITY_COLORS = {
	Plant = Color3.fromRGB(65, 220, 120),
	Animal = Color3.fromRGB(110, 180, 255),
	Monster = Color3.fromRGB(255, 110, 110),
	Collectible = Color3.fromRGB(255, 215, 110),
	Traveler = Color3.fromRGB(190, 130, 255),
}

local FAST_KILL_UNSAFE_NAMES = {
	TowerWolfNPC = true,
	Legend = true,
	Antellery = true,
	["Guardian Snibber"] = true,
	TitaniumAncientKnightNPC = true,
	["Twirling Warlock"] = true,
	["Big Ant"] = true,
}

local FAST_KILL_SUPER_UNSAFE_NAMES = {
	["TOTALITY JACK"] = true,
	Zitrat = true,
	FantasticDragonNPC = true,
	WhispererNPC = true,
	ForestGiantNPC = true,
	CKnight = true,
	Ratboy = true,
}

function sanitizeTag(text)
	return tostring(text or "Tracked"):gsub("[^%w_]", "")
end

function normalizePlantKey(text)
	return string.lower(tostring(text or "")):gsub("[^%w]", "")
end

function plantNameMatches(candidateName, targetKey)
	local candidateKey = normalizePlantKey(candidateName)
	return candidateKey == targetKey
		or string.find(candidateKey, targetKey, 1, true) ~= nil
		or string.find(targetKey, candidateKey, 1, true) ~= nil
end

function toDisplayName(rawName)
	if DISPLAY_NAME_OVERRIDES[rawName] then
		return DISPLAY_NAME_OVERRIDES[rawName]
	end
	local clean = tostring(rawName or "")
	clean = clean:gsub("^NPC_", "")
	clean = clean:gsub("NPC$", "")
	clean = clean:gsub("_", " ")
	clean = clean:gsub("(%l)(%u)", "%1 %2")
	clean = clean:gsub("(%u)(%u%l)", "%1 %2")
	clean = clean:gsub("(%a)(%d)", "%1 %2")
	clean = clean:gsub("(%d)(%a)", "%1 %2")
	clean = clean:gsub("%s+", " ")
	return clean
end

function sortEntriesByDisplayName(entries)
	table.sort(entries, function(a, b)
		return string.lower(a.displayName or "") < string.lower(b.displayName or "")
	end)
end

function buildOptionLookup(entries)
	local labels, lookup, usedLabels = {}, {}, {}
	for _, entry in ipairs(entries) do
		local label = entry.displayName
		if usedLabels[label] then
			label = ("%s [%s]"):format(label, entry.key or entry.workspaceName or entry.itemId or "?")
		end
		usedLabels[label] = true
		entry.optionLabel = label
		lookup[label] = entry
		table.insert(labels, label)
	end
	table.sort(labels, function(a, b) return string.lower(a) < string.lower(b) end)
	return labels, lookup
end

function buildItemInfoEntries()
	if not itemInfoCacheBuilt then
		local entries = {}
		for index, info in ipairs(ReplicatedStorage.ItemInfo:GetChildren()) do
			local id = tonumber(info.Name)
			local fullName = info:FindFirstChild("FullName")
			if id and fullName and fullName.Value ~= "" then
				local entry = {
					key = "item:" .. id,
					itemId = id,
					displayName = fullName.Value,
				}
				table.insert(entries, entry)
				itemInfoById[id] = entry
				itemInfoByLowerName[string.lower(fullName.Value)] = entry
			end
			if index % 250 == 0 then
				task.wait()
			end
		end
		sortEntriesByDisplayName(entries)
		itemInfoEntriesCache = entries
		itemInfoCacheBuilt = true
	end
	return itemInfoEntriesCache or {}
end

function buildPlantOptions()
	local entries = {}

	for _, plantName in ipairs(PLANT_TRACK_NAMES) do
		table.insert(entries, {
			key = plantName,
			workspaceName = plantName,
			displayName = toDisplayName(plantName),
			matchKey = normalizePlantKey(plantName),
			entityType = "Plant",
			special = plantName == "GratefulFrogs" and "frog" or nil,
		})
	end

	sortEntriesByDisplayName(entries)
	local labels, lookup = buildOptionLookup(entries)
	plantOptionLookup = lookup
	return labels
end

function getGroupedEntityInfo(rawName, entityType)
	if entityType ~= "Monster" then
		return nil, nil
	end
	local rawBase = tostring(rawName or ""):match("^(.-)%d+NPC$")
	if not rawBase or rawBase == "" then
		return nil, nil
	end
	local displayName = toDisplayName(rawBase .. "NPC")
	if displayName == "" then
		return nil, nil
	end
	return "group:" .. normalizePlantKey(displayName), displayName
end

function buildEntityOptions(rawEntries, entityType)
	local entries = {}
	local groupedEntries = {}
	for _, raw in ipairs(rawEntries) do
		local groupKey, groupName = getGroupedEntityInfo(raw, entityType)
		if groupKey then
			local entry = groupedEntries[groupKey]
			if not entry then
				entry = {
					key = groupKey,
					workspaceName = raw,
					workspaceNames = {},
					displayName = groupName,
					entityType = entityType,
				}
				groupedEntries[groupKey] = entry
				table.insert(entries, entry)
			end
			table.insert(entry.workspaceNames, raw)
		else
			table.insert(entries, {
				key = raw,
				workspaceName = raw,
				workspaceNames = {raw},
				displayName = toDisplayName(raw),
				entityType = entityType,
			})
		end
	end
	for _, entry in ipairs(entries) do
		if not entry.workspaceNames or #entry.workspaceNames == 0 then
			entry.workspaceNames = {entry.workspaceName}
		end
		table.sort(entry.workspaceNames)
		entry.workspaceName = entry.workspaceNames[1]
	end
	sortEntriesByDisplayName(entries)
	return buildOptionLookup(entries)
end

function buildTravelerOptions()
	local entries = {}
	for _, traveler in ipairs(TRAVELERS_NIGHT) do
		table.insert(entries, {
			key = traveler.name,
			workspaceName = traveler.name,
			displayName = traveler.label,
			entityType = "Traveler",
			isNight = true,
		})
	end
	for _, traveler in ipairs(TRAVELERS_DAY) do
		table.insert(entries, {
			key = traveler.name,
			workspaceName = traveler.name,
			displayName = traveler.label,
			entityType = "Traveler",
			isNight = false,
		})
	end
	sortEntriesByDisplayName(entries)
	local labels, lookup = buildOptionLookup(entries)
	travelerOptionLookup = lookup
	return labels
end

function buildEntranceOptions()
	local entries = {}
	for _, entrance in ipairs(ENTRANCES) do
		table.insert(entries, {
			key = entrance.key,
			displayName = entrance.label,
			entrance = entrance,
		})
	end
	sortEntriesByDisplayName(entries)
	local labels, lookup = buildOptionLookup(entries)
	entranceOptionLookup = lookup
	return labels
end

function getPlantDropdownOptions()
	if not plantDropdownOptions then
		plantDropdownOptions = buildPlantOptions()
	end
	return plantDropdownOptions
end

function getAnimalDropdownOptions()
	if not animalDropdownOptions then
		animalDropdownOptions, animalOptionLookup = buildEntityOptions(ANIMAL_NAMES, "Animal")
	end
	return animalDropdownOptions
end

function getMonsterDropdownOptions()
	if not monsterDropdownOptions then
		monsterDropdownOptions, monsterOptionLookup = buildEntityOptions(MONSTER_NPC_NAMES, "Monster")
	end
	return monsterDropdownOptions
end

function getCollectibleDropdownOptions()
	if not collectibleDropdownOptions then
		collectibleDropdownOptions, collectibleOptionLookup = buildEntityOptions(NIGHTMARE_COLLECTIBLE_NAMES, "Collectible")
	end
	return collectibleDropdownOptions
end

function getTravelerDropdownOptions()
	if not travelerDropdownOptions then
		travelerDropdownOptions = buildTravelerOptions()
	end
	return travelerDropdownOptions
end

function getEntranceDropdownOptions()
	if not entranceDropdownOptions then
		entranceDropdownOptions = buildEntranceOptions()
	end
	return entranceDropdownOptions
end

function buildShopItemOptions()
	local labels, lookup = buildOptionLookup(buildItemInfoEntries())
	shopItemOptionLookup = lookup
	return labels
end

function clearPlantESPVisuals()
	for _, obj in ipairs(spawnersFolder:GetDescendants()) do
		if obj.Name == "PlantBoxHandleAdornment"
			or obj.Name == "PlantBeam"
			or obj.Name == "PlantBeamAttachment0"
			or obj.Name == "PlantBeamAttachment1"
			or string.find(obj.Name, "^TrackedPlant_")
			or string.find(obj.Name, "_Beam$")
			or string.find(obj.Name, "_A1$")
			or string.find(obj.Name, "_BB$") then
			obj:Destroy()
		end
	end
	local character = player.Character
	if character then
		for _, obj in ipairs(character:GetDescendants()) do
			if string.find(obj.Name, "_A0$") or string.find(obj.Name, "_Beam$") then
				obj:Destroy()
			end
		end
	end
end

function rebuildPlantSelectionCache()
	plants = {}
	plantNames = {}
	loweredPlantNames = {}
	for _, entry in pairs(trackedPlantEntries) do
		if entry.active and entry.workspaceName and entry.esp then
			table.insert(plants, entry.workspaceName)
			table.insert(plantNames, entry.displayName)
			table.insert(loweredPlantNames, string.lower(entry.displayName))
		end
	end
end

function getPlantESPTag(entry)
	return sanitizeTag("TrackedPlant_" .. tostring(entry and entry.key or "Unknown"))
end

function resolveTrackedPlantTarget(instance)
	if not instance then return nil, nil end
	local model = instance
	if not instance:IsA("Model") and not instance:IsA("Folder") then
		model = instance:FindFirstAncestorOfClass("Model") or instance.Parent or instance
	end
	local part
	if model and model.FindFirstChild then
		part = model:FindFirstChild("HitBox") or model:FindFirstChildWhichIsA("BasePart", true)
	end
	if not part and instance:IsA("BasePart") then
		part = instance
	end
	return model or instance, part
end

function getTrackedPlantEntryByName(nameKey, exactLookup, activeEntries)
	local exactEntry = exactLookup[nameKey]
	if exactEntry then
		return exactEntry
	end
	for _, entry in pairs(activeEntries) do
		if plantNameMatches(nameKey, entry.matchKey or normalizePlantKey(entry.workspaceName)) then
			return entry
		end
	end
	return nil
end

function findTrackedPlantMatch(instance, exactLookup, activeEntries)
	local current = instance
	while current and current ~= spawnersFolder.Parent do
		local entry = getTrackedPlantEntryByName(normalizePlantKey(current.Name), exactLookup, activeEntries)
		if entry then
			return entry, current
		end
		current = current.Parent
	end
	return nil, nil
end

function scanTrackedPlantInstances()
	local foundByKey = {}
	local activeEntries = {}
	local exactLookup = {}
	for key, entry in pairs(trackedPlantEntries) do
		if entry.active and entry.workspaceName and not entry.special then
			activeEntries[key] = entry
			foundByKey[key] = {}
			exactLookup[entry.matchKey or normalizePlantKey(entry.workspaceName)] = entry
		end
	end
	if next(activeEntries) == nil then
		return foundByKey
	end

	if not plantScanDirty and (os.clock() - plantScanLastRun) < 1.2 then
		return plantScanCache
	end

	if not spawnersFolder or not spawnersFolder.Parent then
		return foundByKey
	end

	for index, descendant in ipairs(spawnersFolder:GetDescendants()) do
		if descendant:IsA("Model") or descendant:IsA("Folder") or descendant:IsA("BasePart") then
			local entry, matchedInstance = findTrackedPlantMatch(descendant, exactLookup, activeEntries)
			if entry then
				local model, part = resolveTrackedPlantTarget(matchedInstance or descendant)
				if model and part then
					local bucket = foundByKey[entry.key]
					if bucket and not bucket[model] then
						bucket[model] = part
					end
				end
			end
		end
		if index % 400 == 0 then
			task.wait()
		end
	end
	plantScanCache = foundByKey
	plantScanDirty = false
	plantScanLastRun = os.clock()
	return plantScanCache
end

function getTrackedInstancePart(instance)
	if not instance then return nil end
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") and instance.PrimaryPart then
		return instance.PrimaryPart
	end
	return instance:FindFirstChild("HumanoidRootPart", true)
		or instance:FindFirstChild("HitBox", true)
		or instance:FindFirstChildWhichIsA("BasePart", true)
end

function getTrackedWorkspaceNames(source)
	if type(source) == "table" then
		if type(source.workspaceNames) == "table" and #source.workspaceNames > 0 then
			return source.workspaceNames
		end
		if source.workspaceName then
			return {source.workspaceName}
		end
		if source.key then
			return {source.key}
		end
	elseif type(source) == "string" and source ~= "" then
		return {source}
	end
	return {}
end

function findBestTrackedInstance(source)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local bestInstance, bestPart, bestDistance = nil, nil, math.huge
	for _, workspaceName in ipairs(getTrackedWorkspaceNames(source)) do
		local instance = findEntityInWorkspace(workspaceName)
		local part = getTrackedInstancePart(instance)
		if part and part.Parent then
			local distance = hrp and (part.Position - hrp.Position).Magnitude or 0
			if not bestPart or distance < bestDistance then
				bestInstance = instance
				bestPart = part
				bestDistance = distance
			end
		elseif not bestInstance and instance then
			bestInstance = instance
		end
	end
	return bestInstance, bestPart
end

function getEntityESPTag(instanceName, entityType)
	return sanitizeTag("Tracked_" .. tostring(entityType or "Entity") .. "_" .. tostring(instanceName or "Unknown"))
end

function resolveEntityCandidate(candidate)
	if not candidate then return nil end
	if candidate:IsA("Model") or candidate:IsA("Folder") or candidate:IsA("BasePart") then
		return candidate
	end
	return candidate:FindFirstAncestorOfClass("Model")
		or candidate:FindFirstAncestorOfClass("Folder")
		or candidate:FindFirstAncestorWhichIsA("BasePart")
end

function findEntityInWorkspace(instanceName)
	local npc = findNPCInWorkspace(instanceName)
	if npc then return npc end

	local targetKey = normalizePlantKey(instanceName)

	local function findUnderRoot(root)
		if not root then
			return nil
		end

		local exact = root:FindFirstChild(instanceName, true)
		local resolved = resolveEntityCandidate(exact)
		if resolved then
			return resolved
		end

		local fuzzyCandidate = nil
		for index, descendant in ipairs(root:GetDescendants()) do
			if descendant:IsA("Model") or descendant:IsA("Folder") or descendant:IsA("BasePart") then
				local current = descendant
				while current and current ~= root.Parent do
					local currentKey = normalizePlantKey(current.Name)
					if currentKey == targetKey then
						return resolveEntityCandidate(descendant) or resolveEntityCandidate(current) or descendant
					end
					if not fuzzyCandidate and plantNameMatches(currentKey, targetKey) then
						fuzzyCandidate = resolveEntityCandidate(descendant) or resolveEntityCandidate(current) or descendant
					end
					current = current.Parent
				end
			end
			if index % 400 == 0 then
				task.wait()
			end
		end
		return fuzzyCandidate
	end

	local spawnerMatch = findUnderRoot(spawnersFolder)
	if spawnerMatch then
		return spawnerMatch
	end
	return findUnderRoot(Workspace)
end

function applyTrackedInstanceESP(instance, entry)
	if not instance or not entry or not entry.esp then return end
	local color = ENTITY_COLORS[entry.entityType] or Color3.fromRGB(255, 255, 255)
	local tag = getEntityESPTag(instance.Name, entry.entityType)
	addHighlightESP(instance, color, Color3.new(1, 1, 1), tag)
	local part = getTrackedInstancePart(instance)
	if part then
		addBillboardESP(part, entry.label, color, tag)
		if entry.entityType == "Collectible" then
			addTracerESP(part, color, tag)
		end
	end
end

function clearTrackedInstanceESP(instance, entry)
	if not instance or not entry then return end
	removeESP(instance, getEntityESPTag(instance.Name, entry.entityType))
end

function notifyTrackedInstance(instance, entry)
	if not instance or not entry or not entry.notify or notifiedInstances[instance] then return end
	notifiedInstances[instance] = true
	notifyEntity(instance, entry.label, entry.entityType, instance.Name)
end

function refreshTrackedInstance(instanceName, entry)
	local foundInstance = nil
	for _, workspaceName in ipairs(getTrackedWorkspaceNames(entry or instanceName)) do
		local instance = findEntityInWorkspace(workspaceName)
		if instance then
			foundInstance = foundInstance or instance
			if entry.esp then applyTrackedInstanceESP(instance, entry)
			else clearTrackedInstanceESP(instance, entry) end
			notifyTrackedInstance(instance, entry)
			autoTeleportTrackedTarget(entry, instance, getTrackedInstancePart(instance))
		end
	end
	return foundInstance
end

function getPlayerESPTag(targetPlayer)
	return sanitizeTag("TrackedPlayer_" .. tostring(targetPlayer and targetPlayer.Name or "Player"))
end

function refreshPlayersESP()
	if not espToggles.players then
		return
	end
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			local character = otherPlayer.Character
			local tag = getPlayerESPTag(otherPlayer)
			if character and character.Parent then
				if espToggles.players then
					local part = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart", true)
					local hum = character:FindFirstChildWhichIsA("Humanoid")
					local hpText = ""
					if hum then
						hpText = ("\nHP: %d/%d"):format(math.max(0, math.floor(hum.Health)), math.max(1, math.floor(hum.MaxHealth)))
					end
					addHighlightESP(character, Color3.fromRGB(90, 170, 255), Color3.new(1, 1, 1), tag)
					if part then
						addBillboardESP(part, otherPlayer.Name .. hpText, Color3.fromRGB(90, 170, 255), tag)
					end
				else
					removeESP(character, tag)
				end
			end
		end
	end
end

function clearPlayersESP()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player and otherPlayer.Character then
			removeESP(otherPlayer.Character, getPlayerESPTag(otherPlayer))
		end
	end
end

function teleportToTrackedInstance(instanceName, label)
	local _, part = findBestTrackedInstance(instanceName)
	if part then
		teleportTo(part.Position + Vector3.new(0, 5, 0))
	else
		notify({Title=label or "Tracker", Content="Target is not available right now.", Duration=3})
	end
end

function bringTrackedInstanceToPlayer(instanceName, label)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		notify({Title=label or "Bring Target", Content="Character is not ready yet.", Duration=3})
		return
	end

	local instance = findBestTrackedInstance(instanceName)
	if not instance then
		notify({Title=label or "Bring Target", Content="Target is not available right now.", Duration=3})
		return
	end

	local model = instance:IsA("Model") and instance or instance:FindFirstAncestorOfClass("Model")
	local part = getTrackedInstancePart(model or instance)
	if not part then
		notify({Title=label or "Bring Target", Content="Target has no movable part.", Duration=3})
		return
	end

	local targetPosition = hrp.Position + hrp.CFrame.LookVector * 16 + Vector3.new(0, 4, 0)
	if model then
		local originalPivot = model:GetPivot()
		local targetPivot = CFrame.new(targetPosition) * (originalPivot - originalPivot.Position)
		local baseParts = {}
		for _, descendant in ipairs(model:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.CanCollide = false
				descendant.AssemblyLinearVelocity = Vector3.zero
				descendant.AssemblyAngularVelocity = Vector3.zero
				table.insert(baseParts, descendant)
			end
		end
		for _ = 1, 8 do
			pcall(function()
				model:PivotTo(targetPivot)
			end)
			task.wait()
		end
		local finalPart = getTrackedInstancePart(model)
		if finalPart and (finalPart.Position - targetPosition).Magnitude > 20 then
			for _, basePart in ipairs(baseParts) do
				local offset = originalPivot:ToObjectSpace(basePart.CFrame)
				basePart.CFrame = targetPivot * offset
			end
		end
	else
		part.CFrame = CFrame.new(targetPosition)
	end

	local finalPart = getTrackedInstancePart(model or instance)
	local distance = finalPart and (finalPart.Position - targetPosition).Magnitude or math.huge
	notify({
		Title = label or "Bring Target",
		Content = distance <= 30 and "Moved near your character."
			or "Move was attempted, but the server kept it away.",
		Duration = 4,
	})
end

function removeFogEffects()
	pcall(function()
		if player.PlayerScripts:FindFirstChild("Fog") then
			player.PlayerScripts.Fog:Destroy()
		end
	end)
	pcall(function()
		local fogbox = player.Character and player.Character:FindFirstChild("Fogbox")
		if fogbox then
			for _, ring in ipairs({"Ring1", "Ring2", "Ring3"}) do
				local part = fogbox:FindFirstChild(ring)
				if part then part:Destroy() end
			end
		end
	end)
end

function clearSpiderBodyMovers()
	for part, mover in pairs(spiderBodyMovers) do
		if mover and mover.Parent then mover:Destroy() end
		if part and part.Parent and part:IsA("BasePart") then
			part.CanCollide = true
		end
	end
	spiderBodyMovers = {}
end

function bringSpiderBossToPlayer()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		notify({Title="Spider Boss", Content="Character is not ready yet.", Duration=3})
		return
	end

	removeFogEffects()

	local targetPosition = hrp.Position + hrp.CFrame.LookVector * 24 + Vector3.new(0, 6, 0)
	local spider = Workspace:FindFirstChild("NPCS") and Workspace.NPCS:FindFirstChild("BanditSpiderNPC")
	local spiderPart = spider and getTrackedInstancePart(spider)

	if not spiderPart then
		notify({Title="Spider Boss", Content="Loading spider boss from the nest...", Duration=4})
		teleportTo(Vector3.new(1496, 73, -3738))
		task.wait(4)
		spider = Workspace:FindFirstChild("NPCS") and Workspace.NPCS:FindFirstChild("BanditSpiderNPC")
		spiderPart = spider and getTrackedInstancePart(spider)
	end

	if not spider or not spiderPart then
		notify({Title="Spider Boss", Content="Spider boss is not available in this server.", Duration=4})
		return
	end

	clearSpiderBodyMovers()
	local originalPivot = spider:GetPivot()
	local targetPivot = CFrame.new(targetPosition) * (originalPivot - originalPivot.Position)
	local baseParts = {}

	for _, descendant in ipairs(spider:GetDescendants()) do
		if descendant:IsA("BodyPosition") or descendant:IsA("BodyGyro") or descendant:IsA("AlignPosition") or descendant:IsA("AlignOrientation") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.AssemblyLinearVelocity = Vector3.zero
			descendant.AssemblyAngularVelocity = Vector3.zero
			table.insert(baseParts, descendant)
		end
	end

	for _ = 1, 8 do
		pcall(function()
			spider:PivotTo(targetPivot)
		end)
		if spiderPart and spiderPart.Parent then
			spiderPart.AssemblyLinearVelocity = Vector3.zero
			spiderPart.AssemblyAngularVelocity = Vector3.zero
		end
		task.wait()
	end

	if spiderPart and (spiderPart.Position - targetPosition).Magnitude > 20 then
		for _, part in ipairs(baseParts) do
			local offset = originalPivot:ToObjectSpace(part.CFrame)
			part.CFrame = targetPivot * offset
		end
	end

	teleportTo(targetPosition + Vector3.new(0, 4, 16))
	local finalPart = getTrackedInstancePart(spider)
	local distance = finalPart and (finalPart.Position - targetPosition).Magnitude or math.huge
	notify({
		Title="Spider Boss",
		Content = distance <= 30 and "Spider boss moved to your location."
			or "Spider boss move was attempted, but the server kept it away.",
		Duration=5,
	})
end

function isFastKillPlayerHumanoid(humanoid)
	for _, onlinePlayer in ipairs(Players:GetPlayers()) do
		if humanoid:FindFirstAncestor(onlinePlayer.Name) then
			return true
		end
	end
	return false
end

function isFastKillAnchoredModel(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Anchored then
			return true
		end
	end
	return false
end

function shouldInstantKillHumanoid(humanoid)
	local model = humanoid:FindFirstAncestorOfClass("Model")
	if not model then return false end
	if FAST_KILL_UNSAFE_NAMES[model.Name] or FAST_KILL_SUPER_UNSAFE_NAMES[model.Name] then
		return false
	end
	return game.PlaceId == 963149987 and #Players:GetPlayers() == 1
end

function tryFastKillHumanoid(humanoid, tracker)
	if not fastKillsEnabled or not humanoid or humanoid.Health <= 0 or not tracker then return end
	local model = humanoid:FindFirstAncestorOfClass("Model")
	if not model or isFastKillAnchoredModel(model) then return end

	local damageRatio = (humanoid.MaxHealth - tracker.Value) / math.max(humanoid.MaxHealth, 1)
	local shouldKill = false

	if game.PlaceId == 963149987 then
		if FAST_KILL_UNSAFE_NAMES[model.Name] then
			shouldKill = damageRatio < 0.44
		elseif FAST_KILL_SUPER_UNSAFE_NAMES[model.Name] then
			shouldKill = damageRatio < 0.01
		elseif #Players:GetPlayers() == 1 then
			shouldKill = true
		end
	else
		shouldKill = damageRatio < 0.69
			and not FAST_KILL_UNSAFE_NAMES[model.Name]
			and not FAST_KILL_SUPER_UNSAFE_NAMES[model.Name]
	end

	if shouldKill then
		task.delay(0.1, function()
			if fastKillsEnabled and humanoid.Parent and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end)
	end
end

function hookFastKillHumanoid(humanoid)
	if fastKillTrackedHumanoids[humanoid] or isFastKillPlayerHumanoid(humanoid) then return end
	fastKillTrackedHumanoids[humanoid] = true

	function connectTracker(playerDamages)
		local tracker = playerDamages:FindFirstChild(player.Name)
		if not tracker then return end
		tryFastKillHumanoid(humanoid, tracker)
		connectSignal(tracker.Changed, function()
			tryFastKillHumanoid(humanoid, tracker)
		end)
	end

	connectSignal(humanoid.ChildAdded, function(child)
		if child.Name == "PlayerDamages" then
			task.wait()
			connectTracker(child)
		end
	end)

	local existingTracker = humanoid:FindFirstChild("PlayerDamages")
	if existingTracker then
		connectTracker(existingTracker)
	end

	if shouldInstantKillHumanoid(humanoid) and fastKillsEnabled then
		task.delay(1, function()
			if fastKillsEnabled and humanoid.Parent and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end)
	end
end

function initializeFastKills()
	if fastKillInitialized then return end
	fastKillInitialized = true

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Humanoid") then
			hookFastKillHumanoid(descendant)
		end
	end

	connectSignal(Workspace.DescendantAdded, function(descendant)
		if descendant:IsA("Humanoid") then
			hookFastKillHumanoid(descendant)
		end
	end)
end

function enableFastKills(state)
	fastKillsEnabled = state
	initializeFastKills()
	if state then
		for _, descendant in ipairs(Workspace:GetDescendants()) do
			if descendant:IsA("Humanoid") and shouldInstantKillHumanoid(descendant) then
				task.delay(0.15, function()
					if fastKillsEnabled and descendant.Parent and descendant.Health > 0 then
						descendant.Health = 0
					end
				end)
			end
		end
	end
end

function createParagraphWrapper(paragraph)
	return {
		_actual = paragraph,
		Set = function(_, opts)
			if opts.Title ~= nil then pcall(function() paragraph:SetTitle(opts.Title) end) end
			if opts.Content ~= nil then pcall(function() paragraph:SetDesc(opts.Content) end) end
		end,
		Destroy = function() pcall(function() paragraph:Destroy() end) end,
	}
end

function getDropdownDefault(config)
	local current = config.CurrentOption
	if type(current) == "table" then
		if config.MultipleOptions then
			return current
		end
		local first = current[1]
		if first == "" then return nil end
		return first
	end
	return current
end

function createContainerWrapper(container)
	local wrapper = { _actual = container, _current = nil }

	local function getTarget()
		if wrapper._current and wrapper._current._actual then
			return wrapper._current._actual
		end
		return wrapper._actual
	end

	function wrapper:CreateSection(title)
		local section = createContainerWrapper(wrapper._actual:Section({
			Title = title,
			Opened = false,
			Box = true,
		}))
		wrapper._current = section
		return section
	end

	function wrapper:Destroy()
		pcall(function()
			if wrapper._actual and wrapper._actual.Destroy then
				wrapper._actual:Destroy()
			end
		end)
	end

	function wrapper:SetTitle(title)
		pcall(function()
			if wrapper._actual and wrapper._actual.SetTitle then
				wrapper._actual:SetTitle(title)
			end
		end)
	end

	function wrapper:CreateLabel(text)
		return createParagraphWrapper(getTarget():Paragraph({Title = text, Desc = ""}))
	end

	function wrapper:CreateParagraph(config)
		return createParagraphWrapper(getTarget():Paragraph({
			Title = config.Title or "",
			Desc = config.Content or "",
		}))
	end

	function wrapper:CreateButton(config)
		return getTarget():Button({
			Title = config.Name or "Button",
			Desc = config.Description,
			Callback = config.Callback,
		})
	end

	function wrapper:CreateToggle(config)
		return getTarget():Toggle({
			Title = config.Name or "Toggle",
			Desc = config.Description,
			Value = config.CurrentValue or false,
			Callback = config.Callback,
		})
	end

	function wrapper:CreateSlider(config)
		local range = config.Range or {0, 100}
		return getTarget():Slider({
			Title = config.Name or "Slider",
			Desc = config.Description,
			Step = config.Increment or 1,
			Value = {
				Min = range[1],
				Max = range[2],
				Default = config.CurrentValue or range[1],
			},
			Callback = config.Callback,
		})
	end

	function wrapper:CreateInput(config)
		local inputObject
		inputObject = getTarget():Input({
			Title = config.Name or "Input",
			Desc = config.Description,
			Placeholder = config.PlaceholderText or "",
			Value = "",
			Callback = function(value)
				if config.Callback then
					config.Callback(value)
				end
				if config.RemoveTextAfterFocus and inputObject and inputObject.Set then
					task.defer(function()
						pcall(function() inputObject:Set("") end)
					end)
				end
			end,
		})
		return inputObject
	end

	function wrapper:CreateDropdown(config)
		local dropdown = getTarget():Dropdown({
			Title = config.Name or "Dropdown",
			Desc = config.Description,
			Values = config.Options or {},
			Value = getDropdownDefault(config),
			Multi = config.MultipleOptions or false,
			AllowNone = true,
			SearchBarEnabled = config.SearchEnabled or false,
			Callback = function(value)
				if not config.Callback then return end
				if config.MultipleOptions then
					config.Callback(value)
				else
					config.Callback({value})
				end
			end,
		})

		return {
			_actual = dropdown,
			Refresh = function(_, values) pcall(function() dropdown:Refresh(values) end) end,
			Select = function(_, value) pcall(function() dropdown:Select(value) end) end,
			Destroy = function() pcall(function() dropdown:Destroy() end) end,
		}
	end

	return wrapper
end

local uiYieldCounter = 0
function yieldUIBuild(force)
	uiYieldCounter += 1
	if force or uiYieldCounter % 4 == 0 then
		task.wait()
	end
end

function createTrackerDropdownAsync(dropdownKey, targetWrapper, delay, builder)
	task.spawn(function()
		if delay and delay > 0 then
			task.wait(delay)
		else
			task.wait()
		end
		if not getgenv().scriptRunning then return end
		local ok, dropdownOrError = pcall(builder, targetWrapper)
		if not ok then
			warn("[FF Hub] failed to create tracker dropdown:", dropdownKey, dropdownOrError)
			notify({
				Title = "UI",
				Content = "Failed to build " .. tostring(dropdownKey) .. " dropdown.",
				Duration = 4,
			})
			return
		end
		trackerDropdowns[dropdownKey] = dropdownOrError
		if #getSelectionValues(trackerSelections[dropdownKey]) > 0 then
			setDropdownSelection(dropdownKey)
		end
	end)
end

-- =====================================================================
-- SHOP HELPERS
-- =====================================================================
function getShopNames()
	local names = {}
	if not Workspace:FindFirstChild("Shops") then return names end
	for _, shop in pairs(Workspace.Shops:GetChildren()) do
		if shop:FindFirstChild("Slots") then table.insert(names, shop.Name) end
	end
	table.sort(names); return names
end

function getShopPosition(shopName)
	if shopPositionCache[shopName] then return shopPositionCache[shopName] end
	local shops = Workspace:FindFirstChild("Shops"); if not shops then return nil end
	local shop = shops:FindFirstChild(shopName); if not shop then return nil end
	local part = shop:FindFirstChildWhichIsA("BasePart", true)
	if part then shopPositionCache[shopName] = part.Position; return part.Position end
	return nil
end

function getShopItems(shopName)
	buildItemInfoEntries()
	local shops = Workspace:FindFirstChild("Shops"); if not shops then return {} end
	local shop = shops:FindFirstChild(shopName)
	if not shop or not shop:FindFirstChild("Slots") then return {} end
	local result = {}
	for index, slot in ipairs(shop.Slots:GetChildren()) do
		local itemSlot = slot:FindFirstChild("Item"); local priceSlot = slot:FindFirstChild("Price")
		if itemSlot then
			local itemId = tonumber(itemSlot.Value)
			local price  = priceSlot and formatNumber(priceSlot.Value) or "?"
			local entry = itemInfoById[itemId]
			if entry then
				table.insert(result, {name=entry.displayName, price=price, id=itemId})
			end
		end
		if index % 25 == 0 then
			task.wait()
		end
	end
	return result
end

function findWatchedItemsInShops()
	local found = {}; local shops = Workspace:FindFirstChild("Shops"); if not shops then return found end
	for watchedIndex, watched in ipairs(watchedShopItems) do
		if watched.active then
			for shopIndex, shop in ipairs(shops:GetChildren()) do
				if shop:FindFirstChild("Slots") then
					for slotIndex, slot in ipairs(shop.Slots:GetChildren()) do
						local iSlot = slot:FindFirstChild("Item"); local pSlot = slot:FindFirstChild("Price")
						if iSlot and tonumber(iSlot.Value) == watched.id then
							table.insert(found, {itemName=watched.name, shopName=shop.Name, price=pSlot and formatNumber(pSlot.Value) or "?"})
						end
						if slotIndex % 40 == 0 then task.wait() end
					end
				end
				if shopIndex % 10 == 0 then task.wait() end
			end
		end
		if watchedIndex % 10 == 0 then task.wait() end
	end
	return found
end

function notifyShopItem(itemName, shopName, price)
	showActionDialog({
		Title = "🛒 " .. itemName .. " in stock!",
		Content = shopName .. " — " .. price .. "g",
		ActionTitle = "Teleport to Shop",
		Callback = function()
			local pos = getShopPosition(shopName)
			if pos then
				teleportTo(pos + Vector3.new(0, 5, 0))
				notify({Title="Teleported", Content="Arrived at " .. shopName, Duration=3})
			end
		end,
	})
end

function refreshShopWatcher()
	local hits = findWatchedItemsInShops()
	for _, hit in pairs(hits) do notifyShopItem(hit.itemName, hit.shopName, hit.price); task.wait(0.3) end
end

function buildShopItemsDisplay(shopName)
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

function updatePresentParagraph()
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

function markPresent(part)
	if not espToggles.present then return end
	if part:FindFirstChild("PresentESP_BB") then return end
	addBillboardESP(part, "🎁 PRESENT", Color3.fromRGB(255,80,80), "PresentESP")
	addHighlightESP(part.Parent or part, Color3.fromRGB(255,50,50), Color3.new(1,1,1), "PresentESP")
end

function collectPresentIfNeeded()
	if not autoCollect.present then
		return
	end
	local model = LatestPresentModel
	if not model or not model.Parent then
		return
	end
	task.wait(0.3)
	local attempts = 0
	repeat
		pcall(function()
			local remote = model:FindFirstChild("InteractEvent") or model:FindFirstChildOfClass("RemoteEvent")
			if remote then
				remote:FireServer()
			end
		end)
		task.wait(0.1)
		attempts += 1
	until not model or not model.Parent or not autoCollect.present or attempts > 100
end

function teleportToPresentNow(skipEnabledCheck)
	if not skipEnabledCheck and not enabled.present then
		notify({Title="Present", Content="Enable Present first.", Duration=2})
		return false
	end
	if LatestPresent and LatestPresent.Parent then
		teleportTo(LatestPresent.Position)
		collectPresentIfNeeded()
		notify({Title="Teleported!", Content="Arrived at present.", Duration=3})
		return true
	end
	notify({Title="Present", Content="No present detected yet.", Duration=3})
	return false
end

function onPresentFound(present)
	repeat task.wait() until present:FindFirstChild("PP")
	local part = present:FindFirstChildOfClass("Part")
	if not part then return end
	markPresent(part)
	LatestPresent = part; LatestPresentModel = present
	updatePresentParagraph()
	if not enabled.present then return end
	if autoTeleportState.present and not autoTeleportedPresents[present] then
		autoTeleportedPresents[present] = true
		task.spawn(function()
			teleportToPresentNow(true)
		end)
	end
	if notif.present then
		showActionDialog({
			Title = "🎁 Present Found!",
			Content = "A new present has spawned.",
			ActionTitle = "Teleport to Present",
			Callback = function()
				teleportToPresentNow(true)
			end,
		})
	end
end

for _, child in pairs(Workspace:GetChildren()) do
	if string.sub(string.lower(child.Name),1,7) == "present" and #child.Name == 8 then task.spawn(onPresentFound, child) end
end
connectSignal(Workspace.ChildAdded, function(child)
	if string.sub(string.lower(child.Name),1,7) == "present" and #child.Name == 8 then task.spawn(onPresentFound, child) end
end)

-- =====================================================================
-- WINDUI INIT
-- =====================================================================
WindUI = loadCachedRemote(
	{
		"https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
		"https://github.com/Footagesus/WindUI/releases/latest/download/main.lua",
	},
	"FFHub/WindUI.lua"
)

local ActualWindow = WindUI:CreateWindow({
	Title = "Fantastic Frontier Hub",
	Icon = "compass",
	Author = "by SeventhBuilder • " .. HUB_VERSION,
	Folder = "FFHub",
	Size = UDim2.fromOffset(640, 470),
	MinSize = Vector2.new(580, 360),
	MaxSize = Vector2.new(920, 640),
	Theme = "Dark",
	ToggleKey = currentToggleKey,
	Transparent = true,
	Resizable = true,
	SideBarWidth = 190,
	HideSearchBar = false,
	ScrollBarEnabled = true,
})

Window = {
	_actual = ActualWindow,
	SetTheme = function(_, theme)
		pcall(function() WindUI:SetTheme(theme) end)
	end,
	SetToggleKey = function(_, keyCode)
		currentToggleKey = keyCode or currentToggleKey
		currentToggleKeyName = formatToggleKeyName(currentToggleKey)
		pcall(function() ActualWindow:SetToggleKey(currentToggleKey) end)
	end,
	ShowDialog = function(_, config)
		return ActualWindow:Dialog(config)
	end,
	Destroy = function()
		pcall(function() ActualWindow:Destroy() end)
	end,
}

getgenv().FFHubUnload = function()
	pcall(function() ActualWindow:Destroy() end)
end

ActualWindow:OnClose(function()
	if suppressWindowCloseNotice then
		return
	end
	WindUI:Notify({
		Title = "FF Hub",
		Content = "Press " .. currentToggleKeyName .. " to reopen the window.",
		Duration = 5,
	})
end)

if #pendingActionDialogs > 0 then
	task.spawn(function()
		local queuedDialogs = pendingActionDialogs
		pendingActionDialogs = {}
		for _, dialogOpts in ipairs(queuedDialogs) do
			if not getgenv().scriptRunning then
				break
			end
			showActionDialog(dialogOpts)
			task.wait(0.1)
		end
	end)
end


WorldTab     = createContainerWrapper(ActualWindow:Tab({Title = "World", Icon = "globe"}))
PlantsTab    = createContainerWrapper(ActualWindow:Tab({Title = "Plants", Icon = "leaf"}))
AnimalsTab   = createContainerWrapper(ActualWindow:Tab({Title = "Animals", Icon = "rabbit"}))
MonstersTab  = createContainerWrapper(ActualWindow:Tab({Title = "Monsters", Icon = "skull"}))
AutoFarmTab  = createContainerWrapper(ActualWindow:Tab({Title = "AutoFarm", Icon = "zap"}))
TeleportsTab = createContainerWrapper(ActualWindow:Tab({Title = "Teleports", Icon = "map"}))
PlayerTab    = createContainerWrapper(ActualWindow:Tab({Title = "Player", Icon = "user"}))
ShopsTab     = createContainerWrapper(ActualWindow:Tab({Title = "Shops", Icon = "shopping-cart"}))
SettingsTab  = createContainerWrapper(ActualWindow:Tab({Title = "Settings", Icon = "settings"}))

plantDropdownOptions = nil
animalDropdownOptions = nil
monsterDropdownOptions = nil
collectibleDropdownOptions = nil
travelerDropdownOptions = nil
entranceDropdownOptions = nil
yieldUIBuild()

function getThemeOptions()
	local themes = {}
	local ok, themeTable = pcall(function() return WindUI:GetThemes() end)
	if ok and type(themeTable) == "table" then
		for themeName, _ in pairs(themeTable) do
			table.insert(themes, themeName)
		end
	end
	if #themes == 0 then
		themes = {"Dark", "Light"}
	end
	table.sort(themes)
	return themes
end

notify({Title="FF Hub", Content="Loaded " .. HUB_VERSION .. " by SeventhBuilder", Duration=3})
yieldUIBuild()

connectSignal(ReplicatedStorage.Events.NightBegin.OnClientEvent, function()
	shopPositionCache = {}
	task.wait(2)
	onNightBeginEntrances()
	refreshShopWatcher()
	checkAllTravelers(TRAVELERS_NIGHT)
	if selectedShopName then buildShopItemsDisplay(selectedShopName) end
end)

pcall(function()
	connectSignal(ReplicatedStorage.Events.DayBegin.OnClientEvent, function()
		task.wait(2)
		checkAllTravelers(TRAVELERS_DAY)
	end)
end)

function findFirstTrackedPlantTarget(entry)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local foundModel, foundPart = nil, nil
	local closestDistance = math.huge
	iterateTrackedPlantInstances(entry, function(model, part)
		if not foundModel then
			foundModel, foundPart = model, part
		end
		if part then
			local distance = hrp and (part.Position - hrp.Position).Magnitude or 0
			if distance < closestDistance then
				foundModel, foundPart = model, part
				closestDistance = distance
			end
		end
	end)
	return foundModel, foundPart
end

function collectPlantEntryNow(entry)
	if not entry then return end
	local model, part = findFirstTrackedPlantTarget(entry)
	if not model then
		notify({Title=entry.label, Content="Plant is not available right now.", Duration=3})
		return
	end
	if part and part.Parent then
		teleportTo(part.Position + Vector3.new(0, 5, 0))
	end
	local remote = model:FindFirstChild("InteractEvent", true) or model:FindFirstChild("CollectEvent", true)
	if remote then
		for _ = 1, 15 do
			pcall(function() remote:FireServer() end)
			task.wait(0.1)
			if not model.Parent then break end
		end
	end
end

updateTrackedPlantStatus = function(entry, count)
	if not entry then return end
	if entry.section then
		entry.section:SetTitle(("Tracked - %s (%d)"):format(entry.label, count))
	end
	local paragraph = trackedPlantStatusParagraphs[entry.key]
	if paragraph then
		updateParagraph(paragraph, "Status", "Exists: " .. tostring(count))
	end
end

function clearTrackedPlantESP(entry)
	if not entry then return end
	local tag = getPlantESPTag(entry)
	iterateTrackedPlantInstances(entry, function(model)
		removeESP(model, tag)
	end)
end

function removeTrackedPlant(optionLabel, keepSelection)
	local data = plantOptionLookup[optionLabel]
	if not data then return end
	local entry = trackedPlantEntries[data.key]
	if not entry then return end

	clearTrackedPlantESP(entry)
	if entry.section then
		entry.section:Destroy()
	end

	trackedPlantStatusParagraphs[data.key] = nil
	trackedPlantEntries[data.key] = nil
	plantScanDirty = true

	rebuildPlantSelectionCache()
	queuePlantRefresh(0.1)

	if not keepSelection then
		trackerSelections.plants[optionLabel] = nil
		setDropdownSelection("plants")
	end
end

function addTrackedPlant(optionLabel)
	local data = plantOptionLookup[optionLabel]
	if not data then return end
	if trackedPlantEntries[data.key] then return end

	local entry = {
		key = data.key,
		workspaceName = data.workspaceName,
		matchKey = data.matchKey,
		optionLabel = optionLabel,
		label = data.displayName,
		displayName = data.displayName,
		entityType = "Plant",
		special = data.special,
		active = true,
		notify = true,
		esp = true,
		autoTeleport = false,
		autoCollect = false,
	}
	trackedPlantEntries[data.key] = entry
	plantScanDirty = true

	rebuildPlantSelectionCache()

	local section = PlantsTab:CreateSection("Tracked - " .. entry.label .. " (0)")
	entry.section = section
	section:CreateToggle({
		Name = "Notify",
		CurrentValue = true,
		Callback = function(v)
			entry.notify = v
		end,
	})
	section:CreateToggle({
		Name = "ESP",
		CurrentValue = true,
		Callback = function(v)
			entry.esp = v
			rebuildPlantSelectionCache()
			if not v then
				clearTrackedPlantESP(entry)
			else
				queuePlantRefresh(0.05)
			end
		end,
	})
	section:CreateToggle({
		Name = "Auto Teleport",
		CurrentValue = false,
		Callback = function(v)
			entry.autoTeleport = v
		end,
	})
	section:CreateToggle({
		Name = "Auto Collect",
		CurrentValue = false,
		Callback = function(v)
			entry.autoCollect = v
		end,
	})
	section:CreateButton({
		Name = "Teleport",
		Callback = function()
			if entry.autoCollect then
				collectPlantEntryNow(entry)
				return
			end
			local _, part = findFirstTrackedPlantTarget(entry)
			if part then
				teleportTo(part.Position + Vector3.new(0, 5, 0))
			else
				notify({Title=entry.label, Content="Plant is not available right now.", Duration=3})
			end
		end,
	})
	section:CreateButton({
		Name = "Collect Now",
		Callback = function()
			collectPlantEntryNow(entry)
		end,
	})
	trackedPlantStatusParagraphs[entry.key] = section:CreateParagraph({
		Title = "Status",
		Content = "Exists: 0",
	})
	section:CreateButton({
		Name = "Stop Tracking",
		Callback = function()
			removeTrackedPlant(optionLabel)
		end,
	})
	queuePlantRefresh(0.05)
	notify({Title="Plant Tracker", Content="Now tracking: " .. data.displayName, Duration=3})
end

function removeTrackedEntity(selectionKey, lookupTable, storeTable, optionLabel, keepSelection)
	local data = lookupTable[optionLabel]
	if not data then return end
	local entry = storeTable[data.key or data.workspaceName]
	if not entry then return end

	for _, workspaceName in ipairs(getTrackedWorkspaceNames(entry)) do
		local instance = findEntityInWorkspace(workspaceName)
		if instance then
			clearTrackedInstanceESP(instance, entry)
		end
	end
	if entry.section then
		entry.section:Destroy()
	end
	storeTable[data.key or data.workspaceName] = nil
	if not trackerSelections[selectionKey] then
		trackerSelections[selectionKey] = {}
	end
	trackerSelections[selectionKey][optionLabel] = nil
	if not keepSelection then
		setDropdownSelection(selectionKey)
	end
end

function addTrackedEntity(selectionKey, tabWrapper, lookupTable, storeTable, optionLabel, entityType)
	local data = lookupTable[optionLabel]
	if not data then return end
	if storeTable[data.key or data.workspaceName] then return end

	local entry = {
		key = data.key or data.workspaceName,
		optionLabel = optionLabel,
		workspaceName = data.workspaceName,
		workspaceNames = data.workspaceNames,
		label = data.displayName,
		active = true,
		notify = true,
		esp = true,
		autoTeleport = false,
		entityType = entityType,
		isNight = data.isNight,
	}
	storeTable[entry.key] = entry

	local section = tabWrapper:CreateSection("Tracked - " .. data.displayName)
	entry.section = section
	section:CreateToggle({
		Name = "Notify",
		CurrentValue = true,
		Callback = function(v)
			entry.notify = v
		end,
	})
	section:CreateToggle({
		Name = "ESP",
		CurrentValue = true,
		Callback = function(v)
			entry.esp = v
			for _, workspaceName in ipairs(getTrackedWorkspaceNames(entry)) do
				local instance = findEntityInWorkspace(workspaceName)
				if instance then
					if v then applyTrackedInstanceESP(instance, entry)
					else clearTrackedInstanceESP(instance, entry) end
				end
			end
		end,
	})
	section:CreateButton({
		Name = "Teleport",
		Callback = function()
			teleportToTrackedInstance(entry, data.displayName)
		end,
	})
	if entityType == "Collectible" then
		section:CreateToggle({
			Name = "Auto Teleport",
			CurrentValue = false,
			Callback = function(v)
				entry.autoTeleport = v
			end,
		})
	end
	if entityType == "Monster" then
		section:CreateButton({
			Name = "Bring To Me",
			Callback = function()
				bringTrackedInstanceToPlayer(entry, data.displayName)
			end,
		})
	end
	section:CreateButton({
		Name = "Check Now",
		Callback = function()
			local instance = refreshTrackedInstance(entry.key, entry)
			if instance then
				notify({Title=data.displayName, Content="Found in this server.", Duration=3})
			else
				notify({Title=data.displayName, Content="Not available right now.", Duration=3})
			end
		end,
	})

	section:CreateButton({
		Name = "Stop Tracking",
		Callback = function()
			removeTrackedEntity(selectionKey, lookupTable, storeTable, optionLabel)
		end,
	})

	refreshTrackedInstance(entry.key, entry)
	notify({Title=entityType, Content="Now tracking: " .. data.displayName, Duration=3})
end

function syncTrackerSelections(selectionKey, selectedValues, addFn, removeFn)
	local nextSelection = normalizeSelectionList(selectedValues)
	local currentSelection = trackerSelections[selectionKey]

	for optionLabel in pairs(currentSelection) do
		if not nextSelection[optionLabel] then
			currentSelection[optionLabel] = nil
			removeFn(optionLabel, true)
		end
	end

	for optionLabel in pairs(nextSelection) do
		if not currentSelection[optionLabel] then
			currentSelection[optionLabel] = true
			addFn(optionLabel)
		end
	end
end

function destroyMatchingWorkspaceInstances(matchFn)
	local removed = 0
	local descendants = Workspace:GetDescendants()
	for index = #descendants, 1, -1 do
		local obj = descendants[index]
		if matchFn(obj) then
			removed += 1
			pcall(function()
				obj:Destroy()
			end)
		end
		if index % 250 == 0 then
			task.wait()
		end
	end
	return removed
end

local presentSection = WorldTab:CreateSection("Present")
presentSection:CreateToggle({
	Name = "Enable Present",
	CurrentValue = false,
	Callback = function(v)
		enabled.present = v
		updatePresentParagraph()
		notify({Title="Present", Content=v and "Enabled" or "Disabled", Duration=2})
		if v and LatestPresent and LatestPresent.Parent and autoTeleportState.present then
			task.spawn(function()
				teleportToPresentNow(true)
			end)
		end
		if v and LatestPresent and LatestPresent.Parent and notif.present then
			showActionDialog({
				Title = "🎁 Present Ready",
				Content = "A present is already available.",
				ActionTitle = "Teleport to Present",
				Callback = function()
					teleportToPresentNow(true)
				end,
			})
		end
	end,
})
presentSection:CreateToggle({
	Name = "Auto Teleport",
	CurrentValue = false,
	Callback = function(v)
		autoTeleportState.present = v
		if v and enabled.present and LatestPresent and LatestPresent.Parent then
			task.spawn(function()
				teleportToPresentNow(true)
			end)
		end
	end,
})
presentSection:CreateToggle({
	Name = "Auto Collect",
	CurrentValue = false,
	Callback = function(v)
		autoCollect.present = v
	end,
})
presentSection:CreateButton({
	Name = "Teleport to Present",
	Callback = function()
		teleportToPresentNow()
	end,
})
presentStatusParagraph = presentSection:CreateParagraph({
	Title = "Present Status",
	Content = "Enable Present to begin tracking.",
})
yieldUIBuild()

local entrancesSection = WorldTab:CreateSection("Entrances")
entrancesSection:CreateLabel("Select multiple entrances. Selecting one again removes it from tracking.")
createTrackerDropdownAsync("entrances", entrancesSection, 0.02, function(section)
	return section:CreateDropdown({
		Name = "Entrances to Track",
		Options = getEntranceDropdownOptions(),
		CurrentOption = {},
		MultipleOptions = true,
		SearchEnabled = false,
		Callback = function(opt)
			syncTrackerSelections("entrances", opt, function(label)
				local data = entranceOptionLookup[label]
				local evRef = data and data.entrance
				if not evRef then return end
				enabled[evRef.key] = true
				refreshEntranceStatus(evRef)
				notify({Title=evRef.label, Content="Enabled", Duration=2})
			end, function(label)
				local data = entranceOptionLookup[label]
				local evRef = data and data.entrance
				if not evRef then return end
				enabled[evRef.key] = false
				clearEntranceESP(evRef.key)
				updateParagraph(entranceParagraphs[evRef.key], evRef.label, "Disabled.")
				notify({Title=evRef.label, Content="Disabled", Duration=2})
			end)
		end,
	})
end)
for entranceIndex, ev in ipairs(ENTRANCES) do
	local evRef = ev
	entranceParagraphs[ev.key] = entrancesSection:CreateParagraph({
		Title = ev.label,
		Content = "Select it above to check status.",
	})
	entrancesSection:CreateButton({
		Name = "Teleport to " .. ev.label,
		Callback = function()
			teleportEntrance(evRef)
		end,
	})
	if entranceIndex % 2 == 0 then
		yieldUIBuild()
	end
end
yieldUIBuild()

local travelerSection = WorldTab:CreateSection("Traveler NPCs")
travelerSection:CreateLabel("Select multiple travelers. Selecting one again removes it from tracking.")
createTrackerDropdownAsync("travelers", travelerSection, 0.05, function(section)
	return section:CreateDropdown({
		Name = "Travelers to Track",
		Options = getTravelerDropdownOptions(),
		CurrentOption = {},
		MultipleOptions = true,
		SearchEnabled = true,
		Callback = function(opt)
			syncTrackerSelections("travelers", opt, function(label)
				addTrackedEntity("travelers", WorldTab, travelerOptionLookup, travelerWatchList, label, "Traveler")
			end, function(label)
				removeTrackedEntity("travelers", travelerOptionLookup, travelerWatchList, label)
			end)
		end,
	})
end)
yieldUIBuild()

local performanceSection = WorldTab:CreateSection("Performance")
performanceSection:CreateButton({Name="Remove All Trees", Callback=function()
	local treeNames = {
		PostTrees = true,
		Tree_A_1 = true,
		Tree_B_1 = true,
		Tree_B_2 = true,
		Tree_C_1 = true,
		Tree_D_1 = true,
		Tree_D_2 = true,
	}
	local removed = destroyMatchingWorkspaceInstances(function(obj)
		return treeNames[obj.Name] == true
	end)
	notify({Title="Performance", Content=("Trees removed: %d"):format(removed), Duration=4})
end})

performanceSection:CreateButton({Name="Remove All Vegetation", Callback=function()
	local vegetationNames = {
		GrassyRootSystemPart = true,
		BushLeafPart = true,
		LilyPadPart = true,
		FlowerPart = true,
		BushPart = true,
		CropPartSQ = true,
		GrassPart = true,
		TallGrassPartSmall = true,
		DeadShrubPart = true,
		PlantPart = true,
		Trunk = true,
		Root = true,
		Leaves = true,
		LeafPart = true,
		WeedPart = true,
		CropPart = true,
	}
	local removed = destroyMatchingWorkspaceInstances(function(obj)
		return vegetationNames[obj.Name] == true or (obj:IsA("MeshPart") and obj.MeshId == "rbxassetid://511992639")
	end)
	notify({Title="Performance", Content=("Vegetation removed: %d"):format(removed), Duration=4})
end})

performanceSection:CreateButton({Name="Remove All Rocks", Callback=function()
	local removed = destroyMatchingWorkspaceInstances(function(obj)
		return obj.Name == "LargeRockPart" or obj.Name == "RockPart"
	end)
	notify({Title="Performance", Content=("Rocks removed: %d"):format(removed), Duration=4})
end})

local utilitiesSection = WorldTab:CreateSection("Utilities")
utilitiesSection:CreateButton({
	Name = "Remove Fog",
	Callback = function()
		removeFogEffects()
		notify({Title="Utilities", Content="Fog removed!", Duration=3})
	end,
})
utilitiesSection:CreateButton({
	Name = "Teleport to Uncollected Ratboy Token",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/JustApstl/FF/refs/heads/main/scripts/teleport-to-uncollected-ratboy-token.lua"))()
	end,
})
yieldUIBuild()

local plantTrackerSection = PlantsTab:CreateSection("Plant Tracker")
plantTrackerSection:CreateLabel("Select multiple plants. Selecting one again removes it from tracking.")
trackerDropdowns.plants = plantTrackerSection:CreateDropdown({
	Name = "Plants to Track",
	Options = getPlantDropdownOptions(),
	CurrentOption = {},
	MultipleOptions = true,
	SearchEnabled = true,
	Callback = function(opt)
		syncTrackerSelections("plants", opt, addTrackedPlant, removeTrackedPlant)
	end,
})
if #getSelectionValues(trackerSelections.plants) > 0 then
	setDropdownSelection("plants")
end
yieldUIBuild()

local collectiblesSection = PlantsTab:CreateSection("Nightmare Collectibles")
collectiblesSection:CreateLabel("Select multiple collectibles. Selecting one again removes it from tracking.")
createTrackerDropdownAsync("collectibles", collectiblesSection, 0.15, function(section)
	return section:CreateDropdown({
		Name = "Collectibles to Track",
		Options = getCollectibleDropdownOptions(),
		CurrentOption = {},
		MultipleOptions = true,
		SearchEnabled = true,
		Callback = function(opt)
			syncTrackerSelections("collectibles", opt, function(label)
				addTrackedEntity("collectibles", PlantsTab, collectibleOptionLookup, entityWatchList, label, "Collectible")
			end, function(label)
				removeTrackedEntity("collectibles", collectibleOptionLookup, entityWatchList, label)
			end)
		end,
	})
end)
yieldUIBuild()

local animalsSection = AnimalsTab:CreateSection("Animal Tracker")
animalsSection:CreateLabel("Select multiple animals. Selecting one again removes it from tracking.")
createTrackerDropdownAsync("animals", animalsSection, 0.2, function(section)
	return section:CreateDropdown({
		Name = "Animals to Track",
		Options = getAnimalDropdownOptions(),
		CurrentOption = {},
		MultipleOptions = true,
		SearchEnabled = true,
		Callback = function(opt)
			syncTrackerSelections("animals", opt, function(label)
				addTrackedEntity("animals", AnimalsTab, animalOptionLookup, entityWatchList, label, "Animal")
			end, function(label)
				removeTrackedEntity("animals", animalOptionLookup, entityWatchList, label)
			end)
		end,
	})
end)
yieldUIBuild()

local monstersSection = MonstersTab:CreateSection("Monster Tracker")
monstersSection:CreateLabel("Select multiple monsters. Selecting one again removes it from tracking.")
createTrackerDropdownAsync("monsters", monstersSection, 0.25, function(section)
	return section:CreateDropdown({
		Name = "Monsters to Track",
		Options = getMonsterDropdownOptions(),
		CurrentOption = {},
		MultipleOptions = true,
		SearchEnabled = true,
		Callback = function(opt)
			syncTrackerSelections("monsters", opt, function(label)
				addTrackedEntity("monsters", MonstersTab, monsterOptionLookup, entityWatchList, label, "Monster")
			end, function(label)
				removeTrackedEntity("monsters", monsterOptionLookup, entityWatchList, label)
			end)
		end,
	})
end)
yieldUIBuild()

MonstersTab:CreateSection("Combat")
MonstersTab:CreateToggle({
	Name = "Faster Kills",
	CurrentValue = false,
	Callback = function(v)
		enableFastKills(v)
		notify({Title="Faster Kills", Content=v and "Enabled" or "Disabled", Duration=3})
	end,
})
MonstersTab:CreateButton({
	Name = "Bring Spider Boss To Me",
	Callback = function()
		bringSpiderBossToPlayer()
	end,
})
MonstersTab:CreateButton({
	Name = "Fast Regen Stamina",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/SeventhBuilder/FF/main/scripts/fast-regen-stamina.lua"))()
	end,
})
yieldUIBuild()

-- =====================================================================
-- AUTOFARM TAB
-- =====================================================================
AutoFarmTab:CreateSection("🪲 Firefly Stones")
AutoFarmTab:CreateToggle({Name="Firefly Stones AutoFarm", CurrentValue=false, Flag="FireflyFarm",
	Callback=function(v) ffarm=v; if v then checkTP() end; notify({Title="AutoFarm", Content="Firefly "..(v and "ON" or "OFF"), Duration=2}) end})

AutoFarmTab:CreateSection("🪺 Bird Nests")
AutoFarmTab:CreateToggle({Name="Bird Nests AutoFarm", CurrentValue=false, Flag="BirdFarm",
	Callback=function(v) bfarm=v; if v then teleportTo(Vector3.new(-1405,325,-2271)); task.wait(1); checkTP() end; notify({Title="AutoFarm", Content="Bird Nests "..(v and "ON" or "OFF"), Duration=2}) end})

AutoFarmTab:CreateSection("🍔 Deli")
AutoFarmTab:CreateDropdown({Name="Deli Mode", Options={"Both (Random)","Short Wait","Long Wait"},
	CurrentOption={"Both (Random)"}, Flag="DeliMode",
	Callback=function(opt) shortwait=opt[1]=="Short Wait"; longwait=opt[1]=="Long Wait"; randomboth=opt[1]=="Both (Random)" end})
AutoFarmTab:CreateToggle({Name="Deli AutoFarm", CurrentValue=false, Flag="DeliFarm",
	Callback=function(v) dfarm=v; if v then teleportTo(Vector3.new(7066,144,-1621)); task.wait(3) end; notify({Title="AutoFarm", Content="Deli "..(v and "ON" or "OFF"), Duration=2}) end})
yieldUIBuild()

AutoFarmTab:CreateSection("💀 The Lost (PATCHED) — Requires Hidden Key")
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
				notify({Title="AutoFarm", Content="Lost Farm ON", Duration=3})
			else lfarm=false; notify({Title="AutoFarm", Content="❌ Hidden Key required!", Duration=5}) end
		else lfarm=false; amountEmptyInventory=20; notify({Title="AutoFarm", Content="Lost Farm OFF", Duration=2}) end
	end})
yieldUIBuild()

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
				else notify({Title="Shops", Content="Can't resolve position for "..opt[1], Duration=3}) end
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
yieldUIBuild()

TeleportsTab:CreateSection("👺 Ratboy's Nightmare")
TeleportsTab:CreateDropdown({Name="Locations", SearchEnabled=true, CurrentOption={""}, MultipleOptions=false,
	Options={
		"Back of The Theatre","End of the Road","Fish Hall","Inside","Maze of the Root","Meeting Place","MYSTERY STORE",
		"The Back Area","The Ballroom","The Deli","The Grand Hall","The Hidden Library","The Library of Riddles",
		"The Lost","The Mansion","The Old Cave","The Old Mansion","The Plant Room","The Road",
		"The Supermarket","The Theatre","The Vault","Waiting Room",
	},
	Callback=function(opt) if RATBOY_LOC_TP[opt[1]] then teleportTo(RATBOY_LOC_TP[opt[1]]) end end})
TeleportsTab:CreateDropdown({Name="Buttons", SearchEnabled=true, CurrentOption={""}, MultipleOptions=false,
	Options={"Blue Button","Cyan Button","Green Button","Orange Button","Pink Button","Purple Button","Red Button","Yellow Button"},
	Callback=function(opt) if RATBOY_BUTTONS_TP[opt[1]] then teleportTo(RATBOY_BUTTONS_TP[opt[1]]) end end})
TeleportsTab:CreateDropdown({Name="Doors", SearchEnabled=true, CurrentOption={""}, MultipleOptions=false,
	Options={"Blue Door","Cyan Door","Green Door","Orange Door","Pink Door","Purple Door","Red Door","Yellow Door"},
	Callback=function(opt) if RATBOY_DOORS_TP[opt[1]] then teleportTo(RATBOY_DOORS_TP[opt[1]]) end end})
yieldUIBuild()

TeleportsTab:CreateSection("🏠 Housing")
TeleportsTab:CreateDropdown({Name="Housing Location", SearchEnabled=true, CurrentOption={""}, MultipleOptions=false,
	Options={"Black Tower (Celestial Field)","Boathouse (Long Coast)","Castle (Topple Town)","Ice Spire (Matumada)","Starter House (Topple Town)","Two Story House (Topple Town)","White Tower (Quiet Field)"},
	Callback=function(opt) if HOUSING_TP[opt[1]] then teleportTo(HOUSING_TP[opt[1]]) end end})
yieldUIBuild()

TeleportsTab:CreateSection("🧑‍💼 Vendors")
TeleportsTab:CreateDropdown({Name="Vendors", SearchEnabled=true, CurrentOption={""}, MultipleOptions=false,
	Options={"Amy Thistlewitch","Arbewhy","Archaeologist"},
	Callback=function(opt) if VENDOR_TP[opt[1]] then teleportTo(VENDOR_TP[opt[1]]) end end})
yieldUIBuild()

TeleportsTab:CreateSection("🚪 Entrances")
for entranceIndex, ev in ipairs(ENTRANCES) do
	local evRef = ev
	TeleportsTab:CreateButton({Name="Teleport to "..ev.label, Callback=function() teleportEntrance(evRef) end})
	if entranceIndex % 2 == 0 then
		yieldUIBuild()
	end
end
yieldUIBuild()

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
			if not Clip and player.Character then
				for _, child in pairs(player.Character:GetDescendants()) do
					if child:IsA("BasePart") and child.CanCollide then child.CanCollide = false end
				end
			end
		end)
	else if Noclipping then Noclipping:Disconnect(); Noclipping = nil end end
end})

PlayerTab:CreateToggle({Name="Fly Jump", CurrentValue=false, Flag="FlyJump", Callback=function(v)
	setFlyJump(v)
end})

PlayerTab:CreateToggle({Name="Fly", CurrentValue=false, Flag="Fly", Callback=function(v)
	if v then NOFLY(); task.wait(); sFLY() else NOFLY() end
end})
yieldUIBuild()

local playerESPSection = PlayerTab:CreateSection("Players")
playerESPSection:CreateToggle({Name="Players ESP", CurrentValue=espToggles.players, Flag="PlayersESP",
	Callback=function(v)
		espToggles.players = v
		if not v then
			clearPlayersESP()
		else
			refreshPlayersESP()
		end
		notify({Title="Players ESP", Content=v and "Enabled" or "Disabled", Duration=2})
	end})
playerESPSection:CreateLabel("Shows player name and current health.")
yieldUIBuild()

PlayerTab:CreateSection("🛠 Tools")

PlayerTab:CreateButton({Name="Telekinesis  [Hold=Grab | Q/E=Dist | R=Rot | T=Pull | Y=Fling]", Callback=function()
	function inject(obj, fn)
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
		function spawnBeam(f,t,c)
			local p1=Instance.new("ObjectValue"); p1.Name="Part1"; p1.Value=f
			local p2=Instance.new("ObjectValue"); p2.Name="Part2"; p2.Value=t
			local pr=Instance.new("ObjectValue"); pr.Name="Par"; pr.Value=c
			local co=Instance.new("ObjectValue"); co.Name="Color"; co.Value=bcs
			local bs=lc:Clone(); bs.Disabled=false
			p1.Parent=bs; p2.Parent=bs; pr.Parent=bs; co.Parent=bs; bs.Parent=workspace
			if t==grabbed then ovRef=p2 end
		end
		function onMD(mouse)
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
		function onKD(k) k=k:lower()
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
	notify({Title="Telekinesis", Content="Added to backpack!", Duration=3})
end})

PlayerTab:CreateButton({Name="B-Tools", Callback=function()
	for _,v in pairs(Workspace:GetDescendants()) do if v:IsA("BasePart") then v.Locked=false end end
	for i=1,4 do local t=Instance.new("HopperBin"); t.BinType=i; t.Parent=player:FindFirstChildOfClass("Backpack") end
	notify({Title="B-Tools", Content="Added to backpack!", Duration=3})
end})

PlayerTab:CreateButton({Name="Infinite Yield", Callback=function()
	loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end})
yieldUIBuild()

-- =====================================================================
-- SHOPS TAB
-- =====================================================================
function removeWatchedShopItem(optionLabel, keepSelection)
	local data = shopItemOptionLookup[optionLabel]
	if not data then return end
	for index = #watchedShopItems, 1, -1 do
		local entry = watchedShopItems[index]
		if entry.id == data.itemId then
			if entry.section then
				entry.section:Destroy()
			end
			table.remove(watchedShopItems, index)
			break
		end
	end
	if not keepSelection then
		trackerSelections.shopItems[optionLabel] = nil
		setDropdownSelection("shopItems")
	end
end

function addWatchedShopItem(optionLabel)
	local data = shopItemOptionLookup[optionLabel]
	if not data then return end
	for _, entry in ipairs(watchedShopItems) do
		if entry.id == data.itemId then
			return
		end
	end

	local entry = {
		id = data.itemId,
		name = data.displayName,
		active = true,
		optionLabel = optionLabel,
	}
	table.insert(watchedShopItems, entry)

	local section = ShopsTab:CreateSection("Tracked Item - " .. data.displayName)
	entry.section = section
	section:CreateToggle({
		Name = "Notify in Shops",
		CurrentValue = true,
		Callback = function(v)
			entry.active = v
		end,
	})
	section:CreateButton({
		Name = "Stop Watching",
		Callback = function()
			removeWatchedShopItem(optionLabel)
		end,
	})
end

task.spawn(function()
	repeat task.wait(0.2) until Workspace:FindFirstChild("Shops")
	local shopNames = getShopNames()
	if #shopNames == 0 then shopNames = {"No shops found"} end

	local shopBrowserSection = ShopsTab:CreateSection("🛒 Shop Browser")
	shopBrowserSection:CreateDropdown({Name="Select Shop", Options=shopNames, CurrentOption={""},
		MultipleOptions=false, SearchEnabled=true, Flag="SelectedShop",
		Callback=function(opt)
			selectedShopName = opt[1]
			buildShopItemsDisplay(selectedShopName)
		end})
	selectedShopName = nil
	yieldUIBuild()

	shopItemParagraph = shopBrowserSection:CreateParagraph({Title="Shop Items", Content="Select a shop above to view its inventory."})
	yieldUIBuild()

	shopBrowserSection:CreateButton({Name="Teleport to Selected Shop", Callback=function()
		if not selectedShopName or selectedShopName == "No shops found" then
			notify({Title="Shops", Content="Select a shop first.", Duration=3}); return
		end
		local pos = getShopPosition(selectedShopName)
		if pos then teleportTo(pos + Vector3.new(0,5,0)); notify({Title="Teleported", Content="Arrived at "..selectedShopName, Duration=3})
		else notify({Title="Shops", Content="Can't find "..selectedShopName.."'s position.", Duration=3}) end
	end})

	local itemTrackerSection = ShopsTab:CreateSection("Item Tracker")
	itemTrackerSection:CreateButton({
		Name = "Load Searchable Item List",
		Callback = function()
			if shopItemOptionsLoaded then
				notify({Title="Shops", Content="Item list is already loaded.", Duration=3})
				return
			end
			notify({Title="Shops", Content="Loading item list...", Duration=3})
			task.spawn(function()
				local options = buildShopItemOptions()
				shopItemOptionsLoaded = true
				if trackerDropdowns.shopItems then
					trackerDropdowns.shopItems:Refresh(options)
					setDropdownSelection("shopItems")
				end
				notify({Title="Shops", Content=("Loaded %d item options."):format(#options), Duration=4})
			end)
		end,
	})
	trackerDropdowns.shopItems = itemTrackerSection:CreateDropdown({
		Name = "Items to Watch",
		Options = {"Press 'Load Searchable Item List'"},
		CurrentOption = {},
		MultipleOptions = true,
		SearchEnabled = true,
		Callback = function(opt)
			if not shopItemOptionsLoaded or shopItemOptionLookup == nil or next(shopItemOptionLookup) == nil then
				notify({Title="Shops", Content="Load the item list first.", Duration=3})
				return
			end
			syncTrackerSelections("shopItems", opt, addWatchedShopItem, removeWatchedShopItem)
		end,
	})
end)

-- =====================================================================
-- SETTINGS TAB
-- =====================================================================
setFlyJump = function(state)
	flyJumpEnabled = state
	if flyJumpConnection then
		flyJumpConnection:Disconnect()
		flyJumpConnection = nil
	end
	if not state then
		return
	end
	flyJumpConnection = UserInputService.JumpRequest:Connect(function()
		if not flyJumpEnabled or not getgenv().scriptRunning then return end
		local character = player.Character
		local hum = character and character:FindFirstChildWhichIsA("Humanoid")
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if hum and hrp then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			hrp.AssemblyLinearVelocity = Vector3.new(
				hrp.AssemblyLinearVelocity.X,
				math.max(hrp.AssemblyLinearVelocity.Y, jumppower),
				hrp.AssemblyLinearVelocity.Z
			)
		end
	end)
end

cleanupHub = function()
	getgenv().scriptRunning = false
	ffarm = false
	bfarm = false
	dfarm = false
	lfarm = false
	watchedShopItems = {}
	selectedShopName = nil
	shopItemOptionsLoaded = false
	plants = {}
	plantNames = {}
	loweredPlantNames = {}
	clearSpiderBodyMovers()
	clearPlantESPVisuals()
	disconnectRuntimeConnections()
	setFlyJump(false)
	pcall(function()
		local hum = player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
		if hum then
			hum.WalkSpeed = 16
			hum.JumpPower = 50
			hum.MaxSlopeAngle = 89
			hum.PlatformStand = false
		end
		Workspace.Gravity = 196.2
		NOFLY()
		if Noclipping then
			Noclipping:Disconnect()
			Noclipping = nil
		end
	end)
	for _, entry in pairs(trackedPlantEntries) do
		clearTrackedPlantESP(entry)
	end
	for _, entry in pairs(entityWatchList) do
		local instance = findEntityInWorkspace(entry.workspaceName or entry.key)
		if instance then
			clearTrackedInstanceESP(instance, entry)
		end
	end
	for _, entry in pairs(travelerWatchList) do
		local instance = findEntityInWorkspace(entry.workspaceName or entry.key)
		if instance then
			clearTrackedInstanceESP(instance, entry)
		end
	end
	clearPlayersESP()
	for _, ev in pairs(ENTRANCES) do
		clearEntranceESP(ev.key)
	end
	getgenv().FFHubUnload = nil
	suppressWindowCloseNotice = true
	pcall(function()
		ActualWindow:Destroy()
	end)
end

getgenv().FFHubUnload = cleanupHub

SettingsTab:CreateSection("🔔 Notifications")
SettingsTab:CreateToggle({Name="Present Notifications",    CurrentValue=notif.present,    Flag="NotifPresent",    Callback=function(v) notif.present=v end})
SettingsTab:CreateToggle({Name="Firefly Notifications",    CurrentValue=notif.firefly,    Flag="NotifFirefly",    Callback=function(v) notif.firefly=v end})
SettingsTab:CreateToggle({Name="Bird Nest Notifications",  CurrentValue=notif.birdnest,   Flag="NotifBird",       Callback=function(v) notif.birdnest=v end})
SettingsTab:CreateToggle({Name="Strangeman Notifications", CurrentValue=notif.strangeman, Flag="NotifStrangeman", Callback=function(v) notif.strangeman=v end})
SettingsTab:CreateToggle({Name="Rabbit Hole Notifications",CurrentValue=notif.rabbithole, Flag="NotifRabbithole", Callback=function(v) notif.rabbithole=v end})
SettingsTab:CreateToggle({Name="Pitfall Notifications",    CurrentValue=notif.pitfall,    Flag="NotifPitfall",    Callback=function(v) notif.pitfall=v end})
yieldUIBuild()

SettingsTab:CreateSection("ESP")
SettingsTab:CreateToggle({Name="Present ESP", CurrentValue=espToggles.present, Flag="PresentESP",
	Callback=function(v)
		espToggles.present = v
		if not v and LatestPresent then
			pcall(function() removeESP(LatestPresent.Parent, "PresentESP") end)
			pcall(function() removeESP(LatestPresent, "PresentESP") end)
		elseif v and LatestPresent and LatestPresent.Parent then
			markPresent(LatestPresent)
		end
		notify({Title="Present ESP", Content=v and "Enabled" or "Disabled", Duration=2})
	end})
SettingsTab:CreateToggle({Name="Plant ESP", CurrentValue=espToggles.plants, Flag="PlantESP",
	Callback=function(v)
		espToggles.plants = v
		if not v then
			for _, entry in pairs(trackedPlantEntries) do
				clearTrackedPlantESP(entry)
			end
		else
			queuePlantRefresh(0.05)
		end
		notify({Title="Plant ESP", Content=v and "Enabled" or "Disabled", Duration=2})
	end})

for entranceIndex, ev in ipairs(ENTRANCES) do
	local evRef = ev
	SettingsTab:CreateToggle({Name=ev.label.." ESP", CurrentValue=true, Flag=ev.key.."ESP",
		Callback=function(v)
			espToggles[evRef.key] = v
			if not v then clearEntranceESP(evRef.key)
			else
				local entrance = evRef.getEntrance()
				if entrance and enabled[evRef.key] then applyEntranceESP(entrance, evRef.key, evRef.color, evRef.label) end
			end
			notify({Title=evRef.label.." ESP", Content=v and "Enabled" or "Disabled", Duration=2})
		end})
	if entranceIndex % 2 == 0 then
		yieldUIBuild()
	end
end
yieldUIBuild()

SettingsTab:CreateSection("Theme")
SettingsTab:CreateLabel("Version: " .. HUB_VERSION)
local keybindLabel = SettingsTab:CreateLabel("Window toggle key: " .. currentToggleKeyName)
SettingsTab:CreateDropdown({Name="Window Keybind", SearchEnabled=true,
	Options={"RightShift","LeftShift","RightControl","LeftControl","Insert","Home","End","PageUp","PageDown","Backquote","Delete","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12"},
	CurrentOption={currentToggleKeyName},
	Callback=function(opt)
		local keyName = opt[1]
		local keyCode = keyName and Enum.KeyCode[keyName]
		if keyCode then
			Window:SetToggleKey(keyCode)
			updateParagraph(keybindLabel, "Window toggle key: " .. currentToggleKeyName, "")
			notify({Title="UI Keybind", Content="Window keybind set to " .. currentToggleKeyName, Duration=3})
		end
	end})
SettingsTab:CreateDropdown({Name="Theme", SearchEnabled=true,
	Options=getThemeOptions(),
	CurrentOption={WindUI:GetCurrentTheme() or "Dark"}, Flag="Theme",
	Callback=function(opt)
		local themeName = opt[1]
		if themeName and themeName ~= "" then
			pcall(function() WindUI:SetTheme(themeName) end)
		end
	end})
yieldUIBuild()

SettingsTab:CreateSection("Exit")
SettingsTab:CreateButton({Name="Exit Hub", Callback=function()
	cleanupHub()
end})
yieldUIBuild()

-- =====================================================================
-- FLY FUNCTIONS
-- =====================================================================
function sFLY()
	repeat task.wait() until player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if flyKeyDown then flyKeyDown:Disconnect(); flyKeyDown = nil end
	if flyKeyUp then flyKeyUp:Disconnect(); flyKeyUp = nil end
	local T=player.Character.HumanoidRootPart; local C={F=0,B=0,L=0,R=0}; local S=0
	local BG=Instance.new("BodyGyro"); local BV=Instance.new("BodyVelocity")
	BG.P=9e4; BG.maxTorque=Vector3.new(9e9,9e9,9e9); BG.Parent=T
	BV.maxForce=Vector3.new(9e9,9e9,9e9); BV.Parent=T; FLYING=true
	local hum=player.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=true end
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
		local h2=player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if h2 then h2.PlatformStand=false end
	end)
end

function NOFLY()
	FLYING=false
	if flyKeyDown then flyKeyDown:Disconnect(); flyKeyDown = nil end
	if flyKeyUp then flyKeyUp:Disconnect(); flyKeyUp = nil end
	local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand=false end
end

-- =====================================================================
-- MAIN LOOPS
-- =====================================================================
task.spawn(function()
	while getgenv().scriptRunning do
		task.wait()
		local hum=player.Character and player.Character:FindFirstChildWhichIsA("Humanoid")
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
						if notif.birdnest then notify({Title="Bird Nests", Content="Nest found!", Duration=3}) end
						teleportTo(part.Position); task.wait(0.05); bs.Collectible.InteractEvent:FireServer()
						for i=0,50 do ReplicatedStorage.Events.OpenSlot:FireServer(i) end; task.wait(3)
					else
						if notif.birdnest then notify({Title="Bird Nests", Content="Not loaded.", Duration=3}) end
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

task.spawn(function()
	while getgenv().scriptRunning do
		task.wait(2)
		if next(trackedPlantEntries) ~= nil then
			processTrackedPlants()
		end
		if espToggles.players then
			refreshPlayersESP()
		end
		local entityRefreshCount = 0
		for name, entry in pairs(entityWatchList) do
			if entry.active then
				refreshTrackedInstance(name, entry)
				entityRefreshCount += 1
				if entityRefreshCount % 3 == 0 then
					task.wait()
				end
			end
		end
		local travelerRefreshCount = 0
		for name, entry in pairs(travelerWatchList) do
			if entry.active then
				refreshTrackedInstance(name, entry)
				travelerRefreshCount += 1
				if travelerRefreshCount % 3 == 0 then
					task.wait()
				end
			end
		end
	end
end)

-- Periodic paragraph refresh loop
task.spawn(function()
	while getgenv().scriptRunning do
		task.wait(5)
		updatePresentParagraph()
	end
end)

-- Initial checks on load
task.spawn(function()
	task.wait(2)
	onNightBeginEntrances()
	updatePresentParagraph()
	if next(trackedPlantEntries) ~= nil then
		processTrackedPlants()
	end
	for name, entry in pairs(entityWatchList) do
		if entry.active then
			refreshTrackedInstance(name, entry)
		end
	end
	for name, entry in pairs(travelerWatchList) do
		if entry.active then
			refreshTrackedInstance(name, entry)
		end
	end
end)

