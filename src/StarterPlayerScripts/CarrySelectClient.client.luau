-- ============================================================
-- CarrySelectClient.client.luau
-- GUI pilihan carry yang berdiri sendiri (standalone)
-- Dibuat 100% dari script, responsif, dan muncul di kanan layar
-- ============================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local carrySelectSignal = playerGui:WaitForChild("CarrySelectSignal", 30)
if not carrySelectSignal then
	warn("[CarrySelect] CarrySelectSignal not found! Carry selection disabled.")
	return
end

local CarryReplic = ReplicatedStorage:WaitForChild("CarryReplic")
local CarryRemotes = CarryReplic:WaitForChild("CarryRemotes")
local CarryRemote = CarryRemotes:WaitForChild("CarryRemote")
local CarryChoicesFolder = CarryReplic:WaitForChild("CarryChoices")

-- ============================================================
-- BUAT SCREEN GUI
-- ============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CarrySelectGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 50
screenGui.Enabled = false
screenGui.Parent = playerGui

-- Overlay gelap di belakang popup
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.BorderSizePixel = 0
overlay.ZIndex = 1
overlay.Parent = screenGui

-- Panel utama di sisi kanan layar
local panel = Instance.new("Frame")
panel.Name = "Panel"
-- Responsive width: 80% layar hp, maksimal 320px
panel.Size = UDim2.new(0.8, 0, 0, 0) 
panel.Position = UDim2.new(1.5, 0, 0.5, 0) -- Mulai dari luar layar kanan
panel.AnchorPoint = Vector2.new(1, 0.5)
panel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
panel.BackgroundTransparency = 0.05
panel.ClipsDescendants = true
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.ZIndex = 10
panel.Parent = screenGui

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(320, 9999)
sizeConstraint.MinSize = Vector2.new(240, 0)
sizeConstraint.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 16)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(80, 80, 110)
panelStroke.Thickness = 2
panelStroke.Transparency = 0.2
panelStroke.Parent = panel

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingTop = UDim.new(0, 20)
panelPadding.PaddingBottom = UDim.new(0, 20)
panelPadding.PaddingLeft = UDim.new(0, 18)
panelPadding.PaddingRight = UDim.new(0, 18)
panelPadding.Parent = panel

local panelLayout = Instance.new("UIListLayout")
panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
panelLayout.Padding = UDim.new(0, 12)
panelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
panelLayout.Parent = panel

-- Header: Avatar + Teks
local headerFrame = Instance.new("Frame")
headerFrame.Size = UDim2.new(1, 0, 0, 60)
headerFrame.BackgroundTransparency = 1
headerFrame.LayoutOrder = 0
headerFrame.ZIndex = 11
headerFrame.Parent = panel

local avatarImg = Instance.new("ImageLabel")
avatarImg.Size = UDim2.new(0, 56, 0, 56)
avatarImg.Position = UDim2.new(0, 0, 0.5, 0)
avatarImg.AnchorPoint = Vector2.new(0, 0.5)
avatarImg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
avatarImg.ZIndex = 12
avatarImg.Parent = headerFrame
Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -70, 0, 26)
titleLabel.Position = UDim2.new(0, 70, 0, 4)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "PILIH GAYA CARRY"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18 -- Diperbesar sedikit
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 12
titleLabel.Parent = headerFrame

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Size = UDim2.new(1, -70, 0, 20)
subtitleLabel.Position = UDim2.new(0, 70, 0, 32)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "Gendong siapa?"
subtitleLabel.RichText = true
subtitleLabel.Font = Enum.Font.Gotham
subtitleLabel.TextSize = 14 -- Diperbesar sedikit
subtitleLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
subtitleLabel.TextWrapped = true
subtitleLabel.ZIndex = 12
subtitleLabel.Parent = headerFrame

-- Garis Pemisah
local separator = Instance.new("Frame")
separator.Size = UDim2.new(1, 0, 0, 2)
separator.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
separator.BorderSizePixel = 0
separator.LayoutOrder = 1
separator.ZIndex = 11
separator.Parent = panel
Instance.new("UICorner", separator).CornerRadius = UDim.new(1, 0)

-- Container untuk tombol-tombol carry
local buttonsContainer = Instance.new("Frame")
buttonsContainer.Size = UDim2.new(1, 0, 0, 0)
buttonsContainer.BackgroundTransparency = 1
buttonsContainer.AutomaticSize = Enum.AutomaticSize.Y
buttonsContainer.LayoutOrder = 2
buttonsContainer.ZIndex = 11
buttonsContainer.Parent = panel

local btnLayout = Instance.new("UIListLayout")
btnLayout.SortOrder = Enum.SortOrder.LayoutOrder
btnLayout.Padding = UDim.new(0, 10)
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.Parent = buttonsContainer

