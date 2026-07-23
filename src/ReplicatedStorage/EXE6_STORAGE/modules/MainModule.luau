local tween_service = game:GetService("TweenService")
local marketplace_service = game:GetService("MarketplaceService")
local user_service = game:GetService("UserService")
local input_service = game:GetService("UserInputService")
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local info_2 = TweenInfo.new(.8, Enum.EasingStyle.Exponential)
local quick = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local smooth = TweenInfo.new(1, Enum.EasingStyle.Exponential)

local back = TweenInfo.new(.5, Enum.EasingStyle.Back)
local long_back = TweenInfo.new(.8, Enum.EasingStyle.Back)

local two = TweenInfo.new(1.5, Enum.EasingStyle.Exponential)
local two_delay = TweenInfo.new(1.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
local two_rev = TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, true)

local client = players.LocalPlayer

local storage = script.Parent.Parent
local events = storage.events

local ClassIcons = require(storage.modules.ClassIcons)
local Utilities = require(storage.modules.Utilities)
local Alerts = require(storage.modules.Alerts)
local Configuration = require(storage.modules.Configuration)
local CustomCommands = require(storage.modules.CustomCommands)
local Leaflet = require(storage.modules.Leaflet)
local Signal = require(storage.modules.Signal)
local Slider = require(storage.modules.Slider)

local cam = workspace.CurrentCamera

local ui = client.PlayerGui:WaitForChild("EXE6")

local main_frame = ui.main_frame
local navigation = main_frame.content.navigation
local screen = main_frame.content.screen

local modals = ui.modal_frame

local profile = modals.profile
local ban = modals.ban
local kick = modals.kick
local ban_history = modals.ban_history
local server_teleportation = modals.server_teleportation
local progress_tracker = modals.progress_tracker
local confirmation_prompt = modals.confirmation
local character_viewer = modals.character_viewer
local role_info = modals.role_info
local announcement = modals.announcement
local notify = modals.notify
local warn = modals.warn
local chat_history = modals.chat_history
local warn_history = modals.warn_history
local attachment = modals.attachments
local privacy = modals.privacy
local custom_command = modals.custom_command
local preview = modals.preview
local notification_history = modals.notification_history
local live_track = modals.live_track
local fly = modals.fly

local param_enum = modals.parameter_enum
local param_player = modals.parameter_player

local spectate = ui.spectate
local context_menu = ui.context_menu

local module = {}

-- Events

module.ScreenChanged = Signal.new()

-- INTERFACE

function cache(t, frame)
	for i, other_modals in pairs(module.GetOpenedModals()) do
		if other_modals ~= frame and other_modals.Interactable then
			table.insert(t, other_modals)

			other_modals.Interactable = false
		end
	end
end

function FireBootGlow()
	if not Configuration.Interface.StartupEffect then return end

	local blur = lighting:FindFirstChild("Exe6BootBlur")
	local color = lighting:FindFirstChild("Exe6BootColorCorrection")

	if not blur then
		blur = Instance.new("BlurEffect")
		blur.Name = "Exe6BootBlur"
		blur.Size = 0
		blur.Parent = lighting
	end

	if not color then 
		color = Instance.new("ColorCorrectionEffect")
		color.Name = "Exe6BootColorCorrection"
		color.Parent = lighting
	end

	Utilities.Haptic(.5, 1.5)

	tween_service:Create(blur, two_rev, {Size = 12}):Play()
	tween_service:Create(color, two_rev, {Brightness = .2, Contrast = 1,
		Saturation = .5}):Play()
end

function module.SetFullscreen(state)
	if state then
		main_frame:SetAttribute("Fullscreen", true)

		if Utilities.GetViewportRatio() > 1300 then
			main_frame.content.LeafletControls.Bottom.Resize.Visible = false

			main_frame.content.LeafletControls.Top.Actions.Frame.Container.fullscreen.Visible = false
			main_frame.content.LeafletControls.Top.Actions.Frame.Container.restore.Visible = true

			main_frame.content.LeafletControls.Top.Actions.Size = UDim2.new(0, 85, 1, 0)
		else
			main_frame.content.LeafletControls.Bottom.Resize.Visible = false

			main_frame.content.LeafletControls.Top.Actions.Frame.Container.fullscreen.Visible = false
			main_frame.content.LeafletControls.Top.Actions.Frame.Container.restore.Visible = false

			main_frame.content.LeafletControls.Top.Actions.Size = UDim2.new(0, 60, 1, 0)
		end

		--

		tween_service:Create(main_frame, info, {BackgroundTransparency = 0}):Play()

		tween_service:Create(main_frame.content.LeafletControls.Top, info, {Position = UDim2.fromOffset(0, 50)}):Play()
		tween_service:Create(main_frame.content.navigation.padding, info, {PaddingTop = UDim.new(0, 50)}):Play()
		tween_service:Create(main_frame.content.LeafletControls.Space, info, {Size = UDim2.new(1, 0, 1, -100)}):Play()

		--

		if main_frame:GetAttribute("NavigationMenu") then
			if main_frame.AbsoluteSize.X > 500 then
				tween_service:Create(main_frame.content.navigation, info, {
					Size = UDim2.new(0, 220, 1, 0),
					AnchorPoint = Vector2.new(0, 0)}):Play()

				tween_service:Create(main_frame.content.screen, info, {
					AnchorPoint = Vector2.new(1, 1), 
					Size = UDim2.new(1, -225, 1, -10)}):Play()

				main_frame:SetAttribute("PortraitMode", false)

			else

				main_frame:SetAttribute("PortraitMode", true)

				tween_service:Create(main_frame.content.navigation, info, {
					Size = UDim2.new(1, 0, 1, 0),
					AnchorPoint = Vector2.new(0, 0)}):Play()

				tween_service:Create(main_frame.content.screen, info, {
					AnchorPoint = Vector2.new(0, 1), 
					Size = UDim2.new(1, -225, 1, -10)}):Play()
			end
		else
			tween_service:Create(main_frame.content.screen, info, {Size = UDim2.new(1, -10, 1, -100)}):Play()
		end
	else
		main_frame:SetAttribute("Fullscreen", false)

		if Utilities.GetViewportRatio() > 1300 then
			main_frame.content.LeafletControls.Bottom.Resize.Visible = true

			main_frame.content.LeafletControls.Top.Actions.Frame.Container.fullscreen.Visible = true
			main_frame.content.LeafletControls.Top.Actions.Frame.Container.restore.Visible = false

			main_frame.content.LeafletControls.Top.Actions.Size = UDim2.new(0, 85, 1, 0)
		else
			main_frame.content.LeafletControls.Bottom.Resize.Visible = false

			main_frame.content.LeafletControls.Top.Actions.Frame.Container.fullscreen.Visible = false
			main_frame.content.LeafletControls.Top.Actions.Frame.Container.restore.Visible = false

			main_frame.content.LeafletControls.Top.Actions.Size = UDim2.new(0, 60, 1, 0)
		end

		--

		tween_service:Create(main_frame, info, {BackgroundTransparency = 1}):Play()

		tween_service:Create(main_frame.content.LeafletControls.Top, info, {Position = UDim2.fromOffset(0, 0)}):Play()
		tween_service:Create(main_frame.content.navigation.padding, info, {PaddingTop = UDim.new(0, 0)}):Play()
		tween_service:Create(main_frame.content.LeafletControls.Space, info, {Size = UDim2.new(1, 0, 1, -50)}):Play()

		--

		if main_frame:GetAttribute("NavigationMenu") then
			if main_frame.AbsoluteSize.X > 500 then
				tween_service:Create(main_frame.content.navigation, info, {
					Size = UDim2.new(0, 220, 1, 0),
					AnchorPoint = Vector2.new(0, 0)}):Play()

				tween_service:Create(main_frame.content.screen, info, {
					AnchorPoint = Vector2.new(1, 1), 
					Size = UDim2.new(1, -225, 1, -10)}):Play()

				main_frame:SetAttribute("PortraitMode", false)
			else

				tween_service:Create(main_frame.content.navigation, info, {
					Size = UDim2.new(1, 0, 1, 0),
					AnchorPoint = Vector2.new(0, 0)}):Play()

				tween_service:Create(main_frame.content.screen, info, {
					AnchorPoint = Vector2.new(0, 1), 
					Size = UDim2.new(1, -225, 1, -10)}):Play()

				main_frame:SetAttribute("PortraitMode", true)
			end
		else
			tween_service:Create(main_frame.content.screen, info, {Size = UDim2.new(1, -10, 1, -50)}):Play()
		end
	end
end

function module.NavigationMenu(state)
	if state then
		main_frame:SetAttribute("NavigationMenu", true)
		main_frame.content.navigation.Interactable = true

		--

		if main_frame.AbsoluteSize.X > 500 then
			tween_service:Create(main_frame.content.navigation, info, {
				Size = UDim2.new(0, 220, 1, 0),
				AnchorPoint = Vector2.new(0, 0)}):Play()

			tween_service:Create(main_frame.content.screen, info, {
				AnchorPoint = Vector2.new(1, 1), 
				Size = UDim2.new(1, -225, 1, -10)}):Play()

			main_frame:SetAttribute("PortraitMode", false)

		else

			tween_service:Create(main_frame.content.navigation, info, {
				Size = UDim2.new(1, -20, 1, 0),
				AnchorPoint = Vector2.new(0, 0)}):Play()

			tween_service:Create(main_frame.content.screen, info, {
				AnchorPoint = Vector2.new(0, 1), 
				Size = UDim2.new(1, -225, 1, -10)}):Play()

			main_frame:SetAttribute("PortraitMode", true)
		end

	else
		main_frame:SetAttribute("NavigationMenu", false)
		main_frame.content.navigation.Interactable = false

		--

		tween_service:Create(main_frame.content.navigation, info, {AnchorPoint = Vector2.new(1, 0)}):Play()

		if main_frame:GetAttribute("Fullscreen") then
			tween_service:Create(main_frame.content.screen, info, {
				AnchorPoint = Vector2.new(1, 1), 
				Size = UDim2.new(1, -10, 1, -100)}):Play()
		else
			tween_service:Create(main_frame.content.screen, info, {
				AnchorPoint = Vector2.new(1, 1), 
				Size = UDim2.new(1, -10, 1, -50)}):Play()
		end
	end
end

local Exe6Booted = false
local Exe6Booting = false

--Toggles the Exe 6 panel.
function module.Exe6(state, ForceCloseModals)
	if Exe6Booting then return end

	task.spawn(function()
		if state then
			if main_frame.Visible then return end

			main_frame.Visible = true
			main_frame.Interactable = false
			main_frame.ImageTransparency = 1
			main_frame.BackgroundTransparency = 1

			events.ui.ExeToggled:Fire(state)

			Utilities.Haptic(.4)
			Utilities.ResetScrollPosition(ui)

			if not Exe6Booted then -- Booting
				Exe6Booting = true

				main_frame.page:JumpTo(main_frame.loading)

				main_frame.Position = UDim2.fromScale(.5, .5)
				main_frame.Size = UDim2.fromOffset(200, 150)
				main_frame.ImageColor3 = Color3.fromRGB(0, 0, 0)
				main_frame.SliceScale = 1

				main_frame.loading.logo.ImageTransparency = 1
				main_frame.loading.logo.scale.Scale = .8
				main_frame.loading.logo.Position = UDim2.fromScale(.5, .5)

				main_frame.page.Animated = false
				main_frame.scale.Scale = .8

				--

				tween_service:Create(main_frame, info, {ImageTransparency = 0}):Play()
				tween_service:Create(main_frame.scale, info, {Scale = 1}):Play()

				tween_service:Create(main_frame.loading.logo, info, {ImageTransparency = 0}):Play()
				tween_service:Create(main_frame.loading.logo.scale, info, {Scale = 1}):Play()

				-- Waiting

				task.wait(2)

				--

				main_frame.page.Animated = true

				FireBootGlow()

				ui.storage.opening:Play()

				--
				task.wait(1)
				--

				Exe6Booted = true	
				Exe6Booting = false

			else -- Booted

				main_frame.page.Animated = false

				module.GoToScreen(screen.home)

				main_frame.page.Animated = false
				main_frame.scale.Scale = .8

				--

				tween_service:Create(main_frame.scale, info, {Scale = 1}):Play()
			end

			if Utilities.GetViewportRatio() > 1300 then

				module.SetFullscreen(false)

				-- Desktop

				tween_service:Create(main_frame, info, {
					Position = UDim2.fromScale(.5, .5),
					ImageColor3 = Color3.fromRGB(27, 27, 27),
					ImageTransparency = .03,
					BackgroundTransparency = 1,
					SliceScale = .08,
					Size = UDim2.fromOffset(900, 500)}):Play()
			else

				module.SetFullscreen(true)

				-- Mobile

				tween_service:Create(main_frame, info, {
					Position = UDim2.fromScale(.5, .5),
					ImageColor3 = Color3.fromRGB(27, 27, 27),
					ImageTransparency = 1,
					BackgroundTransparency = 0,
					SliceScale = .08,
					Size = UDim2.fromScale(1, 1)}):Play()
			end

			--

			main_frame.page:JumpTo(main_frame.content)
			module.GoToScreen(main_frame.content.screen.home)

			--
			task.wait(.5)
			--

			main_frame.Interactable = true

			if main_frame:GetAttribute("Fullscreen") then
				module.NavigationMenu(false)
			else
				module.NavigationMenu(true)
			end
		else
			if not main_frame.Visible then return end

			main_frame.page.Animated = false
			main_frame.page:JumpTo(main_frame.empty)

			if ForceCloseModals then
				events.ui.ForceCloseModals:Fire()
			end

			--

			tween_service:Create(main_frame, info, {
				ImageTransparency = 1,
				BackgroundTransparency = 1}):Play()

			tween_service:Create(main_frame.scale, info, {Scale = .8}):Play()

			--
			task.wait(.5)
			--

			main_frame.Visible = false
		end
	end)
