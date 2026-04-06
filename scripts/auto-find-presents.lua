function mark(part)

    local epic = Instance.new("Part")
    epic.Parent = part
    epic.Name = "parttrace"
    epic.Position = part.Position
    epic.Size = Vector3.new(0.2,0.2,0.2)
    epic.Anchored = true
    epic.Transparency = 1

    local billgui = Instance.new('BillboardGui', epic)
    local textlab = Instance.new('TextLabel', billgui)

    billgui.Name = "ESP"
    billgui.Adornee  = epic
    billgui.AlwaysOnTop = true
    billgui.ExtentsOffset = Vector3.new(0, 1, 0)
    billgui.Size = UDim2.new(0, 5, 0, 5)
	
    textlab.Name = 'Present'
    textlab.BackgroundColor3 = Color3.new(255, 255, 255)
    textlab.BackgroundTransparency = 1
    textlab.BorderSizePixel = 0
    textlab.Position = UDim2.new(0, 0, 0, -40)
    textlab.Size = UDim2.new(1, 0, 10, 0)
    textlab.Visible = true
    textlab.ZIndex = 10
    textlab.Font = 'ArialBold'
    textlab.FontSize = 'Size14'
    textlab.Text = "PRESENT"
    textlab.TextColor = BrickColor.new('Bright red')
    textlab.TextStrokeColor3 = Color3.fromRGB(0,0,0)
    textlab.TextStrokeTransparency = 0.6
end

function goto(pos)
    active = true 
    if not game.Workspace.HOLE:FindFirstChild("HoleTPEntrance") then
        repeat
        local prevPos = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(1304,96,-525)
        wait()
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = prevPos
        wait(1)
        until game.Workspace.HOLE:FindFirstChild("HoleTPEntrance")
    end
 
    if (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - pos).magnitude < 200 then
        game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
        wait(.3)
        active = false
    else
        local hole = game.Workspace.HOLE.HoleTPEntrance
        local oPos = hole.Position
        local oSize = hole.Size
 
        hole.Size = Vector3.new(1,1,1)
        hole.Transparency = 1
        hole.CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
        repeat hole.Position = game.Players.LocalPlayer.Character.HumanoidRootPart.Position wait() until (hole.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).magnitude < 10
        hole.Position = oPos
        hole.Size = oSize
        repeat wait() until (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(430,441,102)).magnitude < 10
        for i=1, 4 do
            game.Players.LocalPlayer.Character.HumanoidRootPart.Anchored = true
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
            wait(.1)
        end
        wait(.1)
        game.Players.LocalPlayer.Character.HumanoidRootPart.Anchored = false
        active = false
    end
end

function buttonfunction(content)
    for i,v in pairs(game.Workspace:GetChildren()) do
        if string.sub(string.lower(v.Name), 1, 7) == "present" and string.len(v.Name) == 8 then
            goto(v:FindFirstChildOfClass("Part").Position)
        end
    end
end

bindable = Instance.new("BindableFunction")
bindable.OnInvoke = buttonfunction

for i,v in pairs(game.Workspace:GetChildren()) do
    if string.sub(string.lower(v.Name), 1, 7) == "present" and string.len(v.Name) == 8 then
        repeat wait() until v:FindFirstChild("PP")
        mark(v:FindFirstChildOfClass("Part"))
        game.StarterGui:SetCore("SendNotification", {
            Title = "Found present!";
            Text = "A new present has been spotted!";
            Icon = "rbxassetid://1053360438";
            Duration = 5;
            Callback = bindable;
            Button1 = "Teleport to Present";
        })
    end
end
game.Workspace.ChildAdded:Connect(function(child)
    if string.sub(string.lower(child.Name), 1, 7) == "present" and string.len(child.Name) == 8 then
        repeat wait() until child:FindFirstChild("PP")
        mark(child:FindFirstChildOfClass("Part"))
        game.StarterGui:SetCore("SendNotification", {
            Title = "Found present!";
            Text = "A new present has been spotted!";
            Icon = "rbxassetid://1053360438";
            Duration = 5;
            Callback = bindable;
            Button1 = "Teleport to Present";
        })
    end
end)