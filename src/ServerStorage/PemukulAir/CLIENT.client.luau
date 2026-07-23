local tool = script.Parent
local handle = tool:FindFirstChild("Handle") or tool:WaitForChild("Part")
local mouse = game.Players.LocalPlayer:GetMouse()
local canslap = false
local cd = false
local equipped = false
local localp = game.Players.LocalPlayer
local char = localp.Character or localp.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid") 

tool.Equipped:Connect(function()
	equipped = true
end)

tool.Unequipped:Connect(function()
	equipped = false
end)

tool.Activated:Connect(function()
	if not cd and equipped then
		cd = true
		local multiplier = 2.25


		if handle.Transparency == 1 then

		end

		canslap = true
		wait(tool:WaitForChild("Speed").Value / multiplier)
		canslap = false
		wait(tool:WaitForChild("Speed").Value - tool:WaitForChild("Speed").Value / multiplier)
		cd = false
	else
	end
end)

handle.Touched:Connect(function(part)
	if canslap then
		if part.Parent:FindFirstChildOfClass("Humanoid") then
			canslap = false
			-- Ensure 'char' and its 'HumanoidRootPart' are available here too
			local currentCharacter = localp.Character -- Get the most up-to-date character
			if currentCharacter then
				local humanoidRootPart = currentCharacter:WaitForChild("HumanoidRootPart") -- Wait for HumanoidRootPart
				local velocity = humanoidRootPart.CFrame.LookVector * tool:WaitForChild("Power").Value

				tool:WaitForChild("Event"):FireServer("slash", part.Parent, velocity)
			end
		else
		end
	else
	end
end)