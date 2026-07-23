-- ============================================================
-- TangkapAyamManager.server.luau
-- Mengatur logika server untuk minigame Tangkap Ayam (Score & Timer Based)
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Pastikan folder Minigames dan TangkapAyam ada di ReplicatedStorage
local minigamesFolder = ReplicatedStorage:FindFirstChild("Minigames")
if not minigamesFolder then
	minigamesFolder = Instance.new("Folder")
	minigamesFolder.Name = "Minigames"
	minigamesFolder.Parent = ReplicatedStorage
end

local ayamFolder = minigamesFolder:FindFirstChild("TangkapAyam")
if not ayamFolder then
	ayamFolder = Instance.new("Folder")
	ayamFolder.Name = "TangkapAyam"
	ayamFolder.Parent = minigamesFolder
end

local eventsFolder = ayamFolder:FindFirstChild("Events")
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "Events"
	eventsFolder.Parent = ayamFolder
end

-- ============================================================
-- KLIEN SCRIPT SEKARANG ADA DI STARTERPLAYERSCRIPTS
-- ============================================================
-- ============================================================

local function getOrCreateEvent(className, name)
	local event = eventsFolder:FindFirstChild(name)
	if not event then
		event = Instance.new(className)
		event.Name = name
		event.Parent = eventsFolder
	end
	return event
end

local StartGameBindable = getOrCreateEvent("BindableEvent", "StartGame")
local DrunkEffectEvent = getOrCreateEvent("RemoteEvent", "DrunkEffectEvent")
local UpdateUIEvent = getOrCreateEvent("RemoteEvent", "UpdateTangkapAyamUI")
local HideUIEvent = getOrCreateEvent("RemoteEvent", "HideTangkapAyamUI")

local activePlayers = {} 
local participatingPlayers = {}
local playerScores = {}
local isGameRunning = false
local activeChickens = {}

local GAME_DURATION = 60
local MAX_CHICKENS = 5

-- Setup Chicken Dummy jika belum ada di ReplicatedStorage
local ayamSource = ReplicatedStorage:FindFirstChild("Ayam") or ReplicatedStorage:FindFirstChild("Chicken")
local ayamModel = nil

if ayamSource then
	if ayamSource:IsA("Model") then
		ayamModel = ayamSource
	elseif ayamSource:IsA("Part") or ayamSource:IsA("MeshPart") then
		-- Jika user menggunakan Part tunggal, kita bungkus jadi Model agar punya Humanoid & PrimaryPart
		ayamModel = Instance.new("Model")
		ayamModel.Name = "Ayam"
		
		local partClone = ayamSource:Clone()
		partClone.Name = "HumanoidRootPart"
		partClone.Anchored = false
		partClone.Parent = ayamModel
		ayamModel.PrimaryPart = partClone
		
		local hum = Instance.new("Humanoid")
		hum.WalkSpeed = 25
		hum.Parent = ayamModel
	end
end

if not ayamModel then
	ayamModel = Instance.new("Model")
	ayamModel.Name = "Ayam"
	
	local part = Instance.new("Part")
	part.Name = "HumanoidRootPart"
	part.Size = Vector3.new(2, 2, 2)
	part.Color = Color3.fromRGB(255, 255, 0)
	part.Parent = ayamModel
	ayamModel.PrimaryPart = part
	
	local hum = Instance.new("Humanoid")
	hum.WalkSpeed = 25
	hum.Parent = ayamModel
	
	ayamModel.Parent = ReplicatedStorage
end

local startChickenAI -- Forward declaration

local function cleanupArena(arenaModel)
	for _, chicken in ipairs(activeChickens) do
		if chicken then chicken:Destroy() end
	end
	activeChickens = {}
	
	for player, _ in pairs(participatingPlayers) do
		pcall(function() DrunkEffectEvent:FireClient(player, false) end)
		pcall(function() HideUIEvent:FireClient(player) end)
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.WalkSpeed = 16
		end
	end
	
	activePlayers = {}
	participatingPlayers = {}
	playerScores = {}
	isGameRunning = false
	if arenaModel then arenaModel:SetAttribute("IsPlaying", false) end
end

