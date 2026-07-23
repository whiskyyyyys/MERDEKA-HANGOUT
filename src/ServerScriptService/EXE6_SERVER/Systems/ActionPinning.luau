local players = game:GetService("Players")
local replicated_storage = game:GetService("ReplicatedStorage")

local storage = replicated_storage:WaitForChild("EXE6_STORAGE")
local events = storage.events

local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("Exe6", "ActionPinning")

local module = {}
module.__index = module

function getData(userId)
	local success, result = pcall(function()
		return DataStore:GetAsync(tostring(userId))
	end)
	return (success and result) or {}
end

function saveData(userId, data)
	pcall(function()
		DataStore:SetAsync(tostring(userId), data)
	end)
end

function module.Pin(userId, actionName)
	local data = getData(userId)

	for _, v in ipairs(data) do
		if v == actionName then
			return
		end
	end

	table.insert(data, actionName)
	saveData(userId, data)
end

function module.Unpin(userId, actionName)
	local data = getData(userId)

	for i = #data, 1, -1 do
		if data[i] == actionName then
			table.remove(data, i)
		end
	end

	saveData(userId, data)
end

function module.Override(userId, data)
	saveData(userId, data)
end

function module:GetPins(userId)
	return getData(userId)
end

return setmetatable({}, module)