local AssetService = game:GetService("AssetService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Storage = ReplicatedStorage:WaitForChild("Masters(Storage)")
local Modules = Storage.Modules
local Events = Storage.Events

local Audios = require(Modules.Audios)
local Settings = require(Modules.Settings)
local Signal = require(Modules.Signal)

local client = Players.LocalPlayer
local ui = client.PlayerGui:WaitForChild("Masters")
local Playback = ui.Playback

-- Variables

local LOAD_TIMEOUT = 10
local MAX_HISTORY = 50
local STREAM_PERCENT = .4
local STREAM_SECONDS = 30
local EQ_TWEEN_TIME = .5

local State = {
	MasterList = {},       
	ContinuePlaying = {},  
	Queue = {},            
	History = {},

	ContextName = "Masters", 
	Pointer = 1,           
	CurrentSongId = 0,
	CurrentMetadata = nil,
	ActiveSound = nil,

	EQs = {
		PlaybackEQ = nil,
		MasterEQ = Playback.Equalizer
	}, 

	Volume = 1,

	IsLoading = false,
	IsCrossfading = false,
	IsPaused = false,

	AccumulatedTime = 0,
	HasStreamed = false,
	HasPlayedOnce = false,

	HeartbeatConnection = nil, 

	Settings = {
		Shuffle = false,
		RepeatMode = "Queue", 
	}
}

local CachedMetadatas = {}

local module = {}

-- Signals

module.TrackChanged = Signal.new()
module.QueueUpdated = Signal.new()
module.StatusChanged = Signal.new()

-- Utilities

local function RebuildTrackingIds(TargetTable, Prefix)
	for i, Item in ipairs(TargetTable) do
		Item.TrackingId = Prefix .. "-" .. i
	end
end

local function UpdateStatus()
	module.StatusChanged:Fire({
		IsLoading = State.IsLoading,
		IsCrossfading = State.IsCrossfading,
		IsPaused = State.IsPaused,

		CurrentSong = State.CurrentSongId,
		ContextName = State.ContextName,

		Settings = {
			RepeatMode = State.Settings.RepeatMode,
			Shuffle = State.Settings.Shuffle,
		}
	})
end

local function PreloadNextTracks()
	local Instances = {}
	local function Create(Id)
		local S = Instance.new("Sound")

		S.SoundId = "rbxassetid://" .. Id

		table.insert(Instances, S)
	end

	if #State.Queue > 0 then Create(State.Queue[1].Id) end
	if State.Pointer < #State.ContinuePlaying then Create(State.ContinuePlaying[State.Pointer + 1].Id) end

	task.spawn(function()
		ContentProvider:PreloadAsync(Instances)

		for _, S in Instances do S:Destroy() end
	end)
end

local function GenerateShuffleList(List)
	local Shuffled = table.clone(List)

	for i = #Shuffled, 2, -1 do
		local j = math.random(1, i)
		Shuffled[i], Shuffled[j] = Shuffled[j], Shuffled[i]
	end

	return Shuffled
end

local CurrentThread

local function LoadMetadata(SongId)
	if CurrentThread then
		task.cancel(CurrentThread)
		CurrentThread = nil
	end

	for _, Cache in CachedMetadatas do
		if Cache.AssetId == SongId then
			State.CurrentMetadata = Cache
			return
		end
	end

	local Data = Audios.GetAudioMetadataAsync({SongId})
	if not Data then return end
	if not Data[1].Title or not Data[1].Artist then return end

	Data[1].Id = SongId
	State.CurrentMetadata = Data[1]

	CurrentThread = task.spawn(function()
		if not State.CurrentMetadata then return end

		local Metadata = Audios.GetAudioMetaDataAsync(SongId, State.CurrentMetadata.Title, State.CurrentMetadata.Artist)
		if not Metadata then return end

		State.CurrentMetadata.UpdateTime = Metadata.UpdateTime
		State.CurrentMetadata.CreateTime = Metadata.CreateTime
		State.CurrentMetadata.Tags =  Metadata.Tags

		if #CachedMetadatas >= 30 then
			table.remove(CachedMetadatas, 1)
		end

		table.insert(CachedMetadatas, State.CurrentMetadata)
	end)
end

local function TransitionTo(SongId, PlayInstantly, DisableCrossfade)
	if State.IsLoading then return end

	if State.HeartbeatConnection then
		State.HeartbeatConnection:Disconnect()
		State.HeartbeatConnection = nil
	end

	State.IsLoading = true
	State.HasStreamed = false
	State.IsPaused = not PlayInstantly

	UpdateStatus()
	LoadMetadata(SongId)

	module.QueueUpdated:Fire()

	local SettingsData = Settings.FetchSettings()

	local XfadeTiming
	local FadeTime

	if SettingsData and SettingsData.Playback.Crossfade.Enabled then
		XfadeTiming = SettingsData.Playback.Crossfade.Duration
		FadeTime = DisableCrossfade and 0 or SettingsData.Playback.Crossfade.Duration
	else
		XfadeTiming = 0
		FadeTime = 0
	end

	-- Sound Setup

	local NewSound = Instance.new("Sound")
	local EQ = Instance.new("EqualizerSoundEffect")

	NewSound.Name = tostring(SongId)
	NewSound.SoundId = "rbxassetid://" .. SongId
	NewSound.Volume = 0
	NewSound.SoundGroup = Playback
	NewSound.Parent = Playback

	EQ.Name = "PlaybackEQ"
	EQ.HighGain = 0
	EQ.LowGain = 0
	EQ.MidGain = 0
	EQ.Parent = NewSound

	-- Loading

	local LoadFailed = false

	local Timeout = task.delay(LOAD_TIMEOUT, function()
		if not NewSound.IsLoaded then
			LoadFailed = true

			NewSound:Destroy()

			State.IsLoading = false

			UpdateStatus()

			module.Next(true)
		end
	end)

	if not NewSound.IsLoaded then
		NewSound.Loaded:Wait()
	end

	if LoadFailed then return end

	task.cancel(Timeout)

	-- History

	if State.CurrentSongId then
		table.insert(State.History, State.CurrentSongId)

		if #State.History > MAX_HISTORY then
			table.remove(State.History, 1)
		end
	end

	local OldSound = State.ActiveSound

	State.ActiveSound = NewSound
	State.EQs.PlaybackEQ = EQ
	State.CurrentSongId = SongId
	State.AccumulatedTime = 0
	State.HasStreamed = false
	State.IsLoading = false

	if PlayInstantly then
		NewSound:Play()
	end

	-- Transition

	State.IsCrossfading = FadeTime > 0

	if OldSound and FadeTime > 0 then
		TweenService:Create(NewSound, TweenInfo.new(FadeTime), {
			Volume = State.Volume}):Play()

		local FadeOut = TweenService:Create(OldSound, TweenInfo.new(FadeTime), {
			Volume = 0})

		FadeOut:Play()

		FadeOut.Completed:Once(function()
			OldSound:Destroy()
			State.IsCrossfading = false
			UpdateStatus()
		end)

	else
		NewSound.Volume = State.Volume

		if OldSound then OldSound:Destroy() end

		task.defer(function()
			State.IsCrossfading = false
			UpdateStatus()
		end)
	end

	UpdateStatus()
	module.TrackChanged:Fire(SongId)
	PreloadNextTracks()

	-- Autonext

	task.spawn(function()
		while NewSound.TimeLength <= 0 do
			RunService.Heartbeat:Wait()
		end

		local StreamGoal = math.min(STREAM_SECONDS, NewSound.TimeLength * STREAM_PERCENT)

		State.HeartbeatConnection = RunService.Heartbeat:Connect(function(Delta)
			if not NewSound.Parent then return end
			if State.IsPaused or State.IsLoading then return end

			if NewSound.IsPlaying then
				State.AccumulatedTime += Delta
			end

			if not State.HasStreamed and State.AccumulatedTime >= StreamGoal then
				State.HasStreamed = true

				Events.Main.Algorithm.AddSong:FireServer(SongId)
				Events.Main.Playback.AddSong:FireServer(SongId)

				if State.CurrentMetadata and tonumber(State.CurrentMetadata.AssetId) == SongId then
					Events.Main.Algorithm.AddArtist:FireServer(State.CurrentMetadata.Artist)

					Events.Main.Playback.AddArtist:FireServer(State.CurrentMetadata.Artist)
					Events.Main.Playback.IncreaseDuration:FireServer(State.CurrentMetadata.Duration or 0)

					if State.CurrentMetadata.Tags then
						Events.Main.Algorithm.AddTags:FireServer(State.CurrentMetadata.Tags[1])
					end
				end
			end

			local Remaining = NewSound.TimeLength - NewSound.TimePosition

			if Remaining <= math.max(XfadeTiming, .25) then
				State.HeartbeatConnection:Disconnect()
				State.HeartbeatConnection = nil

				module.Next(true)
			end
		end)
	end)
end

-- Functions
-- Functions / States

function module.GetCurrentSongId() return State.CurrentSongId end
function module.GetActiveSound() return State.ActiveSound end
function module.GetContextName() return State.ContextName end
function module.GetState() return State end
function module.GetLoadingStatus() return State.IsLoading end
function module.GetCrossfadingStatus() return State.IsCrossfading end
function module.GetPausedStatus() return State.IsPaused end
function module.GetSettings() return State.Settings end
function module.GetCurrentMetadata() return State.CurrentMetadata end

function module.GetVisualQueue()
	local ContextItems = {}
	for i = State.Pointer + 1, #State.ContinuePlaying do
		table.insert(ContextItems, State.ContinuePlaying[i])
	end
	return {
		NowPlaying = State.CurrentSongId,
		ContextName = State.ContextName,
		Queue = table.clone(State.Queue),
		ContinuePlaying = ContextItems
	}
end

-- Functions / Playback

function module.Pause()
	if not State.ActiveSound or State.IsPaused then return end

	State.IsPaused = true
	State.ActiveSound:Pause()

	UpdateStatus()
end

function module.Resume()
	if not State.ActiveSound or not State.IsPaused then return end

	State.IsPaused = false
	State.ActiveSound:Resume()

	local Info = TweenInfo.new(.5, Enum.EasingStyle.Sine)

	State.ActiveSound.Volume = 0

	TweenService:Create(State.ActiveSound, Info, {Volume = State.Volume}):Play()

	if State.EQs.PlaybackEQ then
		State.EQs.PlaybackEQ.LowGain = 10
		State.EQs.PlaybackEQ.MidGain = -80
		State.EQs.PlaybackEQ.HighGain = -80

		TweenService:Create(State.EQs.PlaybackEQ, Info, {
			LowGain = 0,
			MidGain = 0,
			HighGain = 0}):Play()
	end

	UpdateStatus()
end

function module.ToggleRepeat()	
	if State.Settings.RepeatMode == "Queue" then
		State.Settings.RepeatMode = "Song"
	elseif State.Settings.RepeatMode == "Song" then
		State.Settings.RepeatMode = "Queue"
	end

	UpdateStatus()
end

function module.RemoveByTrackingId(TrackingId)
	local Prefix = string.split(TrackingId, "-")[1]

	if Prefix == "Q" then
		for i, Item in ipairs(State.Queue) do
			if Item.TrackingId == TrackingId then
				table.remove(State.Queue, i)
				RebuildTrackingIds(State.Queue, "Q")
				break
			end
		end

	elseif Prefix == "CP" then
		for i, Item in ipairs(State.ContinuePlaying) do
			if Item.TrackingId == TrackingId and i ~= State.Pointer then
				table.remove(State.ContinuePlaying, i)
				RebuildTrackingIds(State.ContinuePlaying, "CP")
				if i < State.Pointer then State.Pointer -= 1 end
				break
			end
		end
	end

	module.QueueUpdated:Fire()
end

function module.ProceedByTrackingId(TrackingId)
	if State.IsLoading or State.IsCrossfading then return end
	if not TrackingId then return end

	local Prefix = string.split(TrackingId, "-")[1]

	-- User-added Songs

	if Prefix == "Q" then
		for i, Item in ipairs(State.Queue) do
			if Item.TrackingId == TrackingId then
				for _ = 1, i - 1 do
					table.remove(State.Queue, 1)
				end

				local Target = table.remove(State.Queue, 1)
				RebuildTrackingIds(State.Queue, "Q")
				module.QueueUpdated:Fire()

				TransitionTo(Target.Id, true, true)
				return
			end
		end
	end

	-- From Masterpool

	if Prefix == "CP" then
		for i, Item in ipairs(State.ContinuePlaying) do
			if Item.TrackingId == TrackingId then
				-- Already playing
				if i == State.Pointer then
					return
				end

				State.Pointer = i

				TransitionTo(Item.Id, true, true)
				return
			end
		end
	end
end

function module.ClearQueue()
	if State.IsLoading or State.IsCrossfading then return end
	if #State.Queue == 0 then return end

	State.Queue = {}
	module.QueueUpdated:Fire()
end

function module.ClearContinuePlaying()
	if State.IsLoading or State.IsCrossfading then return end
	if not State.CurrentSongId then return end

	local CurrentItem = State.ContinuePlaying[State.Pointer]
	if not CurrentItem then return end

	State.ContinuePlaying = {
		{
			Id = CurrentItem.Id,
			TrackingId = "CP-1",
			Source = CurrentItem.Source
		}
	}

	State.Pointer = 1
	module.QueueUpdated:Fire()
end


function module.LoadSource(SongIds, StartIndex, ContextName, PlayInstantly)
	State.IsLoading = false
	State.IsCrossfading = false 

	State.MasterList = SongIds
	State.Pointer = StartIndex or 1
	State.ContextName = ContextName or "Unknown Source"
	State.Queue = {}
	State.History = {}

	local Items = {}

	for i, Id in ipairs(SongIds) do
		table.insert(Items, {Id = Id, TrackingId = "CP-"..i, Source = "Context"})
	end

	State.ContinuePlaying = Items

	TransitionTo(State.ContinuePlaying[State.Pointer].Id, PlayInstantly, true)
end

function module.PlayNext(SongIds)
	for i = #SongIds, 1, -1 do
		table.insert(State.Queue, 1, {
			Id = SongIds[i], 
			TrackingId = "", 
			Source = "Manual"
		})
	end

	RebuildTrackingIds(State.Queue, "Q")
	module.QueueUpdated:Fire()
	PreloadNextTracks()
end

function module.AddToQueue(SongIds)
	for _, SongId in ipairs(SongIds) do
		if #State.Queue >= 30 then break end

		table.insert(State.Queue, {
			Id = SongId, 
			TrackingId = "", 
			Source = "Manual"
		})
	end

	RebuildTrackingIds(State.Queue, "Q")
	module.QueueUpdated:Fire()
	PreloadNextTracks()
end

function module.ToggleShuffle()
	State.Settings.Shuffle = not State.Settings.Shuffle

	if State.Settings.Shuffle then
		local Pool = {}

		for _, Item in State.Queue do table.insert(Pool, Item) end

		for i = State.Pointer + 1, #State.ContinuePlaying do
			table.insert(Pool, State.ContinuePlaying[i])
		end

		local ShuffledPool = GenerateShuffleList(Pool)
		local CurrentItem = State.ContinuePlaying[State.Pointer]

		State.ContinuePlaying = {CurrentItem}

		for _, Item in ShuffledPool do table.insert(State.ContinuePlaying, Item) end

		State.Pointer = 1
		State.Queue = {}

	else
		local NewQueue = {}
		local AlbumOnly = {}

		for i = State.Pointer + 1, #State.ContinuePlaying do
			local Item = State.ContinuePlaying[i]
			if Item.Source == "Manual" then table.insert(NewQueue, Item) end
		end

		for i, Id in State.MasterList do
			table.insert(AlbumOnly, {Id = Id, TrackingId = "CP-"..i, Source = "Context"})
		end

		State.Queue = NewQueue
		State.ContinuePlaying = AlbumOnly

		RebuildTrackingIds(State.Queue, "Q")
		RebuildTrackingIds(State.ContinuePlaying, "CP")

		for i, Item in AlbumOnly do
			if Item.Id == State.CurrentSongId then State.Pointer = i break end
		end
	end

	module.QueueUpdated:Fire()
	UpdateStatus()
end

function module.Next()
	if State.Settings.RepeatMode == "Song" then
		TransitionTo(State.CurrentSongId, true)
		return
	end

	if #State.Queue > 0 then
		local NextObj = table.remove(State.Queue, 1)
		RebuildTrackingIds(State.Queue, "Q")
		TransitionTo(NextObj.Id, true)

		module.QueueUpdated:Fire()

		return
	end

	if State.Pointer < #State.ContinuePlaying then
		State.Pointer += 1
		TransitionTo(State.ContinuePlaying[State.Pointer].Id, true)
	else
		State.Pointer = 1 
		TransitionTo(State.ContinuePlaying[State.Pointer].Id, true)
	end
end

function module.Previous()
	if State.ActiveSound and State.ActiveSound.TimePosition > 3 then
		State.ActiveSound.TimePosition = 0
		return
	end

	if #State.History > 0 then
		local PrevId = table.remove(State.History)

		if State.Pointer > 1 and State.ContinuePlaying[State.Pointer - 1].Id == PrevId then
			State.Pointer -= 1
		end

		TransitionTo(PrevId, true)

		module.QueueUpdated:Fire()
	end
end

return module