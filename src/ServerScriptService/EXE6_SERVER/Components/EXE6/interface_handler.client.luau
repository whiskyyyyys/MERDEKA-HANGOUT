local tween_service = game:GetService("TweenService")
local input_service = game:GetService("UserInputService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local run_service = game:GetService("RunService")
local collection_service = game:GetService("CollectionService")
local textchat_service = game:GetService("TextChatService")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local smooth = TweenInfo.new(1, Enum.EasingStyle.Exponential)
local quick = TweenInfo.new(.3, Enum.EasingStyle.Exponential)

local back = TweenInfo.new(.5, Enum.EasingStyle.Back)

local client = players.LocalPlayer

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local events = storage.events

local MainModule = require(storage.modules.MainModule) 
local Configuration = require(storage.modules.Configuration)
local Utilities = require(storage.modules.Utilities)
local Alerts = require(storage.modules.Alerts)

local ui = script.Parent
local main_frame = ui.main_frame
local announcement = ui.announcement

local cam = workspace.CurrentCamera
local viewport = cam.ViewportSize

function ApplyAccentColor()
	for i, elements in pairs(ui:GetDescendants()) do
		if elements:HasTag("Exe6PrimaryThemeImageColor3") then
			elements.ImageColor3 = Configuration.Interface.Theme
		end

		if elements:HasTag("Exe6PrimaryThemeTextColor3") then
			elements.TextColor3 = Configuration.Interface.Theme
		end


		if elements:HasTag("Exe6SecondaryThemeImageColor3") then
			elements.ImageColor3 = Utilities.AdjustColor(Configuration.Interface.Theme)
		end

		if elements:HasTag("Exe6SecondaryThemeTextColor3") then
			elements.TextColor3 = Utilities.AdjustColor(Configuration.Interface.Theme)
		end

		if elements:HasTag("Exe6PrimaryThemeBackgroundColor3") then
			elements.BackgroundColor3 = Configuration.Interface.Theme
		end

		if elements:HasTag("Exe6PrimarySpeculars") then
			local Specular = Utilities.GetSpecularHighlightsAndShadows(Configuration.Interface.Theme, 1.4, .3)
			local Keypoints = {
				ColorSequenceKeypoint.new(0, Specular.Highlight),
				ColorSequenceKeypoint.new(.5, Specular.Shadows),
				ColorSequenceKeypoint.new(1, Specular.Highlight)
			}

			elements.Color = ColorSequence.new(Keypoints)
		end
	end
end

ApplyAccentColor()

-- ACCESS

input_service.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Configuration.Interface.AccessKey and not processed then
		MainModule.Exe6(not ui.main_frame.Visible, not input_service:IsKeyDown(Enum.KeyCode.LeftShift))
	end
end)

-- TOPBAR

