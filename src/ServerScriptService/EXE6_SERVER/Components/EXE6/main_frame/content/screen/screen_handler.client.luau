local input_service = game:GetService("UserInputService")
local user_service = game:GetService("UserService")
local tween_service = game:GetService("TweenService")
local marketplace_service = game:GetService("MarketplaceService")
local log_service = game:GetService("LogService")
local collection_service = game:GetService("CollectionService")

local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local starter_gui = game:GetService("StarterGui")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local quart = TweenInfo.new(.4, Enum.EasingStyle.Quart)
local nan = TweenInfo.new(.001)
local back = TweenInfo.new(.5, Enum.EasingStyle.Back)

local client = players.LocalPlayer

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local events = storage.events

local MainModule = require(storage.modules.MainModule) 
local Utilities = require(storage.modules.Utilities)
local Alerts = require(storage.modules.Alerts)
local Configuration = require(storage.modules.Configuration)
local CustomCommands = require(storage.modules.CustomCommands) 
local Tracking = require(storage.modules.Tracking)

local screen = script.Parent
local ui = screen.Parent.Parent.Parent

local modals = screen.Parent.Parent.Parent.modal_frame

local home = screen.home
local people = screen.people
local bans = screen.bans
local announcement = screen.announcements
local activity_audits = screen.activity_audits
local utils_page = screen.utilities
local system = screen.system

local Selections = {
	PeopleSelection = {},
	BanSelection = {},
	GlobalBanSelection = {}
}

local RefreshStatuses = {
	PeoplePage = false,
	BanPage = false
}

--// GLOBAL FUNCTIONS

function UpdatePeopleSelection()
	local count = #Selections.PeopleSelection

	people.BulkActions.Selections.Button.count.Text = count

	if count > 0 then
		people.BulkActions.Interactable = true

		tween_service:Create(people.BulkActions, info, {BackgroundTransparency = 0,
			Position = UDim2.fromScale(.5, 1)}):Play()
	else
		people.BulkActions.Interactable = false

		tween_service:Create(people.BulkActions, info, {BackgroundTransparency = 1,
			Position = UDim2.new(.5, 0, 1, 80)}):Play()
	end
end

local UnbanForGameBanType = false

function UpdateBanSelection()
	local count = #Selections.BanSelection
	local involved_items = {}

	bans.BulkActions.Selections.Button.count.Text = count

	for i, item in bans.scroll.display.scroll:GetChildren() do
		if item:IsA("ImageButton") and item:HasTag("Exe6RecordedUserId") and item:GetAttribute("selected") then
			table.insert(involved_items, item)
		end
	end

	local consistent, game_ban_type = Utilities.IsSelectedRecordedUserIdConsistent(involved_items)

	UnbanForGameBanType = game_ban_type

	if count > 0 and consistent then
		bans.BulkActions.Interactable = true

		tween_service:Create(bans.BulkActions, info, {BackgroundTransparency = 0,
			Position = UDim2.fromScale(.5, 1)}):Play()
	else
		bans.BulkActions.Interactable = false

		tween_service:Create(bans.BulkActions, info, {BackgroundTransparency = 1,
			Position = UDim2.new(.5, 0, 1, 80)}):Play()
	end
end

--// HOME

function format_date(input)
	local day = tonumber(os.date("%d"))

	return os.date("%A, %B ") .. day
end

function get_greeting()
	local hour = tonumber(os.date("%H"))

	if hour >= 5 and hour < 12 then
		return "Good Morning, "
	elseif hour >= 12 and hour < 17 then
		return "Good Afternoon, "
	elseif hour >= 17 and hour < 21 then
		return "Good Evening, "
	else
		return "Welcome, "
	end
end

--//// Exe Opened

function extract_5_logs(logs)
	local result = {}
	local len = #logs

	for i = math.max(1, len - 4), len do
		table.insert(result, logs[i])
	end

	return result
end

