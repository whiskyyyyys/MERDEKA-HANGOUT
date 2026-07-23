local AssetService = game:GetService("AssetService")
local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local InputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local nan = TweenInfo.new(.0001)
local quick = TweenInfo.new(.25, Enum.EasingStyle.Exponential)
local normal = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local smooth = TweenInfo.new(.8, Enum.EasingStyle.Exponential)
local slow = TweenInfo.new(1, Enum.EasingStyle.Exponential)
local five = TweenInfo.new(5, Enum.EasingStyle.Exponential)

local bounce = TweenInfo.new(.5, Enum.EasingStyle.Back)
local elastic = TweenInfo.new(1, Enum.EasingStyle.Back)

local loop = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false)
local long_loop = TweenInfo.new(50, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false)
local long_loop_reverses = TweenInfo.new(50, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true)

local crossfading_loop = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false)

local client = Players.LocalPlayer
local camera = workspace.CurrentCamera

local storage = ReplicatedStorage:WaitForChild("Masters(Storage)")
local events = storage.Events
local modules = storage.Modules

local Alerts = require(modules.Alerts)
local Audios = require(modules.Audios)
local Configuration = require(modules.Configuration)
local Listeners = require(modules.Listeners)
local LyricsEngine = require(modules.LyricsEngine)
local Main = require(modules.Main)
local OnlineStations = require(modules.OnlineStations)
local Queue = require(modules.Queue)
local Settings = require(modules.Settings)
local Signal = require(modules.Signal)
local Smoothness = require(modules.Smoothness)
local TextFiltering = require(modules.TextFiltering)
local Utilities = require(modules.Utilities)

local ui = script.Parent
local frame = ui.Interface.Frame

local ShareSheet = ui.ShareSheet

local Bar = frame.Bar
local Full = frame.Full

local NowPlaying = Full.NowPlaying
local PlaylistCreation = Full.PlaylistCreation
local SettingsPage = Full.Settings

local Playback = ui.Playback

local AudiosLoaded = {}

local TimeScrubberData = {
	Dragging = false,
	StartPos = 0, 
	StartScale = 0   
}

local VolumeScrubberData = {
	Dragging = false,
	StartPos = 0, 
	StartScale = 0   
}

local CrossfadeDurationScrubberData = {
	Dragging = false,
	StartPos = 0, 
	StartScale = 0   
}

local ArtistPageProperties = {
	CurrentArtistLoaded = "",
	LoadingArtist = false,
	Discography = {}
}

local PlaylistPageProperties = {
	CurrentPlaylistId = "",
	CurrentPlaylistName = "",
	CurrentCreatorId = 0,
	CurrentPlaylistData = {},
	FilteringTitle = false,

	LoadingPlaylist = false,
	Songs = {},
	ToAdd = 0,

	RequestReload = Signal.new()
}

local StationPageProperties = {
	CurrentStationId = "",
	CurrentStationData = {},
	IsCurrentlyOnline = false,
	LoadingStation = false,
	Songs = {},
}

local SettingsPageProperties = {
	Changed = Signal.new(),
	HasChanged = false,
	LoadingSettings = false,
	Data = nil,
}

local DetailsPageProperties = {
	LoadingDetails = false,
	CurrentSongLoaded = 0,
	SettingsChanged = Signal.new()
}

local SearchingProperties = {
	Advancing = false,
	Cooldown = 5,
	RecentKeyword = "",
	SearchData = nil
}

local LibraryProperties = {
	Cooldown = 1,
	Initialized = false,
	Loading = false,
	ForReload = false,
	RequestReload = Signal.new(),
	PinnedChanged = Signal.new()
}

local HoverBackgroundProperties = {
	IsVisualAUsed = false
}

local NowPlayingProperties = {
	IsVisualAUsed = false,
	IsAlbumArtA = false,
	LyricsTopOffset = 20,
	TargetPosition = UDim2.fromScale(0, 0),
	TargetAnchor = Vector2.new(0, 0),
	Progress = 0,
	CurrentIndex = 1,
	Sequence = {"TopLeft", "TopRight", "Center", "BottomRight", "BottomLeft", "Center"},
	Spots = {
		{
			AnchorPoint = Vector2.new(0, 0),
			Position = UDim2.fromScale(0, 0),
			State = "TopLeft"
		},

		{
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			State = "TopRight"
		},

		{
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			State = "BottomLeft"
		},

		{
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(1, 1),
			State = "BottomRight"
		},

		{
			AnchorPoint = Vector2.new(.5, .5),
			Position = UDim2.fromScale(.5, .5),
			State = "Center"
		},
	},
	CurrentLyricsLoaded = nil,
}

local BarProperties = {
	IsVisualAUsed = false
}

local InterfaceDragProperties = {

	-- Variables

	Padding = {Top = GuiService.TopbarInset.Height - 20, Bottom = -40, Left = -40, Right = -40},
	TuckDepth = 50,
	Tucked = false,
	SnappedTo = "None",
	MainDrag = false,
	MainCurrentlyDragged = false,
	MainDragInput = nil,
	MainDragStart = nil,
	MainStartPos = nil,

	-- Events

	DragStarted = Signal.new(),
	DragReleased = Signal.new()
}

-- Types

type SongItemProperties = {
	Container: any,
	ContextName: string,
	Item: Instance,
	ItemProperties: any,
	MasterPool: any,
	Pointer: number,
	SongInfo: any,
	Source: SongSourceType
}

type ArtistItemProperties = {
	Container: any,
	Item: Instance,
	ItemProperties: any,
	ArtistName: any,
	Source: ArtistSourceType
}

type PlaylistItemProperties = {
	Container: any,
	Item: Instance,
	ItemProperties: any,
	PlaylistData: any,
	Source: PlaylistSourceType
}

type StationItemProperties = {
	Container: any,
	Item: Instance,
	ItemProperties: any,
	StationData: any,
	Source: StationItemProperties,
	Online: boolean
}

type ArtistSourceType = "Library" | "Standard" | "Playlist" | "ArtistPage" 
type PlaylistSourceType = "Library" | "Standard" | "PlaylistPage" 
type StationItemProperties = "Standard" | "StationPage" 
type SongSourceType = "Library" | "Standard" | "Playlist" | "Queue" | "ContinuePlaying" | "NowPlaying"

type SongInfo = {
	Artist: any,
	ContextName: any,
	MasterPool: any,
	Pointer: number,
	Title: any,
	SongId: number,
	TrackingId: any,
}

-- Functions

function InitiateSettings()
	local Data = Settings.FetchSettings()
	if not Data then Data = Settings.FetchDefaultSettings() end

	SettingsPageProperties.Data = Data
end

function AutostartStation()
	local ConfigurationData = Configuration.GetConfiguration()
	if not ConfigurationData then return end

	local Station = Configuration.GetLocalStationByStationId(ConfigurationData.Stations.AutoStart)
	if not Station then return end

	Queue.LoadSource(Station.Songs, 1, Station.Name, true)
end

function GetSpotByName(Name)
	for _, Spot in NowPlayingProperties.Spots do
		if Spot.State == Name then return Spot end
	end
end

function HoverBackground(State, ImageId)
	if State then
		if HoverBackgroundProperties.IsVisualAUsed then
			HoverBackgroundProperties.IsVisualAUsed = false

			Full.Util.HoverBackground.Visual_B.Image = ImageId
			TweenService:Create(Full.Util.HoverBackground.Visual_B, normal, {ImageTransparency = 0}):Play()
		else
			HoverBackgroundProperties.IsVisualAUsed = true

			Full.Util.HoverBackground.Visual_A.Image = ImageId
			TweenService:Create(Full.Util.HoverBackground.Visual_A, normal, {ImageTransparency = 0}):Play()
		end
	else
		if HoverBackgroundProperties.IsVisualAUsed then
			TweenService:Create(Full.Util.HoverBackground.Visual_A, normal, {ImageTransparency = 1}):Play()
		else
			TweenService:Create(Full.Util.HoverBackground.Visual_B, normal, {ImageTransparency = 1}):Play()
		end
	end
end

function NowPlayingBackground(ImageId)
	local Settings = events.Main.Settings.FetchSettings:InvokeServer()

	if NowPlayingProperties.IsVisualAUsed then
		NowPlayingProperties.IsVisualAUsed = false

		NowPlaying.Util.Visual.Saturation.Visual_B.Image = ImageId

		if Settings.Playback.Crossfade.Enabled then

			TweenService:Create(NowPlaying.Util.Visual.Saturation.Visual_A, 
				TweenInfo.new(Settings.Playback.Crossfade.Duration, Enum.EasingStyle.Linear), 
				{ImageTransparency = 1}):Play()
			TweenService:Create(NowPlaying.Util.Visual.Saturation.Visual_B, 
				TweenInfo.new(Settings.Playback.Crossfade.Duration, Enum.EasingStyle.Linear), 
				{ImageTransparency = 0}):Play()

		else

			TweenService:Create(NowPlaying.Util.Visual.Saturation.Visual_A, TweenInfo.new(1, Enum.EasingStyle.Linear), 
				{ImageTransparency = 1}):Play()
			TweenService:Create(NowPlaying.Util.Visual.Saturation.Visual_B, TweenInfo.new(1, Enum.EasingStyle.Linear), 
				{ImageTransparency = 0}):Play()
		end
	else
		NowPlayingProperties.IsVisualAUsed = true

		NowPlaying.Util.Visual.Saturation.Visual_A.Image = ImageId

		if Settings.Playback.Crossfade.Enabled then

			TweenService:Create(NowPlaying.Util.Visual.Saturation.Visual_A, 
				TweenInfo.new(Settings.Playback.Crossfade.Duration, Enum.EasingStyle.Linear), 
				{ImageTransparency = 0}):Play()

			TweenService:Create(NowPlaying.Util.Visual.Saturation.Visual_B, 
				TweenInfo.new(Settings.Playback.Crossfade.Duration, Enum.EasingStyle.Linear), 
				{ImageTransparency = 1}):Play()

		else

			TweenService:Create(NowPlaying.Util.Visual.Saturation.Visual_A, TweenInfo.new(1, Enum.EasingStyle.Linear), 
				{ImageTransparency = 0}):Play()

			TweenService:Create(NowPlaying.Util.Visual.Saturation.Visual_B, TweenInfo.new(1, Enum.EasingStyle.Linear), 
				{ImageTransparency = 1}):Play()
		end
	end
end

function NowPlayingAlbumArt(ImageId, IsCrossfading)
	local Settings = events.Main.Settings.FetchSettings:InvokeServer()

	if NowPlayingProperties.IsAlbumArtA then
		NowPlayingProperties.IsAlbumArtA = false

		NowPlaying.Content.Media.Art.Photo.ArtB.Image = ImageId

		if Settings.Playback.Crossfade.Enabled then
			local TimeValue

			if IsCrossfading then
				TimeValue = Settings.Playback.Crossfade.Duration
			else
				TimeValue = .01
			end

			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtA, 
				TweenInfo.new(TimeValue, Enum.EasingStyle.Linear), 
				{ImageTransparency = 1}):Play()
			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtA.scale, 
				TweenInfo.new(TimeValue, Enum.EasingStyle.Sine), 
				{Scale = 1.2}):Play()

			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtB, 
				TweenInfo.new(TimeValue, Enum.EasingStyle.Linear), 
				{ImageTransparency = 0}):Play()
			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtB.scale, 
				TweenInfo.new(TimeValue, Enum.EasingStyle.Sine), 
				{Scale = 1}):Play()

		else
			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtA, TweenInfo.new(1, Enum.EasingStyle.Linear), 
				{ImageTransparency = 1}):Play()
			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtA.scale, 
				TweenInfo.new(Settings.Playback.Crossfade.Duration, Enum.EasingStyle.Sine), 
				{Scale = 1.2}):Play()

			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtB, TweenInfo.new(1, Enum.EasingStyle.Linear), 
				{ImageTransparency = 0}):Play()
			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtB.scale, 
				TweenInfo.new(Settings.Playback.Crossfade.Duration, Enum.EasingStyle.Sine), 
				{Scale = 1}):Play()
		end
	else

		NowPlayingProperties.IsAlbumArtA = true

		NowPlaying.Content.Media.Art.Photo.ArtA.Image = ImageId

		if Settings.Playback.Crossfade.Enabled then
			local TimeValue

			if IsCrossfading then
				TimeValue = Settings.Playback.Crossfade.Duration
			else
				TimeValue = .01
			end

			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtA, 
				TweenInfo.new(TimeValue, Enum.EasingStyle.Linear), 
				{ImageTransparency = 0}):Play()
			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtA.scale, 
				TweenInfo.new(TimeValue, Enum.EasingStyle.Sine), 
				{Scale = 1}):Play()

			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtB, 
				TweenInfo.new(TimeValue, Enum.EasingStyle.Linear), 
				{ImageTransparency = 1}):Play()
			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtB.scale, 
				TweenInfo.new(TimeValue, Enum.EasingStyle.Sine), 
				{Scale = 1.2}):Play()

		else
			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtA, TweenInfo.new(1, Enum.EasingStyle.Linear), 
				{ImageTransparency = 0}):Play()
			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtA.scale, 
				TweenInfo.new(Settings.Playback.Crossfade.Duration, Enum.EasingStyle.Sine), 
				{Scale = 1}):Play()

			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtB, TweenInfo.new(1, Enum.EasingStyle.Linear), 
				{ImageTransparency = 1}):Play()
			TweenService:Create(NowPlaying.Content.Media.Art.Photo.ArtB.scale, 
				TweenInfo.new(Settings.Playback.Crossfade.Duration, Enum.EasingStyle.Sine), 
				{Scale = 1.2}):Play()
		end
	end
end

function BarBackground(ImageId)
	local Settings = events.Main.Settings.FetchSettings:InvokeServer()

	if BarProperties.IsVisualAUsed then
		BarProperties.IsVisualAUsed = false

		Bar.Util.Visual.Saturation.Visual_B.Image = ImageId

		if Settings.Playback.Crossfade.Enabled then

			TweenService:Create(Bar.Util.Visual.Saturation.Visual_A, 
				TweenInfo.new(Settings.Playback.Crossfade.Duration, Enum.EasingStyle.Linear), 
				{ImageTransparency = 1}):Play()
			TweenService:Create(Bar.Util.Visual.Saturation.Visual_B, 
				TweenInfo.new(Settings.Playback.Crossfade.Duration, Enum.EasingStyle.Linear), 
				{ImageTransparency = 0}):Play()

		else

			TweenService:Create(Bar.Util.Visual.Saturation.Visual_A, TweenInfo.new(1, Enum.EasingStyle.Linear), 
				{ImageTransparency = 1}):Play()
			TweenService:Create(Bar.Util.Visual.Saturation.Visual_B, TweenInfo.new(1, Enum.EasingStyle.Linear), 
				{ImageTransparency = 0}):Play()
		end
	else
		BarProperties.IsVisualAUsed = true

		Bar.Util.Visual.Saturation.Visual_A.Image = ImageId

		if Settings.Playback.Crossfade.Enabled then

			TweenService:Create(Bar.Util.Visual.Saturation.Visual_A, 
				TweenInfo.new(Settings.Playback.Crossfade.Duration, Enum.EasingStyle.Linear), 
				{ImageTransparency = 0}):Play()

			TweenService:Create(Bar.Util.Visual.Saturation.Visual_B, 
				TweenInfo.new(Settings.Playback.Crossfade.Duration, Enum.EasingStyle.Linear), 
				{ImageTransparency = 1}):Play()

		else

			TweenService:Create(Bar.Util.Visual.Saturation.Visual_A, TweenInfo.new(1, Enum.EasingStyle.Linear), 
				{ImageTransparency = 0}):Play()

			TweenService:Create(Bar.Util.Visual.Saturation.Visual_B, TweenInfo.new(1, Enum.EasingStyle.Linear), 
				{ImageTransparency = 1}):Play()
		end
	end
end

-- Functions / Options

local OptionInfoPresets = {
	PlayModes = {
		Play = {
			Name = "Play",
			Icon = "rbxassetid://11423157473"
		},

		PlayNext = {
			Name = "Play Next",
			Icon = "rbxassetid://12967339693"
		},

		PlayLast = {
			Name = "Play Last",
			Icon = "rbxassetid://12967340242"
		},

		ProceedHere = {
			Name = "Proceed Here",
			Icon = "rbxassetid://12967340242"
		},

		PlayAlone = {
			Name = "Play Alone",
			Icon = "rbxassetid://12967528364"
		}
	},

	Library = {
		AddToLibrary = {
			Name = "Add To Library",
			Icon = "rbxassetid://11295291707"
		},

		RemoveFromLibrary = {
			Name = "Remove From Library",
			Icon = "rbxassetid://11326877488"
		},

		Pin = {
			Name = "Pin",
			Icon = "rbxassetid://12974469173"
		},

		UndoPin = {
			Name = "Undo Pin",
			Icon = "rbxassetid://12974257382"
		}
	},

	Playlist = {
		AddToPlaylist = {
			Name = "Add To Playlist",
			Icon = "rbxassetid://11432849996"
		},

		CreatePlaylistWith = {
			Name = "Create Playlist With",
			Icon = "rbxassetid://12974227834"
		},

		RemoveFromPlaylist = {
			Name = "Remove From Playlist",
			Icon = "rbxassetid://11326877488"
		},

		EditPlaylist = {
			Name = "Edit Playlist",
			Icon = "rbxassetid://11326670192"
		},

		AddToLibrary = {
			Name = "Add To Library",
			Icon = "rbxassetid://11295291707"
		},

		CopyPlaylist = {
			Name = "Copy Playlist",
			Icon = "rbxassetid://12974407511"
		},

		SetPrivate = {
			Name = "Set to Private",
			Icon = "rbxassetid://14187755345"
		},

		SetPublic = {
			Name = "Set to Public",
			Icon = "rbxassetid://11293979388"
		},

		DeletePlaylist = {
			Name = "Delete Playlist",
			Icon = "rbxassetid://11326877488"
		}
	},

	Preferences = {
		Favorite = {
			Name = "Favorite",
			Icon = "rbxassetid://12974204015"
		},

		Dislike = {
			Name = "Dislike",
			Icon = "rbxassetid://11295273791"
		},

		UndoFavorite = {
			Name = "Undo Favorite",
			Icon = "rbxassetid://12974204015"
		},

		UndoDislike = {
			Name = "Undo Dislike",
			Icon = "rbxassetid://11295273791"
		},

		More = {
			Name = "Save",
			Icon = "rbxassetid://11422144827"
		},

		Block = {
			Name = "Block",
			Icon = "rbxassetid://11419666512"
		},

		UndoMore = {
			Name = "Undo Save",
			Icon = "rbxassetid://11422144827"
		},

		UndoBlock = {
			Name = "Undo Block",
			Icon = "rbxassetid://11419666512"
		},

	},

	Stations = {

		CopyStation = {
			Name = "Copy Station",
			Icon = "rbxassetid://12974407511"
		}
	},

	Queue = {
		ClearQueue = {
			Name = "Clear Queue",
			Icon = "rbxassetid://12966398330"
		},

		ClearContinuePlaying = {
			Name = "Clear Continue Playing",
			Icon = "rbxassetid://12966398330"
		},

		RemoveFromQueue = {
			Name = "Remove From Queue",
			Icon = "rbxassetid://11326877488"
		}
	},

	Others = {
		ViewDetails = {
			Name = "View Details",
			Icon = "rbxassetid://11422155687"
		},

		ViewArtist = {
			Name = "View Artist",
			Icon = "rbxassetid://11295273292"
		},

		ViewPlaylist = {
			Name = "View Playlist",
			Icon = "rbxassetid://11432849996"
		},

		ViewStation = {
			Name = "View Station",
			Icon = "rbxassetid://11432849777"
		},
	},

	Share = {
		ShareSong = {
			Name = "Share Song",
			Icon = "rbxassetid://11295275294"
		},

		ShareArtist = {
			Name = "Share Artist",
			Icon = "rbxassetid://11295275294"
		},

		SharePlaylist = {
			Name = "Share Playlist",
			Icon = "rbxassetid://11295275294"
		},

		ShareStation = {
			Name = "Share Station",
			Icon = "rbxassetid://11295275294"
		},
	}
}

function callback_Play(Data: SongInfo)
	Queue.LoadSource(Data.MasterPool, Data.Pointer, Data.ContextName, true)
end

function callback_PlayNext(Data: SongInfo)
	Queue.PlayNext({Data.MasterPool[Data.Pointer]})
end

function callback_PlayLast(Data: SongInfo)
	Queue.AddToQueue({Data.MasterPool[Data.Pointer]})
end

function callback_SongLibrary(Index, Data: SongInfo)
	if Index == 1 then
		local SongId = Data.MasterPool[Data.Pointer]
		local Success, Result = events.Main.Library.SetSong:InvokeServer(SongId, true)

		if Success then
			LibraryProperties.RequestReload:Fire()

			Alerts.BannerNotify({
				Header = "Successfully Added from your Library",
				Description = "Added from your library.",
				Icon = Utilities.GetCoverForSong(SongId)
			})

		elseif not Success and Result then
			if Result == "unknown" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "Failed to find song.",
					Icon = "rbxassetid://11419709766"
				})

			elseif  Result == "limit" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "You have exceeded the maximum of 30 songs.",
					Icon = "rbxassetid://11419709766"
				})
			end
		end

	elseif Index == 2 then
		local SongId = Data.MasterPool[Data.Pointer]
		local Success, Result = events.Main.Library.SetSong:InvokeServer(SongId, false)

		if Success then
			LibraryProperties.RequestReload:Fire()

			Alerts.BannerNotify({
				Header = "Successfully Removed from your Library",
				Description = "Removed from your library.",
				Icon = Utilities.GetCoverForSong(SongId)
			})

		elseif not Success and Result then
			if Result == "unknown" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "Failed to find song.",
					Icon = "rbxassetid://11419709766"
				})
			end
		end
	end
end

function callback_ArtistLibrary(Index, ArtistName)
	if Index == 1 then
		local Success, Result = events.Main.Library.SetArtist:InvokeServer(ArtistName, true)

		if Success then
			LibraryProperties.RequestReload:Fire()

			Alerts.BannerNotify({
				Header = "Successfully Added from your Library",
				Description = `Added {ArtistName} to your library.`,
				Icon = "rbxassetid://11295273292"
			})

		elseif not Success and Result then
			if Result == "unknown" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "Failed to find artist.",
					Icon = "rbxassetid://11419709766"
				})

			elseif  Result == "limit" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "You have exceeded the maximum of 30 artists.",
					Icon = "rbxassetid://11419709766"
				})
			end
		end

	elseif Index == 2 then
		local Success, Result = events.Main.Library.SetArtist:InvokeServer(ArtistName, false)

		if Success then
			LibraryProperties.RequestReload:Fire()

			Alerts.BannerNotify({
				Header = "Successfully Removed from your Library",
				Description = `Removed {ArtistName} from your library.`,
				Icon = "rbxassetid://11295273292"
			})

		elseif not Success and Result then
			if Result == "unknown" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "Failed to find artist.",
					Icon = "rbxassetid://11419709766"
				})
			end
		end
	end
end

function callback_SongPlaylist(Index, SongId, PlaylistId)
	if Index == 1 then		
		local Success, Result = events.Main.Library.SetSongToPlaylist:InvokeServer(PlaylistId, SongId, true)

		if Success then
			PlaylistPageProperties.RequestReload:Fire()

			Alerts.BannerNotify({
				Header = "Added Successfully",
				Description = "This song was added to your playlist.",
				Icon = Utilities.GetCoverForSong(SongId)
			})

		elseif not Success and Result then
			if Result == "limit" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "You have exceeded the maximum of 30 songs per playlist.",
					Icon = "rbxassetid://11419709766"
				})

			elseif Result == "unowned" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "You can't add songs to someone's playlist.",
					Icon = "rbxassetid://11419709766"
				})

			elseif Result == "unknown" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "Failed to add song.",
					Icon = "rbxassetid://11419709766"
				})
			end
		end

	elseif Index == 2 then
		local Success, Result = events.Main.Library.SetSongToPlaylist:InvokeServer(PlaylistId, SongId, false)

		if Success then
			PlaylistPageProperties.RequestReload:Fire()

			Alerts.BannerNotify({
				Header = "Removed Successfully",
				Description = "This song was removed from your playlist.",
				Icon = Utilities.GetCoverForSong(SongId)
			})

		elseif not Success and Result then
			if Result == "unknown" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "Failed to add song.",
					Icon = "rbxassetid://11419709766"
				})

			elseif Result == "unowned" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "You can't remove songs from someone's playlist.",
					Icon = "rbxassetid://11419709766"
				})

			end
		end
	end
end

function callback_AddToPlaylist(SongId)
	local Options = {}

	table.insert(Options, {
		Name = OptionInfoPresets.Playlist.CreatePlaylistWith.Name,
		Icon = OptionInfoPresets.Playlist.CreatePlaylistWith.Icon,
	})

	table.insert(Options, "SEPARATOR")

	local Playlists = events.Main.Library.GetPlaylists:InvokeServer()
	if not Playlists then return end

	for i, Data in Playlists do
		table.insert(Options, {
			Name = Data.Name,
			Icon = Data.Cover,
		})
	end

	local OptionChosen = Main.PromptOptions({
		Options = Options,
		MaxOptions = 8
	})

	if OptionChosen == "Create Playlist With" then
		Main.PlaylistCreation(true)

		PlaylistPageProperties.ToAdd = SongId

	elseif OptionChosen ~= nil then
		local PlaylistId = events.Main.Library.GetPlaylistIdByName:InvokeServer(OptionChosen)
		if not PlaylistId then return end

		callback_SongPlaylist(1, SongId, PlaylistId)
	end
end

function callback_PinSong(Index, Data: SongInfo)
	if Index == 1 then
		local SongId = Data.MasterPool[Data.Pointer]

		events.Main.Library.Pin:FireServer("Song", Data.MasterPool[Data.Pointer], true)
		LibraryProperties.RequestReload:Fire()

		Alerts.BannerNotify({
			Header = "Pinned To Your Library",
			Description = "This song is now pinned to your library.",
			Icon = Utilities.GetCoverForSong(SongId)
		})

	elseif Index == 2 then
		local SongId = Data.MasterPool[Data.Pointer]

		events.Main.Library.Pin:FireServer("Song", Data.MasterPool[Data.Pointer], false)
		LibraryProperties.RequestReload:Fire()

		Alerts.BannerNotify({
			Header = "Unpinned From Your Library",
			Description = "This song was unpinned from your library.",
			Icon = Utilities.GetCoverForSong(SongId)
		})
	end
end

function callback_PinArtist(Index, ArtistName)
	if Index == 1 then
		events.Main.Library.Pin:FireServer("Artist", ArtistName, true)
		LibraryProperties.RequestReload:Fire()


		Alerts.BannerNotify({
			Header = "Pinned To Your Library",
			Description = "This artist is now pinned to your library.",
			Icon = "rbxassetid://11295273292"
		})

	elseif Index == 2 then
		events.Main.Library.Pin:FireServer("Artist", ArtistName, false)
		LibraryProperties.RequestReload:Fire()

		Alerts.BannerNotify({
			Header = "Unpinned From Your Library",
			Description = "This artist was unpinned from your library.",
			Icon = "rbxassetid://11295273292"
		})
	end
end

function callback_PinPlaylist(Index, PlaylistId)
	if Index == 1 then
		events.Main.Library.Pin:FireServer("Playlist", PlaylistId, true)
		LibraryProperties.RequestReload:Fire()

		Alerts.BannerNotify({
			Header = "Pinned To Your Library",
			Description = "This playlist is now pinned to your library.",
			Icon = "rbxassetid://11295273292"
		})

	elseif Index == 2 then
		events.Main.Library.Pin:FireServer("Playlist", PlaylistId, false)
		LibraryProperties.RequestReload:Fire()

		Alerts.BannerNotify({
			Header = "Unpinned From Your Library",
			Description = "This playlist was unpinned from your library.",
			Icon = "rbxassetid://11295273292"
		})
	end
end

function callback_Favorite(Index, Data: SongInfo)
	if Index == 1 then
		local SongId = Data.MasterPool[Data.Pointer]
		local Success, Result = events.Main.Preferences.FavoriteSong:InvokeServer(SongId, true)

		if Success then
			LibraryProperties.RequestReload:Fire()

			Alerts.BannerNotify({
				Header = "Favorited",
				Description = "This song is added to your Favorites.",
				Icon = Utilities.GetCoverForSong(SongId)
			})

		elseif not Success and Result then
			if Result == "unknown" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "Failed to find song.",
					Icon = "rbxassetid://11419709766"
				})

			elseif  Result == "limit" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "You have exceeded the maximum of 90 songs.",
					Icon = "rbxassetid://11419709766"
				})
			end
		end

	elseif Index == 2 then
		local SongId = Data.MasterPool[Data.Pointer]
		local Success, Result = events.Main.Preferences.FavoriteSong:InvokeServer(SongId, false)

		if Success then
			LibraryProperties.RequestReload:Fire()

			Alerts.BannerNotify({
				Header = "Favorite Undone",
				Description = "This song was removed from your Favorites.",
				Icon = Utilities.GetCoverForSong(SongId)
			})

		elseif not Success and Result then
			if Result == "unknown" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "Failed to find song.",
					Icon = "rbxassetid://11419709766"
				})
			end
		end
	end
end

function callback_CopyOnlineStation(StationId)
	local Success, Result = events.Main.Library.CopyOnlineStation:InvokeServer(StationId)

	if Success then
		LibraryProperties.RequestReload:Fire()

		Alerts.BannerNotify({
			Header = "Successfully Copied",
			Description = "You've copied a station to a playlist.",
			Icon = "rbxassetid://12974407511"
		})

	elseif not Success and Result then
		if Result == "unknown" then
			Alerts.BannerNotify({
				Header = "An Error Occurred.",
				Description = "Failed to copy station.",
				Icon = "rbxassetid://11419709766"
			})

		elseif  Result == "limit" then
			Alerts.BannerNotify({
				Header = "An Error Occurred.",
				Description = "You have exceeded the maximum of 30 playlists.",
				Icon = "rbxassetid://11419709766"
			})
		end
	end
end

function callback_CopyLocalStation(StationId)
	local Success, Result = events.Main.Library.CopyLocalStation:InvokeServer(StationId)

	if Success then
		LibraryProperties.RequestReload:Fire()

		Alerts.BannerNotify({
			Header = "Successfully Copied",
			Description = "You've copied a station to a playlist.",
			Icon = "rbxassetid://12974407511"
		})

	elseif not Success and Result then
		if Result == "unknown" then
			Alerts.BannerNotify({
				Header = "An Error Occurred.",
				Description = "Failed to copy station.",
				Icon = "rbxassetid://11419709766"
			})

		elseif  Result == "limit" then
			Alerts.BannerNotify({
				Header = "An Error Occurred.",
				Description = "You have exceeded the maximum of 30 playlists.",
				Icon = "rbxassetid://11419709766"
			})
		end
	end
end

function callback_Dislike(Index, Data: SongInfo)
	if Index == 1 then
		local SongId = Data.MasterPool[Data.Pointer]
		local Success, Result = events.Main.Preferences.DislikeSong:InvokeServer(SongId, true)

		if Success then
			Alerts.BannerNotify({
				Header = "Disliked",
				Description = "This song will never show on your feed from now on.",
				Icon = Utilities.GetCoverForSong(SongId)
			})

		elseif not Success and Result then
			if Result == "unknown" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "Failed to find song.",
					Icon = "rbxassetid://11419709766"
				})

			elseif  Result == "limit" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "You have exceeded the maximum of 90 songs.",
					Icon = "rbxassetid://11419709766"
				})
			end
		end

	elseif Index == 2 then
		local SongId = Data.MasterPool[Data.Pointer]
		local Success, Result = events.Main.Preferences.DislikeSong:InvokeServer(SongId, false)

		if Success then
			Alerts.BannerNotify({
				Header = "Dislike Undone",
				Description = "This song will be shown on your feed from now on.",
				Icon = Utilities.GetCoverForSong(SongId)
			})

		elseif not Success and Result then
			if Result == "unknown" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "Failed to find song.",
					Icon = "rbxassetid://11419709766"
				})
			end
		end
	end
end

function callback_Block(Index, ArtistName)
	if Index == 1 then
		local Success, Result = events.Main.Preferences.BlockArtist:InvokeServer(ArtistName, true)

		if Success then
			Alerts.BannerNotify({
				Header = "Successfully Blocked " .. ArtistName,
				Description = "This artist is blocked.",
				Icon = "rbxassetid://11295273292"
			})

		elseif not Success and Result then
			if Result == "unknown" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "Failed to find artist.",
					Icon = "rbxassetid://11419709766"
				})

			elseif  Result == "limit" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "You have exceeded the maximum of 30 artists.",
					Icon = "rbxassetid://11419709766"
				})
			end
		end

	elseif Index == 2 then
		local Success, Result = events.Main.Preferences.BlockArtist:InvokeServer(ArtistName, false)

		if Success then
			Alerts.BannerNotify({
				Header = "Successfully Unblocked " .. ArtistName,
				Description = "This artist is now unblocked.",
				Icon = "rbxassetid://11295273292"
			})

		elseif not Success and Result then
			if Result == "unknown" then
				Alerts.BannerNotify({
					Header = "An Error Occurred.",
					Description = "Failed to find artist.",
					Icon = "rbxassetid://11295273292"
				})
			end
		end
	end
end

