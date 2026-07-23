-- ============================================================
-- MaxZoomOut.lua
-- Script → masukkan ke StarterPlayerScripts
-- Set max zoom out kamera player di Roblox
-- ============================================================

local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

-- Tunggu karakter load
localPlayer.CharacterAdded:Connect(function()
	-- Set CameraMaxZoomDistance sangat besar = zoom out maksimal
	localPlayer.CameraMaxZoomDistance = 25
end)

-- Terapkan juga langsung saat script pertama jalan
-- (untuk karakter yang sudah ada)
localPlayer.CameraMaxZoomDistance = 25