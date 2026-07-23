local tween_service = game:GetService("TweenService")
local marketplace_service = game:GetService("MarketplaceService")
local input_service = game:GetService("UserInputService")
local run_service = game:GetService("RunService")

local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local quick = TweenInfo.new(.2, Enum.EasingStyle.Exponential)

local smooth = TweenInfo.new(.8, Enum.EasingStyle.Quart)

local back = TweenInfo.new(.5, Enum.EasingStyle.Back)

local nano = TweenInfo.new(.001)

local loop = TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, -1, false)

local client = players.LocalPlayer

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local events = storage.events

local Configuration = events.auth.Auth:InvokeServer("GetConfigurations")
local MainModule = require(storage.modules.MainModule)
local Utilities = require(storage.modules.Utilities)
local Alerts = require(storage.modules.Alerts)
local Leaflet = require(storage.modules.Leaflet)
local Tracking = require(storage.modules.Tracking)

local ui = script.Parent.Parent
local modals = script.Parent

local profile = modals.profile
local ban = modals.ban
local kick = modals.kick
local ban_history = modals.ban_history
local server_teleportation = modals.server_teleportation
local progress_tracker = modals.progress_tracker
local character_viewer = modals.character_viewer
local role_info = modals.role_info
local announcement = modals.announcement
local notify = modals.notify
local confirmation_prompt = modals.confirmation
local warn = modals.warn
local chat_history = modals.chat_history
local warn_history = modals.warn_history
local privacy = modals.privacy
local custom_command = modals.custom_command
local notification_history = modals.notification_history
local live_track = modals.live_track
local fly = modals.fly

local param_enum = modals.parameter_enum
local param_player = modals.parameter_player

local camera = workspace.CurrentCamera

--// LEAFLETS

Leaflet:ApplyMainFrame(ui.main_frame, {
	MinSize = Vector2.new(500, 400),
})

Leaflet:Apply(ui.announcement, {
	MinSize = Vector2.new(450, 350),
	MaxSize = Vector2.new(700, 800),
	LockedZIndex = true,
	NormalizeSize = false,
	DisableForcedClose = true,
})

Leaflet:Apply(announcement, {
	MinSize = Vector2.new(500, 400),
	MaxSize = Vector2.new(600, 900),
})

Leaflet:Apply(ban, {
	MinSize = Vector2.new(500, 450),
	MaxSize = Vector2.new(700, 900),
})

Leaflet:Apply(ban_history, {
	MinSize = Vector2.new(500, 400),
	MaxSize = Vector2.new(700, 900),
})

Leaflet:Apply(character_viewer, {
	MinSize = Vector2.new(450, 500),
	MaxSize = Vector2.new(600, 700),
	LockedZIndex = true,
	DragDisabled = true,
	DisablePanelWhenFocused = true,
	DisableOtherLeafWhenFocused = true,
})

Leaflet:Apply(chat_history, {
	MinSize = Vector2.new(500, 400),
	MaxSize = Vector2.new(700, 900),
})

Leaflet:Apply(confirmation_prompt, {
	MinSize = Vector2.new(450, 220),
	MaxSize = Vector2.new(450, 220),
	LockedZIndex = true,
	DisablePanelWhenFocused = true,
	DisableOtherLeafWhenFocused = true,
	DisableForcedClose = true,
})

Leaflet:Apply(kick, {
	MinSize = Vector2.new(500, 400),
	MaxSize = Vector2.new(700, 900),
})

Leaflet:Apply(notify, {
	MinSize = Vector2.new(500, 400),
	MaxSize = Vector2.new(600, 900),
})

Leaflet:Apply(param_enum, {
	MinSize = Vector2.new(500, 500),
	MaxSize = Vector2.new(700, 900),
	LockedZIndex = true,
	DisablePanelWhenFocused = true,
	DisableOtherLeafWhenFocused = true,
	DisableForcedClose = true,
})

Leaflet:Apply(param_player, {
	MinSize = Vector2.new(500, 500),
	MaxSize = Vector2.new(700, 900),
	LockedZIndex = true,
	DisablePanelWhenFocused = true,
	DisableOtherLeafWhenFocused = true,
	DisableForcedClose = true,
})

Leaflet:Apply(privacy, {
	MinSize = Vector2.new(400, 400),
	MaxSize = Vector2.new(500, 600),
})

Leaflet:Apply(profile, {
	MinSize = Vector2.new(450, 500),
	MaxSize = Vector2.new(600, 900),
})

Leaflet:Apply(progress_tracker, {
	MinSize = Vector2.new(300, 270),
	MaxSize = Vector2.new(300, 270),
	LockedZIndex = true,
	DisablePanelWhenFocused = true,
	DisableOtherLeafWhenFocused = true,
	DisableForcedClose = true,
})

Leaflet:Apply(role_info, {
	MinSize = Vector2.new(400, 500),
	MaxSize = Vector2.new(600, 900),
})

Leaflet:Apply(server_teleportation, {
	MinSize = Vector2.new(400, 400),
	MaxSize = Vector2.new(600, 600),
})

Leaflet:Apply(warn, {
	MinSize = Vector2.new(500, 400),
	MaxSize = Vector2.new(600, 700),
})

Leaflet:Apply(warn_history, {
	MinSize = Vector2.new(500, 400),
	MaxSize = Vector2.new(700, 900),
})

Leaflet:Apply(custom_command, {
	MinSize = Vector2.new(500, 400),
	MaxSize = Vector2.new(700, 900),
})

Leaflet:Apply(notification_history, {
	MinSize = Vector2.new(500, 400),
	MaxSize = Vector2.new(700, 900),
})

Leaflet:Apply(live_track, {
	MinSize = Vector2.new(450, 500),
	MaxSize = Vector2.new(500, 700),
})

Leaflet:Apply(fly, {
	MinSize = Vector2.new(400, 400),
	MaxSize = Vector2.new(400, 400),
})


--// PROFILE

profile.frame.content.scroll.primary.kick.MouseButton1Click:Connect(function()
	MainModule.Kick(true, {profile:GetAttribute("UserId")}, profile.frame.content.scroll.primary.kick)
end)

profile.frame.content.scroll.primary.ban.MouseButton1Click:Connect(function()
	MainModule.Ban(true, {profile:GetAttribute("UserId")}, profile.frame.content.scroll.primary.ban)
end)

profile.frame.content.scroll.primary.notify.MouseButton1Click:Connect(function()
	MainModule.Notify(true, {profile:GetAttribute("UserId")}, profile.frame.content.scroll.primary.notify)
end)

profile.frame.content.scroll.primary.warn.MouseButton1Click:Connect(function()
	MainModule.Warn(true, {profile:GetAttribute("UserId")}, profile.frame.content.scroll.primary.warn)
end)

function PromptRoleOfProfile(Source)
	local role = events.auth.Auth:InvokeServer("IsAuthorized", profile:GetAttribute("UserId"))

	if role then
		MainModule.RoleInfo(true, role.Role.Alias, Source)
	else
		Alerts.BannerNotify({
			Header = "Failed To Fetch Role Details",
			Description = "An error occurred upon fetching role information.",
			Icon = "rbxassetid://11422145135",
			Involved = {profile:GetAttribute("UserId")}
		})
	end
end

profile.frame.content.scroll.team.role.MouseButton1Click:Connect(function()
	PromptRoleOfProfile(profile.frame.content.scroll.team.role)
end)

profile.frame.content.scroll.status.team.MouseButton1Click:Connect(function()
	PromptRoleOfProfile(profile.frame.content.scroll.status.team)
end)

profile.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.Profile(false)
end)

players.PlayerRemoving:Connect(function(person)
	if profile:GetAttribute("UserId") == person.UserId and profile.Visible then
		local userid = person.UserId

		MainModule.Profile(false)

		--
		task.wait(1)
		--

		MainModule.Profile(true, userid)

		Alerts.BannerNotify({
			Header = "This Player has Left.";
			Description = "Reopened Profile menu with offline features.";
			Icon = "rbxassetid://11963361597";
			Involved = {userid};
		})
	end
end)

local ProfileActions = profile.frame.content.scroll

for i, ProfileTextbox in pairs(ProfileActions:GetDescendants()) do
	if ProfileTextbox:IsA("ImageButton") and ProfileTextbox:HasTag("Exe6ProfileTextbox") then

		ProfileTextbox.MouseButton1Click:Connect(function()
			ProfileTextbox.value.Visible = true
			ProfileTextbox.value:CaptureFocus()
		end)

		ProfileTextbox.value.FocusLost:Connect(function()
			ProfileTextbox.value.Visible = false
		end)

	end
end

ProfileActions.humanoid.health.value.FocusLost:Connect(function()
	local value = tonumber(ProfileActions.humanoid.health.value.Text)
	if not value then return end

	events.Activities.Humanoid:FireServer(profile:GetAttribute("UserId"), "Health", value)
end)

ProfileActions.humanoid.speed.value.FocusLost:Connect(function()
	local value = tonumber(ProfileActions.humanoid.speed.value.Text)
	if not value then return end

	events.Activities.Humanoid:FireServer(profile:GetAttribute("UserId"), "Speed", value)
end)

ProfileActions.humanoid.jump.value.FocusLost:Connect(function()
	local value = tonumber(ProfileActions.humanoid.jump.value.Text)
	if not value then return end

	events.Activities.Humanoid:FireServer(profile:GetAttribute("UserId"), "Jump", value)
end)


profile.frame.content.scroll.more.spectate.MouseButton1Click:Connect(function()
	MainModule.Spectate(true, profile:GetAttribute("UserId"))
end)

ui.spectate.frame.menu.close.MouseButton1Click:Connect(function()
	MainModule.Spectate(false)
end)


profile.frame.content.scroll.history.chat.MouseButton1Click:Connect(function()
	MainModule.ChatHistory(true, profile:GetAttribute("UserId"), profile.frame.content.scroll.history.chat)
end)

profile.frame.content.scroll.history.ban.MouseButton1Click:Connect(function()
	MainModule.BanHistory(true, false, profile:GetAttribute("UserId"), profile.frame.content.scroll.history.ban)
end)

profile.frame.content.scroll.history.warning.MouseButton1Click:Connect(function()
	MainModule.WarnHistory(true, profile:GetAttribute("UserId"), profile.frame.content.scroll.history.warning)
end)

profile.frame.content.scroll.freeze.freeze.MouseButton1Click:Connect(function()
	events.Activities.Character:FireServer(profile:GetAttribute("UserId"), "Freeze")
end)

profile.frame.content.scroll.freeze.unfreeze.MouseButton1Click:Connect(function()
	events.Activities.Character:FireServer(profile:GetAttribute("UserId"), "Unfreeze")
end)

