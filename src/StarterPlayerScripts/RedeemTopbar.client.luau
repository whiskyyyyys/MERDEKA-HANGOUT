-- ============================================================
-- RedeemTopbar.client.luau
-- StarterPlayerScripts/RedeemTopbar
-- Tombol Redeem di Topbar + GUI tema Kemerdekaan Indonesia
-- ============================================================

local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local TweenService       = game:GetService("TweenService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Lighting = game:GetService("Lighting")
local redeemBlur = Instance.new("BlurEffect")
redeemBlur.Name = "RedeemBlur"
redeemBlur.Size = 0
redeemBlur.Parent = Lighting

-- Remote
local redeemRemotes = ReplicatedStorage:WaitForChild("RedeemRemotes", 30)
if not redeemRemotes then
	warn("[RedeemTopbar] RedeemRemotes tidak ditemukan!")
	return
end
local RedeemCode = redeemRemotes:WaitForChild("RedeemCode")

-- ============================================================
-- WARNA & TEMA (Gaya Kartun / Outline Tebal)
-- ============================================================
local WARNA_MERAH   = Color3.fromRGB(240, 70, 70)
local WARNA_HIJAU   = Color3.fromRGB(100, 220, 100)
local WARNA_PUTIH   = Color3.fromRGB(255, 255, 255)
local WARNA_HITAM   = Color3.fromRGB(20, 20, 20)
local WARNA_ABU     = Color3.fromRGB(235, 235, 235)

-- ============================================================
-- SAMBUNGKAN KE GUI FISIK DI STARTERGUI
-- ============================================================
local RedeemScreenGui = playerGui:WaitForChild("RedeemScreenGui")
local MainContainerFrame = RedeemScreenGui:WaitForChild("MainContainerFrame")

-- Ambil referensi komponen
local TitleLabelText = MainContainerFrame:WaitForChild("TitleLabelText")
local SubtitleLabelText = MainContainerFrame:WaitForChild("SubtitleLabelText")
local InputBackgroundFrame = MainContainerFrame:WaitForChild("InputBackgroundFrame")
local CodeInputTextBox = InputBackgroundFrame:WaitForChild("CodeInputTextBox")
local SubmitRedeemButton = MainContainerFrame:WaitForChild("SubmitRedeemButton")
local StatusMessageLabel = MainContainerFrame:WaitForChild("StatusMessageLabel")
local CloseMenuButton = MainContainerFrame:WaitForChild("CloseMenuButton")
local ContainerStroke = MainContainerFrame:WaitForChild("ContainerStroke")

-- Efek Hover Tombol Klaim
SubmitRedeemButton.MouseEnter:Connect(function()
	TweenService:Create(SubmitRedeemButton, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(120, 240, 120) }):Play()
end)
SubmitRedeemButton.MouseLeave:Connect(function()
	TweenService:Create(SubmitRedeemButton, TweenInfo.new(0.1), { BackgroundColor3 = WARNA_HIJAU }):Play()
end)

-- Efek Hover Tombol Close
CloseMenuButton.MouseEnter:Connect(function()
	TweenService:Create(CloseMenuButton, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(255, 100, 100) }):Play()
end)
CloseMenuButton.MouseLeave:Connect(function()
	TweenService:Create(CloseMenuButton, TweenInfo.new(0.1), { BackgroundColor3 = WARNA_MERAH }):Play()
end)

-- ============================================================
-- ANIMASI OPEN / CLOSE
-- ============================================================
local isOpen = false

local function openGUI()
	if isOpen then return end
	isOpen = true
	RedeemScreenGui.Enabled = true
	MainContainerFrame.Visible = true -- Pastikan frame terlihat
	
	-- Animasi muncul dari atas
	MainContainerFrame.Size = UDim2.new(0, 360, 0, 240)
	MainContainerFrame.Position = UDim2.new(0.5, 0, -0.5, 0)
	
	TweenService:Create(redeemBlur, TweenInfo.new(0.3), { Size = 15 }):Play()
	TweenService:Create(MainContainerFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()

	CodeInputTextBox.Text = ""
	StatusMessageLabel.Text = ""
end

local function closeGUI()
	if not isOpen then return end
	isOpen = false
	
	-- Animasi kembali ke atas
	TweenService:Create(redeemBlur, TweenInfo.new(0.2), { Size = 0 }):Play()
	TweenService:Create(MainContainerFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(0.5, 0, -0.5, 0)
	}):Play()

	task.wait(0.2)
	MainContainerFrame.Visible = false -- Sembunyikan lagi sesuai permintaan
	RedeemScreenGui.Enabled = false
end

-- ============================================================
-- TOMBOL ACTIONS
-- ============================================================
local isProcessing = false

SubmitRedeemButton.Activated:Connect(function()
	if isProcessing then return end
	
	local code = CodeInputTextBox.Text
	if code == "" or #code < 2 then
		StatusMessageLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		StatusMessageLabel.Text = "Masukan kode terlebih dahulu!"
		return
	end

	isProcessing = true
	SubmitRedeemButton.Text = "Tunggu..."
	StatusMessageLabel.Text = ""

	local ok, result = pcall(function()
		return RedeemCode:InvokeServer(code)
	end)

	if ok and result and result.success then
		StatusMessageLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
		StatusMessageLabel.Text = "Berhasil: " .. result.message

		TweenService:Create(ContainerStroke, TweenInfo.new(0.2), { Color = WARNA_EMAS }):Play()
		task.wait(0.5)
		TweenService:Create(ContainerStroke, TweenInfo.new(0.3), { Color = WARNA_MERAH }):Play()
	else
		StatusMessageLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		local msg = (ok and result and result.message) or "Terjadi kesalahan!"
		StatusMessageLabel.Text = "Gagal: " .. msg
	end

	SubmitRedeemButton.Text = "KLAIM SEKARANG"
	isProcessing = false
end)

CloseMenuButton.Activated:Connect(function()
	closeGUI()
end)

-- Tidak ada overlay klik luar lagi

-- ============================================================
-- TOPBARPLUS ICON
-- ============================================================
local Icon = require(ReplicatedStorage:WaitForChild("TopbarPlus"):WaitForChild("Icon"))

local redeemIcon = Icon.new()
	:setRight() -- Di sebelah kanan agar tidak nabrak menu kiri
	:setImage("rbxthumb://type=Asset&id=89996216566721&w=150&h=150") -- Icon kado
	:modifyTheme({"IconImageScale", "Value", 0.9, "Deselected"})
	:modifyTheme({"IconImageScale", "Value", 0.9, "Selected"})
	:bindEvent("selected", function()
		openGUI()
	end)
	:bindEvent("deselected", function()
		closeGUI()
	end)

-- Sinkronisasi agar icon mengikuti state GUI (misal ditutup lewat tombol X)
MainContainerFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if MainContainerFrame.Visible then
		redeemIcon:select()
	else
		redeemIcon:deselect()
	end
end)

print("[RedeemTopbar] Berhasil memuat GUI Redeem dan Topbar Icon!")
