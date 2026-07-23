-- ============================================================
-- MasukanPakuManager.server.luau
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("[MasukanPaku] ========== MasukanPakuManager DIMULAI ==========")

-- 1. Setup ReplicatedStorage Events
local minigamesFolder = ReplicatedStorage:FindFirstChild("Minigames")
if not minigamesFolder then
	minigamesFolder = Instance.new("Folder")
	minigamesFolder.Name = "Minigames"
	minigamesFolder.Parent = ReplicatedStorage
end

local masukanPakuFolder = minigamesFolder:FindFirstChild("MasukanPaku")
if not masukanPakuFolder then
	masukanPakuFolder = Instance.new("Folder")
	masukanPakuFolder.Name = "MasukanPaku"
	masukanPakuFolder.Parent = minigamesFolder
end

local eventsFolder = masukanPakuFolder:FindFirstChild("Events")
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "Events"
	eventsFolder.Parent = masukanPakuFolder
end

-- BindableEvent untuk dipanggil PadManagers
local startGameBindable = eventsFolder:FindFirstChild("StartGame")
if not startGameBindable then
	startGameBindable = Instance.new("BindableEvent")
	startGameBindable.Name = "StartGame"
	startGameBindable.Parent = eventsFolder
end

-- RemoteEvents untuk komunikasi Client-Server
local function getOrCreateRemote(name)
	local remote = eventsFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = eventsFolder
	end
	return remote
end

local gameStartEvent = getOrCreateRemote("GameStartEvent")
local claimWinEvent = getOrCreateRemote("ClaimWinEvent")
local gameEndEvent = getOrCreateRemote("GameEndEvent")

-- API CashService
local addCash = ReplicatedStorage:WaitForChild("_AddCash", 5)

local isGameRunning = false
local activePlayers = {}

-- ============================================================
-- GAME LOOP
-- ============================================================