profile.frame.content.scroll.teleportation.follow.MouseButton1Click:Connect(function()
	events.Activities.Character:FireServer(profile:GetAttribute("UserId"), "Follow")
end)

profile.frame.content.scroll.teleportation.bring.MouseButton1Click:Connect(function()
	events.Activities.Character:FireServer(profile:GetAttribute("UserId"), "Bring")
end)

profile.frame.content.scroll.visibility.invisible.MouseButton1Click:Connect(function()
	events.Activities.Character:FireServer(profile:GetAttribute("UserId"), "Invisible")
end)

profile.frame.content.scroll.visibility.visible.MouseButton1Click:Connect(function()
	events.Activities.Character:FireServer(profile:GetAttribute("UserId"), "Visible")
end)

profile.frame.content.scroll.visibility.set.value.FocusLost:Connect(function()
	local value = tonumber(ProfileActions.visibility.set.value.Text)
	if not value then return end

	value = math.clamp(value, 0, 1)

	events.Activities.Character:FireServer(profile:GetAttribute("UserId"), "Transparency", value)
end)

profile.frame.content.scroll.more.copy.MouseButton1Click:Connect(function()
	events.Activities.Character:FireServer(profile:GetAttribute("UserId"), "Shapeshift")
end)

profile.frame.content.scroll.fly.fly.MouseButton1Click:Connect(function()
	MainModule.Fly(true, profile.frame.content.scroll.fly.fly)
end)

profile.frame.content.scroll.fly.disable.MouseButton1Click:Connect(function()
	events.NoClip.NoClip:InvokeServer(client, false)
end)

profile.frame.content.scroll.tracking.track.MouseButton1Click:Connect(function()
	local recipient = players:GetPlayerByUserId(profile:GetAttribute("UserId"))

	if recipient then
		Tracking.SetTrack(recipient.Character, true)

		Alerts.BannerNotify({
			Header = "Successfully Tracked",
			Description = recipient.DisplayName .. " is now being tracked.",
			Icon = "rbxassetid://12967713729",
			Involved = {profile:GetAttribute("UserId")}
		})
	end
end)

profile.frame.content.scroll.tracking.stop.MouseButton1Click:Connect(function()
	local recipient = players:GetPlayerByUserId(profile:GetAttribute("UserId"))

	if recipient then
		Tracking.SetTrack(recipient.Character, false)

		Alerts.BannerNotify({
			Header = "Stopped Tracking",
			Description = "You stopped tracking " .. recipient.DisplayName .. ".",
			Icon = "rbxassetid://12966825204",
			Involved = {profile:GetAttribute("UserId")}
		})
	end
end)

profile.frame.content.scroll.tracking.live_track.MouseButton1Click:Connect(function()
	local recipient = players:GetPlayerByUserId(profile:GetAttribute("UserId"))

	if recipient then
		Tracking.SetTrack(recipient.Character, true)
		MainModule:LiveTrack(recipient.Character, profile.frame.content.scroll.tracking.live_track)
	end
end)

profile.frame.content.scroll.more.view.MouseButton1Click:Connect(function()
	MainModule.CharacterViewer(true, profile:GetAttribute("UserId"), profile.frame.content.scroll.more.view)
end)

--// BAN

local ban_properties = ban.frame.content.properties

function animate_expiration_object(expiration)
	task.spawn(function()
		ban_properties.scroll.duration.box.textbox.Interactable = false

		ban_properties.scroll.duration.box.expiration.date.gradient.Offset = Vector2.new(-1, 0)
		ban_properties.scroll.duration.box.expiration.date.gradient.Rotation = 0

		tween_service:Create(ban_properties.scroll.duration.box.expiration.date.gradient, info,{Offset = Vector2.new(1, 0)}):Play()

		--
		task.wait(.5)
		--

		ban_properties.scroll.duration.box.expiration.date.Text = expiration

		ban_properties.scroll.duration.box.expiration.date.gradient.Offset = Vector2.new(-1, 0)
		ban_properties.scroll.duration.box.expiration.date.gradient.Rotation = -180

		tween_service:Create(ban_properties.scroll.duration.box.expiration.date.gradient, info,{Offset = Vector2.new(1, 0)}):Play()
		tween_service:Create(ban_properties.scroll.duration.box.expiration, info, 
			{Size = UDim2.new(0, ban_properties.scroll.duration.box.expiration.date.AbsoluteSize.X + 30, 1, -2)}):Play()

		--
		task.wait(.5)
		--

		ban_properties.scroll.duration.box.textbox.Interactable = true
	end)
end

ban_properties.bottom.Ban.Button.MouseButton1Click:Connect(function()
	local deserialized = Utilities.DeserializeNumberTable(ban:GetAttribute("SerializedIds"))

	MainModule.ConfirmationPrompt(true, {
		ID = "Ban",
		Header = "Ban ".. #deserialized .." player(s)?",
		Description = "This action will prevent them from entering the game.",
		Accept = "Ban"
	}, ban_properties.bottom.Ban.Button)
end)

events.ui.ConfirmationPromptClosed.Event:Connect(function(id, result)
	if id == "Ban" and result then
		MainModule.TrackProgress(true, "Issuing Ban...")

		local result, err = events.Activities.Primary:InvokeServer("Ban", ban:GetAttributes())

		if result then
			MainModule.Ban(false)
			Alerts.BannerNotify({
				Header = "Ban Issued Successfully";
				Description = #result.Success .. "/" .. #result.All .. " has been successfully banned." ;
				Icon = "rbxassetid://11419712454";
				Involved = Utilities.ExtractTableContents(result.Success, 1, 5)
			})
		else
			Alerts.BannerNotify({
				Header = "Issuing Ban Failed";
				Description = err;
				Icon = "rbxassetid://11422144471";
			})
		end

		MainModule.TrackProgress(false)
	end
end)

ban_properties.scroll.reason.textbox:GetPropertyChangedSignal("Text"):Connect(function()
	local count = ban_properties.scroll.reason.textbox.Text:len()

	ban_properties.scroll.reason.limit.Text = count .. "/400"

	if count > 400 then
		tween_service:Create(ban_properties.scroll.reason.header.header.badge, info, {
			ImageTransparency = 0, Size = UDim2.fromOffset(10, 10)}):Play()
	else
		tween_service:Create(ban_properties.scroll.reason.header.header.badge, info, {
			ImageTransparency = 1, Size = UDim2.fromOffset(-10, 10)}):Play()
	end
end)

ban_properties.scroll.moderator_note.textbox:GetPropertyChangedSignal("Text"):Connect(function()
	local count = ban_properties.scroll.moderator_note.textbox.Text:len()

	ban_properties.scroll.moderator_note.limit.Text = count .. "/1000"

	if count > 1000 then
		tween_service:Create(ban_properties.scroll.moderator_note.header.header.badge, info, {
			ImageTransparency = 0, Size = UDim2.fromOffset(10, 10)}):Play()
	else
		tween_service:Create(ban_properties.scroll.moderator_note.header.header.badge, info, {
			ImageTransparency = 1, Size = UDim2.fromOffset(-10, 10)}):Play()
	end
end)

ban_properties.scroll.reason.textbox.FocusLost:Connect(function()
	local final = Utilities.TrimString(ban_properties.scroll.reason.textbox.Text, 400)

	if ban_properties.scroll.moderator_note.textbox.Text == "" or 
		(ban_properties.scroll.moderator_note.textbox.Text == ban_properties.scroll.reason.textbox.Text) then

		ban_properties.scroll.moderator_note.textbox.Text = ban_properties.scroll.reason.textbox.Text
		ban:SetAttribute("ModeratorNote", final)
	end

	ban_properties.scroll.reason.textbox.Text = final
	ban:SetAttribute("Reason", final)
end)

ban_properties.scroll.reason.header.predefined_reasons.MouseButton1Click:Connect(function()
	local reason = MainModule.ParameterEnum(true, Configuration.PredefinedReasons, NumberRange.new(1, 1), "Ban Reason",
		ban_properties.scroll.reason.header.predefined_reasons)

	if reason then
		ban_properties.scroll.reason.textbox.Text = reason[1]

		Utilities.AnimateFillTextbox(ban_properties.scroll.reason.textbox)

		local final = Utilities.TrimString(ban_properties.scroll.reason.textbox.Text, 400)

		if ban_properties.scroll.moderator_note.textbox.Text == "" or 
			(ban_properties.scroll.moderator_note.textbox.Text == ban_properties.scroll.reason.textbox.Text) then

			ban_properties.scroll.moderator_note.textbox.Text = ban_properties.scroll.reason.textbox.Text
			ban:SetAttribute("ModeratorNote", final)
		end

		ban_properties.scroll.reason.textbox.Text = final
		ban:SetAttribute("Reason", final)
	end
end)

ban_properties.scroll.moderator_note.header.predefined_reasons.MouseButton1Click:Connect(function()
	local moderator_note = MainModule.ParameterEnum(true, Configuration.PredefinedReasons, NumberRange.new(1, 1), "Moderator Note",
		ban_properties.scroll.moderator_note.header.predefined_reasons)

	if moderator_note then
		ban_properties.scroll.moderator_note.textbox.Text = moderator_note[1]

		Utilities.AnimateFillTextbox(ban_properties.scroll.moderator_note.textbox)

		local final = Utilities.TrimString(ban_properties.scroll.moderator_note.textbox.Text, 1000)

		ban_properties.scroll.moderator_note.textbox.Text = final
		ban:SetAttribute("ModeratorNote", final)
	end
end)

ban_properties.scroll.moderator_note.textbox.FocusLost:Connect(function()
	ban_properties.scroll.moderator_note.textbox.Text = Utilities.TrimString(ban_properties.scroll.moderator_note.textbox.Text, 1000)

	ban:SetAttribute("ModeratorNote", ban_properties.scroll.moderator_note.textbox.Text)
end)

ban_properties.scroll.duration.box.textbox.FocusLost:Connect(function()
	local seconds = Utilities.FormatTimeStringToSeconds(ban_properties.scroll.duration.box.textbox.Text)
	local expiration = Utilities.FormatSecondsToRealDate(seconds)

	ban:SetAttribute("Duration", seconds)

	animate_expiration_object(expiration)
end)

ban_properties.scroll.settings.permanent.MouseButton1Click:Connect(function()
	if ban:GetAttribute("Duration") == -1 then
		Utilities.SwitchToggle(ban_properties.scroll.settings.permanent.switch, false)

		ban_properties.scroll.duration.Interactable = true
		ban_properties.scroll.duration.util.gray.Visible = false

		--

		local seconds = Utilities.FormatTimeStringToSeconds(ban_properties.scroll.duration.box.textbox.Text)
		local expiration = Utilities.FormatSecondsToRealDate(seconds)

		ban:SetAttribute("Duration", seconds)
		animate_expiration_object(expiration)
	else
		Utilities.SwitchToggle(ban_properties.scroll.settings.permanent.switch, true)

		ban_properties.scroll.duration.Interactable = false
		ban_properties.scroll.duration.util.gray.Visible = true

		ban:SetAttribute("Duration", -1)
	end
end)

