local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataStore = DataStoreService:GetDataStore("Masters", "SessionSaving")

local module = {}

local FLUSH_INTERVAL = 60
local MAX_RECEIVERS = 5

local Buffer = {}
local BufferStatus = {}

-- Utilities

local function GetDefaultSession()
	return {
		Playback = {
			SoundId = 0,
			MasterPool = {},
			Context = "None",
			Volume = .5,
			Repeat = false,
			Shuffle = false,
			TimePosition = 0,
		},
		RecentReceivers = {}
	}
end

local function EnsureLoaded(UserId)
	if not Buffer[UserId] then
		local success, data = pcall(function()
			return DataStore:GetAsync(tostring(UserId))
		end)

		if success and data then
			local default = GetDefaultSession()
			
			for key, val in default.Playback do
				if data.Playback[key] == nil then
					data.Playback[key] = val
				end
			end
			
			Buffer[UserId] = data
		else
			Buffer[UserId] = GetDefaultSession()
		end

		BufferStatus[UserId] = false
	end
	
	return Buffer[UserId]
end


function module.FetchSavedSession(UserId)
	local data = EnsureLoaded(UserId)
	return data.Playback
end

function module.FetchRecentReceivers(UserId)
	local data = EnsureLoaded(UserId)
	return data.RecentReceivers
end

function module.SetPlaybackState(UserId, NewData)
	local data = EnsureLoaded(UserId)

	for key, value in NewData do
		if data.Playback[key] ~= nil then
			data.Playback[key] = value
		end
	end

	BufferStatus[UserId] = true
end

function module.SaveReceiver(UserId, ReceiverId)
	local data = EnsureLoaded(UserId)
	local recent = data.RecentReceivers
	local existingIndex = table.find(recent, ReceiverId)
	
	if existingIndex then
		table.remove(recent, existingIndex)
	end

	table.insert(recent, 1, ReceiverId)

	if #recent > MAX_RECEIVERS then
		table.remove(recent, #recent)
	end

	BufferStatus[UserId] = true
end

function module.Flush(UserId)
	if BufferStatus[UserId] == true then
		local success, err = pcall(function()
			--DataStore:SetAsync(tostring(UserId), Buffer[UserId])
		end)

		if success then
			BufferStatus[UserId] = false
		else
			warn("SessionSaving: Failed to flush for " .. UserId .. ": " .. err)
		end
	end
end

function module.FlushAll()
	for userId, isDirty in BufferStatus do
		if isDirty then
			module.Flush(userId)
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