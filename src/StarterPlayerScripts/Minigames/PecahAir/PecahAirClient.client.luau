-- ============================================================
-- PecahAirClient.client.luau
-- Logika Client: Efek Buta (Blindfold) & Jalan Sempoyongan (Dizzy)
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Tunggu event
local minigamesFolder = ReplicatedStorage:WaitForChild("Minigames")
local pecahAirFolder = minigamesFolder:WaitForChild("PecahAir")
local eventsFolder = pecahAirFolder:WaitForChild("Events")
local GameStartEvent = eventsFolder:WaitForChild("GameStartEvent")
local GameEndEvent = eventsFolder:WaitForChild("GameEndEvent")

local isGameRunning = false
local blindfoldGui = nil
local dizzyConnection = nil
local blinkThread = nil
local hiddenGuis = {}

-- ─────────────────────────────────────────────────────────
-- SETUP GUI BUTA
-- ─────────────────────────────────────────────────────────
local function setupBlindfold()
	if blindfoldGui then blindfoldGui:Destroy() end

	blindfoldGui = Instance.new("ScreenGui")
	blindfoldGui.Name = "PecahAirBlindfold"
	blindfoldGui.IgnoreGuiInset = true
	blindfoldGui.ResetOnSpawn = false
	blindfoldGui.DisplayOrder = 100

	local blackFrame = Instance.new("Frame")
	blackFrame.Size = UDim2.new(1, 0, 1, 0)
	blackFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	blackFrame.BackgroundTransparency = 0 -- Hitam pekat
	blackFrame.Parent = blindfoldGui

	blindfoldGui.Parent = player:WaitForChild("PlayerGui")
	return blackFrame
end

-- ─────────────────────────────────────────────────────────
-- GAME START
-- ─────────────────────────────────────────────────────────
local ENABLE_BLINDFOLD = false -- Kata user: efek buta ntar aja
local ENABLE_DIZZY = true      -- Diaktifkan untuk efek susah jalan lurus

local originalWalkSpeed = 16

GameStartEvent.OnClientEvent:Connect(function()
	isGameRunning = true
	
	-- Sembunyikan UI lain di PlayerGui
	hiddenGuis = {}
	local playerGui = player:WaitForChild("PlayerGui")
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "WinScreenGui" and gui.Name ~= "PecahAirBlindfold" then
			gui.Enabled = false
			table.insert(hiddenGuis, gui)
		end
	end

	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")

	-- Lambatkan jalan pemain
	originalWalkSpeed = hum.WalkSpeed
	hum.WalkSpeed = 5 -- Jalan sangat lambat

	-- 1. Mulai Efek Buta (jika diaktifkan)
	if ENABLE_BLINDFOLD then
		local blackScreen = setupBlindfold()

		if blinkThread then task.cancel(blinkThread) end
		blinkThread = task.spawn(function()
			while isGameRunning do
				-- Gelap selama waktu acak
				task.wait(math.random(2, 5))
				if not isGameRunning then break end

				-- Kilatan penglihatan (0.2 detik)
				blackScreen.BackgroundTransparency = 1
				task.wait(0.25)

				-- Kembali gelap
				if isGameRunning then
					blackScreen.BackgroundTransparency = 0
				end
			end
		end)
	end

	-- 2. Mulai Efek Pusing (Susah jalan lurus)
	if ENABLE_DIZZY then
		if dizzyConnection then dizzyConnection:Disconnect() end

		local timeAcc = 0
		dizzyConnection = RunService.RenderStepped:Connect(function(dt)
			if not isGameRunning then
				dizzyConnection:Disconnect()
				return
			end
			
			-- Bikin jalan nggak lurus
			if hum.MoveDirection.Magnitude > 0 then
				timeAcc = timeAcc + dt
				
				local swaySpeed = 4
				local swayIntensity = 1.0
				
				local sway = (math.sin(timeAcc * swaySpeed) + math.cos(timeAcc * swaySpeed * 1.3) * 0.5) * swayIntensity
				
				local cam = workspace.CurrentCamera
				if cam then
					-- Kamera digoyang SANGAT SEDIKIT saja biar tidak mual
					cam.CFrame = cam.CFrame * CFrame.Angles(0, math.rad(sway * 1.5), math.rad(sway * 0.5))
				end
				
				-- Belokkan arah jalan secara paksa (Berfungsi di PC dan Mobile)
				local originalDir = hum.MoveDirection
				if originalDir.Magnitude > 0.01 then
					local crookedDir = CFrame.Angles(0, math.rad(sway * 45), 0) * originalDir
					hum:Move(crookedDir, false)
				end
			end
		end)
	end

	print("[PecahAirClient] Efek Buta & Pusing diaktifkan!")
end)

