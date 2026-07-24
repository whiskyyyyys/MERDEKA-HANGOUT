local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("FishConfig"))

return function(registry)
	-- Ambil semua nama ikan dari FishConfig dan jadikan list untuk Enum
	local fishList = {}
	
	for _, fishes in pairs(FishConfig.FISH_BY_RARITY) do
		for _, fishName in ipairs(fishes) do
			table.insert(fishList, fishName)
		end
	end
	
	-- Membuat tipe kustom "fish" yang otomatis menangani Autocomplete & Pencarian (Case Insensitive)
	registry:RegisterType("fish", registry.Cmdr.Util.MakeEnumType("fish", fishList))
end
