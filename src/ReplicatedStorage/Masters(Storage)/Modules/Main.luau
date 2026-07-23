local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local InputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local nan = TweenInfo.new(.001)
local quick = TweenInfo.new(.25, Enum.EasingStyle.Exponential)
local normal = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local smooth = TweenInfo.new(.8, Enum.EasingStyle.Exponential)
local slow = TweenInfo.new(1, Enum.EasingStyle.Exponential)
local five = TweenInfo.new(5, Enum.EasingStyle.Exponential)

local bounce = TweenInfo.new(.5, Enum.EasingStyle.Back)
local elastic = TweenInfo.new(1, Enum.EasingStyle.Back)

local client = Players.LocalPlayer
local cam = workspace.CurrentCamera
local viewport = cam.ViewportSize

local storage = ReplicatedStorage:WaitForChild("Masters(Storage)")
local events = storage.Events
local modules = storage.Modules

local Signal = require(modules.Signal)
local Utilities = require(modules.Utilities)

local ui = client.PlayerGui:WaitForChild("Masters")
local context_menu = ui.ContextMenu

local ShareSheet = ui.ShareSheet

local frame = ui.Interface.Frame

local Bar = frame.Bar
local Full = frame.Full

local NowPlaying = Full.NowPlaying
local PlaylistCreation = Full.PlaylistCreation
local Settings = Full.Settings

local SizeIndex = {
	Bar = UDim2.fromOffset(300, 120),
	Full = UDim2.fromOffset(800, 450)
}

local LastPos = UDim2.fromScale(.5, .5)

local Status = {
	SettingState = false,
	CurrentOrientation = false,
	NowPlayingPanelScreen = "QueueList",
	PreparedForDisplay = false,
	LastMainPage = "Discovery",
	CurrentPage = "Discovery",
	Fullscreen = false,
	Sidebar = true,
	SidebarFullscreen = false,
}

local module = {}

-- Types

export type MastersOrientation = "Portrait" | "Landscape"
export type MastersNowPlayingPanelScreen = "Lyrics" | "QueueList" | "Listeners"
export type MastersState = "Bar" | "Full"
export type MastersPage = "Discovery" | "Search" | "Library" | "Playlist" | "Expanded" | "Artist" | "Details" | "Main" | "Stations"

export type MastersContextMenu = {
	Header: string?,
	Options: any,
	Mobile: boolean?,
}

export type MastersShareSheetInfo = {
	Icon: string?,
	Title: string,
	Subtext: string?,
	External: boolean?
}

-- Events

module.StateChanged = Signal.new()
module.PageChanged = Signal.new()
module.OrientationChanged = Signal.new()
module.PreparenessChanged = Signal.new()
module.PlaylistCreationClosed = Signal.new()

-- Functions

function module.GetState(): MastersState
	return ui.Interface:GetAttribute("State")
end

function module.IsFullscreen(): boolean
	return Status.Fullscreen
end

function module.GetSidebarStatus(): boolean
	return Status.Sidebar, Status.SidebarFullscreen
end


function module.GetOrientation(): MastersOrientation
	if cam.ViewportSize.X > cam.ViewportSize.Y then
		return "Landscape"
		
	elseif cam.ViewportSize.X <= cam.ViewportSize.Y then
		return "Portrait"
	end
end

function module.GetCurrentPage(): MastersPage
	return Status.CurrentPage
end

function module.SetLastPosition(Pos: UDim2)
	LastPos = Pos
end

function SetContentLibrary(State)
	Full.Container.Visible = State
end

