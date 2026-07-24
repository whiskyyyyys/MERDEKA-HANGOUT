local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FishConfig = require(ReplicatedStorage.Modules.FishConfig)
local InventoryService = require(ServerScriptService.Modules.InventoryService)
local PlayerDataService = require(ServerScriptService.Modules.PlayerDataService)

return function(context, players, fishName, weightKg)
	-- Cari rarity ikan berdasarkan nama yang diinput
	local rarity = nil
	local trueFishName = fishName
	
	for r, fishes in pairs(FishConfig.FISH_BY_RARITY) do
		for _, f in ipairs(fishes) do
			if string.lower(f) == string.lower(fishName) then
				rarity = r
				trueFishName = f -- Gunakan kapitalisasi asli dari config
				break
			end
		end
		if rarity then break end
	end
	
	if not rarity then
		return "Gagal: Ikan '" .. fishName .. "' tidak ditemukan di database game!"
	end
	
	-- Hitung scale factor berdasarkan berat kustom. 
	-- Semakin berat, ikan akan semakin raksasa!
	local range = FishConfig.RARITY_SIZE_RANGE[rarity]
	local maxKg = range.maxKg
	local maxScale = range.maxScale
	local scaleFactor = (weightKg / maxKg) * maxScale
	
	-- Batas wajar minimal agar tidak menghilang
	if scaleFactor <= 0.1 then scaleFactor = 0.1 end
	
	local totalGiven = 0
	
	for _, player in ipairs(players) do
		local clone = InventoryService.CreateFishTool(rarity, trueFishName, weightKg, scaleFactor, false)
		if clone then
			local backpack = player:FindFirstChild("Backpack")
			if backpack then
				clone.Parent = backpack
				PlayerDataService.AddFish(player, trueFishName, rarity, weightKg, scaleFactor)
				totalGiven += 1
			end
		end
	end
	
	return "Berhasil memberikan " .. trueFishName .. " (" .. weightKg .. " Kg) ke " .. totalGiven .. " pemain!"
end
