local Players = game:GetService("Players")
local DataStore = game:GetService("DataStoreService"):GetDataStore("CVNXAN")
local SpinEvent = game:GetService("ReplicatedStorage"):WaitForChild("Events"):WaitForChild("Spin")
local SpinModule = require(game:GetService("ReplicatedStorage"):WaitForChild("SpinModule"))

local MarketplaceService = game:GetService("MarketplaceService")

local productFunctions = {}

local function PlayerJoined(Player)

	local PlayerStats = Instance.new("Folder",Player)
	PlayerStats.Name = "PlayerStats"

	local SpinTime = Instance.new("NumberValue",PlayerStats)
	SpinTime.Name = "SpinTime"
	SpinTime.Value = SpinModule.Spin.SpinTimeForReward

	spawn(function()
		while wait(1) do
			if SpinTime.Value > 0 then
				SpinTime.Value -= 1
			elseif SpinTime.Value <= 0 then
				SpinTime.Value = SpinModule.Spin.SpinTimeForReward
				local addSpins = game:GetService("ReplicatedStorage"):FindFirstChild("_AddSpins")
				if addSpins then
					addSpins:Invoke(Player, 1)
				end
			end
		end
	end)
end

local function PlayerRemoved(Player)
	-- Fungsi clean up kosong, tidak lagi butuh menyimpan Gems/Cash di sini karena sudah dihandle Leaderstats.server.luau
end

local function StudioSave()
	wait(0.7)
end

Players.PlayerAdded:Connect(PlayerJoined)
Players.PlayerRemoving:Connect(PlayerRemoved)
game:BindToClose(StudioSave)


-- more uncopylocked! our discord https://discord.gg/uUv64J5sPZ