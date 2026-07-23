local MessagingService = game:GetService("MessagingService")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local storage = ReplicatedStorage:WaitForChild("Masters(Storage)")
local events = storage.Events
local modules = storage.Modules

local server = script.Parent.Parent
local system = server.System

local Algorithm = require(system.Algorithm)

local Configuration = require(modules.Configuration)
local Listeners = require(modules.Listeners)

local TextFiltering = require(modules.TextFiltering)
local Utilities = require(modules.Utilities)

-- Events
-- Events / UI

events.Modules.TextFiltering.FilterText.OnServerInvoke = function(client, mode, text, targetUserId)
	if mode == "Player" then
		local target = Players:GetPlayerByUserId(targetUserId)
		
		if target then
			return TextFiltering.FilterForPlayer(text, client.UserId, target)
		end
		
	elseif mode == "Broadcast" then
		return TextFiltering.FilterBroadcast(text, client.UserId)
	end

	return string.rep("#", #text)
end

-- Events / Modules
-- Events / Modules / Listeners

events.Modules.Listeners.UpdateListener.OnServerEvent:Connect(function(Player, Data)
	if not Data.CurrentSoundId or not Data.ContinuePlaying or not Data.Queue then return end
	
	Listeners.UpdateListener(Player.UserId, Data)
end)

events.Modules.Listeners.GetListeners.OnServerInvoke = function()
	return Listeners.GetListeners()
end

events.Modules.Listeners.GetCurrentTimestamp.OnServerInvoke = function(Player, UserId, SoundId)
	local Receiver = Players:GetPlayerByUserId(UserId)
	if not Receiver then return end
	
	local CurrentTimestamp = events.Modules.Listeners.GetCurrentTimestamp:InvokeClient(Receiver, SoundId)
	if not CurrentTimestamp then return end
	
	return CurrentTimestamp
end

Players.PlayerAdded:Connect(function(Player)
	Listeners.AddListener(Player.UserId)
end)

Players.PlayerRemoving:Connect(function(Player)
	Listeners.RemoveListener(Player.UserId)
end)