local datastore_service = game:GetService("DataStoreService")
local replicated_storage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local WarnDataStore = datastore_service:GetDataStore("Exe6", "Warnings")

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")

local Utilities = require(storage.modules.Utilities)
local Alerts = require(storage.modules.Alerts)

local systems = script.Parent
local components = systems.Parent.Components

local MAX_WARNINGS = 20

local module = {}

function module.Warn(userId, message, mod)
	local success, warnings = pcall(function()
		return WarnDataStore:GetAsync("Warnings_" .. userId) or {}
	end)

	if not success then
		warn("Failed to retrieve warnings for userId:", userId)
		return false
	end

	if #warnings > 0 and not warnings[#warnings].Read then
		warn("UserId:", userId, "must read the latest warning before receiving a new one.")
		return false
	end

	if #warnings >= MAX_WARNINGS then
		table.remove(warnings, 1) 
	end

	table.insert(warnings, {
		Message = message,
		Moderator = mod,
		Timestamp = os.time(),
		Read = false
	})

	local saveSuccess, err = pcall(function()
		WarnDataStore:SetAsync("Warnings_" .. userId, warnings)
	end)

	if not saveSuccess then
		warn("Failed to save warning for userId:", userId, err)
		return false
	end

	return true
end

function module.ReadLatestWarning(userId)
	local success, warnings = pcall(function()
		return WarnDataStore:GetAsync("Warnings_" .. userId) or {}
	end)

	if not success then
		warn("Failed to retrieve warnings for userId:", userId)
		return false
	end

	if #warnings > 0 then
		warnings[#warnings].Read = true

		local saveSuccess, err = pcall(function()
			WarnDataStore:SetAsync("Warnings_" .. userId, warnings)
		end)

		if not saveSuccess then
			warn("Failed to update warning status for userId:", userId, err)
			return false
		end
	end

	return true
end

function module.RemoveLastUnreadWarning(userId)
	local success, warnings = pcall(function()
		return WarnDataStore:GetAsync("Warnings_" .. userId) or {}
	end)

	if not success then
		warn("Failed to retrieve warnings for userId:", userId)
		return false
	end

	if #warnings == 0 then
		warn("No warnings found for userId:", userId)
		return false
	end

	if warnings[#warnings].Read then
		warn("Latest warning for userId:", userId, "is already read.")
		return false
	end

	table.remove(warnings, #warnings)

	local saveSuccess, err = pcall(function()
		WarnDataStore:SetAsync("Warnings_" .. userId, warnings)
	end)

	if not saveSuccess then
		warn("Failed to save updated warnings for userId:", userId, err)
		return false
	end

	return true
end

function module.GetWarnings(userId)
	local success, warnings = pcall(function()
		return WarnDataStore:GetAsync("Warnings_" .. userId) or {}
	end)

	if not success then
		warn("Failed to retrieve warnings for userId:", userId)
		return {}
	end

	return warnings
end

function module.GetLatestWarning(userId)
	local success, warnings = pcall(function()
		return WarnDataStore:GetAsync("Warnings_" .. userId) or {}
	end)

	if not success then
		warn("Failed to retrieve warnings for userId:", userId)
		return nil
	end

	return warnings[#warnings] or nil
end

function module.PromptUserLatestUnreadWarning(userid)
	local recipient = players:GetPlayerByUserId(userid)
	if not recipient then 
		warn("Player user isn't found in the server.")
		
		return false 
	end
	
	local LatestWarning = module.GetLatestWarning(userid)
	
	if not LatestWarning then return end
	if LatestWarning.Read then return end
	
	local ui = components.Exe6WarnSystem:Clone()
	local character = recipient.Character or recipient.CharacterAdded:Wait()
	local highlight = Utilities.AddWarnHighlight()

	local moderator = Utilities.GetNameByUserIdAsync(LatestWarning.Moderator, true)
	
	Utilities.SetStatusForScriptDescendants(ui, true)
	Utilities.Haptic(1, 1)
	
	recipient:AddTag("Exe6PlayerUnavailable")
	
	highlight.Parent = character
	character.HumanoidRootPart.Anchored = true
	
	ui.frame.content.scroll.label.Text = LatestWarning.Message
	
	ui.frame.content.scroll.details.moderator.profile.Image = Utilities.GetPlayerThumbnail(LatestWarning.Moderator)
	ui.frame.content.scroll.details.moderator.username.Text = moderator
	ui.frame.content.scroll.details.date.Text = Utilities.FormatSecondsToRealDate(os.time() - LatestWarning.Timestamp) or ""
	
	ui.Parent = recipient.PlayerGui
	
	--
	
	storage.events.ui.WarningPrompt:FireClient(recipient, true)
	
	-- Actions
	
	ui.frame.actions.dismiss.MouseButton1Click:Connect(function()
		ui.frame.Interactable = false
		module.ReadLatestWarning(userid)
		
		--
		
		character.Humanoid.Health = 0
		
		recipient:RemoveTag("Exe6PlayerUnavailable")
		
		storage.events.ui.Recalibrate:Fire(recipient)
		storage.events.ui.WarningPrompt:FireClient(recipient, false)
		
		--
		
		Alerts.BannerNotify({
			Header = "Account Reactivated",
			Icon = "rbxassetid://11422917864",
			Host = recipient
		})
		
		--
		
		ui:Destroy()
	end)

	ui.frame.actions.cancel.MouseButton1Click:Connect(function()
		recipient:Kick(LatestWarning.Message)
	end)
	
	return true
end

return module