function EditPinnedActionsOnHomepage(Source)
	local Actions = {}

	for i, button in home.scroll.pinned:GetChildren() do
		if button:IsA("ImageButton") and button:HasTag("Exe6PinnedAction") then
			local event = Instance.new("BindableEvent")

			event.Name = button.Name

			table.insert(Actions, event)
		end
	end

	local Selected = MainModule.ParameterEnum(true, Actions, NumberRange.new(1, #Actions), "Select Actions...", Source)

	if Selected then
		MainModule.TrackProgress(true)

		local collected = {}

		for i, button in home.scroll.pinned:GetChildren() do
			if button:IsA("ImageButton") and button:HasTag("Exe6PinnedAction") then
				button.Visible = false
			end
		end

		for i, obj in Selected do
			local item = home.scroll.pinned:FindFirstChild(obj.Name)

			if item then
				item.Visible = true
				table.insert(collected, item.Name)
			end
		end

		events.auth.ActionPinning:InvokeServer("Override", client.UserId, collected)

		MainModule.TrackProgress(false)
	end

	for i, dump in Actions do
		if dump:IsA("Instance") then
			dump:Destroy()
		end
	end
end

events.ui.ExeToggled.Event:Connect(function(state)
	if state then
		local date = os.date()

		home.scroll.header.greetings.Text = get_greeting() .. client.DisplayName
		home.scroll.header.date.Text = format_date()

		--// Developer Console

		local full_history = log_service:GetLogHistory()
		local logs = extract_5_logs(full_history)

		for i, v in home.scroll.overview.console.logs:GetChildren() do
			if v:IsA("TextLabel") then
				v:Destroy()
			end
		end

		for i, v in logs do
			local msg = home.scroll.overview.console.logs.list.log:Clone()
			local timestamp = os.date("!%H:%M:%S", math.floor(v.timestamp))

			msg.Text = timestamp .. " " .. v.message
			msg.TextColor3 = msg:GetAttribute(tostring(v.messageType):sub(18, -1))
			msg.Parent = home.scroll.overview.console.logs
		end

		--// Pinned Actions

		local Pins = events.auth.FetchPins:InvokeServer()

		if Pins then			
			for i, Action in Pins do
				local item = home.scroll.pinned:FindFirstChild(Action)
				if not item then continue end

				item.Visible = (item ~= nil)
			end

			for i, item in home.scroll.pinned:GetChildren() do
				if item:IsA("ImageButton") and item:HasTag("Exe6PinnedAction") then

					item.MouseButton1Click:Connect(function()

						events.ui.TriggerPinnedAction:Fire(item.Name)
						Utilities.Haptic(.5)
						ui.storage.click:Play()

					end)

					item.MouseButton2Click:Connect(function()
						local OptionChosen = MainModule.PromptOptions({
							Options = {
								{Name = "Execute", Icon = "rbxassetid://11326879610"},
								{Name = "Unpin", Icon = "rbxassetid://12974257382"},

								"SEPARATOR",

								{Name = "Edit", Icon = "rbxassetid://11326670192"},
							}
						})

						if OptionChosen == "Execute" then

							events.ui.TriggerPinnedAction:Fire(item.Name)
							Utilities.Haptic(.5)

						elseif OptionChosen == "Unpin" then
							MainModule.TrackProgress(true)

							Utilities.Haptic(.5, .01)

							events.auth.ActionPinning:InvokeServer("Unpin", client.UserId, item.Name)

							item.Visible = false
							MainModule.TrackProgress(false)

						elseif OptionChosen == "Edit" then

							EditPinnedActionsOnHomepage(item)

						end
					end)

					item.TouchLongPress:Connect(function()
						local OptionChosen = MainModule.PromptOptions({
							Options = {
								{Name = "Execute", Icon = "rbxassetid://11326879610"},
								{Name = "Unpin", Icon = "rbxassetid://12974257382"},

								"SEPARATOR",

								{Name = "Edit", Icon = "rbxassetid://11326670192"},
							},
							Mobile = true
						})

						if OptionChosen == "Execute" then

							events.ui.TriggerPinnedAction:Fire(item.Name)
							Utilities.Haptic(.5)

						elseif OptionChosen == "Unpin" then
							MainModule.TrackProgress(true)

							Utilities.Haptic(.5, .01)

							events.auth.ActionPinning:InvokeServer("Unpin", client.UserId, item.Name)

							item.Visible = false
							MainModule.TrackProgress(false)

						elseif OptionChosen == "Edit" then

							EditPinnedActionsOnHomepage(item)

						end
					end)

					--

					item.MouseEnter:Connect(function()
						tween_service:Create(item, info, {ImageTransparency = .9}):Play()
						tween_service:Create(item.content.list, info, {Padding = UDim.new(0, 5)}):Play()
					end)

					item.MouseButton1Down:Connect(function()
						tween_service:Create(item, info, {ImageTransparency = .95}):Play()
						tween_service:Create(item.content.list, info, {Padding = UDim.new(0, 15)}):Play()
					end)

					item.InputEnded:Connect(function()
						tween_service:Create(item, info, {ImageTransparency = 1}):Play()
						tween_service:Create(item.content.list, info, {Padding = UDim.new(0, 10)}):Play()
					end)
				end
			end
		end
	end
end)

-- Pinned Actions

local TrackTypeTable = {}

function SupplyTrackTypeTable()
	local PlayerType = Instance.new("Team")
	PlayerType.Name = "Players"

	local WorkspaceType = Instance.new("WorldModel")
	WorkspaceType.Name = "Workspace"

	table.insert(TrackTypeTable, PlayerType)
	table.insert(TrackTypeTable, WorkspaceType)
end

SupplyTrackTypeTable()

home.scroll.pinned.header.Edit.MouseButton1Click:Connect(function()
	EditPinnedActionsOnHomepage(home.scroll.pinned.header.Edit)
end)

events.ui.TriggerPinnedAction.Event:Connect(function(Action)
	if Action == "Announce" then
		MainModule.Announcement(true, home.scroll.pinned.Announce)

	elseif Action == "Ban" then
		local Selected = MainModule.ParameterPlayer(true, NumberRange.new(1, 50), "Ban...", home.scroll.pinned.Ban)

		if Selected then
			local UserIds = Utilities.PlayersToUserIds(Selected)

			MainModule.Ban(true, UserIds, home.scroll.pinned.Ban)
		end

	elseif Action == "Kick" then
		local Selected = MainModule.ParameterPlayer(true, NumberRange.new(1, 50), "Kick...", home.scroll.pinned.Notify)

		if Selected then
			local UserIds = Utilities.PlayersToUserIds(Selected)

			MainModule.Kick(true, UserIds)
		end
	elseif Action == "Notify" then
		local Selected = MainModule.ParameterPlayer(true, NumberRange.new(1, 50), "Notify...", home.scroll.pinned.Ban)

		if Selected then
			local UserIds = Utilities.PlayersToUserIds(Selected)

			MainModule.Notify(true, UserIds)
		end

	elseif Action == "NotificationDrawer" then
		MainModule.NotificationHistory(true, home.scroll.pinned.NotificationDrawer)

	elseif Action == "Spectate" then
		local Selected = MainModule.ParameterPlayer(true, NumberRange.new(1), "Spectate...", home.scroll.pinned.Spectate)

		if Selected then
			if modals.profile:GetAttribute("UserId") ~= Selected[1].UserId then
				MainModule.Profile(true, Selected[1].UserId)
				MainModule.Profile(false)
			end

			MainModule.Spectate(true, Selected[1].UserId)
		end

	elseif Action == "ViewAvatar" then
		local Selected = MainModule.ParameterPlayer(true, NumberRange.new(1), "View...", home.scroll.pinned.ViewAvatar)

		if Selected then
			MainModule.CharacterViewer(true, Selected[1].UserId, home.scroll.pinned.ViewAvatar)
		end

	elseif Action == "Warn" then
		local Selected = MainModule.ParameterPlayer(true, NumberRange.new(1), "Warn...", home.scroll.pinned.Warn)

		if Selected then
			local UserIds = Utilities.PlayersToUserIds(Selected)

			MainModule.Warn(true, UserIds, home.scroll.pinned.Warn)
		end

	elseif Action == "LiveTrack" then
		local Trackables = collection_service:GetTagged("Exe6Tracking")

		if #Trackables > 0 then
			local Selected = MainModule.ParameterEnum(true, collection_service:GetTagged("Exe6Tracking"), 
				NumberRange.new(1), "Live Track...", home.scroll.pinned.LiveTrack)

			if Selected then
				MainModule.LiveTrack(true, Selected[1], home.scroll.pinned.LiveTrack)
			end
		end

	elseif Action == "Track" then
		local TrackType = MainModule.ParameterEnum(true, TrackTypeTable, 
			NumberRange.new(1), "Track...", home.scroll.pinned.Track)

		if TrackType then
			if TrackType[1].Name == "Players" then
				local Selected = MainModule.ParameterPlayer(true, NumberRange.new(1,50), "Track Players...", home.scroll.pinned.Track)

				if Selected then
					for i, v in Selected do
						Tracking.SetTrack(v.Character, true)
					end

					Alerts.BannerNotify({
						Header = "Successfully Tracked",
						Description = #Selected .. " player(s) are now being tracked.",
						Icon = "rbxassetid://12967713729"
					})
				end

			elseif TrackType[1].Name == "Workspace" then
				local Selected = MainModule.ParameterEnum(true, Tracking.GetAllTrackableObjects(), 
					NumberRange.new(1, 50), "Track Workspace...", home.scroll.pinned.Track)

				if Selected then
					for i, v in Selected do
						Tracking.SetTrack(v, true)
					end

					Alerts.BannerNotify({
						Header = "Successfully Tracked",
						Description = #Selected .. " object(s) are now being tracked.",
						Icon = "rbxassetid://12967713729"
					})
				end
			end
		end

	elseif Action == "Roles" then
		local Roles = {}
		local fetch = events.auth.FetchRoles:InvokeServer()

		for i, v in fetch do
			local obj = Instance.new("Team")

			obj.Name = v.Alias

			table.insert(Roles, obj)
		end

		local Selected = MainModule.ParameterEnum(true, Roles, NumberRange.new(1), "Select a role...",
			home.scroll.pinned.Roles)

		if Selected then
			MainModule.RoleInfo(true, Selected[1].Name, home.scroll.pinned.Roles)
		end

		for i, dump in Roles do
			if dump:IsA("Instance") then
				dump:Destroy()
			end
		end

	elseif Action == "Fly" then
		MainModule.Fly(true, home.scroll.pinned.Fly)
		
	elseif Action == "Unfly" then
		events.NoClip.NoClip:InvokeServer(client, false)
	end
end)

--

home.scroll.overview.console.MouseButton1Click:Connect(function()
	starter_gui:SetCore("DevConsoleVisible", true)
end)

home.scroll.overview.privacy.MouseButton1Click:Connect(function()
	MainModule.Privacy(true, home.scroll.overview.privacy)
end)

home.scroll.overview.server_teleportation.MouseButton1Click:Connect(function()
	MainModule.ServerTeleportation(true, home.scroll.overview.server_teleportation)
end)

home.scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
	tween_service:Create(home.scroll.information.game_display.thumbnail, info, {
		ImageColor3 = Utilities.GetImageColor3ByScrollPositionInHomepage(home.scroll.CanvasPosition.Y)}):Play()

	tween_service:Create(home.scroll.information.game_display, info, {
		BackgroundTransparency = Utilities.GetTransparencyByScrollPositionInHomepage(home.scroll.CanvasPosition.Y)}):Play()

	tween_service:Create(home.scroll.information.game_display.thumbnail.scale, info, {
		Scale = Utilities.GetScaleByScrollPositionInHomepage(home.scroll.CanvasPosition.Y)}):Play()

	tween_service:Create(home.scroll.information.game_display.content.tech, info, {
		Size = UDim2.new(1, Utilities.GetSizeXByScrollPositionInHomepage(home.scroll.CanvasPosition.Y), 0, 0)}):Play()

	tween_service:Create(home.scroll.information.game_display.content.tech.jobid, info, {
		BackgroundTransparency = Utilities.GetTransparencyByScrollPositionInHomepage(home.scroll.CanvasPosition.Y)}):Play()
	tween_service:Create(home.scroll.information.game_display.content.tech.jobid.stroke, info, {
		Transparency = Utilities.GetTransparencyByScrollPositionInHomepage(home.scroll.CanvasPosition.Y)}):Play()

	tween_service:Create(home.scroll.information.game_display.content.tech.placeid, info, {
		BackgroundTransparency = Utilities.GetTransparencyByScrollPositionInHomepage(home.scroll.CanvasPosition.Y)}):Play()
	tween_service:Create(home.scroll.information.game_display.content.tech.placeid.stroke, info, {
		Transparency = Utilities.GetTransparencyByScrollPositionInHomepage(home.scroll.CanvasPosition.Y)}):Play()
end)

for i, button in home.scroll.people:GetChildren() do
	if button:IsA("ImageButton") then

		button.MouseButton1Click:Connect(function()
			MainModule.GoToScreen(screen.people)
		end)

	end
end

--//// Game Info

home.scroll.information.game_display.content.icon.MouseEnter:Connect(function()
	tween_service:Create(home.scroll.information.game_display.content.icon.photo.scale, info, {Scale = 1.5}):Play()
	tween_service:Create(home.scroll.information.game_display.content.icon.shadow.scale, info, {Scale = 1.5}):Play()
end)

home.scroll.information.game_display.content.icon.InputEnded:Connect(function()
	tween_service:Create(home.scroll.information.game_display.content.icon.photo.scale, info, {Scale = 1}):Play()
	tween_service:Create(home.scroll.information.game_display.content.icon.shadow.scale, info, {Scale = 1}):Play()
end)

function display_game_info()
	local Design = events.ui.GetGameDesignTable:InvokeServer()
	local game_info = marketplace_service:GetProductInfoAsync(game.PlaceId)

	home.scroll.information.game_display.content.info.game_name.Text = game_info.Name
	home.scroll.information.game_display.content.info.creator.Text = game_info.Creator.Name
	home.scroll.information.game_display.content.description.Text = game_info.Description

	home.scroll.information.game_display.content.icon.photo.Image = Design["Icon"]
	home.scroll.information.game_display.thumbnail.Image = Design["Thumbnail"]

	home.scroll.information.game_display.content.tech.placeid.value.Text = game.PlaceId
	home.scroll.information.game_display.content.tech.jobid.value.Text = game.JobId
end

display_game_info()

local tech = home.scroll.information.game_display.content.tech

tech.placeid.MouseButton1Click:Connect(function()
	tech.placeid.value.Interactable = true
	tech.placeid.value:CaptureFocus()

	tech.placeid.value.SelectionStart = 0
	tech.placeid.value.CursorPosition = tech.placeid.value.Text:len() + 1
end)

tech.placeid.value.FocusLost:Connect(function()
	tech.placeid.value.Text = game.PlaceId
	tech.placeid.value.Interactable = false
end)

tech.jobid.MouseButton1Click:Connect(function()
	tech.jobid.value.Interactable = true
	tech.jobid.value:CaptureFocus()

	tech.jobid.value.SelectionStart = 0
	tech.jobid.value.CursorPosition = tech.jobid.value.Text:len() + 1
end)

tech.jobid.value.FocusLost:Connect(function()
	tech.jobid.value.Text = game.JobId
	tech.jobid.value.Interactable = false
end)

--//// People

function update_meter()
	local num = #players:GetPlayers()
	local max = players.MaxPlayers

	local percentage = (num / max) * 100
	local meter_value = -180 + (percentage * 1.8)

	home.scroll.people.count.count.Text = num .. "/" .. max

	tween_service:Create(home.scroll.people.count.meter.line, info, {Rotation = meter_value}):Play()
end

function update_counts_overview()
	local num = #players:GetPlayers()
	local team = {}

	for i, person in players:GetPlayers() do
		local authorized = events.auth.Auth:InvokeServer("IsAuthorized", person.UserId)

		if person:HasTag("Exe6PersonLoaded") and authorized then
			table.insert(team, person)
		end
	end

	people.scroll.charts.max.count.Text = players.MaxPlayers
	people.scroll.charts.others.count.Text = num - #team
	people.scroll.charts.people.count.Text = num
	people.scroll.charts.team.count.Text = #team
end

function PeoplePageSelection(item, person, state)
	if state then
		if #Selections.PeopleSelection < 50 then
			item:SetAttribute("selected", true)

			table.insert(Selections.PeopleSelection, person.UserId)

			tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(27, 27, 27)}):Play()
			tween_service:Create(item.select.blue.scale, info, {Scale = 1}):Play()
		else
			Alerts.BannerNotify({
				Header = "Bulk Selection Limit Reached";
				Description = "You can only select 50 players at a time.";
				Icon = "rbxassetid://12974220720";
			})
		end
	else
		item:SetAttribute("selected", false)

		table.remove(Selections.PeopleSelection, table.find(Selections.PeopleSelection, person.UserId) or 0)

		tween_service:Create(item.select.blue.scale, info, {Scale = 0}):Play()
		tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(27, 27, 27)}):Play()
	end

	UpdatePeopleSelection()
