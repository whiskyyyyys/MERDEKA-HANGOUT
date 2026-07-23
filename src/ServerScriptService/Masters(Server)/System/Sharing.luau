local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataStore = DataStoreService:GetDataStore("Masters", "Sharing")

local systems = script.Parent

local SessionSaving = require(systems.SessionSaving)
local Settings = require(systems.Settings)

local module = {}

local FLUSH_INTERVAL = 30
local MAX_SHARED_ITEMS = 30

local Buffer = {}
local BufferStatus = {}

-- Utilities

local function EnsureLoaded(UserId)
	if not Buffer[UserId] then
		local success, data = pcall(function()
			return DataStore:GetAsync(tostring(UserId))
		end)

		Buffer[UserId] = (success and data) or {}
		BufferStatus[UserId] = false
	end

	return Buffer[UserId]
end

-- Functions

function module.FetchSharedWithYou(UserId)
	return EnsureLoaded(UserId)
end

function module.Share(SenderId, ReceiverId, Type, Identifier)	
	local ReceiverSettings = Settings.FetchSettings(ReceiverId)
	
	if not ReceiverSettings.Socials.Sharing then
		return false, "disabled"
	end
	
	local SenderSettings = Settings.FetchSettings(SenderId)
	
	if not SenderSettings.Socials.Sharing then
		return false, "setting disabled"
	end

	local Inbox = EnsureLoaded(ReceiverId)
	
	if #Inbox >= MAX_SHARED_ITEMS then
		table.remove(Inbox, #Inbox)
	end

	table.insert(Inbox, 1, {
		Type = Type,
		Identifier = Identifier,
		Sender = SenderId,
		TimeSent = os.time()
	})

	BufferStatus[ReceiverId] = true
	SessionSaving.SaveReceiver(SenderId, ReceiverId)

	return true
end

function module.IsShared(UserId, Type, Identifier)
	local Inbox = EnsureLoaded(UserId)

	local LatestSender = nil
	local LatestDate = nil
	local TotalCount = 0

	for i = #Inbox, 1, -1 do
		local Item = Inbox[i]

		if Item.Type == Type and Item.Identifier == Identifier then
			if TotalCount == 0 then
				LatestSender = Item.Sender
				LatestDate = Item.TimeSent
			end

			TotalCount += 1
		end
	end

	if LatestDate and LatestSender then
		return {LatestSender = LatestSender, LatestDate = LatestDate, TotalCount = TotalCount}
	else
		return nil
	end
end

function module.Flush(UserId)
	if BufferStatus[UserId] then
		local success, err = pcall(function()
			DataStore:SetAsync(tostring(UserId), Buffer[UserId])
		end)

		if success then
			BufferStatus[UserId] = false
		else
			warn("Saving: Failed to flush for " .. UserId .. ": " .. err)
		end
	end
end

function module.FlushAll()
	for UserId, isDirty in pairs(BufferStatus) do
		if isDirty then
			module.Flush(UserId)
		end
	end
end

-- Autosave

task.spawn(function()
	while true do
		task.wait(FLUSH_INTERVAL)
		module.FlushAll()
	end
end)

-- Cleanup

Players.PlayerRemoving:Connect(function(player)
	module.Flush(player.UserId)
	Buffer[player.UserId] = nil
	BufferStatus[player.UserId] = nil
end)

if RunService:IsServer() then
	game:BindToClose(function()
		module.FlushAll()
	end)
end

return module