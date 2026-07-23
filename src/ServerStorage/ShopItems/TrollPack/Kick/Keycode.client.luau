--This lisions for the player to click with the tool
--do not change if dont know to script
local event = script.Parent:FindFirstChild("Activate")
local tool = script.Parent

tool.Activated:Connect(function()
	event:FireServer()
end)