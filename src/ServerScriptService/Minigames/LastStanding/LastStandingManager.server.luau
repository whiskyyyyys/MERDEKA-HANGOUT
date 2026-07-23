-- ============================================================
-- LastStandingManager.server.luau
-- Mengatur logika server untuk minigame Last Standing (Sweeper)
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("[LastStanding] ========== LastStandingManager DIMULAI ==========")

-- Pastikan folder Minigames dan LastStanding ada di ReplicatedStorage
local minigamesFolder = ReplicatedStorage:FindFirstChild("Minigames")
if not minigamesFolder then
	minigamesFolder = Instance.new("Folder")
	minigamesFolder.Name = "Minigames"
	minigamesFolder.Parent = ReplicatedStorage
end

local lastStandingFolder = minigamesFolder:FindFirstChild("LastStanding")
if not lastStandingFolder then
	lastStandingFolder = Instance.new("Folder")
	lastStandingFolder.Name = "LastStanding"
	lastStandingFolder.Parent = minigamesFolder
end

local eventsFolder = lastStandingFolder:FindFirstChild("Events")
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "Events"
	eventsFolder.Parent = lastStandingFolder
end

-- Buat event secara otomatis jika belum ada
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
local GameStartEvent = getOrCreateEvent("RemoteEvent", "GameStartEvent")
local GameEndEvent = getOrCreateEvent("RemoteEvent", "GameEndEvent")

local activePlayers = {} -- Melacak pemain yang sedang main
local isGameRunning = false
local sweeperConnection = nil

-- ─────────────────────────────────────────────────────────
-- COUNTDOWN GUI UTILITY
-- ─────────────────────────────────────────────────────────
local function showServerCountdown(player)
	task.spawn(function()
		local pGui = player:FindFirstChild("PlayerGui")
		if not pGui then return end
		local gui = Instance.new("ScreenGui")
		gui.Name = "ServerCountdownGui"
		gui.IgnoreGuiInset = true
		gui.Parent = pGui
		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.TextScaled = true
		text.Font = Enum.Font.GothamBlack
		text.TextColor3 = Color3.fromRGB(255, 255, 0)
		text.TextStrokeTransparency = 0
		text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		text.Parent = gui
		for i = 5, 1, -1 do
			text.Text = tostring(i)
			task.wait(1)
		end
		text.Text = "JUMP!"
		text.TextColor3 = Color3.fromRGB(0, 255, 0)
		task.wait(1)
		gui:Destroy()
	end)
end

