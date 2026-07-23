-- ============================================================
-- PecahAirManager.server.luau
-- Mengatur logika server untuk minigame Pecah Balon Air
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("[PecahAir] ========== PecahAirManager DIMULAI ==========")

-- Pastikan folder Minigames dan PecahAir ada di ReplicatedStorage
local minigamesFolder = ReplicatedStorage:FindFirstChild("Minigames")
if not minigamesFolder then
	minigamesFolder = Instance.new("Folder")
	minigamesFolder.Name = "Minigames"
	minigamesFolder.Parent = ReplicatedStorage
end

local pecahAirFolder = minigamesFolder:FindFirstChild("PecahAir")
if not pecahAirFolder then
	pecahAirFolder = Instance.new("Folder")
	pecahAirFolder.Name = "PecahAir"
	pecahAirFolder.Parent = minigamesFolder
end

local eventsFolder = pecahAirFolder:FindFirstChild("Events")
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "Events"
	eventsFolder.Parent = pecahAirFolder
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
local winners = {}
local isGameRunning = false

-- ─────────────────────────────────────────────────────────
-- SISTEM TOOL PEMUKUL
-- ─────────────────────────────────────────────────────────
local ServerStorage = game:GetService("ServerStorage")

local function giveTool(player)
	-- Cek apakah player sudah punya tool
	local tool = player.Backpack:FindFirstChild("PemukulAir") or (player.Character and player.Character:FindFirstChild("PemukulAir"))
	if not tool then
		-- Prioritaskan mengambil tool buatan Anda dari ServerStorage
		local customTool = ServerStorage:FindFirstChild("PemukulAir")
		if customTool and customTool:IsA("Tool") then
			tool = customTool:Clone()
			tool.Parent = player.Backpack
			print("[PecahAir] Memberikan custom tool 'PemukulAir' dari ServerStorage ke " .. player.Name)
		else
			-- Fallback: Buat Tool sederhana jika belum ada di ServerStorage
			tool = Instance.new("Tool")
			tool.Name = "PemukulAir"
			tool.RequiresHandle = true
			tool.CanBeDropped = false

			local handle = Instance.new("Part")
			handle.Name = "Handle"
			handle.Size = Vector3.new(0.5, 4, 0.5)
			handle.BrickColor = BrickColor.new("Brown")
			handle.Material = Enum.Material.Wood
			handle.Parent = tool

			local animationScript = Instance.new("LocalScript")
			animationScript.Name = "SwingScript"
			animationScript.Source = [[
				local tool = script.Parent
				local player = game.Players.LocalPlayer
				local char = player.Character or player.CharacterAdded:Wait()
				local hum = char:WaitForChild("Humanoid")
			
				local anim = Instance.new("Animation")
				anim.AnimationId = "rbxassetid://218504594" -- Animasi slash default roblox
				local animTrack = nil
			
				tool.Equipped:Connect(function()
					animTrack = hum:LoadAnimation(anim)
				end)
			
				tool.Activated:Connect(function()
					if animTrack then
						animTrack:Play()
					end
				end)
			]]
			animationScript.Parent = tool

			tool.Parent = player.Backpack
		end
	end

	-- Paksa equip
	if player.Character and player.Character:FindFirstChild("Humanoid") then
		player.Character.Humanoid:EquipTool(tool)
	end
	return tool
end

local function removeTool(player)
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			-- Unequip agar event Unequipped di tool sempat jalan untuk memberhentikan animasi
			hum:UnequipTools()
			
			-- Hentikan paksa animasi yang nyangkut (biasanya Priority Action atau Idle custom)
			local animator = hum:FindFirstChildOfClass("Animator") or hum
			local playingTracks = animator:GetPlayingAnimationTracks()
			for _, track in ipairs(playingTracks) do
				if track.Animation.AnimationId == "rbxassetid://218504594" or string.match(track.Name, "Idle") or string.match(track.Name, "Equip") then
					track:Stop()
				end
			end
		end
	end
	
	task.wait(0.1) -- Beri sedikit waktu untuk script animasi client memproses
	
	local tool = player.Backpack:FindFirstChild("PemukulAir") or (char and char:FindFirstChild("PemukulAir"))
	if tool then
		tool:Destroy()
	end
end

