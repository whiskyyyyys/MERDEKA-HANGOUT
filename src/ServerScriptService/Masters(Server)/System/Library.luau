local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local DataStore = DataStoreService:GetDataStore("Masters", "Library")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local storage = ReplicatedStorage:WaitForChild("Masters(Storage)")
local modules = storage.Modules

local Configuration = require(modules.Configuration)
local OnlineStations = require(modules.OnlineStations)

local module = {}

-- Configuration

local FLUSH_INTERVAL = 60
local MAX_SONGS = 30
local MAX_ARTISTS = 30
local MAX_PLAYLISTS = 30
local MAX_PLAYLIST_SONGS = 30

-- Buffer

local Buffer = {}
local BufferStatus = {}

-- Types

export type PlaylistInfo = {
	Name: string,
	Cover: string,
}

-- Utilities

local function GetDefaultLibrary()
	return {
		Artists = {},
		Songs = {},
		Playlist = {},
	}
end

local function FindIndex(List, Key, Value)
	for i, Entry in List do
		if Entry[Key] == Value then
			return i
		end
	end
end

local function GetUserBuffer(UserId)
	local UserBuffer = Buffer[UserId]
	if UserBuffer then
		return UserBuffer
	end

	local success, Data = pcall(function()
		return DataStore:GetAsync(tostring(UserId))
	end)

	UserBuffer = (success and Data) or GetDefaultLibrary()
	Buffer[UserId] = UserBuffer
	BufferStatus[UserId] = false

	return UserBuffer
end

-- Fetch

function module.FetchLibrary(UserId)
	local UserBuffer = Buffer[UserId]
	
	if UserBuffer then
		return UserBuffer
	end

	local Data
	
	pcall(function()
		Data = DataStore:GetAsync(UserId)
	end)

	return Data or GetDefaultLibrary()
end

function module.GetPlaylistByPlaylistId(UserId, PlaylistId)
	local Library = GetUserBuffer(UserId)
	local Index = FindIndex(Library.Playlist, "PlaylistId", PlaylistId)
	
	return if Index then Library.Playlist[Index] else nil
end

function module.GetPlaylists(UserId)
	local Library = GetUserBuffer(UserId)
	
	return Library.Playlist or {}
end

function module.GetPlaylistIdByName(UserId, Name)
	local Library = GetUserBuffer(UserId)
	local Index = FindIndex(Library.Playlist, "Name", Name)

	return if Index then Library.Playlist[Index].PlaylistId else nil
end

-- Songs

function module.SetSong(UserId, SongId, State)
	local Library = GetUserBuffer(UserId)
	local Index = FindIndex(Library.Songs, "SongId", SongId)

	if State then
		if Index then return true end
		if #Library.Songs >= MAX_SONGS then return false, "limit" end

		table.insert(Library.Songs, {
			SongId = tonumber(SongId) or 0,
			Pin = false,
		})
	else
		if Index then
			table.remove(Library.Songs, Index)
		end
	end

	return true
end

function module.IsSongSaved(UserId, SongId)
	local Library = GetUserBuffer(UserId)
	return FindIndex(Library.Songs, "SongId", SongId) ~= nil
end

-- Artists

function module.SetArtist(UserId, ArtistName, State)
	local Library = GetUserBuffer(UserId)
	local Index = FindIndex(Library.Artists, "Name", ArtistName)

	if State then
		if Index then return true end
		if #Library.Artists >= MAX_ARTISTS then return false, "limit" end

		table.insert(Library.Artists, {
			Name = ArtistName,
			Pin = false,
		})
	else
		if Index then
			table.remove(Library.Artists, Index)
		end
	end

	return true
end

function module.IsArtistSaved(UserId, ArtistName)
	local Library = GetUserBuffer(UserId)
	return FindIndex(Library.Artists, "Name", ArtistName) ~= nil
end

-- Playlists

