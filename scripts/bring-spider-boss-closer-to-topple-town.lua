local player = game.Players.LocalPlayer
	if player:FindFirstChild("PlayerScripts") then
		if player:FindFirstChild("PlayerScripts"):FindFirstChild("Fog") then
			player.PlayerScripts.Fog:Destroy()
			venyx:Notify("Bring Spider Boss","Removed fog.","rbxassetid://705101397")
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
	if not game:GetService("Workspace").NPCS.BanditSpiderNPC:FindFirstChildWhichIsA("BasePart") then
		if game.CoreGui:FindFirstChild("FF") then
			if game.CoreGui:FindFirstChild("FF"):FindFirstChild("Main") then
				game.CoreGui:FindFirstChild("FF"):FindFirstChild("Main").Visible = false
			end
		end
		goto(Vector3.new(1496, 73, -3738))
		task.wait(4)
		venyx:Notify("Bring Spider Boss","Teleported to spider boss spawn area. Hub disabled until spider boss teleportation finished.","rbxassetid://705101397")
		task.wait(1)
		if not game:GetService("Workspace").NPCS.BanditSpiderNPC:FindFirstChildWhichIsA("BasePart") then
			venyx:Notify("Bring Spider Boss","No spider boss found.","rbxassetid://705101397")
			if game.CoreGui:FindFirstChild("FF") then
				if game.CoreGui:FindFirstChild("FF"):FindFirstChild("Main") then
					game.CoreGui:FindFirstChild("FF"):FindFirstChild("Main").Visible = true
				end
			end
		else
			task.wait()
			--print("Spider Boss Position"..tostring(game:GetService("Workspace").NPCS.BanditSpiderNPC:FindFirstChildWhichIsA("BasePart").Position))
			local Forces = {}
			local FalseCollisions = {}
			for _,part in pairs(game:GetService("Workspace").NPCS.BanditSpiderNPC:GetDescendants()) do
				for i,c in pairs(part:GetChildren()) do
					if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
						c:Destroy()
					end
				end
				if part:IsA("BasePart") then
					part.CanCollide = false
					task.wait()
					part.CanCollide = true
					table.insert(FalseCollisions, part)
				end
				task.wait()
				local ForceInstance = Instance.new("BodyPosition")
				ForceInstance.Parent = part
				ForceInstance.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
				table.insert(Forces, ForceInstance)
				for i,c in pairs(Forces) do
					c.Position = Vector3.new(684, 226, -438)
				end

			end
			for i,p in pairs(FalseCollisions) do
				p.CanCollide = true
			end
			for i,c in pairs(Forces) do
				c.Position = Vector3.new(684, 226, -438)
			end
			task.wait(5)
			venyx:Notify("Bring Spider Boss","Teleported to spider boss current location. Hub re-enabled.","rbxassetid://705101397")
			if game.CoreGui:FindFirstChild("FF") then
				if game.CoreGui:FindFirstChild("FF"):FindFirstChild("Main") then
					game.CoreGui:FindFirstChild("FF"):FindFirstChild("Main").Visible = true
				end
			end
			goto(game:GetService("Workspace").NPCS.BanditSpiderNPC:FindFirstChildWhichIsA("BasePart").Position + Vector3.new(30,30,30))
		end
	else
		goto(game:GetService("Workspace").NPCS.BanditSpiderNPC:FindFirstChildWhichIsA("BasePart").Position + Vector3.new(30,30,30))
		task.wait()
		--print("Spider Boss Position"..tostring(game:GetService("Workspace").NPCS.BanditSpiderNPC:FindFirstChildWhichIsA("BasePart").Position))
		venyx:Notify("Bring Spider Boss","Teleported to spider boss current location. Hub disabled until spider boss teleportation finished.","rbxassetid://705101397")
		if game.CoreGui:FindFirstChild("FF") then
			if game.CoreGui:FindFirstChild("FF"):FindFirstChild("Main") then
				game.CoreGui:FindFirstChild("FF"):FindFirstChild("Main").Visible = true
			end
		end
		local Forces = {}
		local FalseCollisions = {}
		if game.CoreGui:FindFirstChild("FF") then
			if game.CoreGui:FindFirstChild("FF"):FindFirstChild("Main") then
				game.CoreGui:FindFirstChild("FF"):FindFirstChild("Main").Visible = false
			end
		end
		for _,part in pairs(game:GetService("Workspace").NPCS.BanditSpiderNPC:GetDescendants()) do
			for i,c in pairs(part:GetChildren()) do
				if c:IsA("BodyPosition") or c:IsA("BodyGyro") then
					c:Destroy()
				end
			end
			if part:IsA("BasePart") then
				part.CanCollide = false
				task.wait()
				part.CanCollide = true
				table.insert(FalseCollisions, part)
			end
			task.wait()
			local ForceInstance = Instance.new("BodyPosition")
			ForceInstance.Parent = part
			ForceInstance.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			table.insert(Forces, ForceInstance)
			for i,c in pairs(Forces) do
				c.Position = Vector3.new(684, 226, -438)
			end

		end
		for i,p in pairs(FalseCollisions) do
			p.CanCollide = true
		end
		for i,c in pairs(Forces) do
			c.Position = Vector3.new(684, 226, -438)
		end
		task.wait(5)
		venyx:Notify("Bring Spider Boss","Teleported to spider boss current location. Hub re-enabled.","rbxassetid://705101397")
		if game.CoreGui:FindFirstChild("FF") then
			if game.CoreGui:FindFirstChild("FF"):FindFirstChild("Main") then
				game.CoreGui:FindFirstChild("FF"):FindFirstChild("Main").Visible = true
			end
		end
		goto(game:GetService("Workspace").NPCS.BanditSpiderNPC:FindFirstChildWhichIsA("BasePart").Position + Vector3.new(30,30,30))
	end
