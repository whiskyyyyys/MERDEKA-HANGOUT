-- LocalScript
local Tool = script.Parent
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remote = ReplicatedStorage:FindFirstChild("MagnetRemote")
if not Remote then
	Remote = Instance.new("RemoteEvent")
	Remote.Name = "MagnetRemote"
	Remote.Parent = ReplicatedStorage
end

local Active = false

Tool.Activated:Connect(function()
	Active = not Active
	Remote:FireServer(Active)
end)
