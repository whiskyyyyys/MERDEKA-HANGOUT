-- ============================================================
-- CashRewardUI.client.luau
-- Menampilkan notifikasi popup "+X Cash" saat mendapat Cash
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Remotes")
local CashReward = Remotes:WaitForChild("CashReward")

-- Buat ScreenGui untuk notifikasi
local rewardGui = Instance.new("ScreenGui")
rewardGui.Name = "CashRewardGui"
rewardGui.ResetOnSpawn = false
rewardGui.IgnoreGuiInset = true
rewardGui.Parent = player:WaitForChild("PlayerGui")

CashReward.OnClientEvent:Connect(function(amount, reason)
	if type(amount) ~= "number" or amount <= 0 then return end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 200, 0, 50)
	frame.Position = UDim2.new(0.5, 0, 0.7, 0)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundTransparency = 1
	frame.Parent = rewardGui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "+" .. tostring(amount) .. " Cash"
	if reason and reason ~= "Reward" then
		label.Text = label.Text .. "\n(" .. tostring(reason) .. ")"
	end
	label.TextColor3 = Color3.fromRGB(85, 255, 127) -- Hijau cerah
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0.2, 0)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Parent = frame
	
	-- Animasi muncul (Pop up dan naik ke atas)
	local startScale = Instance.new("UIScale")
	startScale.Scale = 0
	startScale.Parent = frame
	
	-- Randomize sedikit X position agar kalau ada banyak notif tidak terlalu menumpuk
	local randomXOffset = math.random(-50, 50)
	frame.Position = UDim2.new(0.5, randomXOffset, 0.7, 0)
	
	local targetPos = UDim2.new(0.5, randomXOffset, 0.5, 0)
	
	TweenService:Create(startScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	
	-- Pindah ke atas perlahan
	local moveTween = TweenService:Create(frame, TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos})
	moveTween:Play()
	
	-- Fade out setelah 1.5 detik
	task.delay(1.5, function()
		local fadeTween = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1})
		fadeTween:Play()
		fadeTween.Completed:Wait()
		frame:Destroy()
	end)
end)

print("[CashRewardUI] Berhasil dimuat.")