-- ─────────────────────────────────────────────────────────
-- LOGIKA UTAMA MINIGAME
-- ─────────────────────────────────────────────────────────
StartGameBindable.Event:Connect(function(...)
	if isGameRunning then return end

	local args = {...}

	local arena = workspace:FindFirstChild("LastStandingArena") or workspace:FindFirstChild("Last Standing Arena")
	if not arena then
		warn("[LastStanding] LastStandingArena tidak ditemukan di Workspace!")
		return
	end

	-- Kumpulkan semua pemain yang berpartisipasi
	activePlayers = {}
	isGameRunning = true

	-- Buat part endgame otomatis jika belum ada
	local outPart = arena:FindFirstChild("endgame")
	if not outPart then
		outPart = Instance.new("Part")
		outPart.Name = "endgame"
		outPart.Position = arena:GetPivot().Position + Vector3.new(0, 10, -30)
		outPart.Anchored = true
		outPart.CanCollide = false
		outPart.Transparency = 1
		outPart.Parent = arena
	end

	local spawnCounter = 0

	for _, padPlayers in ipairs(args) do
		for _, player in ipairs(padPlayers) do
			if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				spawnCounter = spawnCounter + 1

				-- Cari Start line / Pilar untuk teleport
				local spawnPos = arena:GetPivot() * CFrame.new((spawnCounter - 3) * 5, 2, 0)
				local foundSpawn = false

				local spawnsFolder = arena:FindFirstChild("Spawns")
				if spawnsFolder then
					local spawnPart = spawnsFolder:FindFirstChild(tostring(spawnCounter))
						or spawnsFolder:FindFirstChild("Spawn" .. spawnCounter)
						or spawnsFolder:FindFirstChild("Spawn_" .. spawnCounter)
						or spawnsFolder:GetChildren()[spawnCounter]

					if spawnPart then
						-- Putar 90 derajat dari rotasi aslinya
						local rot = spawnPart.CFrame.Rotation * CFrame.Angles(0, math.rad(90), 0)
						spawnPos = CFrame.new(spawnPart.Position + Vector3.new(0, 3, 0)) * rot
						foundSpawn = true
						print("[LastStanding] Spawn ditemukan:", spawnPart.Name, "untuk", player.Name)
					end
				end

				if not foundSpawn then
					local trackPos = arena:FindFirstChild("Track_" .. spawnCounter)
					if trackPos then
						spawnPos = trackPos.CFrame
					end
				end

				local hrp = player.Character.HumanoidRootPart
				hrp.CFrame = spawnPos
				hrp.Anchored = true -- Freeze player for countdown
				
				-- Jangan biarkan pemain berjalan, HANYA BISA LOMPAT
				local humanoid = player.Character:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = 0
				end

				showServerCountdown(player)

				-- Dengarkan kalau player mati (jatuh ke air / kena kill brick)
				local deathConn
				deathConn = humanoid.Died:Connect(function()
					if not isGameRunning then return end
					print("[LastStanding]", player.Name, "tereliminasi!")
					-- Hapus dari activePlayers
					for i, p in ipairs(activePlayers) do
						if p == player then
							table.remove(activePlayers, i)
							break
						end
					end
				end)

				table.insert(activePlayers, player)
			end
		end
	end

	task.wait(5) -- Tunggu hitungan mundur

	-- Unfreeze semua player setelah countdown
	for _, player in ipairs(activePlayers) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.Anchored = false
			-- Pastikan masih tidak bisa jalan, hanya bisa lompat
			local hum = player.Character:FindFirstChild("Humanoid")
			if hum then
				hum.WalkSpeed = 0
			end
			GameStartEvent:FireClient(player)
		end
	end

	print("[LastStanding] Game Dimulai!")

	-- ─────────────────────────────────────────────────────────
	-- LOGIKA PUTARAN SWEEPER (Sapu Merah)
	-- ─────────────────────────────────────────────────────────
	local sweeper = arena:FindFirstChild("Sweeper")
	local centerPart = nil
	if sweeper then
		if sweeper:IsA("Model") then
			centerPart = sweeper:FindFirstChild("Tengah") or sweeper.PrimaryPart or sweeper:FindFirstChild("Center")
			-- Paksa set PrimaryPart agar PivotTo akurat
			if centerPart and not sweeper.PrimaryPart then
				sweeper.PrimaryPart = centerPart
			end
		elseif sweeper:IsA("BasePart") then
			centerPart = sweeper
		end
	else
		-- Coba cari part Sweeper langsung di Arena
		centerPart = arena:FindFirstChild("Tengah", true) or arena:FindFirstChild("SweeperCenter")
	end

	if centerPart and centerPart:IsA("BasePart") then
		centerPart.Anchored = true
		local currentSpeed = 45 -- Derajat per detik
		local targetSpeed = 45
		local originalCFrame = nil
		
		if sweeper and sweeper:IsA("Model") then
			originalCFrame = sweeper:GetPivot()
		else
			originalCFrame = centerPart.CFrame
		end
		
		-- Task untuk mengganti kecepatan / arah secara acak
		task.spawn(function()
			while isGameRunning do
				task.wait(math.random(3, 8))
				if not isGameRunning then break end
				
				-- Acak kecepatan baru (bisa minus untuk muter kebalik)
				local randomType = math.random(1, 3)
				if randomType == 1 then
					targetSpeed = math.random(30, 60) -- Sedang
				elseif randomType == 2 then
					targetSpeed = math.random(80, 150) -- Cepat
				elseif randomType == 3 then
					targetSpeed = -math.random(30, 100) -- Berbalik arah
				end
			end
		end)

		sweeperConnection = RunService.Heartbeat:Connect(function(dt)
			if not isGameRunning then return end
			-- Lakukan lerp (transisi halus) kecepatan putaran agar tidak tiba-tiba patah
			currentSpeed = currentSpeed + (targetSpeed - currentSpeed) * (dt * 2)
			
			local rotCFrame = CFrame.Angles(0, math.rad(currentSpeed * dt), 0)
			
			if sweeper and sweeper:IsA("Model") then
				local oldPivot = sweeper:GetPivot()
				local newPivot = CFrame.new(oldPivot.Position) * rotCFrame * (oldPivot - oldPivot.Position)
				sweeper:PivotTo(newPivot)
			else
				local pos = centerPart.Position
				centerPart.CFrame = CFrame.new(pos) * rotCFrame * (centerPart.CFrame - pos)
			end
		end)
		
		-- Buat function cleanup untuk dipanggil saat game selesai
		arena:SetAttribute("OriginalSweeperCFrame", true)
		task.spawn(function()
			while isGameRunning do task.wait(1) end
			if sweeper and sweeper:IsA("Model") then
				sweeper:PivotTo(originalCFrame)
			else
				centerPart.CFrame = originalCFrame
			end
		end)
	else
		warn("[LastStanding] Sweeper atau Center Part tidak ditemukan di Arena! Palang tidak akan berputar.")
	end

	-- ─────────────────────────────────────────────────────────
	-- LOOP PERMAINAN (Tunggu sampai sisa 1 orang)
	-- ─────────────────────────────────────────────────────────
	local timeElapsed = 0
	local timeLimit = 120 -- 2 menit maksimal

	while isGameRunning and timeElapsed < timeLimit do
		task.wait(1)
		timeElapsed = timeElapsed + 1

		-- Cek sisa pemain
		-- Bersihkan player yang disconnect
		for i = #activePlayers, 1, -1 do
			local p = activePlayers[i]
			if not p or not p.Parent or not p.Character or p.Character.Humanoid.Health <= 0 then
				table.remove(activePlayers, i)
			end
		end

		if #activePlayers <= 1 then
			isGameRunning = false
		end
	end

	isGameRunning = false
	if sweeperConnection then
		sweeperConnection:Disconnect()
		sweeperConnection = nil
	end

	print("[LastStanding] Game Selesai!")

	-- Kumpulkan nama pemenang
	local addSpinsFunc = ReplicatedStorage:FindFirstChild("_AddSpins")
	local winners = {}
	if #activePlayers > 0 then
		for _, p in ipairs(activePlayers) do
			table.insert(winners, p.Name)
			if addSpinsFunc then
				pcall(function() addSpinsFunc:Invoke(p, 1) end)
				print("[LastStanding] " .. p.Name .. " mendapat 1 Spin Ticket!")
			end
		end
	end

	-- Beri Cash Reward
	local addCashFunc = ReplicatedStorage:FindFirstChild("_AddCash")
	local updateWinsFunc = ReplicatedStorage:FindFirstChild("_LastStandingUpdateWins")
	local updateLossesFunc = ReplicatedStorage:FindFirstChild("_LastStandingUpdateLosses")
	
	local rewardData = {}

	for _, winnerName in ipairs(winners) do
		local reward = 200 -- Hadiah besar karena susah
		rewardData[winnerName] = reward

		local winnerPlayer = Players:FindFirstChild(winnerName)
		if winnerPlayer then
			if addCashFunc then
				pcall(function() addCashFunc:Invoke(winnerPlayer, reward, "Menang Last Standing") end)
			end
			if updateWinsFunc then
				pcall(function() updateWinsFunc:Invoke(winnerPlayer.UserId, 1) end)
			end
		end
	end

	-- Hentikan efek client & teleport keluar
	for _, p in ipairs(activePlayers) do
		-- Kembalikan WalkSpeed
		if p.Character and p.Character:FindFirstChild("Humanoid") then
			p.Character.Humanoid.WalkSpeed = 16
		end
		
		GameEndEvent:FireClient(p, winners, rewardData, {})
	end

	task.wait(5) -- Tunggu UI result selesai

	-- Teleport keluar
	local outPartTeleport = arena:FindFirstChild("endgame")
	for _, p in ipairs(activePlayers) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			p.Character.HumanoidRootPart.Anchored = false
			local offset = Vector3.new(math.random(-10, 10), 3, math.random(-10, 10))
			p.Character.HumanoidRootPart.CFrame = outPartTeleport.CFrame + offset
		end
	end

	activePlayers = {}
	if arena then arena:SetAttribute("IsPlaying", false) end
end)

print("[LastStanding] Berhasil dimuat.")
