local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local SkinConfig = require(ReplicatedStorage.Modules.SkinConfig)
local PlayerDataService = require(ServerScriptService.Modules.PlayerDataService)

local SkinRodService = {}

local skinRodFolder = ServerStorage:WaitForChild("SkinRod")

local function getSkinTemplate(skinName)
	return skinRodFolder:FindFirstChild(skinName)
end

-- Cari rod berdasarkan Attribute "IsFishingRod", BUKAN nama Tool
-- (nama Tool berubah-ubah sesuai skin yang lagi dipakai).
local function findRodTool(player)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, tool in backpack:GetChildren() do
			if tool:IsA("Tool") and tool:GetAttribute("IsFishingRod") then
				return tool
			end
		end
	end
	local character = player.Character
	if character then
		for _, tool in character:GetChildren() do
			if tool:IsA("Tool") and tool:GetAttribute("IsFishingRod") then
				return tool
			end
		end
	end
	return nil
end

-- FIX: ganti seluruh Tool (bukan cuma edit Handle-nya).
-- Tool lama di-destroy, Tool skin baru di-clone ke slot (Parent) yang sama persis
-- -- kalau lagi di-equip (Parent = Character), otomatis ke-equip lagi.
local function replaceRodTool(player, skinName)
	local skinTemplate = getSkinTemplate(skinName)
	if not skinTemplate then
		warn("[SkinRodService] Template skin tidak ditemukan:", skinName)
		return false
	end

	local oldTool = findRodTool(player)
	local targetParent = oldTool and oldTool.Parent or player:FindFirstChild("Backpack")

	if oldTool then
		oldTool:Destroy()
	end

	if not targetParent then return false end

	local newTool = skinTemplate:Clone()
	newTool:SetAttribute("IsFishingRod", true)

	-- Pastikan LineAttachment tetap ada di Handle skin baru (dipakai buat tali/bobber).
	-- Kalau template skin belum punya, otomatis ditambahin biar fitur tali tetap jalan.
	local handle = newTool:FindFirstChild("Handle")
	if handle and not handle:FindFirstChild("LineAttachment") then
		local attachment = Instance.new("Attachment")
		attachment.Name = "LineAttachment"
		attachment.Parent = handle
	end

	newTool.Parent = targetParent
	return true
end

local function applyStoredSkin(player)
	local equippedSkin = PlayerDataService.GetEquippedSkin(player)
	replaceRodTool(player, equippedSkin)
end

local function sendSkinData(remotes, player)
	remotes.SkinRodDataResponse:FireClient(player, {
		skins = SkinConfig.SKINS,
		owned = PlayerDataService.GetOwnedSkins(player),
		equipped = PlayerDataService.GetEquippedSkin(player),
	})
end

function SkinRodService.Init(remotes)
	remotes.SkinRodDataRequest.OnServerEvent:Connect(function(player)
		if not PlayerDataService.IsLoaded(player) then return end
		sendSkinData(remotes, player)
	end)

	remotes.SkinRodBuy.OnServerEvent:Connect(function(player, skinName)
		if typeof(skinName) ~= "string" then return end
		if not PlayerDataService.IsLoaded(player) then return end

		local skinData = SkinConfig.GetSkinData(skinName)
		if not skinData then
			remotes.SkinRodResult:FireClient(player, false, "Skin tidak ditemukan")
			return
		end

		if PlayerDataService.IsSkinOwned(player, skinName) then
			remotes.SkinRodResult:FireClient(player, false, "Skin sudah dimiliki")
			return
		end

		local getCashFunc = ReplicatedStorage:WaitForChild("_GetCash")
		local addCashFunc = ReplicatedStorage:WaitForChild("_AddCash")

		local currentCash = getCashFunc:Invoke(player)
		if currentCash < skinData.price then
			remotes.SkinRodResult:FireClient(player, false, "Cash tidak cukup")
			return
		end

		addCashFunc:Invoke(player, -skinData.price, "Beli Skin " .. skinName)
		PlayerDataService.AddOwnedSkin(player, skinName)

		remotes.SkinRodResult:FireClient(player, true, "Berhasil beli " .. skinName)
		sendSkinData(remotes, player)
	end)

	remotes.SkinRodEquip.OnServerEvent:Connect(function(player, skinName)
		if typeof(skinName) ~= "string" then return end
		if not PlayerDataService.IsLoaded(player) then return end

		if not PlayerDataService.IsSkinOwned(player, skinName) then
			remotes.SkinRodResult:FireClient(player, false, "Skin belum dimiliki")
			return
		end

		PlayerDataService.SetEquippedSkin(player, skinName)
		local ok = replaceRodTool(player, skinName)

		remotes.SkinRodResult:FireClient(player, ok and ("Equip " .. skinName) and true or false, ok and ("Equip " .. skinName) or "Gagal ganti rod")
		sendSkinData(remotes, player)
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(1) -- kasih waktu StarterPack clone tool ke Backpack dulu
			if PlayerDataService.IsLoaded(player) then
				applyStoredSkin(player)
			end
		end)
	end)
end

return SkinRodService