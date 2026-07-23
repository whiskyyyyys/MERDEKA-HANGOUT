local DataStoreService = game:GetService("DataStoreService")
local UserIdDataStore = DataStoreService:GetDataStore("ID")

local ValidUserIdsKey = "UserIdList"
local ExpiredUserIdsKey = "ExpiredUserIds"
local RevokedUserIdsKey = "RevokedUserIds"

local BATCH = 10
local INTERVAL = 60
local MAX_EXPIRED_IDS = 10
local MAX_REVOKED_IDS = 10
local CACHE_EX = 4

local cache = {}
local cacheExpirationTime = 5

local function Cache(key, value)
	local timestamp = tick()

	cache[key] = {value = value, time = timestamp}

	return value
end

local function FetchCache(key)
	local cachedValue = cache[key]
	
	if cachedValue and tick() - cachedValue.time < cacheExpirationTime then
		return cachedValue.value
	end

	return nil
end

local function GetAsync(key)
	local cachedValue = FetchCache(key)
	
	if cachedValue then
		return cachedValue
	end

	local success, value = pcall(function()
		return UserIdDataStore:GetAsync(key)
	end)

	if success then
		Cache(key, value)
	end

	return value
end

local module = {}

function module.SaveUserIds(USERIDs, MODERATORID)
	local success, result = pcall(function()
		local DataKey = GetAsync(ValidUserIdsKey) or {}
		local ExpiredKey = GetAsync(ExpiredUserIdsKey) or {}
		local RevokedKey = GetAsync(RevokedUserIdsKey) or {}

		-- Create lookup for faster access
		local Lookup = {}
		for _, id in ipairs(DataKey) do
			local splitId = id:split(";")
			Lookup[splitId[1]] = true
		end

		-- Remove duplicates from Expired and Revoked keys
		for _, USERID in ipairs(USERIDs) do
			local userIdStr = tostring(USERID)
			for i = #ExpiredKey, 1, -1 do
				if ExpiredKey[i]:split(";")[1] == userIdStr then
					table.remove(ExpiredKey, i)
				end
			end
			for i = #RevokedKey, 1, -1 do
				if RevokedKey[i]:split(";")[1] == userIdStr then
					table.remove(RevokedKey, i)
				end
			end
		end

		-- Save new UserIds
		for _, USERID in ipairs(USERIDs) do
			local userIdWithModerator = tostring(USERID) .. ";" .. tostring(MODERATORID or 0)
			if not Lookup[tostring(USERID)] then
				table.insert(DataKey, userIdWithModerator)
				Lookup[tostring(USERID)] = true
			end
		end

		UserIdDataStore:SetAsync(ValidUserIdsKey, DataKey)
		UserIdDataStore:SetAsync(ExpiredUserIdsKey, ExpiredKey)
		UserIdDataStore:SetAsync(RevokedUserIdsKey, RevokedKey)
	end)

	if not success then
		warn("Failed to save UserIDs:", result)
	end
end

function module.SaveExpiringUserIds(USERIDs, DURATION, MODERATORID)
	local expireTime = os.time() + DURATION
	local success, result = pcall(function()
		local DataKey = GetAsync(ValidUserIdsKey) or {}
		local ExpiredKey = GetAsync(ExpiredUserIdsKey) or {}
		local RevokedKey = GetAsync(RevokedUserIdsKey) or {}
		local Lookup = {}

		-- Create lookup for faster access
		for _, id in ipairs(DataKey) do
			local splitId = id:split(";")
			Lookup[splitId[1]] = id
		end

		-- Remove duplicates from Expired and Revoked keys
		for _, USERID in ipairs(USERIDs) do
			local userIdStr = tostring(USERID)
			for i = #ExpiredKey, 1, -1 do
				if ExpiredKey[i]:split(";")[1] == userIdStr then
					table.remove(ExpiredKey, i)
				end
			end
			for i = #RevokedKey, 1, -1 do
				if RevokedKey[i]:split(";")[1] == userIdStr then
					table.remove(RevokedKey, i)
				end
			end
		end

		-- Save expiring UserIds
		for _, USERID in ipairs(USERIDs) do
			local userIdStr = tostring(USERID)
			local userIdWithTimestamp = userIdStr .. ";" .. tostring(expireTime) .. ";" .. tostring(MODERATORID or 0)

			if Lookup[userIdStr] then
				for i, id in ipairs(DataKey) do
					if id:split(";")[1] == userIdStr then
						DataKey[i] = userIdWithTimestamp
						break
					end
				end
			else
				table.insert(DataKey, userIdWithTimestamp)
			end
		end

		UserIdDataStore:SetAsync(ValidUserIdsKey, DataKey)
		UserIdDataStore:SetAsync(ExpiredUserIdsKey, ExpiredKey)
		UserIdDataStore:SetAsync(RevokedUserIdsKey, RevokedKey)
	end)

	if not success then
		warn("Failed to save expiring UserIDs:", result)
	end