local function ResolveUniqueName(Library, WantedName)
	local CurrentName = WantedName
	
	local function IsNameTaken(name)
		for _, playlist in Library.Playlist do
			if playlist.Name == name then return true end
		end
		
		return false
	end

	while IsNameTaken(CurrentName) do
		CurrentName = CurrentName .. " (Copy)"
	end

	return CurrentName
end

function module.CreatePlaylist(UserId, PlaylistInfo: PlaylistInfo)
	local Library = GetUserBuffer(UserId)
	if #Library.Playlist >= MAX_PLAYLISTS then return false, "limit" end

	local UniqueName = ResolveUniqueName(Library, PlaylistInfo.Name)
	local PlaylistId = `MASTERSPLAYLIST:{tick()}_{UserId}`

	table.insert(Library.Playlist, {
		Name = UniqueName,
		CreatorId = UserId,
		Cover = PlaylistInfo.Cover,
		PlaylistId = PlaylistId,
		Private = true,
		Pin = false,
		Songs = {},
		Updated = os.time(),
	})

	BufferStatus[UserId] = true
	return true, PlaylistId
end

function module.SetSongToPlaylist(UserId, PlaylistId, SongId, State)
	local Library = GetUserBuffer(UserId)
	local PlaylistIndex = FindIndex(Library.Playlist, "PlaylistId", PlaylistId)
	if not PlaylistIndex then return false, "unknown" end

	local Playlist = Library.Playlist[PlaylistIndex]

	if Playlist.CreatorId ~= UserId then
		return false, "unowned"
	end

	local SongIndex = table.find(Playlist.Songs, SongId)

	if State then
		if SongIndex then return true end
		if #Playlist.Songs >= MAX_PLAYLIST_SONGS then return false, "limit" end
		
		table.insert(Playlist.Songs, tonumber(SongId) or 0)
		Playlist.Updated = os.time()
	else
		if SongIndex then
			table.remove(Playlist.Songs, SongIndex)
			Playlist.Updated = os.time()
		end
	end

	BufferStatus[UserId] = true
	return true
end

function module.DeletePlaylist(UserId, PlaylistId)
	local Library = GetUserBuffer(UserId)
	local Index = FindIndex(Library.Playlist, "PlaylistId", PlaylistId)
	
	if Index then
		table.remove(Library.Playlist, Index)
	end
end

function module.SetPlaylistProperty(UserId, PlaylistId, Property, Value)
	local Library = GetUserBuffer(UserId)
	local Index = FindIndex(Library.Playlist, "PlaylistId", PlaylistId)
	if not Index then return false, "unknown" end

	Library.Playlist[Index][Property] = Value
	Library.Playlist[Index].Updated = os.time()
	
	BufferStatus[UserId] = true

	return true
end

function module.AddPublicPlaylist(UserId, CreatorId, PlaylistId, DuplicateCopy)
	local Library = GetUserBuffer(UserId)

	if #Library.Playlist >= MAX_PLAYLISTS then
		return false, "limit"
	end

	local success, CreatorData = pcall(function()
		return DataStore:GetAsync(tostring(CreatorId))
	end)

	if not success or not CreatorData then return false, "unknown" end

	local SourceIndex = FindIndex(CreatorData.Playlist, "PlaylistId", PlaylistId)
	if not SourceIndex then return false, "unknown" end

	local Source = CreatorData.Playlist[SourceIndex]
	if Source.Private then return false, "private" end

	local FinalName = ResolveUniqueName(Library, Source.Name)

	local NewPlaylistEntry = {
		Name = FinalName,
		Cover = Source.Cover,
		Private = false,
		Pin = false,
		Songs = table.clone(Source.Songs),
	}

	if DuplicateCopy then
		NewPlaylistEntry.CreatorId = UserId
		NewPlaylistEntry.PlaylistId = `MASTERSPLAYLIST:{tick()}_{UserId}`
		NewPlaylistEntry.Updated = os.time()
	else
		NewPlaylistEntry.CreatorId = CreatorId
		NewPlaylistEntry.PlaylistId = Source.PlaylistId
		NewPlaylistEntry.Updated = Source.Updated
	end

	table.insert(Library.Playlist, NewPlaylistEntry)

	BufferStatus[UserId] = true
	return true, NewPlaylistEntry.PlaylistId