end

function OptionChosenActivation(UserId, OptionChosen)
	if OptionChosen then
		if OptionChosen == "View Profile" then
			MainModule.Profile(true, UserId)

		elseif OptionChosen == "Ban" then
			MainModule.Ban(true, {UserId})
		elseif OptionChosen == "Kick" then
			MainModule.Kick(true, {UserId})
		elseif OptionChosen == "Warn" then
			MainModule.Warn(true, {UserId})
		elseif OptionChosen == "Notify" then
			MainModule.Notify(true, {UserId})

		elseif OptionChosen == "Chat History" then
			if modals.profile:GetAttribute("UserId") ~= UserId then
				MainModule.Profile(true, UserId)
				MainModule.Profile(false)
			end

			MainModule.ChatHistory(true, UserId)
		elseif OptionChosen == "Ban History" then
			MainModule.BanHistory(true, false, UserId)
		elseif OptionChosen == "Warn History" then
			if modals.profile:GetAttribute("UserId") ~= UserId then
				MainModule.Profile(true, UserId)
				MainModule.Profile(false)
			end

			MainModule.WarnHistory(true, UserId)

		elseif OptionChosen == "Spectate" then
			if modals.profile:GetAttribute("UserId") ~= UserId then
				MainModule.Profile(true, UserId)
				MainModule.Profile(false)
			end

			MainModule.Spectate(true, UserId)

		end
	end
end

function AddPerson(person: Player, directory)
	update_meter()
	update_counts_overview()

	--

	local auth = events.auth.Auth:InvokeServer("IsAuthorized", person.UserId)

	if table.find(directory, home) then
		local item = home.scroll.people.list.item:Clone()

		item.Name = person.UserId
		item.profile.Image = Utilities.GetPlayerThumbnail(person.UserId)
		item.display.Text = Utilities.AddBadgeToIdentifier(person.DisplayName, person.HasVerifiedBadge, person.MembershipType)

		item:SetAttribute("id", person.UserId)
		item:SetAttribute("username", person.Name)

		if auth then
			local role = auth.Role.Alias
			local accent =  auth.Role.Accent
			local order =  person:GetAttribute("order")

			item.role.BackgroundColor3 = accent
			item.role.TextColor3 = Utilities.AdjustColor(accent)
			item.role.Text = role

			item.LayoutOrder = -order
			item.Parent = home.scroll.people.team.scroll
		else
			item.role.Visible = false

			item.Parent = home.scroll.people.others.scroll
		end

		item.MouseEnter:Connect(function()
			tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(53, 53, 53)}):Play()
		end)

		item.MouseButton1Down:Connect(function()
			tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(34, 34, 34)}):Play()
		end)

		item.InputEnded:Connect(function()
			tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(34, 34, 34)}):Play()
		end)

		item.MouseButton1Click:Connect(function()
			MainModule.Profile(true, person.UserId, item.profile)
		end)

		item.TouchLongPress:Connect(function()
			local OptionChosen = MainModule.PromptOptions({
				Header = "@" .. person.DisplayName,
				Options = {
					{Name = "Ban", Icon = "rbxassetid://12974250807", Primary = true},
					{Name = "Kick", Icon = "rbxassetid://11295285778", Primary = true},

					"SEPARATOR",

					{Name = "Warn", Icon = "rbxassetid://11419713314"},
					{Name = "Notify", Icon = "rbxassetid://11295275950"},

					"SEPARATOR",

					{Name = "Chat History", Icon = "rbxassetid://11422929748"},
					{Name = "Ban History", Icon = "rbxassetid://12974250538"},
					{Name = "Warn History", Icon = "rbxassetid://12967751036"},
				},
				Mobile = true
			})

			OptionChosenActivation(person.UserId, OptionChosen)
		end)

		item.MouseButton2Click:Connect(function()
			local OptionChosen = MainModule.PromptOptions({
				Header = "@" .. person.DisplayName,
				Options = {
					{Name = "Ban", Icon = "rbxassetid://12974250807", Primary = true},
					{Name = "Kick", Icon = "rbxassetid://11295285778", Primary = true},

					"SEPARATOR",

					{Name = "View Profile", Icon = "rbxassetid://11963361597"},

					"SEPARATOR",

					{Name = "Warn", Icon = "rbxassetid://11419713314"},
					{Name = "Notify", Icon = "rbxassetid://11295275950"},

					"SEPARATOR",

					{Name = "Chat History", Icon = "rbxassetid://11422929748"},
					{Name = "Ban History", Icon = "rbxassetid://12974250538"},
					{Name = "Warn History", Icon = "rbxassetid://12967751036"},

					"SEPARATOR",

					{Name = "Spectate", Icon = "rbxassetid://16095794599"},
				}
			})

			OptionChosenActivation(person.UserId, OptionChosen)
		end)
	end

	if table.find(directory, people) then
		local item = people.scroll.display.scroll.list.item:Clone()

		item.Name = person.UserId
		item.profile.Image = Utilities.GetPlayerThumbnail(person.UserId)
		item.info.display.Text = Utilities.AddBadgeToIdentifier(person.DisplayName, person.HasVerifiedBadge,person.MembershipType)
		item.info.username.Text = "@" .. person.Name

		item:SetAttribute("id", person.UserId)
		item:SetAttribute("username", person.Name)

		if auth then
			local role = auth.Role.Alias
			local accent =  auth.Role.Accent
			local order =  person:GetAttribute("order")

			item.role.BackgroundColor3 = accent
			item.role.TextColor3 = Utilities.AdjustColor(accent)
			item.role.Text = role

			item.LayoutOrder = -order
			item.Parent = people.scroll.display.scroll
		else
			item.role.Visible = false

			item.LayoutOrder = 0
			item.Parent = people.scroll.display.scroll
		end

		item.MouseEnter:Connect(function()
			if not item:GetAttribute("selected") then
				tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(43, 43, 43)}):Play()
			end
		end)

		item.MouseButton1Down:Connect(function()
			if not item:GetAttribute("selected") then
				tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(18, 18, 18)}):Play()
			end
		end)

		item.InputEnded:Connect(function()
			if not item:GetAttribute("selected") then
				tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(27, 27, 27)}):Play()
			end
		end)

		item.select.MouseButton1Click:Connect(function()
			PeoplePageSelection(item, person, not item:GetAttribute("selected"))
		end)

		item.MouseButton1Click:Connect(function()
			if input_service:IsKeyDown(Enum.KeyCode.LeftShift) then
				PeoplePageSelection(item, person, not item:GetAttribute("selected"))
			else
				MainModule.Profile(true, person.UserId, item.profile)
			end
		end)

		item.TouchLongPress:Connect(function()
			local OptionChosen = MainModule.PromptOptions({
				Header = "@" .. person.DisplayName,
				Options = {
					{Name = "Ban", Icon = "rbxassetid://12974250807", Primary = true},
					{Name = "Kick", Icon = "rbxassetid://11295285778", Primary = true},

					"SEPARATOR",

					{Name = "Toggle Select", Icon = "rbxassetid://11419719540"},

					"SEPARATOR",

					{Name = "Warn", Icon = "rbxassetid://11419713314"},
					{Name = "Notify", Icon = "rbxassetid://11295275950"},

					"SEPARATOR",

					{Name = "Spectate", Icon = "rbxassetid://16095794599"},
				},
				Mobile = true
			})

			if OptionChosen == "Toggle Select" then
				PeoplePageSelection(item, person, not item:GetAttribute("selected"))
			else
				OptionChosenActivation(person.UserId, OptionChosen)
			end
		end)

		item.MouseButton2Click:Connect(function()
			local OptionChosen = MainModule.PromptOptions({
				Header = "@" .. person.DisplayName,
				Options = {
					{Name = "Toggle Select", Icon = "rbxassetid://11419719540", Primary = true},
					{Name = "View Profile", Icon = "rbxassetid://11963361597", Primary = true},

					"SEPARATOR",

					{Name = "Ban", Icon = "rbxassetid://12974250807"},
					{Name = "Kick", Icon = "rbxassetid://11295285778"},
					{Name = "Warn", Icon = "rbxassetid://11419713314"},
					{Name = "Notify", Icon = "rbxassetid://11295275950"},

					"SEPARATOR",

					{Name = "Chat History", Icon = "rbxassetid://11422929748"},
					{Name = "Ban History", Icon = "rbxassetid://12974250538"},
					{Name = "Warn History", Icon = "rbxassetid://12967751036"},

					"SEPARATOR",

					{Name = "Spectate", Icon = "rbxassetid://16095794599"},
				}
			})

			if OptionChosen == "Toggle Select" then
				PeoplePageSelection(item, person, not item:GetAttribute("selected"))
			else
				OptionChosenActivation(person.UserId, OptionChosen)
			end
		end)
	end
end

function RemovePerson(person, ForRefresh)
	local userid = person.UserId

	update_meter()
	update_counts_overview()

	--

	local home_item = home.scroll.people:FindFirstChild(tostring(userid), true)
	local people_item = people.scroll.display.scroll:FindFirstChild(tostring(userid))

	if home_item and home_item:IsA("ImageButton") then
		home_item:Destroy()		
	end

	if people_item then
		if table.find(Selections.PeopleSelection, person.UserId) then
			if not ForRefresh then

				Alerts.BannerNotify({
					Header = "Current Selection Updated";
					Description = person.DisplayName .. " has left the game therefore your selection has been updated.";
					Icon = "rbxassetid://12974235428";
					Involved = {userid}
				})

			end
		end

		PeoplePageSelection(people_item, person, false)
		people_item:Destroy()
	end
end

function InitiatePeople()
	for i, person in players:GetPlayers() do
		AddPerson(person, {home, people})
	end
end

InitiatePeople()

players.PlayerAdded:Connect(function(person)
	AddPerson(person, {home, people})
end)

players.PlayerRemoving:Connect(function(person)
	RemovePerson(person)
end)

--// People Page

people.BulkActions.Actions.Frame.Kick.MouseButton1Click:Connect(function()
	local collected = {}

	for i, id in Selections.PeopleSelection do
		table.insert(collected, id)
	end

	MainModule.Kick(true, collected, people.BulkActions.Actions.Frame.Kick)
end)

