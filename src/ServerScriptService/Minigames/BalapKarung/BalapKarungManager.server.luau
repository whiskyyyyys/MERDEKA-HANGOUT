-- ============================================================
-- BalapKarungManager.server.luau
-- Mengatur logika server untuk minigame Balap Karung
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Pastikan folder Minigames dan BalapKarung ada di ReplicatedStorage
local minigamesFolder = ReplicatedStorage:FindFirstChild("Minigames")
if not minigamesFolder then
	minigamesFolder = Instance.new("Folder")
	minigamesFolder.Name = "Minigames"
	minigamesFolder.Parent = ReplicatedStorage
end

local balapKarungFolder = minigamesFolder:FindFirstChild("BalapKarung")
if not balapKarungFolder then
	balapKarungFolder = Instance.new("Folder")
	balapKarungFolder.Name = "BalapKarung"
	balapKarungFolder.Parent = minigamesFolder
end

local eventsFolder = balapKarungFolder:FindFirstChild("Events")
if not eventsFolder then
	eventsFolder = Instance.new("Folder")
	eventsFolder.Name = "Events"
	eventsFolder.Parent = balapKarungFolder
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
local ShowUIEvent = getOrCreateEvent("RemoteEvent", "ShowUI")
local HideUIEvent = getOrCreateEvent("RemoteEvent", "HideUI")
local GameEndEvent = getOrCreateEvent("RemoteEvent", "GameEndEvent")
local RequestJumpEvent = getOrCreateEvent("RemoteEvent", "RequestJump")

local activePlayers = {} -- Melacak pemain yang masih lari
local participatingPlayers = {} -- Melacak SEMUA pemain yang ikut balapan (termasuk yang sudah finish)
local winners = {}
local isGameRunning = false

-- ─────────────────────────────────────────────────────────
-- SISTEM KARUNG (ASSET ID)
-- ─────────────────────────────────────────────────────────
local karungCache = nil
task.spawn(function()
	pcall(function()
		local InsertService = game:GetService("InsertService")
		local model = InsertService:LoadAsset(10146434580)
		if model then
			karungCache = model:GetChildren()[1]
			print("[BalapKarung] Asset karung berhasil dimuat:", karungCache.ClassName)
		end
	end)
end)

local function equipKarung(char)
	if not karungCache then return end
	if karungCache:IsA("Accessory") then
		local clone = karungCache:Clone()
		clone.Name = "KarungAksesoris"
		local hum = char:FindFirstChild("Humanoid")
		if hum then hum:AddAccessory(clone) end
	elseif karungCache:IsA("Pants") then
		local currentPants = char:FindFirstChildOfClass("Pants")
		if currentPants then
			char:SetAttribute("OldPants", currentPants.PantsTemplate)
			currentPants.PantsTemplate = karungCache.PantsTemplate
		else
			char:SetAttribute("OldPants", "NONE")
			local clone = karungCache:Clone()
			clone.Parent = char
		end
	elseif karungCache:IsA("Shirt") then
		local currentShirt = char:FindFirstChildOfClass("Shirt")
		if currentShirt then
			char:SetAttribute("OldShirt", currentShirt.ShirtTemplate)
			currentShirt.ShirtTemplate = karungCache.ShirtTemplate
		else
			char:SetAttribute("OldShirt", "NONE")
			local clone = karungCache:Clone()
			clone.Parent = char
		end
	end
end