function InitiateTopbar()
	if not Configuration.Interface.Enabled then return end
	
	local IntegratedTopbar = storage.modules.Icon
	local Topbar
	
	for i, TopbarModule in replicated_storage:GetDescendants() do
		if TopbarModule:IsA("ModuleScript") and TopbarModule.Name == "Icon" and TopbarModule:HasTag("Icon") then
			if TopbarModule:FindFirstChild("VERSION") then
				Topbar = require(TopbarModule)
				IntegratedTopbar:Destroy()
				break
			end
		end
	end
	
	if not Topbar then
		Topbar = require(storage.modules.Icon)
	end
	
	local exe_icon = Topbar.new()

	Topbar.setDisplayOrder(9999)

	if Configuration.Interface.Label ~= "" then
		exe_icon:setLabel(Configuration.Interface.Label)
		exe_icon:setCaption(Configuration.Interface.Label)
	end

	if Configuration.Interface.Icon ~= "" then
		exe_icon:setImage(Configuration.Interface.Icon)
	end

	exe_icon:modifyTheme({
		{"IconButton", "BackgroundColor3", Configuration.Interface.BgColor},

		{"IconImage", "ImageColor3", Configuration.Interface.ContentColor},
		{"IconLabel", "TextColor3", Configuration.Interface.ContentColor},
	})

	exe_icon:align(Configuration.Interface.Alignment)
	exe_icon:setCaptionHint(Configuration.Interface.AccessKey)

	exe_icon:setTextFont("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	exe_icon:oneClick(true)

	exe_icon.selected:Connect(function()
		MainModule.Exe6(not ui.main_frame.Visible, not input_service:IsKeyDown(Enum.KeyCode.LeftShift))
	end)
end

InitiateTopbar()

-- CHAT COMMAND ACCESS

function InitiateCommandAccess()
	if not Configuration.Interface.ChatCommandAccess then return end

	local Command = textchat_service:FindFirstChild("Exe6textChatCommand")
	
	if not Command then
		Command = Instance.new("TextChatCommand")
	end

	Command.Enabled = true
	Command.Name = "Exe6TextChatCommand"
	Command.PrimaryAlias = "/exe"
	Command.SecondaryAlias = "/exe6"
	Command.Parent = game:GetService("TextChatService")
	
	Command:AddTag("Exe6")

	Command.Triggered:Connect(function()
		MainModule.Exe6(not ui.main_frame.Visible)
	end)
end

InitiateCommandAccess()

-- LEAFLET CONTROLS

local last_pos = UDim2.fromScale(.5, .5)
local last_size = UDim2.new(.4, 500, .3, 300)

function Fullscreen(state, transform, delete_cache)
	MainModule.SetFullscreen(state)

	if state then
		if not delete_cache then
			last_pos = main_frame.Position
			last_size = main_frame.Size
		end

		if transform then
			tween_service:Create(main_frame, quick, {Position = UDim2.fromScale(.5, .5)}):Play()
			tween_service:Create(main_frame, info, {Size = UDim2.fromScale(1, 1)}):Play()
		end
	else
		if transform then
			tween_service:Create(main_frame, info, {Position = last_pos}):Play()
			tween_service:Create(main_frame, quick, {Size = last_size}):Play()
		end
	end
end

function WindowControlFrame(state)
	local Actions = main_frame.content.LeafletControls.Top.Actions

	Actions:SetAttribute("Collapsed", not state)

	if state then
		Actions.Frame.Container.Interactable = true

		tween_service:Create(Actions.Frame, info, {ImageTransparency = 0}):Play()
		tween_service:Create(Actions.Frame.scale, info, {Scale = 1}):Play()

		tween_service:Create(Actions.Frame.Container.close.container.icon, info, {ImageTransparency = 0}):Play()
		tween_service:Create(Actions.Frame.Container.fullscreen.container.icon, info, {ImageTransparency = 0}):Play()
		tween_service:Create(Actions.Frame.Container.menu.container.icon, info, {ImageTransparency = 0}):Play()
		tween_service:Create(Actions.Frame.Container.restore.container.icon, info, {ImageTransparency = 0}):Play()

		Utilities.Haptic(.2, .05)
	else

		Actions.Frame.Container.Interactable = false

		tween_service:Create(Actions.Frame, info, {ImageTransparency = 1}):Play()
		tween_service:Create(Actions.Frame.scale, info, {Scale = .8}):Play()

		tween_service:Create(Actions.Frame.Container.close.container.icon, info, {ImageTransparency = .5}):Play()
		tween_service:Create(Actions.Frame.Container.fullscreen.container.icon, info, {ImageTransparency = .5}):Play()
		tween_service:Create(Actions.Frame.Container.menu.container.icon, info, {ImageTransparency = .5}):Play()
		tween_service:Create(Actions.Frame.Container.restore.container.icon, info, {ImageTransparency = .5}):Play()
	end
end

main_frame.content.LeafletControls.Top.MouseEnter:Connect(function()
	WindowControlFrame(true)
end)

main_frame.content.LeafletControls.Top.Actions.Frame.MouseButton1Click:Connect(function()
	WindowControlFrame(true)
end)

main_frame.content.LeafletControls.Space.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2
		or input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseWheel then

		if not main_frame.content.LeafletControls.Top.Actions:GetAttribute("Collapsed") then
			WindowControlFrame(false)
		end
	end
end)

main_frame.content.LeafletControls.Top.Actions.Frame.Container.fullscreen.MouseButton1Click:Connect(function()
	Fullscreen(true, true)
end)

main_frame.content.LeafletControls.Top.Actions.Frame.Container.restore.MouseButton1Click:Connect(function()
	Fullscreen(false, true)
end)

main_frame.content.LeafletControls.Top.Actions.Frame.Container.close.MouseButton1Click:Connect(function()
	MainModule.Exe6(false, not input_service:IsKeyDown(Enum.KeyCode.LeftShift))
	WindowControlFrame(false)
end)

main_frame.content.LeafletControls.Top.Actions.Frame.Container.menu.MouseButton1Click:Connect(function()
	MainModule.NavigationMenu(not main_frame:GetAttribute("NavigationMenu"))
end)

--