people.BulkActions.Actions.Frame.Ban.MouseButton1Click:Connect(function()
	local collected = {}

	for i, id in Selections.PeopleSelection do
		table.insert(collected, id)
	end

	MainModule.Ban(true, collected, people.BulkActions.Actions.Frame.Ban)
end)

people.BulkActions.Actions.Frame.Notify.MouseButton1Click:Connect(function()
	local collected = {}

	for i, id in Selections.PeopleSelection do
		table.insert(collected, id)
	end

	MainModule.Notify(true, collected, people.BulkActions.Actions.Frame.Notify)
end)

people.BulkActions.Actions.Frame.Warn.MouseButton1Click:Connect(function()
	local collected = {}

	for i, id in Selections.PeopleSelection do
		table.insert(collected, id)
	end

	MainModule.Warn(true, collected, people.BulkActions.Actions.Frame.Warn)
end)

-- Filters

local filter = people.scroll.filter
local CurrentCategory = "All"

type PeoplePageFilterParameters = {
	Category: "All" | "Team" | "Others" | any;
}

function SetFiltersForPeoplePage(params: PeoplePageFilterParameters)	
	if params.Category then
		CurrentCategory = params.Category
	end

	if params.Category == "All" then
		for index, person in people.scroll.display.scroll:GetChildren() do
			if person:IsA("ImageButton") then
				person.Visible = true
			end
		end

		tween_service:Create(filter.categories.All, info, {BackgroundTransparency = 0}):Play()
		tween_service:Create(filter.categories.Team, info, {BackgroundTransparency = 1}):Play()
		tween_service:Create(filter.categories.Others, info, {BackgroundTransparency = 1}):Play()

		tween_service:Create(filter.categories.All.icon, info, {ImageTransparency = 0}):Play()
		tween_service:Create(filter.categories.Team.icon, info, {ImageTransparency = .5}):Play()
		tween_service:Create(filter.categories.Others.icon, info, {ImageTransparency = .5}):Play()

	elseif params.Category == "Team" then
		for index, person in people.scroll.display.scroll:GetChildren() do
			if person:IsA("ImageButton") then
				person.Visible = person.role.Visible
			end
		end

		tween_service:Create(filter.categories.Team, info, {BackgroundTransparency = 0}):Play()
		tween_service:Create(filter.categories.All, info, {BackgroundTransparency = 1}):Play()
		tween_service:Create(filter.categories.Others, info, {BackgroundTransparency = 1}):Play()

		tween_service:Create(filter.categories.Team.icon, info, {ImageTransparency = 0}):Play()
		tween_service:Create(filter.categories.All.icon, info, {ImageTransparency = .5}):Play()
		tween_service:Create(filter.categories.Others.icon, info, {ImageTransparency = .5}):Play()

	elseif params.Category == "Others" then
		for index, person in people.scroll.display.scroll:GetChildren() do
			if person:IsA("ImageButton") then
				person.Visible = not person.role.Visible
			end
		end

		tween_service:Create(filter.categories.Others, info, {BackgroundTransparency = 0}):Play()
		tween_service:Create(filter.categories.All, info, {BackgroundTransparency = 1}):Play()
		tween_service:Create(filter.categories.Team, info, {BackgroundTransparency = 1}):Play()

		tween_service:Create(filter.categories.Others.icon, info, {ImageTransparency = 0}):Play()
		tween_service:Create(filter.categories.All.icon, info, {ImageTransparency = .5}):Play()
		tween_service:Create(filter.categories.Team.icon, info, {ImageTransparency = .5}):Play()

	end
end

function SearchKeywordForPeoplePage()
	local term = string.lower(filter.search.textbox.Text)

	for i, v in people.scroll.display.scroll:GetChildren() do
		if v:IsA("ImageButton") and v:HasTag("Exe6PersonItem") and v.Visible then
			if term ~= "" then
				local keywords = {
					v.Name,
					v.info.display.Text,
					v.info.username.Text,
					v.role.Text
				}
				local item = string.lower(table.concat(keywords, ","))

				if string.find(item, term) then
					v.LayoutOrder = 1
				else
					v.LayoutOrder = 2
				end
			else
				if v.Name == players.LocalPlayer.Name then
					v.LayoutOrder = 1
				else
					v.LayoutOrder = 2
				end
			end
		end
	end
end

filter.categories.All.MouseButton1Click:Connect(function()
	SetFiltersForPeoplePage({Category = "All"})
end)

filter.categories.Team.MouseButton1Click:Connect(function()
	SetFiltersForPeoplePage({Category = "Team"})

end)

filter.categories.Others.MouseButton1Click:Connect(function()
	SetFiltersForPeoplePage({Category = "Others"})
end)

function EnterKeyforPeoplePage(state)	
	task.spawn(function()
		if state then
			if not filter.search.EnterKey:GetAttribute("Shown") then
				tween_service:Create(filter.search.EnterKey.Frame, nan, {Position = UDim2.fromScale(0, 1.5)}):Play()

				--
				task.wait()
			end

			tween_service:Create(filter.search.EnterKey.Frame, back, {Position = UDim2.fromScale(0, .5)}):Play()
		else
			if filter.search.EnterKey:GetAttribute("Shown") then
				tween_service:Create(filter.search.EnterKey.Frame, nan, {Position = UDim2.fromScale(0, .5)}):Play()

				--
				task.wait()
			end

			tween_service:Create(filter.search.EnterKey.Frame, info, {Position = UDim2.fromScale(0, 1.5)}):Play()
		end

		filter.search.EnterKey:SetAttribute("Shown", state)
	end)
end

filter.search.MouseButton1Click:Connect(function()
	filter.search.textbox:CaptureFocus()
end)

filter.search.textbox:GetPropertyChangedSignal("Text"):Connect(function()
	SearchKeywordForPeoplePage()

	--

	if (filter.search.textbox.Text:len() >= 3 and filter.search.textbox.Text:len() <= 20)
		and filter.search.textbox.Text ~= "" then

		EnterKeyforPeoplePage(true)

	else
		EnterKeyforPeoplePage(false)
	end
end)

filter.search.textbox.FocusLost:Connect(function(entered)
	if entered and filter.search.EnterKey:GetAttribute("Shown") then
		filter.search.Interactable = false

		local success, result = pcall(function()
			return players:GetUserIdFromNameAsync(filter.search.textbox.Text)
		end)

		if success then
			MainModule.Profile(true, result, filter.search)
		else
			Alerts.BannerNotify({
				Header = "Failed to find the player.",
				Description = "Error: Unknown Player",
				Icon = "rbxassetid://11422144471"
			})
		end
	end

	filter.search.Interactable = true
	EnterKeyforPeoplePage(false)
end)

-- Refresh

filter.refresh.MouseButton1Click:Connect(function()
	if not RefreshStatuses.PeoplePage then
		RefreshStatuses.PeoplePage = true

		filter.refresh.icon.Rotation = 0

		tween_service:Create(filter.refresh.icon, info, {Rotation = 360}):Play()

		--

		for i, person in players:GetPlayers() do
			RemovePerson(person, true)
		end

		for i, residiual in people.scroll.display.scroll:GetChildren() do
			if residiual:IsA("ImageButton") then
				residiual:Destroy()
			end
		end

		InitiatePeople()
		SetFiltersForPeoplePage({Category = "All"})

		RefreshStatuses.PeoplePage = false
	end
end)

--// BANS 

