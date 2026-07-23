-- ScissorsClient (LocalScript di dalam Tool)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tool = script.Parent
local Player = Players.LocalPlayer

local SoundRemote = ReplicatedStorage:WaitForChild("ScissorsSoundRemote")
local StopSoundRemote = ReplicatedStorage:WaitForChild("ScissorsStopSound")

-- Saat equip: minta server mulai suara
Tool.Equipped:Connect(function()
	SoundRemote:FireServer()
end)

-- Saat unequip: minta server hentikan suara
Tool.Unequipped:Connect(function()
	StopSoundRemote:FireServer()
end)
