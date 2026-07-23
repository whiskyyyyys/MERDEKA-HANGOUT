local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VoiceChatService = game:GetService("VoiceChatService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer

local DataRemotes = ReplicatedStorage:WaitForChild("DataRemotes")
local DataUpdatedRemote = DataRemotes:WaitForChild("DataUpdated")
local RequestDataRemote = DataRemotes:WaitForChild("RequestData")

local ProfileRemotes = ReplicatedStorage:WaitForChild("ProfileRemotes")
local ProfileInfoRemote = ProfileRemotes:WaitForChild("ProfileInfo")
local RequestProfileInfoRemote = ProfileRemotes:WaitForChild("RequestProfileInfo")

local LocaleConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("LocaleConfig"))

local screenGui = script.Parent
local frame = screenGui:WaitForChild("Frame")
local content = frame:WaitForChild("Container"):WaitForChild("Content")

local top = content:WaitForChild("Top")
local profileFrame = top:WaitForChild("Profile")
local profileIcon = profileFrame:WaitForChild("Icon")

local side = top:WaitForChild("Side")
local displayNameFrame = side:WaitForChild("DisplayName")
local displayNameLabel = displayNameFrame:WaitForChild("Label")
local voiceChatFrame = displayNameFrame:WaitForChild("VoiceChat")
local voiceChatIcon = voiceChatFrame:WaitForChild("Icon")

local realNameFrame = side:WaitForChild("RealName")
local realNameLabel = realNameFrame:WaitForChild("Label")
local countryEmojiFrame = realNameFrame:WaitForChild("CountryEmoji")
local countryEmojiLabel = countryEmojiFrame:WaitForChild("Label")
local deviceEmojiFrame = realNameFrame:WaitForChild("DeviceEmoji")
local deviceEmojiLabel = deviceEmojiFrame:WaitForChild("Label")

local overviewStats = side:WaitForChild("OverviewStats")
local bottom = content:WaitForChild("Bottom")

local winsLabel = overviewStats:WaitForChild("Wins"):WaitForChild("Label")
local killsLabel = overviewStats:WaitForChild("Kills"):WaitForChild("Label")
local eloLabel = overviewStats:WaitForChild("ELO"):WaitForChild("Label")

local playTimeValue = bottom:WaitForChild("PlayTime"):WaitForChild("Value"):WaitForChild("Label")
local totalKillValue = bottom:WaitForChild("TotalKill"):WaitForChild("Value"):WaitForChild("Label")
local totalWinValue = bottom:WaitForChild("TotalWin"):WaitForChild("Value"):WaitForChild("Label")

local DEVICE_ICONS = {
	Mobile = "📱",
	Console = "🎮",
	Tablet = "📱",
	Desktop = "🖥️",
}

local function getDeviceType()
	if UserInputService.GamepadEnabled then
		return "Console"
	elseif UserInputService.TouchEnabled and not UserInputService.MouseEnabled and not UserInputService.KeyboardEnabled then
		return "Mobile"
	elseif UserInputService.TouchEnabled then
		return "Tablet"
	else
		return "Desktop"
	end
end

local function formatPlayTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	if hours > 0 then
		return string.format("%dh %dm", hours, minutes)
	end
	return string.format("%dm", minutes)
end

local function updateStats(data)
	if not data or not data.Stats then
		return
	end

	local stats = data.Stats

	winsLabel.Text = tostring(stats.Wins)
	killsLabel.Text = tostring(stats.Kills)
	eloLabel.Text = tostring(stats.ELO)

	playTimeValue.Text = formatPlayTime(stats.PlayTime)
	totalKillValue.Text = tostring(stats.Kills)
	totalWinValue.Text = tostring(stats.Wins)
end

local function updateProfileInfo(info)
	if not info then
		return
	end

	displayNameLabel.Text = info.DisplayName
	realNameLabel.Text = "@" .. info.Username

	countryEmojiLabel.Text = LocaleConfig.GetFlag(info.LocaleId)
	deviceEmojiLabel.Text = DEVICE_ICONS[getDeviceType()] or "🖥️"

	local thumbType = Enum.ThumbnailType.HeadShot
	local thumbSize = Enum.ThumbnailSize.Size420x420
	local content_, isReady = Players:GetUserThumbnailAsync(info.UserId, thumbType, thumbSize)
	profileIcon.Image = content_
end

local function updateVoiceChatIcon()
	local isVoiceEnabled = false

	local success = pcall(function()
		isVoiceEnabled = VoiceChatService:IsVoiceEnabledForUserIdAsync(localPlayer.UserId)
	end)

	if not success then
		isVoiceEnabled = false
	end

	voiceChatFrame.Visible = isVoiceEnabled
end

DataUpdatedRemote.OnClientEvent:Connect(function(data)
	updateStats(data)
end)

ProfileInfoRemote.OnClientEvent:Connect(function(info)
	updateProfileInfo(info)
end)

RequestDataRemote:FireServer()
RequestProfileInfoRemote:FireServer()

task.spawn(updateVoiceChatIcon)