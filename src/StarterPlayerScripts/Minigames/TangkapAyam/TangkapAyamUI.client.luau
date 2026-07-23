-- ============================================================
-- TangkapAyamUI.client.luau
-- Menampilkan waktu dan skor ayam yang ditangkap dengan UI Premium
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local minigamesFolder = ReplicatedStorage:WaitForChild("Minigames")
local ayamFolder = minigamesFolder:WaitForChild("TangkapAyam")
local eventsFolder = ayamFolder:WaitForChild("Events")
local UpdateUIEvent = eventsFolder:WaitForChild("UpdateTangkapAyamUI")
local HideUIEvent = eventsFolder:WaitForChild("HideTangkapAyamUI")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TangkapAyamUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Frame Utama (Glassmorphism Effect)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 110)
mainFrame.Position = UDim2.new(0.5, 0, 0, -150) -- Off-screen for animation
mainFrame.AnchorPoint = Vector2.new(0.5, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
mainFrame.BackgroundTransparency = 0.1
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = mainFrame

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 50, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
})
gradient.Rotation = 45
gradient.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(200, 0, 0)
stroke.Transparency = 0.1
stroke.Parent = mainFrame

-- Label Waktu
local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1, 0, 0.45, 0)
timeLabel.Position = UDim2.new(0, 0, 0.05, 0)
timeLabel.BackgroundTransparency = 1
timeLabel.Text = "⏳ Sisa Waktu: 60s"
timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timeLabel.Font = Enum.Font.GothamBlack
timeLabel.TextSize = 22
timeLabel.Parent = mainFrame

-- Label Skor
local scoreLabel = Instance.new("TextLabel")
scoreLabel.Size = UDim2.new(1, 0, 0.45, 0)
scoreLabel.Position = UDim2.new(0, 0, 0.5, 0)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Text = "🐔 Total Ayam Tertangkap: 0"
scoreLabel.TextColor3 = Color3.fromRGB(180, 0, 0)
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.TextSize = 20
scoreLabel.Parent = mainFrame

local isShown = false

local function animatePop(guiObject)
	local originalSize = guiObject.Size
	guiObject.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 10, originalSize.Y.Scale, originalSize.Y.Offset + 5)
	TweenService:Create(guiObject, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), {Size = originalSize}):Play()
end

UpdateUIEvent.OnClientEvent:Connect(function(timeLeft, score)
	if not isShown then
		isShown = true
		screenGui.Enabled = true
		TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, 30)
		}):Play()
	end
	
	local oldScore = tonumber(string.match(scoreLabel.Text, "%d+"))
	
	timeLabel.Text = "⏳ Sisa Waktu: " .. timeLeft .. "s"
	scoreLabel.Text = "🐔 Total Ayam Tertangkap: " .. score
	
	if oldScore ~= score then
		animatePop(scoreLabel)
	end
	
	if timeLeft <= 10 then
		timeLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		animatePop(timeLabel)
	else
		timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
end)

HideUIEvent.OnClientEvent:Connect(function()
	if isShown then
		isShown = false
		TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -150)
		}):Play()
		task.delay(0.4, function()
			if not isShown then screenGui.Enabled = false end
		end)
	end
end)

print("[TangkapAyamUI] Loaded successfully!")