end

function module.RemoveUserIds(USERIDs)
	local success, result = pcall(function()
		local DataKey = GetAsync(ValidUserIdsKey) or {}
		local RevokedKey = GetAsync(RevokedUserIdsKey) or {}
		local Lookup = {}

		-- Create lookup for faster access
		for _, id in ipairs(DataKey) do
			local splitId = id:split(";")
			Lookup[splitId[1]] = id
		end

		-- Remove and revoke UserIds
		for _, USERID in ipairs(USERIDs) do
			local userIdStr = tostring(USERID)

			if Lookup[userIdStr] then
				for i, id in ipairs(DataKey) do
					if id:split(";")[1] == userIdStr then
						table.remove(DataKey, i)
						break
					end
				end

				table.insert(RevokedKey, Lookup[userIdStr])

				if #RevokedKey > MAX_REVOKED_IDS then
					table.remove(RevokedKey, 1)
				end
			end
		end

		UserIdDataStore:SetAsync(ValidUserIdsKey, DataKey)
		UserIdDataStore:SetAsync(RevokedUserIdsKey, RevokedKey)
	end)

	if not success then
		warn("Failed to remove UserIDs:", result)
	end
end

function module.ClearExpiredUserIds()
	local success, result = pcall(function()
		local DataKey = GetAsync(ValidUserIdsKey) or {}
		local ExpiredKey = GetAsync(ExpiredUserIdsKey) or {}
		local currentTime = os.time()
		local validUserIds = {}

		for _, userId in ipairs(DataKey) do
			local parts = userId:split(";")

			if #parts == 3 then
				local id = parts[1]
				local expireTime = tonumber(parts[2])

				if expireTime and currentTime >= expireTime then
					table.insert(ExpiredKey, userId)
					if #ExpiredKey > MAX_EXPIRED_IDS then
						table.remove(ExpiredKey, 1)
					end
				else
					table.insert(validUserIds, userId)
				end
			else
				table.insert(validUserIds, userId)
			end
		end

		UserIdDataStore:SetAsync(ValidUserIdsKey, validUserIds)
		UserIdDataStore:SetAsync(ExpiredUserIdsKey, ExpiredKey)
	end)

	if not success then
		warn("Failed to clean up expired UserIDs:", result)
	end
end

function module.GetUserIds()
	local success, result = pcall(function()
		local DataKey = GetAsync(ValidUserIdsKey) or {}
		local permanentUserIds = {}

		for _, userId in ipairs(DataKey) do
			local split = string.split(userId, ";")
			if #split <= 2 then
				table.insert(permanentUserIds, userId)
			end
		end

		return permanentUserIds
	end)

	if success then
		return result
	else
		warn("Failed to get UserIDs:", result)
		return {}
	end
end

function module.GetExpiringUserIds()
	local success, result = pcall(function()
		local DataKey = GetAsync(ValidUserIdsKey) or {}
		local expiringUserIds = {}

		for _, userId in ipairs(DataKey) do
			local split = string.split(userId, ";")
			
			if #split > 2 then
				table.insert(expiringUserIds, userId)
			end
		end

		return expiringUserIds
	end)

	if success then
		return result
	else
		warn("Failed to get expiring UserIDs:", result)
		return {}
	end
end

function module.GetExpiredUserIds()
	local success, result = pcall(function()
		return GetAsync(ExpiredUserIdsKey) or {}
	end)

	if success then
		return result
	else
		warn("Failed to get expired UserIDs:", result)
		return {}
	end
end

function module.GetRevokedUserIds()
	local success, result = pcall(function()
		return GetAsync(RevokedUserIdsKey) or {}
	end)

	if success then
		return result
	else
		warn("Failed to get revoked UserIDs:", result)
		return {}
	end
end

function module.IsUserIdSaved(USERID)
	local userIdStr = tostring(USERID)

	local function ExistsInList(list)
		for _, id in ipairs(list) do
			if id:split(";")[1] == userIdStr then
				return true
			end
		end
		
		return false
	end

	local success, result = pcall(function()
		local PermanentUserIds = GetAsync(ValidUserIdsKey) or {}
		local ExpiringUserIds = GetAsync(ValidUserIdsKey) or {}

		return ExistsInList(PermanentUserIds) or ExistsInList(ExpiringUserIds)
	end)

	if success then
		return result
	else
		warn("Failed to check if UserID is saved:", result)
		return false
	end
end

function module.ClearOmittedUserIds()
	local success, result = pcall(function()
		UserIdDataStore:RemoveAsync(ExpiredUserIdsKey)
		UserIdDataStore:RemoveAsync(RevokedUserIdsKey)
	end)
	
	if not success then
		warn("Couldn't clear the Expired UserIDs.", result)
	end
end

spawn(function()
	while true do
		module.ClearExpiredUserIds()
		task.wait(INTERVAL)
	end
end)

return module