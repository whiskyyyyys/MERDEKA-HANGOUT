-- ScissorsClient (LocalScript) - taruh di dalam Tool Scissors
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local tool = script.Parent
local remote = ReplicatedStorage:WaitForChild("ScissorsRemote")

local mouse = nil
local mouseConn = nil

local function onMouseClick()
	-- pastikan ada mouse dan target
	if not mouse or not mouse.Target then return end
	local targetPart = mouse.Target
	local targetCharacter = targetPart:FindFirstAncestorOfClass("Model")
	if not targetCharacter then return end
	local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
	if not targetPlayer then return end

	-- jangan klik diri sendiri
	if targetPlayer == player then return end

	-- Kirim request ke server, berikan nama player target (lebih aman daripada mengirim Character)
	remote:FireServer(targetPlayer)
end

tool.Equipped:Connect(function()
	-- dapatkan mouse ketika ter-equip
	mouse = player:GetMouse()
	-- sambungkan klik (Button1Down) - aman di LocalScript untuk deteksi klik pemain
	mouseConn = mouse.Button1Down:Connect(onMouseClick)
end)

tool.Unequipped:Connect(function()
	-- hapus koneksi untuk mencegah memory leak
	if mouseConn then
		mouseConn:Disconnect()
		mouseConn = nil
	end
	mouse = nil
end)
