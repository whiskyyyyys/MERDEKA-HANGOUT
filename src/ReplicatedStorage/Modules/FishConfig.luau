local FishConfig = {}

FishConfig.CAST_RANGE = 60
FishConfig.CAST_COOLDOWN = 1.5

FishConfig.STAGES = {
	{zoneScale = 0.5, speed = 3},
	{zoneScale = 0.5, speed = 4.5},
	{zoneScale = 0.5, speed = 6.5},
}
FishConfig.ATTEMPTS_TOTAL = #FishConfig.STAGES

FishConfig.COLOR_PENDING = Color3.fromRGB(20, 20, 20)
FishConfig.COLOR_MISS = Color3.fromRGB(200, 50, 50)
FishConfig.COLOR_SUCCESS = Color3.fromRGB(255, 220, 60)

FishConfig.STREAK_BONUS_PER_CATCH = 5
FishConfig.STREAK_MAX_BONUS = 40
FishConfig.PERFECT_HIT_BONUS_PERCENT = 25

FishConfig.RARITY_WEIGHTS = {
	Common = 45,
	Uncommon = 25,
	Rare = 15,
	Epic = 8,
	Legendary = 4,
	Mythic = 2,
	Secret = 1,
}

FishConfig.RARITY_COLORS = {
	Common = Color3.fromRGB(200, 200, 200),
	Uncommon = Color3.fromRGB(90, 200, 90),
	Rare = Color3.fromRGB(80, 140, 255),
	Epic = Color3.fromRGB(160, 60, 220),
	Legendary = Color3.fromRGB(255, 210, 40),
	Mythic = Color3.fromRGB(220, 40, 40),
	Secret = Color3.fromRGB(255, 255, 255),
}

FishConfig.FISH_BY_RARITY = {
	Common = {"Nemi", "Nemo", "Nemu"},
	Uncommon = {"AngelfishBlack", "BlueTang", "Emperor", "MoorishIdol", "RedSnapper", "YellowTang"},
	Rare = {"ReefShark", "RhinoWhite"},
	Epic = {"MagmaShark", "MambaFish", "NeonFish"},
	Legendary = {"Turtle"},
	Mythic = {"MantraBrown", "MantraRay", "MantraRed"},
	Secret = {"FishJerry", "FishNaomi"},
}

FishConfig.RARITY_SIZE_RANGE = {
	Common =    {minKg = 0.3, maxKg = 1.5,  minScale = 0.6, maxScale = 0.85},
	Uncommon =  {minKg = 1.0, maxKg = 3.0,  minScale = 0.8, maxScale = 1.0},
	Rare =      {minKg = 2.5, maxKg = 6.0,  minScale = 1.0, maxScale = 1.3},
	Epic =      {minKg = 5.0, maxKg = 12.0, minScale = 1.2, maxScale = 1.6},
	Legendary = {minKg = 10.0, maxKg = 25.0, minScale = 1.5, maxScale = 2.0},
	Mythic =    {minKg = 20.0, maxKg = 45.0, minScale = 1.8, maxScale = 2.4},
	Secret =    {minKg = 30.0, maxKg = 60.0, minScale = 2.0, maxScale = 2.8},
}

-- Harga jual per KG, per rarity. Harga akhir = weightKg * angka di sini (dibulatkan).
-- Tinggal edit angka buat balance ekonomi, gak perlu ubah script lain.
FishConfig.SELL_PRICE_PER_KG = {
	Common = 8,
	Uncommon = 15,
	Rare = 30,
	Epic = 60,
	Legendary = 120,
	Mythic = 250,
	Secret = 500,
}

return FishConfig