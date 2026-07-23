-- ============================================================
-- LeaderboardService.server.luau (Masukan Paku)
-- Mengurus DataStore untuk Wins dan Losses Masukan Paku
-- Beserta integrasi ke model PodiumWins dan PodiumLose di Arena
-- ============================================================

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- ═══════════════════════════════════════════════════════════
-- SETUP EVENTS
-- ═══════════════════════════════════════════════════════════
local RSMinigames = ReplicatedStorage:FindFirstChild("Minigames")
if not RSMinigames then
	RSMinigames = Instance.new("Folder")
	RSMinigames.Name = "Minigames"
	RSMinigames.Parent = ReplicatedStorage
end

local MasukanPakuFolder = RSMinigames:FindFirstChild("MasukanPaku")
if not MasukanPakuFolder then
	MasukanPakuFolder = Instance.new("Folder")
	MasukanPakuFolder.Name = "MasukanPaku"
	MasukanPakuFolder.Parent = RSMinigames
end

local EventsFolder = MasukanPakuFolder:FindFirstChild("Events")
if not EventsFolder then
	EventsFolder = Instance.new("Folder")
	EventsFolder.Name = "Events"
	EventsFolder.Parent = MasukanPakuFolder
end

local function getOrCreateEvent(className, name)
	local event = EventsFolder:FindFirstChild(name)
	if not event then
		event = Instance.new(className)
		event.Name = name
		event.Parent = EventsFolder
	end
	return event
end

local LeaderboardUpdate = getOrCreateEvent("RemoteEvent", "LeaderboardUpdate")
local LossLeaderboardUpdate = getOrCreateEvent("RemoteEvent", "LossLeaderboardUpdate")

-- ═══════════════════════════════════════════════════════════
-- DATASTORES & CONFIG
-- ═══════════════════════════════════════════════════════════
local winsBoard = DataStoreService:GetOrderedDataStore("MasukanPakuWins_v1")
local lossesBoard = DataStoreService:GetOrderedDataStore("MasukanPakuLosses_v1")

local REFRESH_INTERVAL = 30
local TOP_COUNT = 100
local DISPLAY_COUNT = 50

local topWinsCache = {}
local topLossesCache = {}

local BLACKLISTED_IDS = {
	[9237231865] = true,
	[8380162171] = true,
}

-- ═══════════════════════════════════════════════════════════
-- DATA FETCHING
-- ═══════════════════════════════════════════════════════════
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
		warn("[MasukanPakuLB] Gagal fetch " .. statKey .. ": " .. tostring(pages))
		return {}
	end

	local newTop = {}
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

		if rank >= DISPLAY_COUNT then break end
	end
	return newTop
end

local function cloneTopData(source)
	local sendData = {}
	for i = 1, math.min(#source, DISPLAY_COUNT) do
		sendData[i] = source[i]
	end
	return sendData
end

-- ═══════════════════════════════════════════════════════════
-- PODIUM AVATAR SYSTEM
-- ═══════════════════════════════════════════════════════════
local function updatePodiums()
	task.spawn(function()
		local arena = workspace:FindFirstChild("MasukanPakuArena")
		if not arena then 
			print("[MasukanPaku Podium] Model 'MasukanPakuArena' tidak ditemukan di Workspace!")
			return 
		end
		
		local function spawnOnAltar(userId, altarPart, dummyName, animId)
			if not altarPart then 
				print("[MasukanPaku Podium] Part 'Altar' tidak ditemukan untuk", dummyName)
				return 
			end
			
			local existing = altarPart:FindFirstChild(dummyName)
			if existing and existing:GetAttribute("UserId") == userId then
				return 
			end
			
			print("[MasukanPaku Podium] Mendownload avatar untuk UserId:", userId)
			local success, model = pcall(function()
				return Players:CreateHumanoidModelFromUserId(userId)
			end)
			
			if success and model then
				model.Name = dummyName
				model:SetAttribute("UserId", userId)
				
				if existing then existing:Destroy() end
				
				local humanoid = model:FindFirstChildWhichIsA("Humanoid")
				if humanoid then
					humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
				end
				
				local offset = (altarPart.Size.Y / 2) + 2.5
				model:SetPrimaryPartCFrame(altarPart.CFrame * CFrame.new(0, offset, 0))
				
				for _, part in ipairs(model:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
						if part.Name == "HumanoidRootPart" then
							part.Anchored = true
						end
					end
				end
				
				model.Parent = altarPart
				print("[MasukanPaku Podium] Berhasil memajang avatar", dummyName, "di Altar!")
				
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
				warn("[MasukanPaku Podium] Gagal mendownload avatar UserId:", userId)
			end
		end
		
		local podiumWins = arena:FindFirstChild("PodiumWins")
		if podiumWins then
			local altarWins = podiumWins:FindFirstChild("Altar", true)
			local winId = (topWinsCache[1] and topWinsCache[1].userId) or 1
			print("[MasukanPaku Podium] Mencoba spawn Top 1 Win di PodiumWins")
			spawnOnAltar(winId, altarWins, "Top1_Win", "127528880902667")
		else
			print("[MasukanPaku Podium] Model 'PodiumWins' tidak ditemukan di dalam MasukanPakuArena!")
		end
		
		local podiumLose = arena:FindFirstChild("PodiumLose")
		if podiumLose then
			local altarLose = podiumLose:FindFirstChild("Altar", true)
			local loseId = (topLossesCache[1] and topLossesCache[1].userId) or 156
			print("[MasukanPaku Podium] Mencoba spawn Top 1 Lose di PodiumLose")
			spawnOnAltar(loseId, altarLose, "Top1_Lose", "140694108746068")
		else
			print("[MasukanPaku Podium] Model 'PodiumLose' tidak ditemukan di dalam MasukanPakuArena!")
		end
	end)
end

-- ═══════════════════════════════════════════════════════════
-- LEADERBOARD REFRESHER
-- ═══════════════════════════════════════════════════════════
local function refreshLeaderboards()
	topWinsCache = fetchTopData(winsBoard, "wins")
	topLossesCache = fetchTopData(lossesBoard, "losses")

	LeaderboardUpdate:FireAllClients(cloneTopData(topWinsCache))
	LossLeaderboardUpdate:FireAllClients(cloneTopData(topLossesCache))
	
	updatePodiums()
end

-- ═══════════════════════════════════════════════════════════
-- API BINDABLES UNTUK UPDATE
-- ═══════════════════════════════════════════════════════════
local updateWinsFunc = Instance.new("BindableFunction")
updateWinsFunc.Name = "_MasukanPakuUpdateWins"
updateWinsFunc.Parent = ReplicatedStorage
updateWinsFunc.OnInvoke = function(userId, amount)
	pcall(function()
		winsBoard:IncrementAsync(tostring(userId), amount)
	end)
	return true
end

local updateLossesFunc = Instance.new("BindableFunction")
updateLossesFunc.Name = "_MasukanPakuUpdateLosses"
updateLossesFunc.Parent = ReplicatedStorage
updateLossesFunc.OnInvoke = function(userId, amount)
	pcall(function()
		lossesBoard:IncrementAsync(tostring(userId), amount)
	end)
	return true
end

-- ═══════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════
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

print("[MasukanPaku] Leaderboard Service Aktif!")
