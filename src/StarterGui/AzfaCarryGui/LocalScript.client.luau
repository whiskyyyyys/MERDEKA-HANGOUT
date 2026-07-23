local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera
local gui = script.Parent

-- Sembunyikan UI fisik lama jika masih ada agar tidak bentrok
pcall(function()
	if gui:FindFirstChild("AzfaPromtFrame") then gui.AzfaPromtFrame.Visible = false end
	if gui:FindFirstChild("AzfaDropFrame") then gui.AzfaDropFrame.Visible = false end
end)

-- ==========================================
-- PEMBUATAN UI MODERN (PROCEDURAL)
-- ==========================================
local Container = Instance.new("Frame")
Container.Name = "ModernCarryUI"
Container.Size = UDim2.fromScale(1, 1)
Container.BackgroundTransparency = 1
Container.Parent = gui

-- 1. PROMPT FRAME (Untuk Request Masuk)
local PromptFrame = Instance.new("Frame")
PromptFrame.Name = "Prompt"
PromptFrame.Size = UDim2.new(0, 320, 0, 160)
PromptFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
PromptFrame.AnchorPoint = Vector2.new(0.5, 0.5)
PromptFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
PromptFrame.BackgroundTransparency = 0.1
PromptFrame.ClipsDescendants = true
PromptFrame.Visible = false
PromptFrame.Parent = Container

local PromptCorner = Instance.new("UICorner")
PromptCorner.CornerRadius = UDim.new(0, 12)
PromptCorner.Parent = PromptFrame

local PromptStroke = Instance.new("UIStroke")
PromptStroke.Color = Color3.fromRGB(60, 60, 70)
PromptStroke.Thickness = 2
PromptStroke.Parent = PromptFrame

local PromptTitle = Instance.new("TextLabel")
PromptTitle.Size = UDim2.new(1, 0, 0, 40)
PromptTitle.BackgroundTransparency = 1
PromptTitle.Text = "CARRY REQUEST"
PromptTitle.Font = Enum.Font.GothamBold
PromptTitle.TextSize = 18
PromptTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PromptTitle.Parent = PromptFrame

local PromptText = Instance.new("TextLabel")
PromptText.Size = UDim2.new(0.9, 0, 0, 50)
PromptText.Position = UDim2.new(0.5, 0, 0, 45)
PromptText.AnchorPoint = Vector2.new(0.5, 0)
PromptText.BackgroundTransparency = 1
PromptText.Text = "Player ingin menggendongmu!"
PromptText.Font = Enum.Font.Gotham
PromptText.TextSize = 15
PromptText.TextColor3 = Color3.fromRGB(220, 220, 220)
PromptText.TextWrapped = true
PromptText.Parent = PromptFrame

local AcceptBtn = Instance.new("TextButton")
AcceptBtn.Size = UDim2.new(0.4, 0, 0, 40)
AcceptBtn.Position = UDim2.new(0.5, -5, 1, -15)
AcceptBtn.AnchorPoint = Vector2.new(1, 1)
AcceptBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
AcceptBtn.Text = "TERIMA"
AcceptBtn.Font = Enum.Font.GothamBold
AcceptBtn.TextColor3 = Color3.new(1, 1, 1)
AcceptBtn.TextSize = 14
AcceptBtn.Parent = PromptFrame
Instance.new("UICorner", AcceptBtn).CornerRadius = UDim.new(0, 8)

local DeclineBtn = Instance.new("TextButton")
DeclineBtn.Size = UDim2.new(0.4, 0, 0, 40)
DeclineBtn.Position = UDim2.new(0.5, 5, 1, -15)
DeclineBtn.AnchorPoint = Vector2.new(0, 1)
DeclineBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
DeclineBtn.Text = "TOLAK"
DeclineBtn.Font = Enum.Font.GothamBold
DeclineBtn.TextColor3 = Color3.new(1, 1, 1)
DeclineBtn.TextSize = 14
DeclineBtn.Parent = PromptFrame
Instance.new("UICorner", DeclineBtn).CornerRadius = UDim.new(0, 8)

-- 2. DROP FRAME (Widget saat Digendong/Menggendong)
local DropFrame = Instance.new("Frame")
DropFrame.Name = "DropWidget"
DropFrame.Size = UDim2.new(0, 200, 0, 70)
DropFrame.Position = UDim2.new(1, -20, 0.5, 0)
DropFrame.AnchorPoint = Vector2.new(1, 0.5)
DropFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
DropFrame.BackgroundTransparency = 0.1
DropFrame.Visible = false
DropFrame.Parent = Container

local DropCorner = Instance.new("UICorner")
DropCorner.CornerRadius = UDim.new(0, 12)
DropCorner.Parent = DropFrame

local DropAvatar = Instance.new("ImageLabel")
DropAvatar.Size = UDim2.new(0, 50, 0, 50)
DropAvatar.Position = UDim2.new(0, 10, 0.5, 0)
DropAvatar.AnchorPoint = Vector2.new(0, 0.5)
DropAvatar.BackgroundTransparency = 1
DropAvatar.Parent = DropFrame
Instance.new("UICorner", DropAvatar).CornerRadius = UDim.new(1, 0)

local DropName = Instance.new("TextLabel")
DropName.Size = UDim2.new(1, -70, 0, 20)
DropName.Position = UDim2.new(0, 70, 0, 10)
DropName.BackgroundTransparency = 1
DropName.Text = "PlayerName"
DropName.Font = Enum.Font.GothamBold
DropName.TextSize = 14
DropName.TextColor3 = Color3.new(1, 1, 1)
DropName.TextXAlignment = Enum.TextXAlignment.Left
DropName.Parent = DropFrame

