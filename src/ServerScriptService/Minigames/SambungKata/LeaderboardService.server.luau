-- ============================================================
-- LeaderboardService.server.lua
-- Global leaderboard wins + losses
-- ============================================================

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Modules")
local Config = require(Modules:WaitForChild("GameConfig"))

local Remotes = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Remotes")
local LeaderboardUpdate = Remotes:WaitForChild("LeaderboardUpdate")
local LossLeaderboardUpdate = Remotes:WaitForChild("LossLeaderboardUpdate")

local winsBoard   = DataStoreService:GetOrderedDataStore("GlobalWins_v6")
local lossesBoard = DataStoreService:GetOrderedDataStore("GlobalLosses_v6")

local BLACKLISTED_IDS = {
	[9237231865] = true,
	[8380162171] = true,
}

local REFRESH_INTERVAL = 30
local TOP_COUNT = 100
local DISPLAY_COUNT = 50

local topWinsCache = {}
local topLossesCache = {}
local rankLookup = {}

local function findBoardPart(name)
	return workspace:FindFirstChild(name, true)
end

local function ensureLossBoardPart()
	local winsPart = findBoardPart("LeaderboardPart")
	if not winsPart or not winsPart:IsA("BasePart") then
		return
	end
	if findBoardPart("LeaderboardJawaPalsuPart") then
		return
	end

	local clone = winsPart:Clone()
	clone.Name = "LeaderboardJawaPalsuPart"
	clone.CFrame = winsPart.CFrame + winsPart.CFrame.RightVector * (winsPart.Size.X + 6)
	clone.Parent = winsPart.Parent

	local oldGui = clone:FindFirstChild("LeaderboardSurfaceGui")
	if oldGui then
		oldGui:Destroy()
	end

end

local function updateOrderedValue(store, userId, value, label)
	local success, err = pcall(function()
		store:SetAsync(tostring(userId), value)
	end)
	if not success then
		warn("[LeaderboardService] Gagal update " .. label .. " untuk "
			.. tostring(userId) .. ": " .. tostring(err))
	end
end

local function getDisplayName(userId)
	local displayName = "Player"
	local success, info = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	if success and info then
		displayName = info
	end

	local onlinePlayer = Players:GetPlayerByUserId(userId)
	if onlinePlayer then
		displayName = onlinePlayer.DisplayName or onlinePlayer.Name
	end

	return displayName
end

local function fetchTopData(store, statKey)
	local success, pages = pcall(function()
		return store:GetSortedAsync(false, TOP_COUNT)
	end)
	if not success or not pages then
		warn("[LeaderboardService] Gagal fetch " .. statKey .. ": " .. tostring(pages))
		return {}
	end

	local newTop = {}
	local newLookup = {}
	local rank = 0

	for _, entry in ipairs(pages:GetCurrentPage()) do
		local userId = tonumber(entry.key) or 0
		local value = entry.value or 0

		if BLACKLISTED_IDS[userId] then
			continue
		end

		rank = rank + 1
		local row = {
			userId = userId,
			name = getDisplayName(userId),
			rank = rank,
			value = value,
		}
		row[statKey] = value
		table.insert(newTop, row)
		newLookup[userId] = rank

		if rank >= DISPLAY_COUNT then
			break
		end
	end

	return newTop, newLookup
end

