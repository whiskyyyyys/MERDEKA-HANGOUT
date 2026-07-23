-- ============================================================
-- TambangManager.server.luau
-- Mengatur arena, tali di pemain, logika menang, dan teleport EndGame
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- ═══════════════════════════════════════════════════════════
-- KONFIGURASI
-- ═══════════════════════════════════════════════════════════
local ROPE_RADIUS = 0.12
local ROPE_COLOR = Color3.fromRGB(194, 158, 100)
local ROPE_MATERIAL = Enum.Material.Fabric
local WIN_THRESHOLD = 25 -- Harus jauh (25 poin) baru menang

-- ═══════════════════════════════════════════════════════════
-- SETUP FOLDER & EVENTS
-- ═══════════════════════════════════════════════════════════
local RSMinigames = ReplicatedStorage:FindFirstChild("Minigames") or Instance.new("Folder", ReplicatedStorage)
RSMinigames.Name = "Minigames"

local TambangFolder = RSMinigames:FindFirstChild("TarikTambang") or Instance.new("Folder", RSMinigames)
TambangFolder.Name = "TarikTambang"

local EventsFolder = TambangFolder:FindFirstChild("Events") or Instance.new("Folder", TambangFolder)
EventsFolder.Name = "Events"

local function getOrCreateEvent(className, name)
	local event = EventsFolder:FindFirstChild(name)
	if not event then
		event = Instance.new(className)
		event.Name = name
		event.Parent = EventsFolder
	end
	return event
end

local StartGameBindable = getOrCreateEvent("BindableEvent", "StartGame")
local ShowUIEvent = getOrCreateEvent("RemoteEvent", "ShowUI")
local HideUIEvent = getOrCreateEvent("RemoteEvent", "HideUI")
local PullEvent = getOrCreateEvent("RemoteEvent", "PullEvent")
local GameEndEvent = getOrCreateEvent("RemoteEvent", "GameEndEvent")
local ScoreUpdateEvent = getOrCreateEvent("RemoteEvent", "ScoreUpdate")

-- ═══════════════════════════════════════════════════════════
-- AUTO-BUILD ARENA
-- ═══════════════════════════════════════════════════════════
local Arena = workspace:FindFirstChild("TarikTambangArena")
local CenterLine, TeamRedSpawns, TeamWhiteSpawns, EndGameSpawn

if not Arena then
	Arena = Instance.new("Model")
	Arena.Name = "TarikTambangArena"
	Arena.Parent = workspace
	print("[Tambang] Membangun arena otomatis...")
end

-- Garis Tengah
CenterLine = Arena:FindFirstChild("CenterLine")
if not CenterLine then
	CenterLine = Instance.new("Part")
	CenterLine.Name = "CenterLine"
	CenterLine.Size = Vector3.new(30, 0.5, 5)
	CenterLine.Position = Vector3.new(0, 0.25, 100)
	CenterLine.Anchored = true
	CenterLine.Color = Color3.fromRGB(139, 69, 19)
	CenterLine.Material = Enum.Material.Mud
	CenterLine.Parent = Arena
end

-- Spawn Tim Merah
TeamRedSpawns = Arena:FindFirstChild("RedSpawns")
if not TeamRedSpawns then
	TeamRedSpawns = Instance.new("Folder")
	TeamRedSpawns.Name = "RedSpawns"
	TeamRedSpawns.Parent = Arena
	for i = 1, 5 do
		local s = Instance.new("Part")
		s.Name = "Spawn" .. i
		s.Size = Vector3.new(4, 0.5, 4)
		s.Position = CenterLine.Position + Vector3.new(0, 0.25, i * -4 - 3)
		s.Anchored = true
		s.CanCollide = false
		s.Transparency = 0.5
		s.Color = Color3.fromRGB(255, 0, 0)
		s.Parent = TeamRedSpawns
	end
end

