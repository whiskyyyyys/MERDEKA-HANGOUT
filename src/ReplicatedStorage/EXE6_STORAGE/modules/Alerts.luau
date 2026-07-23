local run_service = game:GetService("RunService")
local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local quick = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local smooth = TweenInfo.new(1, Enum.EasingStyle.Exponential)

local bounce = TweenInfo.new(1, Enum.EasingStyle.Back)
local reverse = TweenInfo.new(.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, true)

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local events = storage.events

local Utilities = require(storage.modules.Utilities)
local Configuration = require(storage.modules.Configuration)
local Leaflet = require(storage.modules.Leaflet)

local module = {}
local PreviousNotificationProperties = {Header = "", Description = ""}

local NotificationHistory = {}

export type BannerNotificationData = {
	Icon: any;
	Header: any;
	Description: any;
	Involved: any;
	Duration: any;
	Pin: any;
	Host: any;
}

function module.BannerNotify(data: BannerNotificationData)
	if run_service:IsClient() then
		local hovering = false
		local onDelete = false 
		local onStacked = false

		local client = players.LocalPlayer
		local ui = client.PlayerGui:WaitForChild("EXE6")
		local container = ui:FindFirstChild("notification")
		local notif = container.list.notification:Clone()

		notif.banner.AnchorPoint = Vector2.new(.5, 1)

		notif:SetAttribute("Header", data.Header or "Header")
		notif:SetAttribute("Description", data.Description or "Description")

		notif.Name = Utilities.ShuffleString(notif:GetAttribute("Header"))

		notif.Parent = container

		if Configuration.Notifications.NotificationHistory then
			table.insert(NotificationHistory, data)
		end

		--

		if PreviousNotificationProperties.Header == notif:GetAttribute("Header") and 
			PreviousNotificationProperties.Description == notif:GetAttribute("Description") then

			for i, item in pairs(container:GetChildren()) do
				if item:IsA("Frame") and item:GetAttribute("Header") == notif:GetAttribute("Header") and 
					item:GetAttribute("Description") == notif:GetAttribute("Description") and 
					item.banner.AnchorPoint == Vector2.new(.5, 0) then

					onStacked = true

					if not item.extra.Visible then

						item.extra.Visible = true
						item.extra.Size = UDim2.fromOffset(item.banner.AbsoluteSize.X, item.banner.AbsoluteSize.Y)
						item.extra.Position = UDim2.new(.5, 0, 1, -20)
						item.extra.frame.ImageTransparency = 1

						--

						tween_service:Create(item.extra, info, {Position = UDim2.fromScale(.5, 1)}):Play()
						tween_service:Create(item.extra.frame, info, { ImageTransparency = 0 }):Play()

					end
				end
			end
		end

		PreviousNotificationProperties = {
			Header = notif:GetAttribute("Header"),
			Description = notif:GetAttribute("Description"),
		}

		--

		task.spawn(function()
			if not onStacked then
				if data.Icon then
					notif.banner.frame.container.icon.Image = data.Icon
				else
					notif.banner.frame.container.icon.Visible = false
					notif.banner.frame.space.Visible = false
				end

				if data.Header then
					notif.banner.frame.information.header.Text = data.Header
				else
					notif.banner.frame.information.header.Visible = false
				end

				if data.Description then
					notif.banner.frame.information.description.Text = data.Description or "Description"
				else
					notif.banner.frame.information.description.Visible = false
				end

				if data.Involved then
					for i, user in ipairs(data.Involved) do
						local banner = notif:FindFirstChild("banner")
						if not banner then break end

						local profile = notif.banner.frame.information.involved.list.player:Clone()

						profile.Image = Utilities.GetPlayerThumbnail(user)
						profile.ZIndex = -i
						profile.Parent = notif.banner.frame.information.involved
					end
				end
			end
		end)

		if onStacked then
			notif:Destroy()

			return
		end

		Utilities.Haptic(.5)

		--		

		notif.banner.MouseEnter:Connect(function()
			hovering = true

			tween_service:Create(notif.banner, info, {ImageTransparency = 0}):Play()
		end)

		notif.MouseLeave:Connect(function()
			hovering = false

			tween_service:Create(notif.banner, info, {ImageTransparency = .5}):Play()
		end)

		if data.Pin then
			notif.banner.frame.pinned.Visible = true

		else

			notif.banner.frame.MouseButton1Click:Connect(function()
				hovering = false
				onDelete = true

				notif.Interactable = false

				tween_service:Create(notif, info, {Size = UDim2.new(1, 0, 0, 30)}):Play()
				tween_service:Create(notif.banner, info, {ImageTransparency = 1, AnchorPoint = Vector2.new(.5, 1)}):Play()
				tween_service:Create(notif.extra.frame, info, { ImageTransparency = 1 }):Play()

				--
				task.wait(.5)
				--

				notif:Destroy()
			end)
		end

		--

		task.spawn(function()

			tween_service:Create(notif.banner, info, { AnchorPoint = Vector2.new(.5, 0) }):Play()

			--
			task.wait(data.Duration or 5)
			--

			repeat task.wait(data.Duration or 5) until not hovering or notif.banner.AnchorPoint == Vector2.new(.5, 1)

			if not onDelete then
				notif.Interactable = false

				tween_service:Create(notif, info, {Size = UDim2.new(1, 0, 0, 30)}):Play()
				tween_service:Create(notif.banner, info, {ImageTransparency = 1, AnchorPoint = Vector2.new(.5, 1)}):Play()
				tween_service:Create(notif.extra.frame, info, { ImageTransparency = 1 }):Play()

				--
				task.wait(.5)
				--

				notif:Destroy()
			end
		end)

	elseif run_service:IsServer() then
		if data.Host then
			events.ui.AlertsModuleEvent:FireClient(data.Host, "BannerNotify", data)
		else
			warn("No provided host for the thrown Banner Notification.")
		end
	end
