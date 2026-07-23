-- ============================================================
-- MHCoinTopbar.client.luau
-- Menampilkan total MHCoin secara global di Topbar menggunakan TopbarPlus
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Modul TopbarPlus
local Icon = require(ReplicatedStorage:WaitForChild("TopbarPlus"):WaitForChild("Icon"))

-- ─────────────────────────────────────────
-- TOPBARPLUS MHCOIN ICON
-- ─────────────────────────────────────────
local mhcoinIcon = Icon.new()
	:setRight() -- Taruh di sebelah kanan
	:setLabel("MH Coin: 0")

mhcoinIcon.selected:Connect(function()
	local playerGui = player:WaitForChild("PlayerGui")
	local coinShop = playerGui:FindFirstChild("CoinShop")
	if coinShop then
		coinShop.Enabled = true
		local frame = coinShop:FindFirstChild("FrameCoin")
		if frame then frame.Visible = true end
	end
end)

mhcoinIcon.deselected:Connect(function()
	local playerGui = player:WaitForChild("PlayerGui")
	local coinShop = playerGui:FindFirstChild("CoinShop")
	if coinShop then
		coinShop.Enabled = false
		local frame = coinShop:FindFirstChild("FrameCoin")
		if frame then frame.Visible = false end
	end
end)

-- ─────────────────────────────────────────
-- LISTENERS
-- ─────────────────────────────────────────
-- Inisialisasi awal saat baru login membaca dari statsData
task.spawn(function()
	local statsData = player:WaitForChild("StatsData", 10)
	if statsData then
		local mhcoinValue = statsData:WaitForChild("MHCoin", 10)
		if mhcoinValue then
			mhcoinIcon:setLabel("MH Coin: " .. tostring(mhcoinValue.Value))
			
			-- Update kalau objek Value berubah (Otomatis ditrigger oleh MHCoinService)
			mhcoinValue.Changed:Connect(function(newVal)
				mhcoinIcon:setLabel("MH Coin: " .. tostring(newVal))
			end)
		end
	end
end)

print("[MHCoinTopbar] Berhasil memuat topbar MHCoin!")
