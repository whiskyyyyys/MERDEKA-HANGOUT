local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local storage = ReplicatedStorage:WaitForChild("Masters(Storage)")
local events = storage.Events

local CachedLyrics = {}

local module = {}

function module.HasLyrics(SongId, HasIndex)
	local LyricsIndex
	
	if HasIndex then
		LyricsIndex = HasIndex
	else
		LyricsIndex = events.Modules.LyricsEngine.GetLyricsIndex:InvokeServer()
	end
	
	if not LyricsIndex then return end
	
	if LyricsIndex[SongId] or LyricsIndex[tostring(SongId)] then
		return true
	else
		return false
	end
end

function module.GetLyrics(SongId)
	local LyricsIndex = events.Modules.LyricsEngine.GetLyricsIndex:InvokeServer()
	
	if not LyricsIndex then return end
	if not module.HasLyrics(SongId, LyricsIndex) then return end
	
	local Cached

	for i, Data in CachedLyrics do
		if Data.SoundId == SongId then
			Cached = Data
		end
	end

	if Cached then
		return Cached
	end

	local Data = events.Modules.LyricsEngine.GetLyrics:InvokeServer(LyricsIndex[tostring(SongId)])
	if not Data then return end

	if #CachedLyrics == 30 then
		table.remove(CachedLyrics, 1)
	end 

	table.insert(CachedLyrics, Data)

	return Data
end

return module