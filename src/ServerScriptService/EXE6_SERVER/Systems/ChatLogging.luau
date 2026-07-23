local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local events = storage.events

local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("Exe6", "ChatLogging")

local Auth = require(script.Parent.Parent.Auth)
local Configuration = Auth.GetConfigurations()

local Utilities = require(storage.modules.Utilities)

local MaxChats = 200

local module = {}

function module:LogChats(UserID, collected_chats)
	if not Configuration.ChatHistory.Enabled then
		return
	end
	
	assert(typeof(UserID) == "number", "User ID must be a number.")

	local success, err = pcall(function()
		local plrChats = DataStore:GetAsync(UserID) or {}
		
		for pos, info in pairs(collected_chats) do
			local message = info.Message
			
			if Configuration.ChatHistory.FilterMessages then
				message = Utilities.FilterString(message, UserID, true)
			end
			
			table.insert(plrChats, {
				Timestamp = info.Timestamp,
				Message = message,
			})
			
		end
		
		if #plrChats > MaxChats then
			local excessCount = #plrChats - MaxChats
			
			for _ = 1, excessCount do
				table.remove(plrChats, 1)
			end
		end
		
		DataStore:SetAsync(UserID, plrChats)
	end)
	
	if not success then
		warn("Failed to log chat: "..tostring(err))
	end
	
end

function module:GetLoggedChats(UserID)
	if Configuration.ChatHistory.Enabled == false then
		return nil;
	end
	
	assert(typeof(UserID) == "number", "User ID must be a number.")

	local success, logs = pcall(function()
		return DataStore:GetAsync(UserID) or {}
	end)

	if not success then
		warn("Failed to retrieve chat logs: " .. tostring(logs))
		return {}
	end
	
	return logs
end

return module