function AddPersonToBanPageField(username)
	local success, userid = pcall(function()
		return players:GetUserIdFromNameAsync(username)
	end)

	if success then
		if table.find(Selections.GlobalBanSelection, userid) then
			Alerts.BannerNotify({
				Header = "Player has been already added.";
				Description = "Player's username is already on the list.";
				Icon = "rbxassetid://11422145434"
			})

			return
		else
			table.insert(Selections.GlobalBanSelection, userid)
		end

		local item = bans.scroll.global_ban.box.Frame.list.item:Clone()

		item.Name = userid
		item.profile.Image = Utilities.GetPlayerThumbnail(userid)
		item.username.Text = "@" .. username
		item.padding.PaddingBottom = UDim.new(-1, 0)
		item.Parent = bans.scroll.global_ban.box.Frame

		item:SetAttribute("UserId", userid)

		bans.scroll.global_ban.box.subframe.count.header.Text = #Selections.GlobalBanSelection .. "/50"

		-- Sound

		local Pitch = #Selections.GlobalBanSelection * .1

		modals.Parent.storage.click.PlaybackSpeed = Pitch
		modals.Parent.storage.click:Play()

		Utilities.Haptic(.5)

		--

		tween_service:Create(item.padding, info, {PaddingBottom = UDim.new(0, 0)}):Play()

		--

		item.actions.profile.MouseButton1Click:Connect(function()
			MainModule.Profile(true, item:GetAttribute("UserId"), item.profile)
		end)

		item.actions.cancel.MouseButton1Click:Connect(function()
			table.remove(Selections.GlobalBanSelection, table.find(Selections.GlobalBanSelection, userid) or 0)
			bans.scroll.global_ban.box.subframe.count.header.Text = #Selections.GlobalBanSelection .. "/50"

			GlobalFieldActions(#Selections.GlobalBanSelection > 0)

			item:Destroy()
		end)

		item.MouseButton2Click:Connect(function()
			local OptionChosen = MainModule.PromptOptions({
				Header = "@" .. username,
				Options = {
					{Name = "Remove", Icon = "rbxassetid://11326877488"},
					{Name = "View Profile", Icon = "rbxassetid://11963361597"},
				}
			})

			if OptionChosen == "Remove" then
				table.remove(Selections.GlobalBanSelection, table.find(Selections.GlobalBanSelection, userid) or 0)
				bans.scroll.global_ban.box.subframe.count.header.Text = #Selections.GlobalBanSelection .. "/50"

				GlobalFieldActions(#Selections.GlobalBanSelection > 0)

				item:Destroy()

			elseif OptionChosen == "View Profile" then
				MainModule.Profile(true, item:GetAttribute("UserId"), item.profile)
			end
		end)

		item.TouchLongPress:Connect(function()
			local OptionChosen = MainModule.PromptOptions({
				Header = "@" .. username,
				Options = {
					{Name = "Remove", Icon = "rbxassetid://11326877488"},
					{Name = "View Profile", Icon = "rbxassetid://11963361597"},
				},
				Mobile = true
			})

			if OptionChosen == "Remove" then
				table.remove(Selections.GlobalBanSelection, table.find(Selections.GlobalBanSelection, userid) or 0)
				bans.scroll.global_ban.box.subframe.count.header.Text = #Selections.GlobalBanSelection .. "/50"

				GlobalFieldActions(#Selections.GlobalBanSelection > 0)

				item:Destroy()

			elseif OptionChosen == "View Profile" then
				MainModule.Profile(true, item:GetAttribute("UserId"), item.profile)
			end
		end)
	else
		Alerts.BannerNotify({
			Header = "Failed to find player.";
			Description = "This player doesn't exist.";
			Icon = "rbxassetid://11433646681"
		})
	end
end

function SearchKeywordForBanPage()
	local term = string.lower(bans.scroll.filter.search.textbox.Text)

	for i, v in bans.scroll.display.scroll:GetChildren() do
		if v:IsA("ImageButton") then
			if term ~= "" then
				local keywords = {
					v.Name,
					v.info.mod.Text,
					v.info.username.Text,
				}
				local item = string.lower(table.concat(keywords, ","))

				if string.find(item, term) then
					v.Visible = true
				else
					v.Visible = false
				end
			else
				v.Visible = true
			end
		end
	end
end

function GlobalFieldActions(state)
	if state then
		bans.scroll.global_ban.box.subframe.actions.Interactable = true

		--

		tween_service:Create(bans.scroll.global_ban.box.subframe.actions, info, {Size = UDim2.fromOffset(260, 50)}):Play()
	else
		bans.scroll.global_ban.box.subframe.actions.Interactable = false

		--

		tween_service:Create(bans.scroll.global_ban.box.subframe.actions, info, {Size = UDim2.fromOffset(0, 50)}):Play()
	end
end

function ClearInvolvedBanAttempts()
	Selections.GlobalBanSelection = {}
	bans.scroll.global_ban.box.subframe.count.header.Text = #Selections.GlobalBanSelection .. "/50"

	GlobalFieldActions(false)

	--

	for i, v in bans.scroll.global_ban.box.Frame:GetChildren() do
		if v:IsA("ImageButton") and v:HasTag("Exe6InvolvedItem") then
			v:Destroy()
		end
	end
end

bans.scroll.filter.search.textbox:GetPropertyChangedSignal("Text"):Connect(SearchKeywordForBanPage)

bans.scroll.global_ban.box.subframe.actions.ban.MouseButton1Click:Connect(function()
	if #Selections.GlobalBanSelection > 0 then
		MainModule.Ban(true, Selections.GlobalBanSelection, bans.scroll.global_ban.box.subframe.actions.ban)

		-- Clearance

		Selections.GlobalBanSelection = {}
		bans.scroll.global_ban.box.subframe.count.header.Text = #Selections.GlobalBanSelection .. "/50"

		GlobalFieldActions(false)
		ClearInvolvedBanAttempts()
	end
end)

bans.scroll.global_ban.box.subframe.actions.revoke.MouseButton1Click:Connect(function()
	if #Selections.GlobalBanSelection > 0 then
		MainModule.ConfirmationPrompt(true, {
			ID = "GlobalGameRevoke",
			Header = "Do you want to continue?",
			Description = `Do you want to Game Revoke {#Selections.GlobalBanSelection} player(s)?`,
			Accept = "Revoke"
		}, bans.scroll.global_ban.box.subframe.actions.revoke)
	end
end)

bans.scroll.global_ban.box.subframe.actions.clear.MouseButton1Click:Connect(ClearInvolvedBanAttempts)

bans.scroll.global_ban.box.Frame.Field.textbox.FocusLost:Connect(function()
	if bans.scroll.global_ban.box.Frame.Field.textbox.Text ~= "" and #Selections.GlobalBanSelection < 50 then

		AddPersonToBanPageField(bans.scroll.global_ban.box.Frame.Field.textbox.Text)
		bans.scroll.global_ban.box.Frame.Field.textbox.Text = ""

		if #Selections.GlobalBanSelection > 1 then
			bans.scroll.global_ban.box.Frame.Field.textbox:CaptureFocus()
		end

		GlobalFieldActions(#Selections.GlobalBanSelection > 0)
	end
end)

screen.page.PageLeave:Connect(function(p)
	if p == bans then
		ClearInvolvedBanAttempts()
	end
end)

events.ui.ConfirmationPromptClosed.Event:Connect(function(id, result)
	if id == "GlobalGameRevoke" and result then
		local collected = {}

		for i, userid in pairs(Selections.GlobalBanSelection) do
			table.insert(collected, userid)
		end

		MainModule.TrackProgress(true, "Revoking Ban...")

		local properties = {
			ServerOnly = false,
			SerializedIds = Utilities.SerializeNumberTable(collected)
		}

		local result = events.Activities.Primary:InvokeServer("Unban", properties)

		if result then
			UpdateBanSelection()

			Alerts.BannerNotify({
				Header = "Revoked Bans Successfully";
				Description = #result.Success .. "/" .. #result.All .. " has their bans revoked." ;
				Icon = "rbxassetid://11419712454";
				Involved = Utilities.ExtractTableContents(result.Success, 1, 5)
			})
		else
			Alerts.BannerNotify({
				Header = "Revoking Bans Failed";
				Description = "An error occurred while revoking bans.";
				Icon = "rbxassetid://11422144471";
			})
		end
		ClearInvolvedBanAttempts()
		MainModule.TrackProgress(false)
	end
end)

--

function RecordedUserIdsSelection(item, id, state)
	if state then
		if #Selections.BanSelection < 50 then
			item:SetAttribute("selected", true)

			table.insert(Selections.BanSelection, id)

			tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(38, 38, 38)}):Play()
			tween_service:Create(item.select.blue.scale, info, {Scale = 1.04}):Play()
		else
			Alerts.BannerNotify({
				Header = "Bulk Selection Limit Reached";
				Description = "You can only select 50 players at a time.";
				Icon = "rbxassetid://12974220720";
			})
		end
	else
		item:SetAttribute("selected", false)

		table.remove(Selections.BanSelection, table.find(Selections.BanSelection, id) or 0)

		tween_service:Create(item.select.blue.scale, info, {Scale = 0}):Play()
		tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(29, 29, 29)}):Play()
	end

	UpdateBanSelection()
end

function ActivateItem(item, id, server, null)
	item.MouseEnter:Connect(function()
		if not item:GetAttribute("selected") then
			tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(38, 38, 38)}):Play()
		end
	end)

	item.MouseButton1Down:Connect(function()
		if not item:GetAttribute("selected") then
			tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(22, 22, 22)}):Play()
		end
	end)

	item.InputEnded:Connect(function()
		if not item:GetAttribute("selected") then
			tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(29, 29, 29)}):Play()
		end
	end)

	item.select.MouseButton1Click:Connect(function()
		if not null then
			RecordedUserIdsSelection(item, tonumber(id), not item:GetAttribute("selected"))
		end
	end)


	item.MouseButton1Click:Connect(function()
		if not server then
			MainModule.BanHistory(true, item.ban_type.server.Visible, tonumber(id), item)
		end
	end)
end

local ongoing = 0