function callback_ViewArtist(ArtistName)
	if ArtistPageProperties.LoadingArtist then return end
	if DetailsPageProperties.LoadingDetails then return end
	if PlaylistPageProperties.LoadingPlaylist then return end
	if StationPageProperties.LoadingStation then return end

	local Artist = LoadArtist(ArtistName)

	if Artist then
		ArtistPageProperties.LoadingArtist = false

		Alerts.BannerNotify({
			Header = "Failed to load artist.",
			Description = "An error occurred while loading artist.",
			Icon = "rbxassetid://11433646681"
		})
	end
end

function callback_ViewDetails()
	if ArtistPageProperties.LoadingArtist then return end
	if DetailsPageProperties.LoadingDetails then return end
	if PlaylistPageProperties.LoadingPlaylist then return end
	if StationPageProperties.LoadingStation then return end

	Main.NowPlaying(false)
	LoadCurrentSongDetails()
end

function callback_ViewPlaylist(CreatorId, PlaylistId)
	if ArtistPageProperties.LoadingArtist then return end
	if DetailsPageProperties.LoadingDetails then return end
	if PlaylistPageProperties.LoadingPlaylist then return end
	if StationPageProperties.LoadingStation then return end

	LoadPlaylist(CreatorId, PlaylistId)
end

function callback_ViewStation(Online, StationId)
	if ArtistPageProperties.LoadingArtist then return end
	if DetailsPageProperties.LoadingDetails then return end
	if PlaylistPageProperties.LoadingPlaylist then return end
	if StationPageProperties.LoadingStation then return end

	if Online then
		LoadOnlineStation(StationId)
	else
		LoadLocalStation(StationId)
	end
end

function callback_ShareSong(SongId, Title, Artist)
	if not SettingsPageProperties.Data.Socials.Sharing then
		Alerts.BannerNotify({
			Header = "Sharing Disabled",
			Description = "Turn Sharing on in the setting.",
			Icon = "rbxassetid://11419713314"
		})

		return
	end

	local Receiver = Main.PromptShare({
		Title = Title,
		Subtext = Artist,
		Icon = Utilities.GetCoverForSong(SongId),
	})

	if Receiver then
		local success, result = events.Main.Sharing.Share:InvokeServer(Receiver, "Song", SongId)

		if success then
			Alerts.BannerNotify({
				Header = "Successfully Shared",
				Description = "You've shared " .. Title .. " by " .. Artist .. ".",
				Icon = "rbxassetid://11295275294"
			})
		else
			if result == "disabled" then
				Alerts.BannerNotify({
					Header = "Failed to Share",
					Description = "The person you've tried sharing with is unavailable.",
					Icon = "rbxassetid://14187755345"
				})

			elseif result == "setting disabled" then
				Alerts.BannerNotify({
					Header = "Failed to Share",
					Description = "Turn Sharing on in the settings.",
					Icon = "rbxassetid://14187755345"
				})

			else
				Alerts.BannerNotify({
					Header = "Failed to Share",
					Description = "An error occurred while sharing.",
					Icon = "rbxassetid://14187755345"
				})
			end
		end
	end
end

function callback_ShareArtist(ArtistName)
	if not SettingsPageProperties.Data.Socials.Sharing then
		Alerts.BannerNotify({
			Header = "Sharing Disabled",
			Description = "Turn Sharing on in the setting.",
			Icon = "rbxassetid://11419713314"
		})

		return
	end

	local Receiver = Main.PromptShare({
		Title = ArtistName,
		Subtext = "Artist"
	})

	if Receiver then
		local success, result = events.Main.Sharing.Share:InvokeServer(Receiver, "Artist", ArtistName)

		if success then
			Alerts.BannerNotify({
				Header = "Successfully Shared",
				Description = "You've shared " .. ArtistName .. ".",
				Icon = "rbxassetid://11295275294"
			})
		else
			if result == "disabled" then
				Alerts.BannerNotify({
					Header = "Failed to Share",
					Description = "The person you've tried sharing with is unavailable.",
					Icon = "rbxassetid://14187755345"
				})
			else
				Alerts.BannerNotify({
					Header = "Failed to Share",
					Description = "An error occurred while sharing.",
					Icon = "rbxassetid://14187755345"
				})
			end
		end
	end
end

function callback_SharePlaylist(PlaylistData)
	if not SettingsPageProperties.Data.Socials.Sharing then
		Alerts.BannerNotify({
			Header = "Sharing Disabled",
			Description = "Turn Sharing on in the setting.",
			Icon = "rbxassetid://11419713314"
		})

		return
	end

	local Receiver = Main.PromptShare({
		Title = PlaylistData.Name,
		Subtext = "Playlist",
	})

	if Receiver then
		local success1, result1 = events.Main.Library.SetPlaylistProperty:InvokeServer(PlaylistData.PlaylistId, "Private", false)

		if success1 then
			local success, result = events.Main.Sharing.Share:InvokeServer(Receiver, "Playlist", PlaylistData.PlaylistId)

			if success then
				Alerts.BannerNotify({
					Header = "Successfully Shared",
					Description = "You've shared " .. PlaylistData.Name .. ".",
					Icon = "rbxassetid://11295275294"
				})
			else
				if result == "disabled" then
					Alerts.BannerNotify({
						Header = "Failed to Share",
						Description = "The person you've tried sharing with is unavailable.",
						Icon = "rbxassetid://14187755345"
					})
				else
					Alerts.BannerNotify({
						Header = "Failed to Share",
						Description = "An error occurred while sharing.",
						Icon = "rbxassetid://14187755345"
					})
				end
			end
		else
			Alerts.BannerNotify({
				Header = "Failed to Share",
				Description = "An error occurred while sharing.",
				Icon = "rbxassetid://14187755345"
			})
		end
	end
end

-- Option Functions

function PromptSongOptions(Source: SongSourceType, Data: SongInfo, Mobile)
	local VisualQueue = Queue.GetVisualQueue()
	local Options = {}

	if Source == "Standard" then
		local SongId = Data.MasterPool[Data.Pointer]
		local SongsInQueue = (#VisualQueue.Queue + #VisualQueue.ContinuePlaying)

		local IsAdded = events.Main.Library.IsSongSaved:InvokeServer(SongId)
		local IsFavorited = events.Main.Preferences.IsSongFavorite:InvokeServer(SongId)
		local IsDisliked = events.Main.Preferences.IsSongDislike:InvokeServer(SongId)

		if SongsInQueue == 0 and not Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
				Primary = true
			})

		elseif SongsInQueue == 0 and Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
			})

		elseif SongsInQueue > 1 then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
				Primary = true
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayLast.Name,
				Icon = OptionInfoPresets.PlayModes.PlayLast.Icon,
				Primary = true
			})
		end

		table.insert(Options, "SEPARATOR")

		if IsAdded then
			table.insert(Options, {
				Name = OptionInfoPresets.Library.RemoveFromLibrary.Name,
				Icon = OptionInfoPresets.Library.RemoveFromLibrary.Icon,
			})

		else
			table.insert(Options, {
				Name = OptionInfoPresets.Library.AddToLibrary.Name,
				Icon = OptionInfoPresets.Library.AddToLibrary.Icon,
			})
		end

		table.insert(Options, {
			Name = OptionInfoPresets.Playlist.AddToPlaylist.Name,
			Icon = OptionInfoPresets.Playlist.AddToPlaylist.Icon,
		})

		table.insert(Options, "SEPARATOR")

		if IsFavorited then
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.UndoFavorite.Name,
				Icon = OptionInfoPresets.Preferences.UndoFavorite.Icon,
			})

		else
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.Favorite.Name,
				Icon = OptionInfoPresets.Preferences.Favorite.Icon,
			})
		end

		if IsDisliked then
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.UndoDislike.Name,
				Icon = OptionInfoPresets.Preferences.UndoDislike.Icon,
			})

		else
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.Dislike.Name,
				Icon = OptionInfoPresets.Preferences.Dislike.Icon,
			})
		end

		table.insert(Options, "SEPARATOR")

		table.insert(Options, {
			Name = OptionInfoPresets.Share.ShareSong.Name,
			Icon = OptionInfoPresets.Share.ShareSong.Icon,
		})

	elseif Source == "Queue" then
		Options = {
			OptionInfoPresets.PlayModes.ProceedHere,
			OptionInfoPresets.PlayModes.PlayAlone,

			"SEPARATOR",

			OptionInfoPresets.Queue.RemoveFromQueue,
			OptionInfoPresets.Queue.ClearQueue,
		}

	elseif Source == "ContinuePlaying" then
		Options = {
			OptionInfoPresets.PlayModes.ProceedHere,
			OptionInfoPresets.PlayModes.PlayAlone,

			"SEPARATOR",

			OptionInfoPresets.Queue.RemoveFromQueue,
			OptionInfoPresets.Queue.ClearContinuePlaying,
		}

	elseif Source == "Library" then

		local SongId = Data.MasterPool[Data.Pointer]
		local SongsInQueue = (#VisualQueue.Queue + #VisualQueue.ContinuePlaying)

		local IsAdded = events.Main.Library.IsSongSaved:InvokeServer(SongId)
		local IsPinned = events.Main.Library.IsPinned:InvokeServer("Song", SongId)
		local IsFavorited = events.Main.Preferences.IsSongFavorite:InvokeServer(SongId)
		local IsDisliked = events.Main.Preferences.IsSongDislike:InvokeServer(SongId)

		if IsPinned then
			table.insert(Options, {
				Name = OptionInfoPresets.Library.UndoPin.Name,
				Icon = OptionInfoPresets.Library.UndoPin.Icon,
				Primary = true
			})

		else
			table.insert(Options, {
				Name = OptionInfoPresets.Library.Pin.Name,
				Icon = OptionInfoPresets.Library.Pin.Icon,
				Primary = true
			})
		end

		if SongsInQueue == 0 and not Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
				Primary = true
			})

		elseif SongsInQueue == 0 and Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
			})

		elseif SongsInQueue > 1 then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
				Primary = true
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayLast.Name,
				Icon = OptionInfoPresets.PlayModes.PlayLast.Icon,
				Primary = true
			})
		end

		table.insert(Options, "SEPARATOR")

		if IsAdded then
			table.insert(Options, {
				Name = OptionInfoPresets.Library.RemoveFromLibrary.Name,
				Icon = OptionInfoPresets.Library.RemoveFromLibrary.Icon,
			})

		else
			table.insert(Options, {
				Name = OptionInfoPresets.Library.AddToLibrary.Name,
				Icon = OptionInfoPresets.Library.AddToLibrary.Icon,
			})
		end

		table.insert(Options, {
			Name = OptionInfoPresets.Playlist.CreatePlaylistWith.Name,
			Icon = OptionInfoPresets.Playlist.CreatePlaylistWith.Icon,
		})

		table.insert(Options, {
			Name = OptionInfoPresets.Playlist.AddToPlaylist.Name,
			Icon = OptionInfoPresets.Playlist.AddToPlaylist.Icon,
		})

		table.insert(Options, "SEPARATOR")

		if IsFavorited then
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.UndoFavorite.Name,
				Icon = OptionInfoPresets.Preferences.UndoFavorite.Icon,
			})

		else
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.Favorite.Name,
				Icon = OptionInfoPresets.Preferences.Favorite.Icon,
			})
		end

		if IsDisliked then
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.UndoDislike.Name,
				Icon = OptionInfoPresets.Preferences.UndoDislike.Icon,
			})

		else
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.Dislike.Name,
				Icon = OptionInfoPresets.Preferences.Dislike.Icon,
			})
		end

		table.insert(Options, "SEPARATOR")

		table.insert(Options, {
			Name = OptionInfoPresets.Share.ShareSong.Name,
			Icon = OptionInfoPresets.Share.ShareSong.Icon,
		})

	elseif Source == "NowPlaying" then
		local SongId = Data.SongId

		local IsAdded = events.Main.Library.IsSongSaved:InvokeServer(SongId)
		local IsFavorited = events.Main.Preferences.IsSongFavorite:InvokeServer(SongId)
		local IsDisliked = events.Main.Preferences.IsSongDislike:InvokeServer(SongId)

		table.insert(Options, {
			Name = OptionInfoPresets.Others.ViewDetails.Name,
			Icon = OptionInfoPresets.Others.ViewDetails.Icon
		})

		table.insert(Options, "SEPARATOR")

		if IsAdded then
			table.insert(Options, {
				Name = OptionInfoPresets.Library.RemoveFromLibrary.Name,
				Icon = OptionInfoPresets.Library.RemoveFromLibrary.Icon
			})
		else
			table.insert(Options, {
				Name = OptionInfoPresets.Library.AddToLibrary.Name,
				Icon = OptionInfoPresets.Library.AddToLibrary.Icon
			})
		end

		table.insert(Options, {
			Name = OptionInfoPresets.Playlist.CreatePlaylistWith.Name,
			Icon = OptionInfoPresets.Playlist.CreatePlaylistWith.Icon,
		})

		table.insert(Options, {
			Name = OptionInfoPresets.Playlist.AddToPlaylist.Name,
			Icon = OptionInfoPresets.Playlist.AddToPlaylist.Icon
		})

		table.insert(Options, "SEPARATOR")

		if IsFavorited then
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.UndoFavorite.Name,
				Icon = OptionInfoPresets.Preferences.UndoFavorite.Icon,
			})

		else
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.Favorite.Name,
				Icon = OptionInfoPresets.Preferences.Favorite.Icon,
			})
		end

		if IsDisliked then
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.UndoDislike.Name,
				Icon = OptionInfoPresets.Preferences.UndoDislike.Icon,
			})

		else
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.Dislike.Name,
				Icon = OptionInfoPresets.Preferences.Dislike.Icon,
			})
		end

		table.insert(Options, "SEPARATOR")

		table.insert(Options, {
			Name = OptionInfoPresets.Share.ShareSong.Name,
			Icon = OptionInfoPresets.Share.ShareSong.Icon,
		})

	elseif Source == "Playlist" then
		local SongId = Data.MasterPool[Data.Pointer]
		local SongsInQueue = (#VisualQueue.Queue + #VisualQueue.ContinuePlaying)

		local IsFavorited = events.Main.Preferences.IsSongFavorite:InvokeServer(SongId)
		local IsDisliked = events.Main.Preferences.IsSongDislike:InvokeServer(SongId)

		if SongsInQueue == 0 and not Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
				Primary = true
			})

		elseif SongsInQueue == 0 and Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
			})

		elseif SongsInQueue > 1 then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
				Primary = true
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayLast.Name,
				Icon = OptionInfoPresets.PlayModes.PlayLast.Icon,
				Primary = true
			})
		end

		table.insert(Options, "SEPARATOR")

		table.insert(Options, {
			Name = OptionInfoPresets.Playlist.AddToPlaylist.Name,
			Icon = OptionInfoPresets.Playlist.AddToPlaylist.Icon,
		})

		if client.UserId == PlaylistPageProperties.CurrentCreatorId and table.find(PlaylistPageProperties.Songs, SongId) then
			table.insert(Options, {
				Name = OptionInfoPresets.Playlist.RemoveFromPlaylist.Name,
				Icon = OptionInfoPresets.Playlist.RemoveFromPlaylist.Icon,
			})
		end

		table.insert(Options, "SEPARATOR")

		if IsFavorited then
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.UndoFavorite.Name,
				Icon = OptionInfoPresets.Preferences.UndoFavorite.Icon,
			})

		else
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.Favorite.Name,
				Icon = OptionInfoPresets.Preferences.Favorite.Icon,
			})
		end

		if IsDisliked then
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.UndoDislike.Name,
				Icon = OptionInfoPresets.Preferences.UndoDislike.Icon,
			})

		else
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.Dislike.Name,
				Icon = OptionInfoPresets.Preferences.Dislike.Icon,
			})
		end

		table.insert(Options, "SEPARATOR")

		table.insert(Options, {
			Name = OptionInfoPresets.Share.ShareSong.Name,
			Icon = OptionInfoPresets.Share.ShareSong.Icon,
		})

	end

	local ContextMenuOption = Main.PromptOptions({
		Header = Data.Title,
		Options = Options,
		Mobile = Mobile
	})

	-- Play Modes

	if ContextMenuOption == "Play" then
		callback_Play(Data)

	elseif ContextMenuOption == "Play Next" then
		callback_PlayNext(Data)

	elseif ContextMenuOption == "Play Last" then
		callback_PlayLast(Data)

	elseif ContextMenuOption == "Play Alone" then
		Data.MasterPool = {Data.SongId}
		Data.Pointer = 1
		Data.ContextName = ""

		callback_Play(Data)

	elseif ContextMenuOption == "Proceed Here" then
		if not Data.TrackingId then return end

		Queue.ProceedByTrackingId(Data.TrackingId)


		-- Library

	elseif ContextMenuOption == "Add To Library" then
		callback_SongLibrary(1, Data)

	elseif ContextMenuOption == "Remove From Library" then
		callback_SongLibrary(2, Data)

	elseif ContextMenuOption == "Pin" then
		callback_PinSong(1, Data)

	elseif ContextMenuOption == "Undo Pin" then
		callback_PinSong(2, Data)

		-- Playlist

	elseif ContextMenuOption == "Create Playlist With" then
		Main.PlaylistCreation(true)

		PlaylistPageProperties.ToAdd = Data.SongId

	elseif ContextMenuOption == "Add To Playlist" then
		callback_AddToPlaylist(Data.SongId)

	elseif ContextMenuOption == "Remove From Playlist" then
		callback_SongPlaylist(2, Data.SongId, PlaylistPageProperties.CurrentPlaylistId)

		-- Preferences

	elseif ContextMenuOption == "Favorite" then
		callback_Favorite(1, Data)

	elseif ContextMenuOption == "Undo Favorite" then
		callback_Favorite(2, Data)

	elseif ContextMenuOption == "Dislike" then
		callback_Dislike(1, Data)

	elseif ContextMenuOption == "Undo Dislike" then
		callback_Dislike(2, Data)


		-- Queue

	elseif ContextMenuOption == "Clear Queue" then
		Queue.ClearQueue()

	elseif ContextMenuOption == "Clear Continue Playing" then
		Queue.ClearContinuePlaying()

	elseif ContextMenuOption == "Remove From Queue" then
		if not Data.TrackingId then return end

		Queue.RemoveByTrackingId(Data.TrackingId)

		-- Others

	elseif ContextMenuOption == "View Artist" then
		callback_ViewArtist(NowPlaying.Content.Media.Details.SongInfo.Source.Text)

	elseif ContextMenuOption == "View Details" then
		callback_ViewDetails()

		-- Share

	elseif ContextMenuOption == "Share Song" then
		callback_ShareSong(Data.SongId, Data.Title, Data.Artist)
	end

end

function PromptArtistOption(Source: ArtistSourceType, ArtistName, Mobile)
	local Options = {}

	if Source == "Standard" then
		local IsAdded = events.Main.Library.IsArtistSaved:InvokeServer(ArtistName)
		local IsBlocked = events.Main.Preferences.IsArtistBlock:InvokeServer(ArtistName)

		table.insert(Options, {
			Name = OptionInfoPresets.Others.ViewArtist.Name,
			Icon = OptionInfoPresets.Others.ViewArtist.Icon,
			Primary = true
		})

		table.insert(Options, "SEPARATOR")

		if IsAdded then
			table.insert(Options, {
				Name = OptionInfoPresets.Library.RemoveFromLibrary.Name,
				Icon = OptionInfoPresets.Library.RemoveFromLibrary.Icon,
			})
		else
			table.insert(Options, {
				Name = OptionInfoPresets.Library.AddToLibrary.Name,
				Icon = OptionInfoPresets.Library.AddToLibrary.Icon,
			})
		end

		table.insert(Options, "SEPARATOR")

		if IsBlocked then
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.UndoBlock.Name,
				Icon = OptionInfoPresets.Preferences.UndoBlock.Icon,
			})
		else
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.Block.Name,
				Icon = OptionInfoPresets.Preferences.Block.Icon,
			})
		end

	elseif Source == "Library" then
		local IsAdded = events.Main.Library.IsArtistSaved:InvokeServer(ArtistName)
		local IsPinned = events.Main.Library.IsPinned:InvokeServer("Artist", ArtistName)
		local IsBlocked = events.Main.Preferences.IsArtistBlock:InvokeServer(ArtistName)

		table.insert(Options, {
			Name = OptionInfoPresets.Others.ViewArtist.Name,
			Icon = OptionInfoPresets.Others.ViewArtist.Icon,
			Primary = true
		})

		if IsPinned then
			table.insert(Options, {
				Name = OptionInfoPresets.Library.UndoPin.Name,
				Icon = OptionInfoPresets.Library.UndoPin.Icon,
				Primary = true
			})
		else
			table.insert(Options, {
				Name = OptionInfoPresets.Library.Pin.Name,
				Icon = OptionInfoPresets.Library.Pin.Icon,
				Primary = true
			})

		end

		table.insert(Options, "SEPARATOR")

		if IsAdded then
			table.insert(Options, {
				Name = OptionInfoPresets.Library.RemoveFromLibrary.Name,
				Icon = OptionInfoPresets.Library.RemoveFromLibrary.Icon,
			})
		else
			table.insert(Options, {
				Name = OptionInfoPresets.Library.AddToLibrary.Name,
				Icon = OptionInfoPresets.Library.AddToLibrary.Icon,
			})
		end

		table.insert(Options, "SEPARATOR")

		if IsBlocked then
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.UndoBlock.Name,
				Icon = OptionInfoPresets.Preferences.UndoBlock.Icon,
			})
		else
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.Block.Name,
				Icon = OptionInfoPresets.Preferences.Block.Icon,
			})
		end
	elseif Source == "ArtistPage" then
		local IsAdded = events.Main.Library.IsArtistSaved:InvokeServer(ArtistName)
		local IsBlocked = events.Main.Preferences.IsArtistBlock:InvokeServer(ArtistName)

		if IsAdded then
			table.insert(Options, {
				Name = OptionInfoPresets.Library.RemoveFromLibrary.Name,
				Icon = OptionInfoPresets.Library.RemoveFromLibrary.Icon,
			})
		else
			table.insert(Options, {
				Name = OptionInfoPresets.Library.AddToLibrary.Name,
				Icon = OptionInfoPresets.Library.AddToLibrary.Icon,
			})
		end

		table.insert(Options, "SEPARATOR")

		if IsBlocked then
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.UndoBlock.Name,
				Icon = OptionInfoPresets.Preferences.UndoBlock.Icon,
			})
		else
			table.insert(Options, {
				Name = OptionInfoPresets.Preferences.Block.Name,
				Icon = OptionInfoPresets.Preferences.Block.Icon,
			})
		end

		table.insert(Options, "SEPARATOR")

		table.insert(Options, {
			Name = OptionInfoPresets.Share.ShareArtist.Name,
			Icon = OptionInfoPresets.Share.ShareArtist.Icon,
		})

	end

	local ContextMenuOption = Main.PromptOptions({
		Header = ArtistName,
		Options = Options,
		Mobile = Mobile
	})

	if ContextMenuOption == "View Artist" then
		callback_ViewArtist(ArtistName)

		-- Library

	elseif ContextMenuOption == "Add To Library" then
		callback_ArtistLibrary(1, ArtistName)

	elseif ContextMenuOption == "Remove From Library" then
		callback_ArtistLibrary(2, ArtistName)

	elseif ContextMenuOption == "Pin" then
		callback_PinArtist(1, ArtistName)

	elseif ContextMenuOption == "Undo Pin" then
		callback_PinArtist(2, ArtistName)

		-- Preferences

	elseif ContextMenuOption == "Block" then
		callback_Block(1, ArtistName)

	elseif ContextMenuOption == "Undo Block" then
		callback_Block(2, ArtistName)

		-- Share

	elseif ContextMenuOption == "Share Artist" then
		callback_ShareArtist(ArtistName)
	end
end

function PromptPlaylistOption(Source: PlaylistSourceType, PlaylistData, Mobile)
	local VisualQueue = Queue.GetVisualQueue()
	local Options = {}

	if Source == "Standard" then
		local SongsInQueue = (#VisualQueue.Queue + #VisualQueue.ContinuePlaying)

		table.insert(Options, {
			Name = OptionInfoPresets.Others.ViewPlaylist.Name,
			Icon = OptionInfoPresets.Others.ViewPlaylist.Icon,
			Primary = true,
		})

		table.insert(Options, "SEPARATOR")

		if SongsInQueue == 0 and not Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
				Primary = true
			})

		elseif SongsInQueue == 0 and Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
			})

		elseif SongsInQueue > 1 then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
				Primary = true
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayLast.Name,
				Icon = OptionInfoPresets.PlayModes.PlayLast.Icon,
				Primary = true
			})
		end

		table.insert(Options, "SEPARATOR")

		table.insert(Options, {
			Name = OptionInfoPresets.Share.SharePlaylist.Name,
			Icon = OptionInfoPresets.Share.SharePlaylist.Icon,
		})

	elseif Source == "Library" then
		local SongsInQueue = (#VisualQueue.Queue + #VisualQueue.ContinuePlaying)
		local IsPinned = events.Main.Library.IsPinned:InvokeServer("Playlist", PlaylistData.PlaylistId)

		if IsPinned then
			table.insert(Options, {
				Name = OptionInfoPresets.Library.UndoPin.Name,
				Icon = OptionInfoPresets.Library.UndoPin.Icon,
				Primary = true
			})
		else
			table.insert(Options, {
				Name = OptionInfoPresets.Library.Pin.Name,
				Icon = OptionInfoPresets.Library.Pin.Icon,
				Primary = true
			})
		end

		table.insert(Options, "SEPARATOR")

		if SongsInQueue == 0 and not Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

		elseif SongsInQueue == 0 and Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
			})

		elseif SongsInQueue > 1 then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayLast.Name,
				Icon = OptionInfoPresets.PlayModes.PlayLast.Icon,
			})
		end

		table.insert(Options, "SEPARATOR")

		table.insert(Options, {
			Name = OptionInfoPresets.Playlist.DeletePlaylist.Name,
			Icon = OptionInfoPresets.Playlist.DeletePlaylist.Icon,
		})

		table.insert(Options, "SEPARATOR")

		table.insert(Options, {
			Name = OptionInfoPresets.Share.SharePlaylist.Name,
			Icon = OptionInfoPresets.Share.SharePlaylist.Icon,
		})

	elseif Source == "PlaylistPage" then
		local SongsInQueue = (#VisualQueue.Queue + #VisualQueue.ContinuePlaying)

		if SongsInQueue == 0 and not Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
				Primary = true
			})

		elseif SongsInQueue == 0 and Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
			})

		elseif SongsInQueue > 1 then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
				Primary = true
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayLast.Name,
				Icon = OptionInfoPresets.PlayModes.PlayLast.Icon,
				Primary = true
			})
		end

		table.insert(Options, "SEPARATOR")

		if client.UserId == PlaylistPageProperties.CurrentCreatorId then
			if PlaylistData.Private then
				table.insert(Options, {
					Name = OptionInfoPresets.Playlist.SetPublic.Name,
					Icon = OptionInfoPresets.Playlist.SetPublic.Icon,
				})
			else
				table.insert(Options, {
					Name = OptionInfoPresets.Playlist.SetPrivate.Name,
					Icon = OptionInfoPresets.Playlist.SetPrivate.Icon,
				})
			end

		else
			table.insert(Options, {
				Name = OptionInfoPresets.Playlist.AddToLibrary.Name,
				Icon = OptionInfoPresets.Playlist.AddToLibrary.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.Playlist.CopyPlaylist.Name,
				Icon = OptionInfoPresets.Playlist.CopyPlaylist.Icon,
			})
		end

		table.insert(Options, {
			Name = OptionInfoPresets.Playlist.DeletePlaylist.Name,
			Icon = OptionInfoPresets.Playlist.DeletePlaylist.Icon,
		})

		table.insert(Options, "SEPARATOR")

		table.insert(Options, {
			Name = OptionInfoPresets.Share.SharePlaylist.Name,
			Icon = OptionInfoPresets.Share.SharePlaylist.Icon,
		})

	end

	local ContextMenuOption = Main.PromptOptions({
		Options = Options,
		Mobile = Mobile
	})

	if ContextMenuOption == "View Playlist" then
		callback_ViewPlaylist(PlaylistData.CreatorId, PlaylistData.PlaylistId)

		-- Library

	elseif ContextMenuOption == "Pin" then
		callback_PinPlaylist(1, PlaylistData.PlaylistId)

	elseif ContextMenuOption == "Undo Pin" then
		callback_PinPlaylist(2, PlaylistData.PlaylistId)

		-- Play Modes

	elseif ContextMenuOption == "Play" then
		Queue.LoadSource(PlaylistData.Songs, 1, PlaylistData.Name, true)

	elseif ContextMenuOption == "Play Next" then
		Queue.PlayNext(PlaylistData.Songs)

	elseif ContextMenuOption == "Play Last" then
		Queue.AddToQueue(PlaylistData.Songs)

		-- Other

	elseif ContextMenuOption == "Set to Private" then
		local success = events.Main.Library.SetPlaylistProperty:InvokeServer(PlaylistData.PlaylistId, "Private", true)

		if success then
			PlaylistPageProperties.RequestReload:Fire()

			Alerts.BannerNotify({
				Header = "Set this Playlist Private",
				Description = "You set this playlist private. You're the only one able to see this playlist.",
				Icon = "rbxassetid://14187755345"
			})
		else
			Alerts.BannerNotify({
				Header = "An Error Occurred.",
				Description = "An error occurred while setting this playlist private.",
				Icon = "rbxassetid://14187755345"
			})
		end

	elseif ContextMenuOption == "Set to Public" then
		local success = events.Main.Library.SetPlaylistProperty:InvokeServer(PlaylistData.PlaylistId, "Private", false)

		if success then
			PlaylistPageProperties.RequestReload:Fire()

			Alerts.BannerNotify({
				Header = "Set this Playlist Public",
				Description = "You set this playlist public. Share this playlist and let anyone view this playlist.",
				Icon = "rbxassetid://11293979388"
			})
		else
			Alerts.BannerNotify({
				Header = "An Error Occurred.",
				Description = "An error occurred while setting this playlist public.",
				Icon = "rbxassetid://14187755345"
			})
		end

	elseif ContextMenuOption == "Add To Library" then
		events.Main.Library.AddPublicPlaylist:InvokeServer(
			PlaylistPageProperties.CurrentCreatorId, PlaylistPageProperties.CurrentPlaylistId, false)

		LibraryProperties.RequestReload:Fire()

	elseif ContextMenuOption == "Copy Playlist" then
		events.Main.Library.AddPublicPlaylist:InvokeServer(
			PlaylistPageProperties.CurrentCreatorId, PlaylistPageProperties.CurrentPlaylistId, true)

		LibraryProperties.RequestReload:Fire()

	elseif ContextMenuOption == "Delete Playlist" then
		events.Main.Library.DeletePlaylist:FireServer(PlaylistData.PlaylistId)

		if Main.GetCurrentPage() == "Playlist" then
			Main.SetPage(Main.GetLastMainPage())
		else
			LibraryProperties.RequestReload:Fire()
		end

	elseif ContextMenuOption == "Share Playlist" then
		callback_SharePlaylist(PlaylistData)
	end
end

function PromptStationOption(Source: StationItemProperties, StationData, Online, Mobile)
	local VisualQueue = Queue.GetVisualQueue()
	local Options = {}

	if Source == "Standard" then
		local SongsInQueue = (#VisualQueue.Queue + #VisualQueue.ContinuePlaying)

		table.insert(Options, {
			Name = OptionInfoPresets.Others.ViewStation.Name,
			Icon = OptionInfoPresets.Others.ViewStation.Icon,
			Primary = true,
		})

		table.insert(Options, "SEPARATOR")

		if SongsInQueue == 0 and not Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
				Primary = true
			})

		elseif SongsInQueue == 0 and Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
			})

		elseif SongsInQueue > 1 then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayLast.Name,
				Icon = OptionInfoPresets.PlayModes.PlayLast.Icon,
			})
		end

	elseif Source == "StationPage" then
		local SongsInQueue = (#VisualQueue.Queue + #VisualQueue.ContinuePlaying)

		if SongsInQueue == 0 and not Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
				Primary = true
			})

		elseif SongsInQueue == 0 and Queue.GetActiveSound() then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
			})

		elseif SongsInQueue > 1 then
			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.Play.Name,
				Icon = OptionInfoPresets.PlayModes.Play.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayNext.Name,
				Icon = OptionInfoPresets.PlayModes.PlayNext.Icon,
			})

			table.insert(Options, {
				Name = OptionInfoPresets.PlayModes.PlayLast.Name,
				Icon = OptionInfoPresets.PlayModes.PlayLast.Icon,
			})
		end

		table.insert(Options, "SEPARATOR")

		table.insert(Options, {
			Name = OptionInfoPresets.Stations.CopyStation.Name,
			Icon = OptionInfoPresets.Stations.CopyStation.Icon,
		})
	end

	local ContextMenuOption = Main.PromptOptions({
		Options = Options,
		Mobile = Mobile
	})

	if ContextMenuOption == "View Station" then
		callback_ViewStation(Online, StationData.StationId)

		-- Play Modes

	elseif ContextMenuOption == "Play" then
		Queue.LoadSource(StationData.Songs, 1, StationData.Name, true)

	elseif ContextMenuOption == "Play Next" then
		Queue.PlayNext(StationData.Songs)

	elseif ContextMenuOption == "Play Last" then
		Queue.AddToQueue(StationData.Songs)

		-- Other

	elseif ContextMenuOption == "Copy Station" then
		if Online then
			callback_CopyOnlineStation(StationData.StationId)
		else
			callback_CopyLocalStation(StationData.StationId)
		end
	end
end

-- Functions / Main

