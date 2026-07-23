local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemotesUtil = require(ReplicatedStorage.Modules.RemotesUtil)
local PlayerDataService = require(ServerScriptService.Modules.PlayerDataService)
local InventoryService = require(ServerScriptService.Modules.InventoryService)
local FishingLineService = require(ServerScriptService.Modules.FishingLineService)
local FishingService = require(ServerScriptService.Modules.FishingService)
local SellFishService = require(ServerScriptService.Modules.SellFishService)
local SkinRodService = require(ServerScriptService.Modules.SkinRodService)

local remotes = RemotesUtil.Get()

PlayerDataService.Init()
FishingLineService.Init()
FishingService.Init(remotes)
SellFishService.Init(remotes)
SkinRodService.Init(remotes)

local function onPlayerReady(player)
	local attempts = 0
	while not PlayerDataService.IsLoaded(player) and player.Parent and attempts < 100 do
		task.wait(0.1)
		attempts += 1
	end
	if not PlayerDataService.IsLoaded(player) then return end

	-- Restore saat karakter spawn (karena Backpack di-reset setiap respawn)
	player.CharacterAdded:Connect(function(character)
		local inventory = PlayerDataService.GetInventory(player)
		if #inventory > 0 then
			InventoryService.RestoreInventory(player, inventory)
		end
	end)

	-- Jika karakter sudah ada saat ini
	if player.Character then
		local inventory = PlayerDataService.GetInventory(player)
		if #inventory > 0 then
			InventoryService.RestoreInventory(player, inventory)
		end
	end
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(onPlayerReady, player)
end)

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerReady, player)
end