end

function module:GetNotificationHistory()
	return NotificationHistory
end

export type AnnouncementData = {
	Icon: any;
	Header: any;
	Description: any;
	Duration: any;
	Host: number;
	Timestamp: any;
}

function module.PromptAnnounce(data: AnnouncementData)
	if run_service:IsClient() then
		local client = players.LocalPlayer
		local ui = client.PlayerGui:WaitForChild("EXE6")

		local frame = ui:FindFirstChild("announcement")

		local mod = Utilities.GetUserInfoByUserId(data.Host)
		local auth = events.auth.Auth:InvokeServer("IsAuthorized", data.Host)

		if not mod then return end

		--

		if Configuration.Announcements.NotifyWithSound then
			ui.storage.announcement:Play()
		end
		
		frame.Visible = true
		frame.Position = UDim2.fromScale(.5, 1.5)

		frame.frame.content.Visible = true
		frame.frame.content.GroupTransparency = 1

		frame.frame.content.scroll.CanvasPosition = Vector2.new(0, 0)

		frame.frame.content.Actions.duration.Canvas.GroupTransparency = 1
		frame.frame.content.Actions.duration.Canvas.scale.Scale = .8
		
		frame:SetAttribute("Host", data.Host)

		-- User Host

		frame.frame.content.Actions.user.profile.Image = Utilities.GetPlayerThumbnail(data.Host)
		frame.frame.content.Actions.user.display.Text = mod.DisplayName

		if auth then
			frame.frame.content.Actions.user.role.Visible = true
			frame.frame.content.Actions.user.role.Text = auth.Role.Alias
			frame.frame.content.Actions.user.role.BackgroundColor3 = auth.Role.Accent
			frame.frame.content.Actions.user.role.TextColor3 = Utilities.AdjustColor(auth.Role.Accent)
		else
			frame.frame.content.scroll.user.role.Visible = false
		end

		-- Information

		frame.frame.content.scroll.header.icon.Image = data.Icon
		frame.frame.content.scroll.description.Text = data.Description
		frame.frame.content.scroll.header.Text = data.Header

		--

		Utilities.Haptic(1, .8)
		Utilities.CircularProgress(frame.frame.content.Actions.duration.Canvas, data.Duration, true)

		--

		local ViewportMiddle = Utilities.GetHalfViewport()
		local LeafConfigs = Leaflet:GetLeafData(frame)
		local NormalizedSize = Leaflet:NormalizeLeafSize(LeafConfigs.BaseSize, LeafConfigs.MinSize, LeafConfigs.MaxSize)

		Leaflet:Activate(frame)
		Leaflet:CaptureFocus(frame)

		task.spawn(function()
			-- Show
			tween_service:Create(frame.frame.content.Actions.duration.Canvas, info, {GroupTransparency = 0}):Play()
			tween_service:Create(frame.frame.content.Actions.duration.Canvas.scale, info, {Scale = 1}):Play()

			tween_service:Create(frame, quick, {Position = UDim2.fromOffset(ViewportMiddle.X, ViewportMiddle.Y)}):Play()
			tween_service:Create(frame, info, {Size = UDim2.fromOffset(NormalizedSize.X, NormalizedSize.Y)}):Play()
			tween_service:Create(frame.scale, info, {Scale = 1}):Play()

			tween_service:Create(frame.frame.content, info, {GroupTransparency = 0}):Play()

			-- 
			task.wait(data.Duration)
			--

			-- Hide
			Leaflet:Deactivate(frame)

			tween_service:Create(frame.frame.content.Actions.duration.Canvas, info, {GroupTransparency = 1}):Play()
			tween_service:Create(frame.frame.content.Actions.duration.Canvas.scale, info, {Scale = .8}):Play()

			tween_service:Create(frame, info, {Position = UDim2.new(0, frame.Position.X.Offset, 1.5, 0)}):Play()
			tween_service:Create(frame.frame.content, info, {GroupTransparency = 1}):Play()

			--
			task.wait(.5)
			--

			frame.Visible = false
		end)
	end
end

return module