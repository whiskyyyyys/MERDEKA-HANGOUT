local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local DataStore = DataStoreService:GetDataStore("Masters", "Algorithm")

local module = {}

-- Configuration

local FLUSH_INTERVAL = 60
local TOP_LIMIT = 100

local SESSION_INCREMENT = 1

-- Decay tuning

local BASE_DECAY = .95
local MAX_INACTIVE_TIME = 60 * 60 * 24 * 30

-- Runtime Buffer

local Buffer = {}
local BufferStatus = {}

-- Utilities

local function GetDefaultAlgorithm()
	return {
		Artists = {},
		Songs = {},
		Tags = {},
	}
end

local function GetUserBuffer(UserId)
	local UserBuffer = Buffer[UserId]
	if not UserBuffer then
		UserBuffer = {
			Artists = {},
			Songs = {},
			Tags = {},
			SessionMultiplier = 1,
		}
		Buffer[UserId] = UserBuffer
	end
	return UserBuffer
end

local function TrimTopN(List)
	if #List > TOP_LIMIT then
		for i = #List, TOP_LIMIT + 1, -1 do
			table.remove(List, i)
		end
	end
end

-- Arrangement

function module.Arrange(AlgorithmTable, OrderType)
	if OrderType ~= "Relevance" and OrderType ~= "LastUpdate" then
		error("Algortihm: Invalid order type: " .. tostring(OrderType))
	end

	table.sort(AlgorithmTable, function(a, b)
		return (a[OrderType] or 0) > (b[OrderType] or 0)
	end)
end

-- Increment Logic

local function IncrementEntry(List, KeyName, KeyValue, Amount)
	local Now = os.time()

	for _, Entry in List do
		if Entry[KeyName] == KeyValue then
			Entry.Relevance += Amount
			Entry.LastUpdate = Now
			return
		end
	end

	if KeyName == "SongId" then
		table.insert(List, {
			[KeyName] = tonumber(KeyValue),
			Relevance = Amount,
			LastUpdate = Now,
		})
	else
		table.insert(List, {
			[KeyName] = KeyValue,
			Relevance = Amount,
			LastUpdate = Now,
		})
	end
end

-- Decay

local function ApplyDecay(List)
	local Now = os.time()

	for _, Entry in List do
		local LastUpdate = Entry.LastUpdate or Now
		local InactiveTime = math.clamp(Now - LastUpdate, 0, MAX_INACTIVE_TIME)

		local TimeFactor = InactiveTime / MAX_INACTIVE_TIME
		local DecayMultiplier = BASE_DECAY ^ (1 + TimeFactor * 4)

		Entry.Relevance = math.floor(Entry.Relevance * DecayMultiplier)
	end
end

-- Functions

function module.FetchAlgorithm(UserId)
	local Data

	pcall(function()
		Data = DataStore:GetAsync(UserId)
	end)

	Data = Data or GetDefaultAlgorithm()

	module.Arrange(Data.Artists, "Relevance")
	module.Arrange(Data.Songs, "Relevance")
	module.Arrange(Data.Tags, "Relevance")

	TrimTopN(Data.Artists)
	TrimTopN(Data.Songs)
	TrimTopN(Data.Tags)

	return Data
end

function module.AddArtist(UserId, ArtistName)
	local UserBuffer = GetUserBuffer(UserId)
	local Weight = math.floor(UserBuffer.SessionMultiplier)

	UserBuffer.Artists[ArtistName] = (UserBuffer.Artists[ArtistName] or 0) + Weight
	UserBuffer.SessionMultiplier += SESSION_INCREMENT
end

function module.AddSong(UserId, SongId)
	local UserBuffer = GetUserBuffer(UserId)
	local Weight = math.floor(UserBuffer.SessionMultiplier)

	UserBuffer.Songs[SongId] = (UserBuffer.Songs[SongId] or 0) + Weight
	UserBuffer.SessionMultiplier += SESSION_INCREMENT
end

function module.AddTag(UserId, Tag)
	local UserBuffer = GetUserBuffer(UserId)
	local Weight = math.floor(UserBuffer.SessionMultiplier)

	UserBuffer.Tags[Tag] = (UserBuffer.Tags[Tag] or 0) + Weight
	UserBuffer.SessionMultiplier += SESSION_INCREMENT
end

-- Flush Logic

function module.Flush(UserId)
	local UserBuffer = Buffer[UserId]
	
	if not UserBuffer then return end
	if BufferStatus[UserId] then return end
	
	BufferStatus[UserId] = true

	pcall(function()
		DataStore:UpdateAsync(UserId, function(OldData)
			OldData = OldData or GetDefaultAlgorithm()

			-- Apply time-aware decay
			ApplyDecay(OldData.Artists)
			ApplyDecay(OldData.Songs)
			ApplyDecay(OldData.Tags)

			-- Merge current session
			for Artist, Count in UserBuffer.Artists do
				IncrementEntry(OldData.Artists, "Name", Artist, Count)
			end
			for SongId, Count in UserBuffer.Songs do
				IncrementEntry(OldData.Songs, "SongId", SongId, Count)
			end
			for Tag, Count in UserBuffer.Tags do
				IncrementEntry(OldData.Tags, "Tag", Tag, Count)
			end

			-- Arrange + trim
			module.Arrange(OldData.Artists, "Relevance")
			module.Arrange(OldData.Songs, "Relevance")
			module.Arrange(OldData.Tags, "Relevance")

			TrimTopN(OldData.Artists)
			TrimTopN(OldData.Songs)
			TrimTopN(OldData.Tags)

			return OldData
		end)
	end)

	Buffer[UserId] = nil
	BufferStatus[UserId] = nil
end

function module.FlushAll()
	for UserId in Buffer do
		module.Flush(UserId)
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

Players.PlayerRemoving:Connect(function(Player)
	module.Flush(Player.UserId)
end)

if RunService:IsServer() then
	game:BindToClose(function()
		module.FlushAll()
	end)
end

return module