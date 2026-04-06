repeat wait() until game:FindFirstChild("Players") ~= nil
repeat wait() until game.Players.LocalPlayer ~= nil

local FasterKills = true
local mouse = game.Players.LocalPlayer:GetMouse()
local unsafenames = {
    "TowerWolfNPC"; -- 15
    "Legend"; -- 23
    "Antellery"; -- 24
    "Guardian Snibber"; -- 27
    "TitaniumAncientKnightNPC"; -- 28
    "Twirling Warlock"; -- 29?
    "Big Ant"; -- 43
} -- NPCs that can be killed at 50% or less
local superunsafenames = {
    "TOTALITY JACK"; -- 30
    "Zitrat"; -- 35
    "FantasticDragonNPC"; -- 36
    "WhispererNPC"; -- 40
    "ForestGiantNPC"; -- 43
    "CKnight"; -- 44
    "Ratboy"; -- 45
} -- NPCs that can't be killed early

function IsInTable(table, tofind)
    local found = false
    for i,v in pairs(table) do
        if v == tofind then
            found = true
            break
        end
    end
    return found
end

local function setuphumanoid(v)
    v.ChildAdded:Connect(function(child)
        if child.Name == "PlayerDamages" then
            wait()
            if child:FindFirstChild(game.Players.LocalPlayer.Name) then
                local tracker = child:FindFirstChild(game.Players.LocalPlayer.Name)
                local model = v:FindFirstAncestorOfClass("Model")
                local IsAnchored = false
                for i,v in pairs(model:GetDescendants()) do
                    if v:IsA("BasePart") and v.Anchored == true then
                        IsAnchored = true
                    end
                end
                if not IsAnchored then
                    model = v:FindFirstAncestorWhichIsA("Model")
                    if game.PlaceId == 963149987 and (v.MaxHealth - tracker.Value) / v.MaxHealth < 0.44 and FasterKills == true and IsInTable(unsafenames, model.Name) then
                        wait(0.1)
                        v.Health = 0
                    elseif game.PlaceId == 963149987 and (v.MaxHealth - tracker.Value) / v.MaxHealth < 0.01 and FasterKills == true and IsInTable(superunsafenames, model.Name) then
                        wait(0.1)
                        v.Health = 0
                    elseif game.PlaceId ~= 963149987 and (v.MaxHealth - tracker.Value) / v.MaxHealth < 0.69 and FasterKills == true and not IsInTable(unsafenames, model.Name) and not IsInTable(superunsafenames, model.Name) then
                        wait(0.1)
                        v.Health = 0
                    end
                    tracker.Changed:Connect(function()
                        model = v:FindFirstAncestorWhichIsA("Model")
                        if game.PlaceId == 963149987 and (v.MaxHealth - tracker.Value) / v.MaxHealth < 0.44 and FasterKills == true and IsInTable(unsafenames, model.Name) then
                            wait(0.1)
                            v.Health = 0
                        elseif game.PlaceId == 963149987 and (v.MaxHealth - tracker.Value) / v.MaxHealth < 0.01 and FasterKills == true and IsInTable(superunsafenames, model.Name) then
                            wait(0.1)
                            v.Health = 0
                        elseif game.PlaceId ~= 963149987 and (v.MaxHealth - tracker.Value) / v.MaxHealth < 0.69 and FasterKills == true and not IsInTable(unsafenames, model.Name) and not IsInTable(superunsafenames, model.Name) then
                            wait(0.1)
                            v.Health = 0
                        end
                    end)
                end
            end
        end
    end)
end


mouse.KeyDown:Connect(function(key)
    if key == "l" then
        FasterKills = not FasterKills
        local currenttext = ""
        if FasterKills == true then
            currenttext = "FASTER KILLS are now turned ON!"
        else
            currenttext = "FASTER KILLS are now turned OFF!"
        end
        game.StarterGui:SetCore("SendNotification", {
            Title = "notification";
            Text = currenttext;
            Icon = "rbxassetid://2541869220";
            Duration = 3;
        })
        local model = game:FindFirstAncestorOfClass("Model")
        if game.PlaceId == 963149987 and FasterKills == true and #game.Players:GetPlayers() == 1 then
            wait(1)
            for i,v in pairs(game.Workspace:GetDescendants()) do
                if v:IsA("Humanoid") then
                    local model = game:FindFirstAncestorOfClass("Model")
                    if not v:FindFirstAncestor(game.Players.LocalPlayer.Name) and model ~= nil and not IsInTable(unsafenames, model.Name) and not IsInTable(superunsafenames, model.Name) then
                        v.Health = 0
                    end
                end
            end
        end
    end
end)

for i,v in pairs(game.Workspace:GetDescendants()) do
    if v:IsA("Humanoid") then
        local BelongsToPlayer = false
        for i,x in pairs(game.Players:GetPlayers()) do
            if v:FindFirstAncestor(x.Name) then
                BelongsToPlayer = true
            end
        end
        if not BelongsToPlayer then
            model = v:FindFirstAncestorOfClass("Model")
            if game.PlaceId == 963149987 and FasterKills == true and #game.Players:GetPlayers() == 1 and not IsInTable(unsafenames, model.Name) and not IsInTable(superunsafenames, model.Name) then
                wait(1)
                v.Health = 0
            elseif game.PlaceId == 963149987 and #game.Players:GetPlayers() == 1 and IsInTable(unsafenames, model.Name) then
                setuphumanoid(v)
            else
                setuphumanoid(v)
            end
        end
    end
end
game.Workspace.DescendantAdded:Connect(function(v)
    if v:IsA("Humanoid") then
        local BelongsToPlayer = false
        for i,x in pairs(game.Players:GetPlayers()) do
            if v:FindFirstAncestor(x.Name) then
                BelongsToPlayer = true
            end
        end
        if not BelongsToPlayer then
            model = v:FindFirstAncestorOfClass("Model")
            if game.PlaceId == 963149987 and FasterKills == true and #game.Players:GetPlayers() == 1 and not IsInTable(unsafenames, model.Name) and not IsInTable(superunsafenames, model.Name) then
                wait(1)
                v.Health = 0
            elseif game.PlaceId == 963149987 and #game.Players:GetPlayers() == 1 and IsInTable(unsafenames, model.Name) or game.PlaceId == 963149987 and #game.Players:GetPlayers() == 1 and IsInTable(superunsafenames, model.Name) then
                setuphumanoid(v)
            else
                setuphumanoid(v)
            end
        end
    end
end)

game.StarterGui:SetCore("SendNotification", {
    Title = "Loaded!";
    Text = "Press L to toggle the script on / off! (Made by Aidez)";
    Icon = "rbxassetid://2541869220";
    Duration = 3;
})