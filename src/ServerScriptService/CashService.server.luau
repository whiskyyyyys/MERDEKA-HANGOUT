local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Remotes")

local CashUpdate = Remotes:FindFirstChild("CashUpdate")
if not CashUpdate then
	CashUpdate = Instance.new("RemoteEvent")
	CashUpdate.Name = "CashUpdate"
	CashUpdate.Parent = Remotes
end

local CashReward = Remotes:FindFirstChild("CashReward")
if not CashReward then
	CashReward = Instance.new("RemoteEvent")
	CashReward.Name = "CashReward"
	CashReward.Parent = Remotes
end

local cashStore = DataStoreService:GetDataStore("PlayerCash_v1")
local cashCache = {}

local function loadData(player)
	local uid = tostring(player.UserId)
	local ok, data = pcall(function()
		return cashStore:GetAsync("cash_" .. uid)
	end)
	
	local cash = 0
	if ok and type(data) == "number" then
		cash = data
	end
	
	-- KOMPENSASI BUG UNTUK whisha rtx1945
	if player.UserId == 800392350 or player.Name == "whisha rtx1945" or player.Name == "whisha_rtx1945" then
		-- Cek apakah sudah dikompensasi
		local compKey = "comp_3233_" .. uid
		local okComp, compData = pcall(function() return cashStore:GetAsync(compKey) end)
		if okComp and not compData then
			print("[CashService] Memberikan kompensasi 3233 Cash kepada", player.Name)
			cash = cash + 3233
			pcall(function() cashStore:SetAsync(compKey, true) end)
		end
	end
	
	cashCache[player] = cash
	
	-- Buat leaderstats
	local ls = player:WaitForChild("StatsData", 10)
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "StatsData"
		ls.Parent = player
	end
	
	local cashStat = ls:FindFirstChild("Cash")
	if not cashStat then
		cashStat = Instance.new("IntValue")
		cashStat.Name = "Cash"
		cashStat.Parent = ls
	end
	cashStat.Value = cash
	
	CashUpdate:FireClient(player, cash)
end

local function saveData(player)
	local cash = cashCache[player]
	if not cash then return end
	local uid = tostring(player.UserId)
	
	pcall(function()
		cashStore:SetAsync("cash_" .. uid, cash)
	end)
end

local function addCash(player, amount, reason)
	if not cashCache[player] then return end
	local finalAmount = math.floor(amount)
	cashCache[player] = math.max(0, cashCache[player] + finalAmount)
	
	local ls = player:FindFirstChild("StatsData")
	if ls then
		local s = ls:FindFirstChild("Cash")
		if s then s.Value = cashCache[player] end
	end
	
	CashUpdate:FireClient(player, cashCache[player])
	local label = reason or "Reward"
	CashReward:FireClient(player, finalAmount, label)
	saveData(player)
end

Players.PlayerAdded:Connect(loadData)

for _, p in ipairs(Players:GetPlayers()) do
	task.spawn(function() loadData(p) end)
end

Players.PlayerRemoving:Connect(function(player)
	saveData(player)
	cashCache[player] = nil
end)

game:BindToClose(function()
	for player, _ in pairs(cashCache) do
		saveData(player)
	end
end)

-- BindableFunctions untuk dipanggil script server lain
local addCashFunc = Instance.new("BindableFunction")
addCashFunc.Name = "_AddCash"
addCashFunc.Parent = ReplicatedStorage -- Simpan di root ReplicatedStorage agar mudah diakses
addCashFunc.OnInvoke = function(player, amount, reason)
	if not player or not amount then return false end
	addCash(player, amount, reason)
	return true
end

local getCashFunc = Instance.new("BindableFunction")
getCashFunc.Name = "_GetCash"
getCashFunc.Parent = ReplicatedStorage
getCashFunc.OnInvoke = function(player)
	return cashCache[player] or 0
end

print("[CashService] Berhasil dimuat.")
