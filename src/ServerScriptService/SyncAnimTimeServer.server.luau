local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local SyncAnimTime = Remotes:FindFirstChild("SyncAnimTime")
if not SyncAnimTime then
	SyncAnimTime = Instance.new("RemoteEvent")
	SyncAnimTime.Name = "SyncAnimTime"
	SyncAnimTime.Parent = Remotes
end

SyncAnimTime.OnServerEvent:Connect(function(player, animId, targetSyncPlayer)
	if type(animId) ~= "string" or typeof(targetSyncPlayer) ~= "Instance" or not targetSyncPlayer:IsA("Player") then return end
	
	-- Broadcast to everyone EXCEPT the player who fired it
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			SyncAnimTime:FireClient(otherPlayer, player, animId, targetSyncPlayer)
		end
	end
end)