end

local InScreenTransition = false

function module.GoToScreen(page)
	task.spawn(function()
		if page.Parent ~= screen then return end

		if not InScreenTransition then
			InScreenTransition = true

			screen.page:JumpTo(page)
			screen.padding.PaddingTop = UDim.new(.5, 0)
			
			module.ScreenChanged:Fire(page)

			--

			tween_service:Create(screen.padding, info, {PaddingTop = UDim.new(0, 0)}):Play()

			-- Button

			for i, dir in pairs(navigation.directory:GetDescendants()) do
				if dir:IsA("ImageButton") and dir:HasTag("Exe6ScreenButton") then
					if screen.page.CurrentPage == dir.util.screen_directory.Value then

						tween_service:Create(dir, info, {BackgroundTransparency = 0}):Play()
						tween_service:Create(dir.padding, info, {PaddingLeft = UDim.new(0, 15)}):Play()
						tween_service:Create(dir.stroke, info, {Transparency = 0}):Play()

						tween_service:Create(dir.icon, info, {ImageTransparency = 0}):Play()
						tween_service:Create(dir.label, info, {TextTransparency = 0}):Play()

					else

						tween_service:Create(dir, info, {BackgroundTransparency = 1}):Play()
						tween_service:Create(dir.padding, info, {PaddingLeft = UDim.new(0, 10)}):Play()
						tween_service:Create(dir.stroke, info, {Transparency = 1}):Play()

						tween_service:Create(dir.icon, info, {ImageTransparency = .5}):Play()
						tween_service:Create(dir.label, info, {TextTransparency = .5}):Play()

					end
				end
			end

			-- Transition Animation

			local scroll = page:FindFirstChild("scroll")
			if not scroll then return end

			local list = scroll:FindFirstChild("list")
			local padding = scroll:FindFirstChild("padding")
			if not list or not padding then return end

			padding.PaddingTop = UDim.new(1, 0)
			list.Padding = UDim.new(1, 0)

			tween_service:Create(padding, info, {PaddingTop = UDim.new(0, 0)}):Play()
			tween_service:Create(list, info_2, {Padding = UDim.new(0, 15)}):Play()

			--
			task.wait(1)
			--

			InScreenTransition = false
		end
	end)
end

function module.CurrentScreen()
	return screen.page.CurrentPage
end

function module.GetOpenedModals()
	local opened_modals = {}

	for i, opened in pairs(modals:GetChildren()) do
		if opened:IsA("ImageButton") and opened.Visible then
			table.insert(opened_modals, opened)
		end
	end

	return opened_modals
end

--

local profile_connections = {}

