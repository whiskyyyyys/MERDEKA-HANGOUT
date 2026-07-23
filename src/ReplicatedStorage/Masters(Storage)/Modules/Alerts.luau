local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local normal = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local quick = TweenInfo.new(.3, Enum.EasingStyle.Exponential)
local smooth = TweenInfo.new(1, Enum.EasingStyle.Exponential)

local bounce = TweenInfo.new(1, Enum.EasingStyle.Back)
local reverse = TweenInfo.new(.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, true)

local storage = ReplicatedStorage:WaitForChild("Masters(Storage)")
local events = storage.Events

local Utilities = require(storage.Modules.Utilities)

local module = {}
local PreviousNotificationProperties = {Header = "", Description = ""}

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
	if RunService:IsClient() then
		local hovering = false
		local onDelete = false 
		local onStacked = false

		local client = Players.LocalPlayer
		local ui = client.PlayerGui:WaitForChild("Masters")
		local Container = ui:FindFirstChild("Notifications")
		local notif = Container.list.Item:Clone()

		notif.Banner.AnchorPoint = Vector2.new(.5, 1)

		notif:SetAttribute("Header", data.Header or "Header")
		notif:SetAttribute("Description", data.Description or "Description")

		notif.Name = Utilities.ShuffleString(notif:GetAttribute("Header"))

		notif.Parent = Container

		--

		if PreviousNotificationProperties.Header == notif:GetAttribute("Header") and 
			PreviousNotificationProperties.Description == notif:GetAttribute("Description") then

			for i, item in pairs(Container:GetChildren()) do
				if item:IsA("Frame") and item:GetAttribute("Header") == notif:GetAttribute("Header") and 
					item:GetAttribute("Description") == notif:GetAttribute("Description") and 
					item.Banner.AnchorPoint == Vector2.new(.5, 0) then

					onStacked = true

					if not item.Stack.Visible then

						item.Stack.Visible = true
						item.Stack.Size = UDim2.fromOffset(item.Banner.AbsoluteSize.X, item.Banner.AbsoluteSize.Y)
						item.Stack.Position = UDim2.new(.5, 0, 1, -20)
						item.Stack.Frame.ImageTransparency = 1

						--

						TweenService:Create(item.Stack, normal, {Position = UDim2.fromScale(.5, 1)}):Play()
						TweenService:Create(item.Stack.Frame, normal, { ImageTransparency = 0 }):Play()

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
					notif.Banner.Frame.Util.Icon.Image = data.Icon
				else
					notif.Banner.Frame.Util.Icon.Visible = false
					notif.Banner.Frame.space.Visible = false
				end

				if data.Header then
					notif.Banner.Frame.Info.Header.Text = data.Header
				else
					notif.Banner.Frame.Info.Header.Visible = false
				end

				if data.Description then
					notif.Banner.Frame.Info.Description.Text = data.Description or "Description"
				else
					notif.Banner.Frame.Info.Description.Visible = false
				end

				if data.Involved then
					for i, user in ipairs(data.Involved) do
						local Banner = notif:FindFirstChild("Banner")
						if not Banner then break end

						local profile = notif.Banner.Frame.Info.Involved.list.player:Clone()

						profile.Image = Utilities.GetPlayerThumbnail(user)
						profile.ZIndex = -i
						profile.Parent = notif.Banner.Frame.Info.involved
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

		notif.Banner.MouseEnter:Connect(function()
			hovering = true

			TweenService:Create(notif.Banner, normal, {ImageTransparency = 0}):Play()
		end)

		notif.MouseLeave:Connect(function()
			hovering = false

			TweenService:Create(notif.Banner, normal, {ImageTransparency = .5}):Play()
		end)

		if data.Pin then
			notif.Banner.Frame.pinned.Visible = true

		else

			notif.Banner.Frame.MouseButton1Click:Connect(function()
				hovering = false
				onDelete = true

				notif.Interactable = false

				TweenService:Create(notif, normal, {Size = UDim2.new(1, 0, 0, 30)}):Play()
				TweenService:Create(notif.Banner, normal, {ImageTransparency = 1, AnchorPoint = Vector2.new(.5, 1)}):Play()
				TweenService:Create(notif.Stack.Frame, normal, { ImageTransparency = 1 }):Play()

				--
				task.wait(.5)
				--

				notif:Destroy()
			end)
		end

		--

		task.spawn(function()

			TweenService:Create(notif.Banner, normal, {AnchorPoint = Vector2.new(.5, 0)}):Play()

			--
			task.wait(data.Duration or 5)
			--

			repeat task.wait(data.Duration or 5) until not hovering or notif.Banner.AnchorPoint == Vector2.new(.5, 1)

			if not onDelete then
				notif.Interactable = false

				TweenService:Create(notif, normal, {Size = UDim2.new(1, 0, 0, 30)}):Play()
				TweenService:Create(notif.Banner, normal, {ImageTransparency = 1, AnchorPoint = Vector2.new(.5, 1)}):Play()
				TweenService:Create(notif.Stack.Frame, normal, { ImageTransparency = 1 }):Play()

				--
				task.wait(.5)
				--

				notif:Destroy()
			end
		end)

	elseif RunService:IsServer() then
		if data.Host then
			events.ui.Alerts:FireClient(data.Host, "BannerNotify", data)
		else
			warn("No provided host for the thrown Banner Notification.")
		end
	end
end

return module