ban_properties.scroll.settings.alts.MouseButton1Click:Connect(function()
	local status = ban:GetAttribute("ExcludeAltAccounts")

	Utilities.SwitchToggle(ban_properties.scroll.settings.alts.switch, not status)
	ban:SetAttribute("ExcludeAltAccounts", not status)
end)

ban_properties.scroll.settings.server.MouseButton1Click:Connect(function()
	if ban:GetAttribute("ServerOnly") then
		ban_properties.scroll.duration.Interactable = false
		ban_properties.scroll.duration.util.gray.Visible = true

		ban_properties.scroll.moderator_note.Interactable = true
		ban_properties.scroll.moderator_note.util.gray.Visible = false

		ban_properties.scroll.settings.permanent.Interactable = true
		ban_properties.scroll.settings.permanent.gray.Visible = false

		ban_properties.scroll.settings.alts.Interactable = true
		ban_properties.scroll.settings.alts.gray.Visible = false


		ban:SetAttribute("Duration", -1)
		ban:SetAttribute("ServerOnly", false)

		Utilities.SwitchToggle(ban_properties.scroll.settings.permanent.switch, true)
		Utilities.SwitchToggle(ban_properties.scroll.settings.server.switch, false)
	else
		ban_properties.scroll.duration.Interactable = false
		ban_properties.scroll.duration.util.gray.Visible = true

		ban_properties.scroll.moderator_note.Interactable = false
		ban_properties.scroll.moderator_note.util.gray.Visible = true

		ban_properties.scroll.settings.permanent.Interactable = false
		ban_properties.scroll.settings.permanent.gray.Visible = true

		ban_properties.scroll.settings.alts.Interactable = false
		ban_properties.scroll.settings.alts.gray.Visible = true

		ban:SetAttribute("Duration", -1)
		ban:SetAttribute("ServerOnly", true)

		Utilities.SwitchToggle(ban_properties.scroll.settings.permanent.switch, true)
		Utilities.SwitchToggle(ban_properties.scroll.settings.server.switch, true)
	end
end)

events.ui.ModalToggled.Event:Connect(function(modal, state)
	if modal == ban and state then
		Utilities.SwitchToggle(ban_properties.scroll.settings.alts.switch, ban:GetAttribute("ExcludeAltAccounts"))

		animate_expiration_object(Utilities.FormatSecondsToRealDate(86400))
	end
end)

ban.frame.content.players.bottom.Back.Button.MouseButton1Click:Connect(function()
	ban.frame.content.page:JumpTo(ban.frame.content.properties)
end)

ban.frame.content.properties.bottom.Manage.Button.MouseButton1Click:Connect(function()
	ban.frame.content.page:JumpTo(ban.frame.content.players)
end)

ban.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.Ban(false)
end)

ban.frame.LeafletControls.Top.Pin.Button.MouseButton1Click:Connect(function()
	MainModule.TrackProgress(true)

	local Action = "Ban"
	local pins = events.auth.FetchPins:InvokeServer(client.UserId)
	if not pins then MainModule.TrackProgress(false) return end

	if table.find(pins, Action) then
		events.auth.ActionPinning:InvokeServer("Unpin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Ban.Visible = false

		Alerts.BannerNotify({
			Header = `Unpinned the {Action} action.`,
			Icon = "rbxassetid://12974257382"
		})
	else
		events.auth.ActionPinning:InvokeServer("Pin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Ban.Visible = true

		Alerts.BannerNotify({
			Header = `Pinned the {Action} action.`,
			Icon = "rbxassetid://12974469173"
		})
	end

	MainModule.TrackProgress(false)
end)

--// KICK

local kick_properties = kick.frame.content.properties

kick_properties.bottom.Kick.Button.MouseButton1Click:Connect(function()
	local deserialized = Utilities.DeserializeNumberTable(kick:GetAttribute("SerializedIds"))

	MainModule.ConfirmationPrompt(true, {
		ID = "Kick",
		Header = "Kick ".. #deserialized .." player(s)?",
		Description = "This action will remove them from this server.",
		Accept = "Kick"
	}, kick_properties.bottom.Kick.Button)
end)

events.ui.ConfirmationPromptClosed.Event:Connect(function(id, result)
	if id == "Kick" and result then
		local result = events.Activities.Primary:InvokeServer("Kick", kick:GetAttributes())

		if kick:GetAttribute("TrackWarn") then
			local properties = {
				SerializedIds = kick:GetAttribute("SerializedIds"),
				Warning = kick:GetAttribute("Reason")
			}

			local warn = events.Activities.Primary:InvokeServer("Warn", properties)
		end

		if result then
			MainModule.Kick(false)

			Alerts.BannerNotify({
				Header = "Kicked Successfully";
				Description = #result.Success .. "/" .. #result.All .. " has been successfully kicked." ;
				Icon = "rbxassetid://11419712454";
				Involved = Utilities.ExtractTableContents(result.Success, 1, 5)
			})
		else
			Alerts.BannerNotify({
				Header = "Kick Failed";
				Description = "An error occurred while attempting to kick.";
				Icon = "rbxassetid://11422144471";
			})
		end
	elseif id == "Kick" and not result then
		Alerts.BannerNotify({
			Header = "Kick Failed";
			Description = "An error occurred while attempting to kick.";
			Icon = "rbxassetid://11422144471";
		})
	end
end)

kick_properties.scroll.reason.textbox:GetPropertyChangedSignal("Text"):Connect(function()
	local count = kick_properties.scroll.reason.textbox.Text:len()

	kick_properties.scroll.reason.limit.Text = count .. "/200"

	if count > 200 then
		tween_service:Create(kick_properties.scroll.reason.header.header.badge, info, {
			ImageTransparency = 0, Size = UDim2.fromOffset(10, 10)}):Play()
	else
		tween_service:Create(kick_properties.scroll.reason.header.header.badge, info, {
			ImageTransparency = 1, Size = UDim2.fromOffset(-10, 10)}):Play()
	end
end)

kick_properties.scroll.reason.textbox.FocusLost:Connect(function()
	local final = Utilities.TrimString(kick_properties.scroll.reason.textbox.Text, 200)

	kick_properties.scroll.reason.textbox.Text = final
	kick:SetAttribute("Reason", final)
end)

kick_properties.scroll.reason.header.predefined_reasons.MouseButton1Click:Connect(function()
	local reason = MainModule.ParameterEnum(true, Configuration.PredefinedReasons, NumberRange.new(1, 1), "Kick Reason",
		kick_properties.scroll.reason.header.predefined_reasons)

	if reason then
		kick_properties.scroll.reason.textbox.Text = reason[1]

		Utilities.AnimateFillTextbox(kick_properties.scroll.reason.textbox)

		local final = Utilities.TrimString(kick_properties.scroll.reason.textbox.Text, 200)

		kick_properties.scroll.reason.textbox.Text = final
		kick:SetAttribute("Reason", final)
	end
end)

kick_properties.scroll.settings.warn.MouseButton1Click:Connect(function()
	local status = kick:GetAttribute("TrackWarn")

	Utilities.SwitchToggle(kick_properties.scroll.settings.warn.switch, not status)
	kick:SetAttribute("TrackWarn", not status)
end)

kick.frame.content.players.bottom.Back.Button.MouseButton1Click:Connect(function()
	kick.frame.content.page:JumpTo(kick.frame.content.properties)
end)

kick.frame.content.properties.bottom.Manage.Button.MouseButton1Click:Connect(function()
	kick.frame.content.page:JumpTo(kick.frame.content.players)
end)

kick.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.Kick(false)
end)

kick.frame.LeafletControls.Top.Pin.Button.MouseButton1Click:Connect(function()
	MainModule.TrackProgress(true)

	local Action = "Kick"
	local pins = events.auth.FetchPins:InvokeServer(client.UserId)
	if not pins then MainModule.TrackProgress(false) return end

	if table.find(pins, Action) then
		events.auth.ActionPinning:InvokeServer("Unpin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Kick.Visible = false

		Alerts.BannerNotify({
			Header = `Unpinned the {Action} action.`,
			Icon = "rbxassetid://12974257382"
		})
	else
		events.auth.ActionPinning:InvokeServer("Pin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Kick.Visible = true

		Alerts.BannerNotify({
			Header = `Pinned the {Action} action.`,
			Icon = "rbxassetid://12974469173"
		})
	end

	MainModule.TrackProgress(false)
end)

--// BAN HISTORY

ban_history.frame.content.bottom.Revoke.Button.MouseButton1Click:Connect(function()
	MainModule.BanHistory(false)

	if ban_history.frame.content.scroll.information.game_type.Visible then
		MainModule.ConfirmationPrompt(true, {
			ID = "RevokeGameBan".. ban_history:GetAttribute("UserId"),
			Header = "Revoke " .. Utilities.GetNameByUserIdAsync(ban_history:GetAttribute("UserId"), true) .. "?",
			Description = "Revoking Issued Ban will give them the ability to join this game again.",
			Accept = "Revoke"
		}, ban_history.frame.content.bottom.Revoke.Button)
	else
		MainModule.ConfirmationPrompt(true, {
			ID = "RevokeServerBan".. ban_history:GetAttribute("UserId"),
			Header = "Revoke " .. Utilities.GetNameByUserIdAsync(ban_history:GetAttribute("UserId"), true) .. "?",
			Description = "Revoking Issued Ban will give them the ability to join this server again.",
			Accept = "Revoke"
		}, ban_history.frame.content.bottom.Revoke.Button)
	end
end)

ban_history.frame.content.scroll.information.profile.MouseButton1Click:Connect(function()
	MainModule.BanHistory(false)
	MainModule.Profile(true, ban_history:GetAttribute("UserId"), ban_history.frame.content.scroll.information.profile)
end)

ban_history.frame.content.scroll.information.moderator.MouseButton1Click:Connect(function()
	MainModule.BanHistory(false)
	MainModule.Profile(true, ban_history:GetAttribute("Moderator"), ban_history.frame.content.scroll.information.moderator)
end)

ban_history.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.BanHistory(false)
end)

--// SERVER TELEPORTATION

server_teleportation.frame.content.scroll.key.jobid.MouseButton1Click:Connect(function()
	server_teleportation:SetAttribute("UsingJobID", true)

	server_teleportation.frame.content.scroll.destination.textbox.Text = ""
	server_teleportation.frame.content.scroll.destination.textbox.ClearTextOnFocus = true

	--

	tween_service:Create(server_teleportation.frame.content.scroll.key.jobid, info, {
		BackgroundColor3 = Color3.fromRGB(29, 29, 29)}):Play()
	tween_service:Create(server_teleportation.frame.content.scroll.key.jobid.stroke.gradient, info, {
		Rotation = -90}):Play()

	tween_service:Create(server_teleportation.frame.content.scroll.key.player, info, {
		BackgroundColor3 = Color3.fromRGB(42, 42, 42)}):Play()
	tween_service:Create(server_teleportation.frame.content.scroll.key.player.stroke.gradient, info, {
		Rotation = 90}):Play()
end)

server_teleportation.frame.content.scroll.key.player.MouseButton1Click:Connect(function()
	server_teleportation:SetAttribute("UsingJobID", false)

	server_teleportation.frame.content.scroll.destination.textbox.Text = ""
	server_teleportation.frame.content.scroll.destination.textbox.ClearTextOnFocus = false

	--

	tween_service:Create(server_teleportation.frame.content.scroll.key.player, info, {
		BackgroundColor3 = Color3.fromRGB(29, 29, 29)}):Play()
	tween_service:Create(server_teleportation.frame.content.scroll.key.player.stroke.gradient, info, {
		Rotation = -90}):Play()

	tween_service:Create(server_teleportation.frame.content.scroll.key.jobid, info, {
		BackgroundColor3 = Color3.fromRGB(42, 42, 42)}):Play()
	tween_service:Create(server_teleportation.frame.content.scroll.key.jobid.stroke.gradient, info, {
		Rotation = 90}):Play()
end)

local teleporting = false

server_teleportation.frame.content.bottom.Confirm.Button.MouseButton1Click:Connect(function()
	if not teleporting then
		teleporting = true

		if server_teleportation.frame.content.scroll.destination.textbox.Text ~= "" then
			local jobid = server_teleportation.frame.content.scroll.destination.textbox.Text

			if jobid == game.JobId then
				Alerts.BannerNotify({
					Header = "Unavailable Job ID";
					Description = "The Job ID you provided is currently not available.";
					Icon = "rbxassetid://11963348339"
				})

				teleporting = false
			else
				events.Activities.ServerTeleportation:FireServer(server_teleportation:GetAttribute("UsingJobID"), jobid)

				MainModule.ServerTeleportation(false)

				task.spawn(function()
					MainModule.TrackProgress(true, "Teleporting...")

					task.wait(10)

					MainModule.TrackProgress(false)
				end)
			end
		else
			Alerts.BannerNotify({
				Header = "No Destination Provided";
				Description = "You didn't provide any destination.";
				Icon = "rbxassetid://14187783356"
			})

			teleporting = false
		end
	end
end)

events.Activities.ServerTeleportation.OnClientEvent:Connect(function(success, error)
	teleporting = false

	MainModule.TrackProgress(false)

	if success then
		Alerts.BannerNotify({
			Header = "Teleport Attempt Success";
			Description = "You will be teleported any moment now.";
			Icon = "rbxassetid://11430233649"
		})
	else
		Alerts.BannerNotify({
			Header = "Teleport Attempt Failed";
			Description = error;
			Icon = "rbxassetid://11963348339"
		})
	end
end)

server_teleportation.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.ServerTeleportation(false)
end)

--// PROGRESS TRACKER

local loop = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false)