local function spawnSingleChicken(arenaModel)
	local arenaBounds = arenaModel:FindFirstChild("ArenaBounds")
	if not arenaBounds then return end
	
	local chicken = ayamModel:Clone()
	
	for _, child in ipairs(chicken:GetDescendants()) do
		if child:IsA("Script") or child:IsA("LocalScript") then
			child:Destroy()
		elseif child:IsA("BasePart") then
			child.Anchored = false -- PASTIKAN SEMUA PART UNANCHORED!
			-- Nonaktifkan CanCollide pada part visual agar ayam TIDAK BISA saling panjat / menumpuk!
			if child.Name ~= "HumanoidRootPart" then
				child.CanCollide = false
			end
			child.CanTouch = true
		end
	end
	
	local bg = Instance.new("BodyGyro")
	bg.Name = "AIAim"
	bg.MaxTorque = Vector3.new(0, math.huge, 0) -- Putaran Y sangat kuat
	bg.P = 15000
	bg.Parent = chicken.PrimaryPart
	
	local bv = Instance.new("BodyVelocity")
	bv.Name = "AIMove"
	bv.MaxForce = Vector3.new(math.huge, 0, math.huge) -- Kekuatan tanpa batas di X dan Z
	bv.Velocity = Vector3.new(0, 0, 0)
	bv.Parent = chicken.PrimaryPart
	
	chicken.Parent = workspace
	
	local arenaCenter = arenaBounds.Position
	local arenaRadius = (math.min(arenaBounds.Size.X, arenaBounds.Size.Z) / 2) * 0.75
	
	-- Cari posisi spawn acak yang tidak saling menumpuk dengan ayam lain
	local angle = math.random() * math.pi * 2
	local dist = math.random() * arenaRadius
	local spawnPos = arenaCenter + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
	
	-- Coba cari posisi yang agak renggang jika bisa
	for attempts = 1, 5 do
		local isTooClose = false
		for _, otherChicken in ipairs(activeChickens) do
			if otherChicken and otherChicken.PrimaryPart then
				if (otherChicken.PrimaryPart.Position - spawnPos).Magnitude < 4 then
					isTooClose = true
					break
				end
			end
		end
		
		if not isTooClose then break end
		
		angle = math.random() * math.pi * 2
		dist = math.random() * arenaRadius
		spawnPos = arenaCenter + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
	end
	
	chicken:PivotTo(CFrame.new(Vector3.new(spawnPos.X, arenaCenter.Y + 2, spawnPos.Z)))
	
	-- Tambahkan ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Tangkap!"
	prompt.ObjectText = "Ayam"
	prompt.HoldDuration = 0 -- Instan tekan/tap (sangat mudah untuk mobile & PC)
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 9
	prompt.Parent = chicken.PrimaryPart
	
	prompt.Triggered:Connect(function(player)
		if not isGameRunning or not participatingPlayers[player] then return end
		
		-- Tambah skor
		playerScores[player] = (playerScores[player] or 0) + 1
		
		-- Hapus ayam ini
		for i, c in ipairs(activeChickens) do
			if c == chicken then
				table.remove(activeChickens, i)
				break
			end
		end
		chicken:Destroy()
		
		-- Spawn ayam baru untuk menggantikan
		spawnSingleChicken(arenaModel)
	end)
	
	table.insert(activeChickens, chicken)
	
	startChickenAI(chicken, arenaModel)
end

