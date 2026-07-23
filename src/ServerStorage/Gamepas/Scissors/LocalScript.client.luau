local cas = game:GetService("ContextActionService")
local remote = script.Parent:WaitForChild("Remote")
local tool = script.Parent
local mouse = game:GetService("Players").LocalPlayer:GetMouse()

tool.Activated:Connect(function()
	local hit = mouse.Target
	if not hit then return end
	remote:FireServer(hit)
end)