local function hideTools(player)
	local tempFolder = player:FindFirstChild("TempTools")
	if not tempFolder then
		tempFolder = Instance.new("Folder")
		tempFolder.Name = "TempTools"
		tempFolder.Parent = player
	end
	
	for _, tool in ipairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name ~= "PemukulAir" then
			tool.Parent = tempFolder
		end
	end
	if player.Character then
		for _, tool in ipairs(player.Character:GetChildren()) do
			if tool:IsA("Tool") and tool.Name ~= "PemukulAir" then
				tool.Parent = tempFolder
			end
		end
	end
end

local function restoreTools(player)
	local tempFolder = player:FindFirstChild("TempTools")
	if tempFolder then
		for _, tool in ipairs(tempFolder:GetChildren()) do
			if tool:IsA("Tool") then
				tool.Parent = player.Backpack
			end
		end
	end
end

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
		text.Text = "GO!"
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

	local args = {...} -- Tiap pad mengirim list pemain (pad1 = args[1], pad2 = args[2]...)

	local arena = workspace:FindFirstChild("PecahAirArena") or workspace:FindFirstChild("PecahAir Arena")
	if not arena then
		warn("[PecahAir] PecahAirArena tidak ditemukan!")
		return
	end

	-- Kumpulkan semua pemain yang berpartisipasi
	activePlayers = {}
	winners = {}
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

				-- Cari Start line untuk teleport
				local spawnPos = arena:GetPivot() * CFrame.new((spawnCounter - 3) * 5, 2, 0)
				local foundSpawn = false

				local spawnsFolder = arena:FindFirstChild("Spawns")
				if spawnsFolder then
					-- Coba berbagai format nama spawn
					local spawnPart = spawnsFolder:FindFirstChild(tostring(spawnCounter))
						or spawnsFolder:FindFirstChild("Spawn" .. spawnCounter)
						or spawnsFolder:FindFirstChild("Spawn_" .. spawnCounter)

					-- Kalau tidak ketemu pakai nama, ambil berdasarkan urutan
					if not spawnPart then
						local children = spawnsFolder:GetChildren()
						if children[spawnCounter] then
							spawnPart = children[spawnCounter]
						end
					end

					if spawnPart then
						spawnPos = spawnPart.CFrame + Vector3.new(0, 3, 0)
						foundSpawn = true
						print("[PecahAir] Spawn ditemukan:", spawnPart.Name, "untuk pemain", player.Name)
					end
				end

				if not foundSpawn then
					local trackPos = arena:FindFirstChild("Track_" .. spawnCounter)
					if trackPos then
						spawnPos = trackPos.CFrame
						print("[PecahAir] Track ditemukan: Track_" .. spawnCounter)
					else
						print("[PecahAir] FALLBACK: Spawn tidak ditemukan, pakai posisi arena center untuk", player.Name)
					end
				end

				player.Character.HumanoidRootPart.CFrame = spawnPos
				player.Character.HumanoidRootPart.Anchored = true -- Freeze player for countdown

				showServerCountdown(player)

				-- Berikan tool & sembunyikan tool lain
				giveTool(player)
				hideTools(player)

				table.insert(activePlayers, player)
			end
		end
	end

	-- ─────────────────────────────────────────────────────────
	-- SPAWN 5 BALON AIR DI PART "SpawnBalon"
	-- ─────────────────────────────────────────────────────────
	local spawnBalonPart = arena:FindFirstChild("SpawnBalon")
	if not spawnBalonPart then
		warn("[PecahAir] Part 'SpawnBalon' tidak ditemukan di PecahAirArena! Balon tidak bisa di-spawn.")
	end

	local balloons = {} -- Simpan semua balon
	local balloonConnections = {} -- Simpan koneksi Touched
	local ceilingParts = {} -- Simpan tiang tali

	if spawnBalonPart then
		local TOTAL_BALON = 5
		local JARAK_ANTAR_BALON = 6 -- Jarak horizontal antar balon (stud)

		for i = 1, TOTAL_BALON do
			local balloon = Instance.new("Part")
			balloon.Name = "BalonAir_" .. i
			balloon.Shape = Enum.PartType.Ball
			balloon.Size = Vector3.new(3, 3, 3)

			-- Warna-warni balon biar seru
			local colors = {
				Color3.fromRGB(0, 150, 255),   -- Biru
				Color3.fromRGB(255, 80, 80),    -- Merah
				Color3.fromRGB(80, 255, 80),    -- Hijau
				Color3.fromRGB(255, 200, 0),    -- Kuning
				Color3.fromRGB(200, 80, 255),   -- Ungu
			}
			balloon.Color = colors[i] or colors[1]
			balloon.Material = Enum.Material.Glass
			balloon.Transparency = 0.3
			balloon.Anchored = true
			balloon.CanCollide = true

			-- Posisi: berjajar horizontal dari SpawnBalon (sekarang menggunakan sumbu Z agar menyamping)
			local offsetZ = (i - math.ceil(TOTAL_BALON / 2)) * JARAK_ANTAR_BALON
			balloon.CFrame = spawnBalonPart.CFrame * CFrame.new(0, -3, offsetZ)

			-- Tali pendek dari SpawnBalon ke balon
			local topAtt = Instance.new("Attachment")
			local topPart = Instance.new("Part")
			topPart.Size = Vector3.new(1, 1, 1)
			topPart.Anchored = true
			topPart.Transparency = 1
			topPart.CanCollide = false
			topPart.CFrame = spawnBalonPart.CFrame * CFrame.new(0, 0, offsetZ)
			topPart.Parent = arena
			topAtt.Parent = topPart

			local bottomAtt = Instance.new("Attachment")
			bottomAtt.Position = Vector3.new(0, 1.5, 0)
			bottomAtt.Parent = balloon

			local rope = Instance.new("RopeConstraint")
			rope.Visible = true
			rope.Thickness = 0.15
			rope.Color = BrickColor.new("White")
			rope.Length = 3 -- Tali pendek
			rope.Attachment0 = topAtt
			rope.Attachment1 = bottomAtt
			rope.Parent = balloon

			balloon.Parent = arena

			table.insert(balloons, balloon)
			table.insert(ceilingParts, topPart)

			-- Logika Pecah - SIAPAPUN bisa mecahin balon manapun
			local connection
			connection = balloon.Touched:Connect(function(hit)
				if not isGameRunning then return end
				if hit.Parent and hit.Parent.Name == "PemukulAir" then
					local hitterChar = hit.Parent.Parent
					local hitterPlayer = Players:GetPlayerFromCharacter(hitterChar)

					if hitterPlayer then
						balloon.Transparency = 1
						balloon.CanCollide = false

						-- Tambahkan Suara Pop (Langsung Play agar tidak delay)
						local popSound = Instance.new("Sound")
						popSound.SoundId = "rbxassetid://125643207167266" 
						popSound.Volume = 1
						popSound.Parent = workspace
						popSound:Play()
						game:GetService("Debris"):AddItem(popSound, 3)

						-- Efek Visual Percikan Air (Diperbaiki agar muncul)
						local splashPart = Instance.new("Part")
						splashPart.Size = Vector3.new(0.1, 0.1, 0.1)
						splashPart.Position = balloon.Position
						splashPart.Transparency = 1
						splashPart.Anchored = true
						splashPart.CanCollide = false
						splashPart.Parent = workspace

						local splash = Instance.new("ParticleEmitter")
						-- Hapus custom texture agar pakai bawaan Roblox yang pasti muncul
						splash.Color = ColorSequence.new(balloon.Color)
						splash.Size = NumberSequence.new({
							NumberSequenceKeypoint.new(0, 4), 
							NumberSequenceKeypoint.new(1, 0)
						})
						splash.Speed = NumberRange.new(20, 40)
						splash.SpreadAngle = Vector2.new(360, 360) 
						splash.Drag = 3 
						splash.Acceleration = Vector3.new(0, -40, 0) 
						splash.Enabled = false
						splash.Parent = splashPart

						-- Beri jeda sangat singkat agar engine sempat me-load Emitter sebelum ditembakkan
						task.delay(0.05, function()
							splash:Emit(150)
						end)

						local Debris = game:GetService("Debris")
						Debris:AddItem(splashPart, 3) -- Hapus percikan setelah 3 detik

						-- Catat siapa yang mecahin (hanya kalau belum dicatat)
						local alreadyWon = false
						for _, w in ipairs(winners) do
							if w == hitterPlayer.Name then alreadyWon = true break end
						end
						if not alreadyWon then
							table.insert(winners, hitterPlayer.Name)
						end

						connection:Disconnect()

						task.wait(1)
						balloon:Destroy()
						topPart:Destroy()
					end
				end
			end)

			table.insert(balloonConnections, connection)
		end

		print("[PecahAir] 5 Balon Air berhasil di-spawn di SpawnBalon!")
	end

	-- Tunggu 5 detik untuk hitungan mundur sebelum mulai game
	task.wait(5)

	-- Unfreeze semua player setelah countdown
	for _, player in ipairs(activePlayers) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character.HumanoidRootPart.Anchored = false
			GameStartEvent:FireClient(player)
		end
	end

	print("[PecahAir] Game Dimulai! Menunggu balon dipecahkan...")

	-- Loop permainan
	local timeElapsed = 0
	local timeLimit = 60 -- 1 menit batas waktu

	while isGameRunning and timeElapsed < timeLimit do
		task.wait(1)
		timeElapsed = timeElapsed + 1

		-- Jika sudah ada 1 orang yang pecahin balon, game selesai!
		if #winners >= 1 then
			isGameRunning = false
		end
	end

	isGameRunning = false
	print("[PecahAir] Game Selesai!")

	-- Beri Cash Reward
	local addCashFunc = ReplicatedStorage:FindFirstChild("_AddCash")

	local updateWinsFunc = ReplicatedStorage:FindFirstChild("_BalapKarungUpdateWins")
	local updateLossesFunc = ReplicatedStorage:FindFirstChild("_BalapKarungUpdateLosses")

	local rewardData = {}
	local coinRewards = {150, 100, 50, 25, 10}

	-- Beri hadiah kepada winners sesuai urutan
	for rank, winnerName in ipairs(winners) do
		local reward = coinRewards[rank] or 10
		rewardData[winnerName] = reward

		local winnerPlayer = Players:FindFirstChild(winnerName)
		if winnerPlayer then
			if addCashFunc then
				pcall(function() addCashFunc:Invoke(winnerPlayer, reward, "Pecah Air Rank " .. rank) end)
			end
			
			local addSpins = ReplicatedStorage:FindFirstChild("_AddSpins")
			if addSpins then
				pcall(function() addSpins:Invoke(winnerPlayer, 1) end)
				print("[PecahAir] " .. winnerPlayer.Name .. " mendapat 1 Spin Ticket!")
			end
			
			-- Asumsi kita pakai LeaderboardService dari BalapKarung, 
			-- TAPI karena beda arena, sebaiknya pakai datastore khusus PecahAir. 
			-- Namun saat ini kita panggil _PecahAirUpdateWins (nanti dibuat).
			local updateWins = ReplicatedStorage:FindFirstChild("_PecahAirUpdateWins")
			if updateWins then
				pcall(function() updateWins:Invoke(winnerPlayer.UserId, 1) end)
			end
		end
	end

	-- Kumpulkan data losers
	local losers = {}
	for _, p in ipairs(activePlayers) do
		local isWinner = false
		for _, w in ipairs(winners) do
			if p.Name == w then isWinner = true break end
		end
		if not isWinner then
			table.insert(losers, p.Name)
		end
	end

	-- Pemain yang tidak menang dapat loss
	for _, p in ipairs(activePlayers) do
		local isWinner = false
		for _, w in ipairs(winners) do
			if p.Name == w then isWinner = true break end
		end

		if not isWinner then
			local updateLosses = ReplicatedStorage:FindFirstChild("_PecahAirUpdateLosses")
			if updateLosses then
				pcall(function() updateLosses:Invoke(p.UserId, 1) end)
			end
		end

		-- Hentikan efek client & show result UI
		GameEndEvent:FireClient(p, winners, rewardData, losers)
		removeTool(p)
		restoreTools(p)
	end

	task.wait(5) -- Tunggu UI result selesai

	-- Bersihkan arena
	for _, child in ipairs(arena:GetChildren()) do
		if string.match(child.Name, "^BalonAir_") then
			child:Destroy()
		end
	end

	-- Teleport keluar
	local outPart = arena:FindFirstChild("endgame")
	for _, p in ipairs(activePlayers) do
		if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			p.Character.HumanoidRootPart.Anchored = false
			local offset = Vector3.new(math.random(-10, 10), 3, math.random(-10, 10))
			p.Character.HumanoidRootPart.CFrame = outPart.CFrame + offset
		end
	end

	activePlayers = {}
	if arena then arena:SetAttribute("IsPlaying", false) end
end)
