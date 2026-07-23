-- ============================================================
-- GameManager.server.lua
-- Script → ServerScriptService/GameManager
-- Logika utama game Sambung Kata (Bahasa Indonesia): giliran, validasi, HP, menang
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

-- ── Setup Remotes & Modules ──────────────────────────────────
local function getOrCreate(parent, class, name)
	local obj = parent:FindFirstChild(name)
	if not obj then
		obj = Instance.new(class)
		obj.Name = name
		obj.Parent = parent
	end
	return obj
end

local Modules     = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Modules")
local Config      = require(Modules:WaitForChild("GameConfig"))

-- IndonesianWords di ServerStorage supaya tidak bisa diakses client/exploiter
local ServerStorage = game:GetService("ServerStorage")
local ServerModules = ServerStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
local Words         = require(ServerModules:WaitForChild("IndonesianWords"))

-- Buat folder Remotes jika belum ada
local RSMinigame = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
local remotesFolder = getOrCreate(RSMinigame, "Folder", "Remotes")

-- Buat semua RemoteEvent
for _, rName in pairs(Config.Remotes) do
	getOrCreate(remotesFolder, "RemoteEvent", rName)
end
-- Hardcode remote index yang mungkin hilang dari GameConfig
getOrCreate(remotesFolder, "RemoteEvent", "WordDiscovered")
getOrCreate(remotesFolder, "RemoteFunction", "GetMyIndex")
getOrCreate(remotesFolder, "RemoteFunction", "GetMyIndexByLetter")

-- BindableEvent/Function dibuat oleh ZoneManager, kita tunggu saja
local startGameEvent = RSMinigame:WaitForChild("_StartGame")
local resetZoneFunc  = RSMinigame:WaitForChild("_ResetZone")

-- ── Shortcut Remote ─────────────────────────────────────────
local R = {}
for key, rName in pairs(Config.Remotes) do
	R[key] = remotesFolder:WaitForChild(rName)
end

-- ── State per zona yang sedang bermain ──────────────────────
-- activeSessions[zoneName] = {
--   players     = { Player, ... }  (urutan giliran)
--   hp          = { [Player] = number }
--   wrongCount  = { [Player] = number }  -- salah berturut di giliran ini
--   currentWord = string   (kata terakhir yang diucapkan)
--   currentIdx  = number   (indeks pemain yang sedang giliran)
--   usedWords   = { [word] = true }  (kata yang sudah dipakai)
--   timerThread = thread
--   spectators  = { [Player] = true }
--   wordCount   = { [Player] = number }  -- jumlah kata benar per pemain
--   startTime   = tick()  -- waktu mulai game
-- }
local activeSessions = {}
local sessionCounter  = 0   -- auto-increment, unik per game session

-- BindableFunction untuk coin & stats (dari CoinService)
local addCashFunc  -- akan di-assign saat tersedia
local addWinFunc
local addLossFunc
local unlockPlayerFunc
local removePlayerFromZoneFunc
task.spawn(function()
	addCashFunc       = ReplicatedStorage:WaitForChild("_AddCash", 10)
	addWinFunc         = RSMinigame:WaitForChild("_AddWin", 10)
	addLossFunc        = RSMinigame:WaitForChild("_AddLoss", 10)
	unlockPlayerFunc   = RSMinigame:WaitForChild("_UnlockPlayer", 10)
	removePlayerFromZoneFunc = RSMinigame:WaitForChild("_RemovePlayerFromZone", 10)
end)

-- ── Utilitas ─────────────────────────────────────────────────
local function fireAll(session, remoteName, ...)
	local remote = R[remoteName]
	if not remote then return end
	for _, p in ipairs(session.players) do
		remote:FireClient(p, ...)
	end
	for p in pairs(session.spectators) do
		remote:FireClient(p, ...)
	end
end

-- Broadcast ke SEMUA player di server (agar penonton bisa lihat billboard)
local function fireEveryone(remoteName, ...)
	local remote = R[remoteName]
	if not remote then return end
	for _, p in ipairs(Players:GetPlayers()) do
		remote:FireClient(p, ...)
	end
end

local function countAlive(session)
	local n = 0
	for _, p in ipairs(session.players) do
		if session.hp[p] and session.hp[p] > 0 then
			n = n + 1
		end
	end
	return n