local DropBtn = Instance.new("TextButton")
DropBtn.Size = UDim2.new(1, -80, 0, 25)
DropBtn.Position = UDim2.new(0, 70, 0, 35)
DropBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
DropBtn.Text = "LEPASKAN"
DropBtn.Font = Enum.Font.GothamBold
DropBtn.TextColor3 = Color3.new(1, 1, 1)
DropBtn.TextSize = 12
DropBtn.Parent = DropFrame
Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- LOGIKA FUNGSI CARRY
-- ==========================================
local CarryReplic = ReplicatedStorage:WaitForChild("CarryReplic")
local CarryRemotes = CarryReplic:WaitForChild("CarryRemotes")
local CarryRemote = CarryRemotes:WaitForChild("CarryRemote")

local currentRequesterUserId = nil
local originalCameraSubject = nil
local originalCameraType = nil

local acceptBusy = false
local declineBusy = false
local downBusy = false

local function getThumbnail(userId)
	if typeof(userId) ~= "number" or userId <= 0 then return "" end
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	return ok and content or ""
end

local function setCarryCameraToPlayerRoot(userId)
	local otherPlayer = Players:GetPlayerByUserId(userId)
	if not otherPlayer or not otherPlayer.Character then return end
	local root = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if not originalCameraSubject then originalCameraSubject = camera.CameraSubject end
	if not originalCameraType then originalCameraType = camera.CameraType end

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = root
end

local function restoreOwnCamera()
	local myCharacter = LocalPlayer.Character
	local myHumanoid = myCharacter and myCharacter:FindFirstChildOfClass("Humanoid")
	camera.CameraType = Enum.CameraType.Custom
	if myHumanoid then
		camera.CameraSubject = myHumanoid
	elseif originalCameraSubject then
		camera.CameraSubject = originalCameraSubject
	end
	originalCameraSubject = nil
	originalCameraType = nil
end

local function showPrompt(fromUserId, fromName)
	currentRequesterUserId = fromUserId
	PromptText.Text = string.format("<b>%s</b> ingin menggendongmu!", fromName or "Seseorang")
	PromptText.RichText = true
	
	PromptFrame.Size = UDim2.new(0, 280, 0, 140)
	PromptFrame.Visible = true
	TweenService:Create(PromptFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 320, 0, 160)}):Play()
end

local function hidePrompt()
	currentRequesterUserId = nil
	local tween = TweenService:Create(PromptFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 280, 0, 140)})
	tween:Play()
	tween.Completed:Once(function() PromptFrame.Visible = false end)
end

local function showDrop(otherUserId, otherName)
	DropName.Text = otherName or "Player"
	DropAvatar.Image = getThumbnail(otherUserId)
	
	DropFrame.Position = UDim2.new(1, 50, 0.5, 0)
	DropFrame.Visible = true
	TweenService:Create(DropFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -20, 0.5, 0)}):Play()
end

local function hideDrop()
	local tween = TweenService:Create(DropFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(1, 50, 0.5, 0)})
	tween:Play()
	tween.Completed:Once(function() DropFrame.Visible = false end)
end

-- ==========================================
-- BUTTON EVENTS
-- ==========================================
local function buttonHover(btn)
	TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.2}):Play()
end
local function buttonLeave(btn)
	TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
end
AcceptBtn.MouseEnter:Connect(function() buttonHover(AcceptBtn) end)
AcceptBtn.MouseLeave:Connect(function() buttonLeave(AcceptBtn) end)
DeclineBtn.MouseEnter:Connect(function() buttonHover(DeclineBtn) end)
DeclineBtn.MouseLeave:Connect(function() buttonLeave(DeclineBtn) end)
DropBtn.MouseEnter:Connect(function() buttonHover(DropBtn) end)
DropBtn.MouseLeave:Connect(function() buttonLeave(DropBtn) end)

AcceptBtn.Activated:Connect(function()
	if acceptBusy or not currentRequesterUserId then return end
	acceptBusy = true
	CarryRemote:FireServer("CarryResponse", true, currentRequesterUserId)
	hidePrompt()
	task.delay(0.35, function() acceptBusy = false end)
end)

DeclineBtn.Activated:Connect(function()
	if declineBusy or not currentRequesterUserId then return end
	declineBusy = true
	CarryRemote:FireServer("CarryResponse", false, currentRequesterUserId)
	hidePrompt()
	task.delay(0.35, function() declineBusy = false end)
end)

DropBtn.Activated:Connect(function()
	if downBusy then return end
	downBusy = true
	CarryRemote:FireServer("DropCarry")
	task.delay(0.35, function() downBusy = false end)
end)

-- ==========================================
-- NETWORKING EVENTS
-- ==========================================
CarryRemote.OnClientEvent:Connect(function(action, data)
	if type(action) ~= "string" then return end
	data = data or {}

	if action == "ShowCarryRequest" then
		showPrompt(data.requesterUserId, data.requesterName)
	elseif action == "HideCarryRequest" then
		hidePrompt()
	elseif action == "CarryStarted" then
		hidePrompt()
		showDrop(data.otherUserId, data.otherName)
		if data.role == "carried" and data.otherUserId then
			setCarryCameraToPlayerRoot(data.otherUserId)
		end
	elseif action == "CarryEnded" then
		hidePrompt()
		hideDrop()
		restoreOwnCamera()
	end
end)

LocalPlayer.CharacterAdded:Connect(function()
	PromptFrame.Visible = false
	DropFrame.Visible = false
	restoreOwnCamera()
end)

print("[AzfaCarryGui] Modern Procedural UI loaded successfully!")