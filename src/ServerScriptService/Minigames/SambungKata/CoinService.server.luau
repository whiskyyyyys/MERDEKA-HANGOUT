-- ============================================================
-- CoinService.server.lua
-- Script → ServerScriptService/CoinService
-- Mengelola coin, wins, losses pemain: DataStore, leaderstats
-- ============================================================

local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Modules")
local Config  = require(Modules:WaitForChild("GameConfig"))

local Remotes       = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Remotes")
local CoinUpdate    = Remotes:WaitForChild("CoinUpdate")
local CoinReward    = Remotes:WaitForChild("CoinReward")
local StatsUpdate   = Remotes:WaitForChild("StatsUpdate")
-- DataStore untuk simpan semua data pemain
local dataStore  = DataStoreService:GetDataStore("PlayerData_v2")   -- coins only
local statsStore = DataStoreService:GetDataStore("PlayerStats_v6")  -- wins, losses, winStreak

-- Cache di memory
local dataCache = {}  -- [Player] = { coins=n, wins=n, losses=n, winStreak=n }
local coinMultiplier = 1  -- multiplier untuk admin abuse

local function syncWinStreakAttribute(player, streak)
	if not player then return end
	player:SetAttribute("WinStreak", math.max(0, math.floor(streak or 0)))
end

-- ── Load data saat player join ───────────────────────────────
local function loadData(player)
	local uid = "u_" .. player.UserId

	-- Baca coins dari PlayerData_v2
	local okCoins, coinData = pcall(function()
		return dataStore:GetAsync("data_" .. player.UserId)
	end)
	local coins = 0
	if okCoins and type(coinData) == "table" then
		coins = coinData.coins or 0
	elseif okCoins and type(coinData) == "number" then
		coins = coinData  -- format lama
	else
		-- Coba migrasi dari PlayerCoins_v1 (store sangat lama)
		local okOld, oldCoins = pcall(function()
			return DataStoreService:GetDataStore("PlayerCoins_v1"):GetAsync("coins_" .. player.UserId)
		end)
		coins = (okOld and type(oldCoins) == "number") and oldCoins or 0
	end

	local okStats, statsData = pcall(function()
		return statsStore:GetAsync(uid)
	end)
	local wins, losses, winStreak = 0, 0, 0
	if okStats and type(statsData) == "table" then
		wins      = statsData.wins      or 0
		losses    = statsData.losses    or 0
		winStreak = statsData.winStreak or 0
		
		-- MIGRASI COIN KE CASH (Hanya Sekali per player)
		if not statsData.migratedCash and coins > 0 then
			print("[CoinService] MIGRASI: Memindahkan " .. coins .. " Coin menjadi Cash untuk " .. player.Name)
			-- Berikan cash sesuai jumlah coin yang dimiliki
			local addCash = ReplicatedStorage:WaitForChild("_AddCash", 5)
			if addCash then
				addCash:Invoke(player, coins, "Migrasi Coin")
			end
			coins = 0 -- Reset coin
			statsData.migratedCash = true -- Tandai sudah migrasi
			
			-- Simpan ke PlayerStats_v6 (statsStore)
			pcall(function()
				statsStore:SetAsync(uid, statsData)
			end)
		end
	end

	local pData = {
		coins        = coins,
		wins         = wins,
		losses       = losses,
		winStreak    = winStreak,
		migratedCash = statsData and statsData.migratedCash or false,
	}
	dataCache[player] = pData

	-- Buat leaderstats kalau belum ada
	local ls = player:FindFirstChild("StatsData")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "StatsData"
		ls.Parent = player
	end

	-- Coins
	local coinStat = ls:FindFirstChild("Coins")
	if not coinStat then
		coinStat = Instance.new("IntValue")
		coinStat.Name = "Coins"
		coinStat.Parent = ls
	end
	coinStat.Value = pData.coins

	-- Wins
	local winStat = ls:FindFirstChild("Wins")
	if not winStat then
		winStat = Instance.new("IntValue")
		winStat.Name = "Wins"
		winStat.Parent = ls
	end
	winStat.Value = pData.wins

	-- Losses
	local loseStat = ls:FindFirstChild("Losses")
	if not loseStat then
		loseStat = Instance.new("IntValue")
		loseStat.Name = "Losses"
		loseStat.Parent = ls
	end
	loseStat.Value = pData.losses

	-- Kirim ke client
	syncWinStreakAttribute(player, pData.winStreak)
	CoinUpdate:FireClient(player, pData.coins)
	StatsUpdate:FireClient(player, pData.wins, pData.losses)
