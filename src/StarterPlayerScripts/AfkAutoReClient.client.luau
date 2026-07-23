local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RejoinRemote = ReplicatedStorage:WaitForChild("AFKRejoin")

-- Atur waktu batas AFK menjadi 19 Menit (19 * 60 detik)
local AFK_LIMIT = 19 * 60 
local lastActivity = os.clock()

-- ==========================================
-- FUNGSI RESET WAKTU AFK
-- ==========================================
local function updateActivity()
	lastActivity = os.clock()
end

-- Deteksi sentuhan, gerakan mouse, dan ketikan keyboard
UserInputService.InputBegan:Connect(updateActivity)
UserInputService.InputChanged:Connect(updateActivity)

-- ==========================================
-- LOOPING PENGECEKAN AFK (SANGAT RINGAN)
-- ==========================================
while task.wait(10) do
	if os.clock() - lastActivity >= AFK_LIMIT then

		-- Kirim sinyal ke Server Script untuk meminta Rejoin
		RejoinRemote:FireServer()

		-- Jeda 15 detik agar sinyal tidak di-spam berulang kali saat proses teleportasi sedang berjalan
		task.wait(15) 
	end
end