function LoadRecordedIdsAndStats()
	Utilities.SetBadgeOfNavigationButton("bans", true)

	ongoing = 0
	local data = events.auth.FetchRecordedIds:InvokeServer()

	if data then
		bans.scroll.charts.issued.count.Text = events.auth.VariableEncode:InvokeServer("GetVariable", "Exe6RecordedIssues") or 0
		bans.scroll.charts.kicks.count.Text = events.auth.VariableEncode:InvokeServer("GetVariable", "Exe6RecordedKicks") or 0

		for i, residual in pairs(bans.scroll.display.scroll:GetChildren()) do
			if residual:IsA("ImageButton") then
				residual:Destroy()
			end
		end

		-- Permanent UserIds
		if typeof(data.Permanent) == "table" then
			for i, comp in pairs(data.Permanent) do
				local set = string.split(comp, ";")
				local id = tonumber(set[1])
				local mod_id = tonumber(set[2] or 0)

				task.spawn(function()
					local username = players:GetNameFromUserIdAsync(id)

					local success, result = pcall(function()
						return players:GetNameFromUserIdAsync(mod_id)
					end)

					if username then
						local item = bans.scroll.display.scroll.list.item:Clone()

						item.Name = id
						item.LayoutOrder = 2
						item:SetAttribute("status", "Permanent")

						item.info.username.Text = "@" .. username

						if success and result then
							item.info.mod.Text = "Banned by @" .. result
						else
							item.info.mod.Visible = false
						end

						item.profile.Image = Utilities.GetPlayerThumbnail(id)

						item.ban_type.game.Visible = true
						item.ban_type.duration.Text = "∞"

						item.Parent = bans.scroll.display.scroll

						ongoing += 1

						--

						ActivateItem(item, id)

						item.actions.revoke.MouseButton1Click:Connect(function()
							MainModule.ConfirmationPrompt(true, {
								ID = "RevokeGameBan," .. id,
								Header = "Revoke @" .. username .. "?",
								Description = "Revoking Issued Ban will give them the ability to join this game again.",
								Accept = "Revoke"
							}, item.actions.revoke)
						end)

						item.MouseButton2Click:Connect(function()
							local OptionChosen = MainModule.PromptOptions({
								Header = "@" .. username,
								Options = {
									{Name = "View Ban History", Icon = "rbxassetid://12974250538"},
									{Name = "View Profile", Icon = "rbxassetid://11963361597"},
								}
							})

							if OptionChosen == "View Ban History" then
								MainModule.BanHistory(true, false, id, item)
							elseif OptionChosen == "View Profile" then
								MainModule.Profile(true, id, item.profile)
							end
						end)

						item.TouchLongPress:Connect(function()
							local OptionChosen = MainModule.PromptOptions({
								Header = "@" .. username,
								Options = {
									{Name = "View Ban History", Icon = "rbxassetid://12974250538"},
									{Name = "View Profile", Icon = "rbxassetid://11963361597"},
								},
								Mobile = true
							})

							if OptionChosen == "View Ban History" then
								MainModule.BanHistory(true, false, id, item)
							elseif OptionChosen == "View Profile" then
								MainModule.Profile(true, id, item.profile)
							end
						end)
					end
				end)
			end
		end

		-- Expiring UserIds
		if typeof(data.Expiring) == "table" then
			for i, comp in pairs(data.Expiring) do
				local set = string.split(comp, ";")
				local id = tonumber(set[1])
				local seconds = set[2] - os.time()
				local mod_id = tonumber(set[3] or 0)

				task.spawn(function()
					local username = players:GetNameFromUserIdAsync(id)

					local success, result = pcall(function()
						return players:GetNameFromUserIdAsync(mod_id)
					end)

					if username then
						local item = bans.scroll.display.scroll.list.item:Clone()

						if seconds and seconds > 0 then
							item.Name = id
							item.LayoutOrder = 1

							item:SetAttribute("status", "Expiring")

							item.info.username.Text = "@" .. username

							if success and result then
								item.info.mod.Text = "Banned by @" .. result
							else
								item.info.mod.Visible = false
							end

							item.profile.Image = Utilities.GetPlayerThumbnail(id)

							item.ban_type.game.Visible = true
							item.ban_type.duration.Text = Utilities.FormatSecondsToYWDHM(seconds) or "Unknown"

							item.Parent = bans.scroll.display.scroll

							ongoing += 1

							--

							ActivateItem(item, id)

							item.actions.revoke.MouseButton1Click:Connect(function()
								MainModule.ConfirmationPrompt(true, {
									ID = "RevokeGameBan," .. id,
									Header = "Revoke @" .. username .. "?",
									Description = "Revoking Issued Ban will give them the ability to join this game again.",
									Accept = "Revoke"
								}, item.actions.revoke)
							end)

							item.MouseButton2Click:Connect(function()
								local OptionChosen = MainModule.PromptOptions({
									Header = "@" .. username,
									Options = {
										{Name = "View Ban History", Icon = "rbxassetid://12974250538"},
										{Name = "View Profile", Icon = "rbxassetid://11963361597"},
									}
								})

								if OptionChosen == "View Ban History" then
									MainModule.BanHistory(true, false, id, item)
								elseif OptionChosen == "View Profile" then
									MainModule.Profile(true, id, item.profile)
								end
							end)

							item.TouchLongPress:Connect(function()
								local OptionChosen = MainModule.PromptOptions({
									Header = "@" .. username,
									Options = {
										{Name = "View Ban History", Icon = "rbxassetid://12974250538"},
										{Name = "View Profile", Icon = "rbxassetid://11963361597"},
									},
									Mobile = true
								})

								if OptionChosen == "View Ban History" then
									MainModule.BanHistory(true, false, id, item)
								elseif OptionChosen == "View Profile" then
									MainModule.Profile(true, id, item.profile)
								end
							end)
						else
							item:Destroy()
						end
					end
				end)
			end
		end

		-- Server UserIds
		if typeof(data.Server) == "table" then
			for id, v in pairs(data.Server) do
				task.spawn(function()
					local username = players:GetNameFromUserIdAsync(tonumber(id))

					local success, result = pcall(function()
						return players:GetNameFromUserIdAsync(v.ModeratorId)
					end)

					if username then
						local item = bans.scroll.display.scroll.list.item:Clone()

						item.Name = id
						item.LayoutOrder = 3

						item:SetAttribute("status", "Server")

						item.info.username.Text = "@" .. username

						if success and result then
							item.info.mod.Text = "Banned by @" .. result
						else
							item.info.mod.Visible = false
						end

						item.profile.Image = Utilities.GetPlayerThumbnail(id)

						item.ban_type.server.Visible = true
						item.ban_type.duration.Text = "∞"

						item.icon.ImageTransparency = 1

						item.Parent = bans.scroll.display.scroll

						ongoing += 1

						--

						ActivateItem(item, id, true)

						item.actions.revoke.MouseButton1Click:Connect(function()
							MainModule.ConfirmationPrompt(true, {
								ID = "RevokeServerBan," .. id,
								Header = "Revoke @" .. username .. "?",
								Description = "Revoking Issued Ban will give them the ability to join this server again.",
								Accept = "Revoke"
							}, item.actions.revoke)
						end)

						item.MouseButton2Click:Connect(function()
							local OptionChosen = MainModule.PromptOptions({
								Header = "@" .. username,
								Options = {
									{Name = "View Ban History", Icon = "rbxassetid://12974250538"},
									{Name = "View Profile", Icon = "rbxassetid://11963361597"},
								}
							})

							if OptionChosen == "View Ban History" then
								MainModule.BanHistory(true, false, id, item)
							elseif OptionChosen == "View Profile" then
								MainModule.Profile(true, id, item.profile)
							end
						end)

						item.TouchLongPress:Connect(function()
							local OptionChosen = MainModule.PromptOptions({
								Header = "@" .. username,
								Options = {
									{Name = "View Ban History", Icon = "rbxassetid://12974250538"},
									{Name = "View Profile", Icon = "rbxassetid://11963361597"},
								},
								Mobile = true
							})

							if OptionChosen == "View Ban History" then
								MainModule.BanHistory(true, false, id, item)
							elseif OptionChosen == "View Profile" then
								MainModule.Profile(true, id, item.profile)
							end
						end)
					end
				end)
			end
		end

		-- Expired UserIds
		if typeof(data.Expired) == "table" then
			for i, comp in pairs(data.Expired) do
				local set = string.split(comp, ";")

				local id = tonumber(set[1])
				local mod_id = tonumber(set[3] or 0)

				task.spawn(function()
					local username = players:GetNameFromUserIdAsync(id)

					local success, result = pcall(function()
						return players:GetNameFromUserIdAsync(mod_id)
					end)

					if username then
						local item = bans.scroll.display.scroll.list.item:Clone()

						item.Name = id
						item.LayoutOrder = 4

						item:SetAttribute("status", "Expired")

						item:RemoveTag("Exe6RecordedUserId")

						item.info.username.Text = "@" .. username

						if success and result then
							item.info.mod.Text = "Banned by @" .. result
						else
							item.info.mod.Visible = false
						end

						item.profile.Image = Utilities.GetPlayerThumbnail(id)

						item.ban_type.game.Visible = true
						item.ban_type.duration.Text = "Expired"

						item.select.blue.Visible = false
						item.select.circle.Visible = false

						item.actions.revoke.Visible = false

						item.Parent = bans.scroll.display.scroll

						ActivateItem(item, id, false, true)
					end
				end)
			end
		end

		-- Revoked UserIds
		if typeof(data.Revoked) == "table" then
			for i, comp in pairs(data.Revoked) do
				local set = string.split(comp, ";")

				local id = tonumber(set[1])

				local part1 = tonumber(set[2] or 0)
				local part2 = tonumber(set[3] or 0)

				task.spawn(function()
					local result

					local username = players:GetNameFromUserIdAsync(id)

					if set[3] then
						local success, err = pcall(function()
							result = players:GetNameFromUserIdAsync(part2)
						end)
					else
						local success, err = pcall(function()
							result = players:GetNameFromUserIdAsync(part1)
						end)
					end

					if result then
						local item = bans.scroll.display.scroll.list.item:Clone()

						item.Name = id
						item.LayoutOrder = 5

						item:SetAttribute("status", "Revoked")

						item:RemoveTag("Exe6RecordedUserId")

						item.info.username.Text = "@" .. username

						if result then
							item.info.mod.Text = "Banned by @" .. result
						else
							item.info.mod.Visible = false
						end

						item.profile.Image = Utilities.GetPlayerThumbnail(id)

						item.ban_type.game.Visible = true
						item.ban_type.duration.Text = "Revoked"

						item.select.blue.Visible = false
						item.select.circle.Visible = false

						item.actions.revoke.Visible = false

						item.Parent = bans.scroll.display.scroll

						--

						ActivateItem(item, id, false, true)
					end
				end)
			end
		end

		Utilities.SetBadgeOfNavigationButton("bans", false)
	else
		Alerts.BannerNotify({
			Header = "Failed to load Recorded User IDs.";
			Description = "Resync and try again.";
			Icon = "rbxassetid://11430232399";
		})
	end 
end

local BansResyncing = false
local BanResyncDuration = 10
local BansInitiated = false

MainModule.ScreenChanged:Connect(function(page)
	if page == bans and not BansInitiated then
		BansInitiated = true

		LoadRecordedIdsAndStats()
	end
end)

bans.scroll.filter.resync.MouseButton1Click:Connect(function()
	if not BansResyncing then
		BansResyncing = true

		bans.scroll.filter.resync.icon.Rotation = 0

		Selections.BanSelection = {}

		UpdateBanSelection()

		--

		tween_service:Create(bans.scroll.filter.resync.icon, info, {Rotation = 360}):Play()

		--

		LoadRecordedIdsAndStats()

		BansResyncing = false
	end
end)

bans.BulkActions.Actions.Frame.Revoke.MouseButton1Click:Connect(function()
	MainModule.ConfirmationPrompt(true, {
		ID = "BulkRevoke",
		Header = "Do you want to continue?",
		Description = `Do you want to revoke {#Selections.BanSelection} player(s)?`,
		Accept = "Revoke"
	}, bans.BulkActions.Actions.Frame.Revoke)
end)