function module.Fullscreen(State)
	Status.Fullscreen = State
	
	if State then		
		local InsetY = GuiService.TopbarInset.Height
		TweenService:Create(ui.Interface, smooth, {Size = UDim2.fromScale(1, 1)}):Play()
		
		TweenService:Create(frame.Full.Content.Actions, smooth, {Position = UDim2.new(0, 0, 0, InsetY)}):Play()
		TweenService:Create(frame.Full.Content.Sidebar.padding, smooth, {PaddingTop = UDim.new(0, InsetY)}):Play()
		
		TweenService:Create(frame.Full.Container.padding, smooth, {PaddingTop = UDim.new(0, InsetY)}):Play()
		TweenService:Create(frame.Full.NowPlaying.Content.Panel.padding, smooth, {PaddingTop = UDim.new(0, InsetY)}):Play()
		TweenService:Create(frame.Full.PlaylistCreation.padding, smooth, {PaddingTop = UDim.new(0, InsetY)}):Play()
		TweenService:Create(frame.Full.Settings.padding, smooth, {PaddingTop = UDim.new(0, InsetY)}):Play()

		TweenService:Create(frame.Full.Util.Visual, smooth, {Size = UDim2.fromScale(2, 2)}):Play()
		TweenService:Create(frame.Full.Util.Visual.corner, smooth, {CornerRadius = UDim.new(0, 0)}):Play()
		
		TweenService:Create(frame.Full.Util.ArtistBackground.corner, smooth, {CornerRadius = UDim.new(0, 0)}):Play()
		TweenService:Create(frame.Full.Util.DetailsBackground.corner, smooth, {CornerRadius = UDim.new(0, 0)}):Play()
		TweenService:Create(frame.Full.Util.HoverBackground.corner, smooth, {CornerRadius = UDim.new(0, 0)}):Play()
		TweenService:Create(frame.Full.Util.PlaylistBackground.corner, smooth, {CornerRadius = UDim.new(0, 0)}):Play()

		TweenService:Create(frame.Full.Content.corner, smooth, {CornerRadius = UDim.new(0, 0)}):Play()

		TweenService:Create(ui.Interface.padding, smooth, {
			PaddingBottom = UDim.new(0, 0), PaddingLeft = UDim.new(0, 0),
			PaddingRight = UDim.new(0, 0), PaddingTop = UDim.new(0, 0)}):Play()
		
	else
		
		TweenService:Create(ui.Interface, smooth, {Size = SizeIndex.Full}):Play()

		TweenService:Create(frame.Full.Content.Actions, smooth, {Position = UDim2.new(0, 0, 0, 0)}):Play()
		TweenService:Create(frame.Full.Content.Sidebar.padding, smooth, {PaddingTop = UDim.new(0,0)}):Play()
		
		TweenService:Create(frame.Full.Container.padding, smooth, {PaddingTop = UDim.new(0, 0)}):Play()
		TweenService:Create(frame.Full.NowPlaying.Content.Panel.padding, smooth, {PaddingTop = UDim.new(0, 30)}):Play()
		TweenService:Create(frame.Full.PlaylistCreation.padding, smooth, {PaddingTop = UDim.new(0, 15)}):Play()
		TweenService:Create(frame.Full.Settings.padding, smooth, {PaddingTop = UDim.new(0, 20)}):Play()

		TweenService:Create(frame.Full.Util.Visual, smooth, {Size = UDim2.fromScale(1, 1)}):Play()
		TweenService:Create(frame.Full.Util.Visual.corner, smooth, {CornerRadius = UDim.new(0, 24)}):Play()
		
		TweenService:Create(frame.Full.Util.ArtistBackground.corner, smooth, {CornerRadius = UDim.new(0, 24)}):Play()
		TweenService:Create(frame.Full.Util.DetailsBackground.corner, smooth, {CornerRadius = UDim.new(0, 24)}):Play()
		TweenService:Create(frame.Full.Util.HoverBackground.corner, smooth, {CornerRadius = UDim.new(0, 24)}):Play()
		TweenService:Create(frame.Full.Util.PlaylistBackground.corner, smooth, {CornerRadius = UDim.new(0, 24)}):Play()

		TweenService:Create(frame.Full.Content.corner, smooth, {CornerRadius = UDim.new(0, 24)}):Play()

		TweenService:Create(ui.Interface.padding, smooth, {
			PaddingBottom = UDim.new(0, 40), PaddingLeft = UDim.new(0, 40),
			PaddingRight = UDim.new(0, 40), PaddingTop = UDim.new(0, 40)
		}):Play()
	end
end

function module.Sidebar(State, Fullscreen)
	Status.Sidebar = State
	
	if State then
		Status.SidebarFullscreen = Fullscreen
		
		if Fullscreen then
			TweenService:Create(frame.Full.Content.Sidebar, normal, {AnchorPoint = Vector2.new(0, .5), 
				Size = UDim2.new(1, 0, 1, 0)}):Play()
			TweenService:Create(frame.Full.Content.SidebarOverlay, normal, {BackgroundTransparency = .5}):Play()
		else
			TweenService:Create(frame.Full.Content.Sidebar, normal, {AnchorPoint = Vector2.new(0, .5), 
				Size = UDim2.new(0, 150, 1, 0)}):Play()
			
			TweenService:Create(frame.Full.Content.SidebarOverlay, normal, {BackgroundTransparency = 1}):Play()
			
			TweenService:Create(frame.Full.Content.Miniplayer, normal, {Size = UDim2.new(1, -150, 0, 50)}):Play()
			TweenService:Create(frame.Full.Container, normal, {Size = UDim2.new(1, -150, 1, -40)}):Play()
		end
	else
		TweenService:Create(frame.Full.Content.Sidebar, normal, {AnchorPoint = Vector2.new(1, .5), 
			Size = UDim2.new(0, 150, 1, 0)}):Play()

		TweenService:Create(frame.Full.Content.SidebarOverlay, normal, {BackgroundTransparency = 1}):Play()

		TweenService:Create(frame.Full.Content.Miniplayer, normal, {Size = UDim2.new(1, 0, 0, 50)}):Play()
		TweenService:Create(frame.Full.Container, normal, {Size = UDim2.new(1, 0, 1, -40)}):Play()
	end
end

function module.SetState(MastersState: MastersState)
	if Status.SettingState then return end
	Status.SettingState = true
	
	module.OrientationChanged:Fire(module.GetOrientation())

	task.spawn(function()
		ui.Interface:SetAttribute("State", MastersState)
		module.StateChanged:Fire(MastersState)

		if MastersState == "Full" then
			SetContentLibrary(false)

			Full.Container.Position = UDim2.fromScale(1, 1)

			frame.Modal = true
			frame.page:JumpTo(Full)
			
			if not module.IsPreparedForDisplay() then
				module.SetPreparednessForDisplay(true)
			end

			TweenService:Create(ui.Interface, normal, {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5)}):Play()
			TweenService:Create(ui.Interface, normal, {ImageTransparency = 0}):Play()
			
			if Utilities.GetViewportRatio() > 1300 then
				module.Fullscreen(false)
				
				local ScaleResolution = 1 + (workspace.CurrentCamera.ViewportSize.X * .0002)
				
				TweenService:Create(frame.scale, bounce, {Scale = ScaleResolution}):Play()
			else
				module.Fullscreen(true)
				
				TweenService:Create(frame.scale, bounce, {Scale = 1}):Play()
			end

			--
			task.wait(.5)
			--

			SetContentLibrary(true)

			TweenService:Create(Full.Container, slow, {Position = UDim2.new(1, 0, 0, 20)}):Play()

		elseif MastersState == "Bar" then
			
			SetContentLibrary(false)
			module.Fullscreen(false)

			frame.Modal = false
			frame.page:JumpTo(Bar)	

			TweenService:Create(ui.Interface, smooth, {AnchorPoint = Vector2.new(.5, .5), Position = LastPos}):Play()
			TweenService:Create(ui.Interface, normal, {ImageTransparency = .8}):Play()
			TweenService:Create(ui.Interface, normal, {Size = SizeIndex.Bar}):Play()

			TweenService:Create(frame.scale, bounce, {Scale = 1}):Play()
		end

		Status.SettingState = false
	end)	