-- Spawn Tim Putih
TeamWhiteSpawns = Arena:FindFirstChild("WhiteSpawns")
if not TeamWhiteSpawns then
	TeamWhiteSpawns = Instance.new("Folder")
	TeamWhiteSpawns.Name = "WhiteSpawns"
	TeamWhiteSpawns.Parent = Arena
	for i = 1, 5 do
		local s = Instance.new("Part")
		s.Name = "Spawn" .. i
		s.Size = Vector3.new(4, 0.5, 4)
		s.Position = CenterLine.Position + Vector3.new(0, 0.25, i * 4 + 3)
		s.Anchored = true
		s.CanCollide = false
		s.Transparency = 0.5
		s.Color = Color3.fromRGB(255, 255, 255)
		s.Parent = TeamWhiteSpawns
	end
end

-- EndGame Spawn (tempat pemain dikirim setelah game selesai)
EndGameSpawn = Arena:FindFirstChild("EndGameSpawn")
if not EndGameSpawn then
	EndGameSpawn = Instance.new("Part")
	EndGameSpawn.Name = "EndGameSpawn"
	EndGameSpawn.Size = Vector3.new(20, 1, 20)
	EndGameSpawn.Position = CenterLine.Position + Vector3.new(0, 0.5, 40)
	EndGameSpawn.Anchored = true
	EndGameSpawn.CanCollide = true
	EndGameSpawn.Transparency = 0.7
	EndGameSpawn.Color = Color3.fromRGB(255, 215, 0)
	EndGameSpawn.Material = Enum.Material.Neon
	EndGameSpawn.Parent = Arena
end

-- ═══════════════════════════════════════════════════════════
-- GAME STATE
-- ═══════════════════════════════════════════════════════════
local isGameRunning = false
local ropePosition = 0 -- negatif = merah unggul, positif = putih unggul
local playersInGame = { Red = {}, White = {} }
local activeRopeModel = nil

-- ═══════════════════════════════════════════════════════════
-- FUNGSI TALI (di tangan pemain)
-- ═══════════════════════════════════════════════════════════
local function getHandPosition(character)
	local rh = character:FindFirstChild("RightHand")
	if rh then return rh.Position end
	local ra = character:FindFirstChild("Right Arm")
	if ra then return ra.Position + Vector3.new(0, -0.5, 0) end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then return hrp.Position + Vector3.new(0.5, 0, 0) end
	return nil
end

local function createRopeSegment(from, to, parent)
	local dist = (to - from).Magnitude
	local mid = (from + to) / 2
	local seg = Instance.new("Part")
	seg.Name = "RopeSegment"
	seg.Shape = Enum.PartType.Cylinder
	seg.Size = Vector3.new(dist, ROPE_RADIUS * 2, ROPE_RADIUS * 2)
	seg.CFrame = CFrame.lookAt(mid, to) * CFrame.Angles(0, math.rad(90), 0)
	seg.Anchored = true
	seg.CanCollide = false
	seg.Color = ROPE_COLOR
	seg.Material = ROPE_MATERIAL
	seg.Parent = parent
	return seg
end

local function getPlayerPoints()
	local points = {}
	for i = #playersInGame.Red, 1, -1 do
		local p = playersInGame.Red[i]
		if p.Character then
			local pos = getHandPosition(p.Character)
			if pos then table.insert(points, pos) end
		end
	end
	for i = 1, #playersInGame.White do
		local p = playersInGame.White[i]
		if p.Character then
			local pos = getHandPosition(p.Character)
			if pos then table.insert(points, pos) end
		end
	end
	return points
end

