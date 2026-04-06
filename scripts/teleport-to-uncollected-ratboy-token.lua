for i,v in ipairs(game:GetService("Workspace").Folder:GetDescendants()) do
		task.wait(.01)
		if v:IsA("BoolValue") then
			if v.Value == false then
				local highlight = Instance.new("Highlight")
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.FillColor = Color3.fromRGB(255,255,128)
				highlight.FillTransparency = 0.25
				highlight.OutlineTransparency = 0.5
				highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
				highlight.Adornee = v.Parent.Parent.Holder:FindFirstChildWhichIsA("Model")
				highlight.Parent = v.Parent.Parent.Holder:FindFirstChildWhichIsA("Model")
				goto(v.Parent.Parent.Holder:FindFirstChildWhichIsA("BasePart",true).Position)
				return
			end
		end
	end