-- ─────────────────────────────────────────────────────────
-- GAME END
-- ─────────────────────────────────────────────────────────
GameEndEvent.OnClientEvent:Connect(function(winners, rewardData, losers)
	isGameRunning = false

	if dizzyConnection then
		dizzyConnection:Disconnect()
		dizzyConnection = nil
	end

	-- Kembalikan kecepatan jalan
	local char = player.Character
	if char then
		local hum = char:FindFirstChild("Humanoid")
		if hum then hum.WalkSpeed = originalWalkSpeed end
	end

	if blinkThread then
		task.cancel(blinkThread)
		blinkThread = nil
	end

	if blindfoldGui then
		-- Hapus perlahan efek butanya
		local blackScreen = blindfoldGui:FindFirstChildWhichIsA("Frame")
		if blackScreen then
			TweenService:Create(blackScreen, TweenInfo.new(1), {BackgroundTransparency = 1}):Play()
			task.wait(1)
		end
		blindfoldGui:Destroy()
		blindfoldGui = nil
	end

	print("[PecahAirClient] Efek Buta & Pusing dinonaktifkan!")

	-- ─────────────────────────────────────────────────────────
	-- UI RESULT SIMPLE
	-- ─────────────────────────────────────────────────────────
	local resultGui = Instance.new("ScreenGui")
	resultGui.Name = "WinScreenGui"
	resultGui.IgnoreGuiInset = true
	resultGui.Parent = player:WaitForChild("PlayerGui")

	local bgFrame = Instance.new("Frame")
	bgFrame.Name = "BackgroundDarkener"
	bgFrame.Size = UDim2.new(1, 0, 1, 0)
	bgFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	bgFrame.BackgroundTransparency = 1
	bgFrame.Parent = resultGui

	TweenService:Create(bgFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0.5}):Play()

	local panelBox = Instance.new("Frame")
	panelBox.Name = "PanelWinnerBox"
	panelBox.Size = UDim2.new(0, 450, 0, 260)
	panelBox.Position = UDim2.new(0.5, 0, 0.5, 0)
	panelBox.AnchorPoint = Vector2.new(0.5, 0.5)
	panelBox.BackgroundColor3 = Color3.fromRGB(210, 15, 20) -- Merah Kemerdekaan
	panelBox.Parent = bgFrame
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.Name = "PanelCorner"
	uiCorner.CornerRadius = UDim.new(0, 20)
	uiCorner.Parent = panelBox
	
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Name = "PanelStroke"
	uiStroke.Color = Color3.fromRGB(255, 255, 255) -- Putih
	uiStroke.Thickness = 6
	uiStroke.Parent = panelBox

	local titleText = Instance.new("TextLabel")
	titleText.Name = "TitleLabel"
	titleText.Size = UDim2.new(1, 0, 0, 50)
	titleText.Position = UDim2.new(0, 0, 0, 15)
	titleText.BackgroundTransparency = 1
	titleText.Text = "🎉 HASIL PERTANDINGAN 🎉"
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255) -- Putih
	titleText.Font = Enum.Font.GothamBlack
	titleText.TextSize = 24
	titleText.Parent = panelBox
	
	local winnerNameLabel = Instance.new("TextLabel")
	winnerNameLabel.Name = "WinnerNameLabel"
	winnerNameLabel.Size = UDim2.new(1, 0, 0, 40)
	winnerNameLabel.Position = UDim2.new(0, 0, 0, 70)
	winnerNameLabel.BackgroundTransparency = 1
	winnerNameLabel.Text = "Winner: " .. ((#winners > 0) and string.upper(table.concat(winners, ", ")) or "TIDAK ADA")
	winnerNameLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Emas
	winnerNameLabel.Font = Enum.Font.GothamBold
	winnerNameLabel.TextSize = 28
	winnerNameLabel.Parent = panelBox
	
	local loserNameLabel = Instance.new("TextLabel")
	loserNameLabel.Name = "LoserNameLabel"
	loserNameLabel.Size = UDim2.new(1, 0, 0, 40)
	loserNameLabel.Position = UDim2.new(0, 0, 0, 115)
	loserNameLabel.BackgroundTransparency = 1
	loserNameLabel.Text = "Losers: " .. ((losers and #losers > 0) and table.concat(losers, ", ") or "TIDAK ADA")
	loserNameLabel.TextColor3 = Color3.fromRGB(200, 200, 200) -- Abu-abu
	loserNameLabel.Font = Enum.Font.GothamSemibold
	loserNameLabel.TextSize = 18
	loserNameLabel.TextWrapped = true
	loserNameLabel.Parent = panelBox
	
	local rewardText = Instance.new("TextLabel")
	rewardText.Name = "RewardTextLabel"
	rewardText.Size = UDim2.new(1, 0, 0, 40)
	rewardText.Position = UDim2.new(0, 0, 0, 170)
	rewardText.BackgroundTransparency = 1
	
	local prize = 0
	if #winners > 0 and rewardData and rewardData[winners[1]] then
		prize = rewardData[winners[1]]
	end
	
	rewardText.Text = "Mendapatkan: +" .. prize .. " Koin"
	rewardText.TextColor3 = Color3.fromRGB(255, 255, 255) -- Putih
	rewardText.Font = Enum.Font.GothamSemibold
	rewardText.TextSize = 20
	rewardText.Parent = panelBox

	-- Animasi Pop In Simple
	local uiScale = Instance.new("UIScale")
	uiScale.Name = "PanelScale"
	uiScale.Scale = 0
	uiScale.Parent = panelBox

	TweenService:Create(uiScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()

	-- Hapus GUI setelah 5 detik
	task.wait(4.5)

	TweenService:Create(uiScale, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0}):Play()
	TweenService:Create(bgFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()

	task.wait(0.5)
	resultGui:Destroy()
	
	-- Kembalikan UI yang tadi disembunyikan
	for _, gui in ipairs(hiddenGuis) do
		if gui and gui.Parent then
			gui.Enabled = true
		end
	end
	hiddenGuis = {}
end)