end

local function getNextAliveIdx(session)
	local total = #session.players
	local idx   = session.currentIdx
	for _ = 1, total do
		idx = (idx % total) + 1
		local p = session.players[idx]
		if session.hp[p] and session.hp[p] > 0 then
			return idx
		end
	end
	return nil
end

-- ── Cek valid chain: kata baru harus diawali akhiran kata lama ─
-- Pemain boleh ambil 1 atau 2 huruf dari akhir kata sebelumnya
local function isValidChain(prevWord, newWord)
	local maxTake = math.min(2, math.max(1, #prevWord))
	for take = maxTake, 1, -1 do
		local suffix = prevWord:sub(#prevWord - take + 1)
		if newWord:sub(1, take) == suffix then
			return true, suffix
		end
	end
	return false, nil
end

-- ── Akhiri giliran (timeout atau salah max) ──────────────────
local function normalizeWord(rawWord)
	if type(rawWord) ~= "string" then
		return ""
	end
	local word = (rawWord:lower():match("^%s*(.-)%s*$") or "")
	word = word:gsub("%s+", "")
	word = word:gsub("[^a-z]", "")
	return word
end

local function handleLoseHP(session, player, zoneName)
	if not session.hp[player] then return end  -- Player sudah disconnect
	session.wrongCount[player] = 0

	-- Kurangi HP
	session.hp[player] = session.hp[player] - 1
	R.UpdateHP:FireClient(player, session.hp[player])

	if session.hp[player] <= 0 then
		-- Player gugur
		session.spectators[player] = true

		-- Hapus dari players aktif
		for i, p in ipairs(session.players) do
			if p == player then
				table.remove(session.players, i)
				break
			end
		end

		-- Unlock player dari kursi agar bisa jalan bebas sebagai penonton
		if unlockPlayerFunc then
			pcall(function() unlockPlayerFunc:Invoke(player) end)
		end

		-- Lepaskan juga dari state zone lama agar reset game lama
		-- tidak membuka movement saat pemain sudah ikut game baru.
		if removePlayerFromZoneFunc then
			pcall(function() removePlayerFromZoneFunc:Invoke(zoneName, player) end)
		end

		R.PlayerEliminated:FireClient(player, zoneName, session.sessionId, player.Name)
		fireEveryone("PlayerEliminated", zoneName, session.sessionId, player.Name)

		-- Sesuaikan idx
		if session.currentIdx > #session.players then
			session.currentIdx = #session.players
		end
		if session.currentIdx < 1 then session.currentIdx = 1 end
	end
end

-- ── Cek kondisi menang ───────────────────────────────────────
local function checkWinner(session, zoneName)
	local alive = countAlive(session)
	if alive <= 1 then
		local winner = nil
		for _, p in ipairs(session.players) do
			if session.hp[p] and session.hp[p] > 0 then
				winner = p
				break
			end
		end
		local winName = winner and winner.Name or "Tidak ada"
		fireEveryone("GameEnded", zoneName, session.sessionId, winName)

		-- ── Reward Coin ──────────────────────────────────────
		if addCashFunc then
			local elapsed = tick() - (session.startTime or tick())
			local coinCfg = Config.Coin or {}

			-- Reward pemenang
			if winner then
				local base = math.random(
					coinCfg.BaseWinMin or 5,
					coinCfg.BaseWinMax or 15
				)
				local wordBonus = (session.wordCount[winner] or 0) * (coinCfg.PerWordBonus or 2)
				local speedBonus = 0
				if elapsed < 60 then
					speedBonus = coinCfg.SpeedBonusFast or 5
				elseif elapsed < 120 then
					speedBonus = coinCfg.SpeedBonusMedium or 3
				end
				local total = base + wordBonus + speedBonus
				addCashFunc:Invoke(winner, total, "Sambung Kata Juara (" .. (session.wordCount[winner] or 0) .. " kata, " .. math.floor(elapsed) .. "s)")

				local addSpinsFunc = ReplicatedStorage:FindFirstChild("_AddSpins")
				if addSpinsFunc then
					pcall(function() addSpinsFunc:Invoke(winner, 1) end)
					print("[SambungKata] " .. winner.Name .. " mendapat 1 Spin Ticket!")
				end

				-- Kirim detail reward ke winner untuk NotificationWin GUI
				R.WinNotif:FireClient(winner, {
					isWinner     = true,
					winBonus     = base + speedBonus,
					correctBonus = wordBonus,
					totalCoins   = total,
					wordCount    = session.wordCount[winner] or 0,
				})

				-- Tambah Wins stat (disimpan ke DataStore)
				if addWinFunc then
					addWinFunc:Invoke(winner)
				end
			end

			-- Reward pemain yang kalah (kecil, per kata benar) + tambah loss
			for p, wc in pairs(session.wordCount) do
				if p ~= winner then
					-- Coin partisipasi
					local loseReward = 0
					if wc > 0 then
						loseReward = wc * (coinCfg.LoseReward or 1)
						if loseReward > 0 then
							addCashFunc:Invoke(p, loseReward, "Sambung Kata Partisipasi (" .. wc .. " kata benar)")
						end
					end

					-- Kirim detail reward ke loser untuk NotificationWin GUI
					R.WinNotif:FireClient(p, {
						isWinner     = false,
						winBonus     = 0,
						correctBonus = loseReward,
						totalCoins   = loseReward,
						wordCount    = wc or 0,
					})

					-- Tambah Losses stat (disimpan ke DataStore)
					if addLossFunc then
						addLossFunc:Invoke(p)
					end
				end
			end
		end

		-- Reset zona (cepat agar pemain segera bisa berdiri)
		task.delay(0.5, function()
			activeSessions[zoneName] = nil
			resetZoneFunc:Invoke(zoneName)
		end)
		return true
	end
	return false
end

-- ── Start timer per giliran ──────────────────────────────────
local function startTurn(session, zoneName)
	if #session.players == 0 then return end

	-- Putaran berikutnya
	session.currentIdx    = getNextAliveIdx(session) or 1
	local currentPlayer   = session.players[session.currentIdx]
	session.wrongCount[currentPlayer] = 0

	-- Beritahu semua: giliran siapa + kata saat ini
	fireEveryone("NewTurn", zoneName, session.sessionId, currentPlayer.Name, session.currentWord)

	-- Batalkan timer lama
	if session.timerThread then
		task.cancel(session.timerThread)
		session.timerThread = nil
	end

	-- Timer countdown
	session.timerThread = task.spawn(function()
		for t = Config.TurnTime, 1, -1 do
			-- Kirim timer ke SEMUA pemain, bukan cuma current
			fireAll(session, "TimerTick", zoneName, session.sessionId, t)
			task.wait(1)
		end
		-- Timer habis secara natural → nil-kan SEBELUM panggil startTurn
		-- supaya startTurn tidak task.cancel thread yang sedang berjalan ini
		session.timerThread = nil
		if activeSessions[zoneName] == session then
			handleLoseHP(session, currentPlayer, zoneName)
			if not checkWinner(session, zoneName) then
				-- Randomize huruf baru supaya bisa lanjut
				local letters = {"a","b","c","d","e","g","h","i","j","k",
					"l","m","n","o","p","r","s","t","u","w"}
				session.currentWord = letters[math.random(#letters)]
				startTurn(session, zoneName)
			end
		end
	end)
end

-- ── Event: game dimulai dari ZoneManager ─────────────────────
startGameEvent.Event:Connect(function(zoneName, playerList)
	if activeSessions[zoneName] then return end  -- sudah ada sesi

	sessionCounter = sessionCounter + 1
	local session = {
		players     = playerList,
		sessionId   = sessionCounter,   -- ID unik per game, dikirim ke client
		hp          = {},
		wrongCount  = {},
		wordCount   = {},
		usedWords   = {},
		startTime   = tick(),
		currentWord = (function()
			local letters = {"a","b","c","d","e","g","h","i","j","k",
				"l","m","n","o","p","r","s","t","u","w"}
			return letters[math.random(#letters)]
		end)(),
		currentIdx  = 0,
		timerThread = nil,
		spectators  = {},
	}

	for _, p in ipairs(playerList) do
		session.hp[p]         = Config.MaxHP
		session.wrongCount[p] = 0
		session.wordCount[p]  = 0
	end

	activeSessions[zoneName] = session


	-- Beritahu SEMUA pemain di server game dimulai (agar penonton bisa lihat billboard)
	local gameData = {
		zoneName    = zoneName,
		sessionId   = session.sessionId,   -- <-- client pakai ini untuk filter event
		players     = (function()
			local names = {}
			for _, pp in ipairs(playerList) do
				table.insert(names, pp.Name)
			end
			return names
		end)(),
		startWord   = session.currentWord,
		maxHP       = Config.MaxHP,
		turnTime    = Config.TurnTime,
	}
	for _, p in ipairs(Players:GetPlayers()) do
		R.GameStarted:FireClient(p, gameData)
	end

	task.wait(3)  -- jeda sebelum giliran pertama
	startTurn(session, zoneName)
end)

-- ── Event: live typing relay → SEMUA pemain di server bisa lihat ──
R.LiveTyping.OnServerEvent:Connect(function(player, text)
	text = normalizeWord(text)
	if #text > 40 then
		text = text:sub(1, 40)
	end

	-- Cek apakah player memang sedang dalam sesi game
	local inSession = false
	for _, session in pairs(activeSessions) do
		for _, p in ipairs(session.players) do
			if p == player then inSession = true; break end
		end
		if not inSession and session.spectators[player] then inSession = true end
		if inSession then break end
	end
	if not inSession then return end

	-- Relay hanya ke pemain di sesi yang sama
	for _, session in pairs(activeSessions) do
		local inThis = false
		for _, p in ipairs(session.players) do
			if p == player then inThis = true; break end
		end
		if not inThis and session.spectators[player] then inThis = true end
		if inThis then
			for _, p in ipairs(session.players) do
				if p ~= player then
					R.LiveTyping:FireClient(p, player.Name, text)
				end
			end
			for sp, _ in pairs(session.spectators) do
				if sp ~= player then
					R.LiveTyping:FireClient(sp, player.Name, text)
				end
			end
			break
		end
	end
end)

-- ── Event: pemain kirim kata ─────────────────────────────────
R.SubmitWord.OnServerEvent:Connect(function(player, rawWord)
	-- Cari sesi yang melibatkan player ini
	local session, zoneName
	for zName, sess in pairs(activeSessions) do
		for _, p in ipairs(sess.players) do
			if p == player then
				session  = sess
				zoneName = zName
				break
			end
		end
		if session then break end
	end
	if not session then return end

	-- Apakah benar giliran player ini?
	local currentPlayer = session.players[session.currentIdx]
	if currentPlayer ~= player then return end

	local word = normalizeWord(rawWord)
	if word == "" then
		session.wrongCount[player] = session.wrongCount[player] + 1
		R.WordRejected:FireClient(player, "Gunakan huruf A-Z saja.", session.wrongCount[player])
		fireEveryone("OpponentWrong", zoneName, player.Name, session.wrongCount[player])

		if session.wrongCount[player] >= Config.MaxWrongPerTurn then
			if session.timerThread then task.cancel(session.timerThread); session.timerThread = nil end
			handleLoseHP(session, player, zoneName)
			if not checkWinner(session, zoneName) then
				local letters = {"a","b","c","d","e","g","h","i","j","k","l","m","n","o","p","r","s","t","u","w"}
				session.currentWord = letters[math.random(#letters)]
				startTurn(session, zoneName)
			end
		end
		return
	end

	-- ── Validasi 1a: akhiran huruf 'x' tidak ada dalam bahasa Indonesia ──
	if word:sub(-1) == "x" then
		session.wrongCount[player] = session.wrongCount[player] + 1
		R.WordRejected:FireClient(player, "Kata bahasa Indonesia tidak berakhiran huruf 'x'!", session.wrongCount[player])
		fireEveryone("OpponentWrong", zoneName, player.Name, session.wrongCount[player])

		if session.wrongCount[player] >= Config.MaxWrongPerTurn then
			if session.timerThread then task.cancel(session.timerThread); session.timerThread = nil end
			handleLoseHP(session, player, zoneName)
			if not checkWinner(session, zoneName) then
				local letters = {"a","b","c","d","e","g","h","i","j","k","l","m","n","o","p","r","s","t","u","w"}
				session.currentWord = letters[math.random(#letters)]
				startTurn(session, zoneName)
			end
		end
		return
	end

	-- ── Validasi 1b: ada di kamus? ───────────────────────────
	if not Words.IsValid(word) then
		session.wrongCount[player] = session.wrongCount[player] + 1
		R.WordRejected:FireClient(player, "Kata tidak ada di kamus!", session.wrongCount[player])
		-- Beritahu semua pemain lain bahwa pemain ini salah
		fireEveryone("OpponentWrong", zoneName, player.Name, session.wrongCount[player])

		if session.wrongCount[player] >= Config.MaxWrongPerTurn then
			if session.timerThread then task.cancel(session.timerThread); session.timerThread = nil end
			handleLoseHP(session, player, zoneName)
			if not checkWinner(session, zoneName) then
				local letters = {"a","b","c","d","e","g","h","i","j","k","l","m","n","o","p","r","s","t","u","w"}
				session.currentWord = letters[math.random(#letters)]
				startTurn(session, zoneName)
			end
		end
		return
	end

	-- ── Validasi 2: sudah pernah dipakai? ───────────────────
	if session.usedWords[word] then
		session.wrongCount[player] = session.wrongCount[player] + 1
		R.WordRejected:FireClient(player, "Kata sudah pernah dipakai!", session.wrongCount[player])
		fireEveryone("OpponentWrong", zoneName, player.Name, session.wrongCount[player])

		if session.wrongCount[player] >= Config.MaxWrongPerTurn then
			if session.timerThread then task.cancel(session.timerThread); session.timerThread = nil end
			handleLoseHP(session, player, zoneName)
			if not checkWinner(session, zoneName) then
				local letters = {"a","b","c","d","e","g","h","i","j","k","l","m","n","o","p","r","s","t","u","w"}
				session.currentWord = letters[math.random(#letters)]
				startTurn(session, zoneName)
			end
		end
		return
	end

	-- ── Validasi 3: sambung kata valid? ─────────────────────
	local valid, matchedSuffix = isValidChain(session.currentWord, word)
	if not valid then
		session.wrongCount[player] = session.wrongCount[player] + 1
		R.WordRejected:FireClient(player,
			"Kata harus dimulai dari akhiran kata sebelumnya! ("
				.. session.currentWord .. ")",
			session.wrongCount[player])
		fireEveryone("OpponentWrong", zoneName, player.Name, session.wrongCount[player])

		if session.wrongCount[player] >= Config.MaxWrongPerTurn then
			if session.timerThread then task.cancel(session.timerThread); session.timerThread = nil end
			handleLoseHP(session, player, zoneName)
			if not checkWinner(session, zoneName) then
				local letters = {"a","b","c","d","e","g","h","i","j","k","l","m","n","o","p","r","s","t","u","w"}
				session.currentWord = letters[math.random(#letters)]
				startTurn(session, zoneName)
			end
		end
		return
	end

	-- ── Kata Diterima ────────────────────────────────────────
	if session.timerThread then
		task.cancel(session.timerThread)
		session.timerThread = nil
	end

	session.usedWords[word]   = true
	-- Ambil 1 atau 2 huruf terakhir SECARA ACAK sebagai awalan giliran berikutnya
	-- contoh: "anjing" → bisa "g"(1) atau "ng"(2)
	local maxTake = math.min(2, #word)
	local suffixLen = math.random(1, maxTake)
	session.currentWord       = word:sub(#word - suffixLen + 1)
	session.wrongCount[player]= 0
	session.wordCount[player] = (session.wordCount[player] or 0) + 1

	fireEveryone("WordAccepted", zoneName, player.Name, word, matchedSuffix)

	-- Lanjut giliran berikutnya
	if not checkWinner(session, zoneName) then
		task.wait(1.5)
		startTurn(session, zoneName)
	end
end)

-- ── Bersihkan saat player disconnect ─────────────────────────
Players.PlayerRemoving:Connect(function(player)
	for zoneName, session in pairs(activeSessions) do
		-- Hapus dari active players
		for i, p in ipairs(session.players) do
			if p == player then
				table.remove(session.players, i)
				if session.currentIdx > #session.players then
					session.currentIdx = math.max(1, #session.players)
				end
				break
			end
		end
		session.hp[player]         = nil
		session.spectators[player] = nil

		-- Cek apakah masih ada pemain
		if #session.players <= 1 then
			checkWinner(session, zoneName)
		end
	end
end)

