local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local DataStore = DataStoreService:GetDataStore("Masters", "Playback")

local module = {}

-- Configuration

local FLUSH_INTERVAL = 60
local TOP_LIMIT = 5

-- Buffer

local Buffer = {}
local BufferStatus = {}

-- Time Utilities

local Months = {
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"
}

function module.CurrentYear()
	return tonumber(os.date("%Y"))
end

function module.PreviousYear()
	return module.CurrentYear() - 1
end

function module.CurrentMonth()
	return Months[tonumber(os.date("%m"))]
end

-- Defaults

local function GetEmptyCurrent()
	return {
		Year = module.CurrentYear(),
		Months = {}
	}
end

local function GetEmptyPrevious()
	return {
		Year = module.PreviousYear(),
		TopArtists = {},
		TopSongs = {},
		PlayedSongs = 0,
		PlayedArtist = 0,
		TotalDuration = 0
	}
end

-- Utilities

local function SortByPlays(List)
	table.sort(List, function(a, b)
		return a.Plays > b.Plays
	end)
end

local function IncrementEntry(List, Key, Value)
	for _, Entry in List do
		if Entry[Key] == Value then
			Entry.Plays += 1
			return
		end
	end
	
	if Key == "SongId" then
		table.insert(List, {[Key] = tonumber(Value) or 0, Plays = 1})
	else
		table.insert(List, {[Key] = Value, Plays = 1})
	end
end

local function GetUserBuffer(UserId)
	local User = Buffer[UserId]
	if not User then
		User = {
			Current = nil,
			Previous = nil,
			DirtyCurrent = false,
			DirtyPrevious = false
		}
		Buffer[UserId] = User
	end
	return User
end

-- Rollover Logic

local function SummarizeCurrentToPrevious(Current)
	local Summary = GetEmptyPrevious()

	for _, MonthData in Current.Months do
		for _, Artist in MonthData.Artists or {} do
			IncrementEntry(Summary.TopArtists, "Name", Artist.Name)
			Summary.PlayedArtist += Artist.Plays
		end

		for _, Song in MonthData.Songs or {} do
			IncrementEntry(Summary.TopSongs, "SongId", Song.SongId)
			Summary.PlayedSongs += Song.Plays
		end

		Summary.TotalDuration += (MonthData.Duration or 0)
	end

	SortByPlays(Summary.TopArtists)
	SortByPlays(Summary.TopSongs)

	while #Summary.TopArtists > TOP_LIMIT do table.remove(Summary.TopArtists) end
	while #Summary.TopSongs > TOP_LIMIT do table.remove(Summary.TopSongs) end

	return Summary
end

local function EnsureYear(UserId)
	local User = GetUserBuffer(UserId)

	if not User.Current then
		User.Current = DataStore:GetAsync(UserId .. "_Current") or GetEmptyCurrent()
	end

	if User.Current.Year ~= module.CurrentYear() then
		local Summary = SummarizeCurrentToPrevious(User.Current)
		User.Previous = Summary
		User.DirtyPrevious = true

		User.Current = GetEmptyCurrent()
		User.DirtyCurrent = true
	end
end

-- Fetch

function module.FetchPlayback(UserId, IncludePrevious, IncludeCurrent)
	EnsureYear(UserId)

	local User = GetUserBuffer(UserId)
	local Result = {}

	if IncludePrevious then
		if not User.Previous then
			User.Previous = DataStore:GetAsync(UserId .. "_Previous") or GetEmptyPrevious()
		end
		Result.Previous = User.Previous
	end

	if IncludeCurrent then
		Result.Current = User.Current.Months
	end

	return Result
end

-- Mutations (Current Month)

function module.AddSong(UserId, SongId)
	EnsureYear(UserId)

	local User = GetUserBuffer(UserId)
	local Month = module.CurrentMonth()

	User.Current.Months[Month] = User.Current.Months[Month] or {
		Artists = {},
		Songs = {},
		Duration = 0
	}

	IncrementEntry(User.Current.Months[Month].Songs, "SongId", SongId)
	User.DirtyCurrent = true
end

function module.AddArtist(UserId, ArtistName)
	EnsureYear(UserId)

	local User = GetUserBuffer(UserId)
	local Month = module.CurrentMonth()

	User.Current.Months[Month] = User.Current.Months[Month] or {
		Artists = {},
		Songs = {},
		Duration = 0
	}

	IncrementEntry(User.Current.Months[Month].Artists, "Name", ArtistName)
	User.DirtyCurrent = true
end

function module.IncreaseDuration(UserId, Seconds)
	EnsureYear(UserId)

	local User = GetUserBuffer(UserId)
	local Month = module.CurrentMonth()

	User.Current.Months[Month] = User.Current.Months[Month] or {
		Artists = {},
		Songs = {},
		Duration = 0
	}

	User.Current.Months[Month].Duration += Seconds
	User.DirtyCurrent = true
end

function module.IsMastersPlaybackAvailable()
	local Month = tonumber(os.date("%m"))
	local Day = tonumber(os.date("%d"))

	if Month ~= 12 then
		return false
	end

	return Day >= 15 and Day <= 31
end

-- Flush

function module.Flush(UserId)
	local Playback = Buffer[UserId]
	
	if not Playback then return end
	if BufferStatus[UserId] then return end
	
	BufferStatus[UserId] = true

	pcall(function()
		if Playback.DirtyCurrent then
			DataStore:SetAsync(UserId .. "_Current", Playback.Current)
		end
		
		if Playback.DirtyPrevious then
			DataStore:SetAsync(UserId .. "_Previous", Playback.Previous)
		end
	end)

	Buffer[UserId] = nil
	BufferStatus[UserId] = nil
end

function module.FlushAll()
	for UserId in Buffer do
		module.Flush(UserId)
	end
end

-- Periodic Flush

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
