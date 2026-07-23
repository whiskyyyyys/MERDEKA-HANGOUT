-- ============================================================
-- MHCoinService.server.luau
-- Mengelola MH Coin dan Spin Tickets
-- ============================================================

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local mhStore = DataStoreService:GetDataStore("MHCoin_Spins_v1")
local mhCache = {}
local spinsCache = {}

local function loadData(player)
	local uid = tostring(player.UserId)
	local ok, data = pcall(function()
		return mhStore:GetAsync("mhdata_" .. uid)
	end)
	
	local mhCoins = 0
	local spins = 1 -- Beri 1 free spin awal untuk player baru
	
	if ok and type(data) == "table" then
		mhCoins = data.MHCoin or 0
		spins = data.Spins or 0
	end
	
	mhCache[player] = mhCoins
	spinsCache[player] = spins
	
	-- Buat / Sinkronisasi StatsData
	local ls = player:WaitForChild("StatsData", 10)
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "StatsData"
		ls.Parent = player
	end
	
	local mhStat = ls:FindFirstChild("MHCoin")
	if not mhStat then
		mhStat = Instance.new("IntValue")
		mhStat.Name = "MHCoin"
		mhStat.Parent = ls
	end
	mhStat.Value = mhCoins
	
	local spinStat = ls:FindFirstChild("Spins")
	if not spinStat then
		spinStat = Instance.new("IntValue")
		spinStat.Name = "Spins"
		spinStat.Parent = ls
	end
	spinStat.Value = spins
	
	-- Sinkronisasi ke Leaderstats agar tampil di tab
	task.spawn(function()
		local leaderstats = player:WaitForChild("leaderstats", 10)
		if leaderstats then
			local leaderMHCoin = leaderstats:FindFirstChild("MHCoin")
			if not leaderMHCoin then
				leaderMHCoin = Instance.new("IntValue")
				leaderMHCoin.Name = "MHCoin"
				leaderMHCoin.Parent = leaderstats
			end
			leaderMHCoin.Value = mhCoins
			
			mhStat:GetPropertyChangedSignal("Value"):Connect(function()
				leaderMHCoin.Value = mhStat.Value
			end)
		end
	end)
end

local function saveData(player)
	if not mhCache[player] then return end
	local uid = tostring(player.UserId)
	
	pcall(function()
		mhStore:SetAsync("mhdata_" .. uid, {
			MHCoin = mhCache[player],
			Spins = spinsCache[player]
		})
	end)
end

local function addMHCoin(player, amount)
	if not mhCache[player] then return end
	mhCache[player] = math.max(0, mhCache[player] + math.floor(amount))
	
	local ls = player:FindFirstChild("StatsData")
	if ls and ls:FindFirstChild("MHCoin") then
		ls.MHCoin.Value = mhCache[player]
	end
	saveData(player)
end

local function addSpins(player, amount)
	if not spinsCache[player] then return end
	spinsCache[player] = math.max(0, spinsCache[player] + math.floor(amount))
	
	local ls = player:FindFirstChild("StatsData")
	if ls and ls:FindFirstChild("Spins") then
		ls.Spins.Value = spinsCache[player]
	end
	saveData(player)
end

Players.PlayerAdded:Connect(loadData)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function() loadData(p) end)
end

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	mhCache[player] = nil
	spinsCache[player] = nil
end)

game:BindToClose(function()
	for player, _ in pairs(mhCache) do
		saveData(player)
	end
end)

-- BindableFunctions
local addMHCoinFunc = Instance.new("BindableFunction")
addMHCoinFunc.Name = "_AddMHCoin"
addMHCoinFunc.Parent = ReplicatedStorage
addMHCoinFunc.OnInvoke = function(player, amount)
	if not player or not amount then return false end
	addMHCoin(player, amount)
	return true
end

local addSpinsFunc = Instance.new("BindableFunction")
addSpinsFunc.Name = "_AddSpins"
addSpinsFunc.Parent = ReplicatedStorage
addSpinsFunc.OnInvoke = function(player, amount)
	if not player or not amount then return false end
	addSpins(player, amount)
	return true
end

local getSpinsFunc = Instance.new("BindableFunction")
getSpinsFunc.Name = "_GetSpins"
getSpinsFunc.Parent = ReplicatedStorage
getSpinsFunc.OnInvoke = function(player)
	return spinsCache[player] or 0
end

local deductMHCoinFunc = Instance.new("BindableFunction")
deductMHCoinFunc.Name = "_DeductMHCoin"
deductMHCoinFunc.Parent = ReplicatedStorage
deductMHCoinFunc.OnInvoke = function(player, amount)
	if not player or type(amount) ~= "number" or amount <= 0 then return false end
	if not mhCache[player] then return false end
	if mhCache[player] >= amount then
		mhCache[player] = math.max(0, mhCache[player] - math.floor(amount))
		local ls = player:FindFirstChild("StatsData")
		if ls and ls:FindFirstChild("MHCoin") then
			ls.MHCoin.Value = mhCache[player]
		end
		saveData(player)
		return true
	end
	return false
end

local getMHCoinFunc = Instance.new("BindableFunction")
getMHCoinFunc.Name = "_GetMHCoin"
getMHCoinFunc.Parent = ReplicatedStorage
getMHCoinFunc.OnInvoke = function(player)
	return mhCache[player] or 0
end

print("[MHCoinService] Berhasil dimuat.")