tween_service:Create(progress_tracker.frame.content.loader.icon, loop, {Rotation = 360}):Play()

--// CHARACTER VIEWER

local InCharacterViewerModal = false
local MouseSensitivity = .5

local CharacterViewerZoom = character_viewer.frame.content.canvas.viewport.CameraZoom

local CharacterViewerCamera = Instance.new("Camera")
CharacterViewerCamera.FieldOfView = 50
CharacterViewerCamera.Parent = character_viewer.frame.content.canvas.viewport

character_viewer.frame.content.canvas.viewport.CurrentCamera = CharacterViewerCamera

function InputStart()
	input_service.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
end

function InputEnd()
	local model = character_viewer.frame.content.canvas.viewport:FindFirstChildWhichIsA("Model")

	input_service.MouseBehavior = Enum.MouseBehavior.Default
end

function Zoom(plus)
	if plus then
		tween_service:Create(CharacterViewerZoom, info, {Value = math.clamp(CharacterViewerZoom.Value - .5, 2, 8)}):Play()
	else
		tween_service:Create(CharacterViewerZoom, info, {Value = math.clamp(CharacterViewerZoom.Value + .5, 2, 8)}):Play()
	end
end

function UpdateCharacterViewer(delta)
	if not character_viewer.Visible then return end

	local Canvas = character_viewer.frame.content.canvas

	-- Camera Update

	local focus = Canvas.viewport.Point.CFrame.Position
	local goal = CFrame.new(focus - (camera.CFrame.LookVector * CharacterViewerZoom.Value), focus)

	CharacterViewerCamera.CFrame = CharacterViewerCamera.CFrame:Lerp(goal, math.min(1, delta * 20))
end

character_viewer.frame.content.canvas.MouseEnter:Connect(function()
	InCharacterViewerModal = true
end)

character_viewer.frame.content.canvas.MouseLeave:Connect(function()
	InCharacterViewerModal = false
end)

input_service.InputBegan:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and modals.character_viewer.Visible
		and InCharacterViewerModal then

		InputStart()
	end
end)

input_service.InputEnded:Connect(function(input)
	if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and modals.character_viewer.Visible then
		InputEnd()
	end
end)

character_viewer.frame.content.canvas.viewport.MouseWheelForward:Connect(function()
	Zoom(true)
end)

character_viewer.frame.content.canvas.viewport.MouseWheelBackward:Connect(function()
	Zoom(false)
end)

character_viewer.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.CharacterViewer(false)
end)

