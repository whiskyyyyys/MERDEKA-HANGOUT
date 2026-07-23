-- ============================================================
-- CashShopServer.server.luau
-- Menangani pembelian Cash menggunakan Coin.
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("[CashShopServer] Memulai layanan...")

-- Buat folder CashShop di ReplicatedStorage jika belum ada
local cashShopFolder = ReplicatedStorage:FindFirstChild("CashShop")
if not cashShopFolder then
	cashShopFolder = Instance.new("Folder")
	cashShopFolder.Name = "CashShop"
	cashShopFolder.Parent = ReplicatedStorage
end

local BuyCashWithCoins = cashShopFolder:FindFirstChild("BuyCashWithCoins")
if not BuyCashWithCoins then
	BuyCashWithCoins = Instance.new("RemoteFunction")
	BuyCashWithCoins.Name = "BuyCashWithCoins"
	BuyCashWithCoins.Parent = cashShopFolder
end

-- Cari fungsi _DeductMHCoin dan _AddCash
-- _DeductMHCoin ada di ReplicatedStorage (dari MHCoinService)
local deductMHCoin = ReplicatedStorage:WaitForChild("_DeductMHCoin", 15)
local addCash = ReplicatedStorage:WaitForChild("_AddCash", 10)

if not deductMHCoin or not addCash then
	warn("[CashShopServer] _DeductMHCoin atau _AddCash tidak ditemukan! Cash Shop mungkin tidak berfungsi.")
end

-- Definisi Paket Cash
-- cost = Harga dalam MH Coin
-- reward = Jumlah Cash yang didapatkan
local PACKAGES = {
	["1"] = { cost = 1, reward = 10000 },
	["2"] = { cost = 8, reward = 100000 },
	["3"] = { cost = 32, reward = 500000 },
	["4"] = { cost = 51, reward = 1000000 },
	["5"] = { cost = 205, reward = 5000000 },
	["6"] = { cost = 328, reward = 10000000 },
}

BuyCashWithCoins.OnServerInvoke = function(player, packageId)
	if not deductMHCoin or not addCash then 
		warn("[CashShopServer] Error: _DeductMHCoin / _AddCash nil")
		return false, "Sistem sedang error." 
	end
	
	local packageStr = tostring(packageId)
	local pkg = PACKAGES[packageStr]
	if not pkg then 
		warn("[CashShopServer] Error: Paket " .. tostring(packageId) .. " tidak valid.")
		return false, "Paket tidak valid." 
	end
	
	print("[CashShopServer] Pemain " .. player.Name .. " mencoba membeli " .. pkg.reward .. " Cash seharga " .. pkg.cost .. " MH Coin.")
	
	-- Coba potong MH Coin
	local success = deductMHCoin:Invoke(player, tonumber(pkg.cost))
	if success then
		-- Berikan cash
		local addSuccess = pcall(function()
			addCash:Invoke(player, tonumber(pkg.reward), "Beli Cash Shop")
		end)
		if not addSuccess then
			warn("[CashShopServer] _AddCash gagal untuk " .. player.Name)
		end
		print("[CashShopServer] Transaksi Berhasil! Pemain " .. player.Name .. " mendapatkan " .. pkg.reward .. " Cash.")
		return true, "Berhasil membeli Cash!"
	else
		warn("[CashShopServer] Transaksi Gagal! " .. player.Name .. " gagal deduct MH Coin (mungkin saldo kurang dari " .. pkg.cost .. ").")
		return false, "MH Coin tidak cukup."
	end
end

print("[CashShopServer] Berhasil dimuat.")
