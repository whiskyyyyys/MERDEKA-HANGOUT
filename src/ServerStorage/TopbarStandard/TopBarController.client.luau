local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local UIManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("UIManager"))

local screenGui = script.Parent
local holders = screenGui:WaitForChild("Holders")

local function getClickRegion(iconFrame)
	local iconButton = iconFrame:FindFirstChild("IconButton")
	if not iconButton then
		return nil
	end

	local menu = iconButton:FindFirstChild("Menu")
	if not menu then
		return nil
	end

	local iconSpot = menu:FindFirstChild("IconSpot")
	if not iconSpot then
		return nil
	end

	return iconSpot:FindFirstChild("ClickRegion")
end

local function closeAllPanels(except)
	for _, guiName in ipairs({"Cosmetics", "Powers", "PlayerStats", "Settings"}) do
		if guiName ~= except then
			local gui = playerGui:FindFirstChild(guiName)
			if gui then
				local panelFrame = gui:FindFirstChild("Frame")
				if panelFrame then
					UIManager.Close(panelFrame)
				end
			end
		end
	end
end

local function togglePanel(guiName)
	local gui = playerGui:FindFirstChild(guiName)
	if not gui then
		return
	end

	local panelFrame = gui:FindFirstChild("Frame")
	if not panelFrame then
		return
	end

	if UIManager.IsOpen(panelFrame) then
		UIManager.Close(panelFrame)
	else
		closeAllPanels(guiName)
		UIManager.Open(panelFrame)
	end
end

local function setupCloseButton(guiName)
	local gui = playerGui:FindFirstChild(guiName)
	if not gui then
		return
	end

	local panelFrame = gui:FindFirstChild("Frame")
	if not panelFrame then
		return
	end

	local closeFrame = panelFrame:FindFirstChild("CloseFrame")
	if not closeFrame then
		return
	end

	local closeButton = closeFrame:FindFirstChild("CloseButton")
	if not closeButton then
		return
	end

	closeButton.MouseButton1Click:Connect(function()
		UIManager.Close(panelFrame)
	end)
end

local settingsFrame = holders.Left:WaitForChild("Settings")
local playerStatsFrame = holders.Left:WaitForChild("PlayerStats")

local settingsClickRegion = getClickRegion(settingsFrame)
local playerStatsClickRegion = getClickRegion(playerStatsFrame)

if settingsClickRegion then
	settingsClickRegion.MouseButton1Click:Connect(function()
		togglePanel("Settings")
	end)
end

if playerStatsClickRegion then
	playerStatsClickRegion.MouseButton1Click:Connect(function()
		togglePanel("PlayerStats")
	end)
end

setupCloseButton("Settings")
setupCloseButton("PlayerStats")