end

function module.SetPage(Page: MastersPage, Parameter)
	module.PageChanged:Fire(Page, Parameter)
	
	Status.CurrentPage = Page
	
	if Page == "Discovery" then
		Full.Container.Discovery.Visible = true
		Full.Container.Search.Visible = false
		Full.Container.Library.Visible = false
		Full.Container.Expanded.Visible = false
		Full.Container.Playlist.Visible = false
		Full.Container.Artist.Visible = false
		Full.Container.Details.Visible = false
		Full.Container.Stations.Visible = false
		
		Full.Container.padding.PaddingTop = UDim.new(1, 0)
		
		Status.LastMainPage = Page
		
		--
		
		if Status.Fullscreen then
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, GuiService.TopbarInset.Height)}):Play()
		else
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, 0)}):Play()
		end
		
		TweenService:Create(Full.Content.Sidebar.Tabs.Pages.Discovery, normal, {BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			TextTransparency = 0}):Play()
		TweenService:Create(Full.Content.Sidebar.Tabs.Pages.Search, normal, {BackgroundColor3 = Color3.fromRGB(15, 15, 15),
			TextTransparency = .5}):Play()
		TweenService:Create(Full.Content.Sidebar.Tabs.Pages.Library, normal, {BackgroundColor3 = Color3.fromRGB(15, 15, 15),
			TextTransparency = .5}):Play()

		TweenService:Create(Full.Util.ArtistBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.DetailsBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.PlaylistBackground, five, {GroupTransparency = 1}):Play()
		
	elseif Page == "Search" then
		Full.Container.Discovery.Visible = false
		Full.Container.Search.Visible = true
		Full.Container.Library.Visible = false
		Full.Container.Expanded.Visible = false
		Full.Container.Playlist.Visible = false
		Full.Container.Artist.Visible = false
		Full.Container.Details.Visible = false
		Full.Container.Stations.Visible = false
		
		Full.Container.padding.PaddingTop = UDim.new(1, 0)
		
		Status.LastMainPage = Page

		--

		if Status.Fullscreen then
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, GuiService.TopbarInset.Height)}):Play()
		else
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, 0)}):Play()
		end
		
		TweenService:Create(Full.Content.Sidebar.Tabs.Pages.Discovery, normal, {BackgroundColor3 = Color3.fromRGB(15, 15, 15),
			TextTransparency = .5}):Play()
		TweenService:Create(Full.Content.Sidebar.Tabs.Pages.Search, normal, {BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			TextTransparency = 0}):Play()
		TweenService:Create(Full.Content.Sidebar.Tabs.Pages.Library, normal, {BackgroundColor3 = Color3.fromRGB(15, 15, 15),
			TextTransparency = .5}):Play()

		TweenService:Create(Full.Util.ArtistBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.DetailsBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.PlaylistBackground, five, {GroupTransparency = 1}):Play()
		
	elseif Page == "Library" then
		Full.Container.Discovery.Visible = false
		Full.Container.Search.Visible = false
		Full.Container.Library.Visible = true
		Full.Container.Expanded.Visible = false
		Full.Container.Playlist.Visible = false
		Full.Container.Artist.Visible = false
		Full.Container.Details.Visible = false
		Full.Container.Stations.Visible = false

		Full.Container.padding.PaddingTop = UDim.new(1, 0)
		
		Status.LastMainPage = Page

		--

		if Status.Fullscreen then
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, GuiService.TopbarInset.Height)}):Play()
		else
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, 0)}):Play()
		end
		
		TweenService:Create(Full.Content.Sidebar.Tabs.Pages.Discovery, normal, {BackgroundColor3 = Color3.fromRGB(15, 15, 15),
			TextTransparency = .5}):Play()
		TweenService:Create(Full.Content.Sidebar.Tabs.Pages.Search, normal, {BackgroundColor3 = Color3.fromRGB(15, 15, 15),
			TextTransparency = .5}):Play()
		TweenService:Create(Full.Content.Sidebar.Tabs.Pages.Library, normal, {BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			TextTransparency = 0}):Play()
		
		TweenService:Create(Full.Util.ArtistBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.DetailsBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.PlaylistBackground, five, {GroupTransparency = 1}):Play()
		
	elseif Page == "Playlist" then
		Full.Container.Discovery.Visible = false
		Full.Container.Search.Visible = false
		Full.Container.Library.Visible = false
		Full.Container.Expanded.Visible = false
		Full.Container.Playlist.Visible = true
		Full.Container.Artist.Visible = false
		Full.Container.Details.Visible = false
		Full.Container.Stations.Visible = false
		
		Full.Container.padding.PaddingTop = UDim.new(1, 0)
		
		--
		
		if Status.Fullscreen then
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, GuiService.TopbarInset.Height)}):Play()
		else
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, 0)}):Play()
		end
		
		TweenService:Create(Full.Util.ArtistBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.DetailsBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.PlaylistBackground, five, {GroupTransparency = .95}):Play()
		
	elseif Page == "Stations" then
		Full.Container.Discovery.Visible = false
		Full.Container.Search.Visible = false
		Full.Container.Library.Visible = false
		Full.Container.Expanded.Visible = false
		Full.Container.Playlist.Visible = false
		Full.Container.Artist.Visible = false
		Full.Container.Details.Visible = false
		Full.Container.Stations.Visible = true
		
		Full.Container.padding.PaddingTop = UDim.new(1, 0)

		--

		if Status.Fullscreen then
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, GuiService.TopbarInset.Height)}):Play()
		else
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, 0)}):Play()
		end

		TweenService:Create(Full.Util.ArtistBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.DetailsBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.PlaylistBackground, five, {GroupTransparency = .95}):Play()
		
	elseif Page == "Expanded" then
		Full.Container.Discovery.Visible = false
		Full.Container.Search.Visible = false
		Full.Container.Library.Visible = false
		Full.Container.Expanded.Visible = true
		Full.Container.Playlist.Visible = false
		Full.Container.Artist.Visible = false
		Full.Container.Details.Visible = false
		Full.Container.Stations.Visible = false

		Full.Container.padding.PaddingTop = UDim.new(1, 0)

		--

		if Status.Fullscreen then
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, GuiService.TopbarInset.Height)}):Play()
		else
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, 0)}):Play()
		end
		
		TweenService:Create(Full.Util.ArtistBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.DetailsBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.PlaylistBackground, five, {GroupTransparency = 1}):Play()
		
	elseif Page == "Artist" then
		Full.Container.Discovery.Visible = false
		Full.Container.Search.Visible = false
		Full.Container.Library.Visible = false
		Full.Container.Expanded.Visible = false
		Full.Container.Playlist.Visible = false
		Full.Container.Artist.Visible = true
		Full.Container.Details.Visible = false
		Full.Container.Stations.Visible = false

		Full.Container.padding.PaddingTop = UDim.new(1, 0)
		
		module.NowPlaying(false)

		--

		if Status.Fullscreen then
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, GuiService.TopbarInset.Height)}):Play()
		else
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, 0)}):Play()
		end

		TweenService:Create(Full.Util.ArtistBackground, five, {GroupTransparency = 0}):Play()
		TweenService:Create(Full.Util.DetailsBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.PlaylistBackground, five, {GroupTransparency = 1}):Play()
		
	elseif Page == "Details" then
		Full.Container.Discovery.Visible = false
		Full.Container.Search.Visible = false
		Full.Container.Library.Visible = false
		Full.Container.Expanded.Visible = false
		Full.Container.Playlist.Visible = false
		Full.Container.Artist.Visible = false
		Full.Container.Details.Visible = true
		Full.Container.Stations.Visible = false

		Full.Container.padding.PaddingTop = UDim.new(1, 0)

		module.NowPlaying(false)

		--

		if Status.Fullscreen then
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, GuiService.TopbarInset.Height)}):Play()
		else
			TweenService:Create(Full.Container.padding, normal, {PaddingTop = UDim.new(0, 0)}):Play()
		end

		TweenService:Create(Full.Util.ArtistBackground, five, {GroupTransparency = 1}):Play()
		TweenService:Create(Full.Util.DetailsBackground, five, {GroupTransparency = .95}):Play()
		TweenService:Create(Full.Util.PlaylistBackground, five, {GroupTransparency = 1}):Play()
	end
