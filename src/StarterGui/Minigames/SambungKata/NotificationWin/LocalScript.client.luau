-- ============================================================
-- NotificationWinGui.client.lua
-- LocalScript → masukkan ke StarterGui
-- Menampilkan notifikasi menang/kalah dengan detail reward coin.
-- GUI dibuat PROGRAMATIK (tidak bergantung GUI manual di Studio)
-- sehingga pasti muncul tanpa masalah transparency.
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local TweenService      = game:GetService("TweenService")

local Modules = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Modules")
local Config  = require(Modules:WaitForChild("GameConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Remotes")

local R = {}
for k, v in pairs(Config.Remotes) do R[k] = Remotes:WaitForChild(v) end

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════════════════════════
-- SOUND EFFECTS: victory / defeat
-- ══════════════════════════════════════════════════════════════
local victorySound = Instance.new("Sound")
victorySound.Name    = "VictorySound"
victorySound.SoundId = "rbxassetid://78721791372104"  -- ← ganti SoundId menang sesuai keinginan
victorySound.Volume  = 0.6
victorySound.Parent  = playerGui

local defeatSound = Instance.new("Sound")
defeatSound.Name    = "DefeatSound"
defeatSound.SoundId = "rbxassetid://0"   -- ← ganti SoundId kalah sesuai keinginan
defeatSound.Volume  = 0.5
defeatSound.Parent  = playerGui

-- ══════════════════════════════════════════════════════════════
-- BUILD GUI PROGRAMMATICALLY
-- ══════════════════════════════════════════════════════════════
local screenGui = Instance.new("ScreenGui")
screenGui.Name              = "NotificationWinGenerated"
screenGui.ResetOnSpawn      = false
screenGui.IgnoreGuiInset    = true
screenGui.DisplayOrder      = 100  -- di atas semua GUI lain
screenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
screenGui.Enabled           = false
screenGui.Parent            = playerGui

-- Click catcher (full screen invisible button)
local clickCatcher = Instance.new("TextButton")
clickCatcher.Name                   = "ClickCatcher"
clickCatcher.Size                   = UDim2.new(1, 0, 1, 0)
clickCatcher.Position               = UDim2.new(0, 0, 0, 0)
clickCatcher.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
clickCatcher.BackgroundTransparency = 0.5
clickCatcher.Text                   = ""
clickCatcher.ZIndex                 = 1
clickCatcher.BorderSizePixel        = 0
clickCatcher.Parent                 = screenGui

-- Main frame (center card)
local mainFrame = Instance.new("Frame")
mainFrame.Name                   = "MainFrame"
mainFrame.Size                   = UDim2.new(0, 340, 0, 280)
mainFrame.Position               = UDim2.new(0.5, -170, 0.5, -140)
mainFrame.BackgroundColor3       = Color3.fromRGB(30, 30, 45)
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel        = 0
mainFrame.ZIndex                 = 10
mainFrame.Parent                 = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent       = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color     = Color3.fromRGB(255, 215, 0)
stroke.Thickness = 2
stroke.Parent    = mainFrame

-- Title label (VICTORY / DEFEAT)
local titleLabel = Instance.new("TextLabel")
titleLabel.Name                   = "Title"
titleLabel.Size                   = UDim2.new(1, 0, 0, 50)
titleLabel.Position               = UDim2.new(0, 0, 0, 15)
titleLabel.BackgroundTransparency = 1
titleLabel.Font                   = Enum.Font.GothamBlack
titleLabel.TextSize               = 36
titleLabel.TextColor3             = Color3.fromRGB(255, 215, 0)
titleLabel.Text                   = "VICTORY"
titleLabel.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
titleLabel.TextStrokeTransparency = 0.3
titleLabel.ZIndex                 = 11
titleLabel.Parent                 = mainFrame

-- Divider line
local divider = Instance.new("Frame")
divider.Name                   = "Divider"
divider.Size                   = UDim2.new(0.8, 0, 0, 2)
divider.Position               = UDim2.new(0.1, 0, 0, 72)
divider.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
divider.BackgroundTransparency = 0.6
divider.BorderSizePixel        = 0
divider.ZIndex                 = 11
divider.Parent                 = mainFrame

-- Reward section
local function makeRewardRow(name, labelText, yPos)
	local row = Instance.new("Frame")
	row.Name                   = name
	row.Size                   = UDim2.new(0.85, 0, 0, 30)
	row.Position               = UDim2.new(0.075, 0, 0, yPos)
	row.BackgroundTransparency = 1
	row.ZIndex                 = 11
	row.Parent                 = mainFrame

	local lbl = Instance.new("TextLabel")
	lbl.Name                   = "Label"
	lbl.Size                   = UDim2.new(0.6, 0, 1, 0)
	lbl.Position               = UDim2.new(0, 0, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font                   = Enum.Font.GothamMedium
	lbl.TextSize               = 16
	lbl.TextColor3             = Color3.fromRGB(200, 200, 200)
	lbl.TextXAlignment         = Enum.TextXAlignment.Left
	lbl.Text                   = labelText
	lbl.ZIndex                 = 12
	lbl.Parent                 = row

	local val = Instance.new("TextLabel")
	val.Name                   = "Value"
	val.Size                   = UDim2.new(0.4, 0, 1, 0)
	val.Position               = UDim2.new(0.6, 0, 0, 0)
	val.BackgroundTransparency = 1
	val.Font                   = Enum.Font.GothamBold
	val.TextSize               = 18
	val.TextColor3             = Color3.fromRGB(255, 220, 80)
	val.TextXAlignment         = Enum.TextXAlignment.Right
	val.Text                   = "Rp0"
	val.ZIndex                 = 12
	val.Parent                 = row

	return val
end

local correctVal = makeRewardRow("CorrectRow", "Jawaban Benar:", 90)
local winVal     = makeRewardRow("WinRow",     "Bonus Menang:",  125)

-- Total divider
local divider2 = Instance.new("Frame")
divider2.Size                   = UDim2.new(0.85, 0, 0, 1)
divider2.Position               = UDim2.new(0.075, 0, 0, 165)
divider2.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
divider2.BackgroundTransparency = 0.7
divider2.BorderSizePixel        = 0
divider2.ZIndex                 = 11
divider2.Parent                 = mainFrame

local totalVal = makeRewardRow("TotalRow", "TOTAL:", 175)
totalVal.TextSize   = 22
totalVal.TextColor3 = Color3.fromRGB(80, 255, 80)

-- Word count info
local wordCountLbl = Instance.new("TextLabel")
wordCountLbl.Name                   = "WordCount"
wordCountLbl.Size                   = UDim2.new(0.85, 0, 0, 22)
wordCountLbl.Position               = UDim2.new(0.075, 0, 0, 215)
wordCountLbl.BackgroundTransparency = 1
wordCountLbl.Font                   = Enum.Font.Gotham
wordCountLbl.TextSize               = 13
wordCountLbl.TextColor3             = Color3.fromRGB(150, 150, 150)
wordCountLbl.Text                   = ""
wordCountLbl.ZIndex                 = 12
wordCountLbl.Parent                 = mainFrame

-- Click to close label
local closeLbl = Instance.new("TextLabel")
closeLbl.Name                   = "CloseHint"
closeLbl.Size                   = UDim2.new(1, 0, 0, 25)
closeLbl.Position               = UDim2.new(0, 0, 1, -30)
closeLbl.BackgroundTransparency = 1
closeLbl.Font                   = Enum.Font.GothamMedium
closeLbl.TextSize               = 12
closeLbl.TextColor3             = Color3.fromRGB(140, 140, 140)
closeLbl.Text                   = "Klik di mana saja untuk menutup"
closeLbl.ZIndex                 = 12
closeLbl.Parent                 = mainFrame

-- ══════════════════════════════════════════════════════════════
-- BLUR EFFECT
-- ══════════════════════════════════════════════════════════════
local blurEffect = nil

local function addBlur()
	if blurEffect then return end
	blurEffect = Instance.new("BlurEffect")
	blurEffect.Name   = "WinNotifBlur"
	blurEffect.Size   = 0
	blurEffect.Parent = Lighting
	TweenService:Create(blurEffect, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = 24
	}):Play()
end

local function removeBlur()
	if blurEffect then
		local b = blurEffect
		blurEffect = nil
		local tw = TweenService:Create(b, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = 0
		})
		tw:Play()
		tw.Completed:Connect(function()
			b:Destroy()
		end)
	end