events.ui.ExeToggled.Event:Connect(function(state)
	if state then
		if main_frame:GetAttribute("Fullscreen") then
			tween_service:Create(main_frame.content.LeafletControls.Top, info, {Position = UDim2.fromOffset(0, 50)}):Play()
			tween_service:Create(main_frame.content.navigation.padding, info, {PaddingTop = UDim.new(0, 50)}):Play()
		else
			tween_service:Create(main_frame.content.LeafletControls.Top, info, {Position = UDim2.fromOffset(0, 0)}):Play()
			tween_service:Create(main_frame.content.navigation.padding, info, {PaddingTop = UDim.new(0, 0)}):Play()
		end
	end
end)

events.ui.ExeInterfaceLoaded.OnClientEvent:Connect(function()
	if Configuration.System.AuthorizationNotification then
		Alerts.BannerNotify({
			Header = "You are authorized to use Exe 6.",
			Description = "Connect with your team in Exe 6 by pressing " .. Configuration.Interface.AccessKey.Name,
			Icon = "rbxassetid://11963376159",
			Involved = Utilities.GetUserIdsOfTeamInServer()
		})
	end
end)

events.ui.AlertsModuleEvent.OnClientEvent:Connect(function(func, data)
	Alerts[func](data)
end)

events.Activities.Announcement.OnClientEvent:Connect(function(audience, data)
	if not table.find(audience, players.LocalPlayer.UserId) then return end

	Alerts.PromptAnnounce(data)
end)

announcement.frame.content.Actions.user.MouseButton1Click:Connect(function()
	if announcement:GetAttribute("Host") then
		MainModule.Profile(true, announcement:GetAttribute("Host"))
	end
end)

for i, actions in pairs(main_frame.content.LeafletControls.Top.Actions.Frame.Container:GetChildren()) do
	if actions:IsA("ImageButton") then

		actions.MouseEnter:Connect(function()
			tween_service:Create(actions.container, quick, {ImageColor3 = Color3.fromRGB(34, 34, 34)}):Play()
			tween_service:Create(actions.container.icon.scale, quick, {Scale = 1.2}):Play()
		end)

		actions.MouseButton1Down:Connect(function()
			tween_service:Create(actions.container, quick, {ImageColor3 = Color3.fromRGB(20, 20, 20)}):Play()
			tween_service:Create(actions.container.icon.scale, quick, {Scale = .6}):Play()
		end)

		actions.InputEnded:Connect(function()
			tween_service:Create(actions.container, quick, {ImageColor3 = Color3.fromRGB(44, 44, 44)}):Play()
			tween_service:Create(actions.container.icon.scale, quick, {Scale = 1}):Play()
		end)

		actions.MouseButton1Click:Connect(function()
			ui.storage.click:Play()
		end)

	end
end

-- RESIZE HANDLES

function NormalizedCursorPosition(button)
	local mouseLocation = input_service:GetMouseLocation()
	local guiInset = game:GetService("GuiService"):GetGuiInset().Y

	local buttonPosition = button.AbsolutePosition
	local buttonSize = button.AbsoluteSize

	local correctedMouseY = mouseLocation.Y - guiInset

	local relativeX = (mouseLocation.X - buttonPosition.X) / buttonSize.X
	local relativeY = (correctedMouseY - buttonPosition.Y) / buttonSize.Y

	local finalX = 1 - math.clamp(relativeX, 0, 1)
	local finalY = 1 - math.clamp(relativeY, 0, 1)

	return Vector2.new(finalX, finalY)
end

local ResizeHandles = collection_service:GetTagged("Exe6ResizeHandle")

for i, button in pairs(ResizeHandles) do
	if button:IsA("ImageButton") then

		button.InputChanged:Connect(function(input)
			local normals = NormalizedCursorPosition(button)

			tween_service:Create(button.icon, info, {
				Size = UDim2.fromOffset(20 + (normals.X * 30), 20 + (normals.Y * 30))}):Play()
		end)

		button.InputEnded:Connect(function()
			tween_service:Create(button.icon, info, {Size = UDim2.fromOffset(18, 18)}):Play()
		end)

	end
end

-- SPECTATE

local processing_tweeninfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local pulsating_tweeninfo = TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1)

tween_service:Create(ui.spectate.frame.menu.frame.indicator.badge.scale, processing_tweeninfo, 
	{Scale = 1}):Play()

tween_service:Create(ui.spectate.frame.menu.frame.indicator.pulse, pulsating_tweeninfo, 
	{ImageTransparency = 1}):Play()
