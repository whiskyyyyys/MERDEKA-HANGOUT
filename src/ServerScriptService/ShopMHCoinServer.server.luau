local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local DataStoreService = game:GetService("DataStoreService")

local shopDataStore = DataStoreService:GetDataStore("MHCoinShop_OwnedItems_v1")

local buyRemote = Instance.new("RemoteFunction")
buyRemote.Name = "BuyShopItem"
buyRemote.Parent = ReplicatedStorage

local checkRemote = Instance.new("RemoteFunction")
checkRemote.Name = "CheckShopOwned"
checkRemote.Parent = ReplicatedStorage

local shopItemsFolder = ServerStorage:FindFirstChild("ShopItems")
if not shopItemsFolder then
	shopItemsFolder = Instance.new("Folder")
	shopItemsFolder.Name = "ShopItems"
	shopItemsFolder.Parent = ServerStorage
end

local PRICES = {
	VIP = 39,
	CloudFly = 29,
	EmojiPack = 29,
	MerdekaSkate = 29,
	TrollPack = 29,
}

local ownedCache = {}

local function giveItemsToPlayer(player, itemName)
	local itemFolder = shopItemsFolder:FindFirstChild(itemName)
	if itemFolder then
		for _, item in ipairs(itemFolder:GetChildren()) do
			local clone = item:Clone()
			clone.Parent = player:WaitForChild("Backpack")
			
			local starterGear = player:FindFirstChild("StarterGear")
			if starterGear then
				local starterClone = item:Clone()
				starterClone.Parent = starterGear
			end
		end
	end
	
	if itemName == "VIP" then
		print("[Shop] Memberikan keuntungan VIP tambahan kepada", player.Name)
	end
end

Players.PlayerAdded:Connect(function(player)
	local success, data = pcall(function()
		return shopDataStore:GetAsync(tostring(player.UserId))
	end)
	
	if success and data then
		ownedCache[player] = data
		-- Berikan barang yang sudah dibeli
		for itemName, _ in pairs(data) do
			giveItemsToPlayer(player, itemName)
		end
	else
		ownedCache[player] = {}
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if ownedCache[player] then
		pcall(function()
			shopDataStore:SetAsync(tostring(player.UserId), ownedCache[player])
		end)
		ownedCache[player] = nil
	end
end)

checkRemote.OnServerInvoke = function(player, targetUserId)
	local targetPlayer = player
	if targetUserId then
		targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if not targetPlayer then return {} end
	end
	
	local owned = ownedCache[targetPlayer] or {}
	local result = {}
	for k, v in pairs(owned) do
		result[k] = v
	end
	
	-- Cek VIP dari command Discord
	if targetPlayer:GetAttribute("HasFreeVIP") == true then
		result["VIP"] = true
	end
	
	return result
end

buyRemote.OnServerInvoke = function(player, itemName, targetUserId)
	local targetPlayer = player
	if targetUserId then
		targetPlayer = Players:GetPlayerByUserId(targetUserId)
		if not targetPlayer then return false, "Pemain target tidak ditemukan di server!" end
	end
	
	local price = PRICES[itemName]
	if not price then return false, "Item tidak valid!" end
	
	local isDiscordVip = (itemName == "VIP" and targetPlayer:GetAttribute("HasFreeVIP") == true)
	if (ownedCache[targetPlayer] and ownedCache[targetPlayer][itemName]) or isDiscordVip then
		if targetUserId then
			return false, "Pemain target sudah memiliki item ini!"
		else
			return false, "Kamu sudah memiliki item ini!"
		end
	end
	
	local statsData = player:FindFirstChild("StatsData")
	if not statsData then return false, "Data StatsData tidak ditemukan!" end
	
	local mhcoinStat = statsData:FindFirstChild("MHCoin")
	if not mhcoinStat then return false, "Data MHCoin tidak ditemukan!" end
	
	if mhcoinStat.Value < price then
		return false, "MHCoin tidak cukup!"
	end
	
	local addMHCoinFunc = ReplicatedStorage:FindFirstChild("_AddMHCoin")
	if not addMHCoinFunc then return false, "Sistem MHCoin error!" end
	
	addMHCoinFunc:Invoke(player, -price)
	
	-- Simpan ke cache target
	if not ownedCache[targetPlayer] then ownedCache[targetPlayer] = {} end
	ownedCache[targetPlayer][itemName] = true
	
	-- Simpan ke DataStore langsung (opsional, tapi aman)
	task.spawn(function()
		pcall(function() shopDataStore:SetAsync(tostring(targetPlayer.UserId), ownedCache[targetPlayer]) end)
	end)
	
	giveItemsToPlayer(targetPlayer, itemName)
	
	if targetUserId then
		print("[Shop] " .. player.Name .. " menghadiahkan " .. itemName .. " kepada " .. targetPlayer.Name)
		return true, "Berhasil mengirim hadiah!"
	else
		print("[Shop] " .. player.Name .. " berhasil membeli " .. itemName)
		return true, "Pembelian sukses!"
	end
end