function module.Profile(state, id, Source)
	if state then
		if profile.Visible then return end
		
		for _, conn in profile_connections do
			task.cancel(conn)
		end

		profile.Visible = true
		profile.Interactable = true
		profile.Position = UDim2.fromScale(.5, 1.5)

		profile.frame.fade.Visible = false
		profile.frame.loading.Visible = true
		profile.frame.content.Visible = false

		profile:SetAttribute("UserId", id)

		Utilities.ResetScrollPosition(profile)

		-- Source Calculation
		
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(profile)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(profile)
		Leaflet:CaptureFocus(profile)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, profile)

			profile.Position = Transforms.Position
			profile.Size = Transforms.Size

			profile.scale.Scale = .6
		else
			profile.Position = UDim2.fromScale(.5, 1.5)
			profile.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(profile, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(profile, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(profile.scale, info, {Scale = 1}):Play()

		-- Fetching Datas

		local person =  players:GetPlayerByUserId(id)
		local success, result = pcall(function()
			return user_service:GetUserInfosByUserIdsAsync({id})
		end)

		if success and result[1] then
			profile.frame.content.scroll.status.team.Visible = false
			profile.frame.content.scroll.team.role.Visible = false
			
			profile_connections.authfetching = task.spawn(function()
				local authorized = events.auth.Auth:InvokeServer("IsAuthorized", id)
				
				if authorized then
					profile.frame.content.scroll.status.team.value.Text = authorized.Role.Alias
				else
					profile.frame.content.scroll.status.team.value.Text = "Guest"
				end
				
				profile.frame.content.scroll.status.team.Visible = true
				profile.frame.content.scroll.team.role.Visible = authorized ~= nil
			end)
			
			profile.frame.fade.identity.profile.photo.Image = Utilities.GetPlayerThumbnail(id)
			profile.frame.fade.identity.username.Text = result[1].Username
			profile.frame.fade.identity.display.Text = Utilities.AddBadgeToIdentifier(
				result[1].DisplayName, result[1].HasVerifiedBadge, "")

			if person then
				local account_age = Utilities.FormatSecondsToYM(person.AccountAge) or "Just Created"
				local playtime = Utilities.FormatSecondsToHM(events.misc.GetPlaytime:InvokeServer(person.UserId)) or "Just Joined"

				profile.frame.content.scroll.status.account_age.value.Text = account_age
				profile.frame.content.scroll.status.playtime.value.Text = playtime
			end

			for i, online_features in profile.frame.content.scroll:GetDescendants() do
				if online_features:HasTag("Exe6ProfileActionOnline") then
					online_features.Visible = person
				end
			end

			profile.frame.content.scroll.fly.Visible = client.UserId == id

			profile.frame.fade.Visible = true
			profile.frame.content.Visible = true
			profile.frame.loading.Visible = false

			--

			events.ui.ModalToggled:Fire(profile, true)
		else

			module.Profile(false)

			Alerts.BannerNotify({
				Header = "Failed to load profile.";
				Description = "An error occurred upon fetching user's profile data.";
				Icon = "rbxassetid://11433647387";
				Involved = {id}
			})
		end
	else
		if not profile.Visible then return end

		Leaflet:Deactivate(profile)

		tween_service:Create(profile, info, {Position = UDim2.new(0, profile.Position.X.Offset, 1.5, 0)}):Play()

		--
		task.wait(.5)
		--

		profile.Visible = false

		events.ui.ModalToggled:Fire(profile, false)
	end
end

function module.Ban(state, userids, Source)
	if state then
		if ban.Visible then return end

		ban.Visible = true
		ban.Interactable = true
		ban.Position = UDim2.fromScale(.5, 1.5)

		ban:SetAttribute("ApplyToUniverse", true)
		ban:SetAttribute("Duration", 86400)
		ban:SetAttribute("ExcludeAltAccounts", false)
		ban:SetAttribute("ModeratorNote", "")
		ban:SetAttribute("Reason", "")
		ban:SetAttribute("SerializedIds", "")

		ban.frame.loading.Visible = true

		ban.frame.content.Visible = true
		ban.frame.content.GroupTransparency = 1

		ban.frame.content.page:JumpTo(ban.frame.content.properties)
		ban.frame.content.properties.scroll.CanvasPosition = Vector2.new(0, 0)

		ban.frame.content.properties.scroll.duration.box.textbox.Text = ""
		ban.frame.content.properties.scroll.moderator_note.textbox.Text = ""
		ban.frame.content.properties.scroll.reason.textbox.Text = ""

		Utilities.ResetScrollPosition(ban)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(ban)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(ban)
		Leaflet:CaptureFocus(ban)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, ban)

			ban.Position = Transforms.Position
			ban.Size = Transforms.Size

			ban.scale.Scale = .6
		else
			ban.Position = UDim2.fromScale(.5, 1.5)
			ban.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(ban, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(ban, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(ban.scale, info, {Scale = 1}):Play()

		-- Loading

		ban.frame.content.properties.bottom.Manage.Button.preview.player.Image = Utilities.GetPlayerThumbnail(userids[1])
		ban.frame.content.properties.bottom.Manage.Button.preview.more.Visible = #userids > 1

		for i, residual in pairs(ban.frame.content.players.scroll:GetChildren()) do
			if residual:IsA("ImageButton") then
				residual:Destroy()
			end
		end

		for i, id in userids do
			local item = ban.frame.content.players.scroll.list.item:Clone()

			item.Name = id
			item.profile.Image = Utilities.GetPlayerThumbnail(id)
			item.username.Text = "@" .. players:GetNameFromUserIdAsync(id)
			item.Parent = ban.frame.content.players.scroll

			item.erase.MouseButton1Click:Connect(function()
				local pos = table.find(userids, id)

				if pos then
					table.remove(userids, pos)

					--

					if not table.find(userids, id) then
						ban:SetAttribute("SerializedIds", Utilities.SerializeNumberTable(userids))

						Alerts.BannerNotify({
							Header = "Removed Successfully";
							Description = "The UserId; " .. id .. " is successfully removed.";
							Icon = "rbxassetid://11422145434";
							Involved = {id}
						})

						item:Destroy()

						--

						if #userids < 1 then
							module.Ban(false)
							Alerts.BannerNotify({
								Header = "Ban Failed";
								Description = "Ban menu closed due to deficient number of players.";
								Icon = "rbxassetid://11419666199";
							})
						end
					end
				else
					Alerts.BannerNotify({
						Header = "Failed to remove";
						Description = "The UserId; " .. id .. " isn't found therefore failed to be removed.";
						Icon = "rbxassetid://11433646681";
						Involved = {id}
					})
				end
			end)
		end

		ban.frame.content.properties.scroll.duration.box.expiration.date.Text = Utilities.FormatSecondsToRealDate(86400)
		ban.frame.loading.Visible = false

		ban:SetAttribute("SerializedIds", Utilities.SerializeNumberTable(userids))

		--

		tween_service:Create(ban.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(ban, true)
	else
		if not ban.Visible then return end

		Leaflet:Deactivate(ban)

		tween_service:Create(ban, info, {Position = UDim2.new(0, ban.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(ban.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		ban.Visible = false

		events.ui.ModalToggled:Fire(ban, false)
	end
end

function module.Kick(state, userids, Source)
	if state then
		if kick.Visible then return end

		kick.Visible = true
		kick.Interactable = true
		kick.Position = UDim2.fromScale(.5, 1.5)

		kick:SetAttribute("Reason", "")
		kick:SetAttribute("SerializedIds", "")

		kick.frame.loading.Visible = true

		kick.frame.content.Visible = true
		kick.frame.content.GroupTransparency = 1

		kick.frame.content.page:JumpTo(kick.frame.content.properties)
		kick.frame.content.properties.scroll.CanvasPosition = Vector2.new(0, 0)

		kick.frame.content.properties.scroll.reason.textbox.Text = ""

		Utilities.ResetScrollPosition(kick)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(kick)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(kick)
		Leaflet:CaptureFocus(kick)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, kick)

			kick.Position = Transforms.Position
			kick.Size = Transforms.Size

			kick.scale.Scale = .6
		else
			kick.Position = UDim2.fromScale(.5, 1.5)
			kick.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(kick, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(kick, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(kick.scale, info, {Scale = 1}):Play()

		-- Loading

		kick.frame.content.properties.bottom.Manage.Button.preview.player.Image = Utilities.GetPlayerThumbnail(userids[1])
		kick.frame.content.properties.bottom.Manage.Button.preview.more.Visible = #userids > 1

		for i, residual in pairs(kick.frame.content.players.scroll:GetChildren()) do
			if residual:IsA("ImageButton") then
				residual:Destroy()
			end
		end

		for i, id in userids do
			local item = kick.frame.content.players.scroll.list.item:Clone()

			item.Name = id
			item.profile.Image = Utilities.GetPlayerThumbnail(id)
			item.username.Text = "@" .. players:GetNameFromUserIdAsync(id)
			item.Parent = kick.frame.content.players.scroll

			item.erase.MouseButton1Click:Connect(function()
				local pos = table.find(userids, id)

				if pos then
					table.remove(userids, pos)

					--

					if not table.find(userids, id) then
						Alerts.BannerNotify({
							Header = "Removed Successfully";
							Description = "The UserId; " .. id .. " is successfully removed.";
							Icon = "rbxassetid://11422145434";
							Involved = {id}
						})

						item:Destroy()

						--

						if #userids < 1 then
							module.Kick(false)
							Alerts.BannerNotify({
								Header = "Kick Failed";
								Description = "Kick menu closed due to deficient number of players.";
								Icon = "rbxassetid://11419666199";
							})
						end
					end
				else
					Alerts.BannerNotify({
						Header = "Failed to remove";
						Description = "The UserId; " .. id .. " isn't found therefore failed to be removed.";
						Icon = "rbxassetid://11433646681";
						Involved = {id}
					})
				end
			end)
		end

		kick.frame.loading.Visible = false

		kick:SetAttribute("SerializedIds", Utilities.SerializeNumberTable(userids))

		--

		tween_service:Create(kick.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(kick, true)
	else
		if not kick.Visible then return end

		Leaflet:Deactivate(kick)

		tween_service:Create(kick, info, {Position = UDim2.new(0, kick.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(kick.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		kick.Visible = false

		events.ui.ModalToggled:Fire(kick, false)
	end
end

function module.BanHistory(state, display_server, id, Source)
	if state then
		if ban_history.Visible then return end

		local authorized = events.auth.Auth:InvokeServer("IsAuthorized", client.UserId)
		if not authorized then return end

		local permitted = events.auth.Auth:InvokeServer("GetRoleSetting", authorized.Role.Alias, "ViewBanHistory")
		if not permitted then
			Alerts.BannerNotify({
				Header = "Failed to load Ban History.",
				Description = "You have no access to Ban History.",
				Icon = "rbxassetid://11422916589"
			})

			return 
		end

		--

		ban_history.Visible = true
		ban_history.Interactable = true
		ban_history.Position = UDim2.fromScale(.5, 1.5)

		ban_history.frame.fade.Visible = false

		ban_history.frame.loading.Visible = true

		ban_history.frame.content.Visible = true
		ban_history.frame.content.GroupTransparency = 1

		ban_history.frame.content.scroll.CanvasPosition = Vector2.new(0, 0)

		ban_history:SetAttribute("UserId", id)

		Utilities.ResetScrollPosition(ban_history)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(ban_history)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(ban_history)
		Leaflet:CaptureFocus(ban_history)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, ban_history)

			ban_history.Position = Transforms.Position
			ban_history.Size = Transforms.Size

			ban_history.scale.Scale = .6
		else
			ban_history.Position = UDim2.fromScale(.5, 1.5)
			ban_history.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(ban_history, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(ban_history, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(ban_history.scale, info, {Scale = 1}):Play()

		-- Loading

		task.spawn(function()
			local IsSaved = events.auth.IdSaving:InvokeServer("IsUserIdSaved", id)

			ban_history.frame.content.bottom.Visible = IsSaved
		end)

		for i, residual in pairs(ban_history.frame.content.scroll.history:GetChildren()) do
			if residual:IsA("Frame") and residual:HasTag("Exe6BanHistoryLog") then
				residual:Destroy()
			end
		end

		local history = events.components.GetBanHistory:InvokeServer(id)
		local userids = events.auth.FetchRecordedIds:InvokeServer()
		local data, status

		if history and userids then

			for i, log in pairs(history) do
				local item = ban_history.frame.content.scroll.history.list.log:Clone()

				item.Name = log.StartTime

				item.content.timestamp.Text = Utilities.FormatISO(log.StartTime)

				--

				if log.Ban then
					if log.Duration > 0 then
						item.content.header.Text = "Banned for " .. Utilities.FormateSecondsToWord(log.Duration)
					else								
						item.content.header.Text = "Banned permanently"
					end

					item.Icon.page:JumpTo(item.Icon.ban)

					item.content.note.value.Text = (log.PrivateReason ~= "" and log.PrivateReason or "No note provided.")
					item.content.reason.value.Text = (log.DisplayReason ~= "" and log.DisplayReason or "No reason provided.")
				else
					item.content.header.Text = "Ban revoked"

					item.Icon.page:JumpTo(item.Icon.revoke)
				end

				item.Parent = ban_history.frame.content.scroll.history
			end

			for i, encoded in pairs(userids.Permanent) do
				local set = string.split(encoded, ";")

				if tonumber(set[1]) == id then
					data = encoded
					status = "Permanent"

					break
				end
			end

			for i, encoded in pairs(userids.Expiring) do
				local set = string.split(encoded, ";")

				if tonumber(set[1]) == id then
					data = encoded
					status = "Expiring"

					break
				end
			end

			for i, encoded in pairs(userids.Expired) do
				local set = string.split(encoded, ";")

				if tonumber(set[1]) == id then
					data = encoded
					status = "Expired"

					break
				end
			end

			for i, encoded in pairs(userids.Revoked) do
				local set = string.split(encoded, ";")

				if tonumber(set[1]) == id then
					data = encoded
					status = "Revoked"

					break
				end
			end

			if data then
				local set = string.split(data, ";")

				if status == "Permanent" then
					ban_history.frame.content.scroll.information.moderator.Visible = events.auth.Auth:InvokeServer("IsAuthorized", tonumber(set[2])) ~= false

					ban_history.frame.content.scroll.information.duration.label.Text = "Unknown"

					ban_history.frame.content.scroll.information.moderator.label.Text = Utilities.GetNameByUserIdAsync(tonumber(set[2]), true)
					ban_history.frame.content.scroll.information.moderator.icon.Image = Utilities.GetPlayerThumbnail(tonumber(set[2]))

					ban_history:SetAttribute("Moderator", tonumber(set[2]))

				elseif status == "Expiring" or status == "Expired" then
					local seconds = set[2] - os.time()

					ban_history.frame.content.scroll.information.moderator.Visible = events.auth.Auth:InvokeServer("IsAuthorized", tonumber(set[3]))  ~= false

					ban_history.frame.content.scroll.information.duration.label.Text = Utilities.FormatSecondsToRealDate(seconds)

					ban_history.frame.content.scroll.information.moderator.label.Text = Utilities.GetNameByUserIdAsync(tonumber(set[3]), true)
					ban_history.frame.content.scroll.information.moderator.icon.Image = Utilities.GetPlayerThumbnail(tonumber(set[3]))

					ban_history:SetAttribute("Moderator", tonumber(set[3]))

				elseif status == "Revoked" then
					if set[3] then
						local seconds = set[2] - os.time()

						ban_history.frame.content.scroll.information.moderator.Visible = events.auth.Auth:InvokeServer("IsAuthorized", tonumber(set[3])) ~= false

						ban_history.frame.content.scroll.information.duration.label.Text = Utilities.FormatSecondsToRealDate(seconds)

						ban_history.frame.content.scroll.information.moderator.label.Text = Utilities.GetNameByUserIdAsync(tonumber(set[3]), true)
						ban_history.frame.content.scroll.information.moderator.icon.Image = Utilities.GetPlayerThumbnail(tonumber(set[3]))

						ban_history:SetAttribute("Moderator", tonumber(set[3]))

					elseif set[2] then
						ban_history.frame.content.scroll.information.moderator.Visible = events.auth.Auth:InvokeServer("IsAuthorized", tonumber(set[2])) ~= false

						ban_history.frame.content.scroll.information.duration.label.Text = "Unknown"

						ban_history.frame.content.scroll.information.moderator.label.Text = Utilities.GetNameByUserIdAsync(tonumber(set[2]), true)
						ban_history.frame.content.scroll.information.moderator.icon.Image = Utilities.GetPlayerThumbnail(tonumber(set[2]))

						ban_history:SetAttribute("Moderator", tonumber(set[2]))
					end
				end

				ban_history.frame.content.scroll.information.game_type.Visible = true
				ban_history.frame.content.scroll.information.server_type.Visible = false

				ban_history.frame.fade.identity.profile.photo.Image = Utilities.GetPlayerThumbnail(id)
				ban_history.frame.fade.identity.display.Text = Utilities.GetDisplayNameById(id)
				ban_history.frame.fade.identity.username.Text = Utilities.GetNameByUserIdAsync(id, true)
			else
				module.BanHistory(false)

				Alerts.BannerNotify({
					Header = "Ban History failed to load.";
					Description = "There is no history saved on this account yet.";
					Icon = "rbxassetid://11432858706";
					Involved = {id}
				})
			end

		else

			module.BanHistory(false)

			Alerts.BannerNotify({
				Header = "Ban History failed to load.";
				Description = "An error occurred upon fetching Ban History.";
				Icon = "rbxassetid://11432858706";
				Involved = {id}
			})
		end

		ban_history.frame.fade.Visible = true
		ban_history.frame.loading.Visible = false

		--

		tween_service:Create(ban_history.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(ban_history, true)

	else
		if not ban_history.Visible then return end

		Leaflet:Deactivate(ban_history)

		tween_service:Create(ban_history, info, {Position = UDim2.new(0, ban_history.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(ban_history.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		ban_history.Visible = false

		events.ui.ModalToggled:Fire(ban_history, false)
	end
end

function module.ServerTeleportation(state, Source)
	if state then
		if server_teleportation.Visible then return end

		server_teleportation.Visible = true
		server_teleportation.Interactable = true
		server_teleportation.Position = UDim2.fromScale(.5, 1.5)

		server_teleportation.frame.content.Visible = true
		server_teleportation.frame.content.GroupTransparency = 1

		server_teleportation.frame.content.scroll.CanvasPosition = Vector2.new(0, 0)

		server_teleportation.frame.content.scroll.destination.textbox.Text = ""

		Utilities.ResetScrollPosition(server_teleportation)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(server_teleportation)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(server_teleportation)
		Leaflet:CaptureFocus(server_teleportation)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, server_teleportation)

			server_teleportation.Position = Transforms.Position
			server_teleportation.Size = Transforms.Size

			server_teleportation.scale.Scale = .6
		else
			server_teleportation.Position = UDim2.fromScale(.5, 1.5)
			server_teleportation.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(server_teleportation, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(server_teleportation, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(server_teleportation.scale, info, {Scale = 1}):Play()

		tween_service:Create(server_teleportation.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(server_teleportation, true)
	else
		if not server_teleportation.Visible then return end

		Leaflet:Deactivate(server_teleportation)

		tween_service:Create(server_teleportation, info, {
			Position = UDim2.new(0, server_teleportation.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(server_teleportation.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		server_teleportation.Visible = false

		events.ui.ModalToggled:Fire(server_teleportation, false)
	end
end

function module.TrackProgress(state, operation, Source)
	if state then
		if progress_tracker.Visible then return end

		progress_tracker.Visible = true
		progress_tracker.Interactable = true
		progress_tracker.Position = UDim2.fromScale(.5, 1.5)

		if operation then
			progress_tracker.frame.content.label.Visible = true
			progress_tracker.frame.content.label.Text = operation
		else
			progress_tracker.frame.content.label.Visible = false
		end

		Utilities.Haptic(1)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(progress_tracker)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(progress_tracker)
		Leaflet:CaptureFocus(progress_tracker)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, progress_tracker)

			progress_tracker.Position = Transforms.Position
			progress_tracker.Size = Transforms.Size

			progress_tracker.scale.Scale = .6
		else
			progress_tracker.Position = UDim2.fromScale(.5, 1.5)
			progress_tracker.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(progress_tracker, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(progress_tracker, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(progress_tracker.scale, info, {Scale = 1}):Play()

		--

		events.ui.ModalToggled:Fire(progress_tracker, true)
	else
		if not progress_tracker.Visible then return end

		Leaflet:Deactivate(progress_tracker)

		tween_service:Create(progress_tracker, info, {Position = UDim2.new(0, progress_tracker.Position.X.Offset, 1.5, 0)}):Play()

		--
		task.wait(.5)
		--

		progress_tracker.Visible = false

		events.ui.ModalToggled:Fire(progress_tracker, false)
	end
end

function module.CharacterViewer(state, id, Source)
	if state then
		if character_viewer.Visible then return end

		character_viewer.Visible = true
		character_viewer.Interactable = true
		character_viewer.Position = UDim2.fromScale(.5, 1.5)

		character_viewer.frame.loading.Visible = true

		character_viewer.frame.content.Visible = true
		character_viewer.frame.content.GroupTransparency = 1

		character_viewer.frame.content.canvas.viewport.scale.Scale = 2

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(character_viewer)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(character_viewer)
		Leaflet:CaptureFocus(character_viewer)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, character_viewer)

			character_viewer.Position = Transforms.Position
			character_viewer.Size = Transforms.Size

			character_viewer.scale.Scale = .6
		else
			character_viewer.Position = UDim2.fromScale(.5, 1.5)
			character_viewer.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(character_viewer, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(character_viewer, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(character_viewer.scale, info, {Scale = 1}):Play()

		-- Loading

		local rig = players:CreateHumanoidModelFromUserIdAsync(id)
		local dump = character_viewer.frame.content.canvas.viewport:FindFirstChildWhichIsA("Model")

		if dump then dump:Destroy() end

		for i, risidual in pairs(rig:GetDescendants()) do
			if rig:IsA("Script") or rig:IsA("LocalScript") then
				rig:Destroy()
			end
		end

		rig.Parent = workspace

		--
		task.wait()
		--

		rig:PivotTo(character_viewer.frame.content.canvas.viewport.Point.CFrame)
		rig.Parent = character_viewer.frame.content.canvas.viewport

		character_viewer.frame.loading.Visible = false

		--
		task.wait(1)
		--

		tween_service:Create(character_viewer.frame.content.canvas.viewport.scale, info, {Scale = 1}):Play()
		tween_service:Create(character_viewer.frame.content, info, {GroupTransparency = 0}):Play()

		-- Guidelines

		task.spawn(function()
			tween_service:Create(character_viewer.frame.content.guidelines, info, {ImageTransparency = .7}):Play()

			--
			task.wait(1)
			--

			tween_service:Create(character_viewer.frame.content.guidelines, smooth, {ImageTransparency = 1}):Play()
		end)

		--

		events.ui.ModalToggled:Fire(character_viewer, true)
	else
		if not character_viewer.Visible then return end

		Leaflet:Deactivate(character_viewer)

		tween_service:Create(character_viewer, info, {Position = UDim2.new(0, character_viewer.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(character_viewer.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		character_viewer.Visible = false

		-- Clearance

		local dump = character_viewer.frame.content.canvas.viewport:FindFirstChildWhichIsA("Model")

		if dump then dump:Destroy() end

		events.ui.ModalToggled:Fire(character_viewer, false)
	end
end

function module.RoleInfo(state, role, Source)
	if state then
		if role_info.Visible then return end

		local roleInfo = role_info.frame.content.scroll.info

		local allowedFeatures = role_info.frame.content.scroll.allowed
		local deniedFeatures = role_info.frame.content.scroll.denied

		local unknownFeatures = role_info.frame.content.scroll.unknown

		local roleInfo = {}

		local allowedList = {}
		local deniedList = {}
		local unknownList = {}

		local Names, Descriptions = Utilities.GetPermsVisualsList()

		role_info.Visible = true
		role_info.Interactable = true
		role_info.Position = UDim2.fromScale(.5, 1.5)

		role_info.frame.loading.Visible = true
		role_info.frame.content.Visible = false

		role_info.frame.content.scroll.CanvasPosition = Vector2.new(0, 0)

		for _, dump in pairs(role_info.frame.content.scroll:GetDescendants()) do
			if dump:HasTag("Exe6RoleInfoPermission") and dump.Visible then
				dump:Destroy()
			end
		end

		Utilities.ResetScrollPosition(role_info)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(role_info)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(role_info)
		Leaflet:CaptureFocus(role_info)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, role_info)

			role_info.Position = Transforms.Position
			role_info.Size = Transforms.Size

			role_info.scale.Scale = .6
		else
			role_info.Position = UDim2.fromScale(.5, 1.5)
			role_info.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(role_info, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(role_info, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(role_info.scale, info, {Scale = 1}):Play()

		-- Get list & role

		local RoleList = events.auth.FetchRoles:InvokeServer()
		local RoleRequested = RoleList[role]

		if not RoleList or not RoleRequested then
			module.RoleInfo(false)

			Alerts.BannerNotify({
				Header = "Failed to load role.";
				Description = "An error occurred upon fetching role's properties.";
				Icon = "rbxassetid://11433647387";
			})

			return
		end

		for permission, state in pairs(RoleRequested) do

			if permission == "Alias" or permission == "Accent" or 
				permission == "Kickable" or permission == "Bannable" or permission == "Warnable" then

				roleInfo[permission] = state
			else

				if state == true then
					table.insert(allowedList, permission)
				else
					table.insert(deniedList, permission)
				end

			end

		end

		-- Info

		role_info.frame.content.scroll.info.container.role_name.value.Text = role
		role_info.frame.content.scroll.info.container.accent.icon.ImageColor3 = RoleRequested["Accent"]

		if RoleRequested["Kickable"] == true then
			role_info.frame.content.scroll.info.container.kickable.label.Text = "This role can be kicked."
		else
			role_info.frame.content.scroll.info.container.kickable.label.Text = "This role can't be kicked."
		end

		if RoleRequested["Bannable"] == true then
			role_info.frame.content.scroll.info.container.bannable.label.Text = "This role can be banned."
		else
			role_info.frame.content.scroll.info.container.bannable.label.Text = "This role can't be banned."
		end

		if RoleRequested["Warnable"] == true then
			role_info.frame.content.scroll.info.container.warnable.label.Text = "This role can be warned."
		else
			role_info.frame.content.scroll.info.container.warnable.label.Text = "This role can't be warned."
		end

		-- Allowed list

		if #allowedList > 0 then

			role_info.frame.content.scroll.allowed.container.empty.Visible = false

			for _, permission in pairs(allowedList) do

				local Title = Names[permission]
				local Description = Descriptions[permission]

				if (not Title) or (not Description) then
					table.insert(unknownList, permission)
				else
					local item = role_info.frame.content.scroll.list.template:Clone()

					item.Visible = true
					item.label.Text = Title
					item.description.Text = Description

					item.Parent = role_info.frame.content.scroll.allowed.container
				end

			end

		else
			role_info.frame.content.scroll.allowed.container.empty.Visible = true
		end

		-- Denied list

		if #deniedList > 0 then

			role_info.frame.content.scroll.denied.container.empty.Visible = false

			for _, permission in pairs(deniedList) do
				local Title = Names[permission]
				local Description = Descriptions[permission]

				if (not Title) or (not Description) then
					table.insert(unknownList, permission)
				else
					local item = role_info.frame.content.scroll.list.template:Clone()

					item.Visible = true
					item.label.Text = Title
					item.description.Text = Description

					item.Parent = role_info.frame.content.scroll.denied.container
				end

			end

		else
			role_info.frame.content.scroll.denied.container.empty.Visible = true
		end

		-- Unknown list

		if #unknownList > 0 then

			role_info.frame.content.scroll.unknown.container.empty.Visible = false

			for _, permission in pairs(unknownList) do
				local item = role_info.frame.content.scroll.list.template:Clone()

				item.Visible = true
				item.label.Text = permission
				item.description.Text = tostring(RoleRequested[permission])

				item.Parent = role_info.frame.content.scroll.unknown.container
			end

		else
			role_info.frame.content.scroll.unknown.container.empty.Visible = true
		end

		--

		role_info.frame.loading.Visible = false
		role_info.frame.content.Visible = true

		--

		events.ui.ModalToggled:Fire(role_info, true)
	else
		if not role_info.Visible then return end

		Leaflet:Deactivate(role_info)

		tween_service:Create(role_info, info, {Position = UDim2.new(0, role_info.Position.X.Offset, 1.5, 0)}):Play()

		--
		task.wait(.5)
		--

		role_info.Visible = false

		events.ui.ModalToggled:Fire(role_info, false)
	end
end

function module.Announcement(state, Source)
	if state then
		if announcement.Visible then return end

		announcement.Visible = true
		announcement.Interactable = true

		announcement:SetAttribute("Header", "")
		announcement:SetAttribute("Announcement", "")

		announcement.frame.content.Visible = true
		announcement.frame.content.GroupTransparency = 1

		announcement.frame.content.scroll.CanvasPosition = Vector2.new(0, 0)

		announcement.frame.content.scroll.header.textbox.Text = ""
		announcement.frame.content.scroll.announcement.textbox.Text = ""

		Utilities.ResetScrollPosition(announcement)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(announcement)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(announcement)
		Leaflet:CaptureFocus(announcement)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, announcement)

			announcement.Position = Transforms.Position
			announcement.Size = Transforms.Size

			announcement.scale.Scale = .6
		else
			announcement.Position = UDim2.fromScale(.5, 1.5)
			announcement.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(announcement, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(announcement, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(announcement.scale, info, {Scale = 1}):Play()

		tween_service:Create(announcement.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(announcement, true)
	else
		if not announcement.Visible then return end

		Leaflet:Deactivate(announcement)

		tween_service:Create(announcement, info, {Position = UDim2.new(0, announcement.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(announcement.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		announcement.Visible = false

		events.ui.ModalToggled:Fire(announcement, false)
	end
end

function module.Notify(state, ids, Source)
	if state then
		if notify.Visible then return end

		notify.Visible = true
		notify.Interactable = true
		notify.Position = UDim2.fromScale(.5, 1.5)

		notify:SetAttribute("Recipient", Utilities.SerializeNumberTable(ids))
		notify:SetAttribute("Header", "")
		notify:SetAttribute("Notification", "")

		notify.frame.content.Visible = true
		notify.frame.content.GroupTransparency = 1

		notify.frame.content.scroll.CanvasPosition = Vector2.new(0, 0)

		notify.frame.content.scroll.header.textbox.Text = ""
		notify.frame.content.scroll.notification.textbox.Text = ""

		Utilities.ResetScrollPosition(notify)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(notify)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(notify)
		Leaflet:CaptureFocus(notify)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, notify)

			notify.Position = Transforms.Position
			notify.Size = Transforms.Size

			notify.scale.Scale = .6
		else
			notify.Position = UDim2.fromScale(.5, 1.5)
			notify.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(notify, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(notify, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(notify.scale, info, {Scale = 1}):Play()

		tween_service:Create(notify.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(notify, true)
	else
		if not notify.Visible then return end

		Leaflet:Deactivate(notify)

		tween_service:Create(notify, info, {Position = UDim2.new(0, notify.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(notify.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		notify.Visible = false

		events.ui.ModalToggled:Fire(notify, false)
	end
end

function module.Spectate(state, id)
	if state then
		if spectate.Visible then return end

		local recipient =  players:GetPlayerByUserId(id)

		if not recipient then
			Alerts.BannerNotify({
				Header = "Unable to Spectate";
				Description = "Unable find the user to spectate." ;
				Icon = "rbxassetid://11419709766";
			})

			return
		end

		local authorized = events.auth.Auth:InvokeServer("IsAuthorized", recipient.UserId)
		local character = recipient.Character or recipient.CharacterAdded:Wait()

		spectate.Visible = true
		spectate.Interactable = true
		spectate.Position = UDim2.fromScale(.5, .5)

		spectate.GroupTransparency = 1
		spectate.scale.Scale = 1.25
		spectate.Visible = true

		spectate.frame.menu.frame.user.profile.Image = profile.frame.fade.identity.profile.photo.Image
		spectate.frame.menu.frame.user.display.Text = profile.frame.fade.identity.display.Text

		if Configuration.Spectating.MenuAlignment == "Top" then
			spectate.frame.list.VerticalAlignment = Enum.VerticalAlignment.Top
			spectate.frame.gradient.Rotation = -90

		elseif Configuration.Spectating.MenuAlignment == "Bottom" then
			spectate.frame.list.VerticalAlignment = Enum.VerticalAlignment.Bottom
			spectate.frame.gradient.Rotation = 90
		end

		if authorized then
			spectate.frame.menu.frame.user.role.Visible = true
			spectate.frame.menu.frame.user.role.Text = authorized.Role.Alias

			spectate.frame.menu.frame.user.role.TextColor3 = Utilities.AdjustColor(authorized.Role.Accent)
			spectate.frame.menu.frame.user.role.BackgroundColor3 = authorized.Role.Accent
		else
			spectate.frame.menu.frame.user.role.Visible = false
		end

		task.spawn(function()
			events.ui.ForceCloseModals:Fire()
		end)

		workspace.CurrentCamera.CameraSubject = character:WaitForChild("Humanoid")

		tween_service:Create(spectate, info, {GroupTransparency = 0}):Play()
		tween_service:Create(spectate.scale, smooth, {Scale = 1}):Play()

		events.ui.ModalToggled:Fire(spectate, true)
	else
		if not spectate.Visible then return end

		workspace.CurrentCamera.CameraSubject = client.Character:WaitForChild("Humanoid")

		tween_service:Create(spectate, info, {GroupTransparency = 1}):Play()
		tween_service:Create(spectate.scale, info, {Scale = 1.25}):Play()

		--
		task.wait(.5)
		--

		spectate.Visible = false

		events.ui.ModalToggled:Fire(spectate, false)
	end
end

export type ConfirmationProperties = {
	ID: any,
	Header: any,
	Description: any,
	Accept: any,
	Cancel: any,
}

function module.ConfirmationPrompt(state, Properties: ConfirmationProperties, Source)
	if state then
		if confirmation_prompt.Visible then return end

		confirmation_prompt.Visible = true
		confirmation_prompt.Interactable = true
		confirmation_prompt.Position = UDim2.fromScale(.5, 1.5)

		confirmation_prompt:SetAttribute("CurrentPromptID", Properties.ID)

		confirmation_prompt.frame.content.header.Text = Properties.Header or "No title yet."
		confirmation_prompt.frame.content.label.Text = Properties.Description or "No description yet."

		confirmation_prompt.frame.content.actions.accept.Text = Properties.Accept or "Continue"
		confirmation_prompt.frame.content.actions.cancel.Text = Properties.Cancel or "Cancel"

		Utilities.Haptic(1)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(confirmation_prompt)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(confirmation_prompt)
		Leaflet:CaptureFocus(confirmation_prompt)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, confirmation_prompt)

			confirmation_prompt.Position = Transforms.Position
			confirmation_prompt.Size = Transforms.Size

			confirmation_prompt.scale.Scale = .6
		else
			confirmation_prompt.Position = UDim2.fromScale(.5, 1.5)
			confirmation_prompt.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(confirmation_prompt, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(confirmation_prompt, info, {Size = UDim2.fromOffset(450, 0)}):Play()
		tween_service:Create(confirmation_prompt.scale, info, {Scale = 1}):Play()

		--

		events.ui.ModalToggled:Fire(confirmation_prompt, true)
	else
		if not confirmation_prompt.Visible then return end

		Leaflet:Deactivate(confirmation_prompt)

		tween_service:Create(confirmation_prompt, info, {Position = UDim2.new(0, confirmation_prompt.Position.X.Offset, 1.5, 0)}):Play()

		--
		task.wait(.5)
		--

		confirmation_prompt.Visible = false

		events.ui.ModalToggled:Fire(confirmation_prompt, false)
	end
end

function module.Warn(state, userids, Source)
	if state then
		if warn.Visible then return end

		warn.Visible = true
		warn.Interactable = true
		warn.Position = UDim2.fromScale(.5, 1.5)

		warn:SetAttribute("Warning", "")
		warn:SetAttribute("SerializedIds", "")

		warn.frame.loading.Visible = true

		warn.frame.content.Visible = true
		warn.frame.content.GroupTransparency = 1

		warn.frame.content.page:JumpTo(warn.frame.content.properties)
		warn.frame.content.properties.scroll.CanvasPosition = Vector2.new(0, 0)

		warn.frame.content.properties.scroll.warning.textbox.Text = ""

		Utilities.ResetScrollPosition(warn)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(warn)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(warn)
		Leaflet:CaptureFocus(warn)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, warn)

			warn.Position = Transforms.Position
			warn.Size = Transforms.Size

			warn.scale.Scale = .6
		else
			warn.Position = UDim2.fromScale(.5, 1.5)
			warn.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(warn, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(warn, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(warn.scale, info, {Scale = 1}):Play()

		-- Loading

		warn.frame.content.properties.bottom.Manage.Button.preview.player.Image = Utilities.GetPlayerThumbnail(userids[1])
		warn.frame.content.properties.bottom.Manage.Button.preview.more.Visible = #userids > 1

		for i, residual in pairs(warn.frame.content.players.scroll:GetChildren()) do
			if residual:IsA("ImageButton") then
				residual:Destroy()
			end
		end

		for i, id in userids do
			local item = warn.frame.content.players.scroll.list.item:Clone()

			item.Name = id
			item.profile.Image = Utilities.GetPlayerThumbnail(id)
			item.username.Text = "@" .. players:GetNameFromUserIdAsync(id)
			item.Parent = warn.frame.content.players.scroll

			item.erase.MouseButton1Click:Connect(function()
				local pos = table.find(userids, id)

				if pos then
					table.remove(userids, pos)

					--

					if not table.find(userids, id) then
						Alerts.BannerNotify({
							Header = "Removed Successfully";
							Description = "The UserId; " .. id .. " is successfully removed.";
							Icon = "rbxassetid://11422145434";
							Involved = {id}
						})

						item:Destroy()

						--

						if #userids < 1 then
							module.Warn(false)
							Alerts.BannerNotify({
								Header = "Warn Failed";
								Description = "Warn menu closed due to deficient number of players.";
								Icon = "rbxassetid://11419666199";
							})
						end
					end
				else
					Alerts.BannerNotify({
						Header = "Failed to remove";
						Description = "The UserId; " .. id .. " isn't found therefore failed to be removed.";
						Icon = "rbxassetid://11433646681";
						Involved = {id}
					})
				end
			end)
		end

		warn.frame.loading.Visible = false

		warn:SetAttribute("SerializedIds", Utilities.SerializeNumberTable(userids))

		--

		tween_service:Create(warn.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(warn, true)
	else
		if not warn.Visible then return end

		Leaflet:Deactivate(warn)

		tween_service:Create(warn, info, {Position = UDim2.new(0, warn.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(warn.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		warn.Visible = false

		events.ui.ModalToggled:Fire(warn, false)
	end
end

function module.ChatHistory(state, id, Source)
	if state then
		if chat_history.Visible then return end

		--

		local authorized = events.auth.Auth:InvokeServer("IsAuthorized", client.UserId)
		if not authorized then return end

		local permitted = events.auth.Auth:InvokeServer("GetRoleSetting", authorized.Role.Alias, "ViewChatHistory")
		if not permitted then
			Alerts.BannerNotify({
				Header = "Failed to load Ban History.",
				Description = "You have no access to Chat History.",
				Icon = "rbxassetid://11422916589"
			})

			return 
		end

		--

		chat_history.Visible = true
		chat_history.Interactable = true
		chat_history.Position = UDim2.fromScale(.5, 1.5)

		chat_history:SetAttribute("UserId", id)

		chat_history.frame.loading.Visible = true
		chat_history.frame.loading.TextTransparency = .8

		chat_history.frame.content.Visible = true
		chat_history.frame.content.GroupTransparency = 1

		Utilities.ResetScrollPosition(chat_history)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(chat_history)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(chat_history)
		Leaflet:CaptureFocus(chat_history)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, chat_history)

			chat_history.Position = Transforms.Position
			chat_history.Size = Transforms.Size

			chat_history.scale.Scale = .6
		else
			chat_history.Position = UDim2.fromScale(.5, 1.5)
			chat_history.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(chat_history, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(chat_history, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(chat_history.scale, info, {Scale = 1}):Play()

		-- Loading

		local History = events.components.GetChatHistory:InvokeServer(id)
		local UnsavedChats = events.auth.FetchUnsavedChats:InvokeServer(id)

		if UnsavedChats then
			History = Utilities.CombineTables(History, UnsavedChats)
		end

		if #History <= 0 then
			chat_history.frame.content.scroll.util.label.Visible = true
			chat_history.frame.content.scroll.label.Visible = false
		else
			chat_history.frame.content.scroll.util.label.Visible = false
			chat_history.frame.content.scroll.label.Visible = true
		end

		for _, i in pairs(chat_history.frame.content.scroll:GetChildren()) do
			if i:HasTag("Exe6SavedChat") then
				i:Destroy()
			end
		end

		for _, data in pairs(History) do
			if not data.Date and not data.Timestamp then
				continue
			end

			local epoch = Utilities.FormatEpochData(data.Date or data.Timestamp)
			local ref = epoch.Calender.Month.Short .. epoch.Calender.Day .. epoch.Calender.Year.Short
			local group = chat_history.frame.content.scroll:FindFirstChild(ref)

			if group then
				local chat = group.list.chat:Clone()

				chat.time.label.Text = epoch.Time.Hour .. ":" .. epoch.Time.Minutes .. epoch.Time.Period
				chat.message.Text = data.Message

				chat.Name = epoch.Time.Hour .. epoch.Time.Minutes .. epoch.Time.Seconds .. epoch.Time.Period
				chat.LayoutOrder = -Utilities.GetEpochStats(data.Timestamp, "minutes", "day")
				chat.Parent = group

			else
				group = chat_history.frame.content.scroll.list.group:Clone()
				local chat = group.list.chat:Clone()

				group.header.header.label.Text = epoch.Calender.Month.Long .. " " .. epoch.Calender.Day .. ", "
					.. epoch.Calender.Year.Long

				group.Name = ref
				group.LayoutOrder = -Utilities.GetEpochStats(data.Timestamp, "days", "year")
				group.Parent = chat_history.frame.content.scroll

				chat.time.label.Text = epoch.Time.Hour .. ":" .. epoch.Time.Minutes .. epoch.Time.Period
				chat.message.Text = data.Message

				chat.Name = epoch.Time.Hour .. epoch.Time.Minutes .. epoch.Time.Seconds .. epoch.Time.Period
				chat.LayoutOrder = -Utilities.GetEpochStats(data.Timestamp, "minutes", "day")
				chat.Parent = group
			end
		end

		tween_service:Create(chat_history.frame.loading, info, {TextTransparency = 1}):Play()
		tween_service:Create(chat_history.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(chat_history, true)
	else
		if not chat_history.Visible then return end

		Leaflet:Deactivate(chat_history)

		tween_service:Create(chat_history, info, {Position = UDim2.new(0, chat_history.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(chat_history.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		chat_history.Visible = false

		events.ui.ModalToggled:Fire(chat_history, false)
	end
end

function module.WarnHistory(state, id, Source)
	if state then
		if warn_history.Visible then return end

		local authorized = events.auth.Auth:InvokeServer("IsAuthorized", client.UserId)
		if not authorized then return end

		local permitted = events.auth.Auth:InvokeServer("GetRoleSetting", authorized.Role.Alias, "ViewWarnHistory")
		if not permitted then
			Alerts.BannerNotify({
				Header = "Failed to load Warn History.",
				Description = "You have no access to Ban History.",
				Icon = "rbxassetid://11422916589"
			})

			return 
		end

		--

		warn_history.Visible = true
		warn_history.Interactable = true
		warn_history.Position = UDim2.fromScale(.5, 1.5)

		warn_history:SetAttribute("UserId", id)

		warn_history.frame.loading.Visible = true

		warn_history.frame.content.Visible = true
		warn_history.frame.content.GroupTransparency = 1

		Utilities.ResetScrollPosition(warn_history)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(warn_history)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(warn_history)
		Leaflet:CaptureFocus(warn_history)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, warn_history)

			warn_history.Position = Transforms.Position
			warn_history.Size = Transforms.Size

			warn_history.scale.Scale = .6
		else
			warn_history.Position = UDim2.fromScale(.5, 1.5)
			warn_history.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(warn_history, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(warn_history, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(warn_history.scale, info, {Scale = 1}):Play()

		-- Loading

		local History = events.components.GetWarningHistory:InvokeServer(id)
		local GroupOrder = 9999999

		if #History <= 0 then
			warn_history.frame.content.scroll.util.label.Visible = true
			warn_history.frame.content.scroll.label.Visible = false
		else
			warn_history.frame.content.scroll.util.label.Visible = false
			warn_history.frame.content.scroll.label.Visible = true
		end

		for _, i in pairs(warn_history.frame.content.scroll:GetChildren()) do
			if i:HasTag("Exe6SavedWarn") then
				i:Destroy()
			end
		end

		for _, data in pairs(History) do
			local epoch = Utilities.FormatEpochData(data.Timestamp)
			local ref = epoch.Calender.Month.Short .. epoch.Calender.Year.Long
			local group = warn_history.frame.content.scroll:FindFirstChild(ref)

			if group then
				local item = group.container.list.item:Clone()

				item.warning.Text = data.Message

				item.details.date.Text = epoch.Calender.Month.Long .. " " .. epoch.Calender.Day .. ", " ..
					epoch.Time.Hour .. ":" .. epoch.Time.Minutes .. epoch.Time.Period
				item.details.moderator.Text = Utilities.GetNameByUserIdAsync(data.Moderator, true)

				if data.Read then
					item.util.read.Visible = true
				else
					item.util.unread.Visible = true
				end

				item.LayoutOrder = -Utilities.GetEpochStats(data.Timestamp, "minutes", "month")
				item.Parent = group.container

			else
				group = warn_history.frame.content.scroll.list.group:Clone()
				local item = group.container.list.item:Clone()

				GroupOrder -= 1

				group.header.header.label.Text = `{epoch.Calender.Month.Long} {epoch.Calender.Year.Long}`

				group.Name = ref
				group.LayoutOrder = GroupOrder
				group.Parent = warn_history.frame.content.scroll

				item.warning.Text = data.Message

				item.details.date.Text = epoch.Calender.Month.Long .. " " .. epoch.Calender.Day .. ", " ..
					epoch.Time.Hour .. ":" .. epoch.Time.Minutes .. epoch.Time.Period
				item.details.moderator.Text = Utilities.GetNameByUserIdAsync(data.Moderator, true)

				if data.Read then
					item.util.read.Visible = true
				else
					item.util.unread.Visible = true
				end

				item.LayoutOrder = -Utilities.GetEpochStats(data.Timestamp, "minutes", "month")
				item.Parent = group.container
			end
		end

		warn_history.frame.loading.Visible = false

		tween_service:Create(warn_history.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(warn_history, true)
	else
		if not warn_history.Visible then return end

		Leaflet:Deactivate(warn_history)

		tween_service:Create(warn_history, info, {Position = UDim2.new(0, warn_history.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(warn_history.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		warn_history.Visible = false

		events.ui.ModalToggled:Fire(warn_history, false)
	end
end

function module.NotificationHistory(state, Source)
	if state then
		if notification_history.Visible then return end

		--

		notification_history.Visible = true
		notification_history.Interactable = true
		notification_history.Position = UDim2.fromScale(.5, 1.5)

		notification_history.frame.loading.Visible = true
		notification_history.frame.loading.TextTransparency = .8

		notification_history.frame.content.Visible = true
		notification_history.frame.content.GroupTransparency = 1

		Utilities.ResetScrollPosition(notification_history)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(notification_history)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(notification_history)
		Leaflet:CaptureFocus(notification_history)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, notification_history)

			notification_history.Position = Transforms.Position
			notification_history.Size = Transforms.Size

			notification_history.scale.Scale = .6
		else
			notification_history.Position = UDim2.fromScale(.5, 1.5)
			notification_history.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(notification_history, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(notification_history, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(notification_history.scale, info, {Scale = 1}):Play()

		-- Loading

		local History = Alerts:GetNotificationHistory()

		task.spawn(function()
			for i, dump in pairs(notification_history.frame.content.scroll:GetChildren()) do
				if dump:HasTag("Exe6NotificationItem") then
					dump:Destroy()
				end
			end

			if Configuration.Notifications.NotificationHistory then
				if History and #History > 0 then
					for i, data in pairs(History) do
						local item = notification_history.frame.content.scroll.list.frame:Clone()

						item.Name = data.Header .. data.Description
						item.LayoutOrder = -i

						if data.Icon then
							item.container.icon.Image = data.Icon
						else
							item.container.icon.Visible = false
							item.space.Visible = false
						end

						if data.Header then
							item.information.header.Text = data.Header
						else
							item.information.header.Visible = false
						end

						if data.Description then
							item.information.description.Text = data.Description or "Description"
						else
							item.information.description.Visible = false
						end

						if data.Involved then
							for i, user in ipairs(data.Involved) do
								local profile = item.information.involved.list.player:Clone()

								profile.Image = Utilities.GetPlayerThumbnail(user)
								profile.ZIndex = -i
								profile.Parent = item.information.involved
							end
						end

						item.Parent = notification_history.frame.content.scroll
					end

					notification_history.frame.content.scroll.label.Visible = true
					notification_history.frame.content.scroll.util.empty.Visible = false
				else
					notification_history.frame.content.scroll.label.Visible = false
					notification_history.frame.content.scroll.util.empty.Visible = true
				end

				notification_history.frame.content.scroll.util.disabled.Visible = false
			else
				notification_history.frame.content.scroll.label.Visible = false
				notification_history.frame.content.scroll.util.disabled.Visible = true
			end
		end)

		tween_service:Create(notification_history.frame.loading, info, {TextTransparency = 1}):Play()
		tween_service:Create(notification_history.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(notification_history, true)
	else
		if not notification_history.Visible then return end

		Leaflet:Deactivate(notification_history)

		tween_service:Create(notification_history, info, {Position = UDim2.new(0, notification_history.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(notification_history.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		notification_history.Visible = false

		events.ui.ModalToggled:Fire(notification_history, false)
	end
end

function module.Attachments(state, assetids, Source)
	if state then
		if attachment.Visible then return end

		attachment.Visible = true
		attachment.Interactable = true
		attachment.Position = UDim2.fromScale(.5, 1.5)

		attachment.frame.loading.Visible = true

		attachment.frame.content.Visible = true
		attachment.frame.content.GroupTransparency = 1

		Utilities.ResetScrollPosition(attachment)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(attachment)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(attachment)
		Leaflet:CaptureFocus(attachment)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, attachment)

			attachment.Position = Transforms.Position
			attachment.Size = Transforms.Size

			attachment.scale.Scale = .6
		else
			attachment.Position = UDim2.fromScale(.5, 1.5)
			attachment.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(attachment, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(attachment, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(attachment.scale, info, {Scale = 1}):Play()

		-- Loading

		for i, dump in pairs(attachment.frame.content.scroll.container:GetChildren()) do
			if dump:IsA("ImageButton") then
				dump:Destroy()
			end
		end

		for i, ids in pairs(assetids) do
			local product_info
			local success, err = pcall(function()
				product_info = marketplace_service:GetProductInfoAsync(string.match(ids, "%d+"))
			end)

			if product_info then
				if product_info.AssetTypeId == 1 or product_info.AssetTypeId == 13 then
					local item = attachment.frame.content.scroll.container.list.image_attachment:Clone()
					local ref = "rbxassetid://" .. product_info.AssetId

					item.Name = ref

					item.details.assetname.Text = product_info.Name
					item.details.creator.Text = product_info.Creator.Name

					item.Preview.ImageTransparency = 1
					item.Preview.Photo.ImageTransparency = 1
					item.Preview.Photo.scale.Scale = .8

					item.Preview.Photo.Image = Utilities.AssetToTexture(product_info.AssetId)

					item.util.Delete.Button.MouseButton1Click:Connect(function()
						item:Destroy()
					end)

					item.Parent = attachment.frame.content.scroll.container

					--

					tween_service:Create(item.Preview, info, {ImageTransparency = 0}):Play()
					tween_service:Create(item.Preview.Photo, info, {ImageTransparency = 0}):Play()
					tween_service:Create(item.Preview.Photo.scale, info, {Scale = 1}):Play()

				elseif product_info.AssetTypeId == 3 then
					local item = attachment.frame.content.scroll.container.list.audio_attachment:Clone()
					local ref = "rbxassetid://" .. product_info.AssetId

					item.Name = ref

					item.Preview.ImageTransparency = 1
					item.Preview.Photo.BackgroundTransparency = 1
					item.Preview.Photo.icon.ImageTransparency = 1
					item.Preview.Photo.scale.Scale = .8

					item.details.assetname.Text = product_info.Name
					item.details.creator.Text = product_info.Creator.Name

					item.util.Delete.Button.MouseButton1Click:Connect(function()
						item:Destroy()
					end)

					item.Parent = attachment.frame.content.scroll.container

					--

					tween_service:Create(item.Preview, info, {ImageTransparency = 0}):Play()
					tween_service:Create(item.Preview.Photo, info, {BackgroundTransparency = 0}):Play()
					tween_service:Create(item.Preview.Photo.icon, info, {ImageTransparency = 0}):Play()
					tween_service:Create(item.Preview.Photo.scale, info, {Scale = 1}):Play()
				end
			else
				continue
			end
		end

		attachment.frame.loading.Visible = false

		tween_service:Create(attachment.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(attachment, true)
	else
		if not attachment.Visible then return end

		Leaflet:Deactivate(attachment)

		tween_service:Create(attachment, info, {Position = UDim2.new(0, attachment.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(attachment.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		attachment.Visible = false

		events.ui.ModalToggled:Fire(attachment, false)
	end
end

function module.Privacy(state, Source)
	if state then
		if privacy.Visible then return end

		privacy.Visible = true
		privacy.Interactable = true
		privacy.Position = UDim2.fromScale(.5, 1.5)

		privacy.frame.content.Visible = true
		privacy.frame.content.GroupTransparency = 0

		Utilities.ResetScrollPosition(privacy)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(privacy)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(privacy)
		Leaflet:CaptureFocus(privacy)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, privacy)

			privacy.Position = Transforms.Position
			privacy.Size = Transforms.Size

			privacy.scale.Scale = .6
		else
			privacy.Position = UDim2.fromScale(.5, 1.5)
			privacy.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(privacy, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(privacy, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(privacy.scale, info, {Scale = 1}):Play()

		--

		events.ui.ModalToggled:Fire(privacy, true)
	else
		if not privacy.Visible then return end

		Leaflet:Deactivate(privacy)

		tween_service:Create(privacy, info, {Position = UDim2.new(0, privacy.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(privacy.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		privacy.Visible = false

		events.ui.ModalToggled:Fire(privacy, false)
	end
end

function module.LiveTrack(state, Object, Source)
	if state then
		if live_track.Visible then 
			live_track.Tracking.Value = Object

			return 
		end

		live_track.Visible = true
		live_track.Interactable = true
		live_track.Position = UDim2.fromScale(.5, 1.5)

		live_track.frame.content.Visible = true
		live_track.frame.content.GroupTransparency = 0

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(live_track)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(live_track)
		Leaflet:CaptureFocus(live_track)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, live_track)

			live_track.Position = Transforms.Position
			live_track.Size = Transforms.Size

			live_track.scale.Scale = .6
		else
			live_track.Position = UDim2.fromScale(.5, 1.5)
			live_track.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(live_track, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(live_track, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(live_track.scale, info, {Scale = 1}):Play()

		live_track.Tracking.Value = Object

		--

		events.ui.ModalToggled:Fire(live_track, true)
	else

		if not live_track.Visible then return end

		live_track.Tracking.Value = nil

		Leaflet:Deactivate(live_track)

		tween_service:Create(live_track, info, {Position = UDim2.new(0, live_track.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(live_track.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		live_track.Visible = false

		events.ui.ModalToggled:Fire(live_track, false)
	end
end

function module.Fly(state, Source)
	if state then
		if fly.Visible then 
			return 
		end

		fly.Visible = true
		fly.Interactable = true
		fly.Position = UDim2.fromScale(.5, 1.5)

		fly.frame.content.Visible = true

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(fly)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(fly)
		Leaflet:CaptureFocus(fly)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, fly)

			fly.Position = Transforms.Position
			fly.Size = Transforms.Size

			fly.scale.Scale = .6
		else
			fly.Position = UDim2.fromScale(.5, 1.5)
			fly.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(fly, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(fly, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(fly.scale, info, {Scale = 1}):Play()
		
		--
		
		local FlyState = events.NoClip.GetState:InvokeServer(client)

		if FlyState then
			fly.frame.content.InactiveStatus.Visible = false
			fly.frame.content.ActiveStatus.Visible = true

			tween_service:Create(fly.frame.content.Orientation, info, {GroupTransparency = 0}):Play()
		else
			fly.frame.content.InactiveStatus.Visible = true
			fly.frame.content.ActiveStatus.Visible = false

			tween_service:Create(fly.frame.content.Orientation, info, {Rotation = 0, GroupTransparency = 1}):Play()
		end

		--

		events.ui.ModalToggled:Fire(fly, true)
	else

		if not fly.Visible then return end

		Leaflet:Deactivate(fly)

		tween_service:Create(fly, info, {Position = UDim2.new(0, fly.Position.X.Offset, 1.5, 0)}):Play()

		--
		task.wait(.5)
		--

		fly.Visible = false

		events.ui.ModalToggled:Fire(fly, false)
	end
end

-- This function will yield until further action.
function module.ParameterEnum(state, data, SelectionRange, header, Source)
	if state then
		if param_enum.Visible then return end

		param_enum.Visible = true
		param_enum.Interactable = true
		param_enum.Position = UDim2.fromScale(.5, 1.5)

		param_enum.frame.content.Visible = true
		param_enum.frame.content.GroupTransparency = 1

		param_enum.frame.LeafletControls.Top.Title.Container.Text = header or "Enum Parameter"
		param_enum.frame.content.bottom.Search.Field.textbox.Text = ""

		param_enum.frame.loading.Visible = true

		Utilities.ResetScrollPosition(param_enum)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(param_enum)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(param_enum)
		Leaflet:CaptureFocus(param_enum)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, param_enum)

			param_enum.Position = Transforms.Position
			param_enum.Size = Transforms.Size

			param_enum.scale.Scale = .6
		else
			param_enum.Position = UDim2.fromScale(.5, 1.5)
			param_enum.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(param_enum, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(param_enum, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(param_enum.scale, info, {Scale = 1}):Play()

		-- Loading

		local SessionEnded = false
		local SessionCancelled = false

		local SingleSelect = SelectionRange.Max == 1

		param_enum:SetAttribute("SingleSelect", SingleSelect)

		param_enum.frame.content.bottom.Select.Visible = not SingleSelect
		param_enum.frame.content.bottom.Selections.Visible = not SingleSelect

		param_enum.frame.content.bottom.Selections.Button.count.Text = 0

		for i, dump in pairs(param_enum.frame.content.scroll:GetChildren()) do
			if dump:HasTag("Exe6EnumItem") then
				dump:Destroy()
			end
		end

		local selected = {}

		for i, item in pairs(data) do
			local class = typeof(item)

			if not class then 
				break 
			end

			local obj = param_enum.frame.content.scroll.list:FindFirstChild(class)
			local button

			if obj then
				button = obj:Clone()
			else
				button = param_enum.frame.content.scroll.list.undefined:Clone()
			end

			if class == "BrickColor" then
				button.emblem.ImageColor3 = item.Color
			elseif class == "Color3" then
				button.emblem.ImageColor3 = item

			elseif class == "boolean" then
				if item == false then
					button.emblem.left.Visible = true
				elseif item == true then
					button.emblem.right.Visible = true
				end

			elseif class == "Instance" then
				local icon = ClassIcons.GetClassIcon(item.ClassName)

				if item.ClassName == "ImageLabel" or item.ClassName == "ImageButton" then
					if item.Image == "" then
						if icon then
							button.emblem.icon.Image = icon
						end
					else
						button.emblem.icon.Image = item.Image
					end
				elseif item.ClassName == "Decal" then
					if item.Texture == "" then
						if icon then
							button.emblem.icon.Image = icon
						end
					else
						button.emblem.icon.Image = item.Texture
					end
				else
					if icon then
						button.emblem.icon.Image = icon
					end
				end
			end

			if class == "Instance" then
				local ins_class = item.ClassName

				if Configuration.ParameterEnum.ShowClassType then
					button.value.Text = ins_class .. ": " .. tostring(item)
				else
					button.value.Text = tostring(item)
				end
			else
				if Configuration.ParameterEnum.ShowClassType then
					if typeof(i) == "string" then
						button.value.Text = class .. ": " .. i
					else
						button.value.Text = class .. ": " .. tostring(item)
					end
				else
					if typeof(i) == "string" then
						button.value.Text = i
					else

						button.value.Text = tostring(item)
					end
				end
			end

			button.Name = tostring(item)
			button:SetAttribute("class", class)

			button.Parent = param_enum.frame.content.scroll

			--

			button.MouseButton1Click:Connect(function()
				if button:GetAttribute("selected") then
					table.remove(selected, table.find(selected, item) or 0)

					button:SetAttribute("selected", false)

					tween_service:Create(button.util.badge.selection, info, {ImageTransparency = 1}):Play()
					tween_service:Create(button.util.badge.selection.scale, info, {Scale = .8}):Play()
				else
					if SelectionRange.Max > #selected then
						table.insert(selected, item)

						button:SetAttribute("selected", true)

						if SelectionRange.Max == 1 then 
							SessionEnded = true
						else
							tween_service:Create(button.util.badge.selection, info, {ImageTransparency = 0}):Play()
							tween_service:Create(button.util.badge.selection.scale, info, {Scale = 1}):Play()
						end
					else
						Alerts.BannerNotify({
							Header = "Selection Failed",
							Description = "You have selected " .. SelectionRange.Max .. " item(s) already.",
							Icon = "rbxassetid://12967513681"
						})
					end
				end

				param_enum.frame.content.bottom.Selections.Button.count.Text = #selected
			end)
		end

		param_enum.frame.loading.Visible = false

		tween_service:Create(param_enum.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(param_enum, true)

		-- Yielding Method

		param_enum.frame.content.bottom.Select.Button.MouseButton1Click:Connect(function()
			if #selected >= SelectionRange.Min then
				SessionEnded = true
			end
		end)

		param_enum.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
			SessionCancelled = true
		end)

		repeat task.wait() until SessionEnded or SessionCancelled

		module.ParameterEnum(false)

		if SessionEnded then
			return selected
		end

		if SessionCancelled then
			return nil
		end
	else
		if not param_enum.Visible then return end

		Leaflet:Deactivate(param_enum)

		tween_service:Create(param_enum, info, {Position = UDim2.new(0, param_enum.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(param_enum.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		param_enum.Visible = false

		events.ui.ModalToggled:Fire(param_enum, false)
	end
end

function module.GetEnumItems(data)
	local collection = {}

	for i, item in pairs(data) do
		local class = typeof(item)

		if not class then 
			break 
		end

		local obj = param_enum.frame.content.scroll.list:FindFirstChild(class)
		local button

		if obj then
			button = obj:Clone()
		else
			button = param_enum.frame.content.scroll.list.undefined:Clone()
		end

		if class == "BrickColor" then
			button.emblem.ImageColor3 = item.Color
		elseif class == "Color3" then
			button.emblem.ImageColor3 = item

		elseif class == "boolean" then
			if item == false then
				button.emblem.left.Visible = true
			elseif item == true then
				button.emblem.right.Visible = true
			end

		elseif class == "Instance" then
			local icon = ClassIcons.GetClassIcon(item.ClassName)

			if item.ClassName == "ImageLabel" or item.ClassName == "ImageButton" then
				if item.Image == "" then
					if icon then
						button.emblem.icon.Image = icon
					end
				else
					button.emblem.icon.Image = item.Image
				end
			elseif item.ClassName == "Decal" then
				if item.Texture == "" then
					if icon then
						button.emblem.icon.Image = icon
					end
				else
					button.emblem.icon.Image = item.Texture
				end
			else
				if icon then
					button.emblem.icon.Image = icon
				end
			end
		end

		if class == "Instance" then
			local ins_class = item.ClassName

			if Configuration.ParameterEnum.ShowClassType then
				button.value.Text = ins_class .. ": " .. tostring(item)
			else
				button.value.Text = tostring(item)
			end
		else
			if Configuration.ParameterEnum.ShowClassType then
				if typeof(i) == "string" then
					button.value.Text = class .. ": " .. i
				else
					button.value.Text = class .. ": " .. tostring(item)
				end
			else
				if typeof(i) == "string" then
					button.value.Text = i
				else

					button.value.Text = tostring(item)
				end
			end
		end

		button.Name = tostring(item)
		button:SetAttribute("class", class)

		table.insert(collection, button)
	end

	return collection
end

-- This function will yield until further action.
function module.ParameterPlayer(state, SelectionRange, header, Source)
	if state then
		if param_player.Visible then return end

		param_player.Visible = true
		param_player.Interactable = true
		param_player.Position = UDim2.fromScale(.5, 1.5)

		param_player.frame.content.Visible = true
		param_player.frame.content.GroupTransparency = 1

		param_player.frame.LeafletControls.Top.Title.Container.Text = header or "Enum Parameter"
		param_player.frame.content.bottom.Search.Field.textbox.Text = ""

		param_player.frame.loading.Visible = true

		Utilities.ResetScrollPosition(param_player)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(param_player)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(param_player)
		Leaflet:CaptureFocus(param_player)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, param_player)

			param_player.Position = Transforms.Position
			param_player.Size = Transforms.Size

			param_player.scale.Scale = .6
		else
			param_player.Position = UDim2.fromScale(.5, 1.5)
			param_player.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(param_player, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(param_player, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(param_player.scale, info, {Scale = 1}):Play()

		-- Loading

		local SessionEnded = false
		local SessionCancelled = false

		local SingleSelect = SelectionRange.Max == 1

		param_player:SetAttribute("SingleSelect", SingleSelect)

		param_player.frame.content.bottom.Select.Visible = not SingleSelect
		param_player.frame.content.bottom.Selections.Visible = not SingleSelect

		param_player.frame.content.bottom.Selections.Button.count.Text = 0

		for i, dump in pairs(param_player.frame.content.scroll:GetChildren()) do
			if dump:HasTag("Exe6PersonItem") then
				dump:Destroy()
			end
		end

		local selected = {}

		for i, plr in pairs(players:GetPlayers()) do
			local item = param_player.frame.content.scroll.list.item:Clone()
			local authorized = events.auth.Auth:InvokeServer("IsAuthorized", plr.UserId)

			item.Name = plr.Name

			item.profile.Image = Utilities.GetPlayerThumbnail(plr.UserId)
			item.display.Text = Utilities.AddBadgeToIdentifier(plr.DisplayName, plr.HasVerifiedBadge, plr.MembershipType)

			item:SetAttribute("id", plr.UserId)

			if authorized then
				item.role.BackgroundColor3 = authorized.Role.Accent
				item.role.TextColor3 = Utilities.AdjustColor(authorized.Role.Accent)
				item.role.Text = authorized.Role.Alias
			else
				item.role.Visible = false
			end

			item.Parent = param_player.frame.content.scroll

			--

			item.MouseButton1Click:Connect(function()
				if item:GetAttribute("selected") then
					table.remove(selected, table.find(selected, plr) or 0)

					item:SetAttribute("selected", false)

					tween_service:Create(item.util.badge.selection, info, {ImageTransparency = 1}):Play()
					tween_service:Create(item.util.badge.selection.scale, info, {Scale = .8}):Play()
				else
					if SelectionRange.Max > #selected then
						table.insert(selected, plr)

						item:SetAttribute("selected", true)

						if SelectionRange.Max == 1 then 
							SessionEnded = true
						else
							tween_service:Create(item.util.badge.selection, info, {ImageTransparency = 0}):Play()
							tween_service:Create(item.util.badge.selection.scale, info, {Scale = 1}):Play()
						end
					else
						Alerts.BannerNotify({
							Header = "Selection Failed",
							Description = "You have selected " .. SelectionRange.Max .. " player(s) already.",
							Icon = "rbxassetid://12967513681"
						})
					end
				end

				param_player.frame.content.bottom.Selections.Button.count.Text = #selected
			end)
		end

		param_player.frame.loading.Visible = false

		tween_service:Create(param_player.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(param_player, true)

		-- Yielding Method

		param_player.frame.content.bottom.Select.Button.MouseButton1Click:Connect(function()
			if #selected >= SelectionRange.Min then
				SessionEnded = true
			end
		end)

		param_player.frame.LeafletControls.Top.Close.Button.MouseButton1Click:Connect(function()
			SessionCancelled = true
		end)

		repeat task.wait() until SessionEnded or SessionCancelled

		module.ParameterPlayer(false)

		if SessionEnded then
			return selected
		end

		if SessionCancelled then
			return nil
		end
	else
		if not param_player.Visible then return end

		Leaflet:Deactivate(param_player)

		tween_service:Create(param_player, info, {Position = UDim2.new(0, param_player.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(param_player.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		param_player.Visible = false

		events.ui.ModalToggled:Fire(param_player, false)
	end
end

function module.GetPlayerItems(data)
	local collection = {}

	for i, plr in pairs(data) do
		local item = param_player.frame.content.scroll.list.item:Clone()
		local authorized = events.auth.Auth:InvokeServer("IsAuthorized", plr.UserId)

		item.Name = plr.Name

		item.profile.Image = Utilities.GetPlayerThumbnail(plr.UserId)
		item.display.Text = Utilities.AddBadgeToIdentifier(plr.DisplayName, plr.HasVerifiedBadge, plr.MembershipType)

		item:SetAttribute("id", plr.UserId)

		if authorized then
			item.role.BackgroundColor3 = authorized.Role.Accent
			item.role.TextColor3 = Utilities.AdjustColor(authorized.Role.Accent)
			item.role.Text = authorized.Role.Alias
		else
			item.role.Visible = false
		end

		item.Name = tostring(item)

		table.insert(collection, item)
	end

	return collection
end

local CustomCommandData = {
	Name = "",
	Properties = {},
	Event = nil
}

function module.PromptCustomCommand(state, Data, Source)
	if state then
		if custom_command.Visible then return end

		CustomCommandData = {
			Name = "",
			Properties = {},
			Event = nil
		}
		
		CustomCommandData.Name = Data.Alias
		CustomCommandData.Event = Data.Event
		
		if #Data.Parameters == 0 then	
			module.ExecuteCustomCommand()
			
			return
		end

		custom_command.Visible = true
		custom_command.Interactable = true

		custom_command.frame.content.Visible = true
		custom_command.frame.content.GroupTransparency = 1

		custom_command.frame.content.scroll.CanvasPosition = Vector2.new(0, 0)
		custom_command.frame.LeafletControls.Top.Title.Container.Text = Data.Alias

		Utilities.ResetScrollPosition(custom_command)

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(custom_command)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(custom_command)
		Leaflet:CaptureFocus(custom_command)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, custom_command)

			custom_command.Position = Transforms.Position
			custom_command.Size = Transforms.Size

			custom_command.scale.Scale = .6
		else
			custom_command.Position = UDim2.fromScale(.5, 1.5)
			custom_command.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(custom_command, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(custom_command, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(custom_command.scale, info, {Scale = 1}):Play()

		-- Clearance

		local Order = 0

		for i, dump in pairs(custom_command.frame.content.scroll:GetChildren()) do
			if dump:HasTag("Exe6ParameterItem") then
				dump:Destroy()
			end
		end

		if #Data.Parameters > 0 then			
			custom_command.frame.content.scroll.util.Empty.Visible = false

			for i, Parameter in pairs(Data.Parameters) do
				Order += 1

				if Parameter.ParamType == "Player" then
					local item = custom_command.frame.content.scroll.list.PlayerParam:Clone()

					item.Name = Parameter.Name
					item.LayoutOrder = Order
					item.Header.header.label.Text = Parameter.Name
					item.Parent = custom_command.frame.content.scroll

					item.Header.Edit.MouseButton1Click:Connect(function()
						local Selects = module.ParameterPlayer(true, Parameter.SelectionRange, Parameter.Name, item.Frame)
						if not Selects then return end

						local Collection = module.GetPlayerItems(Selects)

						for i, dump in pairs(item.Frame.Container:GetChildren()) do
							if dump:IsA("ImageButton") then
								dump:Destroy()
							end
						end

						for i, Button in pairs(Collection) do
							Button.BackgroundTransparency = 1
							Button.Interactable = false

							Button.stroke:Destroy()

							Button.Parent = item.Frame.Container
						end

						CustomCommandData.Properties[Parameter.Name] = Selects
					end)

				elseif Parameter.ParamType == "Enum" then
					local item = custom_command.frame.content.scroll.list.EnumParam:Clone()

					item.Name = Parameter.Name
					item.LayoutOrder = Order
					item.Header.header.label.Text = Parameter.Name
					item.Parent = custom_command.frame.content.scroll

					item.Header.Edit.MouseButton1Click:Connect(function()
						local Selects = module.ParameterEnum(true, Parameter.Items, 
							Parameter.SelectionRange, Parameter.Name, item.Frame)

						if not Selects then return end

						local Collection = module.GetEnumItems(Selects)

						for i, dump in pairs(item.Frame.Container:GetChildren()) do
							if dump:IsA("ImageButton") then
								dump:Destroy()
							end
						end

						for i, Button in pairs(Collection) do
							Button.BackgroundTransparency = 1
							Button.Interactable = false

							Button.stroke:Destroy()

							Button.Parent = item.Frame.Container
						end

						CustomCommandData.Properties[Parameter.Name] = Selects
					end)

				elseif Parameter.ParamType == "Slider" then
					local item = custom_command.frame.content.scroll.list.SliderParam:Clone()

					item.Name = Parameter.Name
					item.LayoutOrder = Order
					item.Header.header.label.Text = Parameter.Name
					item.Parent = custom_command.frame.content.scroll

					item.Frame.Details.Min.Text = Parameter.SliderRange.Min
					item.Frame.Details.Max.Text = Parameter.SliderRange.Max

					item.Header.value.label.Text = "Value: " .. Parameter.SliderDefault

					local SliderData = Slider.new(item.Frame.Slider, {
						AllowBackgroundClick = false,
						SliderData = {
							Start = Parameter.SliderRange.Min,
							End = Parameter.SliderRange.Max,
							DefaultValue = Parameter.SliderDefault,
							Increment = Parameter.SliderIncrement
						},
						Axis = "X",
						MoveInfo = info,
						Padding = 0
					})

					CustomCommandData.Properties[Parameter.Name] = Parameter.SliderDefault

					SliderData.Dragged:Connect(function()
						tween_service:Create(item.Frame.Slider.Slider.scale, info, {Scale = 1.4}):Play()
						tween_service:Create(item.Frame.Slider.Slider.shadow, info, {ImageTransparency = 0}):Play()
						tween_service:Create(item.Frame.Slider.Slider.handle, info, {ImageTransparency = .8}):Play()
					end)

					SliderData.Released:Connect(function()
						tween_service:Create(item.Frame.Slider.Slider.scale, info, {Scale = 1}):Play()
						tween_service:Create(item.Frame.Slider.Slider.shadow, info, {ImageTransparency = .8}):Play()
						tween_service:Create(item.Frame.Slider.Slider.handle, info, {ImageTransparency = 1}):Play()
					end)

					SliderData.Changed:Connect(function(value)
						CustomCommandData.Properties[Parameter.Name] = value
						item.Header.value.label.Text = "Value: " .. value
					end)

					SliderData:Track()

				elseif Parameter.ParamType == "Boolean" then
					local item = custom_command.frame.content.scroll.list.BooleanParam:Clone()

					item.Name = Parameter.Name
					item.LayoutOrder = Order
					item.Frame.label.Text = Parameter.Name
					item.Parent = custom_command.frame.content.scroll

					local CurrentValue = Parameter.StartingValue

					CustomCommandData.Properties[Parameter.Name] = Parameter.StartingValue

					if CurrentValue then
						tween_service:Create(item.Frame.state.check, info, {ImageTransparency = 0}):Play()
						tween_service:Create(item.Frame.state.check.scale, info, {Scale = 1}):Play()
					else
						tween_service:Create(item.Frame.state.check, info, {ImageTransparency = 1}):Play()
						tween_service:Create(item.Frame.state.check.scale, info, {Scale = .5}):Play()
					end

					item.Frame.MouseButton1Click:Connect(function()
						if CurrentValue then
							CurrentValue = false

							tween_service:Create(item.Frame.state.check, info, {ImageTransparency = 1}):Play()
							tween_service:Create(item.Frame.state.check.scale, info, {Scale = .5}):Play()
						else
							CurrentValue = true

							tween_service:Create(item.Frame.state.check, info, {ImageTransparency = 0}):Play()
							tween_service:Create(item.Frame.state.check.scale, info, {Scale = 1}):Play()
						end

						CustomCommandData.Properties[Parameter.Name] = CurrentValue
					end)

				elseif Parameter.ParamType == "Textbox" then
					local item = custom_command.frame.content.scroll.list.TextboxParam:Clone()

					item.Name = Parameter.Name
					item.LayoutOrder = Order
					item.Header.header.label.Text = Parameter.Name
					item.Parent = custom_command.frame.content.scroll

					item.textbox.Text = Parameter.StartingText

					item.textbox.FocusLost:Connect(function()
						CustomCommandData.Properties[Parameter.Name] = item.textbox.Text
					end)

					CustomCommandData.Properties[Parameter.Name] = Parameter.StartingText
				end
			end
		end

		--

		tween_service:Create(custom_command.frame.content, info, {GroupTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(custom_command, true)
	else
		if not custom_command.Visible then return end

		Leaflet:Deactivate(custom_command)

		tween_service:Create(custom_command, info, {Position = UDim2.new(0, custom_command.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(custom_command.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		custom_command.Visible = false

		events.ui.ModalToggled:Fire(custom_command, false)
	end
end

function module.ExecuteCustomCommand()
	if CustomCommandData.Event then
		module.TrackProgress(true, "Executing " .. CustomCommandData.Name, custom_command.frame.content.bottom.Execute)

		--

		if CustomCommandData.Event then
			if CustomCommandData.Event:IsA("RemoteEvent") then
				CustomCommandData.Event:FireServer(CustomCommandData.Properties)

			elseif CustomCommandData.Event:IsA("RemoteFunction") then
				CustomCommandData.Event:InvokeServer(CustomCommandData.Properties)

			elseif CustomCommandData.Event:IsA("BindableEvent") then
				CustomCommandData.Event:Fire(CustomCommandData.Properties)

			elseif CustomCommandData.Event:IsA("BindableFunction") then
				CustomCommandData.Event:Invoke(CustomCommandData.Properties)
			end
		end

		--

		if not input_service:IsKeyDown(Enum.KeyCode.LeftShift) then
			module.PromptCustomCommand(false)
		end

		--

		module.TrackProgress(false)
	else
		Alerts.BannerNotify({
			Header = "Custom Command Event Missing",
			Description = CustomCommandData.Name .. "'s Event is missing.",
			Icon = "rbxassetid://12974384407"
		})
	end
end

custom_command.frame.content.bottom.Execute.Button.MouseButton1Click:Connect(function()
	module.ExecuteCustomCommand()
end)

function module.Preview(state, id, Source)
	if state then
		if preview.Visible then

		end

		preview.Visible = true
		preview.Interactable = true

		preview.frame.content.canvas.Preview.Image = id
		preview.frame.content.canvas.Preview.ImageTransparency = 1

		-- Source Calculation
		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(preview)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(preview)
		Leaflet:CaptureFocus(preview)

		if Source then
			local Transforms = Utilities.TransformToSource(Source, preview)

			preview.Position = Transforms.Position
			preview.Size = Transforms.Size

			preview.scale.Scale = .6
		else
			preview.Position = UDim2.fromScale(.5, 1.5)
			preview.Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)
		end

		-- Show

		tween_service:Create(preview, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
		tween_service:Create(preview, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
		tween_service:Create(preview.scale, info, {Scale = 1}):Play()

		tween_service:Create(preview.frame.content.canvas.Preview, info, {ImageTransparency = 0}):Play()

		--

		events.ui.ModalToggled:Fire(preview, true)
	else
		if not preview.Visible then return end

		Leaflet:Deactivate(preview)

		tween_service:Create(preview, info, {Position = UDim2.new(0, preview.Position.X.Offset, 1.5, 0)}):Play()
		tween_service:Create(preview.frame.content, info, {GroupTransparency = 1}):Play()

		--
		task.wait(.5)
		--

		preview.Visible = false

		events.ui.ModalToggled:Fire(preview, false)
	end
end

--// CONTEXT MENU

export type Exe6ContextMenuInfo = {
	Header: any,
	Options: any,
	Mobile: any,
}

function PositionContextMenu()
	local SizeRef = context_menu.SizeReference
	local Menu = context_menu.Frame

	local mouse = input_service:GetMouseLocation()
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

	tween_service:Create(Menu, info, {Position = UDim2.fromOffset(rawX - 30, rawY - 30)}):Play()
	tween_service:Create(Menu, info, {ImageTransparency = 0}):Play()
	tween_service:Create(Menu, info_2, {Size = UDim2.fromOffset(finalSize.X, finalSize.Y)}):Play()

	tween_service:Create(Menu.Content.padding, quick, {PaddingTop = UDim.new(0, 10)}):Play()
	tween_service:Create(Menu.Content.list, info, {Padding = UDim.new(0, 5)}):Play()
end


local CONTEXTING = false

function module.PromptOptions(data: Exe6ContextMenuInfo)
	if CONTEXTING then return end
	CONTEXTING = true

	-- Clearance

	for i, dump in pairs(context_menu.Frame.Content:GetChildren()) do
		if dump:HasTag("Exe6ContextMenuOption") then
			dump:Destroy()
		end

		if dump.Name == "Separator" then
			dump:Destroy()
		end
	end

	for i, dump in pairs(context_menu.Frame.Content.Primary:GetChildren()) do
		if dump:HasTag("Exe6ContextMenuOption") then
			dump:Destroy()
		end
	end

	for i, dump in pairs(context_menu.SizeReference.Content:GetChildren()) do
		if dump:HasTag("Exe6ContextMenuOption") then
			dump:Destroy()
		end

		if dump.Name == "Separator" then
			dump:Destroy()
		end
	end

	for i, dump in pairs(context_menu.SizeReference.Content.Primary:GetChildren()) do
		if dump:HasTag("Exe6ContextMenuOption") then
			dump:Destroy()
		end
	end

	-- Synthesizing

	local ActionChosen = ""
	local ContextProceeded = false
	local ContextCancelled = false

	for _, entry in ipairs(data.Options) do
		if entry == "SEPARATOR" then
			local SizeRefItem = context_menu.SizeReference.Content.list.Separator:Clone()
			SizeRefItem.Parent = context_menu.SizeReference.Content 

			local item = context_menu.Frame.Content.list.Separator:Clone()
			item.Parent = context_menu.Frame.Content

		elseif typeof(entry) == "table" and entry.Name and entry.Icon then
			local item
			local SizeRefItem

			if entry.Primary then
				SizeRefItem = context_menu.SizeReference.Content.list.PrimaryAction:Clone()
				SizeRefItem.Parent = context_menu.SizeReference.Content.Primary

				item = context_menu.Frame.Content.list.PrimaryAction:Clone()
				item.Parent = context_menu.Frame.Content.Primary
			else
				SizeRefItem = context_menu.SizeReference.Content.list.Action:Clone()
				SizeRefItem.Parent = context_menu.SizeReference.Content

				item = context_menu.Frame.Content.list.Action:Clone()
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
				ui.storage.tap:Play()

				Utilities.Haptic(.8, .001)

				--

				if data.Mobile then
					tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(34, 34, 34)}):Play()
				end
			end)

			item.MouseLeave:Connect(function()
				if data.Mobile then
					tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(27, 27, 27)}):Play()
				end
			end)

			item.MouseButton1Up:Connect(function(input)
				if data.Mobile then
					ui.storage.tap:Play()

					ActionChosen = entry.Name
					ContextProceeded = true

					tween_service:Create(item, info, {BackgroundColor3 = Color3.fromRGB(27, 27, 27)}):Play()
				end
			end)
		end
	end

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
		tween_service:Create(context_menu, info, {BackgroundTransparency = .5}):Play()
	end


	context_menu.SizeReference.Content.Primary.Visible = (#context_menu.SizeReference.Content.Primary:GetChildren() - 1) > 0
	context_menu.Frame.Content.Primary.Visible = (#context_menu.Frame.Content.Primary:GetChildren() - 1) > 0

	-- Load

	context_menu.Visible = true

	PositionContextMenu()

	-- Yielding Method

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

	context_menu.Visible = false
	context_menu.Frame.Visible = false

	CONTEXTING = false

	if data.Mobile then
		context_menu.Active = false
		tween_service:Create(context_menu, info, {BackgroundTransparency = 1}):Play()
	end

	if ContextProceeded then
		return ActionChosen
	end

	if ContextCancelled then
		return nil
	end
end

return module