local function unequipKarung(char)
	local acc = char:FindFirstChild("KarungAksesoris")
	if acc then acc:Destroy() end
	
	local oldPants = char:GetAttribute("OldPants")
	if oldPants then
		local currentPants = char:FindFirstChildOfClass("Pants")
		if oldPants == "NONE" then
			if currentPants then currentPants:Destroy() end
		elseif currentPants then
			currentPants.PantsTemplate = oldPants
		end
		char:SetAttribute("OldPants", nil)
	end
	
	local oldShirt = char:GetAttribute("OldShirt")
	if oldShirt then
		local currentShirt = char:FindFirstChildOfClass("Shirt")
		if oldShirt == "NONE" then
			if currentShirt then currentShirt:Destroy() end
		elseif currentShirt then
			currentShirt.ShirtTemplate = oldShirt
		end
		char:SetAttribute("OldShirt", nil)
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
-- INISIALISASI GAME
-- ─────────────────────────────────────────────────────────
StartGameBindable.Event:Connect(function(...)
	local padGroups = {...}
	
	if isGameRunning then return end
	isGameRunning = true
	activePlayers = {}
	participatingPlayers = {}
	winners = {}
	
	print("[BalapKarung] Game Dimulai! Menyiapkan pemain...")
	
	-- padGroups berisi array dari semua pad di arena ini
	-- Untuk Balap Karung, kita gabungkan semua pemain yang ikut
	local allPlayers = {}
	for _, padPlayers in ipairs(padGroups) do
		for _, player in ipairs(padPlayers) do
			table.insert(allPlayers, player)
			activePlayers[player] = true
			participatingPlayers[player] = true
		end
	end
	
	local arena = workspace:FindFirstChild("BalapKarungArena")
	local startLine = arena and arena:FindFirstChild("StartLine")
	local spawnsFolder = arena and arena:FindFirstChild("Spawns")
	
	for i, player in ipairs(allPlayers) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local hrp = char.HumanoidRootPart
			local hum = char:FindFirstChild("Humanoid")
			
			-- Hentikan pergerakan normal
			if hum then
				hum.WalkSpeed = 0
				hum.JumpPower = 0
				hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
			end
			
			-- Pakaikan Karung
			equipKarung(char)
			
			-- Teleport ke titik spawn
			if spawnsFolder and spawnsFolder:FindFirstChild("Spawn" .. i) then
				local spawnPart = spawnsFolder:FindFirstChild("Spawn" .. i)
				hrp.CFrame = spawnPart.CFrame + Vector3.new(0, 3, 0)
			elseif startLine then
				-- Fallback otomatis jika tidak ada folder Spawns
				local offset = Vector3.new((i - 1) * 4, 3, 0) -- Jejerkan pemain jarak 4 stud
				hrp.CFrame = startLine.CFrame * CFrame.new(offset)
			end
			
			hrp.Anchored = true
			showServerCountdown(player)
		end
	end
	
	task.wait(5)
	
	for _, player in ipairs(allPlayers) do
		local char = player.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			char.HumanoidRootPart.Anchored = false
			-- Tampilkan UI Minigame
			ShowUIEvent:FireClient(player)
		end
	end
end)

-- ─────────────────────────────────────────────────────────
-- LOGIKA LOMPAT
-- ─────────────────────────────────────────────────────────
-- Menerima request lompat dari client (kekuatan sweet spot 0.1 - 1.0)
RequestJumpEvent.OnServerEvent:Connect(function(player, power)
	if not isGameRunning or not activePlayers[player] then return end
	
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local hrp = char.HumanoidRootPart
		
		-- Physics sekarang ditangani langsung oleh Client (BalapKarungUI)
		-- Server hanya menerima event untuk verifikasi (jika perlu)
	end
end)

