local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local RemotesUtil = require(ReplicatedStorage.Modules.RemotesUtil)
local remotes = RemotesUtil.Get()
local SkinConfig = require(ReplicatedStorage.Modules.SkinConfig)

-- FIX: nama folder etalase yang benar sesuai Explorer kamu
local SKIN_SHOP_FOLDER_NAME = "ProximityPromptBuySkinsRod"

local ownedSkins = {}
local equippedSkin = "RodDefault"
local promptsByConfigName = {}

local function findSkinShopFolder()
	return workspace:FindFirstChild(SKIN_SHOP_FOLDER_NAME)
end

local function updatePromptText(configName)
	local prompt = promptsByConfigName[configName]
	if not prompt then return end

	local skinData = SkinConfig.GetSkinData(configName)
	if not skinData then return end

	local isOwned = false
	for _, owned in ownedSkins do
		if owned == configName then isOwned = true break end
	end
	local isEquipped = equippedSkin == configName

	prompt.ObjectText = configName

	if isEquipped then
		prompt.ActionText = "Sudah Dipakai"
	elseif isOwned then
		prompt.ActionText = "Pakai Skin"
	elseif skinData.price <= 0 then
		prompt.ActionText = "Ambil Gratis"
	else
		prompt.ActionText = "Beli - " .. skinData.price
	end
end

local function refreshAllPrompts()
	for configName in promptsByConfigName do
		updatePromptText(configName)
	end
end

local function bindPrompt(part)
	-- FIX: cari berdasarkan workspaceName (nama Part), bukan name (nama Tool asli)
	local skinData = SkinConfig.GetSkinByWorkspaceName(part.Name)
	if not skinData then
		warn("[SkinShopPromptClient] Part '" .. part.Name .. "' tidak terdaftar di SkinConfig.SKINS (workspaceName)")
		return
	end

	local prompt = part:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then return end

	local configName = skinData.name
	promptsByConfigName[configName] = prompt
	updatePromptText(configName)

	prompt.Triggered:Connect(function()
		local isOwned = false
		for _, owned in ownedSkins do
			if owned == configName then isOwned = true break end
		end

		if isOwned then
			remotes.SkinRodEquip:FireServer(configName)
		else
			remotes.SkinRodBuy:FireServer(configName)
		end
	end)
end

local function setupShop()
	local shopFolder = findSkinShopFolder()
	if not shopFolder then
		warn("[SkinShopPromptClient] Folder '" .. SKIN_SHOP_FOLDER_NAME .. "' tidak ditemukan di Workspace")
		return
	end

	for _, child in shopFolder:GetChildren() do
		bindPrompt(child)
	end

	shopFolder.ChildAdded:Connect(bindPrompt)
end

remotes.SkinRodDataResponse.OnClientEvent:Connect(function(payload)
	ownedSkins = payload.owned
	equippedSkin = payload.equipped
	refreshAllPrompts()
end)

remotes.SkinRodResult.OnClientEvent:Connect(function(success, message)
	print(success and ("[Skin] " .. message) or ("[Skin] Gagal: " .. message))
end)

setupShop()
remotes.SkinRodDataRequest:FireServer()