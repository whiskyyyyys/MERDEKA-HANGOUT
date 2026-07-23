local DataStoreService = game:GetService("DataStoreService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PositionStore = DataStoreService:GetDataStore("PlayerSavedPosition_V1")

local RejoinRemote = ReplicatedStorage:FindFirstChild("AFKRejoin")
if not RejoinRemote then
	RejoinRemote = Instance.new("RemoteEvent")
	RejoinRemote.Name = "AFKRejoin"
	RejoinRemote.Parent = ReplicatedStorage
end

local MAX_OFFLINE_TIME = 3600 
local savingPlayers = {}

-- Tabel memori untuk menyimpan posisi dan status load
local lastValidPositions = {}
local hasLoadedPos = {}

-- ==========================================
-- LOOP PEREKAM POSISI REAL-TIME
-- ==========================================
-- Mencatat posisi semua pemain setiap 2 detik ke dalam memori server.
-- Jika pemain tiba-tiba disconnect dan karakternya hilang, kita tetap punya data posisi terakhirnya.
task.spawn(function()
	while task.wait(2) do
		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			if char then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					lastValidPositions[player.UserId] = {root.CFrame:components()}
				end
			end
		end
	end
end)

-- ==========================================
-- FUNGSI SIMPAN POSISI
-- ==========================================
local function savePlayerPosition(player)
	if savingPlayers[player.UserId] then return end
	savingPlayers[player.UserId] = true

	-- Ambil koordinat dari memori loop, bukan dari Karakter yang mungkin sudah hancur
	local savedCFrame = lastValidPositions[player.UserId]

	if savedCFrame then
		local data = {
			CFrame = savedCFrame,
			Time = os.time()
		}
		local success, err = pcall(function()
			PositionStore:SetAsync(tostring(player.UserId), data)
		end)
		if not success then
			warn("Gagal menyimpan posisi untuk " .. player.Name .. ": " .. tostring(err))
		end
	end
	savingPlayers[player.UserId] = nil
end

-- ==========================================
-- EVENT SAAT PEMAIN MASUK
-- ==========================================
Players.PlayerAdded:Connect(function(player)
	-- Reset status load agar pemain bisa diteleportasi saat pertama kali masuk
	hasLoadedPos[player.UserId] = false

	local success, savedData = pcall(function()
		return PositionStore:GetAsync(tostring(player.UserId))
	end)

	if success and savedData then
		if os.time() - savedData.Time <= MAX_OFFLINE_TIME then
			player.CharacterAdded:Connect(function(char)
				-- PENTING: Pastikan teleportasi HANYA terjadi 1x (saat join). 
				-- Jika pemain mati/reset, mereka akan spawn di tempat normal.
				if not hasLoadedPos[player.UserId] then
					hasLoadedPos[player.UserId] = true

					local root = char:WaitForChild("HumanoidRootPart", 5)
					if root then
						task.wait(0.5) 
						local finalCFrame = CFrame.new(table.unpack(savedData.CFrame))
						char:PivotTo(finalCFrame)
					end
				end
			end)
		end
	end
end)

-- ==========================================
-- EVENT SAAT PEMAIN KELUAR / DISCONNECT
-- ==========================================
Players.PlayerRemoving:Connect(function(player)
	savePlayerPosition(player)

	-- Bersihkan memori agar tidak bocor (Memory Leak)
	lastValidPositions[player.UserId] = nil
	hasLoadedPos[player.UserId] = nil
end)

-- ==========================================
-- EVENT SAAT MENERIMA SINYAL AFK DARI CLIENT
-- ==========================================
RejoinRemote.OnServerEvent:Connect(function(player)
	savePlayerPosition(player)

	local success, err = pcall(function()
		TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end)

	if not success then
		TeleportService:Teleport(game.PlaceId, player)
	end
end)

-- ==========================================
-- PENGAMANAN DATA SAAT SERVER SHUTDOWN
-- ==========================================
game:BindToClose(function()
	if RunService:IsStudio() then return end 

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			savePlayerPosition(player)
		end)
	end

	task.wait(3)
end)