local run_service = game:GetService("RunService")
local teleport_service = game:GetService("TeleportService")
local http_service = game:GetService("HttpService")
local messaging_service = game:GetService("MessagingService")
local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")
local marketplace_service = game:GetService("MarketplaceService")
local tween_service = game:GetService("TweenService")

local two = TweenInfo.new(2)

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local events = storage.events

local server = script.Parent

local Auth = require(server.Auth)

local IdSaving = require(server.Systems.IdSaving)
local ActivityAuditing = require(server.Systems.ActivityAuditing)
local VariableEncoding = require(server.Systems.VariableEncoding)
local SafeTeleport = require(server.Systems.SafeTeleport)
local ChatLogging = require(server.Systems.ChatLogging)
local Warning = require(server.Systems.Warning)
local ActionPinning = require(server.Systems.ActionPinning)
local CharacterController = require(server.Systems.CharacterController)
local NoClipService = require(server.Systems.NoClipService)

local Utilities = require(storage.modules.Utilities)
local Configuration = Auth.GetConfigurations()
local Alerts = require(storage.modules.Alerts)

local ServerBannedPeople = {}

--// FETCHING

events.auth.Auth.OnServerInvoke = function(person, func, ...)
	return Auth[func](...)
end

events.auth.ActionPinning.OnServerInvoke = function(person, func, ...)
	if not Auth.IsAuthorized(person.UserId) then return end

	return ActionPinning[func](...)
end

events.auth.FetchPins.OnServerInvoke = function(person, func, ...)
	if not Auth.IsAuthorized(person.UserId) then return end

	return ActionPinning:GetPins(person.UserId)
end

events.auth.IdSaving.OnServerInvoke = function(person, func, ...)
	if not Auth.IsAuthorized(person.UserId) then return end

	return IdSaving[func](...)
end

events.auth.FetchRecordedIds.OnServerInvoke = function(player)
	if not Auth.IsAuthorized(player.UserId) then return end

	return {
		Permanent = IdSaving.GetUserIds(),
		Expiring = IdSaving.GetExpiringUserIds(),
		Expired = IdSaving.GetExpiredUserIds(),
		Revoked = IdSaving.GetRevokedUserIds(),
		Server = ServerBannedPeople,
	}
end

events.auth.VariableEncode.OnServerInvoke = function(person, func, ...)
	if not Auth.IsAuthorized(person.UserId) then return end

	return VariableEncoding[func](...)
end

events.misc.GetBanHistory.OnServerInvoke = function(player, id)
	if not Auth.IsAuthorized(player.UserId) then return end

	local full_index = {}
	local success, history = pcall(function()
		return players:GetBanHistoryAsync(id)
	end)

	if success then
		repeat
			local page = history:GetCurrentPage()

			for caseId, case in page do
				table.insert(full_index, case)
			end

			if history.IsFinished then
				break
			end

			history:AdvanceToNextPageAsync()

		until history.IsFinished == true

		return full_index

	else
		warn("Error:", history)

		return nil
	end
end

events.components.GetAuditActivities.OnServerInvoke = function(plr)
	if not Auth.IsAuthorized(plr.UserId) then return end

	return ActivityAuditing.GetAuditedActivities(Configuration.Auditing.Threshold)
end

events.components.GetServerBans.OnInvoke = function()	
	return ServerBannedPeople
end

events.auth.FetchServerBans.OnServerInvoke = function(plr)
	if not Auth.IsAuthorized(plr.UserId) then return end

	return ServerBannedPeople
end

events.auth.FetchRoles.OnServerInvoke = function(plr)
	if not Auth.IsAuthorized(plr.UserId) then return end

	local Roles = Auth.GetRoles()
	return Roles
end

events.components.GetBanHistory.OnServerInvoke = function(player, id)
	if not Auth.IsAuthorized(player.UserId) then return end

	local full_index = {}
	local success, history = pcall(function()
		return players:GetBanHistoryAsync(id)
	end)

	if success then
		repeat
			local page = history:GetCurrentPage()

			for caseId, case in page do
				table.insert(full_index, case)
			end

			if history.IsFinished then
				break
			end

			history:AdvanceToNextPageAsync()

		until history.IsFinished == true

		return full_index

	else
		warn("Error:", history)

		return nil
	end
end