end

-- ── Save data ────────────────────────────────────────────────
local function saveData(player)
	local pData = dataCache[player]
	if not pData then return end
	local uid = "u_" .. player.UserId

	-- Simpan coins ke PlayerData_v2
	pcall(function()
		dataStore:UpdateAsync("data_" .. player.UserId, function(current)
			local existing = type(current) == "table" and current or {}
			return {
				coins = pData.coins,
				-- Pertahankan field lain kalau ada (jangan hapus statsVersion etc)
				wins      = existing.wins,
				losses    = existing.losses,
				winStreak = existing.winStreak,
			}
		end)
	end)

	-- Simpan wins/losses ke PlayerStats_v6
	local ok, err = pcall(function()
		statsStore:SetAsync(uid, {
			wins         = pData.wins,
			losses       = pData.losses,
			winStreak    = pData.winStreak,
			migratedCash = pData.migratedCash,
		})
	end)
	if not ok then
		warn("[CoinService] Gagal simpan stats " .. player.Name .. ": " .. tostring(err))
	end
end

-- ── Tambah coin ──────────────────────────────────────────────
local function addCoins(player, amount, reason)
	local pData = dataCache[player]
	if not pData then return end
	local finalAmount = math.floor(amount * coinMultiplier)
	pData.coins = math.max(0, pData.coins + finalAmount)

	local ls = player:FindFirstChild("StatsData")
	if ls then
		local s = ls:FindFirstChild("Coins")
		if s then s.Value = pData.coins end
	end

	CoinUpdate:FireClient(player, pData.coins)
	local label = reason or "Reward"
	if coinMultiplier > 1 then
		label = label .. " (" .. coinMultiplier .. "x)"
	end
	CoinReward:FireClient(player, finalAmount, label)
	saveData(player)
end

-- ── Tambah win ───────────────────────────────────────────────
local function addWin(player)
	local pData = dataCache[player]
	if not pData then return end
	pData.wins = pData.wins + 1
	pData.winStreak = (pData.winStreak or 0) + 1
	syncWinStreakAttribute(player, pData.winStreak)

	local ls = player:FindFirstChild("StatsData")
	if ls then
		local s = ls:FindFirstChild("Wins")
		if s then s.Value = pData.wins end
	end

	StatsUpdate:FireClient(player, pData.wins, pData.losses)
	saveData(player)

	-- Update global leaderboard OrderedDataStore
	local updateFunc = ReplicatedStorage:FindFirstChild("_UpdateGlobalWins")
	if updateFunc then
		pcall(function()
			updateFunc:Invoke(player.UserId, pData.wins)
		end)
	end
end

-- ── Tambah loss ──────────────────────────────────────────────
local function addLoss(player)
	local pData = dataCache[player]
	if not pData then return end
	pData.losses = pData.losses + 1
	pData.winStreak = 0
	syncWinStreakAttribute(player, 0)

	local ls = player:FindFirstChild("StatsData")
	if ls then
		local s = ls:FindFirstChild("Losses")
		if s then s.Value = pData.losses end
	end

	StatsUpdate:FireClient(player, pData.wins, pData.losses)
	saveData(player)

	local updateFunc = ReplicatedStorage:FindFirstChild("_UpdateGlobalLosses")
	if updateFunc then
		pcall(function()
			updateFunc:Invoke(player.UserId, pData.losses)
		end)
	end
end

-- ── Player join / leave ──────────────────────────────────────
Players.PlayerAdded:Connect(function(player)
	loadData(player)
end)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function() loadData(p) end)
end

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	dataCache[player] = nil
end)

game:BindToClose(function()
	for player, _ in pairs(dataCache) do
		saveData(player)
	end
end)

