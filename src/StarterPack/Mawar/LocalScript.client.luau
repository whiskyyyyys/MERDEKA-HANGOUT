-- Script untuk Tool di Roblox Studio
local tool = script.Parent
local player = game.Players.LocalPlayer
local character = nil
local humanoid = nil
local animator = nil

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MawarSystem = ReplicatedStorage:WaitForChild("MawarSystem")
local RequestGive = MawarSystem:WaitForChild("RequestGive")

-- Settings
local ANIMATION_ID = "rbxassetid://70491642909581" 
local COOLDOWN_TIME = 0.5 
local PLAY_ONLY_ONCE = false 

-- Variables
local lastClickTime = 0
local hasPlayedOnce = false
local animationTrack = nil

local function loadAnimation()
	if animator and not animationTrack then
		local animation = Instance.new("Animation")
		animation.AnimationId = ANIMATION_ID
		animationTrack = animator:LoadAnimation(animation)
		animationTrack.Priority = Enum.AnimationPriority.Action4
		animationTrack.Looped = false
	end
end

-- Generate UI for selecting a player
-- Replace ONLY the promptPlayerSelection function in your tool script with this:

local function promptPlayerSelection()
	local PlayerGui = player:WaitForChild("PlayerGui")
	if PlayerGui:FindFirstChild("MawarPlayerSelect") then return end 

	local gui = Instance.new("ScreenGui", PlayerGui)
	gui.Name = "MawarPlayerSelect"

	local frame = Instance.new("ScrollingFrame", gui)
	frame.Size = UDim2.new(0, 220, 0, 300)
	frame.Position = UDim2.new(0.5, -110, 0.5, -150)
	frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
	frame.CanvasSize = UDim2.new(0, 0, 0, 0)
	frame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	frame.ScrollBarThickness = 4

	local frameCorner = Instance.new("UICorner", frame)
	frameCorner.CornerRadius = UDim.new(0, 8)
	local frameStroke = Instance.new("UIStroke", frame)
	frameStroke.Color = Color3.fromRGB(60, 60, 60)

	local layout = Instance.new("UIListLayout", frame)
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local padding = Instance.new("UIPadding", frame)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)

	local cancelBtn = Instance.new("TextButton", frame)
	cancelBtn.Size = UDim2.new(0.9, 0, 0, 35)
	cancelBtn.Text = "Cancel"
	cancelBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelBtn.Font = Enum.Font.GothamMedium
	cancelBtn.TextSize = 14
	Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 4)
	local cancelStroke = Instance.new("UIStroke", cancelBtn)
	cancelStroke.Color = Color3.fromRGB(200, 100, 100)

	cancelBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

	for _, targetPlayer in pairs(game.Players:GetPlayers()) do
		if targetPlayer ~= player then
			local btn = Instance.new("TextButton", frame)
			btn.Size = UDim2.new(0.9, 0, 0, 35)
			btn.Text = targetPlayer.Name
			btn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			btn.TextColor3 = Color3.fromRGB(240, 240, 240)
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 14
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
			local btnStroke = Instance.new("UIStroke", btn)
			btnStroke.Color = Color3.fromRGB(80, 80, 80)

			btn.MouseButton1Click:Connect(function()
				RequestGive:FireServer(targetPlayer, tool.Name)
				gui:Destroy()
			end)
		end
	end
end

local function playAnimation()
	local currentTime = tick()
	if currentTime - lastClickTime < COOLDOWN_TIME then return end
	if PLAY_ONLY_ONCE and hasPlayedOnce then return end

	if animationTrack then
		for _, track in pairs(animator:GetPlayingAnimationTracks()) do
			if track ~= animationTrack and track.Priority.Value < Enum.AnimationPriority.Action4.Value then
				track:Stop(0.1) 
			end
		end

		animationTrack:Play(0.1, 1, 1) 
		lastClickTime = currentTime
		hasPlayedOnce = true
	else
		warn("Animation track not loaded!")
	end
end

tool.Equipped:Connect(function()
	character = tool.Parent
	humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		animator = humanoid:FindFirstChildOfClass("Animator")
		if not animator then
			animator = Instance.new("Animator")
			animator.Parent = humanoid
		end
		loadAnimation()
	end
end)

tool.Unequipped:Connect(function()
	if animationTrack then animationTrack:Stop(0.2) end
	character = nil
	humanoid = nil
	animator = nil

	-- Close selection UI if unequipped
	local PlayerGui = player:WaitForChild("PlayerGui")
	if PlayerGui:FindFirstChild("MawarPlayerSelect") then
		PlayerGui.MawarPlayerSelect:Destroy()
	end
end)

tool.Activated:Connect(function()
	playAnimation()
	promptPlayerSelection() -- Adds the new pop-up
end)