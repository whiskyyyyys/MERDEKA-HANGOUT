local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GlobalAnnouncementEvent = ReplicatedStorage:FindFirstChild("GlobalAnnouncementEvent")
if not GlobalAnnouncementEvent then
	GlobalAnnouncementEvent = Instance.new("RemoteEvent")
	GlobalAnnouncementEvent.Name = "GlobalAnnouncementEvent"
	GlobalAnnouncementEvent.Parent = ReplicatedStorage
end

-- ============================================================
-- KONFIGURASI PENGUMUMAN
-- ============================================================
local intervalSeconds = 300 -- Muncul setiap 300 detik (5 Menit)

local messages = {
	"Selamat datang di Merdeka Hangout! Jangan lupa bergabung dengan grup kami ya.",
	"Ayo coba mainkan minigame Sambung Kata bersama teman-temanmu!",
	"Ingin mendukung kami? Jangan lupa berikan Like & Favorite pada game ini!",
	"Jadilah pemain yang sopan dan saling menghargai pemain lainnya.",
	"Punya kritik atau saran? Sampaikan di server komunitas kami!"
}

-- ============================================================
-- FUNGSI
-- ============================================================
local function broadcastRandomMessage()
	local msg = messages[math.random(1, #messages)]
	GlobalAnnouncementEvent:FireAllClients({
		displayName = "SERVER",
		prefix = "",
		message = msg,
		nameColor = Color3.fromRGB(255, 215, 0) -- Warna Emas
	})
end

-- Loop otomatis
task.spawn(function()
	while true do
		task.wait(intervalSeconds)
		broadcastRandomMessage()
	end
end)

-- Kirim ke player yang baru join
Players.PlayerAdded:Connect(function(player)
	task.wait(5)
	if player.Parent then
		local welcomeMsg = "Selamat datang " .. player.DisplayName .. " di Merdeka Hangout! Selamat bermain!"
		GlobalAnnouncementEvent:FireClient(player, {
			message = welcomeMsg,
			isChatOnly = true
		})
	end
end)

print("[AutoAnnouncement] Sistem pengumuman server aktif!")
