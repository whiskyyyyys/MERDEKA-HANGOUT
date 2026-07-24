local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local FishConfig = require(ReplicatedStorage.Modules.FishConfig)
local InventoryService = require(ServerScriptService.Modules.InventoryService)
local PlayerDataService = require(ServerScriptService.Modules.PlayerDataService)
local FishingLineService = require(ServerScriptService.Modules.FishingLineService)
local SellFishService = require(ServerScriptService.Modules.SellFishService)

local FishingService = {}

local lastCast = {}
local streakCount = {}
local pendingCatch = {}

local function pickRarity(bonusPercent)
	local weights = FishConfig.RARITY_WEIGHTS
	if not weights then
		warn("[FishingService] FishConfig.RARITY_WEIGHTS tidak ditemukan!")
		return "Common"
	end

	local totalOriginal = 0
	for _, w in weights do totalOriginal += w end

	local commonWeight = weights.Common or 0
	local nonCommonWeight = totalOriginal - commonWeight
	local bonusWeight = totalOriginal * (bonusPercent / 100)

	local adjusted = {}
	for rarity, w in weights do
		if rarity == "Common" then
			local cut = commonWeight > 0 and (bonusWeight * (w / commonWeight)) or 0
			adjusted[rarity] = math.max(w - cut, 0.5)
		else
			local add = nonCommonWeight > 0 and (bonusWeight * (w / nonCommonWeight)) or 0
			adjusted[rarity] = w + add
		end
	end

	local totalWeight = 0
	for _, w in adjusted do totalWeight += w end
	local roll = math.random() * totalWeight
	local acc = 0
	for rarity, w in adjusted do
		acc += w
		if roll <= acc then return rarity end
	end
	return "Common"
end

local function pickFish(player, hitCount)
	local streak = streakCount[player] or 0
	local streakBonus = math.min(streak * FishConfig.STREAK_BONUS_PER_CATCH, FishConfig.STREAK_MAX_BONUS)

	local perfectBonus = 0
	if hitCount and hitCount >= FishConfig.ATTEMPTS_TOTAL then
		perfectBonus = FishConfig.PERFECT_HIT_BONUS_PERCENT
	end

	local totalBonusPercent = streakBonus + perfectBonus
	local rarity = pickRarity(totalBonusPercent)
	local fishNames = FishConfig.FISH_BY_RARITY and FishConfig.FISH_BY_RARITY[rarity]

	if not fishNames or #fishNames == 0 then
		rarity = "Common"
		fishNames = FishConfig.FISH_BY_RARITY and FishConfig.FISH_BY_RARITY.Common or {}
	end

	if #fishNames == 0 then
		warn("[FishingService] Tidak ada ikan terdaftar di FishConfig.FISH_BY_RARITY!")
		return "Common", "Unknown", totalBonusPercent
	end

	local fishName = fishNames[math.random(1, #fishNames)]
	return rarity, fishName, totalBonusPercent
end

local function isValidWaterPosition(targetPosition)
	local rayParams = RaycastParams.new()
	rayParams.IgnoreWater = false
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = {workspace.Terrain}

	local origin = targetPosition + Vector3.new(0, 20, 0)
	local result = workspace:Raycast(origin, Vector3.new(0, -40, 0), rayParams)
	return result ~= nil and result.Material == Enum.Material.Water
end

function FishingService.Init(remotes)
	remotes.RequestCast.OnServerEvent:Connect(function(player, targetPosition)
		if typeof(targetPosition) ~= "Vector3" then
			remotes.CastResult:FireClient(player, false)
			return
		end

		local now = os.clock()
		if lastCast[player] and now - lastCast[player] < FishConfig.CAST_COOLDOWN then
			remotes.CastResult:FireClient(player, false)
			return
		end
		lastCast[player] = now

		local character = player.Character
		if not character then
			remotes.CastResult:FireClient(player, false)
			return
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then
			remotes.CastResult:FireClient(player, false)
			return
		end

		if (targetPosition - root.Position).Magnitude > FishConfig.CAST_RANGE then
			remotes.CastResult:FireClient(player, false)
			return
		end

		local isWater = isValidWaterPosition(targetPosition)
		if isWater then
			pendingCatch[player] = true
			FishingLineService.ShowLine(player, targetPosition) -- FIX: tali dibuat di server, keliatan semua orang
		end
		remotes.CastResult:FireClient(player, isWater)
	end)

	remotes.SubmitCatchResult.OnServerEvent:Connect(function(player, hitCount)
		FishingLineService.HideLine(player) -- FIX: tali hilang begitu minigame selesai, buat semua orang

		if not pendingCatch[player] then return end
		pendingCatch[player] = nil

		if typeof(hitCount) ~= "number" then return end
		hitCount = math.clamp(hitCount, 0, FishConfig.ATTEMPTS_TOTAL)

		if not PlayerDataService.IsLoaded(player) then return end

		local rarity, fishName, bonusPercent = pickFish(player, hitCount)

		if hitCount >= FishConfig.ATTEMPTS_TOTAL then
			streakCount[player] = (streakCount[player] or 0) + 1
		else
			streakCount[player] = 0
		end

		local template = InventoryService.GetFishTemplate(rarity, fishName)
		local iconId = ""
		if template and template:IsA("Tool") then
			iconId = template.TextureId or ""
		end

		local success, weightKg, scaleFactor = InventoryService.GiveFish(player, rarity, fishName)
		if success then
			PlayerDataService.AddFish(player, fishName, rarity, weightKg, scaleFactor)
			
			-- OPTIMASI AFK: Auto-Sell jika inventaris mulai penuh (mencegah lag karena kebanyakan Tool di Backpack)
			local inventory = PlayerDataService.GetInventory(player)
			if #inventory >= 100 then
				task.spawn(function()
					SellFishService.AutoSellAll(player)
				end)
			end
		end

		remotes.FishCaught:FireClient(player, {
			fishName = fishName,
			rarity = rarity,
			iconId = iconId,
			hitCount = hitCount,
			streak = streakCount[player],
			bonusPercent = bonusPercent,
			weightKg = weightKg,
			scaleFactor = scaleFactor,
		})
	end)

	Players.PlayerRemoving:Connect(function(player)
		lastCast[player] = nil
		streakCount[player] = nil
		pendingCatch[player] = nil
	end)
end

return FishingService