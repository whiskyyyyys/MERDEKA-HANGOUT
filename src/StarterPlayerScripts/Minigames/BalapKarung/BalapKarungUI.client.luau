-- ============================================================
-- BalapKarungUI.client.luau
-- UI & Logika Client untuk Minigame Balap Karung (Power Bar)
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Akses PlayerModule untuk menonaktifkan kontrol (W, A, S, D, dll)
local PlayerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local controls = PlayerModule:GetControls()

-- ─────────────────────────────────────────────────────────
-- MENUNGGU FOLDER & EVENT
-- ─────────────────────────────────────────────────────────
local minigamesFolder = ReplicatedStorage:WaitForChild("Minigames")
local balapKarungFolder = minigamesFolder:WaitForChild("BalapKarung")
local eventsFolder = balapKarungFolder:WaitForChild("Events")

local ShowUIEvent = eventsFolder:WaitForChild("ShowUI")
local HideUIEvent = eventsFolder:WaitForChild("HideUI")
local GameEndEvent = eventsFolder:WaitForChild("GameEndEvent")
local RequestJumpEvent = eventsFolder:WaitForChild("RequestJump")

-- ─────────────────────────────────────────────────────────
-- MEMBUAT GUI SECARA DINAMIS
-- ─────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BalapKarungUI"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false
screenGui.Parent = playerGui

local function makeCorner(parent, radius)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = radius or UDim.new(1, 0)
end

-- Tombol Lompat Acak (Whack-a-Mole)
local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local actionBtn = Instance.new("ImageButton")
actionBtn.Name = "JumpBtn"
actionBtn.AnchorPoint = Vector2.new(0.5, 0.5)
actionBtn.Position = UDim2.new(0.5, 0, 0.8, 0)
actionBtn.Size = UDim2.new(0, 65, 0, 65)
actionBtn.BackgroundColor3 = Color3.fromRGB(240, 150, 50)
actionBtn.Parent = screenGui
makeCorner(actionBtn, UDim.new(0.5, 0)) -- Buat bulat

-- Beri gradien agar lebih cantik
local btnGrad = Instance.new("UIGradient", actionBtn)
btnGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 80)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 100, 30))
})
btnGrad.Rotation = 45

local btnStroke = Instance.new("UIStroke", actionBtn)
btnStroke.Thickness = 4
btnStroke.Color = Color3.fromRGB(255, 255, 255)
btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Tambahkan teks/icon ke dalam tombol
local iconText = Instance.new("TextLabel")
iconText.Size = UDim2.new(1, 0, 1, 0)
iconText.BackgroundTransparency = 1
iconText.Text = "TAP!"
iconText.TextColor3 = Color3.fromRGB(255, 255, 255)
iconText.Font = Enum.Font.GothamBlack
iconText.TextSize = 22
iconText.Parent = actionBtn
iconText.ZIndex = 2

-- ═══════════════════════════════════════════════════════════
-- PODIUM GUI (PREMIUM GLASSMORPHISM)
-- ═══════════════════════════════════════════════════════════

local winGui = playerGui:WaitForChild("BalapKarungWinGui")
winGui.Enabled = false

local overlay = winGui:WaitForChild("Overlay")
overlay.Visible = false
local defaultOverlayTransparency = overlay.BackgroundTransparency

local podiumFrame = winGui:WaitForChild("PodiumFrame")
podiumFrame.Visible = false

local slots = {}
local coinLabels = {}
local originalRowData = {}

for i = 1, 3 do
	local row = podiumFrame:WaitForChild("PlayerSlot_" .. i)
	local nameLabel = row:WaitForChild("PlayerName")
	slots[i] = nameLabel
	
	local coinContainer = row:WaitForChild("CoinContainer")
	local coinText = coinContainer:WaitForChild("CoinAmount")
	coinLabels[i] = coinText
	
	-- Simpan warna dan setting asli desain buatan user
	local rowStroke = row:FindFirstChildOfClass("UIStroke")
	originalRowData[i] = {
		bg = row.BackgroundColor3,
		bgTrans = row.BackgroundTransparency,
		strokeColor = rowStroke and rowStroke.Color,
		strokeTrans = rowStroke and rowStroke.Transparency
	}
end

-- ─────────────────────────────────────────────────────────
-- LOGIKA GAME (RANDOM BUTTON)
-- ─────────────────────────────────────────────────────────
local isPlaying = false
local canJump = true
local jumpCooldown = 0.3

local function MoveButtonRandomly()
	-- X: 0.1 sampai 0.9, Y: 0.2 sampai 0.8
	local randomX = math.random(10, 90) / 100
	local randomY = math.random(20, 80) / 100
	actionBtn.Position = UDim2.new(randomX, 0, randomY, 0)
end

