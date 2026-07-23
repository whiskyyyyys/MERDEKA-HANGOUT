local player = game.Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local MawarSystem = ReplicatedStorage:WaitForChild("MawarSystem")
local ReceivePrompt = MawarSystem:WaitForChild("ReceivePrompt")
local RespondGive = MawarSystem:WaitForChild("RespondGive")

local RECEIVER_ANIMATION_ID = "rbxassetid://10714369325"

-- 💎 DARK ROSE / EDGY AESTHETIC
local THEME = {
	bg = Color3.fromRGB(18, 14, 16),
	panel = Color3.fromRGB(26, 18, 22),
	accent = Color3.fromRGB(255, 60, 110), -- Vivid Rose Pink
	text = Color3.fromRGB(250, 240, 245),
	muted = Color3.fromRGB(160, 140, 150),
	stroke = Color3.fromRGB(60, 30, 45)
}

-- Quick Sound Helper
local function playSound(id, volume)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. id
	s.Volume = volume or 0.5
	s.Parent = SoundService
	s:Play()
	game.Debris:AddItem(s, 2)
end

local function createRoundedFrame(parent, size, pos, color)
	local f = Instance.new("Frame", parent)
	f.Size = size; f.Position = pos; f.BackgroundColor3 = color; f.BorderSizePixel = 0
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", f)
	stroke.Color = THEME.stroke; stroke.Thickness = 1.5
	return f, stroke
end

local function showNotification(senderName, toolName)
	local PlayerGui = player:WaitForChild("PlayerGui")
	if PlayerGui:FindFirstChild("MawarNotification") then PlayerGui.MawarNotification:Destroy() end

	local notifGui = Instance.new("ScreenGui", PlayerGui)
	notifGui.Name = "MawarNotification"

	local frame, stroke = createRoundedFrame(notifGui, UDim2.new(0, 320, 0, 50), UDim2.new(0.5, -160, 0, -60), THEME.panel)
	stroke.Color = THEME.accent

	local icon = Instance.new("TextLabel", frame)
	icon.Size = UDim2.new(0, 40, 1, 0); icon.Position = UDim2.new(0, 10, 0, 0)
	icon.BackgroundTransparency = 1; icon.Text = "🌹"; icon.TextSize = 20

	local text = Instance.new("TextLabel", frame)
	text.Size = UDim2.new(1, -60, 1, 0); text.Position = UDim2.new(0, 50, 0, 0)
	text.BackgroundTransparency = 1; text.TextXAlignment = Enum.TextXAlignment.Left
	text.Text = "Received <font color='#ff3c6e'>" .. toolName .. "</font> from " .. senderName
	text.RichText = true; text.TextColor3 = THEME.text; text.Font = Enum.Font.GothamMedium; text.TextSize = 14

	local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(frame, tweenInfo, {Position = UDim2.new(0.5, -160, 0, 30)}):Play()

	task.wait(3.5)

	local slideOut = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -160, 0, -60)})
	slideOut:Play()
	slideOut.Completed:Wait()
	notifGui:Destroy()
end

ReceivePrompt.OnClientEvent:Connect(function(sender, toolName)
	local PlayerGui = player:WaitForChild("PlayerGui")
	if PlayerGui:FindFirstChild("AcceptMawarGui") then return end

	playSound("6895079853", 0.6) -- Soft UI Pop

	local loadedTrack = nil
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
			local animation = Instance.new("Animation")
			animation.AnimationId = RECEIVER_ANIMATION_ID
			loadedTrack = animator:LoadAnimation(animation)
			loadedTrack.Priority = Enum.AnimationPriority.Action4
		end
	end

	local gui = Instance.new("ScreenGui", PlayerGui)
	gui.Name = "AcceptMawarGui"

	-- Main prompt container (starts small for bounce effect)
	local frame, stroke = createRoundedFrame(gui, UDim2.new(0, 280, 0, 130), UDim2.new(0.5, -140, 0.5, -65), THEME.bg)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	frame.Size = UDim2.new(0, 0, 0, 0) 
	frame.ClipsDescendants = true

	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1, 0, 0, 40); title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1; title.Text = "NEW GIFT"
	title.TextColor3 = THEME.accent; title.Font = Enum.Font.GothamBlack; title.TextSize = 18

	local text = Instance.new("TextLabel", frame)
	text.Size = UDim2.new(1, -40, 0, 30); text.Position = UDim2.new(0, 20, 0, 40)
	text.Text = "<b>" .. sender.Name .. "</b> is offering you a " .. toolName .. "."
	text.RichText = true; text.TextColor3 = THEME.text; text.Font = Enum.Font.Gotham; text.TextSize = 13; text.BackgroundTransparency = 1

	local acceptBtn = Instance.new("TextButton", frame)
	acceptBtn.Size = UDim2.new(0, 110, 0, 34); acceptBtn.Position = UDim2.new(0, 20, 1, -45)
	acceptBtn.Text = "Accept"; acceptBtn.BackgroundColor3 = THEME.accent; acceptBtn.TextColor3 = THEME.bg
	acceptBtn.Font = Enum.Font.GothamBold; acceptBtn.TextSize = 13; acceptBtn.AutoButtonColor = false
	Instance.new("UICorner", acceptBtn).CornerRadius = UDim.new(0, 6)

	local declineBtn = Instance.new("TextButton", frame)
	declineBtn.Size = UDim2.new(0, 110, 0, 34); declineBtn.Position = UDim2.new(1, -130, 1, -45)
	declineBtn.Text = "Decline"; declineBtn.BackgroundColor3 = THEME.panel; declineBtn.TextColor3 = THEME.muted
	declineBtn.Font = Enum.Font.GothamMedium; declineBtn.TextSize = 13; declineBtn.AutoButtonColor = false
	Instance.new("UICorner", declineBtn).CornerRadius = UDim.new(0, 6)
	local decStroke = Instance.new("UIStroke", declineBtn); decStroke.Color = THEME.stroke; decStroke.Thickness = 1

	-- Bounce In Animation
	TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 280, 0, 140)}):Play()

	-- Button Hover Effects
	acceptBtn.MouseEnter:Connect(function() TweenService:Create(acceptBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 90, 140)}):Play() end)
	acceptBtn.MouseLeave:Connect(function() TweenService:Create(acceptBtn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.accent}):Play() end)

	declineBtn.MouseEnter:Connect(function() TweenService:Create(declineBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 30, 35)}):Play() end)
	declineBtn.MouseLeave:Connect(function() TweenService:Create(declineBtn, TweenInfo.new(0.2), {BackgroundColor3 = THEME.panel}):Play() end)

	local function closePrompt()
		local tw = TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
		tw:Play()
		tw.Completed:Wait()
		gui:Destroy()
	end

	acceptBtn.MouseButton1Click:Connect(function()
		playSound("6895079853", 0.7) -- Success Chime
		if loadedTrack then
			loadedTrack:Play(0.05, 1, 1) 
		end
		RespondGive:FireServer(true)
		closePrompt()
		showNotification(sender.Name, toolName)
	end)

	declineBtn.MouseButton1Click:Connect(function()
		RespondGive:FireServer(false)
		closePrompt()
	end)
end)