local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ganti angka 0 di bawah ini dengan Product ID asli Anda.
-- (Harus sama dengan yang ada di CoinShopClient!)
local PRODUCT_REWARDS = {
	-- [ID] = JUMLAH_COIN
	[111111] = 1,    -- Ganti dengan Product ID untuk 1 Coin
	[222222] = 10,   -- Ganti dengan Product ID untuk 10 Coin
	[333333] = 50,   -- Ganti dengan Product ID untuk 50 Coin
	[444444] = 100,  -- Ganti dengan Product ID untuk 100 Coin
	[555555] = 500,  -- Ganti dengan Product ID untuk 500 Coin
	[666666] = 1000, -- Ganti dengan Product ID untuk 1000 Coin
}

-- Remote Event untuk update Topbar dari Server (jika diperlukan)
local minigamesFolder = ReplicatedStorage:WaitForChild("Minigames")
local skFolder = minigamesFolder:WaitForChild("SambungKata")
local remotes = skFolder:WaitForChild("Remotes")
local CoinUpdate = remotes:WaitForChild("CoinUpdate")

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local playerId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	
	local player = Players:GetPlayerByUserId(playerId)
	if not player then
		-- Pemain mungkin keluar sebelum proses selesai, 
		-- beri tahu Roblox kita belum memberikan hadiah
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- Cek apakah Product ID ini ada di tabel hadiah kita
	local coinReward = PRODUCT_REWARDS[productId]
	if coinReward then
		local addCoins = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("_AddCoins")
		if addCoins then
			addCoins:Invoke(player, coinReward, "Top Up")
			print("[CoinShop] Pemain " .. player.Name .. " berhasil membeli " .. coinReward .. " Coin!")
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	
	-- Jika tidak dikenali, mungkin ini product gamepass/lainnya
	warn("[CoinShop] Product ID " .. productId .. " tidak dikenal atau tidak ada data Coins.")
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
