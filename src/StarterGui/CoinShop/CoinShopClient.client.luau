local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local frameCoin = gui:WaitForChild("FrameCoin")
local closeFrame = frameCoin:WaitForChild("CloseFrame")
local closeBtn = closeFrame:WaitForChild("CloseButton")
local list = frameCoin:WaitForChild("List")

local notificationBuy = gui:WaitForChild("NotificationBuy")
local notifLabel = notificationBuy:WaitForChild("Label")
local btnYes = notificationBuy:WaitForChild("YES"):WaitForChild("Label"):WaitForChild("TextButton")
local btnNo = notificationBuy:WaitForChild("NO"):WaitForChild("Label"):WaitForChild("TextButton")

local selectedProductId = nil

-- Ganti angka 0 di bawah ini dengan Product ID asli dari Developer Products game Anda
local PRODUCT_IDS = {
	["1"] = 111111, -- Ganti dengan Product ID asli untuk 1 Coin (8 Robux)
	["2"] = 222222, -- Ganti dengan Product ID asli untuk 10 Coin (80 Robux)
	["3"] = 333333, -- Ganti dengan Product ID asli untuk 50 Coin (400 Robux)
	["4"] = 444444, -- Ganti dengan Product ID asli untuk 100 Coin (800 Robux)
	["5"] = 555555, -- Ganti dengan Product ID asli untuk 500 Coin (4000 Robux)
	["6"] = 666666  -- Ganti dengan Product ID asli untuk 1000 Coin (8000 Robux)
}

local COIN_AMOUNTS = {
	["1"] = "1",
	["2"] = "10",
	["3"] = "50",
	["4"] = "100",
	["5"] = "500",
	["6"] = "1000",
}

-- Sembunyikan notifikasi saat awal
notificationBuy.Visible = false

local Lighting = game:GetService("Lighting")

local isAnimating = false

-- Anchor point center
notificationBuy.AnchorPoint = Vector2.new(0.5, 0.5)
notificationBuy.Position = UDim2.new(0.5, 0, 0.5, 0)

frameCoin.AnchorPoint = Vector2.new(0.5, 0.5)
frameCoin.Position = UDim2.new(0.5, 0, 0.5, 0)

-- Buat UIScale
local frameScale = frameCoin:FindFirstChild("UIScale") or Instance.new("UIScale")
frameScale.Parent = frameCoin

local notifScale = notificationBuy:FindFirstChild("UIScale") or Instance.new("UIScale")
notifScale.Parent = notificationBuy

local tweenInfoPop = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenInfoHide = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

-- Fungsi memunculkan Notif (dengan animasi pop-up keren)
local function showNotification()
	isAnimating = true
	notificationBuy.Visible = true
	notifScale.Scale = 0
	TweenService:Create(notifScale, tweenInfoPop, {Scale = 1}):Play()
	
	-- Animasi menyembunyikan frame koin
	local hideFrame = TweenService:Create(frameScale, tweenInfoHide, {Scale = 0})
	hideFrame:Play()
	task.delay(0.3, function()
		if notificationBuy.Visible then
			frameCoin.Visible = false 
		end
		isAnimating = false
	end)
end

-- Fungsi menyembunyikan Notif (kembali ke list)
local function hideNotification()
	isAnimating = true
	local hideNotif = TweenService:Create(notifScale, tweenInfoHide, {Scale = 0})
	hideNotif:Play()
	
	task.delay(0.3, function()
		notificationBuy.Visible = false
		-- Munculkan kembali list koin dengan animasi
		frameCoin.Visible = true
		frameScale.Scale = 0
		TweenService:Create(frameScale, tweenInfoPop, {Scale = 1}):Play()
		task.delay(0.4, function()
			isAnimating = false
		end)
	end)
end

-- ==========================================
-- EFEK BLUR & ANIMASI BUKA/TUTUP SHOP
-- ==========================================
local blurEffect = Lighting:FindFirstChild("CoinShopBlur")
local blurTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function updateBlur()
	if gui.Enabled then
		-- Tambah efek Blur
		if not blurEffect then
			blurEffect = Instance.new("BlurEffect")
			blurEffect.Name = "CoinShopBlur"
			blurEffect.Size = 0
			blurEffect.Parent = Lighting
		end
		TweenService:Create(blurEffect, blurTweenInfo, {Size = 15}):Play()
		
		-- Animasi buka Shop
		if not notificationBuy.Visible then
			frameCoin.Visible = true
			frameScale.Scale = 0
			TweenService:Create(frameScale, tweenInfoPop, {Scale = 1}):Play()
		end
	else
		-- Animasi tutup blur
		if blurEffect then
			TweenService:Create(blurEffect, blurTweenInfo, {Size = 0}):Play()
			task.delay(0.3, function()
				if blurEffect and not gui.Enabled then
					blurEffect:Destroy()
					blurEffect = nil
				end
			end)
		end
		
		-- Tutup semua gui
		frameCoin.Visible = false
		notificationBuy.Visible = false
	end
end

-- Pastikan dalam kondisi tertutup dan bersih saat pertama kali mulai
gui.Enabled = false
frameCoin.Visible = false
notificationBuy.Visible = false
if blurEffect then
	blurEffect:Destroy()
	blurEffect = nil
end

gui:GetPropertyChangedSignal("Enabled"):Connect(updateBlur)
-- ==========================================

-- 1. Fungsikan tombol Close
local uiScale = closeBtn:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
uiScale.Parent = closeBtn

closeBtn.MouseEnter:Connect(function()
	TweenService:Create(uiScale, TweenInfo.new(0.2), {Scale = 1.1}):Play()
end)
closeBtn.MouseLeave:Connect(function()
	TweenService:Create(uiScale, TweenInfo.new(0.2), {Scale = 1}):Play()
end)

closeBtn.Activated:Connect(function()
	-- Kembalikan ukuran asli kalau ditekan
	TweenService:Create(uiScale, TweenInfo.new(0.1), {Scale = 1}):Play()
	
	local hideTween = TweenService:Create(frameScale, tweenInfoHide, {Scale = 0})
	hideTween:Play()
	task.delay(0.3, function()
		gui.Enabled = false
	end)
end)

-- 2. Fungsikan tombol Buy untuk setiap paket Coin
for i = 1, 6 do
	local itemStr = tostring(i)
	local itemFrame = list:FindFirstChild(itemStr)
	if itemFrame then
		
		local function onPackageClicked()
			local productId = PRODUCT_IDS[itemStr]
			if productId and productId > 0 then
				selectedProductId = productId
				notifLabel.Text = "Buy " .. COIN_AMOUNTS[itemStr] .. " Coins?"
				showNotification()
			else
				warn("[CoinShop] Product ID untuk paket " .. itemStr .. " belum diatur di CoinShopClient!")
			end
		end

		local btnBuy = itemFrame:FindFirstChild("ButtonBuy")
		if btnBuy then
			btnBuy.Activated:Connect(onPackageClicked)
		end
		
		-- Buat seluruh frame bisa ditekan
		itemFrame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				onPackageClicked()
			end
		end)
	end
end

-- 3. YES Button
btnYes.Activated:Connect(function()
	hideNotification()
	if selectedProductId then
		MarketplaceService:PromptProductPurchase(player, selectedProductId)
		selectedProductId = nil
	end
end)

-- 4. NO Button
btnNo.Activated:Connect(function()
	hideNotification()
	selectedProductId = nil
end)

print("[CoinShop] Script CoinShopClient berhasil dimuat dengan animasi keren UIScale.")