end

-- Stations

function module.CopyOnlineStation(UserId, StationId)
	local Library = GetUserBuffer(UserId)

	if #Library.Playlist >= MAX_PLAYLISTS then
		return false, "limit"
	end

	local Source = OnlineStations.GetOnlineStationByStationId(StationId)
	if not Source then return false, "unknown" end

	local FinalName = ResolveUniqueName(Library, Source.Name)

	local NewPlaylistEntry = {
		Name = FinalName,
		CreatorId = UserId,
		Cover = Source.Cover,
		PlaylistId = `MASTERSPLAYLIST:{tick()}_{UserId}`,
		Private = false,
		Pin = false,
		Updated = os.time(),
		Songs = table.clone(Source.Songs),
	}

	table.insert(Library.Playlist, NewPlaylistEntry)

	BufferStatus[UserId] = true
	return true, NewPlaylistEntry.PlaylistId
end

function module.CopyLocalStation(UserId, StationId)
	local Library = GetUserBuffer(UserId)

	if #Library.Playlist >= MAX_PLAYLISTS then
		return false, "limit"
	end

	local Source = Configuration.GetLocalStationByStationId(StationId)
	if not Source then return false, "unknown" end

	local FinalName = ResolveUniqueName(Library, Source.Name)

	local NewPlaylistEntry = {
		Name = FinalName,
		CreatorId = UserId,
		Cover = Source.Cover,
		PlaylistId = `MASTERSPLAYLIST:{tick()}_{UserId}`,
		Private = false,
		Pin = false,
		Updated = os.time(),
		Songs = table.clone(Source.Songs),
	}

	table.insert(Library.Playlist, NewPlaylistEntry)

	BufferStatus[UserId] = true
	return true, NewPlaylistEntry.PlaylistId
end

-- Pinning

function module.Pin(UserId, Type, Identifier, State)
	local Library = GetUserBuffer(UserId)

	if Type == "Song" then
		local Index = FindIndex(Library.Songs, "SongId", Identifier)
		
		if Index then
			Library.Songs[Index].Pin = State
		end

	elseif Type == "Artist" then
		local Index = FindIndex(Library.Artists, "Name", Identifier)
		
		if Index then
			Library.Artists[Index].Pin = State
		end

	elseif Type == "Playlist" then
		local Index = FindIndex(Library.Playlist, "PlaylistId", Identifier)
		
		if Index then
			Library.Playlist[Index].Pin = State
		end
	end
end

function module.IsPinned(UserId, Type, Identifier)
	local Library = GetUserBuffer(UserId)
	local Index = FindIndex(Library.Songs, "SongId", Identifier)
	
	if Type == "Song" then
		local Index = FindIndex(Library.Songs, "SongId", Identifier)
		
		if Index then
			return Library.Songs[Index].Pin
		end

	elseif Type == "Artist" then
		local Index = FindIndex(Library.Artists, "Name", Identifier)
		
		if Index then
			return Library.Artists[Index].Pin
		end

	elseif Type == "Playlist" then
		local Index = FindIndex(Library.Playlist, "PlaylistId", Identifier)
		
		if Index then
			return Library.Playlist[Index].Pin
		end
	end
end

-- Flush

function module.Flush(UserId)
	local Library = Buffer[UserId]
	if not Library or BufferStatus[UserId] ~= true then return end

	local success, err = pcall(function()
		DataStore:SetAsync(tostring(UserId), Library)
	end)

	if success then
		BufferStatus[UserId] = false
	else
		warn("Library: Failed to flush for " .. UserId .. ": " .. err)
	end
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