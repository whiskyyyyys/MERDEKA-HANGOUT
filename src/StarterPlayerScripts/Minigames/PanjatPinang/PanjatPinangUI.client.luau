local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Target Waktu: 17 Agustus 2026 00:00:00 WIB
-- (Dalam hitungan mesin/UTC: 16 Agustus 2026 17:00:00)
local TARGET_TIME = os.time({
	year = 2026,
	month = 8,
	day = 16,
	hour = 17,
	min = 0,
	sec = 0
})

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── 1. Buat Notifikasi Pop-up (ScreenGui) Saat Ditolak ──
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PanjatPinangScreen"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local notifLabel = Instance.new("TextLabel")
notifLabel.Name = "Notif"
notifLabel.Size = UDim2.new(0, 400, 0, 60)
notifLabel.Position = UDim2.new(0.5, -200, 0, -100) -- Mulai di luar layar atas
notifLabel.AnchorPoint = Vector2.new(0.5, 0.5)
notifLabel.BackgroundTransparency = 0.2
notifLabel.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
notifLabel.Text = "🚨 PANJAT PINANG BELUM DIBUKA! 🚨\nTunggu hingga 17 Agustus 00:00 WIB"
notifLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
notifLabel.Font = Enum.Font.GothamBold
notifLabel.TextSize = 18
notifLabel.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = notifLabel

local stroke = Instance.new("UIStroke")
stroke.Thickness = 2
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Parent = notifLabel

local RSPanjat = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("PanjatPinang")
local Remotes = RSPanjat:WaitForChild("Remotes")
local EarlyAccessEvent = Remotes:WaitForChild("EarlyAccessAttempt")

local notifTweenIn = TweenService:Create(notifLabel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -200, 0.2, 0)})
local notifTweenOut = TweenService:Create(notifLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, -200, 0, -100)})

-- Hanya mengurus ScreenGui Notifikasi Penolakan saja
print("[PanjatPinangUI] Notifikasi layar aktif!")