end

-- ══════════════════════════════════════════════════════════════
-- SHOW / HIDE
-- ══════════════════════════════════════════════════════════════
local isShowing = false

local function showNotification(data)
	if isShowing then return end
	isShowing = true

	local isWinner     = data.isWinner
	local winBonus     = data.winBonus or 0
	local correctBonus = data.correctBonus or 0
	local totalCoins   = data.totalCoins or 0
	local wordCount    = data.wordCount or 0

	-- Update content
	if isWinner then
		titleLabel.Text       = "VICTORY!"
		titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		stroke.Color          = Color3.fromRGB(255, 215, 0)
	else
		titleLabel.Text       = "DEFEAT"
		titleLabel.TextColor3 = Color3.fromRGB(220, 70, 70)
		stroke.Color          = Color3.fromRGB(220, 70, 70)
	end

	correctVal.Text   = "Rp" .. tostring(correctBonus)
	winVal.Text       = "Rp" .. tostring(winBonus)
	totalVal.Text     = "Rp" .. tostring(totalCoins)
	wordCountLbl.Text = wordCount .. " kata benar"

	-- Prepare for animation: start transparent
	mainFrame.BackgroundTransparency = 1
	clickCatcher.BackgroundTransparency = 1
	for _, desc in ipairs(mainFrame:GetDescendants()) do
		if desc:IsA("TextLabel") then
			desc.TextTransparency = 1
			desc.TextStrokeTransparency = 1
		end
		if desc:IsA("Frame") then
			desc.BackgroundTransparency = 1
		end
		if desc:IsA("UIStroke") then
			desc.Transparency = 1
		end
	end
	stroke.Transparency = 1

	-- Enable and animate
	screenGui.Enabled = true
	addBlur()

	-- Play victory/defeat sound
	if isWinner then
		victorySound:Play()
	else
		defeatSound:Play()
	end

	local fadeIn = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Fade in backdrop
	TweenService:Create(clickCatcher, fadeIn, { BackgroundTransparency = 0.5 }):Play()

	-- Fade in main frame
	TweenService:Create(mainFrame, fadeIn, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(stroke, fadeIn, { Transparency = 0 }):Play()

	-- Fade in all children with slight delay
	task.delay(0.1, function()
		local childFade = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		for _, desc in ipairs(mainFrame:GetDescendants()) do
			if desc:IsA("TextLabel") then
				TweenService:Create(desc, childFade, {
					TextTransparency = 0,
					TextStrokeTransparency = 0.3
				}):Play()
			end
			if desc:IsA("Frame") and desc ~= mainFrame then
				local targetBg = 0
				-- Reward rows have transparent bg by design
				if desc:FindFirstChild("Label") then
					targetBg = 1
				end
				TweenService:Create(desc, childFade, {
					BackgroundTransparency = targetBg
				}):Play()
			end
		end
	end)
end

local function hideNotification()
	if not isShowing then return end
	isShowing = false

	removeBlur()

	local fadeOut = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	TweenService:Create(mainFrame, fadeOut, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(clickCatcher, fadeOut, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(stroke, fadeOut, { Transparency = 1 }):Play()

	for _, desc in ipairs(mainFrame:GetDescendants()) do
		if desc:IsA("TextLabel") then
			TweenService:Create(desc, fadeOut, {
				TextTransparency = 1,
				TextStrokeTransparency = 1
			}):Play()
		end
		if desc:IsA("Frame") and desc ~= mainFrame then
			TweenService:Create(desc, fadeOut, { BackgroundTransparency = 1 }):Play()
		end
	end

	task.delay(0.4, function()
		screenGui.Enabled = false
	end)
end

-- ══════════════════════════════════════════════════════════════
-- CLICK HANDLERS
-- ══════════════════════════════════════════════════════════════
clickCatcher.MouseButton1Click:Connect(hideNotification)
clickCatcher.TouchTap:Connect(hideNotification)

mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		hideNotification()
	end
end)

-- ══════════════════════════════════════════════════════════════
-- LISTEN FROM SERVER
-- ══════════════════════════════════════════════════════════════
R.WinNotif.OnClientEvent:Connect(function(data)
	if not data or type(data) ~= "table" then return end
	showNotification(data)
end)

-- Safety net: jika screenGui di-disable dari luar (misalnya hideOtherGuis),
-- otomatis bersihkan blur supaya tidak nyangkut
screenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not screenGui.Enabled and isShowing then
		isShowing = false
		removeBlur()
	end
end)
