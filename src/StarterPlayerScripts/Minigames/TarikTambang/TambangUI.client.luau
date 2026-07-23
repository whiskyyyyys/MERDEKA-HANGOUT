-- ============================================================
-- TambangUI.client.luau
-- UI Tarik Tambang — Tema Kemerdekaan Merah Putih
-- Tombol hanya di Mobile, PC cukup SPACE
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RSMinigames = ReplicatedStorage:WaitForChild("Minigames")
local TambangFolder = RSMinigames:WaitForChild("TarikTambang")
local Events = TambangFolder:WaitForChild("Events")
local ShowUIEvent = Events:WaitForChild("ShowUI")
local HideUIEvent = Events:WaitForChild("HideUI")
local PullEvent = Events:WaitForChild("PullEvent")
local GameEndEvent = Events:WaitForChild("GameEndEvent")
local ScoreUpdateEvent = Events:WaitForChild("ScoreUpdate")

local PULL_ANIMATION_ID = "rbxassetid://507770818" -- GANTI ID ANIMASI NARIK
local loadedAnimTrack = nil
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ═══════════════════════════════════════════════════════════
-- SCREEN GUI — Referensi langsung ke TambangUI buatan user
-- ═══════════════════════════════════════════════════════════
local screenGui = playerGui:WaitForChild("TambangUI")
screenGui.Enabled = false

-- ScoreContainer
local scoreContainer = screenGui:WaitForChild("ScoreContainer")
local redFill       = scoreContainer:WaitForChild("RedFill")
local whiteFill     = scoreContainer:WaitForChild("WhiteFill")
local midLine       = scoreContainer:FindFirstChild("CenterLine")

-- PullContainer
local container     = screenGui:WaitForChild("PullContainer")
local feedbackLabel = container:WaitForChild("Feedback")
local barBg         = container:WaitForChild("BarBg")
barBg.ClipsDescendants = true

local hitZone       = barBg:WaitForChild("HitZone")
local cursor        = barBg:WaitForChild("Cursor")

-- PullBtn / HintText (sesuai device)
local pullButton    = container:FindFirstChild("PullBtn")
local hintLabel     = container:FindFirstChild("HintText")

if isMobile then
	if pullButton then pullButton.Visible = true end
	if hintLabel  then hintLabel.Visible  = false end
else
	if hintLabel  then hintLabel.Visible  = true end
	if pullButton then pullButton.Visible  = false end
end

-- WinScreen (pakai buatan user juga, hapus dulu agar tidak dobel saat rerun)
local Lighting = game:GetService("Lighting")

local function makeCorner(parent, radius)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = radius or UDim.new(1, 0)
end

-- Hapus WinScreen lama kalau ada (dibuat ulang supaya state-nya bersih)
do
	local old = screenGui:FindFirstChild("WinScreen")
	if old then old:Destroy() end
end

local winScreen = Instance.new("Frame")
winScreen.Name = "WinScreen"
winScreen.Size = UDim2.new(1, 0, 1, 0)
winScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
winScreen.BackgroundTransparency = 1
winScreen.BorderSizePixel = 0
winScreen.Visible = false
winScreen.ZIndex = 10
winScreen.Parent = screenGui

local winCard = Instance.new("Frame")
winCard.Name = "WinCard"
winCard.Size = UDim2.new(0, 340, 0, 240)
winCard.Position = UDim2.new(0.5, -170, 0.5, -120)
winCard.BackgroundColor3 = Color3.fromRGB(35, 10, 10)
winCard.BackgroundTransparency = 1
winCard.BorderSizePixel = 0
winCard.ZIndex = 11
winCard.Parent = winScreen
makeCorner(winCard, UDim.new(0, 16))

local cardStroke = Instance.new("UIStroke", winCard)
cardStroke.Color = Color3.fromRGB(255, 50, 50)
cardStroke.Thickness = 3
cardStroke.Transparency = 1

