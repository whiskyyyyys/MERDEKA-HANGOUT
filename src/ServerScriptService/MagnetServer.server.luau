-- Script
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remote = ReplicatedStorage:FindFirstChild("MagnetRemote")
if not Remote then
	Remote = Instance.new("RemoteEvent")
	Remote.Name = "MagnetRemote"
	Remote.Parent = ReplicatedStorage
end

local activePlayers = {}

Remote.OnServerEvent:Connect(function(player, isActive)
	if isActive then
		activePlayers[player] = true
	else
		activePlayers[player] = nil
	end
end)

RunService.Heartbeat:Connect(function()
	for magnetPlayer, _ in pairs(activePlayers) do
		if magnetPlayer.Character and magnetPlayer.Character:FindFirstChild("Head") then
			local magnetHead = magnetPlayer.Character.Head
			for _, otherPlayer in pairs(Players:GetPlayers()) do
				if otherPlayer ~= magnetPlayer and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = otherPlayer.Character.HumanoidRootPart
					local dist = (hrp.Position - magnetHead.Position).Magnitude
					if dist < 25 then -- radius magnet
						local direction = (magnetHead.Position - hrp.Position).Unit
						local pullStrength = math.clamp(25 - dist, 0, 25) * 0.8 -- lebih cepat dari versi lama (0.15 → 0.5)
						-- tambah sedikit smooth agar target tidak meloncat
						hrp.Velocity = Vector3.new(direction.X, 0, direction.Z) * pullStrength + Vector3.new(0, hrp.Velocity.Y, 0)
					end
				end
			end
		end
	end
end)
