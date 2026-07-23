local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local DataStore = DataStoreService:GetDataStore("Masters", "Preferences")

local module = {}

-- Configuration

local FLUSH_INTERVAL = 60
local LIMIT = 90

local Buffer = {}
local BufferStatus = {}

-- Defaults

local function GetDefaultPreferences()
	return {
		Artists = {
			Block = {},
		},
		Songs = {
			Favorite = {},
			Dislike = {},
		},
	}
end

local function DeepCopy(tbl)
	local copy = {}
	for k, v in tbl do
		if type(v) == "table" then
			copy[k] = DeepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

-- Utilities

local function FindIndex(array, value)
	for i, v in array do
		if v == value then
			return i
		end
	end
end

local function ExistsIn(array, value)
	return FindIndex(array, value) ~= nil
end

local function RemoveIfExists(array, value)
	local i = FindIndex(array, value)
	if i then
		table.remove(array, i)
	end
end

local function CanInsert(array)
	return #array < LIMIT
end

-- Load

local function GetUserBuffer(UserId)
	if Buffer[UserId] then
		return Buffer[UserId]
	end

	local stored
	pcall(function()
		stored = DataStore:GetAsync(UserId)
	end)

	local data = stored or GetDefaultPreferences()
	local buffer = DeepCopy(data)

	Buffer[UserId] = buffer
	return buffer
end

-- Fetch

function module.FetchPreference(UserId)
	if Buffer[UserId] then
		return Buffer[UserId]
	end

	local data
	pcall(function()
		data = DataStore:GetAsync(UserId)
	end)

	return data or GetDefaultPreferences()
end

-- Artist Preferences

function module.BlockArtist(UserId, ArtistName, State)
	if not ArtistName then return false end

	local buf = GetUserBuffer(UserId)
	local Block = buf.Artists.Block

	if State then
		if not ExistsIn(Block, ArtistName) then
			if not CanInsert(Block) then return false, "limit" end
			
			table.insert(Block, ArtistName)
		end
	else
		RemoveIfExists(Block, ArtistName)
	end
end

-- Song Preferences

function module.FavoriteSong(UserId, SongId, State)
	if not SongId then return false end

	local buf = GetUserBuffer(UserId)
	local Fav = buf.Songs.Favorite
	local Dis = buf.Songs.Dislike

	if State then
		if not ExistsIn(Fav, SongId) then
			if not CanInsert(Fav) then return false, "limit" end
			RemoveIfExists(Dis, SongId)
			table.insert(Fav, SongId)
		end
	else
		RemoveIfExists(Fav, SongId)
	end
end

function module.DislikeSong(UserId, SongId, State)
	if not SongId then return false end

	local buf = GetUserBuffer(UserId)
	local Fav = buf.Songs.Favorite
	local Dis = buf.Songs.Dislike

	if State then
		if not ExistsIn(Dis, SongId) then
			if not CanInsert(Dis) then return false, "limit" end
			RemoveIfExists(Fav, SongId)
			table.insert(Dis, SongId)
		end
	else
		RemoveIfExists(Dis, SongId)
	end
end

-- Status Queries

function module.IsSongFavorite(UserId, SongId)
	return ExistsIn(module.FetchPreference(UserId).Songs.Favorite, SongId)
end

function module.IsSongDislike(UserId, SongId)
	return ExistsIn(module.FetchPreference(UserId).Songs.Dislike, SongId)
end

function module.IsArtistBlock(UserId, Artist)
	return ExistsIn(module.FetchPreference(UserId).Artists.Block, Artist)
end

function module.GetArtistStatus(UserId, ArtistName)
	if not ArtistName then return nil end

	if module.IsArtistBlock(UserId, ArtistName) then
		return "Blocked"
	else
		return nil
	end
end

function module.GetSongStatus(UserId, SongId)
	if not SongId then return nil end

	if module.IsSongFavorite(UserId, SongId) then
		return "Favorited"
	elseif module.IsSongDislike(UserId, SongId) then
		return "Disliked"
	else
		return nil
	end
end

-- Flush

function module.Flush(UserId)
	local Preferences = Buffer[UserId]
	
	if not Preferences then return end
	if BufferStatus[UserId] then return end
	
	BufferStatus[UserId] = true

	pcall(function()
		DataStore:UpdateAsync(UserId, function()
			return DeepCopy(Preferences)
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

task.spawn(function()
	while true do
		task.wait(FLUSH_INTERVAL)
		module.FlushAll()
	end
end)

-- Cleanup

Players.PlayerRemoving:Connect(function(player)
	module.Flush(player.UserId)
end)

if RunService:IsServer() then
	game:BindToClose(function()
		module.FlushAll()
	end)
end

return module