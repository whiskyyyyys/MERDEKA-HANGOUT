local Players = game:GetService("Players")
local DataStore = game:GetService("DataStoreService"):GetDataStore("CVNXAN")
local SpinEvent = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Spin")
local SpinModule = require(game:GetService("ReplicatedStorage"):WaitForChild("SpinModule"))

local MarketplaceService = game:GetService("MarketplaceService")

local productFunctions = {}

local function PlayerJoined(Player)

	local leaderstats = Instance.new("Folder",Player)
	leaderstats.Name = "leaderstats"

	local PlayerStats = Instance.new("Folder",Player)
	PlayerStats.Name = "PlayerStats"

	local Cash = Instance.new("NumberValue",leaderstats)
	Cash.Name = "Cash"
	Cash.Value = DataStore:GetAsync("Cash"..Player.UserId) or 0

	local Gems = Instance.new("NumberValue",leaderstats)
	Gems.Name = "Gems"
	Gems.Value = DataStore:GetAsync("Gems"..Player.UserId) or 0

	local SpinTime = Instance.new("NumberValue",PlayerStats)
	SpinTime.Name = "SpinTime"
	SpinTime.Value = SpinModule.Spin.SpinTimeForReward

	local Spin = Instance.new("NumberValue",PlayerStats)
	Spin.Name = "Spin"
	Spin.Value = DataStore:GetAsync("Spin"..Player.UserId) or 1

	spawn(function()
		while wait(1) do
			if SpinTime.Value > 0 then
				SpinTime.Value -= 1
			elseif SpinTime.Value < 0 then
				SpinTime.Value = SpinModule.Spin.SpinTimeForReward
				Spin.Value += 1
			end
		end
	end)
end

local function PlayerRemoved(Player)
	local leaderstats = Player:WaitForChild("leaderstats")
	local PlayerStats = Player:WaitForChild("PlayerStats")

	local Cash = leaderstats:WaitForChild("Cash")
	local Gems = leaderstats:WaitForChild("Gems")
	local Spin = PlayerStats:WaitForChild("Spin")

	DataStore:SetAsync("Cash"..Player.UserId,Cash.Value)
	DataStore:SetAsync("Gems"..Player.UserId,Gems.Value)
	DataStore:SetAsync("Spin"..Player.UserId,Spin.Value)
end

local function StudioSave()
	wait(0.7)
end

local function SpinEventFire(Player,SpinReward)
	local Spin = Player:WaitForChild("PlayerStats"):WaitForChild("Spin")

	if Spin.Value >= 1 then
		Spin.Value -= 1
		local Currency = Player:WaitForChild("leaderstats"):FindFirstChild(SpinModule.Spin.Rewards[SpinReward].Reward)
		if Currency then
			Currency.Value += SpinModule.Spin.Rewards[SpinReward].Amount
		else
			warn(SpinModule.Spin.Rewards[SpinReward].Reward.." not found in leaderstats (leaderstats içinde bulunamadı.)")
		end
	end
end

Players.PlayerAdded:Connect(PlayerJoined)
Players.PlayerRemoving:Connect(PlayerRemoved)
game:BindToClose(StudioSave)
SpinEvent.OnServerEvent:Connect(SpinEventFire)


-- more uncopylocked! our discord https://discord.gg/uUv64J5sPZ