local function cloneTopData(source)
	local sendData = {}
	for i = 1, math.min(#source, DISPLAY_COUNT) do
		sendData[i] = source[i]
	end
	return sendData
end

local function updatePodiums()
	task.spawn(function()
		local sambungKata = workspace:FindFirstChild("SambungKata")
		if not sambungKata then 
			print("[Podium] Model 'SambungKata' tidak ditemukan di Workspace!")
			return 
		end
		
		local function spawnOnAltar(userId, altarPart, dummyName, animId)
			if not altarPart then 
				print("[Podium] Part 'Altar' tidak ditemukan untuk", dummyName)
				return 
			end
			
			-- Cek apakah player yang sama sudah ada di podium
			local existing = altarPart:FindFirstChild(dummyName)
			if existing and existing:GetAttribute("UserId") == userId then
				return -- Tidak perlu load ulang
			end
			
			print("[Podium] Mendownload avatar untuk UserId:", userId)
			-- Download avatar player
			local success, model = pcall(function()
				return Players:CreateHumanoidModelFromUserId(userId)
			end)
			
			if success and model then
				model.Name = dummyName
				model:SetAttribute("UserId", userId)
				
				-- Hapus yang lama
				if existing then existing:Destroy() end
				
				-- Hilangkan tulisan nama di atas kepalanya
				local humanoid = model:FindFirstChildWhichIsA("Humanoid")
				if humanoid then
					humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				end
				
				-- Posisikan di atas Altar (Menghadap searah dengan Altar, sudah dirotasi 180 dari sebelumnya)
				local offset = (altarPart.Size.Y / 2) + 2.5
				model:SetPrimaryPartCFrame(altarPart.CFrame * CFrame.new(0, offset, 0))
				
				-- Kunci HANYA HumanoidRootPart agar kepala dan sendi (Motor6D) tidak copot/terlepas
				for _, part in ipairs(model:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
						if part.Name == "HumanoidRootPart" then
							part.Anchored = true
						end
					end
				end
				
				model.Parent = altarPart
				print("[Podium] Berhasil memajang avatar", dummyName, "di Altar!")
				
				if animId and humanoid then
					local animator = humanoid:FindFirstChildOfClass("Animator")
					if not animator then
						animator = Instance.new("Animator")
						animator.Parent = humanoid
					end
					
					local animation = Instance.new("Animation")
					animation.AnimationId = "rbxassetid://" .. animId
					
					local animTrack = animator:LoadAnimation(animation)
					animTrack.Looped = true
					animTrack:Play()
				end
			else
				warn("[Podium] Gagal mendownload avatar UserId:", userId)
			end
		end
		
		-- Spawn Top 1 Win (Gunakan ID 1 / Roblox sebagai contoh jika data kosong)
		local podiumWins = sambungKata:FindFirstChild("PodiumWins")
		if podiumWins then
			local altarWins = podiumWins:FindFirstChild("Altar", true) -- cari ke dalam group jika ada
			local winId = (topWinsCache[1] and topWinsCache[1].userId) or 1
			print("[Podium] Mencoba spawn Top 1 Win di PodiumWins")
			spawnOnAltar(winId, altarWins, "Top1_Win", "127528880902667")
		else
			print("[Podium] Model 'PodiumWins' tidak ditemukan di dalam SambungKata!")
		end
		
		-- Spawn Top 1 Lose (Gunakan ID 156 / Builderman sebagai contoh jika data kosong)
		local podiumLose = sambungKata:FindFirstChild("PodiumLose")
		if podiumLose then
			local altarLose = podiumLose:FindFirstChild("Altar", true) -- cari ke dalam group jika ada
			local loseId = (topLossesCache[1] and topLossesCache[1].userId) or 156
			print("[Podium] Mencoba spawn Top 1 Lose di PodiumLose")
			spawnOnAltar(loseId, altarLose, "Top1_Lose", "140694108746068")
		else
			print("[Podium] Model 'PodiumLose' tidak ditemukan di dalam SambungKata!")
		end
	end)
end

local function refreshLeaderboards()
	topWinsCache, rankLookup = fetchTopData(winsBoard, "wins")
	topLossesCache = fetchTopData(lossesBoard, "losses")

	LeaderboardUpdate:FireAllClients(cloneTopData(topWinsCache))
	LossLeaderboardUpdate:FireAllClients(cloneTopData(topLossesCache))
	
	-- Update Avatar Podium
	updatePodiums()
end

task.spawn(function()
	task.wait(2)
	ensureLossBoardPart()
end)

task.spawn(function()
	task.wait(5)
	while true do
		refreshLeaderboards()
		task.wait(REFRESH_INTERVAL)
	end
end)

Players.PlayerAdded:Connect(function(player)
	task.wait(3)
	if #topWinsCache > 0 then
		pcall(function()
			LeaderboardUpdate:FireClient(player, cloneTopData(topWinsCache))
		end)
	end
	if #topLossesCache > 0 then
		pcall(function()
			LossLeaderboardUpdate:FireClient(player, cloneTopData(topLossesCache))
		end)
	end
end)

local getRankFunc = Instance.new("BindableFunction")
getRankFunc.Name = "_GetGlobalRank"
getRankFunc.Parent = ReplicatedStorage
getRankFunc.OnInvoke = function(userId)
	if not userId then return 0 end
	return rankLookup[userId] or 0
end

local updateWinsFunc = Instance.new("BindableFunction")
updateWinsFunc.Name = "_UpdateGlobalWins"
updateWinsFunc.Parent = ReplicatedStorage
updateWinsFunc.OnInvoke = function(userId, totalWins)
	if not userId or totalWins == nil then return false end
	updateOrderedValue(winsBoard, userId, totalWins, "wins")
	return true
end

local updateLossesFunc = Instance.new("BindableFunction")
updateLossesFunc.Name = "_UpdateGlobalLosses"
updateLossesFunc.Parent = ReplicatedStorage
updateLossesFunc.OnInvoke = function(userId, totalLosses)
	if not userId or totalLosses == nil then return false end
	updateOrderedValue(lossesBoard, userId, totalLosses, "losses")
	return true
end

-- ── Force Refresh: dipanggil AdminService setelah resetstats all ──
-- Langsung kosongkan cache & broadcast kosong ke semua client
-- TIDAK auto-refetch — biarkan timer 30s yang handle agar DataStore
-- tidak conflict dengan proses wipe yang sedang berjalan.
local forceRefreshEvent = Instance.new("BindableEvent")
forceRefreshEvent.Name = "_ForceRefreshLeaderboard"
forceRefreshEvent.Parent = ReplicatedStorage
forceRefreshEvent.Event:Connect(function()
	topWinsCache   = {}
	topLossesCache = {}
	rankLookup     = {}
	LeaderboardUpdate:FireAllClients({})
	LossLeaderboardUpdate:FireAllClients({})
end)

task.spawn(function()
	task.wait(3)
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("StatsData")
		if leaderstats then
			local wins = leaderstats:FindFirstChild("Wins")
			local losses = leaderstats:FindFirstChild("Losses")
			if wins and wins.Value > 0 then
				updateOrderedValue(winsBoard, player.UserId, wins.Value, "wins")
			end
			if losses and losses.Value > 0 then
				updateOrderedValue(lossesBoard, player.UserId, losses.Value, "losses")
			end
		end
	end
end)