startGameBindable.Event:Connect(function(...)
	if isGameRunning then return end
	
	local args = {...}
	local playersToPlay = {}
	
	-- PadManagers passes table of tables (each pad is an array of players)
	for _, padGroup in ipairs(args) do
		for _, player in ipairs(padGroup) do
			if player and player.Parent then
				table.insert(playersToPlay, player)
			end
		end
	end
	
	if #playersToPlay == 0 then return end
	
	print("[MasukanPaku] Memulai game dengan " .. #playersToPlay .. " pemain.")
	isGameRunning = true
	activePlayers = {}
	
	-- Cari Arena yang benar-benar memiliki folder Spawns (mencegah error kalau ada duplikat model)
	local arena = nil
	for _, child in ipairs(workspace:GetDescendants()) do
		if (child.Name == "MasukanPakuArena" or child.Name == "MasukanPaku Arena") and child:IsA("Model") then
			if child:FindFirstChild("Spawns") or child:FindFirstChild("Spawn") or child:FindFirstChild("spawns") or child:FindFirstChild("spawn") then
				arena = child
				break
			end
		end
	end
	
	if not arena then
		-- Fallback jika ga ketemu yang punya Spawns
		arena = workspace:FindFirstChild("MasukanPakuArena") or workspace:FindFirstChild("MasukanPaku Arena")
		if not arena then
			warn("[MasukanPaku] Arena 'MasukanPakuArena' tidak ditemukan di Workspace!")
		end
	end
	
	-- Cari Folder Spawns di Arena (Toleransi nama folder)
	local spawnsFolder = arena and (arena:FindFirstChild("Spawns") or arena:FindFirstChild("Spawn") or arena:FindFirstChild("spawns") or arena:FindFirstChild("spawn"))
	local spawnPoints = {}
	if spawnsFolder then
		spawnPoints = spawnsFolder:GetChildren()
		-- Sort by name (Spawn1, Spawn2, dll)
		table.sort(spawnPoints, function(a, b)
			return a.Name < b.Name
		end)
	else
		warn("[MasukanPaku] Folder Spawn tidak ditemukan di Arena!")
	end
	
	-- Persiapan Pemain
	for i, player in ipairs(playersToPlay) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
			-- Lepaskan dari Seat (Pad) jika sedang duduk agar teleport tidak nyangkut!
			char.Humanoid.Sit = false
		end
	end
	
	-- Tunggu satu frame agar sistem fisika Roblox memutus SeatWeld
	task.wait()
	
	for i, player in ipairs(playersToPlay) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
			-- Teleport ke Spawn jika ada
			if spawnsFolder and #spawnPoints > 0 then
				local spawnPart = spawnPoints[i] or spawnPoints[1] -- Gunakan spawn ke-i, atau default ke 1
				-- Gunakan PivotTo agar seluruh bagian tubuh ikut terteleportasi (lebih aman dari CFrame biasa)
				char:PivotTo(spawnPart.CFrame * CFrame.new(0, 3, 0))
			end
			
			-- Bikin mereka menghadap ke depan (opsional)
			activePlayers[player] = true
			
			-- Fire Event ke Client
			gameStartEvent:FireClient(player)
		end
	end
	
	if arena then
		arena:SetAttribute("IsPlaying", true)
	end
	
	-- Timeout jika ga ada yang menang dalam 2 menit
	task.delay(120, function()
		if isGameRunning then
			print("[MasukanPaku] Waktu habis, game seri.")
			endGame(nil)
		end
	end)
end)

claimWinEvent.OnServerEvent:Connect(function(player)
	if not isGameRunning or not activePlayers[player] then return end
	
	print("[MasukanPaku] " .. player.Name .. " MENANG!")
	endGame(player)
end)

function endGame(winner)
	isGameRunning = false
	
	local playersToTeleport = {}
	
	-- Fire End Event to Clients
	for p, _ in pairs(activePlayers) do
		if p and p.Parent then
			table.insert(playersToTeleport, p)
			gameEndEvent:FireClient(p, winner)
			
			-- Beri Cash jika menang
			if p == winner then
				local reward = 50
				local addSpins = ReplicatedStorage:FindFirstChild("_AddSpins")
				if addCash then
					pcall(function() addCash:Invoke(p, reward, "Masukan Paku Juara") end)
				end
				if addSpins then
					pcall(function() addSpins:Invoke(p, 1) end)
					print("[MasukanPaku] " .. p.Name .. " mendapat 1 Spin Ticket!")
				end
				-- Update Leaderboard Wins
				pcall(function()
					_G._MasukanPakuUpdateWins(p.UserId, 1)
				end)
			else
				-- Update Leaderboard Losses
				pcall(function()
					_G._MasukanPakuUpdateLosses(p.UserId, 1)
				end)
			end
		end
	end
	
	activePlayers = {}
	
	-- Buka kunci Arena
	local arena = workspace:FindFirstChild("MasukanPakuArena") or workspace:FindFirstChild("MasukanPaku Arena")
	if arena then
		arena:SetAttribute("IsPlaying", false)
	end
	print("[MasukanPaku] Game selesai, arena dibuka.")
	
	-- Tunggu 5 detik lalu teleport ke endgame
	task.delay(5, function()
		if arena then
			local outPart = arena:FindFirstChild("endgame")
			if not outPart then
				outPart = Instance.new("Part")
				outPart.Name = "endgame"
				outPart.Transparency = 1
				outPart.CanCollide = false
				outPart.Anchored = true
				outPart.Position = arena:GetPivot().Position + Vector3.new(0, 10, 0)
				outPart.Parent = arena
				print("[MasukanPaku] Membuat part 'endgame' otomatis.")
			end
			
			for i, p in ipairs(playersToTeleport) do
				if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and outPart then
					p.Character:PivotTo(outPart.CFrame * CFrame.new((i-1)*4, 3, 0))
				end
			end
		end
	end)
end

-- ============================================================
-- GLOBAL EXPORTS UNTUK LEADERBOARD
-- ============================================================
-- _G._MasukanPakuUpdateWins di-setup di LeaderboardService

print("[MasukanPaku] MasukanPakuManager siap!")