function LoadSettings()
	if SettingsPageProperties.LoadingSettings then return end

	SettingsPageProperties.LoadingSettings = true
	SettingsPageProperties.HasChanged = false

	-- Set Page

	SettingsPage.Util.Loading.Visible = true
	SettingsPage.Header.Visible = false
	SettingsPage.Scroll.Visible = false

	Main.Settings(true)

	-- Data

	local SettingsLoaded = Settings.FetchSettings()
	if not SettingsLoaded then SettingsPageProperties.LoadingSettings = false return end

	SettingsPageProperties.Data = SettingsLoaded

	-- Data / Playback

	if SettingsLoaded.Playback.Crossfade.Enabled then
		local ScaleX = Utilities.Map(SettingsLoaded.Playback.Crossfade.Duration, 1, 10, 0, 1)

		Utilities.SwitchToggle(SettingsPage.Scroll.Playback.Container.Crossfade.Enabled.Switch, true)

		SettingsPage.Scroll.Playback.Container.Crossfade.Duration.Visible = true
		SettingsPage.Scroll.Playback.Container.Crossfade.Duration.Timeline.Scrubber.Fill.Size = UDim2.fromScale(ScaleX, 1)
	else
		local ScaleX = Utilities.Map(SettingsLoaded.Playback.Crossfade.Duration, 1, 10, 0, 1)

		Utilities.SwitchToggle(SettingsPage.Scroll.Playback.Container.Crossfade.Enabled.Switch, false)

		SettingsPage.Scroll.Playback.Container.Crossfade.Duration.Visible = false
		SettingsPage.Scroll.Playback.Container.Crossfade.Duration.Timeline.Scrubber.Fill.Size = UDim2.fromScale(ScaleX, 1)
	end

	if SettingsLoaded.Playback.Equalizer.Enabled then
		Utilities.SwitchToggle(SettingsPage.Scroll.Playback.Container.Equalizer.Enabled.Switch, true)

		SettingsPage.Scroll.Playback.Container.Equalizer.HighGain.Visible = true
		SettingsPage.Scroll.Playback.Container.Equalizer.LowGain.Visible = true
		SettingsPage.Scroll.Playback.Container.Equalizer.MiddleGain.Visible = true
	else
		Utilities.SwitchToggle(SettingsPage.Scroll.Playback.Container.Equalizer.Enabled.Switch, false)

		SettingsPage.Scroll.Playback.Container.Equalizer.HighGain.Visible = false
		SettingsPage.Scroll.Playback.Container.Equalizer.LowGain.Visible = false
		SettingsPage.Scroll.Playback.Container.Equalizer.MiddleGain.Visible = false
	end

	SettingsPage.Scroll.Playback.Container.Equalizer.HighGain.Value.Text = SettingsLoaded.Playback.Equalizer.HighGain
	SettingsPage.Scroll.Playback.Container.Equalizer.MiddleGain.Value.Text = SettingsLoaded.Playback.Equalizer.MidGain
	SettingsPage.Scroll.Playback.Container.Equalizer.LowGain.Value.Text = SettingsLoaded.Playback.Equalizer.LowGain

	-- Data / Extras

	Utilities.SwitchToggle(SettingsPage.Scroll.Extras.Container.Glow.Switch, SettingsLoaded.Extras.Glow)
	Utilities.SwitchToggle(SettingsPage.Scroll.Extras.Container.PlaybackHaptics.Switch, SettingsLoaded.Extras.PlaybackHaptics)

	-- Data / Socials

	Utilities.SwitchToggle(SettingsPage.Scroll.Socials.Container.Sharing.Switch, SettingsLoaded.Socials.Sharing)
	Utilities.SwitchToggle(SettingsPage.Scroll.Socials.Container.ListeningVisibility.Switch, SettingsLoaded.Socials.ListeningVisibility)

	--

	SettingsPage.Util.Loading.Visible = false
	SettingsPage.Header.Visible = true
	SettingsPage.Scroll.Visible = true

	SettingsPageProperties.LoadingSettings = false
end

function LoadPlaylist(CreatorId, PlaylistId)
	if not PlaylistId then return end
	if PlaylistPageProperties.LoadingPlaylist then return end

	PlaylistPageProperties.LoadingPlaylist = true

	local Songs = {}
	local Duration = 0

	-- Set Page

	Full.Container.Playlist.Util.Loading.Visible = true
	Full.Container.Playlist.Canvas.Visible = false
	Full.Container.Playlist.Header.Visible = false
	Full.Container.Playlist.QueueList.Visible = false
	Full.Container.Playlist.FeaturedArtists.Visible = false

	Main.SetPage("Playlist")

	PlaylistPageProperties.CurrentPlaylistId = PlaylistId

	-- Residual

	for i, residual in Full.Container.Playlist.QueueList:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	for i, residual in Full.Container.Playlist.FeaturedArtists.Content:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	-- Data

	local Data = events.Main.Library.GetPlaylistByPlaylistId:InvokeServer(CreatorId, PlaylistId)
	if not Data then PlaylistPageProperties.LoadingPlaylist = false return end

	local Metadata = Audios.GetAudioMetadataAsync(Data.Songs)
	if not Metadata then PlaylistPageProperties.LoadingPlaylist = false return end

	local Success, Username = pcall(function()
		return Players:GetNameFromUserIdAsync(Data.CreatorId)
	end)

	if not Success then PlaylistPageProperties.LoadingPlaylist = false return end

	PlaylistPageProperties.Songs = Data.Songs
	PlaylistPageProperties.CurrentCreatorId = Data.CreatorId
	PlaylistPageProperties.CurrentPlaylistName = Data.Name
	PlaylistPageProperties.CurrentPlaylistData = Data

	if #Data.Songs == 30 then
		Full.Container.Playlist.Canvas.Details.Action.Add.Visible = false
	else
		Full.Container.Playlist.Canvas.Details.Action.Add.Visible = true
	end

	Full.Container.Playlist.Canvas.Details.Action.Add.Visible = Data.CreatorId == client.UserId

	if Data.CreatorId ~= client.UserId and Data.Private then
		Full.Container.Playlist.Util.Loading.Visible = true
		Full.Container.Playlist.Canvas.Visible = false
		Full.Container.Playlist.Header.Visible = false
		Full.Container.Playlist.QueueList.Visible = false

		PlaylistPageProperties.LoadingPlaylist = false

		Main.SetPage(Main.GetLastMainPage())

		Alerts.BannerNotify({
			Header = "Failed to Load Playlist",
			Description = `Failed to load this playlist because {Data.Name} is now private.`,
			Icon = "rbxassetid://14187755345"
		})

		return
	end

	if Data.Cover == "" then
		if #Data.Songs > 0 then
			Full.Util.PlaylistBackground.Background.Image = Utilities.GetCoverForSong(Data.Songs[1])

			if #Data.Songs == 1 then
				Full.Container.Playlist.Canvas.Art.Photo.Image = ""

				Full.Container.Playlist.Canvas.Art.Photo.Default.Visible = true
				Full.Container.Playlist.Canvas.Art.Photo.Default.grid.CellSize = UDim2.fromScale(1, 1)

				Full.Container.Playlist.Canvas.Art.Photo.Default.CoverA.Image = Utilities.GetCoverForSong(Data.Songs[1])

			elseif #Data.Songs == 2 then
				Full.Container.Playlist.Canvas.Art.Photo.Image = ""

				Full.Container.Playlist.Canvas.Art.Photo.Default.Visible = true
				Full.Container.Playlist.Canvas.Art.Photo.Default.grid.CellSize = UDim2.fromScale(.5, 1)

				Full.Container.Playlist.Canvas.Art.Photo.Default.CoverA.Image = Utilities.GetCoverForSong(Data.Songs[1])
				Full.Container.Playlist.Canvas.Art.Photo.Default.CoverB.Image = Utilities.GetCoverForSong(Data.Songs[2])

			elseif #Data.Songs == 3 then
				Full.Container.Playlist.Canvas.Art.Photo.Image = ""

				Full.Container.Playlist.Canvas.Art.Photo.Default.Visible = true
				Full.Container.Playlist.Canvas.Art.Photo.Default.grid.CellSize = UDim2.fromScale(1, .34)

				Full.Container.Playlist.Canvas.Art.Photo.Default.CoverA.Image = Utilities.GetCoverForSong(Data.Songs[1])
				Full.Container.Playlist.Canvas.Art.Photo.Default.CoverB.Image = Utilities.GetCoverForSong(Data.Songs[2])
				Full.Container.Playlist.Canvas.Art.Photo.Default.CoverC.Image = Utilities.GetCoverForSong(Data.Songs[3])

			elseif #Data.Songs > 3 then
				Full.Container.Playlist.Canvas.Art.Photo.Image = ""

				Full.Container.Playlist.Canvas.Art.Photo.Default.Visible = true
				Full.Container.Playlist.Canvas.Art.Photo.Default.grid.CellSize = UDim2.fromScale(.5, .5)

				Full.Container.Playlist.Canvas.Art.Photo.Default.CoverA.Image = Utilities.GetCoverForSong(Data.Songs[1])
				Full.Container.Playlist.Canvas.Art.Photo.Default.CoverB.Image = Utilities.GetCoverForSong(Data.Songs[2])
				Full.Container.Playlist.Canvas.Art.Photo.Default.CoverC.Image = Utilities.GetCoverForSong(Data.Songs[3])
				Full.Container.Playlist.Canvas.Art.Photo.Default.CoverD.Image = Utilities.GetCoverForSong(Data.Songs[4])
			end
		else
			Full.Util.PlaylistBackground.Background.Image =  "rbxassetid://74118540785733"
			Full.Container.Playlist.Canvas.Art.Photo.Image =  "rbxassetid://74118540785733"
			Full.Container.Playlist.Canvas.Art.Photo.Default.Visible = false
		end
	else
		Full.Util.PlaylistBackground.Background.Image = Data.Cover
		Full.Container.Playlist.Canvas.Art.Photo.Image = Data.Cover
	end

	for i, Song in Metadata do
		Duration += Song.Duration

		AddSongItem({
			Container = Full.Container.Playlist.QueueList,
			ContextName = Data.Name,
			Item = ui.Storage.Items["Item(Vertical)"],
			MasterPool = Data.Songs,
			Pointer = i,
			SongInfo = Song,
			Source = "Playlist"
		})

		--

		local AlreadyAdded = Full.Container.Playlist.FeaturedArtists.Content:FindFirstChild(Song.Artist)

		if not AlreadyAdded then
			AddArtistItem({
				Container = Full.Container.Playlist.FeaturedArtists.Content,
				Item = ui.Storage.Items["Artist(Standard)"],
				ArtistName = Song.Artist,
				Source = "Standard"
			})
		end
	end

	Full.Container.Playlist.Canvas.Details.Info.Source.Text = Username
	Full.Container.Playlist.Canvas.Details.Info.Title.Text = Data.Name

	local UpData = Utilities.FormatEpochData(Data.Updated)

	if #Data.Songs > 1 then
		Full.Container.Playlist.FeaturedArtists.Visible = true
		Full.Container.Playlist.Canvas.Details.Info.Subtext.Text = 
			`{#Data.Songs} Songs · {Utilities.FormatSecondsToHM(Duration, true)} · Updated {UpData.Relative}`
	else
		if #Data.Songs == 0 then
			Full.Container.Playlist.FeaturedArtists.Visible = false
			Full.Container.Playlist.Canvas.Details.Info.Subtext.Text = `No Songs · Updated {UpData.Relative}`
		else
			Full.Container.Playlist.FeaturedArtists.Visible = true
			Full.Container.Playlist.Canvas.Details.Info.Subtext.Text = 
				`{#Data.Songs} Song · {Utilities.FormatSecondsToHM(Duration, true)} · Updated {UpData.Relative}`
		end
	end

	Full.Container.Playlist.Util.Loading.Visible = false
	Full.Container.Playlist.Canvas.Visible = true
	Full.Container.Playlist.Header.Visible = true
	Full.Container.Playlist.QueueList.Visible = true

	PlaylistPageProperties.LoadingPlaylist = false
end

function LoadOnlineStation(StationId)
	if not StationId then return end
	if StationPageProperties.LoadingStation then return end

	StationPageProperties.LoadingStation = true
	StationPageProperties.IsCurrentlyOnline = true

	local Songs = {}
	local Duration = 0

	-- Set Page

	Full.Container.Stations.Util.Loading.Visible = true
	Full.Container.Stations.Canvas.Visible = false
	Full.Container.Stations.Header.Visible = false
	Full.Container.Stations.QueueList.Visible = false
	Full.Container.Stations.FeaturedArtists.Visible = false

	Main.SetPage("Stations")

	StationPageProperties.CurrentStationId = StationId

	-- Residual

	for i, residual in Full.Container.Stations.QueueList:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	for i, residual in Full.Container.Stations.FeaturedArtists.Content:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	-- Data

	local Data = OnlineStations.GetOnlineStationByStationId(StationId)
	if not Data then StationPageProperties.LoadingStation = false return end

	local Metadata = Audios.GetAudioMetadataAsync(Data.Songs)
	if not Metadata then StationPageProperties.LoadingStation = false return end

	StationPageProperties.Songs = Data.Songs
	StationPageProperties.CurrentStationData = Data

	if Data.Cover == "" then
		Full.Util.PlaylistBackground.Background.Image =  "rbxassetid://74118540785733"
		Full.Container.Stations.Canvas.Art.Photo.Image =  "rbxassetid://74118540785733"
	else
		Full.Util.PlaylistBackground.Background.Image = Data.Cover
		Full.Container.Stations.Canvas.Art.Photo.Image = Data.Cover
	end

	for i, Song in Metadata do
		Duration += Song.Duration or 0

		AddSongItem({
			Container = Full.Container.Stations.QueueList,
			ContextName = Data.Name,
			Item = ui.Storage.Items["Item(Vertical)"],
			MasterPool = Data.Songs,
			Pointer = i,
			SongInfo = Song,
			Source = "Standard"
		})

		--

		local AlreadyAdded = Full.Container.Stations.FeaturedArtists.Content:FindFirstChild(Song.Artist)

		if not AlreadyAdded then
			AddArtistItem({
				Container = Full.Container.Stations.FeaturedArtists.Content,
				Item = ui.Storage.Items["Artist(Standard)"],
				ArtistName = Song.Artist,
				Source = "Standard"
			})
		end
	end

	Full.Container.Stations.Canvas.Details.Info.Source.Text = "Masters"
	Full.Container.Stations.Canvas.Details.Info.Title.Text = Data.Name

	local UpData = Utilities.FormatEpochData(Data.Updated)

	if #Data.Songs > 1 then
		Full.Container.Stations.FeaturedArtists.Visible = true
		Full.Container.Stations.Canvas.Details.Info.Subtext.Text = 
			`{#Data.Songs} Songs · {Utilities.FormatSecondsToHM(Duration, true)} · Updated {UpData.Relative}`
	else
		if #Data.Songs == 0 then
			Full.Container.Stations.FeaturedArtists.Visible = false
			Full.Container.Stations.Canvas.Details.Info.Subtext.Text = `No Songs · Updated {UpData.Relative}`
		else
			Full.Container.Stations.FeaturedArtists.Visible = true
			Full.Container.Stations.Canvas.Details.Info.Subtext.Text = 
				`{#Data.Songs} Song · {Utilities.FormatSecondsToHM(Duration, true)} · Updated {UpData.Relative}`
		end
	end

	Full.Container.Stations.Util.Loading.Visible = false
	Full.Container.Stations.Canvas.Visible = true
	Full.Container.Stations.Header.Visible = true
	Full.Container.Stations.QueueList.Visible = true

	StationPageProperties.LoadingStation = false
end

function LoadLocalStation(StationId)
	if not StationId then return end
	if StationPageProperties.LoadingStation then return end

	StationPageProperties.LoadingStation = true
	StationPageProperties.IsCurrentlyOnline = false

	local Songs = {}
	local Duration = 0

	-- Set Page

	Full.Container.Stations.Util.Loading.Visible = true
	Full.Container.Stations.Canvas.Visible = false
	Full.Container.Stations.Header.Visible = false
	Full.Container.Stations.QueueList.Visible = false
	Full.Container.Stations.FeaturedArtists.Visible = false

	Main.SetPage("Stations")

	StationPageProperties.CurrentStationId = StationId

	-- Residual

	for i, residual in Full.Container.Stations.QueueList:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	for i, residual in Full.Container.Stations.FeaturedArtists.Content:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	-- Data

	local Data = Configuration.GetLocalStationByStationId(StationId)
	if not Data then StationPageProperties.LoadingStation = false return end

	local Metadata = Audios.GetAudioMetadataAsync(Data.Songs)
	if not Metadata then StationPageProperties.LoadingStation = false return end

	StationPageProperties.Songs = Data.Songs
	StationPageProperties.CurrentStationData = Data

	if Data.Cover == "" then
		Full.Util.PlaylistBackground.Background.Image =  "rbxassetid://74118540785733"
		Full.Container.Stations.Canvas.Art.Photo.Image =  "rbxassetid://74118540785733"
	else
		Full.Util.PlaylistBackground.Background.Image = Data.Cover
		Full.Container.Stations.Canvas.Art.Photo.Image = Data.Cover
	end

	for i, Song in Metadata do
		Duration += Song.Duration

		AddSongItem({
			Container = Full.Container.Stations.QueueList,
			ContextName = Data.Name,
			Item = ui.Storage.Items["Item(Vertical)"],
			MasterPool = Data.Songs,
			Pointer = i,
			SongInfo = Song,
			Source = "Standard"
		})

		--

		local AlreadyAdded = Full.Container.Stations.FeaturedArtists.Content:FindFirstChild(Song.Artist)

		if not AlreadyAdded then
			AddArtistItem({
				Container = Full.Container.Stations.FeaturedArtists.Content,
				Item = ui.Storage.Items["Artist(Standard)"],
				ArtistName = Song.Artist,
				Source = "Standard"
			})
		end
	end

	Full.Container.Stations.Canvas.Details.Info.Source.Text = "Local"
	Full.Container.Stations.Canvas.Details.Info.Title.Text = Data.Name

	local UpData = Utilities.FormatEpochData(Data.Updated)

	if #Data.Songs > 1 then
		Full.Container.Stations.FeaturedArtists.Visible = true
		Full.Container.Stations.Canvas.Details.Info.Subtext.Text = 
			`{#Data.Songs} Songs · {Utilities.FormatSecondsToHM(Duration, true)} · Updated {UpData.Relative}`
	else
		if #Data.Songs == 0 then
			Full.Container.Stations.FeaturedArtists.Visible = false
			Full.Container.Stations.Canvas.Details.Info.Subtext.Text = `No Songs · Updated {UpData.Relative}`
		else
			Full.Container.Stations.FeaturedArtists.Visible = true
			Full.Container.Stations.Canvas.Details.Info.Subtext.Text = 
				`{#Data.Songs} Song · {Utilities.FormatSecondsToHM(Duration, true)} · Updated {UpData.Relative}`
		end
	end

	Full.Container.Stations.Util.Loading.Visible = false
	Full.Container.Stations.Canvas.Visible = true
	Full.Container.Stations.Header.Visible = true
	Full.Container.Stations.QueueList.Visible = true

	StationPageProperties.LoadingStation = false
end

function LoadArtist(ArtistName)
	if ArtistPageProperties.LoadingArtist then return end
	ArtistPageProperties.LoadingArtist = true

	local FinishedLoading = false

	local Genres = {}
	local SongIds = {
		Discography = {},
		Familiar = {},
		FamiliarList = {},
	}
	local Duration = 0

	-- Set Page

	local C1, C2 = Utilities.GenerateArtistGradient(ArtistName)

	Full.Util.ArtistBackground.Background.gradient.Color = ColorSequence.new(C1, C2)
	Full.Container.Artist.Action.Play.gradient.Color = ColorSequence.new(C1, C2)

	Full.Container.Artist.Util.Loading.Visible = true
	Full.Container.Artist.Action.Visible = false
	Full.Container.Artist.Canvas.Visible = false
	Full.Container.Artist.Header.Visible = false
	Full.Container.Artist.Sections.Visible = false

	Full.Container.Artist.Sections.Discography.Header.Search.Field.Text = ""
	DiscographySearchKeyword("", false)

	Main.SetPage("Artist")

	ArtistPageProperties.CurrentArtistLoaded = ArtistName

	local Discography = Audios.LoadArtist(ArtistName)
	if #Discography < 1 then return "NotArtist" end

	-- Residual

	for i, residual in Full.Container.Artist.Sections.Discography.Content:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	for i, residual in Full.Container.Artist.Sections.YWF.Content:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	-- Actions

	local Algorithm = events.Main.Algorithm.FetchAlgorithm:InvokeServer()
	local Library = events.Main.Library.FetchLibrary:InvokeServer()
	local Preferences = events.Main.Preferences.FetchPreference:InvokeServer()

	if table.find(Preferences.Artists.Block, ArtistName) then
		Full.Container.Artist.Action.Blocked.Visible = true
		Full.Container.Artist.Action.Play.Visible = false
		Full.Container.Artist.Action.Shuffle.Visible = false
	else
		Full.Container.Artist.Action.Blocked.Visible = false
		Full.Container.Artist.Action.Play.Visible = true
		Full.Container.Artist.Action.Shuffle.Visible = true
	end

	-- Discography

	for i, Song in Discography do
		local IsPlayed = false
		local IsSaved = false
		local IsFavorited = false
		local IsDisliked = false

		local Score = 0

		Duration += Song.Duration

		-- Tags

		for i, Tags in Song.Tags do
			table.insert(Genres, Tags)
		end

		-- Algorithm

		for i, PlayedSong in Algorithm.Songs do
			if PlayedSong.SongId == Song.Id then
				IsPlayed = true

				-- Played within 7 days

				if (os.time() - PlayedSong.LastUpdate) <= 604800 then
					Score += 20
				else
					Score += 5
				end

				-- Addition of relevance

				Score += PlayedSong.Relevance
			end
		end

		-- Library

		for i, SavedSong in Library.Songs do
			if SavedSong.SongId == Song.Id then
				IsSaved = true

				if SavedSong.Pinned then
					Score += 5
				else
					Score += 1
				end
			end
		end

		-- Preferences

		IsFavorited = table.find(Preferences.Songs.Favorite, Song.Id)
		if IsFavorited then Score += 10 end

		IsDisliked = table.find(Preferences.Songs.Dislike, Song.Id)
		if IsFavorited then Score -= 10 end

		--

		if IsPlayed or IsSaved or IsFavorited or IsDisliked then
			Song.Score = Score
			table.insert(SongIds.Familiar, Song)
		end

		table.insert(SongIds.Discography, Song.Id)

		AddSongItem({
			Container = Full.Container.Artist.Sections.Discography.Content,
			ContextName = ArtistName .. "'s Discography",
			Item = ui.Storage.Items["Item(Vertical)"],
			MasterPool = SongIds.Discography,
			Pointer = i,
			SongInfo = Song,
			Source = "Standard"
		})
	end

	for i, Song in SongIds.Familiar do
		table.insert(SongIds.FamiliarList, Song.Id)

		AddSongItem({
			Container = Full.Container.Artist.Sections.YWF.Content,
			ContextName = "You're Familiar With - " .. ArtistName,
			Item = ui.Storage.Items["Item(Big)"],
			ItemProperties = {LayoutOrder = -Song.Score},
			MasterPool = SongIds.FamiliarList,
			Pointer = i,
			SongInfo = Song,
			Source = "Standard"
		})
	end

	if #SongIds.FamiliarList < 1 then
		Full.Container.Artist.Sections.YWF.Visible = false
	else
		Full.Container.Artist.Sections.YWF.Visible = true
	end

	ArtistPageProperties.Discography = SongIds.Discography

	-- Canvas

	local ArrangedGenres = Utilities.ArrangeByFrequency(Genres)

	if #ArrangedGenres >= 2 then
		local FirstGenre = string.gsub(Utilities.CapitalizeWords(ArrangedGenres[1]), "-", " ")
		local SecondGenre = string.gsub(Utilities.CapitalizeWords(ArrangedGenres[2]), "-", " ")

		Full.Container.Artist.Canvas.Genres.Text = `{FirstGenre} · {SecondGenre}`

	elseif #ArrangedGenres == 1 then
		local FirstGenre = string.gsub(Utilities.CapitalizeWords(ArrangedGenres[1]), "-", " ")

		Full.Container.Artist.Canvas.Genres.Text = FirstGenre
	end

	if #Discography > 1 then
		Full.Container.Artist.Canvas.Genres.Text = `{Full.Container.Artist.Canvas.Genres.Text} · {#Discography} Songs`
	else
		Full.Container.Artist.Canvas.Genres.Text = `{Full.Container.Artist.Canvas.Genres.Text} · {#Discography} Song` 
	end

	Full.Container.Artist.Canvas.Genres.Text = `{Full.Container.Artist.Canvas.Genres.Text} · {Utilities.FormatSecondsToHM(Duration)}` 
	Full.Container.Artist.Canvas.Artist.Text = ArtistName

	Full.Container.Artist.Util.Loading.Visible = false
	Full.Container.Artist.Action.Visible = true
	Full.Container.Artist.Canvas.Visible = true
	Full.Container.Artist.Header.Visible = true
	Full.Container.Artist.Sections.Visible = true

	ArtistPageProperties.LoadingArtist = false
end

function LoadCurrentSongDetails()
	if DetailsPageProperties.LoadingDetails then return end

	local CurrentSongId = Queue.GetCurrentSongId()
	local Metadata = Queue.GetCurrentMetadata()

	if not CurrentSongId then return end
	if not Metadata then return end
	if Metadata.Id ~= CurrentSongId then return end

	local IsShared = events.Main.Sharing.IsShared:InvokeServer("Song", CurrentSongId)

	DetailsPageProperties.LoadingDetails = true
	DetailsPageProperties.CurrentSongLoaded = CurrentSongId

	Full.Util.DetailsBackground.Background.Image = Utilities.GetCoverForSong(CurrentSongId)

	Full.Container.Details.Util.Loading.Visible = true

	Full.Container.Details.Action.Visible = false
	Full.Container.Details.Canvas.Visible = false
	Full.Container.Details.Header.Visible = false
	Full.Container.Details.Sections.Visible = false

	Main.SetPage("Details")

	-- Details
	-- Details / Canvas

	Full.Container.Details.Canvas.Art.Photo.Image = Utilities.GetCoverForSong(CurrentSongId)
	Full.Container.Details.Canvas.Title.Text = Metadata.Title
	Full.Container.Details.Canvas.Source.Text = Metadata.Artist

	-- Details / Artist

	local C1, C2 = Utilities.GenerateArtistGradient(Metadata.Artist)

	Full.Container.Details.Sections.Artist.Container.Artist.Value.Text = Metadata.Artist
	Full.Container.Details.Sections.Artist.Container.Artist.Art.gradient.Color = ColorSequence.new(C1, C2)
	Full.Container.Details.Sections.Artist.Container.Artist.Art.Initials.Text = Utilities.GetInitials(Metadata.Artist)

	-- Details / Lyrics

	if NowPlayingProperties.CurrentLyricsLoaded and NowPlayingProperties.CurrentLyricsLoaded.SoundId == CurrentSongId then
		local CompiledLyrics = {}

		for i, Line in NowPlayingProperties.CurrentLyricsLoaded.Lyrics do
			if Line.Id == "CERTIFICATION" then
				table.insert(CompiledLyrics, "\n" .. Line.Line)
			else
				table.insert(CompiledLyrics, Line.Line)
			end
		end

		Full.Container.Details.Sections.Lyrics.Visible = true
		Full.Container.Details.Sections.Lyrics.DisplayLyrics.Text = table.concat(CompiledLyrics, "\n")
	else
		Full.Container.Details.Sections.Lyrics.Visible = false
	end

	-- Details / More Details

	if Metadata.Tags then
		local Genre = string.gsub(Utilities.CapitalizeWords(Metadata.Tags[1]), "-", " ")

		Full.Container.Details.Sections.Details.Container.Genre.Visible = true
		Full.Container.Details.Sections.Details.Container.Genre.Value.Text = Genre
	else
		Full.Container.Details.Sections.Details.Container.Genre.Visible = false
	end

	Full.Container.Details.Sections.Details.Container.Duration.Value.Text = Utilities.FormatSecondsToHM(Metadata.Duration, true)
	Full.Container.Details.Sections.Details.Container.AssetId.Value.Text = CurrentSongId

	if Metadata.UpdateTime then
		local EpochTime = Utilities.ISOToEpoch(Metadata.UpdateTime)

		if EpochTime then
			local EpochData = Utilities.FormatEpochData(EpochTime)

			Full.Container.Details.Sections.Dates.Container.Updated.Visible = true
			Full.Container.Details.Sections.Dates.Container.Updated.Value.Text =
				`{EpochData.Calender.Month.Long} {EpochData.Calender.Day}, {EpochData.Calender.Year.Long}`
		else
			Full.Container.Details.Sections.Dates.Container.Updated.Visible = false
		end
	else
		Full.Container.Details.Sections.Dates.Container.Updated.Visible = false
	end

	if Metadata.CreateTime then
		local EpochTime = Utilities.ISOToEpoch(Metadata.CreateTime)

		if EpochTime then
			local EpochData = Utilities.FormatEpochData(EpochTime)

			Full.Container.Details.Sections.Dates.Container.Released.Visible = true
			Full.Container.Details.Sections.Dates.Container.Released.Value.Text = 
				`{EpochData.Calender.Month.Long} {EpochData.Calender.Day}, {EpochData.Calender.Year.Long}`
		else
			Full.Container.Details.Sections.Dates.Container.Released.Visible = false
		end
	else
		Full.Container.Details.Sections.Dates.Container.Released.Visible = false
	end

	if IsShared then
		local EpochData = Utilities.FormatEpochData(IsShared.LatestDate)
		local Success, Username = pcall(function()
			return Players:GetNameFromUserIdAsync(IsShared.LatestSender)
		end)

		if Success then
			Full.Container.Details.Sections.Sharing.Visible = true

			Full.Container.Details.Sections.Sharing.Container.TotalShares.Value.Text = IsShared.TotalCount
			Full.Container.Details.Sections.Sharing.Container.Sender.Value.Text = "@" .. Username
			Full.Container.Details.Sections.Sharing.Container.Date.Value.Text = 
				`{EpochData.Calender.Month.Long} {EpochData.Calender.Day}, {EpochData.Calender.Year.Long} {EpochData.Time.Hour}:{EpochData.Time.Minutes} {EpochData.Time.Period}`

		else
			Full.Container.Details.Sections.Sharing.Visible = false
		end
	else
		Full.Container.Details.Sections.Sharing.Visible = false
	end

	DetailsPageProperties.LoadingDetails = false

	Full.Container.Details.Util.Loading.Visible = false

	Full.Container.Details.Action.Visible = true
	Full.Container.Details.Canvas.Visible = true
	Full.Container.Details.Header.Visible = true
	Full.Container.Details.Sections.Visible = true
end

-- Bar
-- Bar / Dragging

local function GetCorrectedPos(input)
	return Vector2.new(input.Position.X, input.Position.Y - GuiService.TopbarInset.Height)
end

local function Update(input)
	local CurrentPos = GetCorrectedPos(input)
	local Delta = CurrentPos - InterfaceDragProperties.MainDragStart
	local NewPos = UDim2.new(
		InterfaceDragProperties.MainStartPos.X.Scale, 
		InterfaceDragProperties.MainStartPos.X.Offset + Delta.X,
		InterfaceDragProperties.MainStartPos.Y.Scale, 
		InterfaceDragProperties.MainStartPos.Y.Offset + Delta.Y
	)

	TweenService:Create(ui.Interface, smooth, {Position = NewPos}):Play()
end

