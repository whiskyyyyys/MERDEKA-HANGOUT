-- ============================================================
-- CashTopbar.client.luau
-- Menampilkan total Cash secara global di Topbar menggunakan TopbarPlus
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Modul TopbarPlus
local Icon = require(ReplicatedStorage:WaitForChild("TopbarPlus"):WaitForChild("Icon"))

-- Remote untuk CashUpdate 
local minigamesFolder = ReplicatedStorage:WaitForChild("Minigames")
local skFolder = minigamesFolder:WaitForChild("SambungKata")
local remotes = skFolder:WaitForChild("Remotes")
local CashUpdate = remotes:WaitForChild("CashUpdate")

-- ─────────────────────────────────────────
-- TOPBARPLUS CASH ICON
-- ─────────────────────────────────────────
local cashIcon = Icon.new()
	:setRight() -- Taruh di sebelah kanan
	:setLabel("Cash: 0")

cashIcon.selected:Connect(function()
	local playerGui = player:WaitForChild("PlayerGui")
	local cashShop = playerGui:WaitForChild("CashShop", 5)
	if cashShop then
		cashShop.Enabled = true
		local frame = cashShop:FindFirstChild("Frame")
		if frame then frame.Visible = true end
	else
		warn("[CashTopbar] CashShop tidak ditemukan di PlayerGui!")
	end
end)

cashIcon.deselected:Connect(function()
	local playerGui = player:WaitForChild("PlayerGui")
	local cashShop = playerGui:FindFirstChild("CashShop")
	if cashShop then
		cashShop.Enabled = false
		local frame = cashShop:FindFirstChild("Frame")
		if frame then frame.Visible = false end
	end
end)
-- ─────────────────────────────────────────
-- LISTENERS
-- ─────────────────────────────────────────
-- 1. Update nilai cash dari Remote
CashUpdate.OnClientEvent:Connect(function(newCashValue)
	cashIcon:setLabel("Cash: " .. tostring(newCashValue))
end)

-- 2. Inisialisasi awal saat baru login membaca dari statsData
task.spawn(function()
	local statsData = player:WaitForChild("StatsData", 5)
	if statsData then
		local cashValue = statsData:WaitForChild("Cash", 3)
		if cashValue then
			cashIcon:setLabel("Cash: " .. tostring(cashValue.Value))
			
			-- Cadangan: Update kalau objek Value berubah
			cashValue.Changed:Connect(function(newVal)
				cashIcon:setLabel("Cash: " .. tostring(newVal))
			end)
		end
	end
end)

print("[CashTopbar] Berhasil memuat topbar Cash!")
