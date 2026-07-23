local tween_service = game:GetService("TweenService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local info = TweenInfo.new(.5, Enum.EasingStyle.Exponential)
local smooth = TweenInfo.new(1, Enum.EasingStyle.Exponential)
local quick = TweenInfo.new(.3, Enum.EasingStyle.Exponential)

local client = players.LocalPlayer

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local events = storage.events

local ui = script.Parent

events.ui.WarningPrompt.OnClientEvent:Connect(function(state)
	if state then
		ui.storage.warning:Play()
	end
end)