character_viewer.frame.LeafletControls.Top.Pin.Button.MouseButton1Click:Connect(function()
	MainModule.TrackProgress(true)

	local Action = "ViewAvatar"
	local pins = events.auth.FetchPins:InvokeServer(client.UserId)
	if not pins then MainModule.TrackProgress(false) return end

	if table.find(pins, Action) then
		events.auth.ActionPinning:InvokeServer("Unpin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.ViewAvatar.Visible = false

		Alerts.BannerNotify({
			Header = `Unpinned the {Action} action.`,
			Icon = "rbxassetid://12974257382"
		})
	else
		events.auth.ActionPinning:InvokeServer("Pin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.ViewAvatar.Visible = true

		Alerts.BannerNotify({
			Header = `Pinned the {Action} action.`,
			Icon = "rbxassetid://12974469173"
		})
	end

	MainModule.TrackProgress(false)
end)

--// ROLE INFO

role_info.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.RoleInfo(false)
end)

role_info.frame.LeafletControls.Top.Pin.Button.MouseButton1Click:Connect(function()
	MainModule.TrackProgress(true)

	local Action = "Roles"
	local pins = events.auth.FetchPins:InvokeServer(client.UserId)
	if not pins then MainModule.TrackProgress(false) return end

	if table.find(pins, Action) then
		events.auth.ActionPinning:InvokeServer("Unpin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Roles.Visible = false

		Alerts.BannerNotify({
			Header = `Unpinned the {Action} action.`,
			Icon = "rbxassetid://12974257382"
		})
	else
		events.auth.ActionPinning:InvokeServer("Pin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Roles.Visible = true

		Alerts.BannerNotify({
			Header = `Pinned the {Action} action.`,
			Icon = "rbxassetid://12974469173"
		})
	end

	MainModule.TrackProgress(false)
end)

--// ANNOUNCEMENT

events.ui.ModalToggled.Event:Connect(function(modal, state)
	if state and modal == announcement then

		Utilities.SwitchToggle(announcement.frame.content.scroll.settings.global.switch, false)
		announcement:SetAttribute("Global", false)

	end
end)

announcement.frame.content.scroll.settings.global.MouseButton1Click:Connect(function()
	Utilities.SwitchToggle(announcement.frame.content.scroll.settings.global.switch, not announcement:GetAttribute("Global"))
	announcement:SetAttribute("Global", not announcement:GetAttribute("Global"))
end)

local AudienceRolesLoaded = false
local AudienceTable = {"Everyone", "Team", "Nonmembers"}

announcement.frame.content.scroll.settings.audience.dropdown.MouseButton1Click:Connect(function()
	if not AudienceRolesLoaded then
		local roles = events.auth.Auth:InvokeServer("GetRoles")

		if roles then
			for i, role in pairs(roles) do
				table.insert(AudienceTable, i)
			end

			AudienceRolesLoaded = true
		else
			Alerts.BannerNotify({
				Header = "Failed to Open Audiences Dropdown.",
				Description = "There was an error upon fetching the roles. Please try again.",
				Icon = "rbxassetid://11422916589"
			})
		end
	end

	local data = MainModule.ParameterEnum(true, AudienceTable, NumberRange.new(1, 1), "Audience",
		announcement.frame.content.scroll.settings.audience.dropdown)

	if data then
		announcement.frame.content.scroll.settings.audience.dropdown.Text = tostring(data[1])
		announcement:SetAttribute("Audience", tostring(data[1]))
	end
end)

announcement.frame.content.scroll.duration.ten.MouseButton1Click:Connect(function()
	announcement:SetAttribute("Duration", 10)
	announcement.frame.content.scroll.duration.field.textbox.Text = ""
end)

announcement.frame.content.scroll.duration.fifteen.MouseButton1Click:Connect(function()
	announcement:SetAttribute("Duration", 15)
	announcement.frame.content.scroll.duration.field.textbox.Text = ""
end)

announcement.frame.content.scroll.duration.twenty.MouseButton1Click:Connect(function()
	announcement:SetAttribute("Duration", 20)
	announcement.frame.content.scroll.duration.field.textbox.Text = ""
end)

announcement.frame.content.scroll.duration.field.textbox.FocusLost:Connect(function()
	local duration = tonumber(announcement.frame.content.scroll.duration.field.textbox.Text)

	if duration then
		announcement:SetAttribute("Duration", duration)

		if duration == 10 or duration == 15 or duration == 20 then
			announcement.frame.content.scroll.duration.field.textbox.Text = ""
		else
			announcement.frame.content.scroll.duration.field.textbox.Text = duration
		end
	else
		announcement:SetAttribute("Duration", 10)
		announcement.frame.content.scroll.duration.field.textbox.Text = ""
	end
end)

announcement:GetAttributeChangedSignal("Duration"):Connect(function()
	if announcement:GetAttribute("Duration") == 10 then
		tween_service:Create(announcement.frame.content.scroll.duration.ten.icon.scale, info, {Scale = 1}):Play()
		tween_service:Create(announcement.frame.content.scroll.duration.fifteen.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(announcement.frame.content.scroll.duration.twenty.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(announcement.frame.content.scroll.duration.field.icon.scale, info, {Scale = 0}):Play()

	elseif announcement:GetAttribute("Duration") == 15 then
		tween_service:Create(announcement.frame.content.scroll.duration.fifteen.icon.scale, info, {Scale = 1}):Play()
		tween_service:Create(announcement.frame.content.scroll.duration.ten.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(announcement.frame.content.scroll.duration.twenty.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(announcement.frame.content.scroll.duration.field.icon.scale, info, {Scale = 0}):Play()

	elseif announcement:GetAttribute("Duration") == 20 then
		tween_service:Create(announcement.frame.content.scroll.duration.twenty.icon.scale, info, {Scale = 1}):Play()
		tween_service:Create(announcement.frame.content.scroll.duration.fifteen.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(announcement.frame.content.scroll.duration.ten.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(announcement.frame.content.scroll.duration.field.icon.scale, info, {Scale = 0}):Play()

	else
		tween_service:Create(announcement.frame.content.scroll.duration.field.icon.scale, info, {Scale = 1}):Play()
		tween_service:Create(announcement.frame.content.scroll.duration.fifteen.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(announcement.frame.content.scroll.duration.twenty.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(announcement.frame.content.scroll.duration.ten.icon.scale, info, {Scale = 0}):Play()
	end
end)

announcement.frame.content.scroll.announcement.textbox:GetPropertyChangedSignal("Text"):Connect(function()
	local count = announcement.frame.content.scroll.announcement.textbox.Text:len()

	announcement.frame.content.scroll.announcement.limit.Text = count .. "/400"

	if count > 400 then
		tween_service:Create(announcement.frame.content.scroll.announcement.header.header.badge, info, {
			ImageTransparency = 0, Size = UDim2.fromOffset(10, 10)}):Play()
	else
		tween_service:Create(announcement.frame.content.scroll.announcement.header.header.badge, info, {
			ImageTransparency = 1, Size = UDim2.fromOffset(-10, 10)}):Play()
	end
end)

announcement.frame.content.scroll.announcement.textbox.FocusLost:Connect(function()
	local trimmed = Utilities.TrimString(announcement.frame.content.scroll.announcement.textbox.Text, 400)
	local final

	if Configuration.Announcements.FilterAnnouncements then
		final = Utilities.FilterString(trimmed, players.LocalPlayer.UserId, true)
	else
		final = trimmed
	end

	announcement.frame.content.scroll.announcement.textbox.Text = final
	announcement:SetAttribute("Announcement", final)
end)

announcement.frame.content.scroll.header.textbox:GetPropertyChangedSignal("Text"):Connect(function()
	local count = announcement.frame.content.scroll.header.textbox.Text:len()

	announcement.frame.content.scroll.header.limit.Text = count .. "/50"

	if count > 50 then
		tween_service:Create(announcement.frame.content.scroll.header.header.badge, info, {
			ImageTransparency = 0, Size = UDim2.fromOffset(10, 10)}):Play()
	else
		tween_service:Create(announcement.frame.content.scroll.header.header.badge, info, {
			ImageTransparency = 1, Size = UDim2.fromOffset(-10, 10)}):Play()
	end
end)

announcement.frame.content.scroll.header.textbox.FocusLost:Connect(function()
	local trimmed = Utilities.TrimString(announcement.frame.content.scroll.header.textbox.Text, 50)
	local final

	if Configuration.Announcements.FilterAnnouncements then
		final = Utilities.FilterString(trimmed, players.LocalPlayer.UserId, true)
	else
		final = trimmed
	end

	announcement.frame.content.scroll.header.textbox.Text = final
	announcement:SetAttribute("Header", final)
end)

function ANNOUNCEMENT_ICON_MANAGEMENT()
	for i, icon in pairs(announcement.frame.content.scroll.icons.container:GetChildren()) do
		if icon:IsA("ImageButton") then

			icon.MouseEnter:Connect(function()
				tween_service:Create(icon, info, {ImageTransparency = .9}):Play()
				tween_service:Create(icon.icon.scale, info, {Scale = 1.2}):Play()
			end)

			icon.MouseButton1Down:Connect(function()
				tween_service:Create(icon, info, {ImageTransparency = .95}):Play()
				tween_service:Create(icon.icon.scale, info, {Scale = .6}):Play()
			end)

			icon.InputEnded:Connect(function()
				if icon.icon.Image == announcement:GetAttribute("Icon") then
					tween_service:Create(icon, info, {ImageTransparency = .8}):Play()
				else
					tween_service:Create(icon, info, {ImageTransparency = 1}):Play()
				end

				tween_service:Create(icon.icon.scale, info, {Scale = 1}):Play()
			end)

			icon.MouseButton1Click:Connect(function()
				announcement:SetAttribute("Icon", icon.icon.Image)
			end)

		end
	end

	announcement:GetAttributeChangedSignal("Icon"):Connect(function()
		for i, icon in pairs(announcement.frame.content.scroll.icons.container:GetChildren()) do
			if icon:IsA("ImageButton") then

				if icon.icon.Image == announcement:GetAttribute("Icon") then
					tween_service:Create(icon, info, {ImageTransparency = .8}):Play()
				else
					tween_service:Create(icon, info, {ImageTransparency = 1}):Play()
				end

			end
		end
	end)
end

announcement.frame.content.bottom.Post.Button.MouseButton1Click:Connect(function()
	if announcement:GetAttribute("Announcement") ~= "" and announcement:GetAttribute("Header") ~= "" then
		MainModule.Announcement(false)

		events.Activities.Announcement:FireServer(announcement:GetAttributes())
	else
		Alerts.BannerNotify({
			Header = "Missing Information";
			Description = "You left the Announcement or Header field empty.";
			Icon = "rbxassetid://14187783356"
		})
	end
end)

ANNOUNCEMENT_ICON_MANAGEMENT()

announcement.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.Announcement(false)
end)

announcement.frame.LeafletControls.Top.Pin.Button.MouseButton1Click:Connect(function()
	MainModule.TrackProgress(true)

	local Action = "Announce"
	local pins = events.auth.FetchPins:InvokeServer(client.UserId)
	if not pins then MainModule.TrackProgress(false) return end

	if table.find(pins, Action) then
		events.auth.ActionPinning:InvokeServer("Unpin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Announce.Visible = false

		Alerts.BannerNotify({
			Header = `Unpinned the {Action} action.`,
			Icon = "rbxassetid://12974257382"
		})
	else
		events.auth.ActionPinning:InvokeServer("Pin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Announce.Visible = true

		Alerts.BannerNotify({
			Header = `Pinned the {Action} action.`,
			Icon = "rbxassetid://12974469173"
		})
	end

	MainModule.TrackProgress(false)
end)

--// NOTIFY

notify.frame.content.scroll.duration.ten.MouseButton1Click:Connect(function()
	notify:SetAttribute("Duration", 10)
	notify.frame.content.scroll.duration.field.textbox.Text = ""
end)

notify.frame.content.scroll.duration.fifteen.MouseButton1Click:Connect(function()
	notify:SetAttribute("Duration", 15)
	notify.frame.content.scroll.duration.field.textbox.Text = ""
end)

notify.frame.content.scroll.duration.twenty.MouseButton1Click:Connect(function()
	notify:SetAttribute("Duration", 20)
	notify.frame.content.scroll.duration.field.textbox.Text = ""
end)

notify.frame.content.scroll.duration.field.textbox.FocusLost:Connect(function()
	local duration = tonumber(notify.frame.content.scroll.duration.field.textbox.Text)

	if duration then
		notify:SetAttribute("Duration", duration)

		if duration == 10 or duration == 15 or duration == 20 then
			notify.frame.content.scroll.duration.field.textbox.Text = ""
		else
			notify.frame.content.scroll.duration.field.textbox.Text = duration
		end
	else
		notify:SetAttribute("Duration", 10)
		notify.frame.content.scroll.duration.field.textbox.Text = ""
	end
end)

notify:GetAttributeChangedSignal("Duration"):Connect(function()
	if notify:GetAttribute("Duration") == 10 then
		tween_service:Create(notify.frame.content.scroll.duration.ten.icon.scale, info, {Scale = 1}):Play()
		tween_service:Create(notify.frame.content.scroll.duration.fifteen.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(notify.frame.content.scroll.duration.twenty.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(notify.frame.content.scroll.duration.field.icon.scale, info, {Scale = 0}):Play()
	elseif notify:GetAttribute("Duration") == 15 then
		tween_service:Create(notify.frame.content.scroll.duration.fifteen.icon.scale, info, {Scale = 1}):Play()
		tween_service:Create(notify.frame.content.scroll.duration.ten.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(notify.frame.content.scroll.duration.twenty.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(notify.frame.content.scroll.duration.field.icon.scale, info, {Scale = 0}):Play()
	elseif notify:GetAttribute("Duration") == 20 then
		tween_service:Create(notify.frame.content.scroll.duration.twenty.icon.scale, info, {Scale = 1}):Play()
		tween_service:Create(notify.frame.content.scroll.duration.fifteen.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(notify.frame.content.scroll.duration.ten.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(notify.frame.content.scroll.duration.field.icon.scale, info, {Scale = 0}):Play()
	else
		tween_service:Create(notify.frame.content.scroll.duration.field.icon.scale, info, {Scale = 1}):Play()
		tween_service:Create(notify.frame.content.scroll.duration.fifteen.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(notify.frame.content.scroll.duration.twenty.icon.scale, info, {Scale = 0}):Play()
		tween_service:Create(notify.frame.content.scroll.duration.ten.icon.scale, info, {Scale = 0}):Play()
	end
end)

notify.frame.content.scroll.notification.textbox:GetPropertyChangedSignal("Text"):Connect(function()
	local count = notify.frame.content.scroll.notification.textbox.Text:len()

	notify.frame.content.scroll.notification.limit.Text = count .. "/100"

	if count > 100 then
		tween_service:Create(notify.frame.content.scroll.notification.header.header.badge, info, {
			ImageTransparency = 0, Size = UDim2.fromOffset(10, 10)}):Play()
	else
		tween_service:Create(notify.frame.content.scroll.notification.header.header.badge, info, {
			ImageTransparency = 1, Size = UDim2.fromOffset(-10, 10)}):Play()
	end
end)

notify.frame.content.scroll.notification.textbox.FocusLost:Connect(function()
	local trimmed = Utilities.TrimString(notify.frame.content.scroll.notification.textbox.Text, 100)
	local final

	if Configuration.Announcements.FilterAnnouncements then
		final = Utilities.FilterString(trimmed, players.LocalPlayer.UserId, true)
	else
		final = trimmed
	end

	notify.frame.content.scroll.notification.textbox.Text = final
	notify:SetAttribute("Notification", final)
end)

notify.frame.content.scroll.header.textbox:GetPropertyChangedSignal("Text"):Connect(function()
	local count = notify.frame.content.scroll.header.textbox.Text:len()

	notify.frame.content.scroll.header.limit.Text = count .. "/50"

	if count > 50 then
		tween_service:Create(notify.frame.content.scroll.header.header.badge, info, {
			ImageTransparency = 0, Size = UDim2.fromOffset(10, 10)}):Play()
	else
		tween_service:Create(notify.frame.content.scroll.header.header.badge, info, {
			ImageTransparency = 1, Size = UDim2.fromOffset(-10, 10)}):Play()
	end
end)

notify.frame.content.scroll.header.textbox.FocusLost:Connect(function()
	local trimmed = Utilities.TrimString(notify.frame.content.scroll.header.textbox.Text, 50)
	local final

	if Configuration.Announcements.FilterAnnouncements then
		final = Utilities.FilterString(trimmed, players.LocalPlayer.UserId, true)
	else
		final = trimmed
	end

	notify.frame.content.scroll.header.textbox.Text = final
	notify:SetAttribute("Header", final)
end)

function NOTIFY_ICON_MANAGEMENT()
	for i, icon in pairs(notify.frame.content.scroll.icons.container:GetChildren()) do
		if icon:IsA("ImageButton") then

			icon.MouseEnter:Connect(function()
				tween_service:Create(icon, info, {ImageTransparency = .9}):Play()
				tween_service:Create(icon.icon.scale, info, {Scale = 1.2}):Play()
			end)

			icon.MouseButton1Down:Connect(function()
				tween_service:Create(icon, info, {ImageTransparency = .95}):Play()
				tween_service:Create(icon.icon.scale, info, {Scale = .6}):Play()
			end)

			icon.InputEnded:Connect(function()
				if icon.icon.Image == notify:GetAttribute("Icon") then
					tween_service:Create(icon, info, {ImageTransparency = .8}):Play()
				else
					tween_service:Create(icon, info, {ImageTransparency = 1}):Play()
				end

				tween_service:Create(icon.icon.scale, info, {Scale = 1}):Play()
			end)

			icon.MouseButton1Click:Connect(function()
				notify:SetAttribute("Icon", icon.icon.Image)
			end)

		end
	end

	notify:GetAttributeChangedSignal("Icon"):Connect(function()
		for i, icon in pairs(notify.frame.content.scroll.icons.container:GetChildren()) do
			if icon:IsA("ImageButton") then

				if icon.icon.Image == notify:GetAttribute("Icon") then
					tween_service:Create(icon, info, {ImageTransparency = .8}):Play()
				else
					tween_service:Create(icon, info, {ImageTransparency = 1}):Play()
				end

			end
		end
	end)
end

notify.frame.content.bottom.Notify.Button.MouseButton1Click:Connect(function()
	if notify:GetAttribute("Notification") ~= "" and notify:GetAttribute("Header") ~= "" then
		MainModule.Notify(false)

		events.Activities.Notify:FireServer(notify:GetAttributes())
	else
		Alerts.BannerNotify({
			Header = "Missing Information";
			Description = "You left the Notification or Header field empty.";
			Icon = "rbxassetid://14187783356"
		})
	end
end)

NOTIFY_ICON_MANAGEMENT()

notify.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.Notify(false)
end)

notify.frame.LeafletControls.Top.Pin.Button.MouseButton1Click:Connect(function()
	MainModule.TrackProgress(true)

	local Action = "Notify"
	local pins = events.auth.FetchPins:InvokeServer(client.UserId)
	if not pins then MainModule.TrackProgress(false) return end

	if table.find(pins, Action) then
		events.auth.ActionPinning:InvokeServer("Unpin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Notify.Visible = false

		Alerts.BannerNotify({
			Header = `Unpinned the {Action} action.`,
			Icon = "rbxassetid://12974257382"
		})
	else
		events.auth.ActionPinning:InvokeServer("Pin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Notify.Visible = true

		Alerts.BannerNotify({
			Header = `Pinned the {Action} action.`,
			Icon = "rbxassetid://12974469173"
		})
	end

	MainModule.TrackProgress(false)
end)

--// Confirmation Prompt

confirmation_prompt.frame.content.actions.accept.MouseButton1Click:Connect(function()
	local Action = confirmation_prompt:GetAttribute("CurrentPromptID")

	MainModule.ConfirmationPrompt(false, {})
	events.ui.ConfirmationPromptClosed:Fire(Action, true)

	Utilities.Haptic(.5)
end)

confirmation_prompt.frame.content.actions.cancel.MouseButton1Click:Connect(function()
	local Action = confirmation_prompt:GetAttribute("CurrentPromptID")

	MainModule.ConfirmationPrompt(false, {})
	events.ui.ConfirmationPromptClosed:Fire(Action, false)
end)

--// WARN

local warn_properties = warn.frame.content.properties

warn_properties.bottom.Warn.Button.MouseButton1Click:Connect(function()
	if warn:GetAttribute("Warning") ~= "" then
		local deserialized = Utilities.DeserializeNumberTable(warn:GetAttribute("SerializedIds"))

		MainModule.ConfirmationPrompt(true, {
			ID = "Warn",
			Header = "Warn ".. #deserialized .." player(s)?",
			Description = "This action will prompt them a warning.",
			Accept = "Warn"
		}, warn_properties.bottom.Warn)
	end
end)

warn_properties.scroll.RemoveLastUnreadWarning.MouseButton1Click:Connect(function()
	local deserialized = Utilities.DeserializeNumberTable(warn:GetAttribute("SerializedIds"))

	MainModule.ConfirmationPrompt(true, {
		ID = "RemoveUnreadWarn",
		Header = "Removed Unread Warnings from ".. #deserialized .." player(s)?",
		Description = "This action will remove their last unread warning.",
		Accept = "Remove"
	}, warn_properties.scroll.RemoveLastUnreadWarning)
end)

events.ui.ConfirmationPromptClosed.Event:Connect(function(id, result)
	if id == "Warn" and result then
		MainModule.TrackProgress(true, "Issuing Warn...")

		local result = events.Activities.Primary:InvokeServer("Warn", warn:GetAttributes())

		if result then
			MainModule.Warn(false)
			Alerts.BannerNotify({
				Header = "Warn Issued Successfully";
				Description = #result.Success .. "/" .. #result.All .. " has been successfully warned." ;
				Icon = "rbxassetid://11419712454";
				Involved = Utilities.ExtractTableContents(result.Success, 1, 5)
			})
		else
			Alerts.BannerNotify({
				Header = "Issuing Warn Failed";
				Description = "An error occurred while issuing a warn.";
				Icon = "rbxassetid://11422144471";
			})
		end

		MainModule.TrackProgress(false)
		
	elseif id == "RemoveUnreadWarn" and result then
		MainModule.TrackProgress(true, "Removing Unread Warn...")

		local result = events.Activities.Primary:InvokeServer("RemoveUnreadWarn", warn:GetAttributes())

		if result then
			MainModule.Warn(false)
			
			Alerts.BannerNotify({
				Header = "Removed Unread Warnings Successfully";
				Description = #result.Success .. "/" .. #result.All .. " has been successfully warned." ;
				Icon = "rbxassetid://11419712454";
				Involved = Utilities.ExtractTableContents(result.Success, 1, 5)
			})
		else
			Alerts.BannerNotify({
				Header = "Removing Unread Warnings Failed";
				Description = "An error occurred while issuing a warn.";
				Icon = "rbxassetid://11422144471";
			})
		end

		MainModule.TrackProgress(false)

	elseif id == "Warn" and not result then
		Alerts.BannerNotify({
			Header = "Issuing Warn Failed";
			Description = "An error occurred while attempting to warn.";
			Icon = "rbxassetid://11422144471";
		})
	end
end)

warn_properties.scroll.warning.textbox:GetPropertyChangedSignal("Text"):Connect(function()
	local count = warn_properties.scroll.warning.textbox.Text:len()

	warn_properties.scroll.warning.limit.Text = count .. "/400"

	if count > 400 then
		tween_service:Create(warn_properties.scroll.warning.header.header.badge, info, {
			ImageTransparency = 0, Size = UDim2.fromOffset(10, 10)}):Play()
	else
		tween_service:Create(warn_properties.scroll.warning.header.header.badge, info, {
			ImageTransparency = 1, Size = UDim2.fromOffset(-10, 10)}):Play()
	end
end)

warn_properties.scroll.warning.textbox.FocusLost:Connect(function()
	local final = Utilities.TrimString(warn_properties.scroll.warning.textbox.Text, 400)

	warn_properties.scroll.warning.textbox.Text = final
	warn:SetAttribute("Warning", final)
end)

warn_properties.scroll.warning.header.predefined_reasons.MouseButton1Click:Connect(function()
	local reason = MainModule.ParameterEnum(true, Configuration.PredefinedReasons, NumberRange.new(1, 1), "Warn Reason")

	if reason then
		warn_properties.scroll.warning.textbox.Text = reason[1]

		Utilities.AnimateFillTextbox(warn_properties.scroll.warning.textbox)

		local final = Utilities.TrimString(warn_properties.scroll.warning.textbox.Text, 400)

		warn_properties.scroll.warning.textbox.Text = final
		warn:SetAttribute("Warning", final)
	end
end)

warn.frame.content.players.bottom.Back.Button.MouseButton1Click:Connect(function()
	warn.frame.content.page:JumpTo(warn.frame.content.properties)
end)

warn.frame.content.properties.bottom.Manage.Button.MouseButton1Click:Connect(function()
	warn.frame.content.page:JumpTo(warn.frame.content.players)
end)

warn.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.Warn(false)
end)

warn.frame.LeafletControls.Top.Pin.Button.MouseButton1Click:Connect(function()
	MainModule.TrackProgress(true)

	local Action = "Warn"
	local pins = events.auth.FetchPins:InvokeServer(client.UserId)
	if not pins then MainModule.TrackProgress(false) return end

	if table.find(pins, Action) then
		events.auth.ActionPinning:InvokeServer("Unpin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Warn.Visible = false

		Alerts.BannerNotify({
			Header = `Unpinned the {Action} action.`,
			Icon = "rbxassetid://12974257382"
		})
	else
		events.auth.ActionPinning:InvokeServer("Pin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Warn.Visible = true

		Alerts.BannerNotify({
			Header = `Pinned the {Action} action.`,
			Icon = "rbxassetid://12974469173"
		})
	end

	MainModule.TrackProgress(false)
end)

--// CHAT HISTORY

chat_history.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.ChatHistory(false)
end)

--// NOTIFICATION DRAWER

notification_history.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.NotificationHistory(false)
end)

--// WARN HISTORY

warn_history.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.WarnHistory(false)
end)

--// PRIVACY

function CreateDecal(Id, Name)
	local Decal = Instance.new("Decal")

	Decal.Name = Name
	Decal.Texture = Id

	return Decal
end

local PrivacyTypes = {
	CreateDecal("rbxassetid://11293979388", "Public"),
	CreateDecal("rbxassetid://12967426248", "Team"),
	CreateDecal("rbxassetid://14187755345", "Private"),
}

function AnimatePrivacySlider(PrivacyType)
	if PrivacyType == "Public" then
		privacy.frame.content.scroll.access.options.page:JumpTo(privacy.frame.content.scroll.access.options.Public)
	elseif PrivacyType == "Team" then
		privacy.frame.content.scroll.access.options.page:JumpTo(privacy.frame.content.scroll.access.options.Team)
	elseif PrivacyType == "Private" then
		privacy.frame.content.scroll.access.options.page:JumpTo(privacy.frame.content.scroll.access.options.Private)
	end
end

privacy.frame.content.scroll.access.options.MouseButton1Click:Connect(function()
	Utilities.Haptic(.3)

	local Result = MainModule.ParameterEnum(true, PrivacyTypes, NumberRange.new(1), "Select Accessibility...",
		privacy.frame.content.scroll.access.options)

	if Result then
		local Success = events.Activities.PrivacyAction:InvokeServer("PrivacyChange", Result[1].Name)

		if Success then
			AnimatePrivacySlider(Result[1].Name)
		end
	end
end)

privacy.frame.content.scroll.server_shutdown.shutdown.MouseButton1Click:Connect(function()
	MainModule.ConfirmationPrompt(true, {
		ID = "ServerShutdown",
		Header = "Confirm Shut Down",
		Description = "This action will kick all of the players.",
		Accept = "Shutdown Server"
	}, privacy.frame.content.scroll.server_shutdown.shutdown)
end)

events.ui.ConfirmationPromptClosed.Event:Connect(function(id, result)
	if id == "ServerShutdown" and result then
		MainModule.TrackProgress(true, "Shutdown in progress...")

		events.ui.ForceCloseModals:Fire()

		task.wait(1)

		MainModule.TrackProgress(false)
		local success = events.Activities.PrivacyAction:InvokeServer("ServerShutdown")
	end
end)

events.ui.ChangePrivacy.OnClientEvent:Connect(function(value)
	AnimatePrivacySlider(value)
end)

events.ui.ExeInterfaceLoaded.OnClientEvent:Connect(function(value)
	AnimatePrivacySlider(value)
end)

privacy.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.Privacy(false)
end)

--// PARAMETER ENUM

function SearchKeywordForParamEnum()
	local term = string.lower(param_enum.frame.content.bottom.Search.Field.textbox.Text)

	for i, v in pairs(param_enum.frame.content.scroll:GetChildren()) do
		if v:IsA("ImageButton") and v:HasTag("Exe6EnumItem") then
			if term ~= "" then
				local keywords = {
					v.Name,
					v:GetAttribute("class"),
					v.value.Text,
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

param_enum.frame.content.bottom.Search.Field.textbox:GetPropertyChangedSignal("Text"):Connect(SearchKeywordForParamEnum)

param_enum.frame.content.bottom.Search.Field.textbox.Focused:Connect(function()
	tween_service:Create(param_enum.frame.content.bottom.padding, info, {PaddingLeft = UDim.new(0, 15), 
		PaddingRight = UDim.new(0, 15)}):Play()

	tween_service:Create(param_enum.frame.content.bottom.Selections, info, {Size = UDim2.fromOffset(0, 70),
		ImageTransparency = 1}):Play()
	tween_service:Create(param_enum.frame.content.bottom.Select, info, {Size = UDim2.fromOffset(0, 70),
		ImageTransparency = 1}):Play()

	tween_service:Create(param_enum.frame.content.bottom.Selections.Button.scale, info, {Scale = 0}):Play()
	tween_service:Create(param_enum.frame.content.bottom.Select.Button.scale, info, {Scale = 0}):Play()
end)

param_enum.frame.content.bottom.Search.Field.textbox.FocusLost:Connect(function()
	if not param_enum:GetAttribute("SingleSelect") then
		tween_service:Create(param_enum.frame.content.bottom.padding, info, {PaddingLeft = UDim.new(0, 0), 
			PaddingRight = UDim.new(0, 0)}):Play()

		tween_service:Create(param_enum.frame.content.bottom.Selections, info, {Size = UDim2.fromOffset(94, 70),
			ImageTransparency = .5}):Play()
		tween_service:Create(param_enum.frame.content.bottom.Select, info, {Size = UDim2.fromOffset(128, 70),
			ImageTransparency = .5}):Play()

		tween_service:Create(param_enum.frame.content.bottom.Selections.Button.scale, info, {Scale = 1}):Play()
		tween_service:Create(param_enum.frame.content.bottom.Select.Button.scale, info, {Scale = 1}):Play()
	end
end)

param_enum.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.ParameterEnum(false)
end)

--// PARAMETER PLAYER

function SearchKeywordForParamPlayer()
	local term = string.lower(param_player.frame.content.bottom.Search.Field.textbox.Text)

	for i, v in pairs(param_player.frame.content.scroll:GetChildren()) do
		if v:IsA("ImageButton") and v:HasTag("Exe6EnumItem") then
			if term ~= "" then
				local keywords = {
					v.Name,
					v.display.Text,
					v.role.Text,
					v:GetAttribute("id"),
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

local paramplr_filter = param_player.frame.content.scroll.filter
local CurrentCategory = "All"

type ParameterPlayerFilterParameter = {
	Category: "All" | "Team" | "Others" | any;
}

function SetFiltersForParameterPlayer(params: ParameterPlayerFilterParameter)	
	if params.Category then
		CurrentCategory = params.Category
	end

	if params.Category == "All" then
		for index, person in pairs(param_player.frame.content.scroll:GetChildren()) do
			if person:IsA("ImageButton") then
				person.Visible = true
			end
		end

		tween_service:Create(paramplr_filter.categories.All, info, {BackgroundTransparency = 0}):Play()
		tween_service:Create(paramplr_filter.categories.Team, info, {BackgroundTransparency = 1}):Play()
		tween_service:Create(paramplr_filter.categories.Others, info, {BackgroundTransparency = 1}):Play()

		tween_service:Create(paramplr_filter.categories.All.icon, info, {ImageTransparency = 0}):Play()
		tween_service:Create(paramplr_filter.categories.Team.icon, info, {ImageTransparency = .5}):Play()
		tween_service:Create(paramplr_filter.categories.Others.icon, info, {ImageTransparency = .5}):Play()

	elseif params.Category == "Team" then
		for index, person in pairs(param_player.frame.content.scroll:GetChildren()) do
			if person:IsA("ImageButton") then
				person.Visible = person.role.Visible
			end
		end

		tween_service:Create(paramplr_filter.categories.Team, info, {BackgroundTransparency = 0}):Play()
		tween_service:Create(paramplr_filter.categories.All, info, {BackgroundTransparency = 1}):Play()
		tween_service:Create(paramplr_filter.categories.Others, info, {BackgroundTransparency = 1}):Play()

		tween_service:Create(paramplr_filter.categories.Team.icon, info, {ImageTransparency = 0}):Play()
		tween_service:Create(paramplr_filter.categories.All.icon, info, {ImageTransparency = .5}):Play()
		tween_service:Create(paramplr_filter.categories.Others.icon, info, {ImageTransparency = .5}):Play()

	elseif params.Category == "Others" then
		for index, person in pairs(param_player.frame.content.scroll:GetChildren()) do
			if person:IsA("ImageButton") then
				person.Visible = not person.role.Visible
			end
		end

		tween_service:Create(paramplr_filter.categories.Others, info, {BackgroundTransparency = 0}):Play()
		tween_service:Create(paramplr_filter.categories.All, info, {BackgroundTransparency = 1}):Play()
		tween_service:Create(paramplr_filter.categories.Team, info, {BackgroundTransparency = 1}):Play()

		tween_service:Create(paramplr_filter.categories.Others.icon, info, {ImageTransparency = 0}):Play()
		tween_service:Create(paramplr_filter.categories.All.icon, info, {ImageTransparency = .5}):Play()
		tween_service:Create(paramplr_filter.categories.Team.icon, info, {ImageTransparency = .5}):Play()

	end
end

param_player.frame.content.bottom.Search.Field.textbox:GetPropertyChangedSignal("Text"):Connect(SearchKeywordForParamEnum)

param_player.frame.content.bottom.Search.Field.textbox.Focused:Connect(function()
	tween_service:Create(param_player.frame.content.bottom.padding, info, {PaddingLeft = UDim.new(0, 15), 
		PaddingRight = UDim.new(0, 15)}):Play()

	tween_service:Create(param_player.frame.content.bottom.Selections, info, {Size = UDim2.fromOffset(0, 70),
		ImageTransparency = 1}):Play()
	tween_service:Create(param_player.frame.content.bottom.Select, info, {Size = UDim2.fromOffset(0, 70),
		ImageTransparency = 1}):Play()

	tween_service:Create(param_player.frame.content.bottom.Selections.Button.scale, info, {Scale = 0}):Play()
	tween_service:Create(param_player.frame.content.bottom.Select.Button.scale, info, {Scale = 0}):Play()
end)

param_player.frame.content.bottom.Search.Field.textbox.FocusLost:Connect(function()
	if not param_player:GetAttribute("SingleSelect") then
		tween_service:Create(param_player.frame.content.bottom.padding, info, {PaddingLeft = UDim.new(0, 0), 
			PaddingRight = UDim.new(0, 0)}):Play()

		tween_service:Create(param_player.frame.content.bottom.Selections, info, {Size = UDim2.fromOffset(94, 70),
			ImageTransparency = .5}):Play()
		tween_service:Create(param_player.frame.content.bottom.Select, info, {Size = UDim2.fromOffset(128, 70),
			ImageTransparency = .5}):Play()

		tween_service:Create(param_player.frame.content.bottom.Selections.Button.scale, info, {Scale = 1}):Play()
		tween_service:Create(param_player.frame.content.bottom.Select.Button.scale, info, {Scale = 1}):Play()
	end
end)

paramplr_filter.categories.All.MouseButton1Click:Connect(function()
	SetFiltersForParameterPlayer({Category = "All"})
end)

paramplr_filter.categories.Team.MouseButton1Click:Connect(function()
	SetFiltersForParameterPlayer({Category = "Team"})
end)

paramplr_filter.categories.Others.MouseButton1Click:Connect(function()
	SetFiltersForParameterPlayer({Category = "Others"})
end)

param_player.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.ParameterPlayer(false)
end)

--// CUSTOM COMMAND

custom_command.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.PromptCustomCommand(false)
end)

--// LIVE TRACK

local LiveTrackCamera = Instance.new("Camera")
LiveTrackCamera.FieldOfView = 40
LiveTrackCamera.Parent = character_viewer.frame.content.canvas.viewport

live_track.frame.content.Canvas.Direction.CurrentCamera = LiveTrackCamera

function PointArrow(Object)
	if not Object or not Object:IsA("Instance") then return end

	local Canvas = live_track.frame.content.Canvas
	local arrow = Canvas.Direction.Arrow

	local targetCFrame
	if Object:IsA("BasePart") then
		targetCFrame = Object.CFrame

	elseif Object:IsA("Model") then

		if Object.PrimaryPart then
			targetCFrame = Object:GetPrimaryPartCFrame()
		else
			targetCFrame = Object:GetModelCFrame()
		end

	else
		return
	end

	local cameraCFrame = camera.CFrame
	local cameraPos = cameraCFrame.Position
	local targetPos = targetCFrame.Position
	local direction = (targetPos - cameraPos).Unit
	local lookAt = CFrame.new(Vector3.zero, direction)
	local rotated = lookAt * CFrame.Angles(0, math.rad(90), 0)

	tween_service:Create(arrow, info, {CFrame = rotated}):Play()
end

function UpdateLiveTrack(delta)
	if not live_track.Visible then return end

	local Canvas = live_track.frame.content.Canvas

	-- Camera Update

	local focus = Canvas.Direction.Arrow.CFrame.Position
	local goal = CFrame.new(focus - (camera.CFrame.LookVector * 8), focus)

	LiveTrackCamera.CFrame = LiveTrackCamera.CFrame:Lerp(goal, math.min(1, delta * 20))

	-- Transcribed Distance

	local Object = live_track.Tracking.Value

	if Object then
		Canvas.Parent.Info.Subject.Text = Object.Name

		local Distance, Direction = Tracking.GetGuideDistance(Object)

		if Distance > 20 then
			PointArrow(Object)

			--

			Canvas.Parent.Distance.Numbers.Text = Distance .. " studs"
			Canvas.Parent.Distance.Orientation.Text = Direction

			--

			tween_service:Create(Canvas.Direction.Arrow, info, {Size = Vector3.new(3.5, .1, 2), Transparency = 0}):Play()
			tween_service:Create(Canvas.Direction.Circle, info, {ImageTransparency = 1}):Play()
			tween_service:Create(Canvas.Direction.Circle.Bound, info, {Size = UDim2.fromScale(0, 0), ImageTransparency = 1}):Play()
			tween_service:Create(Canvas.Direction.Circle.Bound.scale, info, {Scale = 0}):Play()
		else
			Canvas.Parent.Distance.Numbers.Text = "Nearby"
			Canvas.Parent.Distance.Orientation.Text = ""

			--

			tween_service:Create(Canvas.Direction.Arrow, info, {Size = Vector3.zero, Transparency = 1}):Play()
			tween_service:Create(Canvas.Direction.Circle, info, {ImageTransparency = 0}):Play()
			tween_service:Create(Canvas.Direction.Circle.Bound, info, {Size = UDim2.fromOffset(60, 60), ImageTransparency = .5}):Play()
			tween_service:Create(Canvas.Direction.Circle.Bound.scale, info, {Scale = Distance * .15}):Play()
		end

		if Distance > 100 then
			tween_service:Create(Canvas, info, {BackgroundTransparency = 1}):Play()
			tween_service:Create(Canvas.Direction.scale, info, {Scale = 1.4}):Play()
		else
			tween_service:Create(Canvas, info, {BackgroundTransparency = 0}):Play()
			tween_service:Create(Canvas.Direction.scale, info, {Scale = 1}):Play()
		end
	end
end

live_track.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.LiveTrack(false)
end)

live_track.frame.LeafletControls.Top.Pin.Button.MouseButton1Click:Connect(function()
	MainModule.TrackProgress(true)

	local Action = "LiveTrack"
	local pins = events.auth.FetchPins:InvokeServer(client.UserId)
	if not pins then MainModule.TrackProgress(false) return end

	if table.find(pins, Action) then
		events.auth.ActionPinning:InvokeServer("Unpin", client.UserId, Action)

		modals.Parent.main_frame.content.screen.home.scroll.pinned.LiveTrack.Visible = false

		Alerts.BannerNotify({
			Header = `Unpinned the {Action} action.`,
			Icon = "rbxassetid://12974257382"
		})
	else
		events.auth.ActionPinning:InvokeServer("Pin", client.UserId, Action)
		
		modals.Parent.main_frame.content.screen.home.scroll.pinned.LiveTrack.Visible = true

		Alerts.BannerNotify({
			Header = `Pinned the {Action} action.`,
			Icon = "rbxassetid://12974469173"
		})
	end

	MainModule.TrackProgress(false)
end)

live_track.Tracking:GetPropertyChangedSignal("Value"):Connect(function()
	if live_track.Tracking.Value ~= nil then
		live_track.Tracking.Value.Destroying:Connect(function()
			live_track.Tracking.Value = nil

			MainModule.LiveTrack(false)
		end)
	end
end)

run_service.Heartbeat:Connect(function(delta)
	UpdateLiveTrack(delta)
	UpdateCharacterViewer(delta)
end)

-- FLY

fly.frame.content.Power.Button.MouseButton1Click:Connect(function()
	local FlyState = events.NoClip.NoClip:InvokeServer(client)
	
	if FlyState then
		fly.frame.content.InactiveStatus.Visible = false
		fly.frame.content.ActiveStatus.Visible = true
		
		tween_service:Create(fly.frame.content.Orientation, info, {GroupTransparency = 0}):Play()
	else
		fly.frame.content.InactiveStatus.Visible = true
		fly.frame.content.ActiveStatus.Visible = false

		tween_service:Create(fly.frame.content.Orientation, info, {Rotation = 0, GroupTransparency = 1}):Play()
	end
end)

fly.frame.content.Power.Button.MouseEnter:Connect(function()
	tween_service:Create(fly.frame.content.Power.scale, info, {Scale = 1.2}):Play()
end)

fly.frame.content.Power.Button.MouseButton1Down:Connect(function()
	tween_service:Create(fly.frame.content.Power.scale, info, {Scale = .6}):Play()
end)

fly.frame.content.Power.Button.InputEnded:Connect(function()
	tween_service:Create(fly.frame.content.Power.scale, info, {Scale = 1}):Play()
end)

fly.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
	MainModule.Fly(false)
end)

fly.frame.LeafletControls.Top.Pin.Button.MouseButton1Click:Connect(function()
	MainModule.TrackProgress(true)

	local Action = "Fly"
	local pins = events.auth.FetchPins:InvokeServer(client.UserId)
	if not pins then MainModule.TrackProgress(false) return end

	if table.find(pins, Action) then
		events.auth.ActionPinning:InvokeServer("Unpin", client.UserId, Action)
		events.auth.ActionPinning:InvokeServer("Unpin", client.UserId, "Unfly")

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Fly.Visible = false
		modals.Parent.main_frame.content.screen.home.scroll.pinned.Unfly.Visible = false

		Alerts.BannerNotify({
			Header = `Unpinned the {Action} action.`,
			Icon = "rbxassetid://12974257382"
		})
	else
		events.auth.ActionPinning:InvokeServer("Pin", client.UserId, Action)
		events.auth.ActionPinning:InvokeServer("Pin", client.UserId, "Unfly")

		modals.Parent.main_frame.content.screen.home.scroll.pinned.Fly.Visible = true
		modals.Parent.main_frame.content.screen.home.scroll.pinned.Unfly.Visible = true

		Alerts.BannerNotify({
			Header = `Pinned the {Action} action.`,
			Icon = "rbxassetid://12974469173"
		})
	end

	MainModule.TrackProgress(false)
end)

--

function run()
	for i, button in pairs(profile.frame.content.scroll:GetDescendants()) do
		if button:IsA("ImageButton") and button:HasTag("Exe6ProfileActionButton") then

			button.MouseEnter:Connect(function()
				tween_service:Create(button, info, {ImageColor3 = Color3.fromRGB(48, 48, 48)}):Play()
			end)

			button.MouseButton1Down:Connect(function()
				tween_service:Create(button, info, {ImageColor3 = Color3.fromRGB(24, 24, 24)}):Play()
			end)

			button.InputEnded:Connect(function()
				tween_service:Create(button, info, {ImageColor3 = Color3.fromRGB(34, 34, 34)}):Play()
			end)

		end
	end

	for i, close in pairs(modals:GetDescendants()) do
		if close:IsA("ImageButton") and close:HasTag("Exe6ModalCloseButton") then

			close.MouseEnter:Connect(function()
				tween_service:Create(close, info, {ImageColor3 = Color3.fromRGB(48, 48, 48)}):Play()
			end)

			close.MouseButton1Down:Connect(function()
				tween_service:Create(close, info, {ImageColor3 = Color3.fromRGB(20, 20, 20)}):Play()
			end)

			close.InputEnded:Connect(function()
				tween_service:Create(close, info, {ImageColor3 = Color3.fromRGB(34, 34, 34)}):Play()
			end)

		end
	end
end

run()

tween_service:Create(fly.frame.content.ActiveStatus.badge.glow, loop, {ImageTransparency = 1}):Play()
tween_service:Create(fly.frame.content.ActiveStatus.badge.glow.scale, loop, {Scale = 2}):Play()

--

events.ui.ForceCloseModals.Event:Connect(function()
	local ActiveLeaf = Leaflet:GetActiveLeaf()
	local copy = {}

	for i, leaf in pairs(ActiveLeaf) do
		table.insert(copy, leaf)
	end

	for _, Leaf in pairs(copy) do
		task.spawn(function()
			local Data = Leaflet:GetLeafData(Leaf)

			if not Data.DisableForcedClose then
				local key = Leaf:GetAttribute("Key")
				local fn = MainModule[key]
				if typeof(fn) == "function" then
					local success, err = pcall(fn, false)
					if not success then
						warn("Error closing modal for", key, ":", err)
					end
				else
					warn("Missing function for key:", key)
				end
			end
		end)
	end
end)