local function PerformJump()
	if not isPlaying or not canJump then return end
	canJump = false
	
	-- Pindahkan tombol secara acak
	MoveButtonRandomly()
	
	-- Kirim dorongan maksimal (1.0) ke server setiap dipencet (opsional)
	RequestJumpEvent:FireServer(1.0)
	
	-- EKSEKUSI FISIKA LOMPATAN DI CLIENT (Pasti bekerja)
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local hrp = char.HumanoidRootPart
		local hum = char:FindFirstChild("Humanoid")
		
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		
		-- Kalkulasi dorongan (40 ke depan, 35 ke atas agar tidak terlalu tinggi)
		local jumpVector = (hrp.CFrame.LookVector * 40) + Vector3.new(0, 35, 0)
		hrp:ApplyImpulse(jumpVector * hrp.AssemblyMass)
	end
	
	-- Efek tombol dipencet
	local originalSize = actionBtn.Size
	actionBtn.Size = UDim2.new(0, 55, 0, 55)
	task.delay(0.1, function() actionBtn.Size = originalSize end)
	
	-- Cooldown cepat
	task.wait(jumpCooldown)
	canJump = true
end

-- Klik Tombol Saja (Tidak perlu space, karena ini minigame mencet tombol di layar)
actionBtn.Activated:Connect(PerformJump)

-- ─────────────────────────────────────────────────────────
-- EVENT LISTENER
-- ─────────────────────────────────────────────────────────
local StarterGui = game:GetService("StarterGui")
local hiddenGuis = {}

ShowUIEvent.OnClientEvent:Connect(function()
	screenGui.Enabled = true
	isPlaying = true
	canJump = true
	MoveButtonRandomly()
	podiumFrame.Visible = false
	overlay.Visible = false
	actionBtn.Visible = true
	
	-- Matikan kontrol jalan/lari bawaan Roblox
	controls:Disable()
	
	-- Sembunyikan CoreGui (Chat, Leaderboard, dll)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	
	-- Sembunyikan UI lain di PlayerGui
	hiddenGuis = {}
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and gui.Enabled and gui.Name ~= "BalapKarungUI" then
			gui.Enabled = false
			table.insert(hiddenGuis, gui)
		end
	end
	
	print("[BalapKarungUI] Game dimulai, kontrol dimatikan & UI disembunyikan.")
end)

HideUIEvent.OnClientEvent:Connect(function()
	screenGui.Enabled = false
	winGui.Enabled = false
	isPlaying = false
end)

GameEndEvent.OnClientEvent:Connect(function(winners, rewardData)
	isPlaying = false
	actionBtn.Visible = false
	
	-- Tampilkan overlay gelap + podium di winGui
	winGui.Enabled = true
	overlay.Visible = true
	podiumFrame.Visible = true
	
	-- Animasi slide-in dari atas
	podiumFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
	TweenService:Create(podiumFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()
	
	-- Update isi slot podium satu per satu (efek reveal)
	for i = 1, 3 do
		if winners[i] then
			slots[i].Text = winners[i]
			
			-- Tampilkan coin reward
			local coinAmount = rewardData and rewardData[winners[i]] or 0
			coinLabels[i].Text = "\xF0\x9F\x92\xB0 +" .. coinAmount
			
			-- Highlight jika ini kita
			if winners[i] == player.Name then
				local row = slots[i].Parent
				row.BackgroundColor3 = Color3.fromRGB(25, 60, 25)
				row.BackgroundTransparency = 0
				local rowStroke = row:FindFirstChildOfClass("UIStroke")
				if rowStroke then
					rowStroke.Color = Color3.fromRGB(100, 255, 100)
					rowStroke.Transparency = 0
				end
			end
		else
			slots[i].Text = "---"
			coinLabels[i].Text = ""
		end
	end
	
	task.wait(5)
	
	-- Animasi slide-out ke bawah
	TweenService:Create(podiumFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, 1.5, 0)
	}):Play()
	TweenService:Create(overlay, TweenInfo.new(0.4), {
		BackgroundTransparency = 1
	}):Play()
	task.wait(0.4)
	
	podiumFrame.Visible = false
	overlay.Visible = false
	overlay.BackgroundTransparency = defaultOverlayTransparency -- Reset untuk pemakaian berikutnya
	screenGui.Enabled = false
	winGui.Enabled = false
	actionBtn.Visible = true
	
	-- Reset warna row ke desain aslinya
	for i = 1, 3 do
		local row = slots[i].Parent
		local orig = originalRowData[i]
		row.BackgroundColor3 = orig.bg
		row.BackgroundTransparency = orig.bgTrans
		local rowStroke = row:FindFirstChildOfClass("UIStroke")
		if rowStroke and orig.strokeColor then
			rowStroke.Color = orig.strokeColor
			rowStroke.Transparency = orig.strokeTrans
		end
	end
	
	-- Kembalikan kontrol pemain
	controls:Enable()
	
	-- Kembalikan CoreGui
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	-- Pastikan Backpack bawaan tetap false agar custom inventory tidak rusak
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	
	-- Munculkan UI yang disembunyikan sebelumnya
	for _, gui in ipairs(hiddenGuis) do
		if gui and gui.Parent then
			gui.Enabled = true
		end
	end
	hiddenGuis = {}
end)
