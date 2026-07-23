-- Tool and script by @Marko97_IT https://www.roblox.com/users/202852515/profile

local Tool = script.Parent
local Grips = {
	Idle = CFrame.new(0.5, -0.1, 0, 0, -1, -0, -1, 0, -0, 0, 0, -1),
	Drinking = CFrame.new(1.3, -1, 1, 0, -1, -0, -1, 0, 0, 1, 1.5, -1)
}
local Active = false

Tool.Equipped:Connect(function()
	Tool.Grip = Grips.Idle
end)

Tool.Unequipped:Connect(function()
	Tool.Handle.Sound:Stop()
end)

Tool.Activated:Connect(function()
	if not Active then
		Active = true
		Tool.Grip = Grips.Drinking
		Tool.Handle.Sound:Play()
		wait(2)
		Tool.Grip = Grips.Idle
		wait(2)
		Active = false
	end
end)