local function DisplayTuckScreen(State)
	if State then
		Bar.page:JumpTo(Bar.Tucked)

		if InterfaceDragProperties.SnappedTo == "Left" then
			Bar.Tucked.list.HorizontalAlignment = Enum.HorizontalAlignment.Right

			TweenService:Create(Bar.Tucked.LeftArrow, normal, {ImageTransparency = 1}):Play()
			TweenService:Create(Bar.Tucked.LeftArrow.scale, normal, {Scale = 0}):Play()

			TweenService:Create(Bar.Tucked.RightArrow, normal, {ImageTransparency = 0}):Play()
			TweenService:Create(Bar.Tucked.RightArrow.scale, normal, {Scale = 1}):Play()

		else
			Bar.Tucked.list.HorizontalAlignment = Enum.HorizontalAlignment.Left

			TweenService:Create(Bar.Tucked.LeftArrow, normal, {ImageTransparency = 0}):Play()
			TweenService:Create(Bar.Tucked.LeftArrow.scale, normal, {Scale = 1}):Play()

			TweenService:Create(Bar.Tucked.RightArrow, normal, {ImageTransparency = 1}):Play()
			TweenService:Create(Bar.Tucked.RightArrow.scale, normal, {Scale = 0}):Play()
		end
	else
		Bar.page:JumpTo(Bar.NowPlaying)

		TweenService:Create(Bar.Tucked.LeftArrow, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(Bar.Tucked.LeftArrow.scale, normal, {Scale = 0}):Play()

		TweenService:Create(Bar.Tucked.RightArrow, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(Bar.Tucked.RightArrow.scale, normal, {Scale = 0}):Play()
	end
end

local function UntuckInterface()
	local ScreenSize = camera.ViewportSize
	local FrameSize = ui.Interface.AbsoluteSize
	local currentCenterX = ui.Interface.AbsolutePosition.X + (FrameSize.X / 2)
	local currentCenterY = (ui.Interface.AbsolutePosition.Y + GuiService.TopbarInset.Height) + (FrameSize.Y / 2)
	local targetX = currentCenterX

	if currentCenterX < ScreenSize.X / 2 then
		targetX = (FrameSize.X / 2) + InterfaceDragProperties.Padding.Left
		InterfaceDragProperties.SnappedTo = "Left"

	else
		targetX = ScreenSize.X - (FrameSize.X / 2) - InterfaceDragProperties.Padding.Right
		InterfaceDragProperties.SnappedTo = "Right"
	end

	InterfaceDragProperties.Tucked = false

	DisplayTuckScreen(false)

	TweenService:Create(ui.Interface, smooth, {
		Position = UDim2.new(0, targetX, 0, currentCenterY)}):Play()
end

local function SnapToNearestSide(Tuck)
	local ScreenSize = camera.ViewportSize
	local FrameSize = ui.Interface.AbsoluteSize

	local rawCenterX = ui.Interface.AbsolutePosition.X + (FrameSize.X / 2)
	local rawCenterY = (ui.Interface.AbsolutePosition.Y + GuiService.TopbarInset.Height) + (FrameSize.Y / 2)
	local currentCenterX = math.clamp(rawCenterX, 0, ScreenSize.X)
	local currentCenterY = math.clamp(rawCenterY, 0, ScreenSize.Y)
	local targetX = currentCenterX

	if currentCenterX < ScreenSize.X / 2 then
		InterfaceDragProperties.SnappedTo = "Left"
		if Tuck then
			-- Use TuckDepth relative to 0
			targetX = 0 - InterfaceDragProperties.TuckDepth
			InterfaceDragProperties.Tucked = true
			DisplayTuckScreen(true)
		else
			targetX = (FrameSize.X / 2) + InterfaceDragProperties.Padding.Left
			InterfaceDragProperties.Tucked = false
			DisplayTuckScreen(false)
		end
	else
		InterfaceDragProperties.SnappedTo = "Right"
		if Tuck then
			-- Use TuckDepth relative to Max Width
			targetX = ScreenSize.X + InterfaceDragProperties.TuckDepth
			InterfaceDragProperties.Tucked = true
			DisplayTuckScreen(true)
		else
			targetX = ScreenSize.X - (FrameSize.X / 2) - InterfaceDragProperties.Padding.Right
			InterfaceDragProperties.Tucked = false
			DisplayTuckScreen(false)
		end
	end

	local minY = (FrameSize.Y / 2) + InterfaceDragProperties.Padding.Top
	local maxY = ScreenSize.Y - (FrameSize.Y / 2) - InterfaceDragProperties.Padding.Bottom
	local success, targetY = pcall(function()
		return math.clamp(currentCenterY, minY, maxY)
	end)

	if not success then
		targetY = ScreenSize.Y / 2
	end

	TweenService:Create(ui.Interface, smooth, {
		Position = UDim2.new(0, targetX, 0, targetY)}):Play()
end

Bar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		InterfaceDragProperties.MainDrag = true
		InterfaceDragProperties.MainDragStart = GetCorrectedPos(input)
		InterfaceDragProperties.MainStartPos = ui.Interface.Position

		InterfaceDragProperties.DragStarted:Fire()

		local connection
		connection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				connection:Disconnect()

				InterfaceDragProperties.MainDrag = false
				InterfaceDragProperties.DragReleased:Fire()

				task.delay(.05, function()
					InterfaceDragProperties.MainCurrentlyDragged = false
				end)

				local ScreenSize = camera.ViewportSize
				local FrameSize = ui.Interface.AbsoluteSize
				local currentCenterX = ui.Interface.AbsolutePosition.X + (FrameSize.X / 2)
				local currentCenterY = (ui.Interface.AbsolutePosition.Y + GuiService.TopbarInset.Height) + (FrameSize.Y / 2)
				local targetX = currentCenterX
				local targetY = currentCenterY

				InterfaceDragProperties.Tucked = false
				InterfaceDragProperties.SnappedTo = "None"

				DisplayTuckScreen(false)

				if currentCenterX < (InterfaceDragProperties.Padding.Left * -1) then
					targetX = -InterfaceDragProperties.TuckDepth
					InterfaceDragProperties.Tucked = true
					InterfaceDragProperties.SnappedTo = "Left"

					DisplayTuckScreen(true)

				elseif currentCenterX > (ScreenSize.X - (InterfaceDragProperties.Padding.Right * -1)) then
					targetX = ScreenSize.X + InterfaceDragProperties.TuckDepth
					InterfaceDragProperties.Tucked = true
					InterfaceDragProperties.SnappedTo = "Right"

					DisplayTuckScreen(true)

				else
					local distToLeft = currentCenterX 
					local distToRight = ScreenSize.X - currentCenterX
					local distToTop = currentCenterY
					local minDistance = math.min(distToLeft, distToRight, distToTop)

					if minDistance == distToLeft then
						targetX = (FrameSize.X / 2) + InterfaceDragProperties.Padding.Left
						InterfaceDragProperties.SnappedTo = "Left"

					elseif minDistance == distToRight then
						targetX = ScreenSize.X - (FrameSize.X / 2) - InterfaceDragProperties.Padding.Right
						InterfaceDragProperties.SnappedTo = "Right"

					else
						targetY = (FrameSize.Y / 2) + InterfaceDragProperties.Padding.Top
						InterfaceDragProperties.SnappedTo = "Top"
					end

					local maxBottom = ScreenSize.Y - (FrameSize.Y / 2) - InterfaceDragProperties.Padding.Bottom

					if targetY > maxBottom then
						targetY = maxBottom
					end

					if InterfaceDragProperties.SnappedTo == "Top" then
						targetX = math.clamp(targetX, (FrameSize.X / 2) + InterfaceDragProperties.Padding.Left, ScreenSize.X - (FrameSize.X / 2) - InterfaceDragProperties.Padding.Right)
					end
				end

				TweenService:Create(ui.Interface, smooth, {
					Position = UDim2.new(0, targetX, 0, targetY)}):Play()
			end
		end)
	end
end)

Bar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		InterfaceDragProperties.MainDragInput = input
	end
end)

InputService.InputChanged:Connect(function(input)
	if input == InterfaceDragProperties.MainDragInput and InterfaceDragProperties.MainDrag then
		if (GetCorrectedPos(input) - InterfaceDragProperties.MainDragStart).Magnitude > 2 then
			InterfaceDragProperties.MainCurrentlyDragged = true
		end

		Update(input)
	end
end)

InterfaceDragProperties.DragStarted:Connect(function()
	Utilities.Haptic(1, .01)
end)

InterfaceDragProperties.DragReleased:Connect(function()
	Utilities.Haptic(1, .01)
end)

--

Bar.MouseButton1Click:Connect(function()
	if InterfaceDragProperties.MainCurrentlyDragged then return end

	if Bar.page.CurrentPage == Bar.Tucked then
		UntuckInterface()
	else
		Main.SetLastPosition(ui.Interface.Position)
		Main.SetState("Full")
	end
end)

Bar.NowPlaying.Content.Controls.PlayPause.MouseButton1Click:Connect(function()
	events.Playback.PlayPause:Fire()
end)

-- Bar / Animations

Bar.NowPlaying.Content.Controls.PlayPause.MouseEnter:Connect(function()
	TweenService:Create(Bar.NowPlaying.Content.Controls.PlayPause.Icon.scale, normal, {Scale = 1.2}):Play()
end)

Bar.NowPlaying.Content.Controls.PlayPause.MouseButton1Down:Connect(function()
	TweenService:Create(Bar.NowPlaying.Content.Controls.PlayPause.Icon.scale, normal, {Scale = .6}):Play()
end)

Bar.NowPlaying.Content.Controls.PlayPause.InputEnded:Connect(function()
	TweenService:Create(Bar.NowPlaying.Content.Controls.PlayPause.Icon.scale, bounce, {Scale = 1}):Play()
end)

-- Initiations

Main.SetPage("Discovery")
Main.SetState("Bar")

SnapToNearestSide(true)
InitiateSettings()

Audios.LoadAudios(AudiosLoaded)

-- Full

local ArtistIndex = {}
local ArtistCommitted = 1
local PlaylistIndex = {}
local PlaylistComitted = 1
local SongIndex = {}
local SongCommitted = 1
local StationIndex = {}
local StationComitted = 1

function AddSongItem(DataInfo: SongItemProperties)
	SongCommitted += 1
	SongIndex[SongCommitted] = DataInfo

	local Data = SongIndex[SongCommitted]
	local SongId = tonumber(Data.MasterPool[Data.Pointer])

	if not SongId then return end
	if not Data then return end

	local Item = Data.Item:Clone()
	if not Item:IsA("ImageButton") then return end

	Item.Name = SongId
	Item:AddTag("MastersSong_" .. Data.Source)

	Item.Information.Source.Text = Data.SongInfo.Artist
	Item.Information.Title.Text = Data.SongInfo.Title

	Item.Art.Photo.Image = Utilities.GetCoverForSong(SongId)

	Item.Parent = Data.Container

	-- 

	local Connection = Queue.TrackChanged:Connect(function(CurrentSongId)
		if CurrentSongId == SongId then
			TweenService:Create(Item.Art.Photo.CurrentlyPlaying, normal, {GroupTransparency = 0}):Play()
		else
			TweenService:Create(Item.Art.Photo.CurrentlyPlaying, normal, {GroupTransparency = 1}):Play()
		end
	end)

	if Data.ItemProperties then
		for Property, Value in Data.ItemProperties do
			if Property == "Pinned" then
				if Value then
					Item.LayoutOrder = -99999
				else
					Item.LayoutOrder = 1
				end

				Item.Art.Photo.Pinned.Visible = Value

				continue

			elseif Property == "Shared" then

				local Success, Username = pcall(function()
					return Players:GetNameFromUserIdAsync(Value.Sender)
				end)

				if not Success then continue end

				Item.Sender.Profile.Image = Utilities.GetPlayerThumbnail(Value.Sender)
				Item.Sender.Username.Text = "From @" .. Username

				continue
			end

			Item[Property] = Value
		end
	end

	--

	local SongInfo: SongInfo = {
		Artist = Data.SongInfo.Artist,
		ContextName = Data.ContextName,
		MasterPool = Data.MasterPool,
		Pointer = Data.Pointer,
		Title = Data.SongInfo.Title,
		SongId = SongId,
	}

	Item.Destroying:Connect(function()
		Connection:Disconnect()
	end)

	Item.MouseButton1Click:Connect(function()
		callback_Play(SongInfo)
	end)

	Item.MouseButton2Click:Connect(function()
		PromptSongOptions(Data.Source, SongInfo)
	end)

	Item.TouchLongPress:Connect(function()
		PromptSongOptions(Data.Source, SongInfo, true)
	end)

	if Data.Item == ui.Storage.Items["Item(Big)"] or Data.Item == ui.Storage.Items["Item(Shared)"] then

		local Hovering = false

		local function Deactivate()
			HoverBackground(false)

			Hovering = false

			Item.ZIndex = 1
			Item.Art.Photo.Hover.Glow:SetAttribute("Enabled", false)

			TweenService:Create(Item.Art.Photo.scale, smooth, {Scale = 1}):Play()

			if InputService.MouseEnabled then
				TweenService:Create(Item.Art.Photo.Hover, smooth, {GroupTransparency = 1}):Play()
			end

			TweenService:Create(Item.Art.Shadow, smooth, {ImageTransparency = .5, SliceScale = .15}):Play()
			TweenService:Create(Item.Art.Shadow.scale, smooth, {Scale = 1}):Play()

			TweenService:Create(Item.list, smooth, {Padding = UDim.new(0, 10)}):Play()
		end

		Item.MouseButton2Click:Connect(Deactivate)
		Item.TouchLongPress:Connect(Deactivate)
		Item.MouseButton1Down:Connect(Deactivate)
		Item.InputEnded:Connect(Deactivate)

		Item.MouseEnter:Connect(function()
			Hovering = true

			Item.ZIndex = 2
			Item.Art.Photo.Hover.Glow:SetAttribute("Enabled", true)

			HoverBackground(true, Utilities.GetCoverForSong(SongId))

			TweenService:Create(Item.Art.Photo.scale, normal, {Scale = 1.2}):Play()

			TweenService:Create(Item.Art.Shadow, normal, {ImageTransparency = 0, SliceScale = .2}):Play()
			TweenService:Create(Item.Art.Shadow.scale, normal, {Scale = 1.4}):Play()

			TweenService:Create(Item.list, normal, {Padding = UDim.new(0, 20)}):Play()

			if InputService.MouseEnabled then
				TweenService:Create(Item.Art.Photo.Hover, normal, {GroupTransparency = 0}):Play()
			end
		end)

		Item.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and Hovering then

				local MouseLocation = InputService:GetMouseLocation()
				local RelativePosition = MouseLocation - Item.Art.Photo.Hover.AbsolutePosition

				TweenService:Create(Item.Art.Photo.Hover.Glow, normal, {
					Position = UDim2.fromOffset(RelativePosition.X, RelativePosition.Y)}):Play()
			end
		end)

	elseif Data.Item == ui.Storage.Items["Item(Small)"] or Data.Item == ui.Storage.Items["Item(Vertical)"] or
		Data.Item == ui.Storage.Items["Item(SearchResults)"] or Data.Item == ui.Storage.Items["Item(Playlist)"] then

		if Data.Item == ui.Storage.Items["Item(Vertical)"] then
			local Duration = Utilities.FormatTime(Data.SongInfo.Duration or 0)

			Item.Duration.Text = Duration.Minutes .. ":" .. Duration.Seconds
		end

		local function Deactivate()
			Item.ZIndex = 1

			HoverBackground(false)

			TweenService:Create(Item, smooth, {BackgroundTransparency = 1}):Play()
			TweenService:Create(Item.stroke, smooth, {Transparency = 1}):Play()

			TweenService:Create(Item.Art.Shadow, smooth, {ImageTransparency = .5}):Play()
		end

		Item.MouseButton2Click:Connect(Deactivate)
		Item.TouchLongPress:Connect(Deactivate)
		Item.MouseButton1Down:Connect(Deactivate)
		Item.InputEnded:Connect(Deactivate)

		Item.MouseEnter:Connect(function()
			Item.ZIndex = 2

			HoverBackground(true, Utilities.GetCoverForSong(SongId))

			TweenService:Create(Item, normal, {BackgroundTransparency = .9}):Play()
			TweenService:Create(Item.stroke, normal, {Transparency = .9}):Play()

			TweenService:Create(Item.Art.Shadow, normal, {ImageTransparency = 1}):Play()
		end)
	end
end

function AddArtistItem(DataInfo: ArtistItemProperties)
	ArtistCommitted += 1
	ArtistIndex[ArtistCommitted] = DataInfo

	local Data = ArtistIndex[ArtistCommitted]

	local Item = Data.Item:Clone()
	if not Item:IsA("ImageButton") then return end

	local Initial = Utilities.GetInitials(Data.ArtistName)
	local C1, C2 = Utilities.GenerateArtistGradient(Data.ArtistName)

	Item.Name = Data.ArtistName
	Item:AddTag("MastersArtist_" .. Data.Source)

	Item.Information.ArtistName.Text = Data.ArtistName

	Item.Art.Photo.Initials.Text = Initial
	Item.Art.Photo.gradient.Color = ColorSequence.new(C1, C2)

	Item.Parent = Data.Container

	--

	if Data.ItemProperties then
		for Property, Value in Data.ItemProperties do
			if Property == "Pinned" then
				if Value then
					Item.LayoutOrder = -99999
				else
					Item.LayoutOrder = 1
				end

				Item.Art.Photo.Pinned.Visible = Value

				continue

			elseif Property == "Shared" then

				local Success, Username = pcall(function()
					return Players:GetNameFromUserIdAsync(Value.Sender)
				end)

				if not Success then continue end

				Item.Sender.Profile.Image = Utilities.GetPlayerThumbnail(Value.Sender)
				Item.Sender.Username.Text = "From @" .. Username

				continue
			end

			Item[Property] = Value
		end
	end

	--

	Item.MouseButton1Click:Connect(function()
		callback_ViewArtist(Data.ArtistName)
	end)

	Item.MouseButton2Click:Connect(function()
		PromptArtistOption(Data.Source, Data.ArtistName)
	end)

	Item.TouchLongPress:Connect(function()
		PromptArtistOption(Data.Source, Data.ArtistName, true)
	end)
end

function AddPlaylistItem(DataInfo: PlaylistItemProperties)
	PlaylistComitted += 1
	PlaylistIndex[PlaylistComitted] = DataInfo

	local Data = PlaylistIndex[PlaylistComitted]

	local Item = Data.Item:Clone()
	if not Item:IsA("ImageButton") then return end

	local Success, Username = pcall(function()
		return Players:GetNameFromUserIdAsync(Data.PlaylistData.CreatorId)
	end)
	if not Success then return end

	Item.Name = Data.PlaylistData.Name
	Item:AddTag("MastersPlaylist_" .. Data.PlaylistData.PlaylistId)

	Item.Information.Title.Text = Data.PlaylistData.Name
	Item.Information.Source.Text = Username

	if Data.PlaylistData.Cover == "" then
		if #Data.PlaylistData.Songs == 0 then
			Item.Art.Photo.Image = "rbxassetid://74118540785733"
			Item.Art.Photo.Default.Visible = false

		elseif #Data.PlaylistData.Songs == 1 then
			Item.Art.Photo.Image = ""

			Item.Art.Photo.Default.Visible = true
			Item.Art.Photo.Default.grid.CellSize = UDim2.fromScale(1, 1)

			Item.Art.Photo.Default.CoverA.Image = Utilities.GetCoverForSong(Data.PlaylistData.Songs[1])

		elseif #Data.PlaylistData.Songs == 2 then
			Item.Art.Photo.Image = ""

			Item.Art.Photo.Default.Visible = true
			Item.Art.Photo.Default.grid.CellSize = UDim2.fromScale(.5, 1)

			Item.Art.Photo.Default.CoverA.Image = Utilities.GetCoverForSong(Data.PlaylistData.Songs[1])
			Item.Art.Photo.Default.CoverB.Image = Utilities.GetCoverForSong(Data.PlaylistData.Songs[2])

		elseif #Data.PlaylistData.Songs == 3 then
			Item.Art.Photo.Image = ""

			Item.Art.Photo.Default.Visible = true
			Item.Art.Photo.Default.grid.CellSize = UDim2.fromScale(1, .34)

			Item.Art.Photo.Default.CoverA.Image = Utilities.GetCoverForSong(Data.PlaylistData.Songs[1])
			Item.Art.Photo.Default.CoverB.Image = Utilities.GetCoverForSong(Data.PlaylistData.Songs[2])
			Item.Art.Photo.Default.CoverC.Image = Utilities.GetCoverForSong(Data.PlaylistData.Songs[3])

		elseif #Data.PlaylistData.Songs > 3 then
			Item.Art.Photo.Image = ""

			Item.Art.Photo.Default.Visible = true
			Item.Art.Photo.Default.grid.CellSize = UDim2.fromScale(.5, .5)

			Item.Art.Photo.Default.CoverA.Image = Utilities.GetCoverForSong(Data.PlaylistData.Songs[1])
			Item.Art.Photo.Default.CoverB.Image = Utilities.GetCoverForSong(Data.PlaylistData.Songs[2])
			Item.Art.Photo.Default.CoverC.Image = Utilities.GetCoverForSong(Data.PlaylistData.Songs[3])
			Item.Art.Photo.Default.CoverD.Image = Utilities.GetCoverForSong(Data.PlaylistData.Songs[4])
		end
	else
		Item.Art.Photo.Image = Data.PlaylistData.Cover
	end

	Item.Parent = Data.Container

	--

	if Data.ItemProperties then
		for Property, Value in Data.ItemProperties do
			if Property == "Pinned" then
				if Value then
					Item.LayoutOrder = -99999
				else
					Item.LayoutOrder = 1
				end

				Item.Art.Photo.Pinned.Visible = Value

				continue

			elseif Property == "Shared" then

				local Success, Username = pcall(function()
					return Players:GetNameFromUserIdAsync(Value.Sender)
				end)

				if not Success then continue end

				Item.Sender.Profile.Image = Utilities.GetPlayerThumbnail(Value.Sender)
				Item.Sender.Username.Text = "From @" .. Username

				continue
			end

			Item[Property] = Value
		end
	end

	--

	Item.MouseButton1Click:Connect(function()
		callback_ViewPlaylist(Data.PlaylistData.CreatorId, Data.PlaylistData.PlaylistId)
	end)

	Item.MouseButton2Click:Connect(function()
		PromptPlaylistOption(Data.Source, DataInfo.PlaylistData)
	end)

	Item.TouchLongPress:Connect(function()
		PromptPlaylistOption(Data.Source, DataInfo.PlaylistData, true)
	end)

	--

	if Data.Item == ui.Storage.Items["Playlist(Big)"] or Data.Item == ui.Storage.Items["Playlist(Shared)"] then
		local Hovering = false

		local function Deactivate()
			Hovering = false

			Item.ZIndex = 1
			Item.Art.Photo.Hover.Glow:SetAttribute("Enabled", false)

			TweenService:Create(Item.Art.Photo.scale, smooth, {Scale = 1}):Play()

			if InputService.MouseEnabled then
				TweenService:Create(Item.Art.Photo.Hover, smooth, {GroupTransparency = 1}):Play()
			end

			TweenService:Create(Item.Art.Shadow, smooth, {ImageTransparency = .5, SliceScale = .15}):Play()
			TweenService:Create(Item.Art.Shadow.scale, smooth, {Scale = 1}):Play()

			TweenService:Create(Item.list, smooth, {Padding = UDim.new(0, 10)}):Play()
		end

		Item.MouseButton2Click:Connect(Deactivate)
		Item.TouchLongPress:Connect(Deactivate)
		Item.MouseButton1Down:Connect(Deactivate)
		Item.InputEnded:Connect(Deactivate)

		Item.MouseEnter:Connect(function()
			Hovering = true

			Item.ZIndex = 2
			Item.Art.Photo.Hover.Glow:SetAttribute("Enabled", true)

			TweenService:Create(Item.Art.Photo.scale, normal, {Scale = 1.2}):Play()

			TweenService:Create(Item.Art.Shadow, normal, {ImageTransparency = 0, SliceScale = .2}):Play()
			TweenService:Create(Item.Art.Shadow.scale, normal, {Scale = 1.4}):Play()

			TweenService:Create(Item.list, normal, {Padding = UDim.new(0, 20)}):Play()

			if InputService.MouseEnabled then
				TweenService:Create(Item.Art.Photo.Hover, normal, {GroupTransparency = 0}):Play()
			end
		end)

		Item.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 and Hovering then

				local MouseLocation = InputService:GetMouseLocation()
				local RelativePosition = MouseLocation - Item.Art.Photo.Hover.AbsolutePosition

				TweenService:Create(Item.Art.Photo.Hover.Glow, normal, {
					Position = UDim2.fromOffset(RelativePosition.X, RelativePosition.Y)}):Play()
			end
		end)
	end
end

function AddStationItem(DataInfo: StationItemProperties)
	StationComitted += 1
	StationIndex[StationComitted] = DataInfo

	local Data = StationIndex[StationComitted]

	local Item = Data.Item:Clone()
	if not Item:IsA("ImageButton") then return end

	Item.Name = Data.StationData.Name
	Item:AddTag("MastersStations_" .. Data.StationData.StationId)

	Item.Content.Title.Text = Data.StationData.Name
	Item.Content.Description.Text = Data.StationData.Description

	if Data.StationData.Cover == "" then
		Item.Util.Visuals.Art.Image = "rbxassetid://74118540785733"
		Item.Util.Visuals.Fade.Image = "rbxassetid://74118540785733"
	else
		Item.Util.Visuals.Art.Image = Data.StationData.Cover
		Item.Util.Visuals.Fade.Image = Data.StationData.Cover
	end

	Item.Parent = Data.Container

	--

	if Data.ItemProperties then
		for Property, Value in Data.ItemProperties do
			Item[Property] = Value
		end
	end

	--

	Item.MouseButton1Click:Connect(function()
		callback_ViewStation(Data.Online, Data.StationData.StationId)
	end)

	Item.MouseButton2Click:Connect(function()
		PromptStationOption(Data.Source, Data.StationData, Data.Online)
	end)

	Item.TouchLongPress:Connect(function()
		PromptStationOption(Data.Source, Data.StationData, Data.Online, true)
	end)
end

-- Full / Discovery

function LoadAllAudios()

	ui.Interface.Interactable = false
	Full.Content.Loading.Visible = true

	-- Clearance

	for i, residual in Full.Container.Discovery:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	-- Curation
	-- Curation / Datas

	local Algorithm = events.Main.Algorithm.FetchAlgorithm:InvokeServer()
	local Preferences = events.Main.Preferences.FetchPreference:InvokeServer()
	local Library = events.Main.Library.FetchLibrary:InvokeServer()

	if not Algorithm or not Preferences or not Library then return end

	local Curations = {
		KeepPlaying = {},
		ForYou = {},
		Explore = {},
		Genres = {},
		CustomSections = {},
		LocalStations = {},
		OnlineStations = {}
	}

	-- Curation / Functions

	local function RemoveNegatives(SongIds)
		local Cleaned = {}

		local BlockedArtists = {}
		for _, Artist in Preferences.Artists.Block do
			BlockedArtists[Artist] = true
		end

		local DislikedSongs = {}
		for _, SongId in Preferences.Songs.Dislike do
			DislikedSongs[SongId] = true
		end

		for _, Song in SongIds do

			local Filtered = false

			if typeof(Song) == "number" then
				if not DislikedSongs[Song] then
					table.insert(Cleaned, Song)
				end
			end

			if Song.Id then
				if not DislikedSongs[Song.Id] then
					if Song.Artist then
						if not BlockedArtists[Song.Artist] then
							table.insert(Cleaned, Song)
						end
					else
						table.insert(Cleaned, Song)
					end
				end
			end

			if Song.SongId then
				if not DislikedSongs[Song.SongId] then
					if Song.Artist then
						if not BlockedArtists[Song.Artist] then
							table.insert(Cleaned, Song)
						end
					else
						table.insert(Cleaned, Song)
					end
				end
			end

			if Song.AssetId then
				if not DislikedSongs[Song.AssetId] then
					if Song.Artist then
						if not BlockedArtists[Song.Artist] then
							table.insert(Cleaned, Song)
						end
					else
						table.insert(Cleaned, Song)
					end
				end
			end
		end

		return Cleaned
	end

	local function CurateKeepPlaying(SongIds)
		SongIds = RemoveNegatives(SongIds)

		local TopSongs = {}
		local TempTable = {}

		for _, Song in SongIds do
			table.insert(TempTable, {
				SongId = Song.SongId,
				Relevance = Song.Relevance or 0,
				LastUpdate = Song.LastUpdate or 0
			})
		end

		table.sort(TempTable, function(a, b)
			if a.Relevance == b.Relevance then
				return a.LastUpdate > b.LastUpdate
			else
				return a.Relevance > b.Relevance
			end
		end)

		for i = 1, math.min(30, #TempTable) do
			table.insert(TopSongs, TempTable[i])
		end

		Curations.KeepPlaying = TopSongs
	end

	local function CurateForYou(SongChunk)
		local NOW = os.time()
		local SEVEN_DAYS = 604800

		local ScoredTags = {}

		for _, TagEntry in Algorithm.Tags do
			local timePassed = NOW - (TagEntry.LastUpdate or 0)
			local decay = math.pow(.5, timePassed / SEVEN_DAYS)
			local tagScore = (TagEntry.Relevance or 0) * math.clamp(decay, 0, 1)

			table.insert(ScoredTags, {Tag = TagEntry.Tag, Score = tagScore})
		end

		table.sort(ScoredTags, function(a, b) return a.Score > b.Score end)

		local TopTags = {}

		for i = 1, math.min(5, #ScoredTags) do
			TopTags[ScoredTags[i].Tag] = true
		end

		for _, Song in SongChunk do
			local IsOwned = false

			if table.find(Preferences.Songs.Favorite or {}, Song.Id) then IsOwned = true end

			if not IsOwned and Library.Songs then
				for _, LibSong in Library.Songs do
					if LibSong.SongId == Song.Id then IsOwned = true; break end
				end
			end

			if IsOwned then continue end

			local HasTopTag = false

			if Song.Tags then
				for _, Tag in Song.Tags do
					if TopTags[Tag] then
						HasTopTag = true
						break
					end
				end
			end

			if HasTopTag then
				local ArtistBonus = 0

				if Library.Artists then
					for _, SavedArtist in Library.Artists do
						if SavedArtist.Name == Song.Artist then
							ArtistBonus = SavedArtist.Pin and 100 or 50
							break
						end
					end
				end

				Song.Relevance = (Song.Relevance or 10) + ArtistBonus

				local existingIndex = nil

				for i, Existing in Curations.ForYou do
					if Existing.Id == Song.Id then
						existingIndex = i
						break
					end
				end

				if existingIndex then
					if Song.Relevance > Curations.ForYou[existingIndex].Relevance then
						Curations.ForYou[existingIndex] = Song
					end

				elseif #Curations.ForYou < 30 then
					table.insert(Curations.ForYou, Song)
				else
					local MinIndex, MinScore = 1, Curations.ForYou[1].Relevance or 0

					for i, Elem in ipairs(Curations.ForYou) do
						if (Elem.Relevance or 0) < MinScore then
							MinScore = Elem.Relevance or 0
							MinIndex = i
						end
					end

					if Song.Relevance > MinScore then
						Curations.ForYou[MinIndex] = Song
					end
				end
			end
		end

		table.sort(Curations.ForYou, function(a, b)
			return (a.Relevance or 0) > (b.Relevance or 0)
		end)
	end

	local function IsSongKnown(SongId)
		if table.find(Preferences.Songs.Favorite, SongId) then return true end

		for _, LibSong in Library.Songs do
			if LibSong.SongId == SongId then return true end
		end

		return false
	end

	local function CurateExplore(SongChunk)
		for _, Song in SongChunk do
			if IsSongKnown(Song.Id) then continue end

			local playedRecently = false

			for _, Played in Algorithm.Songs do
				if Played.SongId == Song.Id then playedRecently = true; break end
			end

			if playedRecently then continue end

			local ArtistScore = 0

			for _, ArtistEntry in Algorithm.Artists do
				if ArtistEntry.Name == Song.Artist then
					ArtistScore = ArtistEntry.Relevance or 0
					break
				end
			end

			local TagScore = 0

			for _, Tag in Song.Tags or {} do
				for _, TagEntry in Algorithm.Tags do
					if TagEntry.Tag == Tag then
						TagScore = math.max(TagScore, TagEntry.Relevance or 0)
					end
				end
			end

			local TotalScore = ArtistScore + TagScore

			if TotalScore == 0 then TotalScore = 5 end 

			Song.Relevance = TotalScore + math.random(1, 15)

			if #Curations.Explore < 30 then
				table.insert(Curations.Explore, Song)
			else
				local MinIndex, MinScore = 1, Curations.Explore[1].Relevance or 0

				for i, Elem in ipairs(Curations.Explore) do
					if (Elem.Relevance or 0) < MinScore then
						MinScore = Elem.Relevance or 0
						MinIndex = i
					end
				end

				if Song.Relevance > MinScore then
					Curations.Explore[MinIndex] = Song
				end
			end
		end

		table.sort(Curations.Explore, function(a, b)
			return (a.Relevance or 0) > (b.Relevance or 0)
		end)
	end

	local function GetCustomSections()
		local AllCustomSections = Configuration.GetConfiguration()

		for SectionId, SectionData in AllCustomSections.CustomSections do
			Curations.CustomSections[SectionId] = SectionData
		end
	end

	local function GetLocalStations()
		local AllLocalStations = Configuration.GetLocalStations()

		for i, StationData in AllLocalStations do
			Curations.LocalStations[StationData.StationId] = StationData
		end
	end

	local function GetOnlineStations()
		local AllOnlineStations = OnlineStations.GetOnlineStations()

		for StationId, StationData in AllOnlineStations do
			Curations.OnlineStations[StationId] = StationData
		end
	end

	-- Curation / Process
	-- Curation / Process / Keep Playing

	if #Algorithm.Songs > 0 then
		local Container = ui.Storage.Items["Container(Standard)"]:Clone()		

		local List = {}
		local Metadatas

		CurateKeepPlaying(Algorithm.Songs)

		for i, Song in Curations.KeepPlaying do
			table.insert(List, Song.SongId)
		end

		if #List > 0 then
			Metadatas = AssetService:GetAudioMetadataAsync(List)
		end

		Metadatas = RemoveNegatives(Metadatas)

		if not Metadatas then return end
		Curations.KeepPlaying = Metadatas

		Container.Name = "KeepPlaying"
		Container.LayoutOrder = 1
		Container.Header.Label.Text = "Keep Playing"
		Container.Parent =  Full.Container.Discovery

		Main.PreparenessChanged:Connect(function()
			repeat task.wait(1) until Main.GetState() == "Full"

			for i, Data in Metadatas do
				AddSongItem({
					Container = Container.Content,
					ContextName = "Keep Playing",
					Item = ui.Storage.Items["Item(Big)"],
					MasterPool = List,
					Pointer = i,
					SongInfo = Data,
					Source = "Standard"
				})
			end
		end)
	end

	-- Curation / Process / For You

	if #Algorithm.Tags > 0 or #Algorithm.Artists > 0 then
		task.spawn(function()
			local Container = ui.Storage.Items["Container(Standard)"]:Clone()

			Container.Name = "ForYou"
			Container.LayoutOrder = 2
			Container.Header.Label.Text = "For You"
			Container.Parent = Full.Container.Discovery

			Audios.ChunkLoaded:Connect(function(AudioPage, AudioChunk)
				AudioChunk = RemoveNegatives(AudioChunk)
				CurateForYou(AudioChunk)
			end)

			local tags = {}

			Main.PreparenessChanged:Connect(function()
				repeat task.wait(1) until Audios.IsLoaded() and Main.GetState() == "Full"

				local CurationCollection = {}

				for i, Data in Curations.ForYou do
					local ItemLoaded = Container.Content:FindFirstChild(Data.Id)

					table.insert(CurationCollection, Data.Id)

					if ItemLoaded then
						ItemLoaded:Destroy()
					end

					table.insert(tags, Data.Tags[1])

					AddSongItem({
						Container = Container.Content,
						ContextName = "For You",
						Item = ui.Storage.Items["Item(Big)"],
						MasterPool = CurationCollection,
						Pointer = i,
						SongInfo = Data,
						Source = "Standard"
					})
				end
			end)
		end)
	end

	-- Curation / Process / Explore

	task.spawn(function()
		local Container = ui.Storage.Items["Container(Standard)"]:Clone()

		Container.Name = "Explore"
		Container.LayoutOrder = 3
		Container.Header.Label.Text = "Explore"
		Container.Parent = Full.Container.Discovery

		Audios.ChunkLoaded:Connect(function(AudioPage, AudioChunk)
			AudioChunk = RemoveNegatives(AudioChunk)
			CurateExplore(AudioChunk)
		end)

		Main.PreparenessChanged:Connect(function()
			repeat task.wait(1) until Audios.IsLoaded() and Main.GetState() == "Full"

			local CurationCollection = {}

			for i, Data in Curations.Explore do
				local ItemLoaded = Container.Content:FindFirstChild(Data.Id)

				table.insert(CurationCollection, Data.Id)

				if ItemLoaded then
					ItemLoaded:Destroy()
				end

				AddSongItem({
					Container = Container.Content,
					ContextName = "Explore",
					Item = ui.Storage.Items["Item(Big)"],
					MasterPool = CurationCollection,
					Pointer = i,
					SongInfo = Data,
					Source = "Standard"
				})
			end
		end)
	end)

	-- Curation / Process / Custom Sections

	task.spawn(function()
		if not Configuration.GetConfiguration().CustomSections then return end

		GetCustomSections()

		for SectionId, SectionData in Curations.CustomSections do
			local Metadata = Audios.GetAudioMetadataAsync(SectionData.Songs)
			if not Metadata then continue end

			local Container = ui.Storage.Items["Container(Standard)"]:Clone()

			Container.Name = SectionId
			Container.LayoutOrder = 6
			Container.Header.Label.Text = SectionData.Name
			Container.Parent =  Full.Container.Discovery

			for i, SongId in SectionData.Songs do
				AddSongItem({
					Container = Container.Content,
					ContextName = SectionData.Name,
					Item = ui.Storage.Items["Item(Big)"],
					MasterPool = SectionData.Songs,
					Pointer = i,
					SongInfo = Metadata[i],
					Source = "Standard"
				})
			end
		end
	end)

	-- Curation / Process / Stations

	task.spawn(function()
		GetLocalStations()

		if #Configuration.GetLocalStations() > 0 then
			local Container = ui.Storage.Items["Container(Stations)"]:Clone()

			Container.Name = "LocalStations"
			Container.LayoutOrder = 999
			Container.Header.Label.Text = "Local Stations"
			Container.Parent =  Full.Container.Discovery

			for StationId, StationData in Curations.LocalStations do
				AddStationItem({
					Container = Container.Content,
					Item = ui.Storage.Items["Station(Big)"],
					StationData = StationData,
					Source = "Standard",
					Online = false
				})
			end
		end
	end)

	task.spawn(function()
		if not Configuration.GetConfiguration().Stations.OnlineStations then return end

		local Container = ui.Storage.Items["Container(Stations)"]:Clone()

		Container.Name = "OnlineStations"
		Container.LayoutOrder = 1000
		Container.Header.Label.Text = "Online Stations"
		Container.Parent =  Full.Container.Discovery

		GetOnlineStations()

		for StationId, StationData in Curations.OnlineStations do
			AddStationItem({
				Container = Container.Content,
				Item = ui.Storage.Items["Station(Big)"],
				StationData = StationData,
				Source = "Standard",
				Online = true
			})
		end
	end)

	-- Curation / Process / Tags

	task.spawn(function()
		local List = {}

		Audios.ChunkLoaded:Connect(function(AudioPage, AudioChunk)
			for i, Song in AudioChunk do
				if not Song then continue end
				if not Song.Tags then continue end
				if not Song.Tags[1] then continue end

				local Tag = string.gsub(Utilities.CapitalizeWords(Song.Tags[1]), "-", " ")

				if not List[Tag] then
					List[Tag] = {}
					Curations.Genres[Tag] = {}
				end

				table.insert(List[Tag], Song.Id)
				table.insert(Curations.Genres[Tag], Song)
			end
		end)

		Main.PreparenessChanged:Connect(function()
			repeat task.wait(1) until Audios.IsLoaded() and Main.GetState() == "Full"

			for Tag, SongCollection in List do
				for i, SongId in SongCollection do
					local Song = Curations.Genres[Tag][i]
					if not Song then continue end

					local Container = Full.Container.Search.Suggestions:FindFirstChild(Tag)

					if not Container then
						Container = ui.Storage.Items["Container(Charts)"]:Clone()

						Container.Name = Tag
						Container.LayoutOrder = -#SongCollection
						Container.Header.Label.Text = Tag
						Container.Parent = Full.Container.Search.Suggestions
					end

					AddSongItem({
						Container = Container.Content,
						ContextName = Tag,
						Item = ui.Storage.Items["Item(Small)"],
						MasterPool = List[Tag],
						Pointer = i,
						SongInfo = Song,
						Source = "Standard"
					})

				end
			end
		end)	
	end)

	ui.Interface.Interactable = true
	Full.Content.Loading.Visible = false
end

LoadAllAudios()

-- Full / Content

Full.Content.Actions.Close.MouseButton1Click:Connect(function()
	if ui.Interface:GetAttribute("State") == "Full" then
		Main.SetState("Bar")
	end
end)

Full.Content.Actions.Sidebar.MouseButton1Click:Connect(function()
	local SidebarOpened = Main.GetSidebarStatus()

	if SidebarOpened then
		Main.Sidebar(false)
	else
		if Utilities.GetViewportRatio() > 1300 then
			Main.Sidebar(true, false)
		else
			if Main.GetOrientation() == "Landscape" then
				Main.Sidebar(true, false)
			else
				Main.Sidebar(true, true)
			end
		end
	end
end)

ui.Layer.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if ui.Interface:GetAttribute("State") == "Full" then
			Main.SetState("Bar")
		end
	end
end)

-- Lyrics Scroll Sync

local ActiveLyrics = {}
local LyricsHeartbeatConnection
local LyricsScrollProperties = {
	Scrolling = false,
	Threshold = 0
}

NowPlaying.Content.Panel.Lyrics.Shield.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.MouseWheel then

		LyricsScrollProperties.Scrolling = true
	end
end)