events.ui.ConfirmationPromptClosed.Event:Connect(function(id, result)
	if id == "BulkRevoke" and result then
		local collected = {}

		for i, userid in pairs(Selections.BanSelection) do
			table.insert(collected, userid)
		end

		if UnbanForGameBanType then
			MainModule.TrackProgress(true, "Revoking Ban...")

			local properties = {
				ServerOnly = false,
				SerializedIds = Utilities.SerializeNumberTable(collected)
			}

			local result = events.Activities.Primary:InvokeServer("Unban", properties)

			if result then
				repeat task.wait() until not BansResyncing

				UpdateBanSelection()

				Alerts.BannerNotify({
					Header = "Revoked Bans Successfully";
					Description = #result.Success .. "/" .. #result.All .. " has their bans revoked." ;
					Icon = "rbxassetid://11419712454";
					Involved = Utilities.ExtractTableContents(result.Success, 1, 5)
				})
			else
				Alerts.BannerNotify({
					Header = "Revoking Bans Failed";
					Description = "An error occurred while revoking bans.";
					Icon = "rbxassetid://11422144471";
				})
			end

			MainModule.TrackProgress(false)
		else
			MainModule.TrackProgress(true, "Revoking Ban...")

			local properties = {
				Reason = "",
				ServerOnly = true,
				SerializedIds = Utilities.SerializeNumberTable(collected)
			}

			local result = events.Activities.Primary:InvokeServer("Unban", properties)

			if result then
				repeat task.wait() until not BansResyncing

				UpdateBanSelection()

				Alerts.BannerNotify({
					Header = "Revoked Bans Successfully";
					Description = #result.Success .. "/" .. #result.All .. " has their bans revoked." ;
					Icon = "rbxassetid://11419712454";
					Involved = Utilities.ExtractTableContents(result.Success, 1, 5)
				})
			else
				Alerts.BannerNotify({
					Header = "Revoking Bans Failed";
					Description = "An error occurred while revoking bans.";
					Icon = "rbxassetid://11422144471";
				})
			end

			MainModule.TrackProgress(false)
		end
	else
		local set = string.split(id, ",")

		if set[1] == "RevokeServerBan" or set[1] == "RevokeGameBan" then
			if not result then
				return
			end
		end

		if set[1] == "RevokeServerBan" then
			local id = tonumber(set[2])

			MainModule.TrackProgress(true, "Revoking Ban...")

			local server_bans = events.auth.FetchServerBans:InvokeServer()
			local record = server_bans[id]

			if record then
				local properties = {
					Reason = record.Reason,
					ServerOnly = true,
					SerializedIds = Utilities.SerializeNumberTable({id})
				}

				local result = events.Activities.Primary:InvokeServer("Unban", properties)

				if result then
					UpdateBanSelection()

					Alerts.BannerNotify({
						Header = "Revoked Bans Successfully";
						Description = #result.Success .. "/" .. #result.All .. " has their bans revoked." ;
						Icon = "rbxassetid://11419712454";
						Involved = Utilities.ExtractTableContents(result.Success, 1, 5)
					})
				else
					Alerts.BannerNotify({
						Header = "Revoking Bans Failed";
						Description = "An error occurred while revoking bans.";
						Icon = "rbxassetid://11422144471";
					})
				end
			end

			MainModule.TrackProgress(false)
		elseif set[1] == "RevokeGameBan" then
			local id = tonumber(set[2])

			MainModule.TrackProgress(true, "Revoking Ban...")

			local properties = {
				ServerOnly = false,
				SerializedIds = Utilities.SerializeNumberTable({id})
			}

			local result = events.Activities.Primary:InvokeServer("Unban", properties)

			if result then
				UpdateBanSelection()

				Alerts.BannerNotify({
					Header = "Revoked Bans Successfully";
					Description = #result.Success .. "/" .. #result.All .. " has their bans revoked." ;
					Icon = "rbxassetid://11419712454";
					Involved = Utilities.ExtractTableContents(result.Success, 1, 5)
				})
			else
				Alerts.BannerNotify({
					Header = "Revoking Bans Failed";
					Description = "An error occurred while revoking bans.";
					Icon = "rbxassetid://11422144471";
				})
			end

			MainModule.TrackProgress(false)
		end
	end
end)

--// ANNOUNCEMENT

announcement.Create.Button.MouseButton1Click:Connect(function()
	MainModule.Announcement(true, announcement.Create.Button)
end)

announcement.Create.Button.MouseEnter:Connect(function()
	tween_service:Create(announcement.Create.Button.scale, info, {Scale = 1.2}):Play()
end)

announcement.Create.Button.MouseButton1Down:Connect(function()
	tween_service:Create(announcement.Create.Button.scale, info, {Scale = .6}):Play()
end)

announcement.Create.Button.InputEnded:Connect(function()
	tween_service:Create(announcement.Create.Button.scale, info, {Scale = 1}):Play()
end)

events.Activities.Announcement.OnClientEvent:Connect(function(audience, AnnouncementData)
	if not table.find(audience, players.LocalPlayer.UserId) then return end

	local post = announcement.scroll.feed.list.post:Clone()
	local auth = events.auth.Auth:InvokeServer("IsAuthorized", AnnouncementData.Host)
	local ref = Utilities.GenerateUniqueCode(20)

	post.Name = ref
	post.LayoutOrder = -#announcement.scroll.feed:GetChildren()

	post:SetAttribute("Author", AnnouncementData.Host)

	post.content.information.label.Text = AnnouncementData.Description
	post.content.information.subject.Text = AnnouncementData.Header
	post.content.image.icon.Image = AnnouncementData.Icon

	post.user.profile.Image = Utilities.GetPlayerThumbnail(AnnouncementData.Host)
	post.user.display.Text = Utilities.GetDisplayNameById(AnnouncementData.Host)
	post.user.duration.Text = Utilities.FormatSecondsToRealDate(os.time() - AnnouncementData.Timestamp) or "Now"

	if auth then
		post.user.role.Visible = true
		post.user.role.Text = auth.Role.Alias
		post.user.role.BackgroundColor3 = auth.Role.Accent
		post.user.role.TextColor3 = Utilities.AdjustColor(auth.Role.Accent)
	else
		post.user.role.Visible = false
	end

	post.scale.Scale = .9

	post.Parent = announcement.scroll.feed

	if screen.page.CurrentPage ~= announcement then
		Utilities.SetBadgeOfNavigationButton("announcements", true)
	end

	--

	tween_service:Create(post.scale, info, {Scale = 1}):Play()

	--

	post.user.MouseButton1Click:Connect(function()
		MainModule.Profile(true, AnnouncementData.Host, post.user.profile)
	end)

	--

	post.MouseButton2Click:Connect(function()
		local Option = MainModule.PromptOptions({
			Options = {
				{Name = "Show Locally", Icon = "rbxassetid://11432831662"},
				{Name = "View Profile", Icon = "rbxassetid://11963361597"},
			}
		})

		if Option == "Show Locally" then
			if ui.announcement.Visible then
				Alerts.BannerNotify({
					Header = "Failed to Show Locally",
					Description = "Something went wrong. Please try again later.",
					Icon = "rbxassetid://12966403319"
				})
			else			
				Alerts.PromptAnnounce(AnnouncementData)
			end

		elseif Option == "View Profile" then
			MainModule.Profile(true, AnnouncementData.Host, post.user.profile)
		end
	end)

	post.TouchLongPress:Connect(function()
		local Option = MainModule.PromptOptions({
			Options = {
				{Name = "Show Locally", Icon = "rbxassetid://11432831662"},
				{Name = "View Profile", Icon = "rbxassetid://11963361597"},
			},
			Mobile = true
		})

		if Option == "Show Locally" then
			if ui.announcement.Visible then
				Alerts.BannerNotify({
					Header = "Failed to Show Locally",
					Description = "Something went wrong. Please try again later.",
					Icon = "rbxassetid://12966403319"
				})
			else			
				Alerts.PromptAnnounce(AnnouncementData)
			end

		elseif Option == "View Profile" then
			MainModule.Profile(true, AnnouncementData.Host, post.user.profile)
		end
	end)
end)

MainModule.ScreenChanged:Connect(function(page)
	if page == announcement then
		Utilities.SetBadgeOfNavigationButton("announcements", false)
	end
end)

--// Audit Activities

local PagesNotLoaded

local ActivitiesResyncing = false
local ActivitiesResyncCooldownTime = 60
local ActivitiesLoaded = 0