events.components.GetChatHistory.OnServerInvoke = function(plr, id)
	if not Auth.IsAuthorized(plr.UserId) then return end

	return ChatLogging:GetLoggedChats(id)
end

events.components.GetWarningHistory.OnServerInvoke = function(plr, id)
	if not Auth.IsAuthorized(plr.UserId) then return end

	return Warning.GetWarnings(id)
end

events.ui.GetGameDesignTable.OnServerInvoke = function(plr)
	if not Auth.IsAuthorized(plr.UserId) then return end

	local ID = game.PlaceId
	local info = marketplace_service:GetProductInfoAsync(ID)

	local design = {
		["Icon"] = "rbxassetid://"..info.IconImageAssetId,
		["Thumbnail"] = "https://assetgame.roblox.com/Game/Tools/ThumbnailAsset.ashx?aid=".. ID .."&fmt=png&wd=420&ht=420"
	}

	return design
end

events.ui.FilterString.OnServerInvoke = function(player, text, id, visible_to_all)
	return Utilities.FilterString(text, id, visible_to_all)
end

events.NoClip.GetState.OnServerInvoke = function(player: Player)
	return NoClipService:GetState(player)
end

--// NOTIFY EVERYONE

events.ui.NotifyEveryone.OnServerEvent:Connect(function(mod, data)
	if not Auth.IsAuthorized(mod.UserId) then return end

	for _, i in pairs(players:GetPlayers()) do

		Alerts.BannerNotify({
			Header = data.Header or nil;
			Description = data.Description or nil;
			Icon = data.Icon or nil;
			Duration = data.Duration or 3;
			Host = i;
		})

	end
end)

--// CHAT LOGGING

local PlayerChats = {}

function TrackChats(player)
	player.Chatted:Connect(function(msg)

		if not PlayerChats[player.UserId] then
			PlayerChats[player.UserId] = {}
		end

		table.insert(PlayerChats[player.UserId], {
			Message = msg,
			Timestamp = os.time(),
		})

	end)
end

players.PlayerAdded:Connect(function(player)	
	TrackChats(player)
end)

players.PlayerRemoving:Connect(function(player)
	if PlayerChats[player.UserId] then

		ChatLogging:LogChats(player.UserId, PlayerChats[player.UserId])

		PlayerChats[player.UserId] = nil

	end
end)

for i, player in pairs(players:GetPlayers()) do
	TrackChats(player)
end

events.auth.FetchUnsavedChats.OnServerInvoke = function(mod, UserId)
	local perm = Auth.IsAuthorized(mod.UserId)
	if not perm then return end

	local player = players:GetPlayerByUserId(UserId)
	if not player then return nil end

	if not PlayerChats[player.UserId] then return nil end

	local UnsavedChats = {}

	for i, chats in pairs(PlayerChats[player.UserId]) do
		table.insert(UnsavedChats, chats)
	end

	return UnsavedChats
end

--// AUTHENTICATIONS

function ServerBan(ban, IdsArray, Reason, ModId)
	if ban then
		for i, id in ipairs(IdsArray) do
			ServerBannedPeople[tostring(id)] = {
				Reason = Reason;
				ModeratorId = ModId;
				ISO = Utilities.GetISO8601();
			}

			--

			local person = players:GetPlayerByUserId(id)

			if person then
				person:Kick("You are banned from this server. Reason: " .. Reason)
			end
		end
	else
		for i, id in ipairs(IdsArray) do
			ServerBannedPeople[tostring(id)] = nil
		end
	end
end

function IsServerBanned(id)
	return ServerBannedPeople[tostring(id)]
end

