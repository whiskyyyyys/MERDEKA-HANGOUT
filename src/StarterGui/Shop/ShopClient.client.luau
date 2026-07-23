local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = script.Parent
local frame = gui:WaitForChild("Frame")
local closeButton = frame:WaitForChild("CloseFrame"):WaitForChild("CloseButton")

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- Buat atau cari BlurEffect
local shopBlur = Lighting:FindFirstChild("ShopBlur")
if not shopBlur then
	shopBlur = Instance.new("BlurEffect")
	shopBlur.Name = "ShopBlur"
	shopBlur.Size = 0
	shopBlur.Parent = Lighting
end

-- Tambahkan ToggleEvent dan SyncEvent
local toggleEvent = Instance.new("BindableEvent")
toggleEvent.Name = "ToggleEvent"
toggleEvent.Parent = gui

local syncEvent = Instance.new("BindableEvent")
syncEvent.Name = "SyncEvent"
syncEvent.Parent = gui

gui.Enabled = false
frame.Visible = true

local isAnimating = false
local isOpen = false
local currentGiftTarget = nil
local originalTexts = {}

local function setShopState(state, giftTargetUserId)
	if isAnimating or isOpen == state then return end
	isAnimating = true
	isOpen = state
	currentGiftTarget = giftTargetUserId
	syncEvent:Fire(isOpen)

	if state then
		gui.Enabled = true
		frame.Position = UDim2.new(0.5, 0, -0.5, 0) -- Dari luar layar atas
		TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
		TweenService:Create(shopBlur, TweenInfo.new(0.3), {Size = 15}):Play()
		task.wait(0.4)
	else
		TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, -0.5, 0)}):Play()
		TweenService:Create(shopBlur, TweenInfo.new(0.3), {Size = 0}):Play()
		task.wait(0.3)
		gui.Enabled = false
	end
	isAnimating = false
end

toggleEvent.Event:Connect(setShopState)

if closeButton and closeButton:IsA("GuiButton") then
	closeButton.MouseButton1Click:Connect(function()
		setShopState(false)
	end)
end

-- Label Title (opsional) untuk menunjukkan kalau ini Gift
local titleLabel = frame:FindFirstChild("Title") or frame:FindFirstChild("Header")
local originalTitleText = "Shop"
if titleLabel and titleLabel:IsA("TextLabel") then
	originalTitleText = titleLabel.Text
end

-- Logika Pembelian
local buyRemote = ReplicatedStorage:WaitForChild("BuyShopItem", 5)
local checkRemote = ReplicatedStorage:WaitForChild("CheckShopOwned", 5)

local scrollingFrame = frame:WaitForChild("ScrollingFrame")
local buyButtons = {}
local itemFramesMap = {} -- Simpan referensi ke frameBuy

-- Helper visual untuk mengubah tombol menjadi OWNED
local function setOwnedVisual(frameBuy, btn)
	local label = frameBuy:FindFirstChild("Label") or frameBuy:FindFirstChildWhichIsA("TextLabel")
	if label then
		label.Text = "OWNED"
	elseif btn:IsA("TextButton") then
		btn.Text = "OWNED"
	end
	
	local icon = frameBuy:FindFirstChild("ImageLabel")
	if icon then
		icon.Visible = false
	end
	
	btn.Interactable = false
end

local function resetVisual(frameBuy, btn)
	local originalText = originalTexts[btn]
	if not originalText then return end
	
	local label = frameBuy:FindFirstChild("Label") or frameBuy:FindFirstChildWhichIsA("TextLabel")
	if label then
		label.Text = originalText
	elseif btn:IsA("TextButton") then
		btn.Text = originalText
	end
	
	local icon = frameBuy:FindFirstChild("ImageLabel")
	if icon then
		icon.Visible = true
	end
	
	btn.Interactable = true
end

-- Fungsi update status tombol
local function updateOwnedStatus()
	if not checkRemote then return end
	
	if titleLabel and titleLabel:IsA("TextLabel") then
		if currentGiftTarget then
			titleLabel.Text = "Gift Item"
		else
			titleLabel.Text = originalTitleText
		end
	end

	-- Reset semua tombol ke awal sebelum cek target!
	for itemName, btn in pairs(buyButtons) do
		if itemFramesMap[itemName] then
			resetVisual(itemFramesMap[itemName], btn)
		end
	end

	local success, ownedData = pcall(function()
		return checkRemote:InvokeServer(currentGiftTarget)
	end)
	
	if success and type(ownedData) == "table" then
		for itemName, isOwned in pairs(ownedData) do
			if isOwned and buyButtons[itemName] and itemFramesMap[itemName] then
				setOwnedVisual(itemFramesMap[itemName], buyButtons[itemName])
			end
		end
	end
end

for _, itemFrame in ipairs(scrollingFrame:GetChildren()) do
	if itemFrame:IsA("Frame") and itemFrame.Name ~= "UIListLayout" and itemFrame.Name ~= "UIAspectRatioConstraint" then
		local frameBuy = itemFrame:FindFirstChild("FrameBuy")
		if frameBuy then
			-- Cari tombol di dalam FrameBuy
			local buyButton = frameBuy:FindFirstChildWhichIsA("GuiButton") or frameBuy:FindFirstChild("TextButton")
			if buyButton then
				buyButtons[itemFrame.Name] = buyButton
				itemFramesMap[itemFrame.Name] = frameBuy
				
				local label = frameBuy:FindFirstChild("Label") or frameBuy:FindFirstChildWhichIsA("TextLabel")
				if label then
					originalTexts[buyButton] = label.Text
				elseif buyButton:IsA("TextButton") then
					originalTexts[buyButton] = buyButton.Text
				end
				
				buyButton.MouseButton1Click:Connect(function()
					if buyRemote then
						-- Mencegah spam click
						buyButton.Interactable = false
						
						local success, msg = buyRemote:InvokeServer(itemFrame.Name, currentGiftTarget)
						
						if not success and msg then
							warn("Shop:", msg)
							buyButton.Interactable = true
							-- Di sini kamu bisa tambahkan pop-up UI kalau koin tidak cukup
						else
							print("Berhasil beli:", itemFrame.Name)
							setOwnedVisual(frameBuy, buyButton)
						end
					end
				end)
			end
		end
	end
end

task.spawn(updateOwnedStatus)
toggleEvent.Event:Connect(function(state)
	if state then task.spawn(updateOwnedStatus) end
end)
