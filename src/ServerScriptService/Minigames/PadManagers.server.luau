local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Packets = require(ReplicatedStorage.Modules.Packets)

local MIN_PLAYERS = 1 -- Diubah ke 1 untuk testing
local COUNTDOWN_START = 15

local PlayersPads = {} -- [Player] = Pad Instance
local Arenas = {} -- Menyimpan state setiap arena

-- ─────────────────────────────────────────────────────────
-- 1. SETUP ARENA
-- ─────────────────────────────────────────────────────────
for _, child in ipairs(workspace:GetChildren()) do
	-- Cari model yang berakhiran "Arena" (contoh: TarikTambangArena, BalapKarungArena)
	if child:IsA("Model") and string.match(child.Name, "Arena$") then
		local padsFolder = child:FindFirstChild("zone") or child:FindFirstChild("Zone") or child:FindFirstChild("Pads")
		if padsFolder then
			print("[PadManager] Menemukan arena:", child.Name)
			Arenas[child.Name] = {
				Model = child,
				Pads = padsFolder:GetChildren(),
				Countdown = COUNTDOWN_START,
				IsCountingDown = false,
				Name = child.Name,
				PlayingPlayers = {}
			}
			
			child:GetAttributeChangedSignal("IsPlaying"):Connect(function()
				if not child:GetAttribute("IsPlaying") then
					local arena = Arenas[child.Name]
					if arena and arena.PlayingPlayers then
						for _, p in ipairs(arena.PlayingPlayers) do
							if p:FindFirstChild("PlayerGui") then
								for _, gui in ipairs(p.PlayerGui:GetChildren()) do
									if gui:IsA("ScreenGui") and gui:GetAttribute("WasEnabled") then
										gui.Enabled = true
										gui:SetAttribute("WasEnabled", nil)
									end
								end
							end
						end
						arena.PlayingPlayers = {}
					end
				end
			end)
		end
	end
end

local function UpdatePadsCountdown(arena, value)
	for _, pad in ipairs(arena.Pads) do
		pad:SetAttribute("Countdown", value)
	end
end