-- ── Expose ke script lain via BindableFunction ───────────────
local addCoinFunc = Instance.new("BindableFunction")
addCoinFunc.Name = "_AddCoins"
addCoinFunc.Parent = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
addCoinFunc.OnInvoke = function(player, amount, reason)
	if not player or not amount then return false end
	addCoins(player, amount, reason)
	return true
end

local deductCoinFunc = Instance.new("BindableFunction")
deductCoinFunc.Name = "_DeductCoins"
deductCoinFunc.Parent = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
deductCoinFunc.OnInvoke = function(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return false end
	local pData = dataCache[player]
	if not pData then return false end
	if pData.coins >= amount then
		pData.coins = math.max(0, pData.coins - math.floor(amount))
		local ls = player:FindFirstChild("StatsData")
		if ls then
			local s = ls:FindFirstChild("Coins")
			if s then s.Value = pData.coins end
		end
		CoinUpdate:FireClient(player, pData.coins)
		saveData(player)
		return true
	end
	return false
end

local getCoinFunc = Instance.new("BindableFunction")
getCoinFunc.Name = "_GetCoins"
getCoinFunc.Parent = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
getCoinFunc.OnInvoke = function(player)
	local pData = dataCache[player]
	return pData and pData.coins or 0
end

local addWinFunc = Instance.new("BindableFunction")
addWinFunc.Name = "_AddWin"
addWinFunc.Parent = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
addWinFunc.OnInvoke = function(player)
	if not player then return false end
	addWin(player)
	return true
end

local addLossFunc = Instance.new("BindableFunction")
addLossFunc.Name = "_AddLoss"
addLossFunc.Parent = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
addLossFunc.OnInvoke = function(player)
	if not player then return false end
	addLoss(player)
	return true
end

-- ── Set wins langsung ────────────────────────────────────────
local setWinsFunc = Instance.new("BindableFunction")
setWinsFunc.Name = "_SetWins"
setWinsFunc.Parent = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
setWinsFunc.OnInvoke = function(player, amount)
	if not player or not amount then return false end
	local pData = dataCache[player]
	if not pData then return false end
	pData.wins = math.max(0, math.floor(amount))
	local ls = player:FindFirstChild("StatsData")
	if ls then
		local s = ls:FindFirstChild("Wins")
		if s then s.Value = pData.wins end
	end
	StatsUpdate:FireClient(player, pData.wins, pData.losses)
	saveData(player)
	-- Update global leaderboard
	local updateFunc = ReplicatedStorage:FindFirstChild("_UpdateGlobalWins")
	if updateFunc then
		pcall(function() updateFunc:Invoke(player.UserId, pData.wins) end)
	end
	return true
end

-- ── Set losses langsung ──────────────────────────────────────
local setLossesFunc = Instance.new("BindableFunction")
setLossesFunc.Name = "_SetLosses"
setLossesFunc.Parent = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
setLossesFunc.OnInvoke = function(player, amount)
	if not player or not amount then return false end
	local pData = dataCache[player]
	if not pData then return false end
	pData.losses = math.max(0, math.floor(amount))
	local ls = player:FindFirstChild("StatsData")
	if ls then
		local s = ls:FindFirstChild("Losses")
		if s then s.Value = pData.losses end
	end
	StatsUpdate:FireClient(player, pData.wins, pData.losses)
	saveData(player)

	local updateFunc = ReplicatedStorage:FindFirstChild("_UpdateGlobalLosses")
	if updateFunc then
		pcall(function() updateFunc:Invoke(player.UserId, pData.losses) end)
	end
	return true
end

local setWinStreakFunc = Instance.new("BindableFunction")
setWinStreakFunc.Name = "_SetWinStreak"
setWinStreakFunc.Parent = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
setWinStreakFunc.OnInvoke = function(player, amount)
	if not player or amount == nil then return false end
	local pData = dataCache[player]
	if not pData then return false end
	pData.winStreak = math.max(0, math.floor(tonumber(amount) or 0))
	syncWinStreakAttribute(player, pData.winStreak)
	saveData(player)
	return true
end

local setMulFunc = Instance.new("BindableFunction")
setMulFunc.Name = "_SetCoinMultiplier"
setMulFunc.Parent = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata")
setMulFunc.OnInvoke = function(mul)
	coinMultiplier = tonumber(mul) or 1
	return true
end
