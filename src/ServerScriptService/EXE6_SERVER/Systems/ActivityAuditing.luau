local datastore_service = game:GetService("DataStoreService")
local replicated_storage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local server = script.Parent.Parent

local Auth = require(server.Auth)
local IdSaving = require(server.Systems.IdSaving)
local WebhookAuditing = require(server.Systems.WebhookAuditing)
local VariableEncoding = require(server.Systems.VariableEncoding)
local SafeTeleport = require(server.Systems.SafeTeleport)
local ChatLogging = require(server.Systems.ChatLogging)

local Utilities = require(storage.modules.Utilities)
local Alerts = require(storage.modules.Alerts)

local DataStoreService = game:GetService("DataStoreService")
local AuditDataStore = DataStoreService:GetDataStore("Exe6", "ActivityAudits")

local MAX_LOG_LIMIT = 500

local module = {}

function module.AuditActivity(Moderator, Message, Recipients)
	assert(typeof(Moderator) == "number", "Moderator must be a number.")
	assert(typeof(Message) == "string", "Message must be a string.")
	assert(typeof(Recipients) == "table", "Recipients must be a table of numbers.")
	
	local mod = players:GetPlayerByUserId(Moderator)

	local success, err = pcall(function()
		local activities = AuditDataStore:GetAsync("Activities") or {}

		table.insert(activities, {
			Moderator = Moderator,
			Message = Message,
			Recipients = Recipients or {},
			JobID = game.JobId,
			Timestamp = os.time()
		})

		if #activities > MAX_LOG_LIMIT then
			local excessCount = #activities - MAX_LOG_LIMIT
			
			for _ = 1, excessCount do
				table.remove(activities, 1)
			end
		end

		AuditDataStore:SetAsync("Activities", activities)
		
		task.spawn(function()
			if not mod then
				warn("Failed to audit on webhook; No team member was found.")
				return;
			end
			WebhookAuditing:AuditOnWebhook(Message, "**Team member:** `"..mod.DisplayName.." ("..mod.Name..")`", Color3.new(1, 1, 1), mod, Recipients, os.time())
		end)
	end)

	if not success then
		warn("Failed to save audit activity: " .. tostring(err))
	end
end

function module.GetAuditedActivities(chunkSize)
	assert(typeof(chunkSize) == "number" and chunkSize > 0, "chunkSize must be a positive number.")

	local success, activities = pcall(function()
		return AuditDataStore:GetAsync("Activities") or {}
	end)

	if not success then
		warn("Failed to retrieve audited activities: " .. tostring(activities))
		return {}
	end

	local chunks = {}
	
	for i = 1, #activities, chunkSize do
		table.insert(chunks, { unpack(activities, i, i + chunkSize - 1) })
	end

	return chunks
end

return module