startChickenAI = function(chicken, arenaModel)
	task.spawn(function()
		local arenaBounds = arenaModel:FindFirstChild("ArenaBounds")
		if not arenaBounds then return end
		
		local lastPos = chicken.PrimaryPart.Position
		local stuckTimer = 0
		
		-- Hitung pusat dan radius arena bundar (dengan safety margin 80%)
		local arenaCenter = arenaBounds.Position
		local arenaRadius = (math.min(arenaBounds.Size.X, arenaBounds.Size.Z) / 2) * 0.80
		
		local function getRandomCirclePos()
			local angle = math.random() * math.pi * 2
			local dist = (0.2 + math.random() * 0.8) * arenaRadius
			return arenaCenter + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		end
		
		local function clampToCircle(pos)
			local offset = Vector3.new(pos.X - arenaCenter.X, 0, pos.Z - arenaCenter.Z)
			if offset.Magnitude > arenaRadius then
				local clampedOffset = offset.Unit * (arenaRadius * 0.85)
				return arenaCenter + Vector3.new(clampedOffset.X, 0, clampedOffset.Z)
			end
			return pos
		end
		
		while isGameRunning and chicken and chicken.Parent and chicken:FindFirstChild("Humanoid") and chicken.PrimaryPart do
			local hum = chicken.Humanoid
			local chickenPos = chicken.PrimaryPart.Position
			
			-- Cek pemain terdekat
			local closestPlayer = nil
			local minDistance = 18 -- Jarak panik ayam
			
			for _, player in ipairs(activePlayers) do
				if player.Character and player.Character.PrimaryPart then
					local dist = (player.Character.PrimaryPart.Position - chickenPos).Magnitude
					if dist < minDistance then
						minDistance = dist
						closestPlayer = player
					end
				end
			end
			
			-- Anti-Stuck Check
			if (chickenPos - lastPos).Magnitude < 0.8 then
				stuckTimer = stuckTimer + 0.5
			else
				stuckTimer = 0
			end
			lastPos = chickenPos
			
			if closestPlayer then
				-- Kabur dari pemain secara dinamis (360 derajat bundar)!
				hum.WalkSpeed = 24
				
				local playerPos = closestPlayer.Character.PrimaryPart.Position
				local fleeDir = (Vector3.new(chickenPos.X, 0, chickenPos.Z) - Vector3.new(playerPos.X, 0, playerPos.Z)).Unit
				
				if fleeDir.Magnitude < 0.1 then
					local randAngle = math.random() * math.pi * 2
					fleeDir = Vector3.new(math.cos(randAngle), 0, math.sin(randAngle))
				end
				
				-- Tambahkan variasi sudut acak (-35 s/d +35 derajat) agar lari natural
				local curveAngle = (math.random() - 0.5) * (math.pi / 2.5)
				local cosA = math.cos(curveAngle)
				local sinA = math.sin(curveAngle)
				local rotatedDir = Vector3.new(
					fleeDir.X * cosA - fleeDir.Z * sinA,
					0,
					fleeDir.X * sinA + fleeDir.Z * cosA
				).Unit
				
				local runDistance = math.random(12, 20)
				local rawTarget = chickenPos + (rotatedDir * runDistance)
				local finalTarget = clampToCircle(rawTarget)
				
				hum:SetAttribute("TargetPos", finalTarget)
				
				local aim = chicken.PrimaryPart:FindFirstChild("AIAim")
				local move = chicken.PrimaryPart:FindFirstChild("AIMove")
				if aim and move then
					aim.CFrame = CFrame.lookAt(chickenPos, chickenPos + rotatedDir)
					move.Velocity = rotatedDir * hum.WalkSpeed
				end
				
				task.wait(0.8) -- Berjalan lincah & stabil
			else
				-- Berkeliling santai menyebar di arena
				hum.WalkSpeed = 14
				
				local targetPos = hum:GetAttribute("TargetPos")
				local distToTarget = targetPos and (Vector3.new(targetPos.X, 0, targetPos.Z) - Vector3.new(chickenPos.X, 0, chickenPos.Z)).Magnitude or 0
				
				if not targetPos or distToTarget < 3 or stuckTimer > 1.2 then
					stuckTimer = 0
					local randomTarget = getRandomCirclePos()
					hum:SetAttribute("TargetPos", randomTarget)
					
					local dir = (Vector3.new(randomTarget.X, 0, randomTarget.Z) - Vector3.new(chickenPos.X, 0, chickenPos.Z)).Unit
					local aim = chicken.PrimaryPart:FindFirstChild("AIAim")
					local move = chicken.PrimaryPart:FindFirstChild("AIMove")
					if aim and move then
						aim.CFrame = CFrame.lookAt(chickenPos, chickenPos + dir)
						move.Velocity = dir * hum.WalkSpeed
					end
					
					task.wait(math.random(15, 25) / 10)
				else
					task.wait(0.4)
				end
			end
		end
	end)
end