local function buildRope()
	if activeRopeModel then activeRopeModel:Destroy() end

	local ropeModel = Instance.new("Model")
	ropeModel.Name = "ActiveRope"
	ropeModel.Parent = Arena

	local points = getPlayerPoints()

	if #points >= 2 then
		for i = 1, #points - 1 do
			createRopeSegment(points[i], points[i + 1], ropeModel)
		end
	end

	-- Pita merah kecil di tengah
	if #points >= 2 then
		local midIdx = math.ceil(#points / 2)
		local midPos = (points[midIdx] + points[math.min(midIdx + 1, #points)]) / 2
		local marker = Instance.new("Part")
		marker.Name = "PitaTengah"
		marker.Shape = Enum.PartType.Ball
		marker.Size = Vector3.new(0.6, 0.6, 0.6)
		marker.Color = Color3.fromRGB(255, 0, 0)
		marker.Material = Enum.Material.Neon
		marker.Anchored = true
		marker.CanCollide = false
		marker.Position = midPos
		marker.Parent = ropeModel
	end

	activeRopeModel = ropeModel
end

local function updateRope()
	if not activeRopeModel then return end
	local points = getPlayerPoints()

	local segments = {}
	local marker = nil
	for _, child in ipairs(activeRopeModel:GetChildren()) do
		if child.Name == "RopeSegment" then
			table.insert(segments, child)
		elseif child.Name == "PitaTengah" then
			marker = child
		end
	end

	if #points >= 2 then
		for i = 1, #points - 1 do
			local seg = segments[i]
			if seg then
				local from, to = points[i], points[i + 1]
				local dist = (to - from).Magnitude
				local mid = (from + to) / 2
				seg.Size = Vector3.new(dist, ROPE_RADIUS * 2, ROPE_RADIUS * 2)
				seg.CFrame = CFrame.lookAt(mid, to) * CFrame.Angles(0, math.rad(90), 0)
			end
		end
		if marker then
			local midIdx = math.ceil(#points / 2)
			local baseMid = (points[midIdx] + points[math.min(midIdx + 1, #points)]) / 2
			-- Geser pita merah berdasarkan skor (ropePosition)
			-- Arah Z: negatif = merah unggul, positif = putih unggul
			local ropeDir = (points[#points] - points[1]).Unit
			marker.Position = baseMid + ropeDir * (ropePosition * 0.3)
		end
	end
end

local function destroyRope()
	if activeRopeModel then
		activeRopeModel:Destroy()
		activeRopeModel = nil
	end
end

-- ═══════════════════════════════════════════════════════════
-- KONTROL GAME
-- ═══════════════════════════════════════════════════════════
local function EndGame(winnerTeam)
	isGameRunning = false
	print("[Tambang] Game Selesai! Pemenang: Tim " .. winnerTeam)

	-- Kirim event kemenangan ke semua client (client akan tampilkan win screen)
	GameEndEvent:FireAllClients(winnerTeam)

	-- Bebaskan pemain dari Anchored dan Catat Wins/Losses
	local updateWins = ReplicatedStorage:FindFirstChild("_TambangUpdateWins")
	local updateLosses = ReplicatedStorage:FindFirstChild("_TambangUpdateLosses")

	for teamName, members in pairs(playersInGame) do
		-- Bandingkan nama tim (misal "Merah" dengan "Merah", atau "Red" dengan "Red")
		-- Sebelumnya kita simpan di playersInGame.Red dan playersInGame.White, 
		-- namun argumen winnerTeam adalah "Merah" atau "Putih".
		local tName = (teamName == "Red") and "Merah" or "Putih"
		local isWin = (string.lower(tName) == string.lower(winnerTeam))

		local addSpins = ReplicatedStorage:FindFirstChild("_AddSpins")
		for _, plr in ipairs(members) do
			-- 1. Catat ke DataStore via LeaderboardService
			if isWin and updateWins then
				task.spawn(function() updateWins:Invoke(plr.UserId, 1) end)
				if addSpins then
					pcall(function() addSpins:Invoke(plr, 1) end)
					print("[Tambang] " .. plr.Name .. " mendapat 1 Spin Ticket!")
				end
			elseif not isWin and updateLosses then
				task.spawn(function() updateLosses:Invoke(plr.UserId, 1) end)
			end

			-- 2. Update leaderstats lokal (jika ada)
			local stats = plr:FindFirstChild("StatsData")
			if stats then
				if isWin then
					local w = stats:FindFirstChild("Wins")
					if w then w.Value = w.Value + 1 end
				else
					local l = stats:FindFirstChild("Losses")
					if l then l.Value = l.Value + 1 end
				end
			end

			-- 3. Bebaskan pergerakan
			if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				plr.Character.HumanoidRootPart.Anchored = false
			end
		end
	end

	-- Hapus tali setelah 2 detik
	task.delay(2, destroyRope)

	-- Teleport semua pemain ke EndGameSpawn setelah 4 detik (setelah win screen hilang)
	task.delay(4, function()
		for _, members in pairs(playersInGame) do
			for _, plr in ipairs(members) do
				if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					local pos = EndGameSpawn.Position + Vector3.new(math.random(-5, 5), 3, math.random(-5, 5))
					plr.Character.HumanoidRootPart.CFrame = CFrame.new(pos)
				end
			end
		end
		ropePosition = 0
		playersInGame = { Red = {}, White = {} }
		
		if Arena then Arena:SetAttribute("IsPlaying", false) end
	end)
end

-- ═══════════════════════════════════════════════════════════
-- START GAME
-- ═══════════════════════════════════════════════════════════
StartGameBindable.Event:Connect(function(redList, whiteList)
	if isGameRunning then return end

	isGameRunning = true
	ropePosition = 0
	playersInGame = { Red = {}, White = {} }

	-- Teleport Tim Merah
	for i, plr in ipairs(redList) do
		table.insert(playersInGame.Red, plr)
		local sp = TeamRedSpawns:FindFirstChild("Spawn" .. tostring(math.min(i, 5))) or TeamRedSpawns:GetChildren()[1]
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local tPos = sp.Position + Vector3.new(0, 3, 0)
			local look = Vector3.new(CenterLine.Position.X, tPos.Y, CenterLine.Position.Z)
			plr.Character.HumanoidRootPart.CFrame = CFrame.lookAt(tPos, look)
			plr.Character.HumanoidRootPart.Anchored = true
		end
		ShowUIEvent:FireClient(plr)
	end

	-- Teleport Tim Putih
	for i, plr in ipairs(whiteList) do
		table.insert(playersInGame.White, plr)
		local sp = TeamWhiteSpawns:FindFirstChild("Spawn" .. tostring(math.min(i, 5))) or TeamWhiteSpawns:GetChildren()[1]
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local tPos = sp.Position + Vector3.new(0, 3, 0)
			local look = Vector3.new(CenterLine.Position.X, tPos.Y, CenterLine.Position.Z)
			plr.Character.HumanoidRootPart.CFrame = CFrame.lookAt(tPos, look)
			plr.Character.HumanoidRootPart.Anchored = true
		end
		ShowUIEvent:FireClient(plr)
	end

	-- Bangun tali setelah teleport selesai
	task.wait(0.5)
	buildRope()

	-- Kirim skor awal
	ScoreUpdateEvent:FireAllClients(0)

	print("[Tambang] Game Dimulai! Merah:", #playersInGame.Red, "Putih:", #playersInGame.White)
end)

-- ═══════════════════════════════════════════════════════════
-- PULL EVENT
-- ═══════════════════════════════════════════════════════════
PullEvent.OnServerEvent:Connect(function(plr, accuracy)
	if not isGameRunning then return end

	local team = nil
	for _, p in ipairs(playersInGame.Red) do if p == plr then team = "Red" break end end
	for _, p in ipairs(playersInGame.White) do if p == plr then team = "White" break end end
	if not team then return end

	local force = 0
	if accuracy >= 0.9 then force = 1.5
	elseif accuracy >= 0.7 then force = 0.8
	elseif accuracy >= 0.4 then force = 0.3
	else force = -0.3 end

	if team == "Red" then
		ropePosition = ropePosition - force
	else
		ropePosition = ropePosition + force
	end

	-- Broadcast skor ke semua pemain
	ScoreUpdateEvent:FireAllClients(ropePosition)

	-- Cek menang (threshold lebih tinggi = harus bener-bener dominan)
	if ropePosition <= -WIN_THRESHOLD then
		EndGame("Merah")
	elseif ropePosition >= WIN_THRESHOLD then
		EndGame("Putih")
	end
end)

-- ═══════════════════════════════════════════════════════════
-- UPDATE LOOP
-- ═══════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
	if isGameRunning and activeRopeModel then
		updateRope()
	end
end)

print("[Tambang] TambangManager Server Aktif!")
