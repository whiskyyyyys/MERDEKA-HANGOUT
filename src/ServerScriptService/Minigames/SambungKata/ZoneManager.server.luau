-- ============================================================
-- ZoneManager.server.lua
-- Script → ServerScriptService/ZoneManager
--
-- CARA PAKAI:
--   1. Di Roblox Studio, buat Folder bernama "Zones" di dalam Workspace
--   2. Letakkan Part di dalam folder tersebut (boleh invisible/visible)
--   3. Beri Attribute bernama "MaxPlayers" (type: number) → nilai 2 / 4 / 8
--   4. Script ini otomatis mendeteksi pemain masuk/keluar via Touched
-- ============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Modules")
local Config  = require(Modules:WaitForChild("GameConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Remotes")

-- 🔍 Tunggu folder Zones ada di Workspace -> SambungKata 🔍
local sambungKataModel = workspace:FindFirstChild("SambungKata")
if not sambungKataModel then
	sambungKataModel = Instance.new("Folder")
	sambungKataModel.Name = "SambungKata"
	sambungKataModel.Parent = workspace
end

local zonesFolder = sambungKataModel:FindFirstChild(Config.ZoneFolder)
if not zonesFolder then
	zonesFolder = Instance.new("Folder")
	zonesFolder.Name = Config.ZoneFolder
	zonesFolder.Parent = sambungKataModel
end

-- ── State ────────────────────────────────────────────────────
-- zoneData[zoneName] = {
--   part        = BasePart,
--   maxPlayers  = number,
--   inside      = { [Player] = true },   -- player fisik di dalam part
--   waitingList = { [Player] = true },   -- sudah klik JOIN
--   status      = "waiting" | "playing",
-- }
local zoneData = {}

local function getMinPlayersForZone(maxPlayers)
	local perZone = Config.MinPlayersByZoneSize or {}
	return perZone[maxPlayers] or Config.MinPlayersToStart or 2
end

-- ── Helper: cek apakah HumanoidRootPart ada di dalam part ────
local function isInsidePart(character, zonePart, margin)
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local localPos = zonePart.CFrame:PointToObjectSpace(hrp.Position)
	local half     = zonePart.Size * 0.5
	local m        = margin or 0
	return  math.abs(localPos.X) <= half.X + m
		and math.abs(localPos.Y) <= half.Y + m
		and math.abs(localPos.Z) <= half.Z + m
end

-- ── Helper: dapatkan Player dari sebuah Part karakter ─────────
local function getPlayerFromPart(part)
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then return nil end
	return Players:GetPlayerFromCharacter(model)
end

-- ── Kirim info zona ke satu / semua player ───────────────────
local function sendZoneInfoToPlayer(player)
	local info = {}
	for zoneName, data in pairs(zoneData) do
		local waiting = 0
		for _ in pairs(data.waitingList) do waiting = waiting + 1 end
		table.insert(info, {
			name       = zoneName,
			maxPlayers = data.maxPlayers,
			current    = waiting,
			status     = data.status,
		})
	end
	Remotes:WaitForChild(Config.Remotes.UpdateZoneInfo):FireClient(player, info)
end

local function sendZoneInfoToAll()
	for _, p in ipairs(Players:GetPlayers()) do
		sendZoneInfoToPlayer(p)
	end
end

-- ── Notify client: player masuk / keluar zona ────────────────
local function notifyEntered(player, zoneName)
	Remotes:WaitForChild(Config.Remotes.UpdateZoneInfo)
		:FireClient(player, { enteredZone = zoneName })
end

local function notifyLeft(player)
	Remotes:WaitForChild(Config.Remotes.UpdateZoneInfo)
		:FireClient(player, { enteredZone = "" })
end

-- ── BindableEvent untuk komunikasi ke GameManager ────────────
-- ZoneManager sebagai producer, GameManager pakai WaitForChild
local startGameEvent      = Instance.new("BindableEvent")
startGameEvent.Name       = "_StartGame"
startGameEvent.Parent     = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")

-- ── Seat-lock: kunci posisi player selama menunggu ────────────
local playerSeatLocks = {}   -- [Player] = task thread

local function lockPlayerToSeat(player, targetCF)
	-- Batalkan lock lama kalau ada
	if playerSeatLocks[player] then
		if type(playerSeatLocks[player]) == "thread" then
			task.cancel(playerSeatLocks[player])
		end
		playerSeatLocks[player] = nil
	end
	-- Nonaktifkan lompat & jalan, terapkan animasi duduk
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.JumpHeight = 0
			hum.WalkSpeed  = 0
		end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame   = targetCF
			hrp.Anchored = true
		end
		-- Set Sit SETELAH anchor agar animasi duduk muncul
		if hum then
			task.defer(function()
				if hum and hum.Parent then
					hum.Sit = true
				end
			end)
		end
	end
	-- Simpan referensi (tidak perlu loop lagi)
	playerSeatLocks[player] = true
end

local function unlockPlayer(player)
	if playerSeatLocks[player] then
		if type(playerSeatLocks[player]) == "thread" then
			task.cancel(playerSeatLocks[player])
		end
		playerSeatLocks[player] = nil
	end
	local char = player.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.Anchored = false
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Sit        = false   -- paksa berdiri dari Seat
			hum.JumpHeight = 7.2     -- default Roblox
			hum.WalkSpeed  = 16
		end
	end
end

-- ── Expose unlockPlayer agar GameManager bisa panggil saat eliminasi ─
local unlockPlayerFunc     = Instance.new("BindableFunction")
unlockPlayerFunc.Name      = "_UnlockPlayer"
unlockPlayerFunc.Parent    = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
unlockPlayerFunc.OnInvoke  = function(player)
	unlockPlayer(player)
end

local removePlayerFromZoneFunc    = Instance.new("BindableFunction")
removePlayerFromZoneFunc.Name     = "_RemovePlayerFromZone"
removePlayerFromZoneFunc.Parent   = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
removePlayerFromZoneFunc.OnInvoke = function(zoneName, player)
	local data = zoneData[zoneName]
	if not data or not player then return false end

	data.waitingList[player] = nil
	for _, slot in ipairs(data.seatSlots) do
		if slot.occupant == player then
			slot.occupant = nil
			break
		end
	end

	if data.prompt and data.status ~= "playing" then
		data.prompt.Enabled = true
	end

	return true
end

-- ── Update billboard di atas zona Part ───────────────────────
local function updateZoneBillboard(zoneName)
	local data = zoneData[zoneName]
	if not data or not data.billboardLabel then return end
	local count = 0
	for _ in pairs(data.waitingList) do count = count + 1 end
	local statusText
	if data.status == "countdown" then
		statusText = count .. "/" .. data.maxPlayers .. "  —  Segera dimulai"
	elseif data.status == "playing" then
		statusText = "Sedang berlangsung"
	else
		statusText = count .. "/" .. data.maxPlayers
			.. (count == 0 and "  —  Menunggu" or "  —  Menunggu")
	end
	data.billboardLabel.Text = statusText
end

-- ── Hitung posisi duduk di sekitar zona ──────────────────────
local function getSeatPositions(zonePart, count)
	-- Prioritas: child Part bernama "Seat1", "Seat2", dst di dalam zona
	local seats = {}
	for i = 1, count do
		local s = zonePart:FindFirstChild("Seat" .. i)
		if s and s:IsA("BasePart") then
			-- HRP center karakter saat duduk di atas permukaan kursi.
			-- Permukaan atas seat = s.Position.Y + s.Size.Y/2
			-- HRP berada ~0.8 stud di atas permukaan seat (setinggi pinggang)
			local surfaceY = s.Position.Y + s.Size.Y / 2
			local hrpY     = surfaceY + 0.8
			local cf = CFrame.new(s.Position.X, hrpY, s.Position.Z)
				* (s.CFrame - s.CFrame.Position)  -- ambil rotasi dari seat
			table.insert(seats, cf)
		end
	end
	if #seats >= count then return seats end

	-- Fallback: posisi melingkar otomatis di atas permukaan zona
	seats = {}
	local radius  = math.max(zonePart.Size.X, zonePart.Size.Z) * 0.28
	radius        = math.max(radius, 4)
	local cx      = zonePart.Position.X
	local cz      = zonePart.Position.Z
	-- Permukaan atas zona + HRP offset (karakter jongkok ~1.5 stud tingginya)
	local surfaceY = zonePart.Position.Y + zonePart.Size.Y / 2
	local seatY    = surfaceY + 0.8
	for i = 1, count do
		local angle = (i - 1) * (2 * math.pi / count)
		local px    = cx + math.cos(angle) * radius
		local pz    = cz + math.sin(angle) * radius
		local pos   = Vector3.new(px, seatY, pz)
		local cf    = CFrame.lookAt(pos, Vector3.new(cx, seatY, cz))
		table.insert(seats, cf)
	end
	return seats
end

-- ── Coba mulai game (dengan hitungan mundur) ──────────────────
local function tryStartGame(zoneName)
	local data = zoneData[zoneName]
	if not data or data.status == "playing" then return end

	local count = 0
	for _ in pairs(data.waitingList) do count = count + 1 end

	local minPlayers = getMinPlayersForZone(data.maxPlayers)
	if count < minPlayers then return end

	local isFull = (count >= data.maxPlayers)

	-- Jika sudah countdown dan sekarang penuh, percepat countdown
	if data.status == "countdown" and isFull and not data.countdownFull then
		data.countdownFull = true
		local fastTime = Config.PreGameCountdown or 4
		if data.countdownRemaining and data.countdownRemaining > fastTime then
			data.countdownRemaining = fastTime
		end
		return
	end

	-- Jika sudah countdown, jangan start lagi
	if data.status == "countdown" then return end

	data.status = "countdown"
	data.countdownFull = isFull
	updateZoneBillboard(zoneName)
	sendZoneInfoToAll()

	if data.countdownThread then
		task.cancel(data.countdownThread)
		data.countdownThread = nil
	end

	local countdownRemote = Remotes:WaitForChild(Config.Remotes.ZoneCountdown)
	local totalTime = isFull
		and (Config.PreGameCountdown or 4)
		or  (Config.PartialCountdown or 10)
	data.countdownRemaining = totalTime

	data.countdownThread = task.spawn(function()
		while data.countdownRemaining > 0 do
			local t = data.countdownRemaining

			-- Cek ulang jumlah pemain
			local cur = 0
			for _ in pairs(data.waitingList) do cur = cur + 1 end
			if cur < getMinPlayersForZone(data.maxPlayers) then
				-- Batalkan karena pemain kurang
				data.status = "waiting"
				data.countdownThread = nil
				data.countdownRemaining = nil
				data.countdownFull = nil
				updateZoneBillboard(zoneName)
				sendZoneInfoToAll()
				for p in pairs(data.waitingList) do
					countdownRemote:FireClient(p, 0)   -- 0 = batal
				end
				return
			end

			-- Update billboard setiap detik
			if data.billboardLabel then
				data.billboardLabel.Text = cur .. "/" .. data.maxPlayers
					.. "  —  Dimulai dalam " .. t .. "s"
			end
			for p in pairs(data.waitingList) do
				countdownRemote:FireClient(p, t)
			end

			task.wait(1)
			data.countdownRemaining = data.countdownRemaining - 1
		end

		data.countdownThread = nil
		data.countdownRemaining = nil
		data.countdownFull = nil

		-- Kumpulkan pemain final
		local playerList = {}
		for p in pairs(data.waitingList) do
			table.insert(playerList, p)
		end
		if #playerList < getMinPlayersForZone(data.maxPlayers) then
			data.status = "waiting"
			updateZoneBillboard(zoneName)
			return
		end

		-- ── PENTING: reset SEMUA slot.occupant dulu sebelum assign ulang
		-- Ini mencegah 2 orang masuk 1 kursi yang sama kalau game reset
		for _, slot in ipairs(data.seatSlots) do
			slot.occupant = nil
		end

		-- Gunakan posisi kursi PRE-COMPUTED saat zona didaftarkan (seatSlots)
		-- Shuffle indeks agar posisi duduk acak
		local slotIndices = {}
		for i = 1, #data.seatSlots do
			slotIndices[i] = i
		end
		for i = #slotIndices, 2, -1 do
			local j = math.random(i)
			slotIndices[i], slotIndices[j] = slotIndices[j], slotIndices[i]
		end

		-- Teleport tiap pemain ke kursi, 1 player per slot
		for i, p in ipairs(playerList) do
			local char = p.Character
			if char then
				local hrp     = char:FindFirstChild("HumanoidRootPart")
				local hum     = char:FindFirstChildOfClass("Humanoid")
				local slotIdx = slotIndices[i]
				local slot    = data.seatSlots[slotIdx]
				if hrp and slot then
					local slotCF  = slot.cframe
					local seatPos = slotCF.Position
					-- Tandai slot terpakai SEBELUM teleport
					slot.occupant = p
					-- Unanchor terlebih dulu agar physics engine menerimanya
					hrp.Anchored = false
					if hum then hum.Sit = false end  -- paksa berdiri dulu
					task.wait()
					-- Teleport ke posisi kursi
					hrp.CFrame = slotCF
					hrp.AssemblyLinearVelocity  = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
					-- Anchor agar tidak jatuh/melayang selama game
					hrp.Anchored = true
					-- Aktifkan animasi duduk
					if hum then
						task.defer(function()
							if hum and hum.Parent then
								hum.Sit = true
							end
						end)
					end
				end
			end
		end

		data.status = "playing"
		if data.prompt then
			data.prompt.Enabled = false
		end
		updateZoneBillboard(zoneName)
		sendZoneInfoToAll()

		-- Hentikan loop snap posisi (lockPlayerToSeat) tapi JANGAN berdirikan
		-- Player tetap duduk di kursi selama game berlangsung
		for _, p in ipairs(playerList) do
			if playerSeatLocks[p] then
				if type(playerSeatLocks[p]) == "thread" then
					task.cancel(playerSeatLocks[p])
				end
				playerSeatLocks[p] = nil
			end
			-- Pastikan tidak bisa jalan/lompat selama game
			local char = p.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					hum.WalkSpeed  = 0
					hum.JumpHeight = 0
				end
			end
		end

		-- Beritahu client: game dimulai (countdown -1)
		for _, p in ipairs(playerList) do
			countdownRemote:FireClient(p, -1)
		end

		task.wait(0.3)
		startGameEvent:Fire(zoneName, playerList)
	end)
end

-- ── Daftarkan satu Part sebagai zona ─────────────────────────
local function registerZonePart(part)
	if not part:IsA("BasePart") then return end

	local zoneName = part.Name
	local maxP     = part:GetAttribute("MaxPlayers") or Config.DefaultMaxPlayers

	-- Zona bersifat trigger: tidak boleh menghalangi pemain
	part.CanCollide  = false
	part.Anchored    = true
	-- Jadikan invisible di runtime (tetap terlihat di Studio saat edit)
	part.Transparency = 1

	-- Billboard di atas zona: hanya status pemain, tanpa nama zona
	local billboard = Instance.new("BillboardGui")
	billboard.Name             = "ZoneBillboard"
	billboard.Size             = UDim2.new(0, 160, 0, 30)
	billboard.StudsOffset      = Vector3.new(0, part.Size.Y / 2 + 1, 0)
	billboard.AlwaysOnTop      = false
	billboard.LightInfluence   = 0
	billboard.MaxDistance      = 55
	billboard.ClipsDescendants = false
	billboard.Parent           = part

	local bbLabel = Instance.new("TextLabel", billboard)
	bbLabel.Size                  = UDim2.new(1, 0, 1, 0)
	bbLabel.BackgroundTransparency = 1
	bbLabel.Font                  = Enum.Font.GothamBold
	bbLabel.TextColor3            = Color3.fromRGB(255, 255, 255)
	bbLabel.TextXAlignment        = Enum.TextXAlignment.Center
	bbLabel.TextScaled            = true
	bbLabel.TextStrokeColor3      = Color3.fromRGB(0, 0, 0)
	bbLabel.TextStrokeTransparency = 0.4
	bbLabel.Text                  = "0/" .. maxP .. "  —  Menunggu"

	-- Precompute posisi kursi (maks maxP kursi)
	local seatCFs = getSeatPositions(part, maxP)
	local seatSlots = {}
	for i, cf in ipairs(seatCFs) do
		local seatPart = part:FindFirstChild("Seat" .. i)
		table.insert(seatSlots, { cframe = cf, occupant = nil, seatPart = seatPart })
	end

	-- Nonaktifkan auto-sit pada Seat objects agar pemain tidak duduk saat lewat
	-- Seat:Sit(humanoid) tetap bisa dipanggil walau Disabled=true
	-- Anchor seat agar tidak melayang/turun karena physics
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("BasePart") then
			child.Anchored  = true   -- cegah seat turun karena physics
			child.CanCollide = false  -- tidak perlu collision
		end
		if child:IsA("Seat") or child:IsA("VehicleSeat") then
			child.Disabled = true
		end
	end

	zoneData[zoneName] = {
		part            = part,
		maxPlayers      = maxP,
		inside          = {},
		waitingList     = {},
		status          = "waiting",
		name            = zoneName,
		billboardLabel  = bbLabel,
		seatSlots       = seatSlots,
		countdownThread = nil,
		prompt          = nil,  -- diisi setelah ProximityPrompt dibuat
	}

	-- ── ProximityPrompt: tekan E untuk langsung Gabung ────────
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText             = "Gabung"
	prompt.ObjectText             = "Arena Duel"
	prompt.KeyboardKeyCode        = Enum.KeyCode.E
	prompt.HoldDuration           = 0
	prompt.MaxActivationDistance  = 20
	prompt.RequiresLineOfSight    = false
	prompt.Style                  = Enum.ProximityPromptStyle.Default
	prompt.Parent                 = part
	zoneData[zoneName].prompt     = prompt  -- simpan referensi

	prompt.Triggered:Connect(function(triggerPlayer)
		local zData = zoneData[zoneName]
		if not zData then return end
		-- Jangan proses kalau zona sedang bermain atau player sudah join
		if zData.status == "playing" then return end
		if zData.waitingList[triggerPlayer] then return end

		-- Validasi fisik: player harus di dalam zona (atau dalam jarak prompt)
		local tChar = triggerPlayer.Character
		if not tChar then return end

		-- Cek kapasitas
		local count = 0
		for _ in pairs(zData.waitingList) do count = count + 1 end
		if count >= zData.maxPlayers then return end

		zData.waitingList[triggerPlayer] = true

		-- Dudukkan dan kunci player di kursi kosong
		local hrp = tChar:FindFirstChild("HumanoidRootPart")
		local hum = tChar:FindFirstChildOfClass("Humanoid")
		if hrp and hum then
			local assigned = false
			for _, slot in ipairs(zData.seatSlots) do
				if slot.occupant == nil then
					slot.occupant = triggerPlayer
					assigned      = true
					hrp.Anchored  = false
					hum.Sit       = false
					task.wait()
					hrp.CFrame = slot.cframe
					hrp.AssemblyLinearVelocity  = Vector3.zero
					hrp.AssemblyAngularVelocity = Vector3.zero
					lockPlayerToSeat(triggerPlayer, slot.cframe)
					break
				end
			end
			if not assigned then
				warn("[ZoneManager] " .. triggerPlayer.Name .. " tidak dapat slot kursi! (ProximityPrompt)")
			end
		end

		-- Konfirmasi join ke client (agar ZoneGui update hasJoined)
		Remotes:WaitForChild(Config.Remotes.UpdateZoneInfo)
			:FireClient(triggerPlayer, { joinedZone = zoneName })

		-- Sembunyikan prompt saat zona penuh
		count = count + 1
		prompt.Enabled = (count < zData.maxPlayers) and (zData.status ~= "playing")

		updateZoneBillboard(zoneName)
		sendZoneInfoToAll()
		tryStartGame(zoneName)
	end)

	-- ── Touched: pemain kemungkinan masuk ────────────────────
	part.Touched:Connect(function(hit)
		local player = getPlayerFromPart(hit)
		if not player then return end
		local char   = player.Character
		if not char  then return end

		local data = zoneData[zoneName]
		if not data then return end
		if data.inside[player] then return end   -- sudah tercatat

		-- Validasi posisi HRP benar-benar di dalam bounding box
		if not isInsidePart(char, part) then return end

		data.inside[player] = true
		notifyEntered(player, zoneName)
		sendZoneInfoToPlayer(player)
	end)

	-- ── TouchEnded: kemungkinan pemain keluar ─────────────────
	part.TouchEnded:Connect(function(hit)
		local player = getPlayerFromPart(hit)
		if not player then return end
		local char   = player.Character
		if not char  then return end

		local data = zoneData[zoneName]
		if not data or not data.inside[player] then return end

		-- Delay lebih besar: cegah false-positive saat karakter bergerak
		task.delay(0.5, function()
			if not data.inside[player] then return end
			if char and isInsidePart(char, part, 3) then return end  -- margin 3 stud

			data.inside[player] = nil
			notifyLeft(player)
			sendZoneInfoToPlayer(player)
		end)
	end)

end

-- ── Scan semua Part yang sudah ada di folder Zones ───────────
for _, child in ipairs(zonesFolder:GetChildren()) do
	registerZonePart(child)
end

-- Support penambahan Part baru saat runtime
zonesFolder.ChildAdded:Connect(registerZonePart)

-- ── Heartbeat: validasi ulang setiap 2 detik ─────────────────
-- Jaga-jaga jika TouchEnded tidak ter-fire (lag, teleport, respawn)
local heartbeatTimer = 0
RunService.Heartbeat:Connect(function(dt)
	heartbeatTimer = heartbeatTimer + dt
	if heartbeatTimer < 2 then return end
	heartbeatTimer = 0

	for _, data in pairs(zoneData) do
		for player in pairs(data.inside) do
			local char = player.Character
			-- Margin 3 stud agar tidak bouncing di perbatasan
			if not char or not isInsidePart(char, data.part, 3) then
				data.inside[player] = nil
				notifyLeft(player)
			end
		end
	end
end)

-- ── Event: RequestJoinZone (tidak lagi dipakai oleh client setelah ProximityPrompt)
-- Tetap ada sebagai fallback/kompatibilitas eksternal, tapi diabaikan.
Remotes:WaitForChild(Config.Remotes.RequestJoinZone).OnServerEvent:Connect(function()
	-- Join sekarang diproses langsung via ProximityPrompt.Triggered di server.
	-- Remote ini tidak akan dikirim oleh ZoneGui client lagi.
end)

-- ── Event: player minta LEAVE zona ───────────────────────────
Remotes:WaitForChild(Config.Remotes.RequestLeaveZone).OnServerEvent:Connect(
	function(player, zoneName)
		local data = zoneData[zoneName]
		if not data then return end
		if not data.waitingList[player] then return end

		data.waitingList[player] = nil

		-- Bebaskan kursi dan lepas lock
		unlockPlayer(player)
		for _, slot in ipairs(data.seatSlots) do
			if slot.occupant == player then
				slot.occupant = nil
				break
			end
		end

		-- Batalkan hitungan mundur jika jumlah pemain kurang dari minimum
		if data.countdownThread then
			local cur = 0
			for _ in pairs(data.waitingList) do cur = cur + 1 end
			if cur < getMinPlayersForZone(data.maxPlayers) then
				task.cancel(data.countdownThread)
				data.countdownThread = nil
				data.countdownRemaining = nil
				data.countdownFull = nil
				data.status = "waiting"
				local countdownRemote = Remotes:WaitForChild(Config.Remotes.ZoneCountdown)
				for p in pairs(data.waitingList) do
					countdownRemote:FireClient(p, 0)  -- 0 = countdown batal
				end
			end
		end

		-- Re-aktifkan ProximityPrompt karena ada slot kosong
		if data.prompt and data.status ~= "playing" then
			data.prompt.Enabled = true
		end

		updateZoneBillboard(zoneName)
		sendZoneInfoToAll()
	end
)

-- ── Reset zona setelah game selesai ──────────────────────────
local resetFunc     = Instance.new("BindableFunction")
resetFunc.Name      = "_ResetZone"
resetFunc.Parent    = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
resetFunc.OnInvoke  = function(zoneName)
	local data = zoneData[zoneName]
	if not data then return end
	if data.countdownThread then
		task.cancel(data.countdownThread)
		data.countdownThread = nil
	end
	for p in pairs(data.waitingList) do
		unlockPlayer(p)
	end
	data.waitingList = {}
	data.status      = "waiting"
	for _, slot in ipairs(data.seatSlots) do
		slot.occupant = nil
	end
	-- Re-aktifkan ProximityPrompt setelah game selesai
	if data.prompt then
		data.prompt.Enabled = true
	end
	updateZoneBillboard(zoneName)
	sendZoneInfoToAll()
	-- Re-notify pemain yang masih fisik di zona agar card muncul kembali
	for p in pairs(data.inside) do
		notifyEntered(p, zoneName)
	end
end

-- ── Bersihkan saat player disconnect ─────────────────────────
Players.PlayerRemoving:Connect(function(player)
	unlockPlayer(player)
	for _, data in pairs(zoneData) do
		data.inside[player]      = nil
		data.waitingList[player] = nil
		for _, slot in ipairs(data.seatSlots) do
			if slot.occupant == player then
				slot.occupant = nil
			end
		end
	end
end)

-- Kirim info zona saat player pertama join
Players.PlayerAdded:Connect(function(player)
	task.wait(2)
	sendZoneInfoToPlayer(player)
end)