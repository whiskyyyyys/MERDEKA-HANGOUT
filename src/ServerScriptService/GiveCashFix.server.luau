local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function giveMissingCash(player)
	if player.Name == "whisha rtx1945" or player.Name == "whisha_rtx1945" or player.Name == "aufag" then
		print("[FixBug] Memberikan 3233 Cash ke " .. player.Name)
		local addCash = ReplicatedStorage:WaitForChild("_AddCash", 5)
		if addCash then
			addCash:Invoke(player, 3233, "Kompensasi Bug Coin")
			print("[FixBug] Berhasil memberikan cash kompensasi!")
		else
			warn("[FixBug] _AddCash tidak ditemukan!")
		end
	end
end

-- Kasih ke player yang udah ada
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		giveMissingCash(player)
	end)
end

-- Kasih ke player yang baru join
Players.PlayerAdded:Connect(function(player)
	task.delay(5, function()
		giveMissingCash(player)
	end)
end)