NowPlaying.Content.Panel.Lyrics.Shield.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
		LyricsScrollProperties.Scrolling = false
	end
end)

--

local function LoadListeners()

	-- Residual

	for i, residual in NowPlaying.Content.Panel.Listeners.Scroll:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	-- Load

	local ListenerData = events.Modules.Listeners.GetListeners:InvokeServer()
	local CurrentSongId = Queue.GetCurrentSongId()

	for UserId, Data in ListenerData do
		UserId = tonumber(UserId)
		if not UserId then continue end

		if Data.CurrentSoundId ~= CurrentSongId then continue end
		if UserId == client.UserId then continue end

		local Player = Players:GetPlayerByUserId(UserId)
		if not Player then return end

		local Item = ui.Storage.Items.ListenerItem:Clone()

		Item.Name = Player.Name
		Item.Profile.Image = Utilities.GetPlayerThumbnail(UserId)
		Item.DisplayName.Text = Player.DisplayName
		Item.Parent = NowPlaying.Content.Panel.Listeners.Scroll

		--

		Item.MouseButton1Click:Connect(function()
			local OptionChosen = Main.PromptOptions({
				Header = Player.DisplayName,
				Options = {
					{Name = "Copy Queue", Icon = "rbxassetid://12974407511"},
					{Name = "Skip to Timestamp", Icon = "rbxassetid://11422923443"},
				}
			})

			if OptionChosen == "Copy Queue" then
				local QueueList = {}

				if #Data.Queue > 0 then
					for i, SongId in Data.Queue do
						table.insert(QueueList, SongId.Id)
					end
				end

				if #Data.ContinuePlaying > 0 then
					for i, SongId in Data.ContinuePlaying do
						table.insert(QueueList, SongId.Id)
					end
				end

				if #QueueList > 0 then
					Queue.ClearContinuePlaying()
					Queue.AddToQueue(QueueList)

					Alerts.BannerNotify({
						Header = "Successfully Copied queue",
						Description = Player.DisplayName .. "'s Queue was copied to your queue.",
						Icon = "rbxassetid://12974407511"
					})
				else
					Alerts.BannerNotify({
						Header = "Unable to Copy Queue",
						Description = Player.DisplayName .. "'s Queue is empty.",
						Icon = "rbxassetid://11419713314"
					})
				end

			elseif OptionChosen == "Skip to Timestamp" then
				local CurrentTimestamp = events.Modules.Listeners.GetCurrentTimestamp:InvokeServer(UserId, CurrentSongId, tick())
				local ActiveSoundObject = Queue.GetActiveSound()

				if not CurrentTimestamp then return end
				if not ActiveSoundObject then return end

				ActiveSoundObject.TimePosition = CurrentTimestamp
			end
		end)

		Item.MouseEnter:Connect(function()
			TweenService:Create(Item, normal, {BackgroundTransparency = .95}):Play()
		end)

		Item.InputEnded:Connect(function()
			TweenService:Create(Item, normal, {BackgroundTransparency = 1}):Play()
		end)
	end
end

NowPlaying.Content.Panel.Listeners.Header.Refresh.MouseButton1Click:Connect(function()
	LoadListeners()
end)

Queue.TrackChanged:Connect(function(SongId)
	table.clear(ActiveLyrics)

	NowPlayingProperties.CurrentLyricsLoaded = nil

	if LyricsHeartbeatConnection then
		LyricsHeartbeatConnection:Disconnect()
	end

	if SongId then
		local Data = AssetService:GetAudioMetadataAsync({SongId})
		if not Data or not Data[1] then return end

		local TimeData = Utilities.FormatTime(Data[1].Duration)

		-- Full / Miniplayer

		Full.Content.Miniplayer.Container.Media.Art.Photo.Image = Utilities.GetCoverForSong(SongId)
		Full.Content.Miniplayer.Container.Media.Art.Photo.scale.Scale = .8

		Full.Content.Miniplayer.Container.Media.Details.Source.Text = Data[1].Artist or "Unknown"
		Full.Content.Miniplayer.Container.Media.Details.Title.Text = Data[1].Title or "Untitled"

		Full.Content.Miniplayer.Container.Media.Details.Source.TextTransparency = 1
		Full.Content.Miniplayer.Container.Media.Details.Title.TextTransparency = 1

		TweenService:Create(Full.Content.Miniplayer.Container.Media.Art.Photo.scale, normal, {Scale = 1}):Play()

		TweenService:Create(Full.Content.Miniplayer.Container.Media.Details.Source, normal, {TextTransparency = .5}):Play()
		TweenService:Create(Full.Content.Miniplayer.Container.Media.Details.Title, normal, {TextTransparency = 0}):Play()

		-- Bar / Player

		Bar.NowPlaying.Art.Photo.Image = Utilities.GetCoverForSong(SongId)

		Bar.NowPlaying.Content.Details.Title.Text = Data[1].Title or "Untitled"
		Bar.NowPlaying.Content.Details.Title.TextTransparency = 1

		Bar.Tucked.Art.Photo.Image = Utilities.GetCoverForSong(SongId)

		TweenService:Create(Bar.NowPlaying.Content.Details.Title, normal, {TextTransparency = 0}):Play()

		-- NowPlaying / Player

		NowPlayingAlbumArt(Utilities.GetCoverForSong(SongId), Queue.GetCrossfadingStatus())

		NowPlaying.Content.Media.Details.SongInfo.Title.Label.Text = Data[1].Title or "Untitled"
		NowPlaying.Content.Media.Details.SongInfo.Source.Text = Data[1].Artist or "Unknown"

		NowPlaying.Content.Media.Timeline.Data.TimeLength.Text = TimeData.Minutes .. ":" .. TimeData.Seconds

		TweenService:Create(NowPlaying.Content.Panel.Lyrics.Container.Scroll, elastic, {CanvasPosition = Vector2.new(0, 0)}):Play()
		TweenService:Create(NowPlaying.Content.Media.Details.SongInfo.Title.padding, slow, {PaddingLeft = UDim.new(0, 15)}):Play()

		TweenService:Create(NowPlaying.Content.Panel.Actions.Lyrics.Preview, nan, {Size = UDim2.fromScale(.2, 1)}):Play()

		-- Bar / Visuals

		BarBackground(Utilities.GetCoverForSong(SongId))

		-- NowPlaying / Visuals

		NowPlayingBackground(Utilities.GetCoverForSong(SongId))

		-- NowPlaying / Lyrics

		local SoundObject = Queue.GetActiveSound()
		local HasLyrics = LyricsEngine.HasLyrics(SongId)

		for i, residual in NowPlaying.Content.Panel.Lyrics.Container.Scroll:GetChildren() do
			if residual:HasTag("MastersTemplate") then
				residual:Destroy()
			end
		end

		if HasLyrics then
			NowPlaying.Content.Panel.Lyrics.NoLyrics.Visible = false
			NowPlaying.Content.Panel.Actions.Lyrics.Icon.ImageTransparency = 0
		else
			NowPlaying.Content.Panel.Lyrics.NoLyrics.Visible = true
			NowPlaying.Content.Panel.Actions.Lyrics.Icon.ImageTransparency = .8
		end

		if SoundObject and HasLyrics then
			NowPlaying.Content.Panel.Lyrics.Loading.Visible = true

			local LyricData = LyricsEngine.GetLyrics(SongId)

			NowPlayingProperties.CurrentLyricsLoaded = LyricData

			for i, LineData in LyricData.Lyrics do
				local Item

				if LineData.Line == "" then
					if (LineData.TimeEnd - LineData.TimeStart) > 5 then
						Item = ui.Storage.Items.GapItem:Clone()
					else
						continue
					end

				elseif LineData.Line == "..." then
					Item = ui.Storage.Items.GapItem:Clone()

				else
					if LyricData.Unsynced then
						Item = ui.Storage.Items.LyricsAdlibItem:Clone()

						Item.Text = LineData.Line
						Item.TextSize = 14
						Item.TextTransparency = 0

						if LineData.Id == "CERTIFICATION" then
							Item.TextTransparency = .8
							Item.TextSize = 14
							Item.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
						end
					else
						Item = ui.Storage.Items.LyricsItem:Clone()

						Item.MainLyrics.Text = LineData.Line

						if LineData.RightAligned then
							Item.MainLyrics.TextXAlignment = Enum.TextXAlignment.Right
						end

						if LineData.Id == "CERTIFICATION" then
							Item.MainLyrics.TextSize = 14
							Item.MainLyrics.FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
						end
					end
				end

				Item.Name = LineData.Id
				Item.LayoutOrder = i

				if LineData.Adlibs then
					for i, Adlib in LineData.Adlibs do
						local AdlibItem = ui.Storage.Items.LyricsAdlibItem:Clone()

						AdlibItem.Name = "Adlib"
						AdlibItem.Text = Adlib
						AdlibItem.LayoutOrder = i
						AdlibItem.Parent = Item

						if LineData.RightAligned then
							AdlibItem.TextXAlignment = Enum.TextXAlignment.Right
						end
					end
				end

				Item.Parent = NowPlaying.Content.Panel.Lyrics.Container.Scroll

				ActiveLyrics[LineData.Id] = {
					Item = Item,
					TimeStart = LineData.TimeStart,
					TimeEnd = LineData.TimeEnd
				}

				--

				if not LyricData.Unsynced then
					Item.MouseButton1Click:Connect(function()
						if TimeScrubberData.Dragging then return end
						if Queue.GetCrossfadingStatus() then return end
						if Queue.GetLoadingStatus() then return end

						SoundObject.TimePosition = LineData.TimeStart
						LyricsScrollProperties.Threshold = 0
					end)

					Item.MouseEnter:Connect(function()
						TweenService:Create(Item, normal, {BackgroundTransparency = .95}):Play()
					end)

					Item.InputEnded:Connect(function()
						TweenService:Create(Item, normal, {BackgroundTransparency = 1}):Play()
					end)
				end

			end

			NowPlaying.Content.Panel.Lyrics.Loading.Visible = false

			if not LyricData.Unsynced then
				LyricsHeartbeatConnection = RunService.Heartbeat:Connect(function(Delta)

					if not SoundObject or not SoundObject.Parent then 
						LyricsHeartbeatConnection:Disconnect()
						return 
					end

					local ActiveLine
					local Scroll = NowPlaying.Content.Panel.Lyrics.Container.Scroll
					local CurrentTime = SoundObject.TimePosition

					for Id, Data in ActiveLyrics do
						if CurrentTime >= Data.TimeStart and CurrentTime <= Data.TimeEnd then
							if Data.Item:HasTag("MastersGapItem") then
								local ProgressX = Utilities.Map(CurrentTime, Data.TimeStart, Data.TimeEnd, 0, 1)
								local ScaleSize = Utilities.Map(CurrentTime, Data.TimeStart, Data.TimeEnd, .6, 1.2)
								local GlowIntensity = Utilities.Map(CurrentTime, Data.TimeStart, Data.TimeEnd, 1, .9)

								Smoothness.ApproachInHeartbeat(Data.Item, "Size", UDim2.new(1, 0, 0, 72), Delta, slow)
								Smoothness.ApproachInHeartbeat(Data.Item.Canvas.scale, "Scale", ScaleSize, Delta, normal)

								Smoothness.ApproachInHeartbeat(Data.Item.Canvas.Fill, "Size", UDim2.fromScale(ProgressX, 1), Delta, normal)
								Smoothness.ApproachInHeartbeat(Data.Item.Canvas.Background, "ImageTransparency", .9, Delta, normal)
								Smoothness.ApproachInHeartbeat(Data.Item.Canvas.Glow, "ImageTransparency", GlowIntensity, Delta, normal)

							else
								Smoothness.ApproachInHeartbeat(Data.Item.MainLyrics, "TextTransparency", 0, Delta, smooth)
								Smoothness.ApproachInHeartbeat(Data.Item.list, "Padding", UDim.new(0, 10), Delta, normal)
							end

							for i, Adlib in Data.Item:GetChildren() do
								if Adlib.Name == "Adlib" then
									Smoothness.ApproachInHeartbeat(Adlib, "TextTransparency", .5, Delta, slow)
								end
							end

							--

							ActiveLine = Data
						else
							if Data.Item:HasTag("MastersGapItem") then
								Smoothness.ApproachInHeartbeat(Data.Item, "Size", UDim2.new(1, 0, 0, 0), Delta, slow)
								Smoothness.ApproachInHeartbeat(Data.Item.Canvas.scale, "Scale", .6, Delta, normal)

								Smoothness.ApproachInHeartbeat(Data.Item.Canvas.Fill, "Size", UDim2.fromScale(0, 1), Delta, normal)
								Smoothness.ApproachInHeartbeat(Data.Item.Canvas.Background, "ImageTransparency", 1, Delta, normal)
								Smoothness.ApproachInHeartbeat(Data.Item.Canvas.Glow, "ImageTransparency", 1, Delta, normal)

							else
								Smoothness.ApproachInHeartbeat(Data.Item.MainLyrics, "TextTransparency", .9, Delta, smooth)
								Smoothness.ApproachInHeartbeat(Data.Item.list, "Padding", UDim.new(0, -10), Delta, normal)
							end

							for i, Adlib in Data.Item:GetChildren() do
								if Adlib.Name == "Adlib" then
									Smoothness.ApproachInHeartbeat(Adlib, "TextTransparency", 1, Delta, slow)
								end
							end
						end

						if Main.GetOrientation() == "Portrait" then
							if Data.Item:HasTag("MastersGapItem") then
								Data.Item.scale.Scale = 1.6
							else
								if Data.Item.Name ~= "CERTIFICATION" then
									Data.Item.MainLyrics.TextSize = 36

									for i, Adlib in Data.Item:GetChildren() do
										if Adlib.Name == "Adlib" then
											Adlib.TextSize = 30
										end
									end
								end
							end
						else
							if Data.Item:HasTag("MastersGapItem") then
								Data.Item.scale.Scale = 1
							else
								if Data.Item.Name ~= "CERTIFICATION" then
									Data.Item.MainLyrics.TextSize = 26

									for i, Adlib in Data.Item:GetChildren() do
										if Adlib.Name == "Adlib" then
											Adlib.TextSize = 20
										end
									end									
								end

							end
						end
					end

					if ActiveLine then
						if LyricsScrollProperties.Scrolling then
							LyricsScrollProperties.Threshold = 240
						else
							LyricsScrollProperties.Threshold -= 1

							if LyricsScrollProperties.Threshold < 1 then
								local TargetY = ActiveLine.Item.AbsolutePosition.Y - Scroll.AbsolutePosition.Y + Scroll.CanvasPosition.Y - NowPlayingProperties.LyricsTopOffset

								TargetY = math.clamp(
									TargetY,
									0,
									Scroll.AbsoluteCanvasSize.Y - Scroll.AbsoluteWindowSize.Y
								)

								Smoothness.ApproachInHeartbeat(Scroll, "CanvasPosition", Vector2.new(0, TargetY), Delta, 
									TweenInfo.new(2, Enum.EasingStyle.Exponential))
							end
						end

						local OffsetXGlow = Utilities.Map(CurrentTime, ActiveLine.TimeStart, ActiveLine.TimeEnd, .2, 1.2)

						Smoothness.ApproachInHeartbeat(NowPlaying.Content.Panel.Actions.Lyrics.Preview, 
							"Size",UDim2.fromScale(OffsetXGlow, 1), Delta, normal)

					else
						Smoothness.ApproachInHeartbeat(NowPlaying.Content.Panel.Actions.Lyrics.Preview, 
							"Size",UDim2.fromScale(.2, 1), Delta, normal)
					end
				end)
			end
		end

		-- Listeners

		events.Modules.Listeners.UpdateListener:FireServer({
			CurrentSoundId = SongId,
			Queue = Queue.GetVisualQueue().Queue,
			ContinuePlaying = Queue.GetVisualQueue().ContinuePlaying
		})

	else

		-- Bar / Visuals

		BarBackground("")

		-- NowPlaying / Visuals

		NowPlayingBackground("")

		-- Listeners

		events.Modules.Listeners.UpdateListener:FireServer({
			CurrentSoundId = 0,
			Queue = Queue.GetVisualQueue().Queue,
			ContinuePlaying = Queue.GetVisualQueue().ContinuePlaying
		})
	end

	-- Listeners

	if SettingsPageProperties.Data.Socials.ListeningVisibility then
		NowPlaying.Content.Panel.Listeners.Scroll.Visible = true
		NowPlaying.Content.Panel.Listeners.Disabled.Visible = false
		NowPlaying.Content.Panel.Listeners.Header.Refresh.Visible = true

		LoadListeners()

	else
		for i, residual in NowPlaying.Content.Panel.Listeners.Scroll:GetChildren() do
			if residual:HasTag("MastersTemplate") then
				residual:Destroy()
			end
		end

		NowPlaying.Content.Panel.Listeners.Scroll.Visible = false
		NowPlaying.Content.Panel.Listeners.Disabled.Visible = true
		NowPlaying.Content.Panel.Listeners.Header.Refresh.Visible = false
	end
end)

RunService.Heartbeat:Connect(function(Delta)
	local CurrentSound = Queue.GetActiveSound()
	local VisualQueue = Queue.GetVisualQueue()
	local SongsInQueue = (#VisualQueue.Queue + #VisualQueue.ContinuePlaying)

	if CurrentSound and CurrentSound.IsPlaying then
		local Loudness = CurrentSound.PlaybackLoudness
		local Scale = Utilities.Map(Loudness, 0, 1000, 1, 5)
		local Transparency = Utilities.Map(Loudness, 0, 500, 1, .7)
		local Saturation = Utilities.Map(Loudness, 0, 1000, .3, 1)

		-- NowPlaying / Media

		Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Art.Photo.scale, "Scale", 1, Delta, smooth)
		Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Art.Shadow.scale, "Scale", 1, Delta, smooth)

		if SettingsPageProperties.Data.Extras.Glow then

			-- Bar / Visuals / Glow

			Smoothness.ApproachInHeartbeat(Bar.Util.Visual.Saturation, "GroupColor3", Color3.fromHSV(0, 0, Saturation), Delta, five)
			Smoothness.ApproachInHeartbeat(Bar.Util.Visual.Noise, "ImageTransparency", Transparency, Delta, slow)
			Smoothness.ApproachInHeartbeat(Bar.Util.Visual.Noise.scale, "Scale", Scale, Delta, slow)

			-- NowPlaying / Visuals / Glow

			Smoothness.ApproachInHeartbeat(NowPlaying.Util.Visual.Saturation, "GroupColor3", Color3.fromHSV(0, 0, Saturation), Delta, five)
			Smoothness.ApproachInHeartbeat(NowPlaying.Util.Visual.Noise, "ImageTransparency", Transparency, Delta, slow)
			Smoothness.ApproachInHeartbeat(NowPlaying.Util.Visual.Noise.scale, "Scale", Scale, Delta, slow)
		else

			-- Bar / Visuals / Glow

			Smoothness.ApproachInHeartbeat(Bar.Util.Visual.Saturation, "GroupColor3", Color3.fromHSV(0, 0, .5), Delta, five)
			Smoothness.ApproachInHeartbeat(Bar.Util.Visual.Noise, "ImageTransparency", 1, Delta, slow)
			Smoothness.ApproachInHeartbeat(Bar.Util.Visual.Noise.scale, "Scale", 1, Delta, slow)

			-- NowPlaying / Visuals / Glow

			Smoothness.ApproachInHeartbeat(NowPlaying.Util.Visual.Saturation, "GroupColor3", Color3.fromHSV(0, 0, .5), Delta, five)
			Smoothness.ApproachInHeartbeat(NowPlaying.Util.Visual.Noise, "ImageTransparency", 1, Delta, slow)
			Smoothness.ApproachInHeartbeat(NowPlaying.Util.Visual.Noise.scale, "Scale", 1, Delta, slow)
		end

		if SettingsPageProperties.Data.Extras.PlaybackHaptics then
			Utilities.Haptic(Utilities.Map(Loudness, 100, 1000, 0, 5) * Playback.Volume, .005)
		end

		local BaseSpeed = .05 
		local MusicInfluence = Utilities.Map(Loudness, 0, 1000, 0, .001)
		local FinalSpeed = BaseSpeed + MusicInfluence
		local MovementInfo = TweenInfo.new(5, Enum.EasingStyle.Linear)

		local VisualA = NowPlaying.Util.Visual.Saturation.Visual_A
		local VisualB = NowPlaying.Util.Visual.Saturation.Visual_B

		Smoothness.ApproachInHeartbeat(VisualA, "Position", NowPlayingProperties.TargetPosition, Delta * FinalSpeed, MovementInfo)
		Smoothness.ApproachInHeartbeat(VisualA, "AnchorPoint", NowPlayingProperties.TargetAnchor, Delta * FinalSpeed, MovementInfo)

		VisualB.Position = VisualA.Position
		VisualB.AnchorPoint = VisualA.AnchorPoint

		Bar.Util.Visual.Saturation.Visual_A.Position = VisualA.Position		
		Bar.Util.Visual.Saturation.Visual_A.AnchorPoint = VisualA.AnchorPoint

		Bar.Util.Visual.Saturation.Visual_B.Position = VisualA.Position		
		Bar.Util.Visual.Saturation.Visual_B.AnchorPoint = VisualA.AnchorPoint

		local DistX = math.abs(VisualA.Position.X.Scale - NowPlayingProperties.TargetPosition.X.Scale)
		local DistY = math.abs(VisualA.Position.Y.Scale - NowPlayingProperties.TargetPosition.Y.Scale)

		if DistX < .05 and DistY < .05 then
			NowPlayingProperties.CurrentIndex += 1

			if NowPlayingProperties.CurrentIndex > #NowPlayingProperties.Sequence then
				NowPlayingProperties.CurrentIndex = 1
			end

			local NextState = NowPlayingProperties.Sequence[NowPlayingProperties.CurrentIndex]
			local NewSpot = GetSpotByName(NextState)

			NowPlayingProperties.TargetPosition = NewSpot.Position
			NowPlayingProperties.TargetAnchor = NewSpot.AnchorPoint
		end

		-- NowPlaying / Timeline

		if not TimeScrubberData.Dragging then
			local TimePosition = Utilities.Map(CurrentSound.TimePosition, 0, CurrentSound.TimeLength, 0, 1)
			local TimeData = Utilities.FormatTime(CurrentSound.TimePosition)

			NowPlaying.Content.Media.Timeline.Data.TimePosition.Text = TimeData.Minutes .. ":" .. TimeData.Seconds

			Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Timeline.Scrubber.Fill, "Size", 
				UDim2.fromScale(TimePosition, 1), Delta, quick)
		else
			local TimePosition = Utilities.Map(NowPlaying.Content.Media.Timeline.Scrubber.Fill.Size.X.Scale, 0, 1, 
				0, CurrentSound.TimeLength)
			local TimeData = Utilities.FormatTime(TimePosition)

			NowPlaying.Content.Media.Timeline.Data.TimePosition.Text = TimeData.Minutes .. ":" .. TimeData.Seconds
		end
	else

		-- Bar / Visuals / Glow

		Smoothness.ApproachInHeartbeat(Bar.Util.Visual.Noise, "ImageTransparency", 1, Delta, five)
		Smoothness.ApproachInHeartbeat(Bar.Util.Visual.Noise.scale, "Scale", 1, Delta, five)

		-- NowPlaying / Visuals / Glow

		Smoothness.ApproachInHeartbeat(NowPlaying.Util.Visual.Saturation, "GroupColor3", Color3.fromRGB(30, 30, 30), Delta, five)
		Smoothness.ApproachInHeartbeat(NowPlaying.Util.Visual.Noise, "ImageTransparency", 1, Delta, five)
		Smoothness.ApproachInHeartbeat(NowPlaying.Util.Visual.Noise.scale, "Scale", 1, Delta, slow)

		-- NowPlaying / Media

		Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Art.Photo.scale, "Scale", .8, Delta, smooth)
		Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Art.Shadow.scale, "Scale", .8, Delta, smooth)
	end

	if Queue.GetActiveSound() then
		Smoothness.ApproachInHeartbeat(Full.Content.Miniplayer, "AnchorPoint", Vector2.new(1, 1), Delta, slow)
	else
		Smoothness.ApproachInHeartbeat(Full.Content.Miniplayer, "AnchorPoint", Vector2.new(1, 0), Delta, slow)
	end

	if Queue.GetLoadingStatus() then		
		Smoothness.ApproachInHeartbeat(Full.Content.Miniplayer.Container.Playback.PlayPause.Icon.ThrobberIcon, "ImageTransparency", 0, Delta, normal)
		Smoothness.ApproachInHeartbeat(Full.Content.Miniplayer.Container.Playback.PlayPause.Icon.PlayIcon, "ImageTransparency", 1, Delta, normal)
		Smoothness.ApproachInHeartbeat(Full.Content.Miniplayer.Container.Playback.PlayPause.Icon.PauseIcon, "ImageTransparency", 1, Delta, normal)

		Smoothness.ApproachInHeartbeat(Bar.NowPlaying.Content.Controls.PlayPause.Icon.ThrobberIcon, "ImageTransparency", 0, Delta, normal)
		Smoothness.ApproachInHeartbeat(Bar.NowPlaying.Content.Controls.PlayPause.Icon.PlayIcon, "ImageTransparency", 1, Delta, normal)
		Smoothness.ApproachInHeartbeat(Bar.NowPlaying.Content.Controls.PlayPause.Icon.PauseIcon, "ImageTransparency", 1, Delta, normal)

		Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Playback.PlayPause.Icon.ThrobberIcon, "ImageTransparency", 0, Delta, normal)
		Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Playback.PlayPause.Icon.PlayIcon, "ImageTransparency", 1, Delta, normal)
		Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Playback.PlayPause.Icon.PauseIcon, "ImageTransparency", 1, Delta, normal)
	else
		Smoothness.ApproachInHeartbeat(Full.Content.Miniplayer.Container.Playback.PlayPause.Icon.ThrobberIcon, "ImageTransparency", 1, Delta, normal)
		Smoothness.ApproachInHeartbeat(Bar.NowPlaying.Content.Controls.PlayPause.Icon.ThrobberIcon, "ImageTransparency", 1, Delta, normal)
		Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Playback.PlayPause.Icon.ThrobberIcon, "ImageTransparency", 1, Delta, normal)

		if CurrentSound then
			if CurrentSound.IsPlaying then
				Smoothness.ApproachInHeartbeat(Full.Content.Miniplayer.Container.Playback.PlayPause.Icon.PauseIcon, "ImageTransparency", 0, Delta, normal)
				Smoothness.ApproachInHeartbeat(Full.Content.Miniplayer.Container.Playback.PlayPause.Icon.PlayIcon, "ImageTransparency", 1, Delta, normal)

				Smoothness.ApproachInHeartbeat(Bar.NowPlaying.Content.Controls.PlayPause.Icon.PauseIcon, "ImageTransparency", 0, Delta, normal)
				Smoothness.ApproachInHeartbeat(Bar.NowPlaying.Content.Controls.PlayPause.Icon.PlayIcon, "ImageTransparency", 1, Delta, normal)

				Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Playback.PlayPause.Icon.PauseIcon, "ImageTransparency", 0, Delta, normal)
				Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Playback.PlayPause.Icon.PlayIcon, "ImageTransparency", 1, Delta, normal)

			else

				Smoothness.ApproachInHeartbeat(Full.Content.Miniplayer.Container.Playback.PlayPause.Icon.PauseIcon, "ImageTransparency", 1, Delta, normal)
				Smoothness.ApproachInHeartbeat(Full.Content.Miniplayer.Container.Playback.PlayPause.Icon.PlayIcon, "ImageTransparency", 0, Delta, normal)

				Smoothness.ApproachInHeartbeat(Bar.NowPlaying.Content.Controls.PlayPause.Icon.PauseIcon, "ImageTransparency", 1, Delta, normal)
				Smoothness.ApproachInHeartbeat(Bar.NowPlaying.Content.Controls.PlayPause.Icon.PlayIcon, "ImageTransparency", 0, Delta, normal)

				Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Playback.PlayPause.Icon.PauseIcon, "ImageTransparency", 1, Delta, normal)
				Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Playback.PlayPause.Icon.PlayIcon, "ImageTransparency", 0, Delta, normal)
			end
		else
			Smoothness.ApproachInHeartbeat(Full.Content.Miniplayer.Container.Playback.PlayPause.Icon.PauseIcon, "ImageTransparency", 1, Delta, normal)
			Smoothness.ApproachInHeartbeat(Full.Content.Miniplayer.Container.Playback.PlayPause.Icon.PlayIcon, "ImageTransparency", 0, Delta, normal)

			Smoothness.ApproachInHeartbeat(Bar.NowPlaying.Content.Controls.PlayPause.Icon.PauseIcon, "ImageTransparency", 1, Delta, normal)
			Smoothness.ApproachInHeartbeat(Bar.NowPlaying.Content.Controls.PlayPause.Icon.PlayIcon, "ImageTransparency", 0, Delta, normal)

			Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Playback.PlayPause.Icon.PauseIcon, "ImageTransparency", 1, Delta, normal)
			Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Playback.PlayPause.Icon.PlayIcon, "ImageTransparency", 0, Delta, normal)
		end
	end

	if Queue.GetCrossfadingStatus() then
		Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Timeline.Data.MusicStatus.Masters, "ImageTransparency", 1, Delta, slow)
		Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Timeline.Data.MusicStatus.Crossfading, "ImageTransparency", .5, Delta, slow)
	else
		Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Timeline.Data.MusicStatus.Masters, "ImageTransparency", .5, Delta, slow)
		Smoothness.ApproachInHeartbeat(NowPlaying.Content.Media.Timeline.Data.MusicStatus.Crossfading, "ImageTransparency", 1, Delta, slow)
	end

	NowPlaying.Content.Media.Timeline.Scrubber.Interactable = not (Queue.GetLoadingStatus() or Queue.GetCrossfadingStatus())

	-- Glow Effect

	if InputService.MouseEnabled then
		local MouseLocation = InputService:GetMouseLocation()

		for i, Glow in CollectionService:GetTagged("MastersGlowHoverEffect") do
			if Glow:GetAttribute("Enabled") then
				local RelativePosition = MouseLocation - Glow.Parent.AbsolutePosition
				local Offset = GuiService.TopbarInset

				Smoothness.ApproachInHeartbeat(Glow, "Position", UDim2.fromOffset(RelativePosition.X, RelativePosition.Y - Offset.Height), Delta, normal)
			end
		end
	end