local winTitle = Instance.new("TextLabel")
winTitle.Size = UDim2.new(1, 0, 0, 50)
winTitle.Position = UDim2.new(0, 0, 0, 20)
winTitle.BackgroundTransparency = 1
winTitle.Font = Enum.Font.GothamBlack
winTitle.TextSize = 38
winTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
winTitle.Text = "VICTORY"
winTitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
winTitle.TextStrokeTransparency = 1
winTitle.TextTransparency = 1
winTitle.ZIndex = 12
winTitle.Parent = winCard

local winDivider = Instance.new("Frame")
winDivider.Size = UDim2.new(0.8, 0, 0, 3)
winDivider.Position = UDim2.new(0.1, 0, 0, 85)
winDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
winDivider.BackgroundTransparency = 1
winDivider.BorderSizePixel = 0
winDivider.ZIndex = 12
winDivider.Parent = winCard

local winSubLabel = Instance.new("TextLabel")
winSubLabel.Size = UDim2.new(0.8, 0, 0, 40)
winSubLabel.Position = UDim2.new(0.1, 0, 0, 100)
winSubLabel.BackgroundTransparency = 1
winSubLabel.Font = Enum.Font.GothamBold
winSubLabel.TextSize = 20
winSubLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
winSubLabel.Text = ""
winSubLabel.TextWrapped = true
winSubLabel.TextTransparency = 1
winSubLabel.ZIndex = 12
winSubLabel.Parent = winCard

local winReward = Instance.new("TextLabel")
winReward.Size = UDim2.new(1, 0, 0, 30)
winReward.Position = UDim2.new(0, 0, 0, 155)
winReward.BackgroundTransparency = 1
winReward.Font = Enum.Font.GothamBlack
winReward.TextSize = 22
winReward.TextColor3 = Color3.fromRGB(100, 255, 100)
winReward.Text = "+1 WIN"
winReward.TextTransparency = 1
winReward.ZIndex = 12
winReward.Parent = winCard

print("[TambangUI] Aktif - UI buatan user berhasil direferensikan!")