function LoadChunk(chunk, page)
	local NewPage = activity_audits.scroll.scroll.list.Page:Clone()

	NewPage.Name = "Page_"..page
	NewPage.Parent = activity_audits.scroll.scroll

	NewPage:SetAttribute("PageNumber", page)

	for i, activity in pairs(chunk) do
		task.spawn(function()
			local ActivityPost = activity_audits.scroll.scroll.list.audit:Clone()

			ActivityPost.LayoutOrder = -i
			ActivityPost:SetAttribute("Moderator", activity.Moderator)

			--// Main info

			local Involved = activity.Recipients

			ActivityPost.user.labels.duration.Text = Utilities.FormatSecondsToRealDate(activity.Timestamp - os.time())
			ActivityPost.user.labels.display.Text = Utilities.GetNameByUserIdAsync(ActivityPost:GetAttribute("Moderator"), true)
			ActivityPost.user.profile.Image = Utilities.GetPlayerThumbnail(ActivityPost:GetAttribute("Moderator"))

			ActivityPost.action.Text = activity.Message

			if activity.JobID and activity.JobID == game.JobId then
				ActivityPost.action.padding.PaddingLeft = UDim.new(0, 30)
				ActivityPost.action.badge.Visible = true
			else
				ActivityPost.action.padding.PaddingLeft = UDim.new(0, 0)
				ActivityPost.action.badge.Visible = false
			end

			--// Involved Effects

			ActivityPost.preview.more.Interactable = true
			ActivityPost.involved.Interactable = true

			ActivityPost.involved.scale.Scale = 0
			ActivityPost.involved.Visible = true

			ActivityPost.involved.AutomaticSize = Enum.AutomaticSize.None

			for _, user in pairs(Involved) do
				local ProfileRedirect = ActivityPost.involved.list.item:Clone()
				ProfileRedirect.username.Text = Utilities.GetNameByUserIdAsync(user, true)
				ProfileRedirect.profile.Image = Utilities.GetPlayerThumbnail(user)

				ProfileRedirect.MouseButton1Click:Connect(function()
					MainModule.Profile(true, user, ProfileRedirect)
				end)

				ProfileRedirect.Parent = ActivityPost.involved
			end

			if #Involved == 1 then			
				ActivityPost.preview.player1.Image = Utilities.GetPlayerThumbnail(Involved[1])
				ActivityPost.preview.player2.Visible = false

			else
				ActivityPost.preview.player1.Image = Utilities.GetPlayerThumbnail(Involved[1])
				ActivityPost.preview.player2.Image = Utilities.GetPlayerThumbnail(Involved[2])

			end

			if #Involved <= 2 then
				ActivityPost.preview.more.Text = "..."
			else
				ActivityPost.preview.more.Text = ((#Involved - 2) .. "+")
			end

			local opening = false

			ActivityPost.preview.more.MouseButton1Click:Connect(function()
				if not opening then
					opening = true

					tween_service:Create(ActivityPost.preview.scale, info, {Scale = 0}):Play()
					tween_service:Create(ActivityPost.involved.scale, info, {Scale = 1}):Play()

					--
					task.wait(.2)
					--

					ActivityPost.involved.AutomaticSize = Enum.AutomaticSize.Y
					ActivityPost.involved.list.Wraps = true

					opening = false
				end
			end)

			ActivityPost.involved.util.collapse.MouseButton1Click:Connect(function()
				if not opening then
					opening = true

					ActivityPost.involved.AutomaticSize = Enum.AutomaticSize.None
					ActivityPost.involved.list.Wraps = false

					tween_service:Create(ActivityPost.preview.scale, info, {Scale = 1}):Play()
					tween_service:Create(ActivityPost.involved.scale, info, {Scale = 0}):Play()

					opening = false
				end
			end)

			ActivityPost.user.MouseButton1Click:Connect(function()
				MainModule.Profile(true, ActivityPost:GetAttribute("Moderator"), ActivityPost.user)
			end)

			--// Make everything appear

			if #Involved == 0 then
				ActivityPost.preview.Visible = false
			else
				ActivityPost.preview.Visible = true
			end

			ActivityPost.Parent = NewPage
			ActivityPost.Visible = true

			ActivitiesLoaded += 1

			--

			Utilities.SetBadgeOfNavigationButton("audits", false)
		end)
	end
end

function ResyncActivities()
	activity_audits.Interactable = false
	Utilities.SetBadgeOfNavigationButton("audits", true)

	--

	local Activities = events.components.GetAuditActivities:InvokeServer()
	local TotalChunks = #Activities
	local ChunksLeft = #Activities

	activity_audits.scroll.scroll.Visible = false

	task.wait(info.Time)

	for _, i in pairs(activity_audits.scroll.scroll:GetChildren()) do
		if i:HasTag("AuditActivityPage") then
			i:Destroy()
		end
	end

	ActivitiesLoaded = 0

	for i, Pages in pairs(Activities) do
		LoadChunk(Activities[ChunksLeft], TotalChunks - ChunksLeft)
		ChunksLeft -= 1
	end

	activity_audits.scroll.scroll.Visible = true

	--

	activity_audits.Interactable = true
end

function SearchKeywordForAuditActivityPage()
	local term = string.lower(activity_audits.scroll.filter.search.textbox.Text)

	for i, v in pairs(activity_audits.scroll.scroll:GetDescendants()) do
		if v:IsA("ImageButton") and v:GetAttribute("Moderator") and v:HasTag("Exe6AuditPost") then
			if term ~= "" then
				local keywords = {
					v.action.Text,

					v.user.labels.display.Text,
					v.user.labels.duration.Text,
				}
				local item = string.lower(table.concat(keywords, ","))

				if string.find(item, term) then
					v.Visible = true
				else
					v.Visible = false
				end
			else
				v.Visible = true
			end
		end
	end
end

activity_audits.scroll.filter.search.textbox:GetPropertyChangedSignal("Text"):Connect(SearchKeywordForAuditActivityPage)

local ActivitiesInitialized = false

screen.page.PageEnter:Connect(function(p)
	if p == activity_audits then
		if ActivitiesInitialized then return end
		ActivitiesResyncing = true
		ActivitiesInitialized = true

		ResyncActivities()

		task.wait(ActivitiesResyncCooldownTime)

		ActivitiesResyncing = false
	end
end)

activity_audits.scroll.filter.resync.MouseButton1Click:Connect(function()
	if ActivitiesResyncing then
		Alerts.BannerNotify({
			Header = "Unable to continue";
			Description = "You can't resync Audit Activities yet.";
			Icon = "rbxassetid://12974197362";
		})
		return;
	end

	if not ActivitiesResyncing then
		ActivitiesResyncing = true

		activity_audits.scroll.filter.resync.icon.Rotation = 0

		--
		tween_service:Create(activity_audits.scroll.filter.resync.icon, info, {Rotation = 360}):Play()
		--

		ResyncActivities()

		task.wait(ActivitiesResyncCooldownTime)

		ActivitiesResyncing =  false
	end
end)

--// UTILITIES

function SearchKeywordForUtilitiesPage()
	local term = string.lower(utils_page.scroll.filter.search.textbox.Text)

	for i, v in pairs(utils_page.scroll.scroll:GetChildren()) do
		if v:IsA("ImageButton") and v:HasTag("Exe6CustomCommand") then
			if term ~= "" then
				local keywords = {
					v.Name,
					v.details.description.Text,
				}
				local item = string.lower(table.concat(keywords, ","))

				if string.find(item, term) then
					v.Visible = true
				else
					v.Visible = false
				end
			else
				v.Visible = true
			end
		end
	end
end

utils_page.scroll.filter.search.textbox:GetPropertyChangedSignal("Text"):Connect(SearchKeywordForUtilitiesPage)

function LoadCustomCommands()
	for i, dump in utils_page.scroll.scroll:GetChildren() do
		if dump:HasTag("Exe6CustomCommand") then
			dump:Destroy()
		end
	end

	for i, Command in CustomCommands.GetCommands() do
		if not table.find(Command.Access, "Team") then 
			local auth = events.auth.Auth:InvokeServer("IsAuthorized", client.UserId)
			if not auth then continue end

			if not table.find(Command.Access, auth.Role.Alias) then
				continue 
			end
		end

		local frame = utils_page.scroll.scroll.list.template:Clone()

		frame.Name = Command.Alias
		frame.Visible = true
		frame.Parent = utils_page.scroll.scroll

		frame.details.alias.Text = Command.Alias
		frame.details.icon.Image = Command.Icon
		frame.details.description.Text = Command.Description

		frame.MouseButton1Click:Connect(function()
			MainModule.PromptCustomCommand(true, Command, frame)
		end)
	end
end

local InitialCCLoadingService = false

MainModule.ScreenChanged:Connect(function(page)
	if page == utils_page then
		if InitialCCLoadingService then return end
		InitialCCLoadingService = true

		LoadCustomCommands()
	end
end)

--// SYSTEM

local Supplied = false

MainModule.ScreenChanged:Connect(function(page)
	if page == system then
		if Supplied then return end
		Supplied = true

		local build = events.ui.GetValue:InvokeServer()
		local AppIds = events.ui.GetAppIds:InvokeServer()

		if build then
			system.scroll.system.build.label.Text = build
		end

		if AppIds then
			if #AppIds > 0 then
				system.scroll.apps.empty.Visible = false

				for i, id in pairs(AppIds) do
					local success, AppInfo = pcall(function()
						return marketplace_service:GetProductInfoAsync(id)
					end)

					if success and AppInfo then
						local item = system.scroll.apps.list.app:Clone()

						item.Name = id
						item.app_name.Text = AppInfo.Name
						item.creator.Text = AppInfo.Creator.Name
						item.Parent = system.scroll.apps
					end
				end
			end
		end
	end
end)

screen.page:GetPropertyChangedSignal("CurrentPage"):Connect(function()
	activity_audits.scroll.scroll.Visible = (screen.page.CurrentPage == activity_audits)
	bans.scroll.display.Visible = (screen.page.CurrentPage == bans)
end)

--// Server Uptime

local stopwatch = home.scroll.overview.uptime.stopwatch

task.spawn(function()
	while task.wait(1) do
		local uptime = Utilities.FormatTime(storage:GetAttribute("ServerUptime"))

		if uptime.Seconds ~= stopwatch.Seconds.Text then
			stopwatch.Seconds.Text = uptime.Seconds
			stopwatch.Seconds.TextTransparency = 1

			stopwatch.Seconds.padding.PaddingTop = UDim.new(.6, 0)

			--

			tween_service:Create(stopwatch.Seconds, info, {TextTransparency = 0}):Play()
			tween_service:Create(stopwatch.Seconds.padding, info, {PaddingTop = UDim.new(0, 0)}):Play()
		end

		if uptime.Minutes ~= stopwatch.Minutes.Text then
			task.wait(.03)
			--

			stopwatch.Minutes.Text = uptime.Minutes
			stopwatch.Minutes.TextTransparency = 1

			stopwatch.Minutes.padding.PaddingTop = UDim.new(.6, 0)

			--

			tween_service:Create(stopwatch.Minutes, info, {TextTransparency = 0}):Play()
			tween_service:Create(stopwatch.Minutes.padding, info, {PaddingTop = UDim.new(0, 0)}):Play()
		end

		if uptime.Hours ~= stopwatch.Hours.Text then
			task.wait(.07)
			--

			stopwatch.Hours.Text = uptime.Hours
			stopwatch.Hours.TextTransparency = 1

			stopwatch.Hours.padding.PaddingTop = UDim.new(.6, 0)

			--

			tween_service:Create(stopwatch.Hours, info, {TextTransparency = 0}):Play()
			tween_service:Create(stopwatch.Hours.padding, info, {PaddingTop = UDim.new(0, 0)}):Play()
		end

		if uptime.Days ~= stopwatch.Days.Text then
			task.wait(.1)
			--

			stopwatch.Days.Text = uptime.Days
			stopwatch.Days.TextTransparency = 1

			stopwatch.Days.padding.PaddingTop = UDim.new(.6, 0)

			--

			tween_service:Create(stopwatch.Days, info, {TextTransparency = 0}):Play()
			tween_service:Create(stopwatch.Days.padding, info, {PaddingTop = UDim.new(0, 0)}):Play()
		end
	end
end)

--// Badges

local processing_tweeninfo = TweenInfo.new(.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

tween_service:Create(screen.Parent.navigation.directory.primary.bans.util.badge_container.badge, processing_tweeninfo, 
	{ImageTransparency = .5}):Play()
tween_service:Create(screen.Parent.navigation.directory.primary.bans.util.badge_container.badge.scale, processing_tweeninfo, 
	{Scale = .6}):Play()

tween_service:Create(screen.Parent.navigation.directory.primary.audits.util.badge_container.badge, processing_tweeninfo, 
	{ImageTransparency = .5}):Play()
tween_service:Create(screen.Parent.navigation.directory.primary.audits.util.badge_container.badge.scale, processing_tweeninfo, 
	{Scale = .6}):Play()

tween_service:Create(screen.Parent.navigation.directory.primary.utilities.util.badge_container.badge, processing_tweeninfo, 
	{ImageTransparency = .5}):Play()
tween_service:Create(screen.Parent.navigation.directory.primary.utilities.util.badge_container.badge.scale, processing_tweeninfo, 
	{Scale = .6}):Play()

--

while true do
	bans.scroll.charts.ongoing.count.Text = ongoing
	activity_audits.scroll.charts.activities.count.Text = ActivitiesLoaded
	ui.main_frame.content.LeafletControls.Top.Clock.Label.Text = Utilities.FormatEpochData(os.time()).Time.Hour .. ":" .. Utilities.FormatEpochData(os.time()).Time.Minutes

	--
	task.wait(1)
end