local function endGame(arenaModel)
	isGameRunning = false
	
	local function getEndgamePart()
		if arenaModel then
			for _, obj in ipairs(arenaModel:GetDescendants()) do
				if obj:IsA("BasePart") and string.match(string.lower(obj.Name), "endgame") then
					return obj
				end
			end
		end
		
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") and string.match(string.lower(obj.Name), "endgame") then
				return obj
			end
		end
		return workspace:FindFirstChild("SpawnLocation")
	end
	
	-- Hentikan efek mabuk untuk semua
	for p, _ in pairs(participatingPlayers) do
		pcall(function() DrunkEffectEvent:FireClient(p, false) end)
		pcall(function() HideUIEvent:FireClient(p) end)
	end
	
	-- Cari Pemenang
	local maxScore = 0
	for p, score in pairs(playerScores) do
		if score > maxScore then
			maxScore = score
		end
	end
	
	local winners = {}
	if maxScore > 0 then
		for p, score in pairs(playerScores) do
			if score == maxScore then
				table.insert(winners, p)
			end
		end
	end
	
	if #winners > 0 then
		for _, winner in ipairs(winners) do
			print("[TangkapAyam] Pemenang: " .. winner.Name .. " dengan " .. maxScore .. " ayam!")
			local updateWinsFunc = ReplicatedStorage:FindFirstChild("_TangkapAyamUpdateWins")
			if updateWinsFunc then pcall(function() updateWinsFunc:Invoke(winner.UserId, 1) end) end
			
			local addSpinsFunc = ReplicatedStorage:FindFirstChild("_AddSpins")
			if addSpinsFunc then pcall(function() addSpinsFunc:Invoke(winner, 1) end) end
			
			pcall(function()
				PodiumTeleportEvent:Fire(winner, "TangkapAyam")
			end)
		end
	else
		print("[TangkapAyam] Tidak ada yang menang.")
	end
	
	local targetSpawn = getEndgamePart()
	
	-- Teleport yang kalah kembali ke lobby
	for p, _ in pairs(participatingPlayers) do
		if not table.find(winners, p) then
			local updateLossesFunc = ReplicatedStorage:FindFirstChild("_TangkapAyamUpdateLosses")
			if updateLossesFunc then pcall(function() updateLossesFunc:Invoke(p.UserId, 1) end) end
			
			if targetSpawn and p.Character then
				p.Character:PivotTo(targetSpawn.CFrame * CFrame.new(0, 3, 0))
			end
		end
	end
	
	task.wait(5)
	
	-- Kembalikan pemenang ke lobby
	for _, winner in ipairs(winners) do
		if targetSpawn and winner.Character then
			winner.Character:PivotTo(targetSpawn.CFrame * CFrame.new(0, 3, 0))
		end
	end
	
	cleanupArena(arenaModel)
end

StartGameBindable.Event:Connect(function(...)
	if isGameRunning then return end
	
	local arenaModel = workspace:FindFirstChild("TangkapAyamArena")
	if not arenaModel then
		warn("[TangkapAyam] Arena tidak ditemukan di Workspace!")
		return
	end
	
	local padGroups = {...}
	for _, group in ipairs(padGroups) do
		for _, player in ipairs(group) do
			participatingPlayers[player] = true
			playerScores[player] = 0
			table.insert(activePlayers, player)
			
			pcall(function() DrunkEffectEvent:FireClient(player, true) end)
		end
	end
	
	if #activePlayers == 0 then
		cleanupArena(arenaModel)
		return
	end
	
	isGameRunning = true
	
	-- Teleport semua ke dalam arena
	local arenaBounds = arenaModel:FindFirstChild("ArenaBounds")
	if arenaBounds then
		for _, player in ipairs(activePlayers) do
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				local size = arenaBounds.Size
				local pos = arenaBounds.Position
				local randomX = pos.X + math.random(-size.X/3, size.X/3)
				local randomZ = pos.Z + math.random(-size.Z/3, size.Z/3)
				player.Character:PivotTo(CFrame.new(Vector3.new(randomX, pos.Y + 3, randomZ)))
			end
		end
	end
	
	task.wait(1)
	
	-- Spawn ayam awal
	for i = 1, MAX_CHICKENS do
		spawnSingleChicken(arenaModel)
	end
	
	-- Game Timer Loop
	task.spawn(function()
		for timeLeft = GAME_DURATION, 0, -1 do
			if not isGameRunning then break end
			
			-- Update UI semua pemain
			for player, _ in pairs(participatingPlayers) do
				local score = playerScores[player] or 0
				pcall(function() UpdateUIEvent:FireClient(player, timeLeft, score) end)
			end
			
			task.wait(1)
		end
		
		if isGameRunning then
			endGame(arenaModel)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	if participatingPlayers[player] then
		participatingPlayers[player] = nil
		playerScores[player] = nil
		for i, p in ipairs(activePlayers) do
			if p == player then table.remove(activePlayers, i) break end
		end
		
		if isGameRunning and #activePlayers == 0 then
			local arenaModel = workspace:FindFirstChild("TangkapAyamArena")
			endGame(arenaModel)
		end
	end
end)

print("[TangkapAyamManager] Loaded successfully!")