end

function module.GetLastMainPage()
	return Status.LastMainPage
end

-- Screens

function module.NowPlaying(State)
	task.spawn(function()
		if State then
			if NowPlaying.Visible then return end

			NowPlaying.Size = UDim2.fromScale(1, 0)
			NowPlaying.Visible = true
			
			Full.Container.Interactable = false
			Full.Content.Interactable = false

			--

			TweenService:Create(NowPlaying, normal, {Size = UDim2.fromScale(1, 1)}):Play()
			TweenService:Create(Full.Content.Shield, normal, {BackgroundTransparency = .5}):Play()
		else
			if not NowPlaying.Visible then return end

			Full.Container.Interactable = true
			Full.Content.Interactable = true

			--

			TweenService:Create(NowPlaying, normal, {Size = UDim2.fromScale(1, 0)}):Play()
			TweenService:Create(Full.Content.Shield, normal, {BackgroundTransparency = 1}):Play()

			--
			task.wait(.5)
			--

			NowPlaying.Visible = false
		end
	end)
end

function module.PlaylistCreation(State)
	task.spawn(function()
		if State then
			if PlaylistCreation.Visible then return end

			PlaylistCreation.Size = UDim2.fromScale(1, 0)
			PlaylistCreation.Visible = true

			Full.Container.Interactable = false
			Full.Content.Interactable = false
			NowPlaying.Interactable = false
			
			PlaylistCreation:SetAttribute("Cover", "")
			PlaylistCreation:SetAttribute("Title", "")
			
			PlaylistCreation.Cover.Custom.Image = "rbxassetid://74118540785733"
			
			PlaylistCreation.Info.Title.Field.Text = ""
			PlaylistCreation.Info.Cover.AssetId.Field.Text = ""

			--

			TweenService:Create(PlaylistCreation, normal, {Size = UDim2.fromScale(1, 1)}):Play()
			TweenService:Create(Full.Content.Shield, normal, {BackgroundTransparency = .5}):Play()
			
		else
			if not PlaylistCreation.Visible then return end

			Full.Container.Interactable = true
			Full.Content.Interactable = true
			NowPlaying.Interactable = true

			--

			TweenService:Create(PlaylistCreation, normal, {Size = UDim2.fromScale(1, 0)}):Play()
			TweenService:Create(Full.Content.Shield, normal, {BackgroundTransparency = 1}):Play()

			--
			task.wait(.5)
			--

			PlaylistCreation.Visible = false
		end
	end)
