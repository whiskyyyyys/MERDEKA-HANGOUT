-- 🕺 Sync Status Notification (Fully compatible with your SyncStatus RemoteEvent)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local syncStatusEvent = ReplicatedStorage:WaitForChild("SyncStatus")

-- GUI setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SyncStatusGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Container frame
local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.Position = UDim2.new(0.5, 0, -0.15, 0) -- hidden above screen
frame.Size = UDim2.new(0, 280, 0, 48)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 1
frame.Visible = false
frame.AutomaticSize = Enum.AutomaticSize.Y
frame.Parent = screenGui

-- UI Corner
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Padding
local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 6)
padding.PaddingBottom = UDim.new(0, 6)
padding.PaddingLeft = UDim.new(0, 10)
padding.PaddingRight = UDim.new(0, 10)
padding.Parent = frame

-- Layout
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Vertical
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.Padding = UDim.new(0, 3)
layout.Parent = frame

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 16)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(200, 200, 200)
title.TextSize = 13
title.Font = Enum.Font.GothamSemibold
title.Text = "Dance System"
title.TextTransparency = 1
title.LayoutOrder = 1
title.Parent = frame

-- Main message
local textLabel = Instance.new("TextLabel")
textLabel.Size = UDim2.new(1, 0, 0, 20)
textLabel.BackgroundTransparency = 1
textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
textLabel.TextStrokeTransparency = 0.8
textLabel.Font = Enum.Font.GothamBold
textLabel.Text = ""
textLabel.TextSize = 16
textLabel.TextTransparency = 1
textLabel.TextWrapped = true
textLabel.AutomaticSize = Enum.AutomaticSize.Y
textLabel.LayoutOrder = 2
textLabel.Parent = frame

-- Tween helper
local function tween(obj, time, props, easing)
	return TweenService:Create(obj, TweenInfo.new(time, easing or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
end

-- Show notification
local showing = false
local function showNotification(msg)
	if showing then return end
	showing = true

	frame.Visible = true
	frame.Position = UDim2.new(0.5, 0, -0.15, 0)
	frame.BackgroundTransparency = 1
	title.TextTransparency = 1
	textLabel.TextTransparency = 1
	textLabel.Text = msg

	-- wait for autosize
	task.wait(0.05)

	-- Slide down
	tween(frame, 0.35, {Position = UDim2.new(0.5, 0, 0.03, 0), BackgroundTransparency = 0.2}, Enum.EasingStyle.Back):Play()
	tween(title, 0.25, {TextTransparency = 0}):Play()
	tween(textLabel, 0.25, {TextTransparency = 0}):Play()

	task.wait(2.5)

	-- Slide up
	local up = tween(frame, 0.35, {Position = UDim2.new(0.5, 0, -0.15, 0), BackgroundTransparency = 1})
	up:Play()
	tween(title, 0.25, {TextTransparency = 1}):Play()
	tween(textLabel, 0.25, {TextTransparency = 1}):Play()
	up.Completed:Wait()

	frame.Visible = false
	showing = false
end

-- Listen for sync start/stop
syncStatusEvent.OnClientEvent:Connect(function(action, leader)
	if action == "start" then
		local name = leader and leader.Name or "someone"
		showNotification("You are now dancing in sync with " .. name)

	elseif action == "stop" then
		showNotification("You stopped synchronizing.")
	end
end)
