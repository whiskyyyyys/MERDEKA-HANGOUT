local Config = {
	BlurSize = 24,
	TweenTime = 0.3,
	ScaleStart = 0.7,
	EasingStyle = Enum.EasingStyle.Back,
	EasingDirectionIn = Enum.EasingDirection.Out,
	EasingDirectionOut = Enum.EasingDirection.In,
	InitialDelay = 1
}

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gameRules = playerGui:WaitForChild("GameRules")
local frameRules = gameRules:WaitForChild("FrameRules")
local closeFrame = frameRules:WaitForChild("CloseFrame")
local closeButton = closeFrame:WaitForChild("CloseButton")

local uiScale = frameRules:FindFirstChildOfClass("UIScale")
if not uiScale then
	uiScale = Instance.new("UIScale")
	uiScale.Parent = frameRules
end

local blurEffect = Instance.new("BlurEffect")
blurEffect.Name = "GameRulesBlur"
blurEffect.Size = 0
blurEffect.Parent = Lighting

local hiddenGuis = {}
local rulesOpen = false
local childAddedConnection = nil

local function tryHideGui(gui)
	if gui:IsA("ScreenGui") and gui ~= gameRules and gui.Enabled then
		hiddenGuis[gui] = true
		gui.Enabled = false
	end
end

local function hideOtherUI()
	hiddenGuis = {}
	for _, gui in ipairs(playerGui:GetChildren()) do
		tryHideGui(gui)
	end

	childAddedConnection = playerGui.ChildAdded:Connect(function(gui)
		if rulesOpen then
			task.defer(tryHideGui, gui)
		end
	end)

	StarterGui:SetCore("TopbarEnabled", false)
end

local function restoreOtherUI()
	if childAddedConnection then
		childAddedConnection:Disconnect()
		childAddedConnection = nil
	end

	for gui, _ in pairs(hiddenGuis) do
		gui.Enabled = true
	end
	hiddenGuis = {}

	StarterGui:SetCore("TopbarEnabled", true)
end

local function showGameRules()
	rulesOpen = true
	hideOtherUI()

	gameRules.Enabled = true
	frameRules.Visible = true
	uiScale.Scale = Config.ScaleStart
	blurEffect.Size = 0

	local scaleTween = TweenService:Create(
		uiScale,
		TweenInfo.new(Config.TweenTime, Config.EasingStyle, Config.EasingDirectionIn),
		{Scale = 1}
	)

	local blurTween = TweenService:Create(
		blurEffect,
		TweenInfo.new(Config.TweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = Config.BlurSize}
	)

	scaleTween:Play()
	blurTween:Play()
end

local function hideGameRules()
	rulesOpen = false

	local scaleTween = TweenService:Create(
		uiScale,
		TweenInfo.new(Config.TweenTime, Config.EasingStyle, Config.EasingDirectionOut),
		{Scale = Config.ScaleStart}
	)

	local blurTween = TweenService:Create(
		blurEffect,
		TweenInfo.new(Config.TweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Size = 0}
	)

	scaleTween:Play()
	blurTween:Play()

	blurTween.Completed:Connect(function()
		frameRules.Visible = false
		gameRules.Enabled = false
		restoreOtherUI()
	end)
end

closeButton.MouseButton1Click:Connect(hideGameRules)

task.wait(Config.InitialDelay)
showGameRules()