-- BubbleClient (LocalScript)
local Players = game:GetService("Players")
local Tool = script.Parent
local Remote = Tool:WaitForChild("BubbleRemote")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local equipped = false
local debounce = false

Tool.Equipped:Connect(function()
	equipped = true
end)

Tool.Unequipped:Connect(function()
	equipped = false
end)

Mouse.Button1Down:Connect(function()
	if not equipped or debounce then return end
	debounce = true

	local target = Mouse.Target
	if target then
		local character = target:FindFirstAncestorOfClass("Model")
		if character and Players:GetPlayerFromCharacter(character) and character ~= Player.Character then
			Remote:FireServer(character)
		end
	end

	task.wait(1)
	debounce = false
end)