end

function module.Settings(State)
	task.spawn(function()
		if State then
			if Settings.Visible then return end

			Settings.Size = UDim2.fromScale(1, 0)
			Settings.Visible = true

			Full.Container.Interactable = false
			Full.Content.Interactable = false
			NowPlaying.Interactable = false

			Settings.Scroll.CanvasPosition = Vector2.new(0, 0)

			--

			TweenService:Create(Settings, normal, {Size = UDim2.fromScale(1, 1)}):Play()
			TweenService:Create(Full.Content.Shield, normal, {BackgroundTransparency = .5}):Play()

		else
			if not Settings.Visible then return end

			Full.Container.Interactable = true
			Full.Content.Interactable = true
			NowPlaying.Interactable = true

			--

			TweenService:Create(Settings, normal, {Size = UDim2.fromScale(1, 0)}):Play()
			TweenService:Create(Full.Content.Shield, normal, {BackgroundTransparency = 1}):Play()

			--
			task.wait(.5)
			--

			Settings.Visible = false
		end
	end)
end

function module.NowPlayingView(MediaState, PanelState)
	if MediaState then
		NowPlaying.Content.Media.Visible = true
		NowPlaying.Content.Media.scale.Scale = .8

		TweenService:Create(NowPlaying.Content.Panel, normal, {Size = UDim2.new(0, 300, 1, 0)}):Play()
		
		if module.GetOrientation() == "Landscape" then
			TweenService:Create(NowPlaying.Content.Media.scale, normal, {Scale = 1}):Play()
		else
			TweenService:Create(NowPlaying.Content.Media.scale, normal, {Scale = 1.8}):Play()
		end
		
	else
		TweenService:Create(NowPlaying.Content.Panel, normal, {Size = UDim2.new(1, 0, 1, 0)}):Play()
		
		NowPlaying.Content.Media.Visible = false
	end
	
	if PanelState then
		NowPlaying.Content.Panel.Visible = true
		NowPlaying.Content.Panel.scale.Scale = .8
		
		NowPlaying.Content.Media.Details.More.Visible = false

		TweenService:Create(NowPlaying.Content.Media, normal, {Size = UDim2.new(0, 200, 1, 0)}):Play()
		TweenService:Create(NowPlaying.Content.Panel.scale, normal, {Scale = 1}):Play()
		
	else
		TweenService:Create(NowPlaying.Content.Media, normal, {Size = UDim2.new(1, 0, 1, 0)}):Play()
		
		NowPlaying.Content.Media.Details.More.Visible = true
		NowPlaying.Content.Panel.Visible = false
	end
end

function module.GetNowplayingViewStates()
	return NowPlaying.Content.Media.Visible, NowPlaying.Content.Panel.Visible
end

function module.NowPlayingPanelScreen(PanelScreen: MastersNowPlayingPanelScreen)
	Status.NowPlayingPanelScreen = PanelScreen
	
	if PanelScreen == "Lyrics" then
		NowPlaying.Content.Panel.Lyrics.Visible = true
		NowPlaying.Content.Panel.Listeners.Visible = false
		NowPlaying.Content.Panel.Queue.Visible = false
		
		NowPlaying.Content.Panel.Actions.Lyrics.Visible = false
		NowPlaying.Content.Panel.Actions.Listeners.Visible = true
		NowPlaying.Content.Panel.Actions.QueueList.Visible = true
		
	elseif PanelScreen == "Listeners" then
		NowPlaying.Content.Panel.Lyrics.Visible = false
		NowPlaying.Content.Panel.Listeners.Visible = true
		NowPlaying.Content.Panel.Queue.Visible = false

		NowPlaying.Content.Panel.Actions.Lyrics.Visible = true
		NowPlaying.Content.Panel.Actions.Listeners.Visible = false
		NowPlaying.Content.Panel.Actions.QueueList.Visible = true
		
	elseif PanelScreen == "QueueList" then
		NowPlaying.Content.Panel.Lyrics.Visible = false
		NowPlaying.Content.Panel.Listeners.Visible = false
		NowPlaying.Content.Panel.Queue.Visible = true

		NowPlaying.Content.Panel.Actions.Lyrics.Visible = true
		NowPlaying.Content.Panel.Actions.Listeners.Visible = true
		NowPlaying.Content.Panel.Actions.QueueList.Visible = false
	end
end

-- Context Menu

local function PositionContextMenu()
	local SizeRef = context_menu.SizeReference
	local Menu = context_menu.Frame

	local mouse = InputService:GetMouseLocation()
	local viewportSize = workspace.CurrentCamera.ViewportSize

	local padding = 8
	local offset = 12

	local finalSize = SizeRef.AbsoluteSize
	local multiplier = .2
	local ScaledDown = Vector2.new((finalSize.X * multiplier), (finalSize.Y * multiplier))

	local rawX = mouse.X + padding
	local rawY = mouse.Y + padding

	if rawX + finalSize.X > viewportSize.X then
		rawX = viewportSize.X - finalSize.X - padding
	end
	if rawY + finalSize.Y > viewportSize.Y then
		rawY = viewportSize.Y - finalSize.Y - padding
	end
	if rawX < padding then
		rawX = padding
	end
	if rawY < padding then
		rawY = padding
	end

	local fromY = rawY + (rawY + finalSize.Y > viewportSize.Y and offset or -offset)

	Menu.Position = UDim2.fromOffset(mouse.X - ScaledDown.X , mouse.Y)
	Menu.Size = UDim2.fromOffset(ScaledDown.X, ScaledDown.Y)
	Menu.ImageTransparency = 1
	Menu.Visible = true

	Menu.Content.padding.PaddingTop = UDim.new(0, 50)
	Menu.Content.list.Padding = UDim.new(1, 0)

	TweenService:Create(Menu, normal, {Position = UDim2.fromOffset(rawX - 30, rawY - 30)}):Play()
	TweenService:Create(Menu, normal, {ImageTransparency = 0}):Play()
	TweenService:Create(Menu, smooth, {Size = UDim2.fromOffset(finalSize.X, finalSize.Y)}):Play()

	TweenService:Create(Menu.Content.padding, quick, {PaddingTop = UDim.new(0, 10)}):Play()
	TweenService:Create(Menu.Content.list, normal, {Padding = UDim.new(0, 5)}):Play()