-- ─────────────────────────────────────────────────────────
-- 2. MEMULAI MINIGAME SESUAI ARENA
-- ─────────────────────────────────────────────────────────
local function StartMinigame(arena)
	print("[PadManager] Memulai game di arena:", arena.Name)
	
	-- Pisahkan pemain berdasarkan pad mana yang mereka injak
	local padPlayersMap = {} -- [Pad] = {player1, player2...}
	for _, pad in ipairs(arena.Pads) do
		padPlayersMap[pad] = {}
	end
	
	-- Data pemain untuk dikirim ke script minigame
	local allPlayersInArena = {}
	local playersByPad = {} -- array of arrays
	
	for player, pad in pairs(PlayersPads) do
		-- Cek apakah pad ini milik arena yang mau mulai
		if pad.Parent and pad.Parent.Parent == arena.Model then
			table.insert(padPlayersMap[pad], player)
			table.insert(allPlayersInArena, player)
		end
	end
	
	for _, pad in ipairs(arena.Pads) do
		table.insert(playersByPad, padPlayersMap[pad])
	end
	
	-- Panggil event khusus berdasarkan nama Arena
	local rsMinigames = ReplicatedStorage:FindFirstChild("Minigames")
	if rsMinigames then
		-- Hapus kata "Arena" dan hilangkan spasi kosong di ujung nama
		local minigameName = string.gsub(arena.Name, "Arena", "")
		minigameName = string.match(minigameName, "^%s*(.-)%s*$")
		
		print("[PadManager] Nama arena asli:", arena.Name, "-> minigame:", minigameName)
		
		local minigameFolder = rsMinigames:FindFirstChild(minigameName)
		
		-- Fallback: coba tanpa spasi sama sekali (misal "Pecah Air" -> "PecahAir")
		if not minigameFolder then
			local noSpaceName = string.gsub(minigameName, "%s+", "")
			print("[PadManager] Mencoba tanpa spasi:", noSpaceName)
			minigameFolder = rsMinigames:FindFirstChild(noSpaceName)
		end
		
		-- Fallback: cari di semua children secara case-insensitive
		if not minigameFolder then
			local lowerName = string.lower(string.gsub(minigameName, "%s+", ""))
			for _, child in ipairs(rsMinigames:GetChildren()) do
				if string.lower(string.gsub(child.Name, "%s+", "")) == lowerName then
					minigameFolder = child
					print("[PadManager] Ditemukan via case-insensitive:", child.Name)
					break
				end
			end
		end
		
		if minigameFolder then
			local events = minigameFolder:FindFirstChild("Events")
			if events then
				local startEvent = events:FindFirstChild("StartGame")
				if startEvent and startEvent:IsA("BindableEvent") then
					-- Kirim array of arrays (semua pad dan pemainnya)
					-- Jika TarikTambang: playersByPad[1] adalah merah, playersByPad[2] putih
					print("[PadManager] Firing StartGame untuk", minigameFolder.Name, "dengan", #allPlayersInArena, "pemain")
					
					-- Kunci arena ini
					arena.Model:SetAttribute("IsPlaying", true)
					
					startEvent:Fire(table.unpack(playersByPad))
				else
					warn("[PadManager] StartGame BindableEvent tidak ditemukan di Events folder:", minigameFolder.Name)
				end
			else
				warn("[PadManager] Events folder tidak ditemukan di dalam:", minigameFolder.Name)
			end
		else
			warn("[PadManager] Folder minigame tidak ditemukan di ReplicatedStorage:", minigameName)
			-- Debug: tampilkan semua folder yang ada
			local folderNames = {}
			for _, child in ipairs(rsMinigames:GetChildren()) do
				table.insert(folderNames, child.Name)
			end
			warn("[PadManager] Folder yang tersedia:", table.concat(folderNames, ", "))
		end
	end
	
	arena.PlayingPlayers = {}
	for _, player in ipairs(allPlayersInArena) do
		table.insert(arena.PlayingPlayers, player)
	end
	
	-- Bersihkan pemain dari Pad arena ini
	for _, player in ipairs(allPlayersInArena) do
		if player.Character then
			player.Character:SetAttribute("InPad", false)
		end
		if player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("LobbyGui") then
			player.PlayerGui.LobbyGui.Enabled = false
		end
		PlayersPads[player] = nil
	end
	
	-- Reset jumlah pemain di pad
	for _, pad in ipairs(arena.Pads) do
		pad:SetAttribute("Players", 0)
	end
end

-- ─────────────────────────────────────────────────────────
-- 3. GLOBAL LOOP (Cek semua arena secara independen)
-- ─────────────────────────────────────────────────────────
task.spawn(function()
	while true do
		task.wait(1)
		
		for _, arena in pairs(Arenas) do
			local readyPadsCount = 0
			local firstPadCount = nil
			local isBalanced = true
			
			for _, pad in ipairs(arena.Pads) do
				local pCount = pad:GetAttribute("Players") or 0
				if pCount >= MIN_PLAYERS then
					readyPadsCount = readyPadsCount + 1
				end
				
				-- Cek apakah jumlah pemain sama di semua pad (balance)
				if firstPadCount == nil then
					firstPadCount = pCount
				elseif firstPadCount ~= pCount then
					isBalanced = false
				end
			end
			
			-- Syarat: 
			-- 1. Semua pad di arena ini memenuhi batas minimum
			-- 2. Jika Tarik Tambang (yang butuh 2 tim), jumlah pemain di kedua pad harus SAMA.
			local canStart = (readyPadsCount >= #arena.Pads and #arena.Pads > 0)
			
			if string.match(arena.Name, "TarikTambang") and not isBalanced then
				canStart = false
			end
			
			if canStart then
				arena.IsCountingDown = true
				arena.Countdown = arena.Countdown - 1
				UpdatePadsCountdown(arena, arena.Countdown)
				
				if arena.Countdown <= 0 then
					StartMinigame(arena)
					arena.Countdown = COUNTDOWN_START
					arena.IsCountingDown = false
					UpdatePadsCountdown(arena, arena.Countdown)
				end
			else
				if arena.IsCountingDown or arena.Countdown < COUNTDOWN_START then
					arena.IsCountingDown = false
					arena.Countdown = COUNTDOWN_START
					UpdatePadsCountdown(arena, arena.Countdown)
				end
			end
		end
	end
end)

-- ─────────────────────────────────────────────────────────
-- 4. EVENT LISTENER TOUCH PAD (Untuk semua arena)
-- ─────────────────────────────────────────────────────────
for _, arena in pairs(Arenas) do
	for _, Pad in ipairs(arena.Pads) do
		local PadHitbox = Pad:FindFirstChild("Hitbox")
		if not PadHitbox then continue end
		
		local BillboardGui = Pad:FindFirstChild("Pad") and Pad.Pad:FindFirstChild("BillboardAttachment") and Pad.Pad.BillboardAttachment:FindFirstChild("BillboardGui")
		if not BillboardGui then continue end
		
		local PlayersText = BillboardGui:FindFirstChild("PlayersText")
		local CountdownText = BillboardGui:FindFirstChild("Countdown")
	
		PadHitbox.Touched:Connect(function(Hit)
			if arena.Model:GetAttribute("IsPlaying") then return end
			if not Hit.Parent:FindFirstChild("Humanoid") then return end
			if Hit.Parent:GetAttribute("InPad") then return end
	
			local Character = Hit.Parent
			local Player = Players:GetPlayerFromCharacter(Character)
			local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
			if not Player or not HumanoidRootPart then return end
	
			local PlayersInPad = Pad:GetAttribute("Players") or 0
			local MaxPlayers = Pad:GetAttribute("MaxPlayers") or 10
	
			if PlayersInPad >= MaxPlayers then return end
	
			Character:SetAttribute("InPad", true)
			PlayersPads[Player] = Pad
			HumanoidRootPart.CFrame = Pad.Pad.CFrame
			Pad:SetAttribute("Players", PlayersInPad + 1)
			
			if Player:FindFirstChild("PlayerGui") then
				local hideList = {"BackpackGui", "CoinTopbar", "MainMenu", "SettingsClient", "CashShopClient"}
				for _, guiName in ipairs(hideList) do
					local gui = Player.PlayerGui:FindFirstChild(guiName)
					if gui and gui:IsA("ScreenGui") then
						if gui.Enabled then
							gui:SetAttribute("WasEnabled", true)
							gui.Enabled = false
						end
					end
				end
				if Player.PlayerGui:FindFirstChild("LobbyGui") then
					Player.PlayerGui.LobbyGui.Enabled = true
				end
			end
		end)
	
		Pad:GetAttributeChangedSignal("Players"):Connect(function()
			local CurrentPlayers = Pad:GetAttribute("Players") or 0
			local MaxPlayers = Pad:GetAttribute("MaxPlayers") or 10
			if PlayersText then
				PlayersText.Text = "Players " .. CurrentPlayers .. "/" .. MaxPlayers
			end
		end)
	
		Pad:GetAttributeChangedSignal("Countdown"):Connect(function()
			if CountdownText then
				CountdownText.Text = Pad:GetAttribute("Countdown")
			end
		end)
		
		local initCur = Pad:GetAttribute("Players") or 0
		local initMax = Pad:GetAttribute("MaxPlayers") or 10
		if PlayersText then PlayersText.Text = "Players " .. initCur .. "/" .. initMax end
		if CountdownText then CountdownText.Text = Pad:GetAttribute("Countdown") or 15 end
	end
end

-- ─────────────────────────────────────────────────────────
-- 5. KELUAR DARI PAD (Leave Button / DC)
-- ─────────────────────────────────────────────────────────
Packets.Leave.OnServerEvent:Connect(function(Player: Player)
	local Character = Player.Character
	if not Character or not Character:GetAttribute("InPad") then return end

	local Pad = PlayersPads[Player]
	if not Pad then return end

	local OutPart = Pad:FindFirstChild("Out")
	local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
	if not HumanoidRootPart then return end

	if OutPart then
		HumanoidRootPart.CFrame = OutPart.CFrame
	else
		-- Fallback jika part "Out" belum dibuat di dalam model Pad
		local padPart = Pad:FindFirstChild("Pad")
		if padPart then
			HumanoidRootPart.CFrame = padPart.CFrame * CFrame.new(0, 3, 10)
		end
	end

	local currentPlayers = Pad:GetAttribute("Players") or 1
	Pad:SetAttribute("Players", math.max(currentPlayers - 1, 0))

	Character:SetAttribute("InPad", false)
	PlayersPads[Player] = nil
	if Player.PlayerGui:FindFirstChild("LobbyGui") then
		Player.PlayerGui.LobbyGui.Enabled = false
	end
	
	-- Munculkan kembali GUI lainnya
	if Player:FindFirstChild("PlayerGui") then
		for _, gui in ipairs(Player.PlayerGui:GetChildren()) do
			if gui:IsA("ScreenGui") and gui:GetAttribute("WasEnabled") then
				gui.Enabled = true
				gui:SetAttribute("WasEnabled", nil)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(Player)
	local Pad = PlayersPads[Player]
	if Pad then
		local currentPlayers = Pad:GetAttribute("Players") or 1
		Pad:SetAttribute("Players", math.max(currentPlayers - 1, 0))
	end
	PlayersPads[Player] = nil
end)