tween_service:Create(ui.spectate.frame.menu.frame.indicator.pulse.scale, pulsating_tweeninfo, 
	{Scale = 2.8}):Play()

-- Dynamic Strokes

local cam = workspace.CurrentCamera
local CurrentRotation = 0

function CalculateShortestRotation(from, to)
	local diff = (to - from + 540) % 360 - 180

	return from + diff
end

function UpdateDynamicSpeculars()
	if not Configuration.Interface.DynamicSpecularEffect then return end

	local look = cam.CFrame.LookVector
	local yaw = math.deg(math.atan2(-look.X, -look.Z)) % 360

	local targetRotation = CalculateShortestRotation(CurrentRotation, yaw)
	CurrentRotation = targetRotation % 360

	for _, gradient in ipairs(collection_service:GetTagged("Exe6DynamicSpeculars")) do
		gradient.Rotation = CurrentRotation
	end
end

function GetRotation()
	local look = cam.CFrame.LookVector
	local yaw = math.deg(math.atan2(-look.X, -look.Z)) % 360

	local targetRotation = CalculateShortestRotation(CurrentRotation, yaw)
	CurrentRotation = targetRotation % 360

	return CurrentRotation
end

run_service.RenderStepped:Connect(function()
	UpdateDynamicSpeculars()
	
	if ui.modal_frame.fly.Visible then
		ui.modal_frame.fly.frame.content.Orientation.Rotation = GetRotation() or 0
	else
		tween_service:Create(ui.modal_frame.fly.frame.content.Orientation, info, {Rotation = 0}):Play()
	end
end)

-- STICKY EFFECT

local TAG = "Exe6StickyEffect"
local tween_info = TweenInfo.new(1, Enum.EasingStyle.Exponential)

function DistanceFromMiddle(offset: Vector2)
	local maxOffset = math.max(math.abs(offset.X), math.abs(offset.Y))
	local closeness = math.clamp(maxOffset, 0, 1)
	return closeness
end

function StickyEffect(frame)
	local originalPos = frame.Position
	local tween
	local offsetAmount = frame:GetAttribute("Offset") or 15

	local function OnHover(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end

		local guiInset = game:GetService("GuiService"):GetGuiInset()
		local mousePos = input_service:GetMouseLocation() - guiInset

		local size = frame.AbsoluteSize
		local anchor = frame.AnchorPoint
		local center = frame.AbsolutePosition + size * anchor

		local diff = (mousePos - center) / size * 2
		local offset = Vector2.new(diff.X * offsetAmount, diff.Y * offsetAmount)

		local targetPos = originalPos + UDim2.fromOffset(offset.X, offset.Y)

		if tween then tween:Cancel() end
		tween = tween_service:Create(frame, tween_info, {Position = targetPos})
		tween:Play()
	end

	frame.MouseEnter:Connect(function()
		frame.InputChanged:Connect(OnHover)

		ui.storage.tap:Play()
	end)

	frame.MouseLeave:Connect(function()
		if tween then tween:Cancel() end
		tween = tween_service:Create(frame, tween_info, {Position = originalPos})
		tween:Play()
	end)
end

for _, frame in collection_service:GetTagged(TAG) do
	StickyEffect(frame)
end

-- LEAFLET TOP CONTROLS

local LeafletControls = collection_service:GetTagged("Exe6LeafletTopControls")

for i, v in pairs(LeafletControls) do
	if v:IsA("ImageLabel") then

		v.MouseEnter:Connect(function()
			tween_service:Create(v, info, {ImageTransparency = 0}):Play()
		end)

		v.InputEnded:Connect(function()
			tween_service:Create(v, info, {ImageTransparency = 1}):Play()
		end)

	end
end

-- BULK ACTIONS

local BulkActions = collection_service:GetTagged("Exe6BulkAction")

for i, v in pairs(BulkActions) do
	if v:IsA("ImageButton") then

		v.MouseEnter:Connect(function()
			tween_service:Create(v, info, {ImageTransparency = .9}):Play()
			tween_service:Create(v.icon.scale, info, {Scale = 1.2}):Play()
		end)
		
		v.MouseButton1Down:Connect(function()
			tween_service:Create(v, info, {ImageTransparency = .95}):Play()
			tween_service:Create(v.icon.scale, info, {Scale = .6}):Play()
		end)
		
		v.InputEnded:Connect(function()
			tween_service:Create(v, info, {ImageTransparency = 1}):Play()
			tween_service:Create(v.icon.scale, info, {Scale = 1}):Play()
		end)

	end
end