end

local Contexting = false

local Contexting = false

function module.PromptOptions(data: MastersContextMenu)
	if Contexting then return end
	Contexting = true

	Utilities.Haptic(1, .001)

	-- Pagination
	
	local MaxOptions = data.MaxOptions or 20
	local CurrentPage = 1
	local Options = data.Options

	-- Clearance
	
	local function Clear()
		for _, residual in pairs(context_menu.Frame.Content:GetChildren()) do
			if residual:HasTag("MastersContextMenuOption") or residual.Name == "Separator" then
				residual:Destroy()
			end
		end

		for _, residual in pairs(context_menu.Frame.Content.Primary:GetChildren()) do
			if residual:HasTag("MastersContextMenuOption") then
				residual:Destroy()
			end
		end

		for _, residual in pairs(context_menu.SizeReference.Content:GetChildren()) do
			if residual:HasTag("MastersContextMenuOption") or residual.Name == "Separator" then
				residual:Destroy()
			end
		end

		for _, residual in pairs(context_menu.SizeReference.Content.Primary:GetChildren()) do
			if residual:HasTag("MastersContextMenuOption") then
				residual:Destroy()
			end
		end
	end

	-- State
	
	local ActionChosen = ""
	local ContextProceeded = false
	local ContextCancelled = false

	-- Render
	
	local function RenderPage()
		Clear()

		local startIndex = (CurrentPage - 1) * MaxOptions + 1
		local endIndex = math.min(startIndex + MaxOptions - 1, #Options)

		local displayIndex = 1

		for i = startIndex, endIndex do
			local entry = Options[i]

			if entry == "SEPARATOR" then
				local SizeRefItem = context_menu.SizeReference.Content.list.Separator:Clone()
				SizeRefItem.LayoutOrder = displayIndex
				SizeRefItem.Parent = context_menu.SizeReference.Content 

				local item = context_menu.Frame.Content.list.Separator:Clone()
				item.LayoutOrder = displayIndex
				item.Parent = context_menu.Frame.Content

			elseif typeof(entry) == "table" and entry.Name and entry.Icon then
				local item
				local SizeRefItem

				if entry.Primary then
					SizeRefItem = context_menu.SizeReference.Content.list.PrimaryAction:Clone()
					SizeRefItem.LayoutOrder = displayIndex
					SizeRefItem.Parent = context_menu.SizeReference.Content.Primary

					item = context_menu.Frame.Content.list.PrimaryAction:Clone()
					item.LayoutOrder = displayIndex
					item.Parent = context_menu.Frame.Content.Primary
				else
					SizeRefItem = context_menu.SizeReference.Content.list.Action:Clone()
					SizeRefItem.LayoutOrder = displayIndex
					SizeRefItem.Parent = context_menu.SizeReference.Content

					item = context_menu.Frame.Content.list.Action:Clone()
					item.LayoutOrder = displayIndex
					item.Parent = context_menu.Frame.Content
				end

				SizeRefItem.Name = entry.Name
				SizeRefItem.label.Text = entry.Name
				SizeRefItem.icon.Image = entry.Icon

				item.Name = entry.Name
				item.label.Text = entry.Name
				item.icon.Image = entry.Icon

				item.MouseButton1Click:Connect(function()
					if data.Mobile then return end
					ActionChosen = entry.Name
					ContextProceeded = true
				end)

				item.MouseEnter:Connect(function()
					ui.Storage.Sounds.Tap:Play()
					Utilities.Haptic(.8, .001)

					if data.Mobile then
						TweenService:Create(item, normal, {BackgroundColor3 = Color3.fromRGB(34, 34, 34)}):Play()
					end
				end)

				item.MouseLeave:Connect(function()
					if data.Mobile then
						TweenService:Create(item, normal, {BackgroundColor3 = Color3.fromRGB(27, 27, 27)}):Play()
					end
				end)

				item.MouseButton1Up:Connect(function()
					if data.Mobile then
						ui.Storage.Sounds.Tap:Play()

						ActionChosen = entry.Name
						ContextProceeded = true

						TweenService:Create(item, normal, {BackgroundColor3 = Color3.fromRGB(27, 27, 27)}):Play()
					end
				end)
			end

			displayIndex += 1
		end

		if endIndex < #Options then
			local SizeRefItem = context_menu.SizeReference.Content.list.Action:Clone()
			SizeRefItem.LayoutOrder = displayIndex
			SizeRefItem.Name = "More..."
			SizeRefItem.label.Text = "More..."
			SizeRefItem.icon.Image = ""
			SizeRefItem.Parent = context_menu.SizeReference.Content

			local item = context_menu.Frame.Content.list.Action:Clone()
			item.LayoutOrder = displayIndex
			item.Name = "More..."
			item.label.Text = "More..."
			item.icon.Image = ""
			item.Parent = context_menu.Frame.Content

			item.MouseButton1Click:Connect(function()
				if data.Mobile then return end
				CurrentPage += 1
				RenderPage()
			end)

			item.MouseButton1Up:Connect(function()
				if data.Mobile then
					ui.Storage.Sounds.Tap:Play()
					CurrentPage += 1
					RenderPage()
				end
			end)
		end

		context_menu.SizeReference.Content.Primary.Visible = (#context_menu.SizeReference.Content.Primary:GetChildren() - 1) > 0
		context_menu.Frame.Content.Primary.Visible = (#context_menu.Frame.Content.Primary:GetChildren() - 1) > 0

		PositionContextMenu()
	end

	--
	
	if data.Header then
		context_menu.SizeReference.Content.Header.Visible = true
		context_menu.SizeReference.Content.Header.label.Text = data.Header

		context_menu.Frame.Content.Header.Visible = true
		context_menu.Frame.Content.Header.label.Text = data.Header
	else
		context_menu.SizeReference.Content.Header.Visible = false
		context_menu.Frame.Content.Header.Visible = false
	end

	if data.Mobile then
		context_menu.Active = true
		TweenService:Create(context_menu, normal, {BackgroundTransparency = .5}):Play()
	end

	--
	
	context_menu.Visible = true
	ui.Interface.Frame.Full.Interactable = false

	RenderPage()

	--
	
	context_menu.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
			ContextCancelled = true
		end
	end)

	context_menu.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			ContextCancelled = true
		end
	end)

	repeat task.wait() until ContextProceeded or ContextCancelled

	-- Cleanup
	
	context_menu.Visible = false
	context_menu.Frame.Visible = false
	ui.Interface.Frame.Full.Interactable = true

	Contexting = false

	if data.Mobile then
		context_menu.Active = false
		TweenService:Create(context_menu, normal, {BackgroundTransparency = 1}):Play()
	end

	if ContextProceeded then
		return ActionChosen
	end

	if ContextCancelled then
		return nil
	end
end

-- Share Sheet

local ShareSheetAbsoluteSize = ShareSheet.MainFrame.AbsoluteSize

local function GetScaleRelativeToScreenDimention(Frame, Axis, Ratio)
	if not Frame then return end

	local ViewportSize = workspace.CurrentCamera.ViewportSize
	local FrameSize = ShareSheetAbsoluteSize
	local TargetScale = 1

	if Axis == "X" then
		TargetScale = ViewportSize.X / FrameSize.X
	elseif Axis == "Y" then
		TargetScale = ViewportSize.Y / FrameSize.Y
	end

	local FinalScale = 1 + ((TargetScale - 1) * math.clamp(Ratio, 0, 1))

	return FinalScale
end

local function PositionShareSheetAtCursor(ShareSheet)
	local Viewport = workspace.CurrentCamera.ViewportSize
	local Inset = GuiService:GetGuiInset()

	local VerticalOffset = 10
	local ScreenPadding = 20

	local MousePos = InputService:GetMouseLocation() - Inset
	local SheetSize = ShareSheet.AbsoluteSize

	local targetX = MousePos.X - (SheetSize.X / 2)
	local targetY = MousePos.Y - SheetSize.Y - VerticalOffset

	if targetY < ScreenPadding then
		targetY = MousePos.Y + VerticalOffset
	end

	local minX = ScreenPadding
	local maxX = Viewport.X - SheetSize.X - ScreenPadding
	local minY = ScreenPadding
	local maxY = Viewport.Y - SheetSize.Y - ScreenPadding

	local finalX = math.clamp(targetX, minX, maxX)
	local finalY = math.clamp(targetY, minY, maxY)

	ShareSheet.AnchorPoint = Vector2.new(0, 0)
	ShareSheet.Position = UDim2.fromOffset(finalX, finalY + 20)

	TweenService:Create(ShareSheet, normal, {
		Position = UDim2.fromOffset(finalX, finalY)}):Play()
end

local ShareSheetOpened = false
local Connection, Connection1, Connection2

function module.PromptShare(data: MastersShareSheetInfo)
	if ShareSheetOpened then return end
	ShareSheetOpened = true
	
	ShareSheet.Visible = true
	ShareSheet.BackgroundTransparency = 1
	
	-- Positioning
	
	ui.Interface.Interactable = false
	ShareSheet.MainFrame.Frame.Container.Interactable = false
	
	TweenService:Create(ShareSheet.MainFrame.Frame.Loader, nan, {ImageTransparency = .8}):Play()
	TweenService:Create(ShareSheet.MainFrame.Frame.Container, nan, {GroupTransparency = 1}):Play()
	
	local CurrentOrientation = module.GetOrientation()
	
	if CurrentOrientation == "Portrait" then
		
		ShareSheet.MainFrame.AnchorPoint = Vector2.new(.5, 0)
		ShareSheet.MainFrame.Position = UDim2.fromScale(.5, 1)
		ShareSheet.MainFrame.scale.Scale = GetScaleRelativeToScreenDimention(ShareSheet.MainFrame, "X", .9)
		
		TweenService:Create(ShareSheet, normal, {BackgroundTransparency = .5}):Play()
		TweenService:Create(ShareSheet.MainFrame, normal, {AnchorPoint = Vector2.new(.5, 1)}):Play()
		
	elseif CurrentOrientation == "Landscape" then
		
		if Utilities.GetViewportRatio() > 1300 then
			ShareSheet.MainFrame.scale.Scale = 1

			PositionShareSheetAtCursor(ShareSheet.MainFrame)

			TweenService:Create(ShareSheet, normal, {BackgroundTransparency = .8}):Play()
		else
			ShareSheet.MainFrame.AnchorPoint = Vector2.new(.5, .5)
			ShareSheet.MainFrame.Position = UDim2.fromScale(.5, .5)
			ShareSheet.MainFrame.scale.Scale = .5

			TweenService:Create(ShareSheet, normal, {BackgroundTransparency = .5}):Play()
			TweenService:Create(ShareSheet.MainFrame.scale, normal, {Scale = 
				GetScaleRelativeToScreenDimention(ShareSheet.MainFrame, "Y", .95)}):Play()
		end
		
	end
	
	-- Residual
	
	for i, residual in ShareSheet.MainFrame.Frame.Container.Recent:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end

	for i, residual in ShareSheet.MainFrame.Frame.Container.Players:GetChildren() do
		if residual:HasTag("MastersTemplate") then
			residual:Destroy()
		end
	end
	
	-- Data
	
	local SharingCancelled = false
	local SharingCompleted = false
	local ReceiverChosen = 0
	
	local RecentReceivers = events.Main.SessionSaving.FetchRecentReceivers:InvokeServer()
	
	if data.Subtext then
		ShareSheet.MainFrame.Frame.Container.Header.Details.Source.Visible = true
		ShareSheet.MainFrame.Frame.Container.Header.Details.Source.Text = data.Subtext
	else
		ShareSheet.MainFrame.Frame.Container.Header.Details.Source.Visible = false
	end
	
	if data.Icon then
		ShareSheet.MainFrame.Frame.Container.Header.Icon.Visible = true
		ShareSheet.MainFrame.Frame.Container.Header.Icon.Photo.Image = data.Icon
		
		ShareSheet.MainFrame.Frame.Container.Header.padding.PaddingLeft = UDim.new(0, 8)
	else
		ShareSheet.MainFrame.Frame.Container.Header.Icon.Visible = false
		ShareSheet.MainFrame.Frame.Container.Header.padding.PaddingLeft = UDim.new(0, 20)
	end
	
	ShareSheet.MainFrame.Frame.Container.Header.Details.Title.Text = data.Title
	
	if RecentReceivers and #RecentReceivers > 0 then
		ShareSheet.MainFrame.Frame.Container.Recent.Visible = true
		
		for i, UserId in RecentReceivers do
			local Success, Username = pcall(function()
				return Players:GetNameFromUserIdAsync(UserId)
			end)
			
			if not Success then continue end
			
			local Item = ui.Storage.Items.ShareSheetRecent:Clone()
			local Player = Players:GetPlayerByUserId(UserId)
			
			Item.Name = Username
			Item.LayoutOrder = i
			
			Item.Photo.Image = Utilities.GetPlayerThumbnail(UserId)
			Item.Photo.Ingame.Visible = Player or false
			
			if Player then
				Item.Username.Text = Player.DisplayName
			else
				Item.Username.Text = "@" .. Username
			end
			
			Item.Parent = ShareSheet.MainFrame.Frame.Container.Recent
			
			Item.MouseButton1Click:Connect(function()
				ReceiverChosen = UserId
				SharingCompleted = true
			end)
			
		end
	else
		ShareSheet.MainFrame.Frame.Container.Recent.Visible = false
	end
	
	for i, Player in Players:GetPlayers() do
		local Item = ui.Storage.Items.ShareSheetPlayerList:Clone()
		
		if Player == client then
			Item.Name = "0" .. Players.Name
			
			Item.Display.Text = "You"
			Item.Username.Text = Player.DisplayName
		else
			Item.Name = Players.Name
			
			Item.Display.Text = Player.DisplayName
			Item.Username.Text = "@" .. Player.Name
		end
		
		Item.Photo.Image = Utilities.GetPlayerThumbnail(Player.UserId)
		Item.Parent = ShareSheet.MainFrame.Frame.Container.Players
		
		Item.MouseButton1Click:Connect(function()
			ReceiverChosen = Player.UserId
			SharingCompleted = true
		end)
	end
	
	ShareSheet.MainFrame.Frame.Container.Interactable = true
	
	TweenService:Create(ShareSheet.MainFrame.Frame.Loader, nan, {ImageTransparency = 1}):Play()
	TweenService:Create(ShareSheet.MainFrame.Frame.Container, normal, {GroupTransparency = 0}):Play()
	
	Connection = ShareSheet.MainFrame.Frame.Container.Header.Close.MouseButton1Click:Connect(function()
		SharingCancelled = true
	end)
	
	Connection1 = ShareSheet.MouseButton1Click:Connect(function()
		SharingCancelled = true
	end)

	Connection2 = ShareSheet.MainFrame.Frame.Container.Players.OfflineItem.MouseButton1Click:Connect(function()
		ReceiverChosen = ShareSheet.MainFrame.Frame.Container.Players.OfflineItem:GetAttribute("UserId")
		SharingCompleted = true
	end)
	
	-- Yielding Method
	
	repeat task.wait() until SharingCompleted or SharingCancelled
	
	ShareSheetOpened = false
	
	ShareSheet.Visible = false
	ui.Interface.Interactable = true
	
	if Connection then
		Connection:Disconnect()
	end
	
	if Connection1 then
		Connection1:Disconnect()
	end
	
	if SharingCompleted then
		return ReceiverChosen
	end
	
	if SharingCancelled then
		return
	end
end

--

function module.IsPreparedForDisplay() return Status.PreparedForDisplay end

function module.SetPreparednessForDisplay(State)
	Status.PreparedForDisplay = State
	module.PreparenessChanged:Fire(State)
end

--

Status.CurrentOrientation = module.GetOrientation()

cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	local NewOrientation = module.GetOrientation()
	
	if Status.CurrentOrientation ~= NewOrientation then
		Status.CurrentOrientation = NewOrientation
		module.OrientationChanged:Fire(NewOrientation)
	end
end)

return module