-- Tombol Batal di paling bawah
local cancelBtnContainer = Instance.new("Frame")
cancelBtnContainer.Size = UDim2.new(1, 0, 0, 42)
cancelBtnContainer.BackgroundTransparency = 1
cancelBtnContainer.LayoutOrder = 3
cancelBtnContainer.ZIndex = 11
cancelBtnContainer.Parent = panel

local cancelBtn = Instance.new("TextButton")
cancelBtn.Size = UDim2.new(1, 0, 1, 0)
cancelBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
cancelBtn.Text = "BATAL"
cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.TextSize = 16 -- Diperbesar sedikit
cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelBtn.ZIndex = 12
cancelBtn.Parent = cancelBtnContainer
Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 10)

-- ============================================================
-- ANIMASI & LOGIKA
-- ============================================================
local isOpen = false
local currentTarget = nil

local function getThumbnail(userId)
	if typeof(userId) ~= "number" or userId <= 0 then return "" end
	local ok, content = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end)
	return ok and content or ""
end

local function closeCarrySelect()
	if not isOpen then return end
	isOpen = false
	currentTarget = nil

	-- Animasi slide out ke kanan
	local slideTween = TweenService:Create(panel, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = UDim2.new(1.5, 0, 0.5, 0)
	})
	local overlayTween = TweenService:Create(overlay, TweenInfo.new(0.2), {BackgroundTransparency = 1})

	slideTween:Play()
	overlayTween:Play()

	slideTween.Completed:Once(function()
		screenGui.Enabled = false
	end)
end

local function openCarrySelect(targetPlayer)
	if isOpen then return end
	if not targetPlayer then return end

	isOpen = true
	currentTarget = targetPlayer

	-- Set header info
	subtitleLabel.Text = "Gendong <b>" .. targetPlayer.DisplayName .. "</b>"
	avatarImg.Image = getThumbnail(targetPlayer.UserId)

	-- Bersihkan tombol lama
	for _, child in ipairs(buttonsContainer:GetChildren()) do
		if child:IsA("GuiButton") then
			child:Destroy()
		end
	end

	-- Buat tombol untuk setiap pilihan carry (Hanya ModuleScript)
	local order = 1
	for _, choice in ipairs(CarryChoicesFolder:GetChildren()) do
		if choice:IsA("ModuleScript") then
			local btn = Instance.new("TextButton")
			btn.Size = UDim2.new(1, 0, 0, 48) -- Lebih tinggi sedikit agar mudah ditekan di HP
			btn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.Font = Enum.Font.GothamSemibold
			btn.TextSize = 17 -- Teks diperbesar
			btn.Text = "🤝  " .. choice.Name
			btn.LayoutOrder = order
			btn.ZIndex = 12
			btn.AutoButtonColor = false
			btn.Parent = buttonsContainer
			
			local btnStroke = Instance.new("UIStroke")
			btnStroke.Color = Color3.fromRGB(70, 70, 90)
			btnStroke.Thickness = 1
			btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			btnStroke.Parent = btn
			
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

			-- Efek hover
			btn.MouseEnter:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(65, 65, 90)}):Play()
			end)
			btn.MouseLeave:Connect(function()
				TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 45, 60)}):Play()
			end)

			btn.MouseButton1Click:Connect(function()
				-- Flash efek klik
				TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = Color3.fromRGB(46, 204, 113)}):Play()
				task.wait(0.15)

				CarryRemote:FireServer("RequestCarry", currentTarget, choice.Name)
				closeCarrySelect()
			end)

			order = order + 1
		end
	end

	-- Tampilkan GUI
	screenGui.Enabled = true
	overlay.BackgroundTransparency = 1
	panel.Position = UDim2.new(1.5, 0, 0.5, 0) -- Pastikan mulai dari luar layar

	-- Animasi slide in dari kanan
	TweenService:Create(overlay, TweenInfo.new(0.25), {BackgroundTransparency = 0.5}):Play()
	TweenService:Create(panel, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.98, 0, 0.5, 0) -- Slide ke dalam di sisi kanan (margin 2%)
	}):Play()
end

-- Tombol Batal
cancelBtn.MouseButton1Click:Connect(function()
	closeCarrySelect()
end)

-- Klik overlay = tutup
overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		closeCarrySelect()
	end
end)

-- Hover efek tombol batal
cancelBtn.MouseEnter:Connect(function()
	TweenService:Create(cancelBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(220, 70, 70)}):Play()
end)
cancelBtn.MouseLeave:Connect(function()
	TweenService:Create(cancelBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
end)

-- ============================================================
-- LISTEN SINYAL DARI AVATAR MENU
-- ============================================================
carrySelectSignal.Event:Connect(function(targetPlayer)
	if targetPlayer and typeof(targetPlayer) == "Instance" and targetPlayer:IsA("Player") then
		openCarrySelect(targetPlayer)
	else
		warn("[CarrySelect] Invalid targetPlayer received:", targetPlayer)
	end
end)

print("[CarrySelectClient] Standalone Carry Selection GUI loaded (Responsive Right-Side)!")
