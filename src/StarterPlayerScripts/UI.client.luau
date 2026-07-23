local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packets = require(ReplicatedStorage.Modules.Packets)

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local LobbyGui : ScreenGui = PlayerGui:WaitForChild("LobbyGui")

LobbyGui.Leave.Activated:Connect(function()
	LobbyGui.Enabled = false
	Packets.Leave:Fire()
end)