-- ─────────────────────────────────────────────────────────
-- KONDISI MENANG (FINISH LINE)
-- ─────────────────────────────────────────────────────────
-- Kita buat listener untuk FinishLine secara dinamis
task.spawn(function()
	local arena = workspace:WaitForChild("BalapKarungArena", 10)
	if not arena then
		warn("[BalapKarung] BalapKarungArena tidak ditemukan di workspace!")
		return
	end
	
	local finishLine = arena:WaitForChild("FinishLine", 5)
	if finishLine then
		finishLine.Touched:Connect(function(hit)
			if not isGameRunning then return end
			
			-- Cari model karakter teratas (karena kadang yang kena adalah aksesoris/topi)
			local char = hit:FindFirstAncestorOfClass("Model")
			local player = char and Players:GetPlayerFromCharacter(char)
			
			if player and activePlayers[player] then
				-- Tandai pemain ini sudah sampai
				activePlayers[player] = nil
				
				-- Kunci karakter di garis finish agar tidak bisa gerak tapi bisa melihat
				if char:FindFirstChild("HumanoidRootPart") then
					char.HumanoidRootPart.Anchored = true
				end
				
				-- Masukkan ke daftar juara (Maksimal 3 orang)
				if #winners < 3 then
					table.insert(winners, player.Name)
					print("[BalapKarung] Juara " .. #winners .. ": " .. player.Name)
				end
				
				-- Hitung sisa pemain yang belum finish
				local remainingPlayers = 0
				for _, _ in pairs(activePlayers) do
					remainingPlayers = remainingPlayers + 1
				end
				
				-- Jika sudah ada 3 juara ATAU semua pemain sudah finish, akhiri game
				if #winners >= 3 or remainingPlayers == 0 then
					isGameRunning = false
					print("[BalapKarung] Balapan Selesai! Mengumumkan juara...")
					
					-- Sistem Coin Reward (pakai CoinService yang sama dengan SambungKata)
					local coinRewards = {150, 100, 50} -- Juara 1, 2, 3
					local addCashFunc = ReplicatedStorage:FindFirstChild("_AddCash")
					
					local rewardData = {} -- {playerName = coinAmount}
					
					local updateWinsFunc = ReplicatedStorage:FindFirstChild("_BalapKarungUpdateWins")
					local updateLossesFunc = ReplicatedStorage:FindFirstChild("_BalapKarungUpdateLosses")
					local addSpinsFunc = ReplicatedStorage:FindFirstChild("_AddSpins")
					
					-- 1. Beri hadiah Coin dan status Win ke para pemenang
					for rank, winnerName in ipairs(winners) do
						local reward = coinRewards[rank] or 25
						rewardData[winnerName] = reward
						
						-- Cari player object dari nama
						local winnerPlayer = nil
						for p, _ in pairs(participatingPlayers) do
							if p.Name == winnerName then
								winnerPlayer = p
								break
							end
						end
						
						-- Berikan cash melalui CashService
						if winnerPlayer and addCashFunc then
							pcall(function()
								addCashFunc:Invoke(winnerPlayer, reward, "Balap Karung Juara " .. rank)
							end)
							print("[BalapKarung] " .. winnerName .. " mendapat " .. reward .. " cash (Juara " .. rank .. ")")
						end
						
						-- Tambah jumlah Win di Leaderboard
						if winnerPlayer and updateWinsFunc then
							pcall(function() updateWinsFunc:Invoke(winnerPlayer.UserId, 1) end)
						end
						
						-- Tambah Tiket Spin Khusus Juara 1
						if winnerPlayer and addSpinsFunc and rank == 1 then
							pcall(function() addSpinsFunc:Invoke(winnerPlayer, 1) end)
							print("[BalapKarung] " .. winnerName .. " mendapat 1 Spin Ticket (Juara 1)")
						end
					end
					
					-- 2. Beri status Loss ke pemain yang tidak juara
					for p, _ in pairs(participatingPlayers) do
						local isWinner = false
						for _, wName in ipairs(winners) do
							if p.Name == wName then isWinner = true break end
						end
						if not isWinner and updateLossesFunc then
							pcall(function() updateLossesFunc:Invoke(p.UserId, 1) end)
						end
					end
					
					-- Kirim event selesai beserta list juara + data coin ke SEMUA peserta
					for p, _ in pairs(participatingPlayers) do
						GameEndEvent:FireClient(p, winners, rewardData)
					end
					
					-- Tunggu 5 detik untuk show UI kemenangan
					task.wait(5)
					
					-- Cari part endgame untuk teleport keluar
					local outPart = arena:FindFirstChild("endgame")
					if not outPart then
						outPart = Instance.new("Part")
						outPart.Name = "endgame"
						local startL = arena:FindFirstChild("StartLine")
						outPart.Position = startL and (startL.Position + Vector3.new(0, 5, -30)) or Vector3.new(0, 5, -30)
						outPart.Anchored = true
						outPart.CanCollide = false
						outPart.Transparency = 1
						outPart.Parent = arena
						print("[BalapKarung] Membuat part 'endgame' otomatis.")
					end
					
					-- Teleport semua peserta ke titik endgame dan normalkan karakternya
					for p, _ in pairs(participatingPlayers) do
						local pChar = p.Character
						if pChar and pChar:FindFirstChild("Humanoid") then
							pChar.Humanoid.WalkSpeed = 16
							pChar.Humanoid.JumpPower = 50
							pChar.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
							
							-- Lepas Karung
							unequipKarung(pChar)
							
							if pChar:FindFirstChild("HumanoidRootPart") then
								pChar.HumanoidRootPart.Anchored = false
								local randomOffset = Vector3.new(math.random(-10, 10), 3, math.random(-10, 10))
								pChar.HumanoidRootPart.CFrame = outPart.CFrame + randomOffset
							end
						end
						
						-- Tidak perlu mengembalikan GUI di sini karena sudah ditangani secara terpusat oleh PadManagers
					end
					
					-- Bersihkan data
					participatingPlayers = {}
					winners = {}
					
					-- Buka kembali arena
					if arena then arena:SetAttribute("IsPlaying", false) end
				end
			end
		end)
	else
		warn("[BalapKarung] FinishLine tidak ditemukan di dalam BalapKarungArena!")
	end
end)