end)

Full.Content.Sidebar.Tabs.Pages.Discovery.MouseButton1Click:Connect(function()
	Main.SetPage("Discovery")

	local SidebarOpened, Fullscreen = Main.GetSidebarStatus()

	if Fullscreen then
		Main.Sidebar(false)
	end
end)

Full.Content.Sidebar.Tabs.Pages.Search.MouseButton1Click:Connect(function()
	Main.SetPage("Search")

	local SidebarOpened, Fullscreen = Main.GetSidebarStatus()

	if Fullscreen then
		Main.Sidebar(false)
	end
end)

Full.Content.Sidebar.Tabs.Pages.Library.MouseButton1Click:Connect(function()
	Main.SetPage("Library")

	local SidebarOpened, Fullscreen = Main.GetSidebarStatus()

	if Fullscreen then
		Main.Sidebar(false)
	end
end)

-- Full / Visuals

TweenService:Create(Full.Util.ArtistBackground.Background.gradient, long_loop_reverses, {Offset = Vector2.new(0, 1)}):Play()
TweenService:Create(Full.Util.ArtistBackground.Visual, long_loop, {Rotation = 360}):Play()

-- Bar / Visuals

TweenService:Create(Bar.Util.Visual.Noise, long_loop, {Rotation = 360}):Play()

-- NowPlaying / Visuals

TweenService:Create(NowPlaying.Content.Media.Timeline.Data.MusicStatus.Crossfading.gradient, crossfading_loop, {Offset = Vector2.new(1, 0)}):Play()

TweenService:Create(NowPlaying.Util.Visual.Noise, long_loop, {Rotation = 360}):Play()

-- Full / Miniplayer

Full.Content.Miniplayer.Container.Playback.PlayPause.MouseButton1Click:Connect(function()
	events.Playback.PlayPause:Fire()
end)

Full.Content.Miniplayer.Container.Playback.Forward.MouseButton1Click:Connect(function()
	events.Playback.Forward:Fire()
end)

Full.Content.Miniplayer.Container.Playback.Rewind.MouseButton1Click:Connect(function()
	events.Playback.Rewind:Fire()
end)

Full.Content.Miniplayer.MouseButton1Click:Connect(function()
	Main.NowPlaying(true)
end)

Full.Content.Miniplayer.TouchSwipe:Connect(function(Direction)
	if Direction == Enum.SwipeDirection.Up then
		Main.NowPlaying(true)
	end
end)

Main.StateChanged:Connect(function(MastersState)	
	if MastersState ~= "Artist" then

		-- Residual

		for i, residual in Full.Container.Artist.Sections.Discography.Content:GetChildren() do
			if residual:HasTag("MastersTemplate") then
				residual:Destroy()
			end
		end

		for i, residual in Full.Container.Artist.Sections.YWF.Content:GetChildren() do
			if residual:HasTag("MastersTemplate") then
				residual:Destroy()
			end
		end

		ArtistPageProperties.Discography = {}

		Main.SetPage(Main.GetLastMainPage())
	end
end)

-- Full / Miniplayer / More
-- NowPlaying / More

Full.Content.Miniplayer.Container.Actions.Queue.MouseButton1Click:Connect(function()
	Main.NowPlaying(true)
	Main.NowPlayingPanelScreen("QueueList")
end)

Full.Content.Miniplayer.Container.Actions.More.MouseButton1Click:Connect(function()
	local SongId = Queue.GetCurrentSongId()
	local Metadata = Queue.GetCurrentMetadata()
	if not SongId or not Metadata then return end

	PromptSongOptions("NowPlaying", {
		MasterPool = {SongId},
		SongId = SongId,
		Title = Metadata.Title,
		Artist = Metadata.Artist,
		Pointer = 1
	})
end)

Full.Content.Miniplayer.Container.Actions.More.TouchLongPress:Connect(function()
	local SongId = Queue.GetCurrentSongId()
	local Metadata = Queue.GetCurrentMetadata()
	if not SongId or not Metadata then return end

	PromptSongOptions("NowPlaying", {
		MasterPool = {SongId},
		SongId = SongId,
		Title = Metadata.Title,
		Artist = Metadata.Artist,
		Pointer = 1
	}, true)
end)

NowPlaying.Content.Panel.Actions.More.MouseButton1Click:Connect(function()
	local SongId = Queue.GetCurrentSongId()
	local Metadata = Queue.GetCurrentMetadata()
	if not SongId or not Metadata then return end

	PromptSongOptions("NowPlaying", {
		MasterPool = {SongId},
		SongId = SongId,
		Title = Metadata.Title,
		Artist = Metadata.Artist,
		Pointer = 1
	})
end)

NowPlaying.Content.Panel.Actions.More.TouchLongPress:Connect(function()
	local SongId = Queue.GetCurrentSongId()
	local Metadata = Queue.GetCurrentMetadata()
	if not SongId or not Metadata then return end

	PromptSongOptions("NowPlaying", {
		MasterPool = {SongId},
		SongId = SongId,
		Title = Metadata.Title,
		Artist = Metadata.Artist,
		Pointer = 1
	}, true)
end)

Full.Content.Miniplayer.Container.Actions.Shuffle.MouseButton1Click:Connect(function()
	Queue.ToggleShuffle()
end)

-- Full / Search

Full.Container.Search.Results.Visible = false
Full.Container.Search.Suggestions.Visible = true

Full.Container.Search:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	local CanvasPos = Full.Container.Search.AbsoluteCanvasSize.Y - Full.Container.Search.AbsoluteWindowSize.Y
	local Threshold = CanvasPos * .8

	if Full.Container.Search.CanvasPosition.Y >= Threshold then
		local PaginationLoading = Full.Container.Search.Results:FindFirstChild("PaginationLoading")

		if not PaginationLoading then
			PaginationLoading = ui.Storage.Items.PaginationLoading:Clone()
			PaginationLoading.Icon:AddTag("MastersThrobberIcon")
			PaginationLoading.Parent = Full.Container.Search.Results
		end

		if SearchingProperties.SearchData and not SearchingProperties.Advancing then
			task.spawn(function()
				SearchingProperties.Advancing = true
				SearchingProperties.SearchData.Advance()

				--
				task.wait(SearchingProperties.Cooldown)
				--

				if Full.Container.Search.CanvasPosition.Y >= Threshold and SearchingProperties.SearchData then
					SearchingProperties.SearchData.Advance()
				end

				SearchingProperties.Advancing = false
			end)
		end
	end
end)

Full.Container.Search.Frame.Textbox.FocusLost:Connect(function()
	if Full.Container.Search.Frame.Textbox.Text == "" then
		Full.Container.Search.Results.Visible = false
		Full.Container.Search.Suggestions.Visible = true

		SearchingProperties.RecentKeyword = ""
		SearchingProperties.SearchData = nil

		-- Clearance

		for i, residual in Full.Container.Search.Results:GetChildren() do
			if residual:HasTag("MastersTemplate") then
				residual:Destroy()
			end
		end

	else

		local Keyword = Full.Container.Search.Frame.Textbox.Text
		if Keyword == SearchingProperties.RecentKeyword then return end

		local PossibleAssetId = tonumber(Keyword)

		SearchingProperties.RecentKeyword = Keyword

		if PossibleAssetId and PossibleAssetId > 999999 then

			Full.Container.Search.Results.Visible = true
			Full.Container.Search.Suggestions.Visible = false

			-- Clearance

			for i, residual in Full.Container.Search.Results:GetChildren() do
				if residual:HasTag("MastersTemplate") then
					residual:Destroy()
				end
			end

			-- Search Queries

			local SongData = Audios.GetAudioMetadataAsync({PossibleAssetId})
			if not SongData or not SongData[1] then return end
			if not SongData[1].Title or not SongData[1].Artist then return end

			AddSongItem({
				Container = Full.Container.Search.Results,
				ContextName = SearchingProperties.RecentKeyword,
				Item = ui.Storage.Items["Item(SearchResults)"],
				MasterPool = {SongData[1].AssetId},
				ItemProperties = {LayoutOrder = 2},
				Pointer = 1,
				SongInfo = SongData[1],
				Source = "Standard"
			})

			local AlreadyAdded = Full.Container.Search.Results:FindFirstChild(SongData[1].Artist)
			if AlreadyAdded and AlreadyAdded:HasTag("MastersArtistItem") then return end

			AddArtistItem({
				Container = Full.Container.Search.Results,
				Item = ui.Storage.Items["Artist(SearchResults)"],
				ItemProperties = {LayoutOrder = 1},
				ArtistName = SongData[1].Artist,
				Source = "Standard"
			})

		else

			local SearchData = Audios.SearchAudiosByKeyword(Keyword)

			SearchingProperties.SearchData = SearchData

			Full.Container.Search.Results.Visible = true
			Full.Container.Search.Suggestions.Visible = false

			-- Clearance

			for i, residual in Full.Container.Search.Results:GetChildren() do
				if residual:HasTag("MastersTemplate") then
					residual:Destroy()
				end
			end

			-- Search Queuries

			local ChunkLoadedTriggered = false

			local function ArrangeSearchQueries(IsFinished, Array)
				if IsFinished then return end
				if #Array == 0 then return end

				-- Clearance

				for i, residual in Full.Container.Search.Results:GetChildren() do
					if residual:HasTag("MastersResidual") then
						residual:Destroy()
					end
				end

				-- Placing

				for i, Song in Array do
					AddSongItem({
						Container = Full.Container.Search.Results,
						ContextName = SearchingProperties.RecentKeyword,
						Item = ui.Storage.Items["Item(SearchResults)"],
						MasterPool = {Song.Id},
						ItemProperties = {LayoutOrder = 2},
						Pointer = 1,
						SongInfo = Song,
						Source = "Standard"
					})

					if Utilities.HowSimilar(Keyword, Song.Artist) >= 75 then
						local AlreadyAdded = Full.Container.Search.Results:FindFirstChild(Song.Artist)
						if AlreadyAdded and AlreadyAdded:HasTag("MastersArtistItem") then continue end

						AddArtistItem({
							Container = Full.Container.Search.Results,
							Item = ui.Storage.Items["Artist(SearchResults)"],
							ItemProperties = {LayoutOrder = 1},
							ArtistName = Song.Artist,
							Source = "Standard"
						})
					end
				end 
			end

			SearchData.ChunkLoaded:Connect(function(IsFinished, Array)
				ChunkLoadedTriggered = false
				ArrangeSearchQueries(IsFinished, Array)
			end)

			if not ChunkLoadedTriggered then
				ArrangeSearchQueries(false, SearchData.Results)
			end
		end
	end
end)

local SearchedKeywords = {}

Audios.SearchedAudio:Connect(function(Keyword)
	Full.Container.Search.Suggestions.Keywords.Visible = true

	if #SearchedKeywords >= 2 then
		table.remove(SearchedKeywords, 1)
	end

	if not table.find(SearchedKeywords, Keyword) then
		table.insert(SearchedKeywords, Keyword)
	end

	for i, residual in Full.Container.Search.Suggestions.Keywords:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	for i, Word in SearchedKeywords do
		local item = ui.Storage.Items.PreviousKeyword:Clone()

		item.Name = Word
		item.LayoutOrder = -i
		item.Parent = Full.Container.Search.Suggestions.Keywords

		item.Label.Text = Word

		--

		item.MouseButton1Click:Connect(function()
			Full.Container.Search.Frame.Textbox.Text = Word
			Full.Container.Search.Frame.Textbox:CaptureFocus()
		end)

		item.Clear.MouseButton1Click:Connect(function()
			item:Destroy()

			table.remove(SearchedKeywords, table.find(SearchedKeywords, Word) or 0)

			if #SearchedKeywords == 0 then
				Full.Container.Search.Suggestions.Keywords.Visible = false
			end
		end)

		--

		item.MouseButton1Down:Connect(function()
			TweenService:Create(item.Label, normal, {TextTransparency = .5}):Play()
			TweenService:Create(item.Icon, normal, {ImageTransparency = .5}):Play()
		end)

		item.InputEnded:Connect(function()
			TweenService:Create(item.Label, normal, {TextTransparency = 0}):Play()
			TweenService:Create(item.Icon, normal, {ImageTransparency = 0}):Play()
		end)

		item.Clear.MouseButton1Down:Connect(function()
			TweenService:Create(item.Clear.Icon, normal, {ImageTransparency = .5}):Play()
		end)

		item.Clear.InputEnded:Connect(function()
			TweenService:Create(item.Clear.Icon, normal, {ImageTransparency = 0}):Play()
		end)
	end
end)

-- Full / Library

function LoadLibrary()
	task.spawn(function()
		if LibraryProperties.Loading then LibraryProperties.ForReload = true return end
		LibraryProperties.Loading = true

		-- Clearance

		for i, residual in Full.Container.Library.Frame:GetChildren() do
			if residual:HasTag("MastersTemplate") then
				residual:Destroy()
			end
		end

		-- Loading

		local Library = events.Main.Library.FetchLibrary:InvokeServer()
		local Preferences = events.Main.Preferences.FetchPreference:InvokeServer()
		local SharedWithYou = events.Main.Sharing.FetchSharedWithYou:InvokeServer()

		if not Library or not Preferences or not SharedWithYou then return end

		-- Artists (4)

		if #Library.Artists > 0 then
			local Container = ui.Storage.Items["Container(ArtistStandard)"]:Clone()

			Container.Name = "Artists"
			Container.LayoutOrder = 4
			Container.Header.Label.Text = "Artists"
			Container.Parent = Full.Container.Library.Frame

			for i, Artist in Library.Artists do
				AddArtistItem({
					Container = Container.Content,
					Item = ui.Storage.Items["Artist(Standard)"],
					ItemProperties = {Pinned = Artist.Pin},
					ArtistName = Artist.Name,
					Source = "Library"
				})
			end
		end

		-- Playlists (2)

		if #Library.Playlist > 0 then
			local Container = ui.Storage.Items["Container(Standard)"]:Clone()

			Container.Name = "Playlists"
			Container.LayoutOrder = 2
			Container.Header.Label.Text = "Playlists"
			Container.Parent = Full.Container.Library.Frame

			for i, Playlist in Library.Playlist do
				AddPlaylistItem({
					Container = Container.Content,
					Item = ui.Storage.Items["Playlist(Big)"],
					ItemProperties = {Pinned = Playlist.Pin, LayoutOrder = -i},
					PlaylistData = Playlist,
					Source = "Library"
				})
			end
		end

		-- Songs (3)

		if #Library.Songs > 0 then
			local List = {}

			for i, Song in Library.Songs do
				table.insert(List, i, Song.SongId)
			end

			local Metadatas = Audios.GetAudioMetadataAsync(List)
			if not Metadatas then return end

			local Container = ui.Storage.Items["Container(Standard)"]:Clone()

			Container.Name = "Songs"
			Container.LayoutOrder = 3
			Container.Header.Label.Text = "Songs"
			Container.Parent = Full.Container.Library.Frame

			for i, Song in Library.Songs do				
				AddSongItem({
					Container = Container.Content,
					ContextName = "Library",
					Item = ui.Storage.Items["Item(Big)"],
					ItemProperties = {Pinned = Song.Pin},
					MasterPool = List,
					Pointer = i,
					SongInfo = Metadatas[i],
					Source = "Library"
				})
			end
		end

		-- Favorite Songs (1)

		if #Preferences.Songs.Favorite > 0 then
			local List = Preferences.Songs.Favorite
			local Metadatas = Audios.GetAudioMetadataAsync(List)
			if not Metadatas then return end

			local Container = ui.Storage.Items["Container(Charts)"]:Clone()

			Container.Name = "Favorites"
			Container.LayoutOrder = 1
			Container.Header.Label.Text = "Favorites"
			Container.Parent = Full.Container.Library.Frame

			for i, Song in List do				
				AddSongItem({
					Container = Container.Content,
					ContextName = "Favorites",
					Item = ui.Storage.Items["Item(Small)"],
					MasterPool = List,
					Pointer = i,
					SongInfo = Metadatas[i],
					Source = "Standard"
				})
			end
		end

		-- Shared With You (5)

		if #SharedWithYou > 0 then
			local Container = ui.Storage.Items["Container(Shared)"]:Clone()

			Container.Name = "SharedWithYou"
			Container.LayoutOrder = 5
			Container.Header.Label.Text = "Shared With You"
			Container.Parent = Full.Container.Library.Frame

			local Songs = {}
			local SongData = {}

			for i, Item in SharedWithYou do
				if Item.Type == "Song" then
					table.insert(Songs, Item.Identifier)
					table.insert(SongData, Item)
				end
			end

			local Metadata = Audios.GetAudioMetadataAsync(Songs)
			if not Metadata then return end

			for i, Item in Songs do
				AddSongItem({
					Container = Container.Content,
					ContextName = "Library",
					Item = ui.Storage.Items["Item(Shared)"],
					ItemProperties = {Shared = SongData[i], LayoutOrder = -SongData[i].TimeSent},
					MasterPool = Songs,
					Pointer = i,
					SongInfo = Metadata[i],
					Source = "Standard"
				})
			end

			for i, Item in SharedWithYou do
				if Item.Type == "Artist" then
					AddArtistItem({
						Container = Container.Content,
						Item = ui.Storage.Items["Artist(Shared)"],
						ItemProperties = {Shared = Item, LayoutOrder = -Item.TimeSent},
						ArtistName = Item.Identifier,
						Source = "Standard"
					})

				elseif Item.Type == "Playlist" then
					local PlaylistData = events.Main.Library.GetPlaylistByPlaylistId:InvokeServer(Item.Sender, Item.Identifier)
					if not PlaylistData then continue end

					AddPlaylistItem({
						Container = Container.Content,
						Item = ui.Storage.Items["Playlist(Shared)"],
						ItemProperties = {Shared = Item, LayoutOrder = -Item.TimeSent},
						PlaylistData = PlaylistData,
						Source = "Standard"
					})
				end
			end
		end

		LibraryProperties.Loading = false
	end)
end

Main.PageChanged:Connect(function(Page, Parameter)
	if Page == "Library" then
		LoadLibrary()
	end
end)

LibraryProperties.RequestReload:Connect(function()
	task.wait(.1)
	LoadLibrary()
end)

-- NowPlaying
-- NowPlaying / ViewStates

NowPlaying.Content.Media.Details.More.MouseButton1Click:Connect(function()
	local Orientation = Main.GetOrientation()

	if Orientation == "Portrait" then
		Main.NowPlayingView(false, true)
	elseif Orientation == "Landscape" then
		Main.NowPlayingView(true, true)
	end
end)

NowPlaying.Content.Panel.QueueOptions.Back.MouseButton1Click:Connect(function()
	local Orientation = Main.GetOrientation()

	if Orientation == "Portrait" then
		Main.NowPlayingView(true, false)
	elseif Orientation == "Landscape" then
		Main.NowPlayingView(true, false)
	end
end)

Main.OrientationChanged:Connect(function(Orientation)
	local MediaState, PanelState = Main.GetNowplayingViewStates()

	if Orientation == "Landscape" then

		-- NowPlaying

		if PanelState then
			Main.NowPlayingView(true, true)
		end

		NowPlayingProperties.LyricsTopOffset = 20

		NowPlaying.Content.Media.scale.Scale = 1
		NowPlaying.Content.Media.list.Padding = UDim.new(0, 10)

		-- Sidebar

		local SidebarOpened, SidebarFullscreen = Main.GetSidebarStatus()

		if SidebarOpened and SidebarFullscreen then
			Main.Sidebar(true, false)
		end

		-- PlaylistPage

		Full.Container.Playlist.Canvas.list.HorizontalAlignment = Enum.HorizontalAlignment.Left
		Full.Container.Playlist.Canvas.Details.Info.Source.TextXAlignment = Enum.TextXAlignment.Left
		Full.Container.Playlist.Canvas.Details.Info.Subtext.TextXAlignment = Enum.TextXAlignment.Left
		Full.Container.Playlist.Canvas.Details.Info.Title.TextXAlignment = Enum.TextXAlignment.Left

		Full.Container.Stations.Canvas.list.HorizontalAlignment = Enum.HorizontalAlignment.Left
		Full.Container.Stations.Canvas.Details.Info.Source.TextXAlignment = Enum.TextXAlignment.Left
		Full.Container.Stations.Canvas.Details.Info.Subtext.TextXAlignment = Enum.TextXAlignment.Left
		Full.Container.Stations.Canvas.Details.Info.Title.TextXAlignment = Enum.TextXAlignment.Left

		-- Miniplayer

		Full.Content.Miniplayer.Position = UDim2.new(1, 0, 1, 0)

		Full.Content.Miniplayer.Container.Actions.Visible = true

		Full.Content.Miniplayer.Container.Playback.Size = UDim2.new(0, 200, 1, 0)
		Full.Content.Miniplayer.Container.Playback.Rewind.Visible = true

		Full.Content.Miniplayer.Container.divider1.Visible = true
		Full.Content.Miniplayer.Container.divider2.Visible = true

		Full.Content.Miniplayer.Container.corner.CornerRadius = UDim.new(0, 0)

		Full.Content.Miniplayer.padding.PaddingLeft = UDim.new(0, 0)
		Full.Content.Miniplayer.padding.PaddingRight = UDim.new(0, 0)

	elseif Orientation == "Portrait" then

		-- NowPlaying

		if MediaState and PanelState then
			Main.NowPlayingView(true, false)
		end

		NowPlayingProperties.LyricsTopOffset = 60

		NowPlaying.Content.Media.scale.Scale = 1.8
		NowPlaying.Content.Media.list.Padding = UDim.new(0, 20)

		-- Sidebar

		local SidebarOpened = Main.GetSidebarStatus()

		if SidebarOpened then
			Main.Sidebar(true, true)
		end

		-- PlaylistPage

		Full.Container.Playlist.Canvas.list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		Full.Container.Playlist.Canvas.Details.Info.Source.TextXAlignment = Enum.TextXAlignment.Center
		Full.Container.Playlist.Canvas.Details.Info.Subtext.TextXAlignment = Enum.TextXAlignment.Center
		Full.Container.Playlist.Canvas.Details.Info.Title.TextXAlignment = Enum.TextXAlignment.Center

		Full.Container.Stations.Canvas.list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		Full.Container.Stations.Canvas.Details.Info.Source.TextXAlignment = Enum.TextXAlignment.Center
		Full.Container.Stations.Canvas.Details.Info.Subtext.TextXAlignment = Enum.TextXAlignment.Center
		Full.Container.Stations.Canvas.Details.Info.Title.TextXAlignment = Enum.TextXAlignment.Center

		-- Miniplayer

		Full.Content.Miniplayer.Position = UDim2.new(1, 0, 1, -15)

		Full.Content.Miniplayer.Container.Actions.Visible = false

		Full.Content.Miniplayer.Container.Playback.Size = UDim2.new(0, 140, 1, 0)
		Full.Content.Miniplayer.Container.Playback.Rewind.Visible = false

		Full.Content.Miniplayer.Container.divider1.Visible = false
		Full.Content.Miniplayer.Container.divider2.Visible = false

		Full.Content.Miniplayer.Container.corner.CornerRadius = UDim.new(0, 12)

		Full.Content.Miniplayer.padding.PaddingLeft = UDim.new(0, 15)
		Full.Content.Miniplayer.padding.PaddingRight = UDim.new(0, 15)
	end

	task.delay(.01, function()
		if Main.GetState() ~= "Bar" then return end
		SnapToNearestSide(true)
	end)
end)

-- NowPlaying / PanelScreen

NowPlaying.Content.Panel.Actions.Listeners.MouseButton1Click:Connect(function()
	Main.NowPlayingPanelScreen("Listeners")
end)

NowPlaying.Content.Panel.Actions.Lyrics.MouseButton1Click:Connect(function()
	Main.NowPlayingPanelScreen("Lyrics")
end)

NowPlaying.Content.Panel.Actions.QueueList.MouseButton1Click:Connect(function()
	Main.NowPlayingPanelScreen("QueueList")
end)

NowPlaying.Content.Media.MouseEnter:Connect(function()
	local TitleX = NowPlaying.Content.Media.Details.SongInfo.Title.Label.AbsoluteSize.X

	if TitleX > 180 then
		local Offset = 180 - TitleX

		TweenService:Create(NowPlaying.Content.Media.Details.SongInfo.Title.padding, TweenInfo.new(TitleX / 50), 
			{PaddingLeft = UDim.new(0, Offset)}):Play()
	end
end)

NowPlaying.Content.Media.InputEnded:Connect(function()
	TweenService:Create(NowPlaying.Content.Media.Details.SongInfo.Title.padding, slow, {PaddingLeft = UDim.new(0, 15)}):Play()
end)

NowPlaying.Content.Media.Details.SongInfo.Title.TouchSwipe:Connect(function(Direction)
	if Direction == Enum.SwipeDirection.Right then
		events.Playback.Rewind:Fire()

	elseif Direction == Enum.SwipeDirection.Left then
		events.Playback.Forward:Fire()
	end
end)

NowPlaying.Content.Media.Details.SongInfo.Source.TouchSwipe:Connect(function(Direction)
	if Direction == Enum.SwipeDirection.Right then
		events.Playback.Rewind:Fire()

	elseif Direction == Enum.SwipeDirection.Left then
		events.Playback.Forward:Fire()
	end
end)

NowPlaying.Content.Media.Art.Photo.Shield.TouchSwipe:Connect(function(Direction)
	if Direction == Enum.SwipeDirection.Right then
		events.Playback.Rewind:Fire()

	elseif Direction == Enum.SwipeDirection.Left then
		events.Playback.Forward:Fire()
	end
end)

NowPlaying.Content.Media.Details.SongInfo.Source.MouseButton1Click:Connect(function()
	local Option = Main.PromptOptions({
		Options = {
			{Name = OptionInfoPresets.Others.ViewArtist.Name, Icon = OptionInfoPresets.Others.ViewArtist.Icon},
			{Name = OptionInfoPresets.Others.ViewDetails.Name, Icon = OptionInfoPresets.Others.ViewDetails.Icon}
		},
	})

	if Option == "View Artist" then
		callback_ViewArtist(NowPlaying.Content.Media.Details.SongInfo.Source.Text)

	elseif Option == "View Details" then
		callback_ViewDetails()

	end
end)

NowPlaying.Content.Media.Details.SongInfo.Source.TouchLongPress:Connect(function()
	local Option = Main.PromptOptions({
		Options = {
			{Name = OptionInfoPresets.Others.ViewArtist.Name, Icon = OptionInfoPresets.Others.ViewArtist.Icon},
			{Name = OptionInfoPresets.Others.ViewDetails.Name, Icon = OptionInfoPresets.Others.ViewDetails.Icon}
		},
		Mobile = true
	})

	if Option == "View Artist" then
		callback_ViewArtist(NowPlaying.Content.Media.Details.SongInfo.Source.Text)

	elseif Option == "View Details" then
		callback_ViewDetails()

	end
end)

-- NowPlaying / Scrubber

local function UpdateTimeScrubber(input)
	local Frame = NowPlaying.Content.Media.Timeline.Scrubber
	local DeltaX = input.Position.X - TimeScrubberData.StartPos
	local DeltaScale = DeltaX / Frame.AbsoluteSize.X
	local NewScale = math.clamp(TimeScrubberData.StartScale + DeltaScale, 0, 1)

	Frame.Fill.Size = UDim2.fromScale(NewScale, 1)

	return NewScale
end

local function ApplyTimeScrubbedPosition()
	if Queue.GetLoadingStatus() then return end
	if Queue.GetCrossfadingStatus() then return end

	local CurrentSong = Queue.GetActiveSound()
	if not CurrentSong then return end

	local ScaleX = NowPlaying.Content.Media.Timeline.Scrubber.Fill.Size.X.Scale
	local TimePosition = Utilities.Map(ScaleX, 0, 1, 0, CurrentSong.TimeLength)

	CurrentSong.TimePosition = TimePosition
end

NowPlaying.Content.Media.Timeline.Scrubber.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		TimeScrubberData.Dragging = true
		TimeScrubberData.StartPos = input.Position.X
		TimeScrubberData.StartScale = NowPlaying.Content.Media.Timeline.Scrubber.Fill.Size.X.Scale

		TweenService:Create(NowPlaying.Content.Media.Timeline.Scrubber, normal, {
			GroupTransparency = 0,
			Size = UDim2.new(1, 20, 0, 12)}):Play()

		TweenService:Create(NowPlaying.Content.Media.Timeline.Data.TimeLength, normal, {TextTransparency = 0}):Play()
		TweenService:Create(NowPlaying.Content.Media.Timeline.Data.TimePosition, normal, {TextTransparency = 0}):Play()
	end
end)

InputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if TimeScrubberData.Dragging then
			ApplyTimeScrubbedPosition()

			TimeScrubberData.Dragging = false

			--

			TweenService:Create(NowPlaying.Content.Media.Timeline.Scrubber, normal, {GroupTransparency = .5,
				Size = UDim2.new(1, 0, 0, 6)}):Play()

			TweenService:Create(NowPlaying.Content.Media.Timeline.Data.TimeLength, normal, {TextTransparency = .8}):Play()
			TweenService:Create(NowPlaying.Content.Media.Timeline.Data.TimePosition, normal, {TextTransparency = .8}):Play()
		end
	end
end)

InputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or
		input.UserInputType == Enum.UserInputType.Touch then

		if TimeScrubberData.Dragging then
			UpdateTimeScrubber(input)
		end
	end
end)

--

