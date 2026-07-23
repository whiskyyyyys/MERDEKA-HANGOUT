-- ScissorsSoundServer (Script di ServerScriptService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundRemote = ReplicatedStorage:WaitForChild("ScissorsSoundRemote")
local StopSoundRemote = ReplicatedStorage:WaitForChild("ScissorsStopSound")

local cooldowns = {}
local COOLDOWN = 2

-- Saat player equip Scissors
SoundRemote.OnServerEvent:Connect(function(player)
	local now = tick()
	if cooldowns[player] and now - cooldowns[player] < COOLDOWN then return end
	cooldowns[player] = now

	if not player.Character then return end
	local head = player.Character:FindFirstChild("Head")
	if not head then return end

	-- kirim sinyal ke semua client untuk mulai suara
	SoundRemote:FireAllClients(player)
end)

-- Saat player unequip Scissors
StopSoundRemote.OnServerEvent:Connect(function(player)
	StopSoundRemote:FireAllClients(player)
end)
