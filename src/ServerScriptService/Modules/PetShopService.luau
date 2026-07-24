local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local PlayerDataService = require(ServerScriptService.Modules.PlayerDataService)
local RemotesUtil = require(ReplicatedStorage.Modules.RemotesUtil)
local remotes = RemotesUtil.Get()

local PetShopService = {}

-- Daftar harga default untuk pet. (Bisa diganti atau ditambahkan sesuai selera)
local PET_PRICES = {
	Cloud_King = 5000,
	Crocodile = 1500,
	Demon17 = 8000,
	Elephant = 2000,
	Goat = 800,
	Horse = 1200,
	Lepord = 3000,
	Lepord17 = 7500,
	Mechanical_Infernus = 15000,
	Moose = 2500,
	Moose17 = 6000,
	Mouse = 500,
	Pig = 700,
	Planetarian_Devil = 20000,
	Shark = 4000,
	Shark17 = 9000,
	Sweetened_Squid = 3500,
	Violet_Enforcer = 12000,
	Zebra = 1800,
}

local function getPetPrice(petName)
	return PET_PRICES[petName] or 1000 -- Harga default jika tidak terdaftar
end

function PetShopService.Init()
	-- Cari folder ProximityPromptBuyPets di Workspace
	local promptFolder = Workspace:FindFirstChild("ProximityPromptBuyPets", true)
	if not promptFolder then
		warn("[PetShopService] Folder ProximityPromptBuyPets tidak ditemukan di Workspace!")
		return
	end
	
	-- Sambungkan semua ProximityPrompt
	for _, part in promptFolder:GetChildren() do
		if part:IsA("BasePart") or part:IsA("Model") then
			local prompt = part:FindFirstChildWhichIsA("ProximityPrompt")
			if prompt then
				local petName = part.Name
				local price = getPetPrice(petName)
				prompt.ActionText = "Buy " .. petName
				prompt.ObjectText = price .. " Cash"
				
				prompt.Triggered:Connect(function(player)
					PetShopService.ProcessPurchase(player, petName, price)
				end)
			end
		end
	end
	print("[PetShopService] Berhasil inisialisasi " .. #promptFolder:GetChildren() .. " pet shop prompt.")
end

function PetShopService.ProcessPurchase(player, petName, price)
	local hasPet = PlayerDataService.IsPetOwned(player, petName)
	
	if hasPet then
		-- Kirim notifikasi gagal (sudah punya)
		-- (Misalnya bisa menggunakan notifikasi UI yang sudah ada, atau buat yang baru. Di sini kita biarkan saja atau gunakan remote)
		remotes.PetPurchased:FireClient(player, false, "Kamu sudah memiliki pet ini!")
		return
	end
	
	-- Cek Cash
	local getCashFunc = ReplicatedStorage:FindFirstChild("_GetCash")
	local addCashFunc = ReplicatedStorage:FindFirstChild("_AddCash")
	
	if not getCashFunc or not addCashFunc then
		warn("[PetShopService] Sistem Cash tidak ditemukan!")
		return
	end
	
	local currentCash = getCashFunc:Invoke(player)
	if currentCash >= price then
		-- Potong cash
		addCashFunc:Invoke(player, -price, "Beli Pet " .. petName)
		
		-- Tambahkan pet ke database
		PlayerDataService.AddOwnedPet(player, petName)
		
		-- Otomatis equip
		PlayerDataService.SetEquippedPet(player, petName)
		
		-- Beritahu sistem pet service untuk langsung memunculkan pet
		require(ServerScriptService.Modules.PetService).SpawnPet(player, petName)
		
		-- Beritahu client update data
		local owned = PlayerDataService.GetOwnedPets(player)
		local equipped = PlayerDataService.GetEquippedPet(player)
		remotes.PetDataResponse:FireClient(player, owned, equipped)
		remotes.PetPurchased:FireClient(player, true, "Berhasil membeli " .. petName .. "!")
	else
		remotes.PetPurchased:FireClient(player, false, "Cash tidak cukup! Butuh " .. price .. " Cash.")
	end
end

return PetShopService
