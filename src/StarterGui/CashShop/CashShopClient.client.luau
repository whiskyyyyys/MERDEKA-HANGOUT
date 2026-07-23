local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local gui = script.Parent
local frame = gui:WaitForChild("Frame")
local closeFrame = frame:WaitForChild("CloseFrame")
local closeBtn = closeFrame:WaitForChild("CloseButton")
local list = frame:WaitForChild("List")

local notificationBuy = gui:WaitForChild("NotificationBuy")
local notifLabel = notificationBuy:WaitForChild("Label")
local btnYes = notificationBuy:WaitForChild("YES"):WaitForChild("Label"):WaitForChild("TextButton")
local btnNo = notificationBuy:WaitForChild("NO"):WaitForChild("Label"):WaitForChild("TextButton")

local selectedProductId = nil
local isAnimating = false

-- Ganti angka 0 di bawah ini dengan Product ID asli dari Developer Products game Anda
local PRODUCT_IDS = {
	["1"] = 111111, -- Ganti dengan Product ID asli untuk paket Cash 1
	["2"] = 222222, -- Ganti dengan Product ID asli untuk paket Cash 2
	["3"] = 333333, -- Ganti dengan Product ID asli untuk paket Cash 3
	["4"] = 444444, -- Ganti dengan Product ID asli untuk paket Cash 4
	["5"] = 555555, -- Ganti dengan Product ID asli untuk paket Cash 5
	["6"] = 666666  -- Ganti dengan Product ID asli untuk paket Cash 6
}

local CASH_AMOUNTS = {
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

-- Anchor point center
notificationBuy.AnchorPoint = Vector2.new(0.5, 0.5)
notificationBuy.Position = UDim2.new(0.5, 0, 0.5, 0)

frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)

-- Buat UIScale
local frameScale = frame:FindFirstChild("UIScale") or Instance.new("UIScale")
frameScale.Parent = frame

local notifScale = notificationBuy:FindFirstChild("UIScale") or Instance.new("UIScale")
notifScale.Parent = notificationBuy

local tweenInfoPop = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tweenInfoHide = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

-- Fungsi memunculkan Notif (dengan animasi slide up)
local function showNotification()
	isAnimating = true
	notificationBuy.Visible = true
	notifScale.Scale = 0
	TweenService:Create(notifScale, tweenInfoPop, {Scale = 1}):Play()
	
	-- Animasi menyembunyikan frame cash
	local hideFrame = TweenService:Create(frameScale, tweenInfoHide, {Scale = 0})
	hideFrame:Play()
	task.delay(0.3, function()
		if notificationBuy.Visible then
			frame.Visible = false 
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
		-- Munculkan kembali list cash dengan animasi
		frame.Visible = true
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
local blurEffect = Lighting:FindFirstChild("CashShopBlur")
local blurTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function updateBlur()
	if gui.Enabled then
		-- Tambah efek Blur
		if not blurEffect then
			blurEffect = Instance.new("BlurEffect")
			blurEffect.Name = "CashShopBlur"
			blurEffect.Size = 0
			blurEffect.Parent = Lighting
		end
		TweenService:Create(blurEffect, blurTweenInfo, {Size = 15}):Play()
		
		-- Animasi buka Shop
		if not notificationBuy.Visible then
			frame.Visible = true
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
		frame.Visible = false
		notificationBuy.Visible = false
	end
end

-- Pastikan dalam kondisi tertutup dan bersih saat pertama kali mulai
gui.Enabled = false
frame.Visible = false
notificationBuy.Visible = false
if blurEffect then
	blurEffect:Destroy()
	blurEffect = nil
end

gui:GetPropertyChangedSignal("Enabled"):Connect(updateBlur)
-- ==========================================

-- 1. Fungsikan tombol Close
closeBtn.Activated:Connect(function()
	local hideTween = TweenService:Create(frameScale, tweenInfoHide, {Scale = 0})
	hideTween:Play()
	task.delay(0.3, function()
		gui.Enabled = false
	end)
end)

-- 2. Fungsikan tombol Buy untuk setiap paket Cash
for i = 1, 6 do
	local itemStr = tostring(i)
	local itemFrame = list:FindFirstChild(itemStr)
	if itemFrame then
		
		local function onPackageClicked()
			selectedProductId = itemStr
			notifLabel.Text = "Buy " .. CASH_AMOUNTS[itemStr] .. " Cash?"
			showNotification()
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
	if isAnimating then return end
	hideNotification()
	if selectedProductId then
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local BuyCashWithCoins = ReplicatedStorage:WaitForChild("CashShop"):WaitForChild("BuyCashWithCoins")
		local packageIdStr = tostring(selectedProductId)
		local success, msg = BuyCashWithCoins:InvokeServer(packageIdStr)
		if success then
			print("[CashShop] Berhasil beli cash!")
		else
			warn("[CashShop] Gagal beli cash:", msg)
			-- Bisa tambahkan UI pesan error di masa depan jika perlu
		end
		selectedProductId = nil
	end
end)

-- 4. NO Button
btnNo.Activated:Connect(function()
	hideNotification()
	selectedProductId = nil
end)

print("[CashShop] Script CashShopClient berhasil dimuat dengan animasi keren UIScale.")