Queue.QueueUpdated:Connect(function()

	-- Clearance

	for i, residual in NowPlaying.Content.Panel.Queue.QueueSection.Container:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	for i, residual in NowPlaying.Content.Panel.Queue.ContinuePlayingSection.Container:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	-- Listing

	local VisualQueue = Queue.GetVisualQueue()

	NowPlaying.Content.Panel.Queue.QueueSection.Visible = #VisualQueue.Queue > 0
	NowPlaying.Content.Panel.Queue.ContinuePlayingSection.Visible = #VisualQueue.ContinuePlaying > 0

	NowPlaying.Content.Panel.Queue.ContinuePlayingSection.Header.Context.Text = "From " .. Queue.GetContextName()

	local Lists = {
		Queue = {},
		ContinuePlaying = {},
	}

	for i, Song in VisualQueue.Queue do
		Lists.Queue[i] = Song.Id
	end

	for i, Song in VisualQueue.ContinuePlaying do
		Lists.ContinuePlaying[i] = Song.Id
	end

	local QueueMetadata = Audios.GetAudioMetadataAsync(Lists.Queue)
	local ContinuePlayingMetadata = Audios.GetAudioMetadataAsync(Lists.ContinuePlaying)

	if not QueueMetadata or not ContinuePlayingMetadata then return end

	for i, Song in VisualQueue.Queue do
		local Data = QueueMetadata[i]
		if not Data then return end

		local item = ui.Storage.Items["Item(NowPlayingQueue)"]:Clone()

		item.Name = Song.Id
		item.LayoutOrder = i

		item:SetAttribute("TrackingId", Song.TrackingId)

		item.Art.Photo.Image = Utilities.GetCoverForSong(Song.Id)

		item.Information.Source.Text = Data.Artist		
		item.Information.Title.Text = Data.Title

		item.Parent = NowPlaying.Content.Panel.Queue.QueueSection.Container

		item.MouseButton1Click:Connect(function()
			Queue.ProceedByTrackingId(Song.TrackingId)
		end)

		item.MouseButton2Click:Connect(function()
			PromptSongOptions("Queue", {
				SongId = Song.Id,
				TrackingId = Song.TrackingId
			})
		end)

		item.TouchLongPress:Connect(function()
			PromptSongOptions("Queue", {
				SongId = Song.Id,
				TrackingId = Song.TrackingId
			}, true)
		end)
	end

	for i, Song in VisualQueue.ContinuePlaying do
		local Data = ContinuePlayingMetadata[i]
		if not Data then return end

		local item = ui.Storage.Items["Item(NowPlayingQueue)"]:Clone()

		item.Name = Song.Id
		item.LayoutOrder = i

		item:SetAttribute("TrackingId", Song.TrackingId)

		item.Art.Photo.Image = Utilities.GetCoverForSong(Song.Id)

		item.Information.Source.Text = Data.Artist		
		item.Information.Title.Text = Data.Title

		item.Parent = NowPlaying.Content.Panel.Queue.ContinuePlayingSection.Container

		item.MouseButton1Click:Connect(function()
			Queue.ProceedByTrackingId(Song.TrackingId)
		end)

		item.MouseButton2Click:Connect(function()
			PromptSongOptions("ContinuePlaying", {
				SongId = Song.Id,
				TrackingId = Song.TrackingId
			})
		end)

		item.TouchLongPress:Connect(function()
			PromptSongOptions("ContinuePlaying", {
				SongId = Song.Id,
				TrackingId = Song.TrackingId,
			}, true)
		end)
	end
end)

NowPlaying.Content.Panel.Queue.QueueSection.Header.Clear.MouseButton1Click:Connect(function()
	Queue.ClearQueue()
end)

--

NowPlaying.Content.Media.Playback.PlayPause.MouseButton1Click:Connect(function()
	events.Playback.PlayPause:Fire()
end)

NowPlaying.Content.Media.Playback.Forward.MouseButton1Click:Connect(function()
	events.Playback.Forward:Fire()
end)

NowPlaying.Content.Media.Playback.Rewind.MouseButton1Click:Connect(function()
	events.Playback.Rewind:Fire()
end)

-- NowPlaying / Dragging Behavior

local NowPlayingDragProperties = {
	MaxSize = 1,
	MinSize = 0,
	Threshold = .5,
	Elasticity = .3,
	SnapTween = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
}

local NowPlayingDragStatus = {
	Dragging = false,
	DragStartY = 0,
	StartSize = NowPlaying.Size.Y.Scale,
	StartPos = NowPlaying.Position.Y.Scale
}

local function SetSize(ScaleY)
	ScaleY = math.clamp(ScaleY, -5, 5)
	NowPlaying.Size = UDim2.new(NowPlaying.Size.X.Scale, NowPlaying.Size.X.Offset, ScaleY, NowPlaying.Size.Y.Offset or 0)
end

local function SnapTo(State)
	if State then
		TweenService:Create(NowPlaying, NowPlayingDragProperties.SnapTween, {
			Size = UDim2.new(NowPlaying.Size.X.Scale, NowPlaying.Size.X.Offset,
				NowPlayingDragProperties.MaxSize, NowPlaying.Size.Y.Offset or 0), Position = UDim2.new(.5, 0, 1, 0)}):Play()		
	else
		Main.NowPlaying(false)
	end
end

NowPlaying.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	NowPlaying.Content.Media.Interactable = false
	NowPlaying.Content.Panel.Interactable = false

	NowPlayingDragStatus.Dragging = true
	NowPlayingDragStatus.DragStartY = input.Position.Y
	NowPlayingDragStatus.StartSize = NowPlaying.Size.Y.Scale
	NowPlayingDragStatus.StartPos = NowPlaying.Position.Y.Scale

	input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End and NowPlayingDragStatus.Dragging then
			NowPlayingDragStatus.Dragging = false

			NowPlaying.Content.Media.Interactable = true
			NowPlaying.Content.Panel.Interactable = true

			local currentScale = NowPlaying.Size.Y.Scale

			if currentScale <= NowPlayingDragProperties.Threshold then
				SnapTo(false)
			else
				SnapTo(true)
			end
		end
	end)
end)

InputService.InputChanged:Connect(function(input)
	if not NowPlayingDragStatus.Dragging then return end

	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		if TimeScrubberData.Dragging then return end

		local DeltaY = input.Position.Y - NowPlayingDragStatus.DragStartY
		local ParentHeight = math.max(1, NowPlaying.Parent.AbsoluteSize.Y)
		local Data = -DeltaY / ParentHeight
		local Target = NowPlayingDragStatus.StartSize + Data

		if Target > NowPlayingDragProperties.MaxSize then
			Target = NowPlayingDragProperties.MaxSize + (Target - NowPlayingDragProperties.MaxSize) * NowPlayingDragProperties.Elasticity
		elseif Target < NowPlayingDragProperties.MinSize then
			Target = NowPlayingDragProperties.MinSize - (NowPlayingDragProperties.MinSize - Target) * NowPlayingDragProperties.Elasticity
		end

		SetSize(Target)
	end
end)

-- NowPlaying / Volume

local function UpdateVolumeScrubber(input)
	local Frame = NowPlaying.Content.Media.Volume.Scrubber
	local DeltaX = input.Position.X - VolumeScrubberData.StartPos
	local DeltaScale = DeltaX / Frame.AbsoluteSize.X
	local NewScale = math.clamp(VolumeScrubberData.StartScale + DeltaScale, 0, 1)

	Frame.Fill.Size = UDim2.fromScale(NewScale, 1)

	local NewVolume = Utilities.Map(NewScale, 0, 1, 0, 2)

	TweenService:Create(Playback, normal, {Volume = NewVolume}):Play()
end

local function ApplyNewVolume(Volume)
	local Frame = NowPlaying.Content.Media.Volume.Scrubber
	local NewScale = Utilities.Map(Volume, 0, 2, 0, 1)

	TweenService:Create(Frame.Fill, normal, {Size = UDim2.fromScale(NewScale, 1)}):Play()
end

NowPlaying.Content.Media.Volume.Scrubber.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		VolumeScrubberData.Dragging = true
		VolumeScrubberData.StartPos = input.Position.X
		VolumeScrubberData.StartScale = NowPlaying.Content.Media.Volume.Scrubber.Fill.Size.X.Scale

		TweenService:Create(NowPlaying.Content.Media.Volume, normal, {Size = UDim2.new(0, 190, 0, 14)}):Play()
		TweenService:Create(NowPlaying.Content.Media.Volume.Scrubber, normal, {
			GroupTransparency = 0,
			Size = UDim2.new(1, 0, 0, 12)}):Play()

		TweenService:Create(NowPlaying.Content.Media.Volume.Max, normal, {ImageTransparency = 0}):Play()
		TweenService:Create(NowPlaying.Content.Media.Volume.Min, normal, {ImageTransparency = 0}):Play()
	end
end)

InputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if VolumeScrubberData.Dragging then
			VolumeScrubberData.Dragging = false

			--

			TweenService:Create(NowPlaying.Content.Media.Volume, normal, {Size = UDim2.new(0, 180, 0, 14)}):Play()
			TweenService:Create(NowPlaying.Content.Media.Volume.Scrubber, normal, {
				GroupTransparency = .5,
				Size = UDim2.new(1, 0, 0, 6)}):Play()

			TweenService:Create(NowPlaying.Content.Media.Volume.Max, normal, {ImageTransparency = .5}):Play()
			TweenService:Create(NowPlaying.Content.Media.Volume.Min, normal, {ImageTransparency = .5}):Play()
		end
	end
end)

InputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or
		input.UserInputType == Enum.UserInputType.Touch then

		if VolumeScrubberData.Dragging then
			UpdateVolumeScrubber(input)
		end
	end
end)

-- NowPlaying / QueueControls

NowPlaying.Content.Panel.QueueOptions.Shuffle.MouseButton1Click:Connect(function()
	Queue.ToggleShuffle()
end)

NowPlaying.Content.Panel.QueueOptions.Queue.MouseButton1Click:Connect(function()
	Queue.ToggleRepeat()
end)

Queue.StatusChanged:Connect(function(Status)
	if Status.Settings.Shuffle then
		TweenService:Create(NowPlaying.Content.Panel.QueueOptions.Shuffle, normal, {BackgroundTransparency = .7}):Play()

		TweenService:Create(Full.Content.Miniplayer.Container.Actions.Shuffle.Fill, normal, {BackgroundTransparency = .95}):Play()
		TweenService:Create(Full.Content.Miniplayer.Container.Actions.Shuffle.Fill.scale, normal, {Scale = 1}):Play()
	else
		TweenService:Create(NowPlaying.Content.Panel.QueueOptions.Shuffle, normal, {BackgroundTransparency = .95}):Play()

		TweenService:Create(Full.Content.Miniplayer.Container.Actions.Shuffle.Fill, normal, {BackgroundTransparency = 1}):Play()
		TweenService:Create(Full.Content.Miniplayer.Container.Actions.Shuffle.Fill.scale, normal, {Scale = .6}):Play()
	end

	if Status.Settings.RepeatMode == "Song" then
		NowPlaying.Content.Panel.Queue.Repeating.Visible = true

		TweenService:Create(NowPlaying.Content.Panel.QueueOptions.Queue, normal, {BackgroundTransparency = .7}):Play()
	else
		NowPlaying.Content.Panel.Queue.Repeating.Visible = false

		TweenService:Create(NowPlaying.Content.Panel.QueueOptions.Queue, normal, {BackgroundTransparency = .95}):Play()
	end
end)

-- Full / Artists

-- ArtistPage / Discography Search

function DiscographySearchKeyword(Keyword, SetVisibility)
	local Container = Full.Container.Artist.Sections.Discography.Content 
	local isCleaningUp = (Keyword == "" or Keyword:match("^%s*$"))
	local CleanKeyword = Keyword:lower()

	for _, Item in Container:GetChildren() do
		if not Item:IsA("GuiObject") then continue end
		if not Item:GetAttribute("OriginalLayoutOrder") then
			Item:SetAttribute("OriginalLayoutOrder", Item.LayoutOrder)
		end

		local Variable = {Item.Name, Item.Information.Source.Text, Item.Information.Title.Text} 
		local CombinedKeywords = table.concat(Variable, " "):lower()

		if isCleaningUp then
			Item.Visible = true
			Item.LayoutOrder = Item:GetAttribute("OriginalLayoutOrder") or 1
		else
			local matchFound = string.find(CombinedKeywords, CleanKeyword, 1, true) ~= nil

			if SetVisibility then
				Item.Visible = matchFound 
			else
				if matchFound then
					local startPos = string.find(CombinedKeywords, CleanKeyword, 1, true)
					Item.LayoutOrder = startPos
				else
					Item.LayoutOrder = 9999 
				end
			end
		end
	end
end

Full.Container.Artist.Sections.Discography.Header.Search.Field.FocusLost:Connect(function()
	DiscographySearchKeyword(Full.Container.Artist.Sections.Discography.Header.Search.Field.Text, false)

	TweenService:Create(Full.Container.Artist.Sections.Discography.Header.Search.Util.Line, normal, {BackgroundTransparency = .9}):Play()
end)

Full.Container.Artist.Sections.Discography.Header.Search.Field.Focused:Connect(function()
	TweenService:Create(Full.Container.Artist.Sections.Discography.Header.Search.Util.Line, normal, {BackgroundTransparency = .5}):Play()
end)

-- ArtistPage / Actions

Full.Container.Artist.Action.Play.MouseButton1Click:Connect(function()
	if #ArtistPageProperties.Discography < 1 then return end

	Queue.LoadSource(ArtistPageProperties.Discography, 1, ArtistPageProperties.CurrentArtistLoaded .. "'s Discography", true)
end)

Full.Container.Artist.Action.Play.MouseButton2Click:Connect(function()
	if #ArtistPageProperties.Discography < 1 then return end

	local Options = Main.PromptOptions({
		Options = {
			{Name = OptionInfoPresets.PlayModes.Play.Name, Icon = OptionInfoPresets.PlayModes.Play.Icon, Primary = true},

			"SEPARATOR",

			{Name = OptionInfoPresets.PlayModes.PlayNext.Name, Icon = OptionInfoPresets.PlayModes.PlayNext.Icon},
			{Name = OptionInfoPresets.PlayModes.PlayLast.Name, Icon = OptionInfoPresets.PlayLast.PlayNext.Icon}
		}
	})

	if Options == "Play" then
		Queue.LoadSource(ArtistPageProperties.Discography, 1, ArtistPageProperties.CurrentArtistLoaded .. "'s Discography", true)

	elseif Options == "Play Next" then
		Queue.PlayNext(ArtistPageProperties.Discography)

	elseif Options == "Play Last" then
		Queue.AddToQueue(ArtistPageProperties.Discography)
	end
end)

Full.Container.Artist.Action.Play.TouchLongPress:Connect(function()
	if #ArtistPageProperties.Discography < 1 then return end

	local Options = Main.PromptOptions({
		Options = {
			{Name = OptionInfoPresets.PlayModes.Play.Name, Icon = OptionInfoPresets.PlayModes.Play.Icon, Primary = true},

			"SEPARATOR",

			{Name = OptionInfoPresets.PlayModes.PlayNext.Name, Icon = OptionInfoPresets.PlayModes.PlayNext.Icon},
			{Name = OptionInfoPresets.PlayModes.PlayLast.Name, Icon = OptionInfoPresets.PlayModes.PlayLast.Icon},
		}, 
		Mobile = true
	})

	if Options == "Play" then
		Queue.LoadSource(ArtistPageProperties.Discography, 1, ArtistPageProperties.CurrentArtistLoaded .. "'s Discography", true)

	elseif Options == "Play Next" then
		Queue.PlayNext(ArtistPageProperties.Discography)

	elseif Options == "Play Last" then
		Queue.AddToQueue(ArtistPageProperties.Discography)
	end
end)

