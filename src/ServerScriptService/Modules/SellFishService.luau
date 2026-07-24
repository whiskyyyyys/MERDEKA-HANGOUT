local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")

local FishConfig = require(ReplicatedStorage.Modules.FishConfig)
local PlayerDataService = require(ServerScriptService.Modules.PlayerDataService)

local SellFishService = {}

local SELL_BUTTON_NAME = "ButtonSellFish" -- nama Part di Workspace
local SELL_COOLDOWN = 0.5
local lastSell = {}

local function getAddCashFunction()
	return ReplicatedStorage:WaitForChild("_AddCash")
end

-- Cari Tool ikan yang SEDANG DIPEGANG (equipped) -- harus jadi child langsung Character,
-- bukan Backpack. Ini yang menegakkan syarat "harus hold dulu buat jual" di server.
local function getEquippedFishTool(character)
	if not character then return nil end
	for _, child in character:GetChildren() do
		if child:IsA("Tool") and child:GetAttribute("Rarity") and child:GetAttribute("WeightKg") then
			return child
		end
	end
	return nil
end

function SellFishService.Init(remotes)
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		-- filter: cuma proses prompt yang parent-nya ButtonSellFish
		if not prompt.Parent or prompt.Parent.Name ~= SELL_BUTTON_NAME then
			return
		end

		local now = os.clock()
		if lastSell[player] and now - lastSell[player] < SELL_COOLDOWN then
			return
		end
		lastSell[player] = now

		local character = player.Character
		local backpack = player:FindFirstChild("Backpack")

		local fishToSell = {}
		
		-- Cari ikan di Character (sedang dipegang)
		if character then
			for _, child in character:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("Rarity") and child:GetAttribute("WeightKg") then
					if child:GetAttribute("IsFavorited") == true then continue end
					table.insert(fishToSell, child)
				end
			end
		end
		
		-- Cari ikan di Backpack
		if backpack then
			for _, child in backpack:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("Rarity") and child:GetAttribute("WeightKg") then
					if child:GetAttribute("IsFavorited") == true then continue end
					table.insert(fishToSell, child)
				end
			end
		end

		if #fishToSell == 0 then
			remotes.SellFishResult:FireClient(player, false, 0, "Kamu tidak punya ikan untuk dijual!")
			return
		end

		local totalCash = 0
		local fishNamesSold = {}

		for _, tool in ipairs(fishToSell) do
			local rarity = tool:GetAttribute("Rarity")
			local weightKg = tool:GetAttribute("WeightKg")
			local scaleFactor = tool:GetAttribute("SizeScale")
			local fishName = tool.Name

			local pricePerKg = FishConfig.SELL_PRICE_PER_KG[rarity]
			if pricePerKg then
				local finalPrice = math.floor((weightKg * pricePerKg) + 0.5)
				totalCash += finalPrice
				PlayerDataService.RemoveFish(player, fishName, rarity, weightKg, scaleFactor)
				table.insert(fishNamesSold, fishName)
				tool:Destroy()
			end
		end

		if totalCash > 0 then
			local addCashFunc = getAddCashFunction()
			local ok = addCashFunc:Invoke(player, totalCash, "Jual " .. #fishNamesSold .. " ikan")
			if ok then
				remotes.SellFishResult:FireClient(player, true, totalCash, "Semua Ikan (" .. #fishNamesSold .. ")")
			else
				remotes.SellFishResult:FireClient(player, false, 0, "Gagal memproses cash")
			end
		else
			remotes.SellFishResult:FireClient(player, false, 0, "Ikan tidak memiliki harga yang valid.")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastSell[player] = nil
	end)
	
	remotes.ToggleFavoriteFish.OnServerEvent:Connect(function(player, tool, isFavorited)
		if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then return end
		if tool.Parent ~= player.Backpack and tool.Parent ~= player.Character then return end
		if not tool:GetAttribute("Rarity") or not tool:GetAttribute("WeightKg") then return end
		
		tool:SetAttribute("IsFavorited", isFavorited == true)
		
		local fishName = tool.Name
		local rarity = tool:GetAttribute("Rarity")
		local weightKg = tool:GetAttribute("WeightKg")
		local scaleFactor = tool:GetAttribute("SizeScale")
		
		PlayerDataService.SetFavorite(player, fishName, rarity, weightKg, scaleFactor, isFavorited == true)
	end)
end

function SellFishService.AutoSellAll(player)
	local character = player.Character
	local backpack = player:FindFirstChild("Backpack")

	local fishToSell = {}
	
	if character then
		for _, child in character:GetChildren() do
			if child:IsA("Tool") and child:GetAttribute("Rarity") and child:GetAttribute("WeightKg") then
				if child:GetAttribute("IsFavorited") == true then continue end
				table.insert(fishToSell, child)
			end
		end
	end
	
	if backpack then
		for _, child in backpack:GetChildren() do
			if child:IsA("Tool") and child:GetAttribute("Rarity") and child:GetAttribute("WeightKg") then
				if child:GetAttribute("IsFavorited") == true then continue end
				table.insert(fishToSell, child)
			end
		end
	end

	if #fishToSell == 0 then return 0 end

	local totalCash = 0
	local fishNamesSold = {}

	for _, tool in ipairs(fishToSell) do
		local rarity = tool:GetAttribute("Rarity")
		local weightKg = tool:GetAttribute("WeightKg")
		local scaleFactor = tool:GetAttribute("SizeScale")
		local fishName = tool.Name

		local pricePerKg = FishConfig.SELL_PRICE_PER_KG[rarity]
		if pricePerKg then
			local finalPrice = math.floor((weightKg * pricePerKg) + 0.5)
			totalCash += finalPrice
			PlayerDataService.RemoveFish(player, fishName, rarity, weightKg, scaleFactor)
			table.insert(fishNamesSold, fishName)
			tool:Destroy()
		end
	end

	if totalCash > 0 then
		local addCashFunc = getAddCashFunction()
		local ok = addCashFunc:Invoke(player, totalCash, "Auto-Sell " .. #fishNamesSold .. " ikan")
		if ok then
			pcall(function()
				local remotes = require(ReplicatedStorage.Modules.RemotesUtil).Get()
				remotes.SellFishResult:FireClient(player, true, totalCash, "Auto-Sell " .. #fishNamesSold .. " Ikan Penuh")
			end)
		end
	end
	return totalCash
end

return SellFishService