events.Activities.Primary.OnServerInvoke = function(player, Action, Properties)
	local perm = Auth.IsAuthorized(player.UserId)
	if not perm then return end
	local alias = Auth.GetRoleNameFromRoleTable(perm.Role)

	if perm and alias then

		--// BAN
		if Action == "Ban" and (Auth.GetRoleSetting(alias, "Ban") or Auth.GetRoleSetting(alias, "ServerBan")) then
			local serialized = Utilities.DeserializeNumberTable(Properties.SerializedIds)
			local userids = {}

			-- Saves Bannable Players

			for i, id in pairs(serialized) do
				local user_perm = Auth.IsAuthorized(id)

				if not user_perm or (user_perm and Auth.GetRoleSetting(user_perm.Role.Alias, "Bannable")) then
					table.insert(userids, id)
				end
			end

			-- Removes Already-Banned Players

			for i, id in pairs(userids) do
				if IsServerBanned(id) or IdSaving.IsUserIdSaved(id) then
					table.remove(userids, table.find(userids, id) or 0)
				end
			end

			if #userids < 1 then
				return false, "No players to ban."
			end

			if Properties.ServerOnly then
				if not Auth.GetRoleSetting(alias, "ServerBan") then 
					return false, `Missing "Server Ban" permission.` 
				end

				ServerBan(true, userids, Properties.Reason, player.UserId)

				VariableEncoding.IncreaseVariable("Exe6RecordedIssues", #userids)

				if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogBanActivities then

					ActivityAuditing.AuditActivity(
						player.UserId,
						"Server Ban Issued for " .. #userids .. " player(s).",
						userids)

				end

				return {Success = userids, All = serialized}
			else
				if not Auth.GetRoleSetting(alias, "Ban") then 
					return false, `Missing "Ban" permission.`
				end

				local config: BanConfigType = {
					UserIds = userids,
					Duration = Properties.Duration,

					ApplyToUniverse = true,
					ExcludeAltAccounts = Properties.ExcludeAltAccounts,

					PrivateReason = Properties.ModeratorNote,
					DisplayReason = Properties.Reason
				}

				local success, err = pcall(function()
					return players:BanAsync(config)
				end)

				-- Auditing

				if success then

					if Properties.Duration == -1 then
						IdSaving.SaveUserIds(userids, player.UserId)
					else
						IdSaving.SaveExpiringUserIds(userids, Properties.Duration, player.UserId)
					end

					VariableEncoding.IncreaseVariable("Exe6RecordedIssues", #userids)

					if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogBanActivities then
						ActivityAuditing.AuditActivity(
							player.UserId,
							"Game Ban Issued for " .. #userids .. " player(s).",
							userids)
					end

					return {Success = userids, All = serialized}
				else
					return false, err
				end
			end

		elseif Action == "Unban" and (Auth.GetRoleSetting(alias, "Unban")or Auth.GetRoleSetting(alias, "ServerUnban")) then
			local serialized = Utilities.DeserializeNumberTable(Properties.SerializedIds)
			local userids = {}

			-- Saves Already-Banned Players

			for i, id in pairs(serialized) do
				table.insert(userids, id)
			end

			if #userids < 1 then
				return	
			end

			if Properties.ServerOnly then
				if not Auth.GetRoleSetting(alias, "ServerUnban") then
					return 
				end

				ServerBan(false, userids, Properties.Reason, player.UserId)

				if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogRevokeBanActivities then
					ActivityAuditing.AuditActivity(
						player.UserId,
						"Revoked Server BanIssued for " .. #userids .. " player(s).",
						userids)
				end

				return {Success = userids, All = userids}
			else
				if not Auth.GetRoleSetting(alias, "Unban") then
					return 
				end

				local config: UnbanConfigType = {
					UserIds = userids,
					ApplyToUniverse = true,
				}

				local success, err = pcall(function()
					return players:UnbanAsync(config)
				end)

				-- Auditing

				if success then
					IdSaving.RemoveUserIds(userids)

					if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogRevokeBanActivities then
						ActivityAuditing.AuditActivity(
							player.UserId,
							"Revoked Game Ban Issued for " .. #userids .. " player(s).",
							userids)
					end

					return {Success = userids, All = userids}
				end
			end

			--// KICK
		elseif Action == "Kick" and Auth.GetRoleSetting(alias, "Kick") then
			local serialized = Utilities.DeserializeNumberTable(Properties.SerializedIds)
			local userids = {}

			for i, id in ipairs(serialized) do
				local user_perm = Auth.IsAuthorized(id)
				local person = players:GetPlayerByUserId(id)

				if not user_perm or (user_perm and Auth.GetRoleSetting(user_perm.Role.Alias, "Kickable")) and person then
					table.insert(userids, id)
				end
			end

			if #userids < 1 then
				return	
			end

			for i, id in ipairs(userids) do
				local person = players:GetPlayerByUserId(id)

				if person then
					person:Kick(Properties.Reason)
				end
			end

			-- Auditing

			if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogKickActivities then
				VariableEncoding.IncreaseVariable("Exe6RecordedKicks", #userids)

				ActivityAuditing.AuditActivity(
					player.UserId,
					"Kicked " .. #userids .. " player(s) from the server: " .. game.JobId .. ".",
					userids)
			end

			return {Success = userids, All = serialized}

		elseif Action == "Warn" and Auth.GetRoleSetting(alias, "Warn") then
			local serialized = Utilities.DeserializeNumberTable(Properties.SerializedIds)
			local userids = {}

			for i, id in ipairs(serialized) do
				local user_perm = Auth.IsAuthorized(id)

				if not user_perm or (user_perm and Auth.GetRoleSetting(user_perm.Role.Alias, "Warnable")) then
					table.insert(userids, id)
				end
			end

			if #userids < 1 then
				return	
			end

			for i, id in ipairs(userids) do
				local person = players:GetPlayerByUserId(id)

				if person then
					local issue = Warning.Warn(id, Properties.Warning, player.UserId)

					if issue then
						Warning.PromptUserLatestUnreadWarning(id)
					else
						table.remove(userids, table.find(userids, id) or 0)
					end
				else
					local issue = Warning.Warn(id, Properties.Warning, player.UserId)

					if not issue then
						table.remove(userids, table.find(userids, id) or 0)
					end
				end
			end

			-- Auditing

			if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogWarnActivities then

				ActivityAuditing.AuditActivity(
					player.UserId,
					"Warned " .. #userids .. " player(s).",
					userids)
			end

			return {Success = userids, All = serialized}
			
		elseif Action == "RemoveUnreadWarn" and Auth.GetRoleSetting(alias, "Warn") then
			local serialized = Utilities.DeserializeNumberTable(Properties.SerializedIds)
			local userids = {}

			for i, id in ipairs(serialized) do
				table.insert(userids, id)
			end

			if #userids < 1 then
				return	
			end

			for i, id in ipairs(userids) do
				local Removal = Warning.RemoveLastUnreadWarning(id)

				if not Removal then
					table.remove(userids, table.find(userids, id) or 0)
				end
			end

			-- Auditing

			if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogWarnActivities then

				ActivityAuditing.AuditActivity(
					player.UserId,
					"Removed Unread Warnings for " .. #userids .. " player(s).",
					userids)
			end

			return {Success = userids, All = serialized}
		end
	end
end

events.Activities.ServerTeleportation.OnServerEvent:Connect(function(player, isjobid, destination)
	local perm = Auth.IsAuthorized(player.UserId)
	if not perm then return end
	local alias = Auth.GetRoleNameFromRoleTable(perm.Role)

	if perm and alias then
		if Auth.GetRoleSetting(alias, "ServerTeleportation") then

			if isjobid then
				local options = Instance.new("TeleportOptions")
				options.ServerInstanceId = destination
				options:SetTeleportData("Exe6Verified")

				local success, result = SafeTeleport(game.PlaceId, {player}, options)

				events.Activities.ServerTeleportation:FireClient(player, success, result)

				if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogServerTeleportation then
					ActivityAuditing.AuditActivity(
						player.UserId,
						"Server teleported to " .. destination .. " (Job ID)", {}
					)
				end
			else
				local user_id = Utilities.GetUserIdByNameAsync(destination)
				local _currentInstance, placeId, jobId

				if user_id then
					local success, result, _currentInstance, placeId, jobId = pcall(function()
						return teleport_service:GetPlayerPlaceInstanceAsync(user_id)
					end)

					if success or (_currentInstance and placeId and jobId) then
						if placeId == game.PlaceId then
							local options = Instance.new("TeleportOptions")
							options.ServerInstanceId = jobId
							options:SetTeleportData("Exe6Verified")

							local success, result = SafeTeleport(game.PlaceId, {player}, options)

							events.Activities.ServerTeleportation:FireClient(player, success, result)

							--

							if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogServerTeleportation then
								ActivityAuditing.AuditActivity(
									player.UserId,
									"Server teleported to @" .. destination .. ".", {}
								)
							end
						else
							events.Activities.ServerTeleportation:FireClient(player, false, "Player is in a different game.")
						end
					else
						events.Activities.ServerTeleportation:FireClient(player, success, result)
					end
				else
					events.Activities.ServerTeleportation:FireClient(player, false, "Failed to find the player.")
				end
			end
		else
			Alerts.BannerNotify({
				Header = "Missing Permissions",
				Description = "You're missing Server Teleporation permissions.",
				Icon = "rbxassetid://12974197533",
				Host = player
			})
		end
	end
end)

--// CHARACTER & HUMANOID ACTIONS

local Cooldown = .5
local Executing = false

events.Activities.Character.OnServerEvent:Connect(function(mod, recipientUserId, action, value)
	if Executing then 
		Alerts.BannerNotify({
			Header = "Unable to continue";
			Description = "A command is already being executed.";
			Icon = "rbxassetid://12974197362";
			Host = mod
		})

		return
	end

	--Permission Check

	local perm = Auth.IsAuthorized(mod.UserId)
	if not perm then return end

	local alias = Auth.GetRoleNameFromRoleTable(perm.Role)

	if not perm or not alias or not Auth.GetRoleSetting(alias, "ConfigureCharacter") then
		Alerts.BannerNotify({
			Header = "Unable to continue";
			Description = "You don't have access to the feature: " .. action;
			Icon = "rbxassetid://12974197362";
			Host = mod
		})
		return
	end

	Executing = true

	--Actions

	if action == "Freeze" then
		local Recipient = players:GetPlayerByUserId(recipientUserId)
		local ActionCommand = CharacterController.SetFreeze(Recipient, true)

		if ActionCommand then
			Alerts.BannerNotify({
				Header = "Successfully Froze",
				Description = action .. " has been successfully executed to " .. Recipient.DisplayName .. ".",
				Icon = "rbxassetid://12974384137",
				Involved = {recipientUserId},
				Host = mod
			})
		end

	elseif action == "Unfreeze" then
		local Recipient = players:GetPlayerByUserId(recipientUserId)
		local ActionCommand = CharacterController.SetFreeze(Recipient, false)

		if ActionCommand then
			Alerts.BannerNotify({
				Header = "Successfully Thawed",
				Description = action .. " has been successfully executed to " .. Recipient.DisplayName .. ".",
				Icon = "rbxassetid://12974384137",
				Involved = {recipientUserId},
				Host = mod
			})
		end

	elseif action == "Follow" then
		local Recipient = players:GetPlayerByUserId(recipientUserId)
		local ActionCommand = CharacterController.Teleport(mod, Recipient, "Follow")

		if ActionCommand then
			Alerts.BannerNotify({
				Header = "Successfully Followed",
				Description = action .. " has been successfully executed to " .. Recipient.DisplayName .. ".",
				Icon = "rbxassetid://12974384137",
				Involved = {recipientUserId},
				Host = mod
			})
		end

	elseif action == "Bring" then
		local Recipient = players:GetPlayerByUserId(recipientUserId)
		local ActionCommand = CharacterController.Teleport(mod, Recipient, "Bring")

		if ActionCommand then
			Alerts.BannerNotify({
				Header = "Successfully Brought",
				Description = action .. " has been successfully executed to " .. Recipient.DisplayName .. ".",
				Icon = "rbxassetid://12974384137",
				Involved = {recipientUserId},
				Host = mod
			})
		end

	elseif action == "Invisible" then
		local Recipient = players:GetPlayerByUserId(recipientUserId)
		local ActionCommand = CharacterController.SetTransparency(Recipient, 1)

		if ActionCommand then
			Alerts.BannerNotify({
				Header = "Successfully Dissapeared ",
				Description = action .. " has been successfully executed to " .. Recipient.DisplayName .. ".",
				Icon = "rbxassetid://12974384137",
				Involved = {recipientUserId},
				Host = mod
			})
		end

	elseif action == "Visible" then
		local Recipient = players:GetPlayerByUserId(recipientUserId)
		local ActionCommand = CharacterController.SetTransparency(Recipient, 0)

		if ActionCommand then
			Alerts.BannerNotify({
				Header = "Successfully Appeared ",
				Description = action .. " has been successfully executed to " .. Recipient.DisplayName .. ".",
				Icon = "rbxassetid://12974384137",
				Involved = {recipientUserId},
				Host = mod
			})
		end

	elseif action == "Transparency" then
		local Recipient = players:GetPlayerByUserId(recipientUserId)
		local ActionCommand = CharacterController.SetTransparency(Recipient, value)

		if ActionCommand then
			Alerts.BannerNotify({
				Header = "Successfully Set Transparency (" .. value .. ")",
				Description = action .. " has been successfully executed to " .. Recipient.DisplayName .. ".",
				Icon = "rbxassetid://12974384137",
				Involved = {recipientUserId},
				Host = mod
			})
		end

	elseif action == "Shapeshift" then
		local ActionCommand = CharacterController.CopyAvatar(mod, recipientUserId)

		if ActionCommand then
			Alerts.BannerNotify({
				Header = "Successfully Copied Avatar ",
				Description = action .. " has been successfully executed.",
				Icon = "rbxassetid://12974384137",
				Involved = {recipientUserId},
				Host = mod
			})
		end
	end

	if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogCharacterActions then
		ActivityAuditing.AuditActivity(
			mod.UserId,
			"Executed " .. action .. ".", {recipientUserId}
		)
	end

	task.wait(Cooldown)
	Executing = false
end)

events.Activities.Humanoid.OnServerEvent:Connect(function(mod, recipientUserId, action, value)
	if Executing == true then 
		Alerts.BannerNotify({
			Header = "Unable to continue";
			Description = "A command is already being executed.";
			Icon = "rbxassetid://12974197362";
			Host = mod
		})
		return
	end

	local perm = Auth.IsAuthorized(mod.UserId)
	if not perm then return end

	local alias = Auth.GetRoleNameFromRoleTable(perm.Role)

	if not perm or not alias or not Auth.GetRoleSetting(alias, "ConfigureHumanoid") then
		Alerts.BannerNotify({
			Header = "Unable to continue";
			Description = "You don't have access to the action: " .. action;
			Icon = "rbxassetid://12974197362";
			Host = mod
		})
		return
	end

	Executing = true

	local Recipient = players:GetPlayerByUserId(recipientUserId)
	local ActualValue = 0

	if action == "Health" then
		local MainValue = math.clamp(value, 0, 100)
		if MainValue == 0 and not Configuration.PlayerManagement.KillingAllowed then
			MainValue = .1
		end

		ActualValue = MainValue

		local ActionCommand = CharacterController.SetHumanoidProperties(Recipient, {Health = MainValue})

		if ActionCommand then
			Alerts.BannerNotify({
				Header = "Successfully Set Health ",
				Description = "Set " .. Recipient.DisplayName .. "'s Health to " .. MainValue .. ".",
				Icon = "rbxassetid://11419717444",
				Involved = {recipientUserId},
				Host = mod
			})
		end

	elseif action == "Speed" then
		local MainValue = math.clamp(value, 0, Configuration.PlayerManagement.MaximumWalkSpeed)
		local ActionCommand = CharacterController.SetHumanoidProperties(Recipient, {Speed = MainValue})

		ActualValue = MainValue

		if ActionCommand then
			Alerts.BannerNotify({
				Header = "Successfully Set Speed ",
				Description = "Set " .. Recipient.DisplayName .. "'s Speed to " .. MainValue .. ".",
				Icon = "rbxassetid://12975608939",
				Involved = {recipientUserId},
				Host = mod
			})
		end

	elseif action == "Jump" then
		local MainValue = math.clamp(value, 0, Configuration.PlayerManagement.MaximumJumpPower)
		local ActionCommand = CharacterController.SetHumanoidProperties(Recipient, {Jump = MainValue})

		ActualValue = MainValue

		if ActionCommand then
			Alerts.BannerNotify({
				Header = "Successfully Set Jump ",
				Description = "Set " .. Recipient.DisplayName .. "'s Jump to " .. MainValue .. ".",
				Icon = "rbxassetid://11963378393",
				Involved = {recipientUserId},
				Host = mod
			})
		end
	end

	if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogHumanoidActions then
		ActivityAuditing.AuditActivity(
			mod.UserId,
			"Set " .. action .. " to " .. ActualValue .. ".", {recipientUserId}
		)
	end

	task.wait(Cooldown)
	Executing = false
end)

events.NoClip.NoClip.OnServerInvoke = function(mod, recipient, state)
	local perm = Auth.IsAuthorized(mod.UserId)
	if not perm then return end

	local alias = Auth.GetRoleNameFromRoleTable(perm.Role)

	if not perm or not alias or not Auth.GetRoleSetting(alias, "ConfigureHumanoid") then
		Alerts.BannerNotify({
			Header = "Unable to continue";
			Description = "You don't have access to flying";
			Icon = "rbxassetid://12974197362";
			Host = mod
		})
		return
	end
	
	return NoClipService:NoClip(recipient, state)
end

--// SERVER ANNOUNCEMENT, GLOBAL ANNOUNCEMENT, NOTIFICATION

local SubscriptionTopic = "ExeGlobalAnnouncementService"
local AnnouncementHistory = {}
local Broadcasting = false

events.Activities.Announcement.OnServerEvent:Connect(function(mod, properties)
	local perm = Auth.IsAuthorized(mod.UserId)
	if not perm then return end

	local alias = Auth.GetRoleNameFromRoleTable(perm.Role)

	local allowedGlobal = Auth.GetRoleSetting(alias, "ServerAnnouncement")
	local allowedServer = Auth.GetRoleSetting(alias, "GlobalAnnouncement")

	if not perm or not alias or (not allowedServer or not allowedGlobal) then
		Alerts.BannerNotify({
			Header = "Unable to continue";
			Description = "You don't have access to Announcements.";
			Icon = "rbxassetid://12974197362";
			Host = mod
		})

		return
	end

	--

	local duration = math.clamp(properties.Duration, 1, Configuration.Announcements.MaximumDuration)

	if not properties.Announcement then
		properties.Announcement = properties.Description
	end

	if properties.Global and allowedGlobal then
		local audience

		if properties.Audience == "Everyone" then
			audience = Utilities.GetUserIdsOfEveryone()
		elseif properties.Audience == "Team" then
			audience = Utilities.GetUserIdsOfTeamInServer()
		elseif properties.Audience == "Nonmembers" then
			audience = Utilities.GetUserIdsOfNonmembers()
		else 
			audience = Utilities.GetUserIdsOfTeam(properties.Audience)
		end

		local AnnouncementData = {
			Icon = properties.Icon;
			Header = properties.Header;
			Description = properties.Announcement;
			Duration = duration;
			Host = mod.UserId;
			Timestamp = os.time();
			Audience = properties.Audience
		}

		messaging_service:PublishAsync(SubscriptionTopic, http_service:JSONEncode(AnnouncementData))

		Alerts.BannerNotify({
			Header = "Announcement Posted Successfully";
			Description = "Your announcement may take a moment to push across servers.";
			Icon = "rbxassetid://12966403319";
			Host = mod
		})

		if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogAnnouncements then

			ActivityAuditing.AuditActivity(
				mod.UserId, 
				"Global Announcement: " .. properties.Header .. "\nAnnouncement: " .. properties.Announcement .. "\nAudience: " .. properties.Audience, 
				{})

		end

	elseif not properties.Global and allowedServer then

		local audience

		if properties.Audience == "Everyone" then
			audience = Utilities.GetUserIdsOfEveryone()
		elseif properties.Audience == "Team" then
			audience = Utilities.GetUserIdsOfTeamInServer()
		elseif properties.Audience == "Nonmembers" then
			audience = Utilities.GetUserIdsOfNonmembers()
		else 
			audience = Utilities.GetUserIdsOfTeam(properties.Audience)
		end

		local AnnouncementData = {
			Icon = properties.Icon;
			Header = properties.Header;
			Description = properties.Announcement;
			Duration = duration;
			Host = mod.UserId;
			Timestamp = os.time()
		}

		repeat task.wait(1) until not Broadcasting

		events.Activities.Announcement:FireAllClients(audience, AnnouncementData)

		Broadcasting = true

		Alerts.BannerNotify({
			Header = "Announcement Posted Successfully";
			Description = "Your Announcement was posted across this server.",
			Icon = "rbxassetid://12966403319";
			Host = mod
		})

		if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogAnnouncements then

			ActivityAuditing.AuditActivity(
				mod.UserId, "Server Announcement: " .. properties.Header .. "\nAnnouncement: " .. properties.Announcement .. "\nAudience: " .. properties.Audience,
				audience)

		end

		--
		task.wait(AnnouncementData.Duration + 5)
		--

		Broadcasting = false
	else
		Alerts.BannerNotify({
			Header = "Unable to continue";
			Description = "You don't have access to Server Announcements.";
			Icon = "rbxassetid://12974197362";
			Host = mod
		})

		return
	end
end)

events.Activities.Notify.OnServerEvent:Connect(function(mod, properties)
	local perm = Auth.IsAuthorized(mod.UserId)
	if not perm then return end

	local alias = Auth.GetRoleNameFromRoleTable(perm.Role)

	local allowedNotify = Auth.GetRoleSetting(alias, "Notify")

	if not perm or not alias or (not allowedNotify) then
		Alerts.BannerNotify({
			Header = "Unable to continue";
			Description = "You don't have access to Notifications.";
			Icon = "rbxassetid://12974197362";
			Host = mod
		})

		return
	end

	--

	local duration = math.clamp(properties.Duration, 1, Configuration.Notifications.MaximumDuration)
	local deserialized = Utilities.DeserializeNumberTable(properties.Recipient)
	local userids = {}

	if deserialized then

		for i, id in pairs(deserialized) do
			local recipient = players:GetPlayerByUserId(id)

			if recipient then

				table.insert(userids, id)

				Alerts.BannerNotify({
					Header = properties.Header;
					Description = properties.Notification;
					Duration = duration;
					Icon = properties.Icon;
					Host = recipient
				})

			end
		end

		if #userids > 0 then

			Alerts.BannerNotify({
				Header = "Notification Sent";
				Description = "Your notification was sent to " .. #userids .. "/" .. #deserialized .. " player(s)." ;
				Icon = "rbxassetid://11419719540";
				Host = mod
			})

		else

			Alerts.BannerNotify({
				Header = "Notification Failed to Send";
				Description = "Your notification was failed to send." ;
				Icon = "rbxassetid://11419709766";
				Host = mod
			})
		end

		--

		if Auth.GetRoleSetting(alias, "AuditActivities") and Configuration.Auditing.LogNotifications then

			ActivityAuditing.AuditActivity(
				mod.UserId,
				"Notification Sent to " .. #userids .. "/" .. #deserialized .. " player(s). " 
					.. properties.Header .. "(Header) " .. properties.Notification .. " (Notification)",
				userids)

		end

	else
		Alerts.BannerNotify({
			Header = "Notification Failed";
			Description = "Your notification did not send.";
			Icon = "rbxassetid://11419709766";
			Host = mod
		})
	end
end)

function ExeGlobalAnnouncementServiceSubscription()
	local connection = messaging_service:SubscribeAsync(SubscriptionTopic, function(message)
		local AnnouncementData = http_service:JSONDecode(message.Data)
		if not AnnouncementData then return end

		repeat task.wait(1) until not Broadcasting

		local audience

		if AnnouncementData.Audience == "Everyone" then
			audience = Utilities.GetUserIdsOfEveryone()

		elseif AnnouncementData.Audience == "Team" then
			audience = Utilities.GetUserIdsOfTeamInServer()

		elseif AnnouncementData.Audience == "Nonmembers" then
			audience = Utilities.GetUserIdsOfNonmembers()

		else 
			audience = Utilities.GetUserIdsOfTeam(AnnouncementData.Audience)
		end

		if audience then
			Broadcasting = true

			events.Activities.Announcement:FireAllClients(audience, AnnouncementData)

			--
			task.wait(AnnouncementData.Duration + 5)
			--

			Broadcasting = false
		end
	end)
end

ExeGlobalAnnouncementServiceSubscription()

--// SPECTATE

--// PLAYTIME

local PlaytimeData = {}
local PlaytimeThreads = {}

function TrackPlaytime(player)
	local userid = player.UserId

	PlaytimeData[userid] = PlaytimeData[userid] or 0

	if PlaytimeThreads[userid] then
		task.cancel(PlaytimeThreads[userid])
	end

	PlaytimeThreads[userid] = task.spawn(function()
		while player and players:FindFirstChild(player.Name) do
			task.wait(1)

			if PlaytimeData[userid] then
				PlaytimeData[userid] += 1
			end
		end
	end)
end

players.PlayerAdded:Connect(function(player)
	TrackPlaytime(player)
end)

players.PlayerRemoving:Connect(function(player)
	local userid = player.UserId

	if PlaytimeThreads[userid] then
		task.cancel(PlaytimeThreads[userid])

		PlaytimeThreads[userid] = nil
	end
end)

for i, player in pairs(players:GetPlayers()) do
	TrackPlaytime(player)
end

events.misc.GetPlaytime.OnServerInvoke = function(plr, userid)
	local perm = Auth.IsAuthorized(plr.UserId)
	if not perm then print("Not Authorized") return end

	return PlaytimeData[userid]
end

--// Server Uptime

task.spawn(function()
	while task.wait(1) do
		storage:SetAttribute("ServerUptime", storage:GetAttribute("ServerUptime") + 1)
	end
end)