Full.Container.Artist.Action.Shuffle.MouseButton1Click:Connect(function()
	if #ArtistPageProperties.Discography < 1 then return end

	if Queue.GetSettings().Shuffle then
		Queue.LoadSource(ArtistPageProperties.Discography, math.random(1, #ArtistPageProperties.Discography), 
			ArtistPageProperties.CurrentArtistLoaded .. "'s Discography", true)

		Queue.ToggleShuffle()
		Queue.ToggleShuffle()
	else
		Queue.LoadSource(ArtistPageProperties.Discography, math.random(1, #ArtistPageProperties.Discography), 
			ArtistPageProperties.CurrentArtistLoaded .. "'s Discography", true)
		Queue.ToggleShuffle()
	end
end)

Full.Container.Artist.Action.More.MouseButton1Click:Connect(function()
	PromptArtistOption("ArtistPage", ArtistPageProperties.CurrentArtistLoaded)
end)

Full.Container.Artist.Action.More.TouchLongPress:Connect(function()
	PromptArtistOption("ArtistPage", ArtistPageProperties.CurrentArtistLoaded, true)
end)

Full.Container.Artist.Header.Back.MouseButton1Click:Connect(function()
	Main.SetPage(Main.GetLastMainPage())
end)

Full.Container.Artist:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	local YAxis = Full.Container.Artist.CanvasPosition.Y
	local Transparency = Utilities.Map(YAxis, 100, 200, 0, .8)

	TweenService:Create(Full.Util.ArtistBackground.Background, smooth, {BackgroundTransparency = Transparency}):Play()
end)

-- DetailsPage

Full.Container.Details.Header.Back.MouseButton1Click:Connect(function()
	Main.SetPage(Main.GetLastMainPage())
end)

Full.Container.Details.Action.Play.MouseButton1Click:Connect(function()
	Queue.LoadSource({DetailsPageProperties.CurrentSongLoaded}, 1, "Masters", true)
end)

-- PlaylistPage

PlaylistPageProperties.RequestReload:Connect(function()
	if Main.GetCurrentPage() == "Playlist" then
		LoadPlaylist(PlaylistPageProperties.CurrentCreatorId, PlaylistPageProperties.CurrentPlaylistId)
	end
end)

Full.Container.Playlist.Canvas.Details.Action.Play.MouseButton1Click:Connect(function()
	if #PlaylistPageProperties.Songs < 1 then return end

	Queue.LoadSource(PlaylistPageProperties.Songs, 1, PlaylistPageProperties.CurrentPlaylistName, true)
end)

Full.Container.Playlist.Canvas.Details.Action.Play.MouseButton2Click:Connect(function()
	if #PlaylistPageProperties.Songs < 1 then return end

	local Options = Main.PromptOptions({
		Options = {
			{Name = OptionInfoPresets.PlayModes.Play.Name, Icon = OptionInfoPresets.PlayModes.Play.Icon, Primary = true},

			"SEPARATOR",

			{Name = OptionInfoPresets.PlayModes.PlayNext.Name, Icon = OptionInfoPresets.PlayModes.PlayNext.Icon},
			{Name = OptionInfoPresets.PlayModes.PlayLast.Name, Icon = OptionInfoPresets.PlayLast.PlayNext.Icon}
		}
	})

	if Options == "Play" then
		Queue.LoadSource(PlaylistPageProperties.Songs, 1, PlaylistPageProperties.CurrentPlaylistName, true)

	elseif Options == "Play Next" then
		Queue.PlayNext(PlaylistPageProperties.Songs)

	elseif Options == "Play Last" then
		Queue.AddToQueue(PlaylistPageProperties.Songs)
	end
end)

Full.Container.Playlist.Canvas.Details.Action.Play.TouchLongPress:Connect(function()
	if #PlaylistPageProperties.Songs < 1 then return end

	local Options = Main.PromptOptions({
		Options = {
			{Name = OptionInfoPresets.PlayModes.Play.Name, Icon = OptionInfoPresets.PlayModes.Play.Icon, Primary = true},

			"SEPARATOR",

			{Name = OptionInfoPresets.PlayModes.PlayNext.Name, Icon = OptionInfoPresets.PlayModes.PlayNext.Icon},
			{Name = OptionInfoPresets.PlayModes.PlayLast.Name, Icon = OptionInfoPresets.PlayModes.PlayLast.Icon},
		}, 
		Mobile = true
	})

	if Options == "Play" then
		Queue.LoadSource(PlaylistPageProperties.Songs, 1, PlaylistPageProperties.CurrentPlaylistName, true)

	elseif Options == "Play Next" then
		Queue.PlayNext(PlaylistPageProperties.Songs)

	elseif Options == "Play Last" then
		Queue.AddToQueue(PlaylistPageProperties.Songs)
	end
end)

Full.Container.Playlist.Canvas.Details.Action.Shuffle.MouseButton1Click:Connect(function()
	if #PlaylistPageProperties.Songs < 1 then return end

	if Queue.GetSettings().Shuffle then
		Queue.LoadSource(PlaylistPageProperties.Songs, math.random(1, #PlaylistPageProperties.Songs), 
			PlaylistPageProperties.CurrentPlaylistName, true)

		Queue.ToggleShuffle()
		Queue.ToggleShuffle()
	else
		Queue.LoadSource(PlaylistPageProperties.Songs, math.random(1, #PlaylistPageProperties.Songs), 
			PlaylistPageProperties.CurrentPlaylistName, true)
		Queue.ToggleShuffle()
	end
end)

Full.Container.Playlist.Canvas.Details.Action.More.MouseButton1Click:Connect(function()
	PromptPlaylistOption("PlaylistPage", PlaylistPageProperties.CurrentPlaylistData)
end)

Full.Container.Playlist.Canvas.Details.Action.More.TouchLongPress:Connect(function()
	PromptPlaylistOption("PlaylistPage", PlaylistPageProperties.CurrentPlaylistData, true)
end)

Full.Container.Playlist.Canvas.Details.Action.Add.MouseButton1Click:Connect(function()
	Main.SetPage("Search")
end)

Full.Container.Playlist.Header.Back.MouseButton1Click:Connect(function()
	Main.SetPage(Main.GetLastMainPage())
end)

-- StationPage

Full.Container.Stations.Canvas.Details.Action.Play.MouseButton1Click:Connect(function()
	if #StationPageProperties.Songs < 1 then return end

	Queue.LoadSource(StationPageProperties.Songs, 1, StationPageProperties.CurrentStationData.Name, true)
end)

Full.Container.Stations.Canvas.Details.Action.Play.MouseButton2Click:Connect(function()
	if #StationPageProperties.Songs < 1 then return end

	local Options = Main.PromptOptions({
		Options = {
			{Name = OptionInfoPresets.PlayModes.Play.Name, Icon = OptionInfoPresets.PlayModes.Play.Icon, Primary = true},

			"SEPARATOR",

			{Name = OptionInfoPresets.PlayModes.PlayNext.Name, Icon = OptionInfoPresets.PlayModes.PlayNext.Icon},
			{Name = OptionInfoPresets.PlayModes.PlayLast.Name, Icon = OptionInfoPresets.PlayLast.PlayNext.Icon}
		}
	})

	if Options == "Play" then
		Queue.LoadSource(StationPageProperties.Songs, 1, StationPageProperties.CurrentStationData.Name, true)

	elseif Options == "Play Next" then
		Queue.PlayNext(StationPageProperties.Songs)

	elseif Options == "Play Last" then
		Queue.AddToQueue(StationPageProperties.Songs)
	end
end)

Full.Container.Stations.Canvas.Details.Action.Play.TouchLongPress:Connect(function()
	if #StationPageProperties.Songs < 1 then return end

	local Options = Main.PromptOptions({
		Options = {
			{Name = OptionInfoPresets.PlayModes.Play.Name, Icon = OptionInfoPresets.PlayModes.Play.Icon, Primary = true},

			"SEPARATOR",

			{Name = OptionInfoPresets.PlayModes.PlayNext.Name, Icon = OptionInfoPresets.PlayModes.PlayNext.Icon},
			{Name = OptionInfoPresets.PlayModes.PlayLast.Name, Icon = OptionInfoPresets.PlayModes.PlayLast.Icon},
		}, 
		Mobile = true
	})

	if Options == "Play" then
		Queue.LoadSource(StationPageProperties.Songs, 1, StationPageProperties.CurrentStationData.Name, true)

	elseif Options == "Play Next" then
		Queue.PlayNext(StationPageProperties.Songs)

	elseif Options == "Play Last" then
		Queue.AddToQueue(StationPageProperties.Songs)
	end
end)

Full.Container.Stations.Canvas.Details.Action.Shuffle.MouseButton1Click:Connect(function()
	if #StationPageProperties.Songs < 1 then return end

	if Queue.GetSettings().Shuffle then
		Queue.LoadSource(StationPageProperties.Songs, math.random(1, #StationPageProperties.Songs), 
			StationPageProperties.CurrentStationData.Name, true)

		Queue.ToggleShuffle()
		Queue.ToggleShuffle()
	else
		Queue.LoadSource(StationPageProperties.Songs, math.random(1, #StationPageProperties.Songs), 
			StationPageProperties.CurrentStationData.Name, true)
		Queue.ToggleShuffle()
	end
end)

Full.Container.Stations.Canvas.Details.Action.More.MouseButton1Click:Connect(function()
	PromptStationOption("StationPage",  StationPageProperties.CurrentStationData, StationPageProperties.IsCurrentlyOnline)
end)

Full.Container.Stations.Canvas.Details.Action.More.TouchLongPress:Connect(function()
	PromptStationOption("StationPage", StationPageProperties.CurrentStationData, StationPageProperties.IsCurrentlyOnline, true)
end)

Full.Container.Stations.Header.Back.MouseButton1Click:Connect(function()
	Main.SetPage(Main.GetLastMainPage())
end)

-- Full / Sidebar

function AssignClientInformation()
	Full.Content.Sidebar.User.Profile.Image = Utilities.GetPlayerThumbnail(client.UserId)
	Full.Content.Sidebar.User.Display.Text = client.DisplayName
end

AssignClientInformation()

Full.Content.Sidebar.User.More.MouseButton1Click:Connect(function()
	local OptionChosen = Main.PromptOptions({
		Options = {
			{Name = "Settings", Icon = "rbxassetid://11293977610"}
		}
	})

	if OptionChosen == "Settings" then
		LoadSettings()
	end
end)

-- Full & NowPlaying / Animations

for i, Actions in CollectionService:GetTagged("MastersMiniplayerAction") do
	if Actions:IsA("ImageButton") then

		Actions.MouseEnter:Connect(function()
			TweenService:Create(Actions.Icon.scale, normal, {Scale = 1.2}):Play()
			TweenService:Create(Actions.Selection, normal, {BackgroundTransparency = .95}):Play()
			TweenService:Create(Actions.Selection.scale, normal, {Scale = 1.1}):Play()
		end)

		Actions.MouseButton1Down:Connect(function()
			TweenService:Create(Actions.Icon.scale, normal, {Scale = .6}):Play()
			TweenService:Create(Actions.Selection, normal, {BackgroundTransparency = .95}):Play()
			TweenService:Create(Actions.Selection.scale, normal, {Scale = .9}):Play()
		end)

		Actions.InputEnded:Connect(function()
			TweenService:Create(Actions.Icon.scale, bounce, {Scale = 1}):Play()
			TweenService:Create(Actions.Selection, normal, {BackgroundTransparency = 1}):Play()
			TweenService:Create(Actions.Selection.scale, bounce, {Scale = 1}):Play()
		end)

	end
end

ui.DescendantAdded:Connect(function(Actions)
	if Actions:HasTag("MastersMiniplayerAction") then
		Actions.MouseEnter:Connect(function()
			TweenService:Create(Actions.Icon.scale, normal, {Scale = 1.2}):Play()
			TweenService:Create(Actions.Selection, normal, {BackgroundTransparency = .95}):Play()
			TweenService:Create(Actions.Selection.scale, normal, {Scale = 1.1}):Play()
		end)

		Actions.MouseButton1Down:Connect(function()
			TweenService:Create(Actions.Icon.scale, normal, {Scale = .6}):Play()
			TweenService:Create(Actions.Selection, normal, {BackgroundTransparency = .95}):Play()
			TweenService:Create(Actions.Selection.scale, normal, {Scale = .9}):Play()
		end)

		Actions.InputEnded:Connect(function()
			TweenService:Create(Actions.Icon.scale, bounce, {Scale = 1}):Play()
			TweenService:Create(Actions.Selection, normal, {BackgroundTransparency = 1}):Play()
			TweenService:Create(Actions.Selection.scale, bounce, {Scale = 1}):Play()
		end)
	end
end)

for i, PlaybackControl in CollectionService:GetTagged("MastersMiniplayerPlaybackControls") do
	if PlaybackControl:IsA("ImageButton") then

		PlaybackControl.MouseEnter:Connect(function()
			TweenService:Create(PlaybackControl.Icon.scale, normal, {Scale = 1.2}):Play()
			TweenService:Create(PlaybackControl.Selection, normal, {BackgroundTransparency = .95}):Play()
			TweenService:Create(PlaybackControl.Selection.scale, normal, {Scale = 1.1}):Play()
		end)

		PlaybackControl.MouseButton1Down:Connect(function()
			TweenService:Create(PlaybackControl.Icon.scale, normal, {Scale = .6}):Play()
			TweenService:Create(PlaybackControl.Selection, normal, {BackgroundTransparency = .95}):Play()
			TweenService:Create(PlaybackControl.Selection.scale, normal, {Scale = .9}):Play()
		end)

		PlaybackControl.InputEnded:Connect(function()
			TweenService:Create(PlaybackControl.Icon.scale, bounce, {Scale = 1}):Play()
			TweenService:Create(PlaybackControl.Selection, normal, {BackgroundTransparency = 1}):Play()
			TweenService:Create(PlaybackControl.Selection.scale, bounce, {Scale = 1}):Play()
		end)

	end
end

local MiniplayerPlaybackAnimations = {
	Forward = {
		Animating = false,
		State = 1,
		Triangles = {
			A = Full.Content.Miniplayer.Container.Playback.Forward.Icon.TriangleA,
			B = Full.Content.Miniplayer.Container.Playback.Forward.Icon.TriangleB,
			C = Full.Content.Miniplayer.Container.Playback.Forward.Icon.TriangleC,
		}
	},

	Rewind = {
		Animating = false,
		State = 1,
		Triangles = {
			A = Full.Content.Miniplayer.Container.Playback.Rewind.Icon.TriangleA,
			B = Full.Content.Miniplayer.Container.Playback.Rewind.Icon.TriangleB,
			C = Full.Content.Miniplayer.Container.Playback.Rewind.Icon.TriangleC,
		}
	},
}

Full.Content.Miniplayer.Container.Playback.Forward.MouseButton1Click:Connect(function()
	if MiniplayerPlaybackAnimations.Forward.Animating then return end
	MiniplayerPlaybackAnimations.Forward.Animating = true

	if MiniplayerPlaybackAnimations.Forward.State == 1 then
		MiniplayerPlaybackAnimations.Forward.State += 1

		TweenService:Create(MiniplayerPlaybackAnimations.Forward.Triangles.A, bounce, {ImageTransparency = 0}):Play()
		TweenService:Create(MiniplayerPlaybackAnimations.Forward.Triangles.A.scale, bounce, {Scale = 1}):Play()

		TweenService:Create(MiniplayerPlaybackAnimations.Forward.Triangles.C, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(MiniplayerPlaybackAnimations.Forward.Triangles.C.scale, normal, {Scale = 0}):Play()

		--
		task.wait(.5)
		--

		MiniplayerPlaybackAnimations.Forward.Triangles.A.LayoutOrder = 2
		MiniplayerPlaybackAnimations.Forward.Triangles.B.LayoutOrder = 3
		MiniplayerPlaybackAnimations.Forward.Triangles.C.LayoutOrder = 1

	elseif MiniplayerPlaybackAnimations.Forward.State == 2 then
		MiniplayerPlaybackAnimations.Forward.State += 1

		TweenService:Create(MiniplayerPlaybackAnimations.Forward.Triangles.C, bounce, {ImageTransparency = 0}):Play()
		TweenService:Create(MiniplayerPlaybackAnimations.Forward.Triangles.C.scale, bounce, {Scale = 1}):Play()

		TweenService:Create(MiniplayerPlaybackAnimations.Forward.Triangles.B, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(MiniplayerPlaybackAnimations.Forward.Triangles.B.scale, normal, {Scale = 0}):Play()

		--
		task.wait(.5)
		--

		MiniplayerPlaybackAnimations.Forward.Triangles.A.LayoutOrder = 3
		MiniplayerPlaybackAnimations.Forward.Triangles.B.LayoutOrder = 1
		MiniplayerPlaybackAnimations.Forward.Triangles.C.LayoutOrder = 2

	elseif MiniplayerPlaybackAnimations.Forward.State == 3 then
		MiniplayerPlaybackAnimations.Forward.State = 1

		TweenService:Create(MiniplayerPlaybackAnimations.Forward.Triangles.B, bounce, {ImageTransparency = 0}):Play()
		TweenService:Create(MiniplayerPlaybackAnimations.Forward.Triangles.B.scale, bounce, {Scale = 1}):Play()

		TweenService:Create(MiniplayerPlaybackAnimations.Forward.Triangles.A, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(MiniplayerPlaybackAnimations.Forward.Triangles.A.scale, normal, {Scale = 0}):Play()

		--
		task.wait(.5)
		--

		MiniplayerPlaybackAnimations.Forward.Triangles.A.LayoutOrder = 1
		MiniplayerPlaybackAnimations.Forward.Triangles.B.LayoutOrder = 2
		MiniplayerPlaybackAnimations.Forward.Triangles.C.LayoutOrder = 3
	end

	MiniplayerPlaybackAnimations.Forward.Animating = false
end)

Full.Content.Miniplayer.Container.Playback.Rewind.MouseButton1Click:Connect(function()
	if MiniplayerPlaybackAnimations.Rewind.Animating then return end
	MiniplayerPlaybackAnimations.Rewind.Animating = true

	if MiniplayerPlaybackAnimations.Rewind.State == 1 then
		MiniplayerPlaybackAnimations.Rewind.State += 1

		TweenService:Create(MiniplayerPlaybackAnimations.Rewind.Triangles.A, bounce, {ImageTransparency = 0}):Play()
		TweenService:Create(MiniplayerPlaybackAnimations.Rewind.Triangles.A.scale, bounce, {Scale = 1}):Play()

		TweenService:Create(MiniplayerPlaybackAnimations.Rewind.Triangles.C, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(MiniplayerPlaybackAnimations.Rewind.Triangles.C.scale, normal, {Scale = 0}):Play()

		--
		task.wait(.5)
		--

		MiniplayerPlaybackAnimations.Rewind.Triangles.A.LayoutOrder = 2
		MiniplayerPlaybackAnimations.Rewind.Triangles.B.LayoutOrder = 1
		MiniplayerPlaybackAnimations.Rewind.Triangles.C.LayoutOrder = 3

	elseif MiniplayerPlaybackAnimations.Rewind.State == 2 then
		MiniplayerPlaybackAnimations.Rewind.State += 1

		TweenService:Create(MiniplayerPlaybackAnimations.Rewind.Triangles.C, bounce, {ImageTransparency = 0}):Play()
		TweenService:Create(MiniplayerPlaybackAnimations.Rewind.Triangles.C.scale, bounce, {Scale = 1}):Play()

		TweenService:Create(MiniplayerPlaybackAnimations.Rewind.Triangles.B, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(MiniplayerPlaybackAnimations.Rewind.Triangles.B.scale, normal, {Scale = 0}):Play()

		--
		task.wait(.5)
		--

		MiniplayerPlaybackAnimations.Rewind.Triangles.A.LayoutOrder = 1
		MiniplayerPlaybackAnimations.Rewind.Triangles.B.LayoutOrder = 3
		MiniplayerPlaybackAnimations.Rewind.Triangles.C.LayoutOrder = 2

	elseif MiniplayerPlaybackAnimations.Rewind.State == 3 then
		MiniplayerPlaybackAnimations.Rewind.State = 1

		TweenService:Create(MiniplayerPlaybackAnimations.Rewind.Triangles.B, bounce, {ImageTransparency = 0}):Play()
		TweenService:Create(MiniplayerPlaybackAnimations.Rewind.Triangles.B.scale, bounce, {Scale = 1}):Play()

		TweenService:Create(MiniplayerPlaybackAnimations.Rewind.Triangles.A, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(MiniplayerPlaybackAnimations.Rewind.Triangles.A.scale, normal, {Scale = 0}):Play()

		--
		task.wait(.5)
		--

		MiniplayerPlaybackAnimations.Rewind.Triangles.A.LayoutOrder = 3
		MiniplayerPlaybackAnimations.Rewind.Triangles.B.LayoutOrder = 2
		MiniplayerPlaybackAnimations.Rewind.Triangles.C.LayoutOrder = 1
	end

	MiniplayerPlaybackAnimations.Rewind.Animating = false
end)

local NowPlayingPlaybackAnimations = {
	Forward = {
		Animating = false,
		State = 1,
		Triangles = {
			A = NowPlaying.Content.Media.Playback.Forward.Icon.TriangleA,
			B = NowPlaying.Content.Media.Playback.Forward.Icon.TriangleB,
			C = NowPlaying.Content.Media.Playback.Forward.Icon.TriangleC,
		}
	},

	Rewind = {
		Animating = false,
		State = 1,
		Triangles = {
			A = NowPlaying.Content.Media.Playback.Rewind.Icon.TriangleA,
			B = NowPlaying.Content.Media.Playback.Rewind.Icon.TriangleB,
			C = NowPlaying.Content.Media.Playback.Rewind.Icon.TriangleC,
		}
	},
}

NowPlaying.Content.Media.Playback.Forward.MouseButton1Click:Connect(function()
	if NowPlayingPlaybackAnimations.Forward.Animating then return end
	NowPlayingPlaybackAnimations.Forward.Animating = true

	if NowPlayingPlaybackAnimations.Forward.State == 1 then
		NowPlayingPlaybackAnimations.Forward.State += 1

		TweenService:Create(NowPlayingPlaybackAnimations.Forward.Triangles.A, bounce, {ImageTransparency = 0}):Play()
		TweenService:Create(NowPlayingPlaybackAnimations.Forward.Triangles.A.scale, bounce, {Scale = 1}):Play()

		TweenService:Create(NowPlayingPlaybackAnimations.Forward.Triangles.C, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(NowPlayingPlaybackAnimations.Forward.Triangles.C.scale, normal, {Scale = 0}):Play()

		--
		task.wait(.5)
		--

		NowPlayingPlaybackAnimations.Forward.Triangles.A.LayoutOrder = 2
		NowPlayingPlaybackAnimations.Forward.Triangles.B.LayoutOrder = 3
		NowPlayingPlaybackAnimations.Forward.Triangles.C.LayoutOrder = 1

	elseif NowPlayingPlaybackAnimations.Forward.State == 2 then
		NowPlayingPlaybackAnimations.Forward.State += 1

		TweenService:Create(NowPlayingPlaybackAnimations.Forward.Triangles.C, bounce, {ImageTransparency = 0}):Play()
		TweenService:Create(NowPlayingPlaybackAnimations.Forward.Triangles.C.scale, bounce, {Scale = 1}):Play()

		TweenService:Create(NowPlayingPlaybackAnimations.Forward.Triangles.B, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(NowPlayingPlaybackAnimations.Forward.Triangles.B.scale, normal, {Scale = 0}):Play()

		--
		task.wait(.5)
		--

		NowPlayingPlaybackAnimations.Forward.Triangles.A.LayoutOrder = 3
		NowPlayingPlaybackAnimations.Forward.Triangles.B.LayoutOrder = 1
		NowPlayingPlaybackAnimations.Forward.Triangles.C.LayoutOrder = 2

	elseif NowPlayingPlaybackAnimations.Forward.State == 3 then
		NowPlayingPlaybackAnimations.Forward.State = 1

		TweenService:Create(NowPlayingPlaybackAnimations.Forward.Triangles.B, bounce, {ImageTransparency = 0}):Play()
		TweenService:Create(NowPlayingPlaybackAnimations.Forward.Triangles.B.scale, bounce, {Scale = 1}):Play()

		TweenService:Create(NowPlayingPlaybackAnimations.Forward.Triangles.A, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(NowPlayingPlaybackAnimations.Forward.Triangles.A.scale, normal, {Scale = 0}):Play()

		--
		task.wait(.5)
		--

		NowPlayingPlaybackAnimations.Forward.Triangles.A.LayoutOrder = 1
		NowPlayingPlaybackAnimations.Forward.Triangles.B.LayoutOrder = 2
		NowPlayingPlaybackAnimations.Forward.Triangles.C.LayoutOrder = 3
	end

	NowPlayingPlaybackAnimations.Forward.Animating = false
end)

NowPlaying.Content.Media.Playback.Rewind.MouseButton1Click:Connect(function()
	if NowPlayingPlaybackAnimations.Rewind.Animating then return end
	NowPlayingPlaybackAnimations.Rewind.Animating = true

	if NowPlayingPlaybackAnimations.Rewind.State == 1 then
		NowPlayingPlaybackAnimations.Rewind.State += 1

		TweenService:Create(NowPlayingPlaybackAnimations.Rewind.Triangles.A, bounce, {ImageTransparency = 0}):Play()
		TweenService:Create(NowPlayingPlaybackAnimations.Rewind.Triangles.A.scale, bounce, {Scale = 1}):Play()

		TweenService:Create(NowPlayingPlaybackAnimations.Rewind.Triangles.C, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(NowPlayingPlaybackAnimations.Rewind.Triangles.C.scale, normal, {Scale = 0}):Play()

		--
		task.wait(.5)
		--

		NowPlayingPlaybackAnimations.Rewind.Triangles.A.LayoutOrder = 2
		NowPlayingPlaybackAnimations.Rewind.Triangles.B.LayoutOrder = 1
		NowPlayingPlaybackAnimations.Rewind.Triangles.C.LayoutOrder = 3

	elseif NowPlayingPlaybackAnimations.Rewind.State == 2 then
		NowPlayingPlaybackAnimations.Rewind.State += 1

		TweenService:Create(NowPlayingPlaybackAnimations.Rewind.Triangles.C, bounce, {ImageTransparency = 0}):Play()
		TweenService:Create(NowPlayingPlaybackAnimations.Rewind.Triangles.C.scale, bounce, {Scale = 1}):Play()

		TweenService:Create(NowPlayingPlaybackAnimations.Rewind.Triangles.B, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(NowPlayingPlaybackAnimations.Rewind.Triangles.B.scale, normal, {Scale = 0}):Play()

		--
		task.wait(.5)
		--

		NowPlayingPlaybackAnimations.Rewind.Triangles.A.LayoutOrder = 1
		NowPlayingPlaybackAnimations.Rewind.Triangles.B.LayoutOrder = 3
		NowPlayingPlaybackAnimations.Rewind.Triangles.C.LayoutOrder = 2

	elseif NowPlayingPlaybackAnimations.Rewind.State == 3 then
		NowPlayingPlaybackAnimations.Rewind.State = 1

		TweenService:Create(NowPlayingPlaybackAnimations.Rewind.Triangles.B, bounce, {ImageTransparency = 0}):Play()
		TweenService:Create(NowPlayingPlaybackAnimations.Rewind.Triangles.B.scale, bounce, {Scale = 1}):Play()

		TweenService:Create(NowPlayingPlaybackAnimations.Rewind.Triangles.A, normal, {ImageTransparency = 1}):Play()
		TweenService:Create(NowPlayingPlaybackAnimations.Rewind.Triangles.A.scale, normal, {Scale = 0}):Play()

		--
		task.wait(.5)
		--

		NowPlayingPlaybackAnimations.Rewind.Triangles.A.LayoutOrder = 3
		NowPlayingPlaybackAnimations.Rewind.Triangles.B.LayoutOrder = 2
		NowPlayingPlaybackAnimations.Rewind.Triangles.C.LayoutOrder = 1
	end

	NowPlayingPlaybackAnimations.Rewind.Animating = false
end)

-- PlaylistCreation

PlaylistCreation.Header.Create.MouseButton1Click:Connect(function()
	if PlaylistCreation:GetAttribute("Title") == "" then
		Alerts.BannerNotify({
			Header = "Missing Fields",
			Description = "There are some fields left that you need to fill out.",
			Icon = "rbxassetid://11432842812"
		})

		return
	end

	if not PlaylistCreation.Cover.Custom.IsLoaded then
		Alerts.BannerNotify({
			Header = "Not Loading",
			Description = "The provided playlist cover is not loading.",
			Icon = "rbxassetid://11419713569"
		})

		return
	end

	if PlaylistPageProperties.FilteringTitle then
		Alerts.BannerNotify({
			Header = "Filtering Text",
			Description = "Your playlist title is still being filtered.",
			Icon = "rbxassetid://11419713569"
		})

		return
	end

	local Success, Result = events.Main.Library.CreatePlaylist:InvokeServer({
		Name = PlaylistCreation:GetAttribute("Title"),
		Cover = PlaylistCreation:GetAttribute("Cover"),
	})

	if Success then
		Main.PlaylistCreation(false)
		Main.PlaylistCreationClosed:Fire(Result)

		if PlaylistPageProperties.ToAdd ~= 0 then
			callback_SongPlaylist(1, PlaylistPageProperties.ToAdd, Result)
		end

		LoadPlaylist(Result)

	else
		if Result == "limit" then
			Alerts.BannerNotify({
				Header = ".",
				Description = "You have exceeded the maximum of 30 playlists.",
				Icon = "rbxassetid://11419709766"
			})
		end
	end
end)

PlaylistCreation.Header.Cancel.MouseButton1Click:Connect(function()
	PlaylistPageProperties.ToAdd = 0

	Main.PlaylistCreation(false)
	Main.PlaylistCreationClosed:Fire()
end)

-- PlaylistCreation / Cover

PlaylistCreation:GetAttributeChangedSignal("Cover"):Connect(function()
	PlaylistCreation.Info.Cover.AssetId.Field.Text = PlaylistCreation:GetAttribute("Cover")
end)

PlaylistCreation.Info.Title.Field:GetPropertyChangedSignal("Text"):Connect(function()
	PlaylistCreation.Info.Title.Count.Text = string.len(PlaylistCreation.Info.Title.Field.Text) .. "/30"
end)

PlaylistCreation.Info.Title.Field.FocusLost:Connect(function()
	PlaylistPageProperties.FilteringTitle = true

	local Trimmed = Utilities.TrimString(PlaylistCreation.Info.Title.Field.Text, 30)
	local Final = TextFiltering.FilterBroadcast(Trimmed, client.UserId)

	PlaylistPageProperties.FilteringTitle = false

	PlaylistCreation.Info.Title.Field.Text = Final
	PlaylistCreation:SetAttribute("Title", Final)
end)

PlaylistCreation.Info.Cover.AssetId.Field.FocusLost:Connect(function()
	local AssetId = PlaylistCreation.Info.Cover.AssetId.Field.Text

	if tonumber(AssetId) then
		AssetId = "rbxassetid://" .. AssetId
	end

	PlaylistCreation.Cover.Custom.Image = AssetId
	PlaylistCreation:SetAttribute("Cover", AssetId)
end)

PlaylistCreation.Cover.Custom:GetPropertyChangedSignal("IsLoaded"):Connect(function()
	if PlaylistCreation.Cover.Custom.IsLoaded then
		TweenService:Create(PlaylistCreation.Cover.Custom.Loading, normal, {ImageTransparency = 1}):Play()
	else
		TweenService:Create(PlaylistCreation.Cover.Custom.Loading, normal, {ImageTransparency = .5}):Play()
	end
end)

-- SettingsPage
-- SettingsPage / Playback
-- SettingsPage / Playback / Crossfade

local CrossfadeDurationTimeline = SettingsPage.Scroll.Playback.Container.Crossfade.Duration.Timeline
local CrossfadeDurationScrubber = SettingsPage.Scroll.Playback.Container.Crossfade.Duration.Timeline.Scrubber

local function UpdateCrossfadeDurationScrubber(input)
	local DeltaX = input.Position.X - CrossfadeDurationScrubberData.StartPos
	local DeltaScale = DeltaX / CrossfadeDurationScrubber.AbsoluteSize.X
	local NewScale = math.clamp(CrossfadeDurationScrubberData.StartScale + DeltaScale, 0, 1)

	CrossfadeDurationScrubber.Fill.Size = UDim2.fromScale(NewScale, 1)

	local NewDuration = Utilities.Map(NewScale, 0, 1, 1, 10)

	SettingsPageProperties.Data.Playback.Crossfade.Duration = NewDuration
end

SettingsPage.Scroll.Playback.Container.Crossfade.Enabled.MouseButton1Click:Connect(function()
	if SettingsPageProperties.LoadingSettings then return end
	if not SettingsPageProperties.Data then return end

	if SettingsPageProperties.Data.Playback.Crossfade.Enabled then
		SettingsPageProperties.Data.Playback.Crossfade.Enabled = false

		Utilities.SwitchToggle(SettingsPage.Scroll.Playback.Container.Crossfade.Enabled.Switch, false)

		SettingsPage.Scroll.Playback.Container.Crossfade.Duration.Visible = false
	else
		SettingsPageProperties.Data.Playback.Crossfade.Enabled = true

		Utilities.SwitchToggle(SettingsPage.Scroll.Playback.Container.Crossfade.Enabled.Switch, true)

		SettingsPage.Scroll.Playback.Container.Crossfade.Duration.Visible = true
	end

	SettingsPageProperties.Changed:Fire(SettingsPageProperties.Data)
end)

CrossfadeDurationScrubber.InputBegan:Connect(function(input)
	if SettingsPageProperties.LoadingSettings then return end
	if not SettingsPageProperties.Data then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		CrossfadeDurationScrubberData.Dragging = true
		CrossfadeDurationScrubberData.StartPos = input.Position.X
		CrossfadeDurationScrubberData.StartScale = CrossfadeDurationScrubber.Fill.Size.X.Scale

		TweenService:Create(CrossfadeDurationTimeline, normal, {Size = UDim2.new(1, 0, 0, 40)}):Play()
		TweenService:Create(CrossfadeDurationScrubber, normal, {
			GroupTransparency = 0,
			Size = UDim2.new(1, 0, 0, 12)}):Play()

		TweenService:Create(CrossfadeDurationTimeline.Data.Max, normal, {TextTransparency = 0}):Play()
		TweenService:Create(CrossfadeDurationTimeline.Data.Min, normal, {TextTransparency = 0}):Play()
	end
end)

InputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		if CrossfadeDurationScrubberData.Dragging then
			CrossfadeDurationScrubberData.Dragging = false

			SettingsPageProperties.Changed:Fire(SettingsPageProperties.Data)

			--

			TweenService:Create(CrossfadeDurationTimeline, normal, {Size = UDim2.new(1, 0, 0, 30)}):Play()
			TweenService:Create(CrossfadeDurationScrubber, normal, {
				GroupTransparency = .5,
				Size = UDim2.new(1, 0, 0, 6)}):Play()

			TweenService:Create(CrossfadeDurationTimeline.Data.Max, normal, {TextTransparency = .5}):Play()
			TweenService:Create(CrossfadeDurationTimeline.Data.Min, normal, {TextTransparency = .5}):Play()
		end
	end
end)

InputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or
		input.UserInputType == Enum.UserInputType.Touch then

		if CrossfadeDurationScrubberData.Dragging then
			UpdateCrossfadeDurationScrubber(input)
		end
	end
end)

-- SettingsPage / Playback / Equalizer

SettingsPage.Scroll.Playback.Container.Equalizer.Enabled.MouseButton1Click:Connect(function()
	if SettingsPageProperties.LoadingSettings then return end
	if not SettingsPageProperties.Data then return end

	if SettingsPageProperties.Data.Playback.Equalizer.Enabled then
		SettingsPageProperties.Data.Playback.Equalizer.Enabled = false

		Utilities.SwitchToggle(SettingsPage.Scroll.Playback.Container.Equalizer.Enabled.Switch, false)

		SettingsPage.Scroll.Playback.Container.Equalizer.LowGain.Visible = false
		SettingsPage.Scroll.Playback.Container.Equalizer.MiddleGain.Visible = false
		SettingsPage.Scroll.Playback.Container.Equalizer.HighGain.Visible = false
	else
		SettingsPageProperties.Data.Playback.Equalizer.Enabled = true

		Utilities.SwitchToggle(SettingsPage.Scroll.Playback.Container.Equalizer.Enabled.Switch, true)

		SettingsPage.Scroll.Playback.Container.Equalizer.LowGain.Visible = true
		SettingsPage.Scroll.Playback.Container.Equalizer.MiddleGain.Visible = true
		SettingsPage.Scroll.Playback.Container.Equalizer.HighGain.Visible = true
	end

	SettingsPageProperties.Changed:Fire(SettingsPageProperties.Data)
end)

SettingsPage.Scroll.Playback.Container.Equalizer.LowGain.Value.FocusLost:Connect(function(entered)
	if not entered then return end
	if SettingsPageProperties.LoadingSettings then return end
	if not SettingsPageProperties.Data then return end

	local Value = tonumber(SettingsPage.Scroll.Playback.Container.Equalizer.LowGain.Value.Text)

	if Value then
		if Value > 10 then
			Value = 10
		elseif Value < -80 then
			Value = -80
		end
	else
		Value = SettingsPageProperties.Data.Playback.Equalizer.LowGain
	end

	SettingsPage.Scroll.Playback.Container.Equalizer.LowGain.Value.Text = Value

	SettingsPageProperties.Data.Playback.Equalizer.LowGain = Value
	SettingsPageProperties.Changed:Fire(SettingsPageProperties.Data)
end)

SettingsPage.Scroll.Playback.Container.Equalizer.MiddleGain.Value.FocusLost:Connect(function(entered)
	if not entered then return end
	if SettingsPageProperties.LoadingSettings then return end
	if not SettingsPageProperties.Data then return end

	local Value = tonumber(SettingsPage.Scroll.Playback.Container.Equalizer.MiddleGain.Value.Text)

	if Value then
		if Value > 10 then
			Value = 10
		elseif Value < -80 then
			Value = -80
		end
	else
		Value = SettingsPageProperties.Data.Playback.Equalizer.MidGain
	end

	SettingsPage.Scroll.Playback.Container.Equalizer.MiddleGain.Value.Text = Value

	SettingsPageProperties.Data.Playback.Equalizer.MidGain = Value
	SettingsPageProperties.Changed:Fire(SettingsPageProperties.Data)
end)

SettingsPage.Scroll.Playback.Container.Equalizer.HighGain.Value.FocusLost:Connect(function(entered)
	if not entered then return end
	if SettingsPageProperties.LoadingSettings then return end
	if not SettingsPageProperties.Data then return end

	local Value = tonumber(SettingsPage.Scroll.Playback.Container.Equalizer.HighGain.Value.Text)

	if Value then
		if Value > 10 then
			Value = 10
		elseif Value < -80 then
			Value = -80
		end
	else
		Value = SettingsPageProperties.Data.Playback.Equalizer.HighGain
	end

	SettingsPage.Scroll.Playback.Container.Equalizer.HighGain.Value.Text = Value

	SettingsPageProperties.Data.Playback.Equalizer.HighGain = Value
	SettingsPageProperties.Changed:Fire(SettingsPageProperties.Data)
end)

-- SettingsPage / Extras

SettingsPage.Scroll.Extras.Container.Glow.MouseButton1Click:Connect(function()
	if SettingsPageProperties.LoadingSettings then return end
	if not SettingsPageProperties.Data then return end

	local NewValue = not SettingsPageProperties.Data.Extras.Glow

	if SettingsPageProperties.Data.Extras.Glow then
		Utilities.SwitchToggle(SettingsPage.Scroll.Extras.Container.Glow.Switch, false)

		SettingsPageProperties.Data.Extras.Glow = false
	else
		Utilities.SwitchToggle(SettingsPage.Scroll.Extras.Container.Glow.Switch, true)

		SettingsPageProperties.Data.Extras.Glow = true
	end

	SettingsPageProperties.Changed:Fire(SettingsPageProperties.Data)
end)

SettingsPage.Scroll.Extras.Container.PlaybackHaptics.MouseButton1Click:Connect(function()
	if SettingsPageProperties.LoadingSettings then return end
	if not SettingsPageProperties.Data then return end

	if SettingsPageProperties.Data.Extras.PlaybackHaptics then
		Utilities.SwitchToggle(SettingsPage.Scroll.Extras.Container.PlaybackHaptics.Switch, false)

		SettingsPageProperties.Data.Extras.PlaybackHaptics = false
	else
		Utilities.SwitchToggle(SettingsPage.Scroll.Extras.Container.PlaybackHaptics.Switch, true)

		SettingsPageProperties.Data.Extras.PlaybackHaptics = true
	end

	SettingsPageProperties.Changed:Fire(SettingsPageProperties.Data)
end)

-- SettingsPage / Socials

SettingsPage.Scroll.Socials.Container.Sharing.MouseButton1Click:Connect(function()
	if SettingsPageProperties.LoadingSettings then return end
	if not SettingsPageProperties.Data then return end

	local NewValue = not SettingsPageProperties.Data.Socials.Sharing

	if SettingsPageProperties.Data.Socials.Sharing then
		Utilities.SwitchToggle(SettingsPage.Scroll.Socials.Container.Sharing.Switch, false)

		SettingsPageProperties.Data.Socials.Sharing = false
	else
		Utilities.SwitchToggle(SettingsPage.Scroll.Socials.Container.Sharing.Switch, true)

		SettingsPageProperties.Data.Socials.Sharing = true
	end

	SettingsPageProperties.Changed:Fire(SettingsPageProperties.Data)
end)

SettingsPage.Scroll.Socials.Container.ListeningVisibility.MouseButton1Click:Connect(function()
	if SettingsPageProperties.LoadingSettings then return end
	if not SettingsPageProperties.Data then return end

	if SettingsPageProperties.Data.Socials.ListeningVisibility then
		Utilities.SwitchToggle(SettingsPage.Scroll.Socials.Container.ListeningVisibility.Switch, false)

		SettingsPageProperties.Data.Socials.ListeningVisibility = false
	else
		Utilities.SwitchToggle(SettingsPage.Scroll.Socials.Container.ListeningVisibility.Switch, true)

		SettingsPageProperties.Data.Socials.ListeningVisibility = true
	end

	SettingsPageProperties.Changed:Fire(SettingsPageProperties.Data)
end)

-- SettingsPage / Changed

function ApplySettingChanges()
	if SettingsPageProperties.LoadingSettings then return end
	if not SettingsPageProperties.Data then return end

	Playback.Equalizer.Enabled = SettingsPageProperties.Data.Playback.Equalizer.Enabled

	Playback.Equalizer.HighGain = SettingsPageProperties.Data.Playback.Equalizer.HighGain
	Playback.Equalizer.MidGain = SettingsPageProperties.Data.Playback.Equalizer.MidGain
	Playback.Equalizer.LowGain = SettingsPageProperties.Data.Playback.Equalizer.LowGain
end

SettingsPageProperties.Changed:Connect(function(Data)
	print(Data)
	SettingsPageProperties.HasChanged = true

	ApplySettingChanges()

	if Data.Socials.ListeningVisibility then
		LoadListeners()
	end
end)

SettingsPage.Header.Back.MouseButton1Click:Connect(function()
	Main.Settings(false)

	if SettingsPageProperties.HasChanged then
		SettingsPageProperties.HasChanged = false
		events.Main.Settings.SetSettings:FireServer(SettingsPageProperties.Data)
	end
end)

-- ShareSheet

function ShareSheetSeachKeyword(Keyword, SetVisibility)
	local Container = ShareSheet.MainFrame.Frame.Container.Players 
	local isCleaningUp = (Keyword == "" or Keyword:match("^%s*$"))
	local CleanKeyword = Keyword:lower()

	for _, Item in Container:GetChildren() do
		if not Item:IsA("ImageButton") and not Item:HasTag("MastersTemplate") then continue end
		if not Item:GetAttribute("OriginalLayoutOrder") then
			Item:SetAttribute("OriginalLayoutOrder", Item.LayoutOrder)
		end

		local Variable = {Item.Name, Item.Display.Text, Item.Username.Text} 
		local CombinedKeywords = table.concat(Variable, " "):lower()

		if isCleaningUp then
			Item.Visible = true
			Item.LayoutOrder = Item:GetAttribute("OriginalLayoutOrder") or 1
		else
			local matchFound = string.find(CombinedKeywords, CleanKeyword, 1, true) ~= nil

			if SetVisibility then
				Item.Visible = matchFound 
			else
				if matchFound then
					local startPos = string.find(CombinedKeywords, CleanKeyword, 1, true)
					Item.LayoutOrder = startPos
				else
					Item.LayoutOrder = 9999 
				end
			end
		end
	end
end

ShareSheet.MainFrame.Frame.Container.Search.Field.TextBox.FocusLost:Connect(function()
	local Keyword = ShareSheet.MainFrame.Frame.Container.Search.Field.TextBox.Text

	ShareSheetSeachKeyword(Keyword, true)

	local Success, UserId = pcall(function()
		return Players:GetUserIdFromNameAsync(Keyword)
	end)

	if not Success then return end

	for i, Player in Players:GetPlayers() do
		if Player.UserId == UserId then
			return
		end
	end

	local Username = Players:GetNameFromUserIdAsync(UserId)
	local OfflineItem = ShareSheet.MainFrame.Frame.Container.Players.OfflineItem

	OfflineItem:SetAttribute("UserId", UserId)
	OfflineItem.Photo.Image = Utilities.GetPlayerThumbnail(UserId)
	OfflineItem.Display.Text = "@" .. Username
	OfflineItem.Username.Text = ""
	OfflineItem.Visible = true
end)

ShareSheet.MainFrame.Frame.Container.Search.Field.TextBox.Focused:Connect(function()
	ShareSheetSeachKeyword("", true)

	ShareSheet.MainFrame.Frame.Container.Players.OfflineItem.Visible = false
end)

-- Events
-- Events / Playback

events.Playback.PlayPause.Event:Connect(function()
	local CurrentSound = Queue.GetActiveSound()

	if CurrentSound then
		if CurrentSound.IsPlaying then
			Queue.Pause()
		else
			Queue.Resume()
		end
	end
end)

events.Playback.Forward.Event:Connect(function()
	Queue.Next()
end)

events.Playback.Rewind.Event:Connect(function()
	Queue.Previous()
end)

-- Events / Modules / Listeners

events.Modules.Listeners.GetCurrentTimestamp.OnClientInvoke = function(SoundId)
	local CurrentSoundId = Queue.GetCurrentSongId()

	if not CurrentSoundId then return end
	if SoundId ~= CurrentSoundId then return end
	if Queue.GetLoadingStatus() or Queue.GetCrossfadingStatus() then return end

	local ActiveSoundObject = Queue.GetActiveSound()
	if not ActiveSoundObject then return end

	return ActiveSoundObject.TimePosition
end

-- Throbber

for i, Icon in CollectionService:GetTagged("MastersThrobberIcon") do
	TweenService:Create(Icon, loop, {Rotation = 360}):Play()
end

ui.DescendantAdded:Connect(function(Object)
	if Object:HasTag("MastersThrobberIcon") then
		TweenService:Create(Object, loop, {Rotation = 360}):Play()
	end
end)

-- Click To Focus

for i, Field in CollectionService:GetTagged("MastersClickToFocus") do
	if Field:IsA("ImageButton") then

		Field.MouseButton1Click:Connect(function()
			Field.Value.Interactable = true
			Field.Value:CaptureFocus()

			Field.Value.SelectionStart = 0
			Field.Value.CursorPosition = string.len(Field.Value.Text) + 1
		end)

		Field.Value.FocusLost:Connect(function()
			Field.Value.Interactable = false
		end)

	end
end

-- Horizontal Containers

local TWEEN_TIME = .1
local MOVE_STEP = 80

local function NavigateHorizontalContainer(Container)
	local Content = Container:WaitForChild("Content")
	local Nav = Container.Util.Navigation
	local LeftBtn = Nav.Left
	local RightBtn = Nav.Right

	local isHoldingLeft = false
	local isHoldingRight = false

	local function UpdateButtons()
		local currentX = Content.CanvasPosition.X
		local maxScroll = Content.AbsoluteCanvasSize.X - Content.AbsoluteWindowSize.X

		LeftBtn.Visible = currentX > 1
		RightBtn.Visible = maxScroll > 0 and currentX < (maxScroll - 1)
	end

	task.defer(UpdateButtons)

	Content:GetPropertyChangedSignal("CanvasPosition"):Connect(UpdateButtons)

	local Layout = Content:FindFirstChildWhichIsA("UILayout")
	
	if Layout then
		Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateButtons)
	end

	LeftBtn.Button.MouseButton1Down:Connect(function()
		isHoldingLeft = true
		
		while isHoldingLeft do
			local targetX = math.max(0, Content.CanvasPosition.X - MOVE_STEP)
			TweenService:Create(Content, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Linear), {
				CanvasPosition = Vector2.new(targetX, 0)
			}):Play()
			task.wait(TWEEN_TIME)
			if targetX <= 0 then break end
		end
	end)
	
	RightBtn.Button.MouseButton1Down:Connect(function()
		isHoldingRight = true
		
		while isHoldingRight do
			local maxScroll = Content.AbsoluteCanvasSize.X - Content.AbsoluteWindowSize.X
			local targetX = math.min(maxScroll, Content.CanvasPosition.X + MOVE_STEP)

			TweenService:Create(Content, TweenInfo.new(TWEEN_TIME, Enum.EasingStyle.Linear), {
				CanvasPosition = Vector2.new(targetX, 0)
			}):Play()
			
			task.wait(TWEEN_TIME)
			if targetX >= maxScroll then break end
		end
	end)

	local function stop() isHoldingLeft = false; isHoldingRight = false end
	
	LeftBtn.Button.InputEnded:Connect(stop)
	RightBtn.Button.InputEnded:Connect(stop)
end

for _, Container in CollectionService:GetTagged("MastersHorizontalContainer") do
	NavigateHorizontalContainer(Container)
end

ui.DescendantAdded:Connect(function(descendant)
	if descendant:HasTag("MastersHorizontalContainer") then
		NavigateHorizontalContainer(descendant)
	end
end)
-- Session Saving

local LastSessionLoaded = false

local function LoadLastSession()
	local LastSavedSession = events.Main.SessionSaving.FetchSavedSession:InvokeServer()
	if not LastSavedSession then return end

	Playback.Volume = LastSavedSession.Volume
	ApplyNewVolume(LastSavedSession.Volume)

	if LastSavedSession.Repeat == "Song" then
		Queue.ToggleRepeat()
	end

	if LastSavedSession.Shuffle then
		Queue.ToggleShuffle()
	end

	LastSessionLoaded = true
end

local function SaveCurrentSession()
	if not LastSessionLoaded then return end

	local Sound = Queue.GetActiveSound()
	local TimePos = 0

	if Sound and not Queue.GetLoadingStatus() and not Queue.GetCrossfadingStatus() then
		TimePos = Sound.TimePosition
	end

	events.Main.SessionSaving.SetPlaybackState:FireServer({
		Volume = Playback.Volume,
		Repeat = Queue.GetSettings().RepeatMode,
		Shuffle = Queue.GetSettings().Shuffle,
	})
end

LoadLastSession()
AutostartStation()

Players.PlayerRemoving:Connect(function(Player)
	if Player == client then
		SaveCurrentSession()
	end
end)