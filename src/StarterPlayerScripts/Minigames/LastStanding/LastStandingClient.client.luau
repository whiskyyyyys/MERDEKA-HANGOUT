-- ============================================================
-- LastStandingClient.client.luau
-- Logika Client: Menampilkan GUI Pemenang Last Standing
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Tunggu event
local minigamesFolder = ReplicatedStorage:WaitForChild("Minigames")
local lastStandingFolder = minigamesFolder:WaitForChild("LastStanding")
local eventsFolder = lastStandingFolder:WaitForChild("Events")
local GameEndEvent = eventsFolder:WaitForChild("GameEndEvent")

local hiddenGuis = {}

-- Sembunyikan UI saat mulai (GameStartEvent bisa ditambahkan jika perlu efek buta dll)
local GameStartEvent = eventsFolder:WaitForChild("GameStartEvent")
GameStartEvent.OnClientEvent:Connect(function()
	hiddenGuis = {}
	local playerGui = player:WaitForChild("PlayerGui")
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "WinScreenGui" then
			gui.Enabled = false
			table.insert(hiddenGuis, gui)
		end
	end
end)

-- ─────────────────────────────────────────────────────────
-- GAME END & UI RESULT SIMPLE
-- ─────────────────────────────────────────────────────────
GameEndEvent.OnClientEvent:Connect(function(winners, rewardData, losers)
	print("[LastStandingClient] Game Selesai! Menampilkan GUI Pemenang.")

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
	titleText.Text = "🎉 HASIL LAST STANDING 🎉"
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
	
	local rewardText = Instance.new("TextLabel")
	rewardText.Name = "RewardTextLabel"
	rewardText.Size = UDim2.new(1, 0, 0, 40)
	rewardText.Position = UDim2.new(0, 0, 0, 150)
	rewardText.BackgroundTransparency = 1
	
	local prize = 0
	if #winners > 0 and rewardData and rewardData[winners[1]] then
		prize = rewardData[winners[1]]
	end
	
	if prize > 0 then
		rewardText.Text = "Mendapatkan: +" .. prize .. " Cash"
	else
		rewardText.Text = "Coba lagi tahun depan!"
	end
	
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

print("[LastStandingClient] Siap!")