winScreen.Visible = false
local blurEffect = nil
local function toggleWinScreen(show, isWin, teamWinnerName)
	if show then
		winScreen.Visible = true
		
		-- Setup teks & warna
		if isWin then
			winTitle.Text = "VICTORY!"
			winTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
			cardStroke.Color = Color3.fromRGB(255, 215, 0)
			winCard.BackgroundColor3 = Color3.fromRGB(35, 30, 10)
			winReward.Text = "+1 Kemenangan"
			winReward.TextColor3 = Color3.fromRGB(100, 255, 100)
		else
			winTitle.Text = "DEFEAT"
			winTitle.TextColor3 = Color3.fromRGB(220, 50, 50)
			cardStroke.Color = Color3.fromRGB(220, 50, 50)
			winCard.BackgroundColor3 = Color3.fromRGB(35, 10, 10)
			winReward.Text = "+1 Kekalahan"
			winReward.TextColor3 = Color3.fromRGB(220, 100, 100)
		end
		winSubLabel.Text = "Tim " .. string.upper(teamWinnerName) .. " Memenangkan Pertandingan!"

		-- Blur
		if not blurEffect then
			blurEffect = Instance.new("BlurEffect")
			blurEffect.Name = "TambangBlur"
			blurEffect.Size = 0
			blurEffect.Parent = Lighting
		end
		TweenService:Create(blurEffect, TweenInfo.new(0.4), { Size = 20 }):Play()

		-- Fade In
		local tInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(winScreen, tInfo, { BackgroundTransparency = 0.5 }):Play()
		TweenService:Create(winCard, tInfo, { BackgroundTransparency = 0 }):Play()
		TweenService:Create(cardStroke, tInfo, { Transparency = 0 }):Play()
		TweenService:Create(winTitle, tInfo, { TextTransparency = 0, TextStrokeTransparency = 0.3 }):Play()
		TweenService:Create(winDivider, tInfo, { BackgroundTransparency = 0.3 }):Play()
		TweenService:Create(winSubLabel, tInfo, { TextTransparency = 0 }):Play()
		TweenService:Create(winReward, tInfo, { TextTransparency = 0 }):Play()
	else
		-- Fade Out
		local tInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(winScreen, tInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(winCard, tInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(cardStroke, tInfo, { Transparency = 1 }):Play()
		TweenService:Create(winTitle, tInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		TweenService:Create(winDivider, tInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(winSubLabel, tInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(winReward, tInfo, { TextTransparency = 1 }):Play()

		if blurEffect then
			local b = blurEffect
			blurEffect = nil
			local tw = TweenService:Create(b, tInfo, { Size = 0 })
			tw:Play()
			tw.Completed:Connect(function() b:Destroy() end)
		end
		
		task.delay(0.4, function() winScreen.Visible = false end)
	end
end

-- ═══════════════════════════════════════════════════════════
-- LOGIKA GAMEPLAY
-- ═══════════════════════════════════════════════════════════
local isPlaying = false
local cursorDir = 1
local cursorSpeed = 1.1
local canClick = true

local function randomizeHitZone()
	local newPos = math.random(12, 88) / 100
	TweenService:Create(hitZone, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
		Position = UDim2.new(newPos, 0, 0, 0)
	}):Play()
end

local function handlePull()
	if not isPlaying or not canClick then return end
	canClick = false

	local cursorPos = cursor.Position.X.Scale
	local hitCenter = hitZone.Position.X.Scale
	local dist = math.abs(hitCenter - cursorPos)

	local accuracy = 0
	local txt = ""
	local col = Color3.fromRGB(255, 255, 255)

	if dist <= 0.025 then
		accuracy = 1.0; txt = "PERFECT!"; col = Color3.fromRGB(255, 215, 0)
	elseif dist <= 0.07 then
		accuracy = 0.7; txt = "GOOD!"; col = Color3.fromRGB(100, 255, 100)
	elseif dist <= 0.14 then
		accuracy = 0.4; txt = "OK"; col = Color3.fromRGB(200, 200, 200)
	else
		accuracy = 0.0; txt = "MISS"; col = Color3.fromRGB(255, 80, 80)
	end

	-- Pindah hitZone HANYA jika berhasil
	if accuracy > 0 then
		randomizeHitZone()
		if loadedAnimTrack then
			loadedAnimTrack:Play()
			task.delay(0.5, function()
				if loadedAnimTrack and loadedAnimTrack.IsPlaying then loadedAnimTrack:Stop() end
			end)
		end
	end

	-- Feedback
	feedbackLabel.Text = txt
	feedbackLabel.TextColor3 = col
	feedbackLabel.TextTransparency = 0
	local savedTxt = txt
	task.delay(0.6, function()
		if feedbackLabel.Text == savedTxt then
			TweenService:Create(feedbackLabel, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
		end
	end)

	PullEvent:FireServer(accuracy)

	task.delay(0.18, function() canClick = true end)
end

if pullButton then pullButton.Activated:Connect(handlePull) end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if not isPlaying then return end
	if input.KeyCode == Enum.KeyCode.Space then handlePull() end
end)

-- Pergerakan jarum (hitZone TIDAK pindah saat pantul)
RunService.RenderStepped:Connect(function(dt)
	if not isPlaying then return end
	local x = cursor.Position.X.Scale + (cursorSpeed * cursorDir * dt)
	if x >= 1 then x = 1; cursorDir = -1; cursorSpeed = math.random(10, 16) / 10
	elseif x <= 0 then x = 0; cursorDir = 1; cursorSpeed = math.random(10, 16) / 10 end
	cursor.Position = UDim2.new(x, 0, 0.5, 0)
end)

-- ═══════════════════════════════════════════════════════════
-- SCORE UPDATE
-- ═══════════════════════════════════════════════════════════
ScoreUpdateEvent.OnClientEvent:Connect(function(score)
	-- score negatif = merah unggul, positif = putih unggul
	-- Normalize ke 0-1 range (threshold 25)
	local norm = math.clamp(score / 25, -1, 1) -- -1 sampai 1
	local redPct = math.clamp(0.5 - norm * 0.5, 0.05, 0.95)
	local whitePct = math.clamp(0.5 + norm * 0.5, 0.05, 0.95)

	TweenService:Create(redFill, TweenInfo.new(0.2), { Size = UDim2.new(redPct, 0, 1, 0) }):Play()
	TweenService:Create(whiteFill, TweenInfo.new(0.2), { Size = UDim2.new(whitePct, 0, 1, 0) }):Play()
end)

-- ═══════════════════════════════════════════════════════════
-- TOGGLE GUI
-- ═══════════════════════════════════════════════════════════
local hiddenGuis = {}

local function ToggleOtherGuis(show)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, show)
	if show then
		-- Jangan pernah kembalikan Backpack bawaan agar custom inventory tidak tertimpa
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end
	
	if not show then
		hiddenGuis = {}
		for _, gui in ipairs(playerGui:GetChildren()) do
			if gui:IsA("ScreenGui") and gui.Name ~= "TambangUI" and gui.Enabled then
				hiddenGuis[gui] = true
				gui.Enabled = false
			end
		end
	else
		for gui, _ in pairs(hiddenGuis) do
			if gui and gui.Parent then gui.Enabled = true end
		end
		hiddenGuis = {}
	end
	if player.Character then
		local head = player.Character:FindFirstChild("Head")
		if head then
			local bb = head:FindFirstChild("GlobalTitleBillboard")
			if bb then bb.Enabled = show end
		end
	end
end

-- ═══════════════════════════════════════════════════════════
-- EVENT LISTENERS
-- ═══════════════════════════════════════════════════════════
ShowUIEvent.OnClientEvent:Connect(function()
	ToggleOtherGuis(false)
	winScreen.Visible = false
	screenGui.Enabled = true

	-- Pastikan semua frame visible (jaga-jaga kalau di desain diset false)
	container.Visible = true
	scoreContainer.Visible = true
	barBg.Visible = true

	isPlaying = true
	feedbackLabel.Text = ""
	feedbackLabel.TextTransparency = 1
	cursor.Position = UDim2.new(0, 0, 0.5, 0)
	hitZone.Position = UDim2.new(0.5, 0, 0, 0)
	redFill.Size = UDim2.new(0.5, 0, 1, 0)
	whiteFill.Size = UDim2.new(0.5, 0, 1, 0)

	print("[TambangUI] ShowUI diterima! GUI seharusnya muncul sekarang.")

	loadedAnimTrack = nil
	if player.Character then
		local hum = player.Character:FindFirstChild("Humanoid")
		if hum then
			local anim = Instance.new("Animation")
			anim.AnimationId = PULL_ANIMATION_ID
			local animator = hum:FindFirstChild("Animator") or Instance.new("Animator", hum)
			loadedAnimTrack = animator:LoadAnimation(anim)
		end
	end
end)

HideUIEvent.OnClientEvent:Connect(function()
	screenGui.Enabled = false
	isPlaying = false
	loadedAnimTrack = nil
	ToggleOtherGuis(true)
end)

GameEndEvent.OnClientEvent:Connect(function(winnerTeam)
	isPlaying = false

	if loadedAnimTrack then
		loadedAnimTrack:Stop()
	end

	-- Sembunyikan bar & tombol
	container.Visible = false

	-- Cek apakah player ini ada di tim yang menang
	local isWin = false
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		local pZ = player.Character.HumanoidRootPart.Position.Z
		-- CenterLine arena Tarik Tambang ada di Z = -500
		-- Tim Merah start di -540 (negatif lebih kecil dari -500)
		-- Tim Putih start di -460 (lebih besar dari -500)
		local pTeam = (pZ < -500) and "Merah" or "Putih"
		if string.lower(pTeam) == string.lower(winnerTeam) then
			isWin = true
		end
	end

	-- Tampilkan GUI kemenangan
	toggleWinScreen(true, isWin, winnerTeam)

	task.delay(4, function()
		toggleWinScreen(false, isWin, winnerTeam)
		task.delay(0.4, function()
			container.Visible = true
			screenGui.Enabled = false
			ToggleOtherGuis(true)
			loadedAnimTrack = nil
		end)
	end)
end)

print("[TambangUI] Aktif!")
