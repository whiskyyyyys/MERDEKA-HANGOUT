local AssetService = game:GetService("AssetService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local storage = ReplicatedStorage:WaitForChild("Masters(Storage)")
local events = storage.Events
local modules = storage.Modules

local Signal = require(modules.Signal)
local Utilities = require(modules.Utilities)

local ArtistSongs = {}
local ChunkSize = 100
local IsLoaded = false

local LoadedMetadatas = {}

local module = {}

-- Metadata Service

function module.GetAudioMetadataAsync(AssetIds)
	assert(type(AssetIds) == "table", "AssetIds must be a table")

	local Batches = Utilities.DivideTableElements(30, AssetIds)
	local Result = table.create(#AssetIds)
	local WriteIndex = 1

	for _, Batch in Batches do
		local success, data = pcall(function()
			return AssetService:GetAudioMetadataAsync(Batch)
		end)

		if success and data then
			for _, meta in data do
				Result[WriteIndex] = meta
				WriteIndex += 1
			end
		else
			warn("GetAudioMetadataAsync failed for batch:", Batch)
		end
	end

	return Result
end

-- Loader Service

-- Loads audios on the background. The table (Container) will be filled with chunks of audios.
function module.LoadAudios(Container)
	task.spawn(function()
		local CurrentChunk = {}
		local count = 0
		local index = 1

		local params = Instance.new("AudioSearchParams")
		params.MinDuration = 30
		params.SearchKeyword = ""

		local pages = AssetService:SearchAudio(params)

		while true do
			local items = pages:GetCurrentPage()

			for _, audio in items do
				table.insert(CurrentChunk, audio)
				count += 1

				if count >= ChunkSize then
					Container[index] = CurrentChunk
					
					module.ChunkLoaded:Fire(index, CurrentChunk)
					
					CurrentChunk = {}
					index += 1
					count = 0
				end
			end

			if pages.IsFinished then
				module.ChunkLoadingFinished:Fire()
				IsLoaded = true
				
				break
			end

			pages:AdvanceToNextPageAsync()
		end
		
		-- Leftovers

		if #CurrentChunk > 0 then
			Container[index] = CurrentChunk
			
			module.ChunkLoaded:Fire(index, CurrentChunk)
		end
	end)
end

-- Yields until all the songs of the provided Artist are loaded.
function module.LoadArtist(ArtistName)
	if ArtistSongs[ArtistName] then
		return ArtistSongs[ArtistName]
	end

	local Songs = {}
	ArtistSongs[ArtistName] = Songs

	local params = Instance.new("AudioSearchParams")
	params.Artist = ArtistName

	local pages = AssetService:SearchAudio(params)

	while true do
		local items = pages:GetCurrentPage()

		for _, audio in items do
			table.insert(Songs, audio)
		end

		if pages.IsFinished then
			break
		end

		pages:AdvanceToNextPageAsync()
	end

	return Songs
end

function module.FetchLoadedArtistSongs(ArtistName)
	return ArtistSongs[ArtistName]
end

function module.GetAudioMetaDataAsync(SongId, Title, Artist)
	if not Title or not Artist then return end
	
	local MetaData

	local AudioSearchParams = Instance.new("AudioSearchParams")
	AudioSearchParams.Title = Title
	AudioSearchParams.Artist = Artist

	local Pages = AssetService:SearchAudio(AudioSearchParams)

	while true do
		local items = Pages:GetCurrentPage()

		for _, audio in items do
			if audio.Id == SongId then
				MetaData = audio

				break
			end
		end

		if Pages.IsFinished then
			break
		end

		Pages:AdvanceToNextPageAsync()
	end
	
	table.insert(LoadedMetadatas, MetaData)
	
	if #LoadedMetadatas > 30 then
		table.remove(LoadedMetadatas, 1)
	end

	return MetaData
end

-- Search Queries / Results

local PreviousSearches = {}
local SearchOrder = {}

local function EnforceSearchLimit()
	while #SearchOrder > 10 do
		local OldestKeyword = table.remove(SearchOrder, 1)
		PreviousSearches[OldestKeyword] = nil
	end
end

function module.SearchAudiosByKeyword(Keyword: string)
	local existing = PreviousSearches[Keyword]
	
	module.SearchedAudio:Fire(Keyword)
	
	if existing then
		local NewSignal = Signal.new()
		
		for _, chunk in existing.Chunks do
			NewSignal:Fire(false, chunk)
		end

		if existing.Finished then
			NewSignal:Fire(true, {})
			
			return {
				ChunkLoaded = NewSignal,
				Advance = function() end,
				Results = existing.Results,
				Finished = true}
		end

		local conn
		
		conn = existing.ChunkLoaded:Connect(function(IsFinished, Chunk)
			NewSignal:Fire(IsFinished, Chunk)
			
			if IsFinished then
				conn:Disconnect()
			end
		end)

		return {
			ChunkLoaded = NewSignal,
			Advance = function() existing.Advance() end,
			Results = existing.Results,
			Finished = existing.Finished,
		}
	end

	local SearchData = {
		Results = {},
		Chunks = {},
		Pages = nil,
		ChunkLoaded = Signal.new(),
		Finished = false,
	}

	PreviousSearches[Keyword] = SearchData
	table.insert(SearchOrder, Keyword)
	EnforceSearchLimit()

	function SearchData.Advance()
		if SearchData.Finished or not SearchData.Pages then
			return
		end

		local success = pcall(function()
			SearchData.Pages:AdvanceToNextPageAsync()
		end)

		if not success then
			SearchData.Finished = true
			SearchData.ChunkLoaded:Fire(true, {})
			
			return
		end

		local Items = SearchData.Pages:GetCurrentPage()
		if Items and #Items > 0 then
			local chunk = {}
			
			for _, a in Items do
				table.insert(SearchData.Results, a)
				table.insert(chunk, a)
			end

			table.insert(SearchData.Chunks, chunk)
			SearchData.ChunkLoaded:Fire(false, chunk)
		end

		if SearchData.Pages.IsFinished then
			SearchData.Finished = true
			SearchData.ChunkLoaded:Fire(true, {})
		end
	end

	task.spawn(function()
		local success, Pages = pcall(function()
			local params = Instance.new("AudioSearchParams")
			
			params.MinDuration = 30
			params.SearchKeyword = Keyword
			
			return AssetService:SearchAudio(params)
		end)

		if not success or not Pages then
			SearchData.Finished = true
			SearchData.ChunkLoaded:Fire(true, {})
			return
		end

		SearchData.Pages = Pages

		local Items = Pages:GetCurrentPage()
		
		if Items and #Items > 0 then
			local chunk = {}
			for _, a in Items do
				table.insert(SearchData.Results, a)
				table.insert(chunk, a)
			end

			table.insert(SearchData.Chunks, chunk)
			SearchData.ChunkLoaded:Fire(false, chunk)
		end

		if Pages.IsFinished then
			SearchData.Finished = true
			SearchData.ChunkLoaded:Fire(true, {})
		end
	end)

	local CallerSignal = Signal.new()

	for _, chunk in SearchData.Chunks do
		CallerSignal:Fire(false, chunk)
	end

	local conn
	
	conn = SearchData.ChunkLoaded:Connect(function(IsFinished, Chunk)
		CallerSignal:Fire(IsFinished, Chunk)
		if IsFinished then
			conn:Disconnect()
		end
	end)

	return {
		ChunkLoaded = CallerSignal,
		Advance = function() SearchData.Advance() end,
		Results = SearchData.Results,
		Finished = SearchData.Finished,
	}
end

function module.FetchSearchedKeywords()
	local List = {}
	
	for Keyword, Data in PreviousSearches do
		table.insert(List, Keyword)
	end
	
	return List
end

-- States

function module.IsLoaded() return IsLoaded end

-- Events

module.ChunkLoaded = Signal.new()
module.SearchedAudio = Signal.new()
module.ChunkLoadingFinished = Signal.new()

return module