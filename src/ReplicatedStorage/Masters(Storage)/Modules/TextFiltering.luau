local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local storage = ReplicatedStorage:WaitForChild("Masters(Storage)")
local events = storage.Events

local module = {}

local function mask(text)
	return string.rep("#", #text)
end

local function filterForPlayer(text, fromUserId, toPlayer)
	local success, result = pcall(function()
		local filterResult = TextService:FilterStringAsync(text, fromUserId)
		return filterResult:GetChatForUserAsync(toPlayer.UserId)
	end)

	if success and result then
		return result
	else
		warn("Filter failed:", result)
		return mask(text)
	end
end

local function filterBroadcast(text, fromUserId)
	local success, result = pcall(function()
		local filterResult = TextService:FilterStringAsync(text, fromUserId)
		return filterResult:GetNonChatStringForBroadcastAsync()
	end)

	if success and result then
		return result
	else
		warn("Filter failed:", result)
		return mask(text)
	end
end

-- Functions

function module.FilterForPlayer(text, fromUserId, toPlayer)
	if RunService:IsServer() then
		return filterForPlayer(text, fromUserId, toPlayer)
		
	elseif RunService:IsClient() then
		
		local success, result = pcall(function()
			return events.Modules.TextFiltering.FilterText:InvokeServer("Player", text, toPlayer.UserId)
		end)

		if success and result then
			return result
		else
			warn("Remote failed:", result)
			return mask(text)
		end
	end
end

function module.FilterBroadcast(text, fromUserId)
	if RunService:IsServer() then
		return filterBroadcast(text, fromUserId)
		
	elseif RunService:IsClient() then
		
		local success, result = pcall(function()
			return events.Modules.TextFiltering.FilterText:InvokeServer("Broadcast", text)
		end)

		if success and result then
			return result
		else
			warn("Remote failed:", result)
			return mask(text)
		end
	end
end

return module