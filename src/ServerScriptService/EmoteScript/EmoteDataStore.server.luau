-- Favorites DataStore ServerScript
-- Supports:
-- 1) New remotes: ReplicatedStorage.Remotes.EmoteRemotes
--    - LoadFavorites (RemoteFunction)
--    - SaveFavorite (RemoteEvent)
-- 2) Legacy remotes (backward compatibility):
--    - ReplicatedStorage.Remotes.LoadFavorites (RemoteEvent)
--    - ReplicatedStorage.Remotes.SaveFavorites (RemoteEvent)

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CONFIG = {
	DataStoreName = "PlayerFavoriteEmotes_v1",
	RemotesFolderName = "Remotes",
	EmoteRemotesFolderName = "EmoteRemotes",
	SaveRetries = 3,
	RetryDelay = 1
}

local EmoteDataStore = DataStoreService:GetDataStore(CONFIG.DataStoreName)
local favoritesCache = {}

local function deepCopyFavorites(favorites)
	return {
		dances = table.clone(favorites.dances),
		poses = table.clone(favorites.poses)
	}
end

local function normalizeName(value)
	if typeof(value) ~= "string" then
		return nil
	end
	local trimmed = string.match(value, "^%s*(.-)%s*$")
	if trimmed == "" then
		return nil
	end
	return trimmed
end

local function normalizeList(rawList)
	if typeof(rawList) ~= "table" then
		return {}
	end

	local list = {}
	local seen = {}

	for _, value in pairs(rawList) do
		local name = normalizeName(value)
		if name and not seen[name] then
			seen[name] = true
			table.insert(list, name)
		end
	end

	table.sort(list, function(a, b)
		return string.lower(a) < string.lower(b)
	end)

	return list
end

local function normalizeFavorites(rawFavorites)
	if typeof(rawFavorites) ~= "table" then
		return {dances = {}, poses = {}}
	end

	-- Accept old keys and legacy array format
	local dancesRaw = rawFavorites.dances or rawFavorites.Dances or rawFavorites.dance or rawFavorites
	local posesRaw = rawFavorites.poses or rawFavorites.Poses or rawFavorites.pose

	return {
		dances = normalizeList(dancesRaw),
		poses = normalizeList(posesRaw)
	}
end

local function userKey(player)
	return "Player_" .. player.UserId
end

local function saveFavorites(player, favorites)
	local normalized = normalizeFavorites(favorites)

	for attempt = 1, CONFIG.SaveRetries do
		local success = pcall(function()
			EmoteDataStore:SetAsync(userKey(player), normalized)
		end)

		if success then
			favoritesCache[player.UserId] = normalized
			return true, deepCopyFavorites(normalized)
		end

		if attempt < CONFIG.SaveRetries then
			task.wait(CONFIG.RetryDelay)
		end
	end

	return false, deepCopyFavorites(normalized)
end

local function loadFavorites(player)
	local cached = favoritesCache[player.UserId]
	if cached then
		return deepCopyFavorites(cached)
	end

	local data = nil
	local success = false

	for attempt = 1, CONFIG.SaveRetries do
		success, data = pcall(function()
			return EmoteDataStore:GetAsync(userKey(player))
		end)

		if success then
			break
		end

		if attempt < CONFIG.SaveRetries then
			task.wait(CONFIG.RetryDelay)
		end
	end

	if not success then
		warn(("[EMOTE] Failed to load favorites for %s (%d). Returning empty."):format(player.Name, player.UserId))
	end

	local normalized = normalizeFavorites(data)
	favoritesCache[player.UserId] = normalized
	return deepCopyFavorites(normalized)
end

local function toggleEntry(list, emoteName)
	local index = table.find(list, emoteName)
	if index then
		table.remove(list, index)
	else
		table.insert(list, emoteName)
	end

	table.sort(list, function(a, b)
		return string.lower(a) < string.lower(b)
	end)
end

local function normalizeCategory(rawCategory)
	if typeof(rawCategory) ~= "string" then
		return nil
	end

	local lower = string.lower(rawCategory)
	if lower == "dance" or lower == "dances" then
		return "dances"
	end
	if lower == "pose" or lower == "poses" then
		return "poses"
	end

	return nil
end

local remotesFolder = ReplicatedStorage:WaitForChild(CONFIG.RemotesFolderName)
local emoteRemotesFolder = remotesFolder:FindFirstChild(CONFIG.EmoteRemotesFolderName)
if not emoteRemotesFolder then
	emoteRemotesFolder = Instance.new("Folder")
	emoteRemotesFolder.Name = CONFIG.EmoteRemotesFolderName
	emoteRemotesFolder.Parent = remotesFolder
end

local loadFavoritesRemoteFunction = emoteRemotesFolder:FindFirstChild("LoadFavorites")
if loadFavoritesRemoteFunction and not loadFavoritesRemoteFunction:IsA("RemoteFunction") then
	warn("[EMOTE] Remotes.EmoteRemotes.LoadFavorites exists but is not a RemoteFunction.")
	loadFavoritesRemoteFunction = nil
end
if not loadFavoritesRemoteFunction then
	loadFavoritesRemoteFunction = Instance.new("RemoteFunction")
	loadFavoritesRemoteFunction.Name = "LoadFavorites"
	loadFavoritesRemoteFunction.Parent = emoteRemotesFolder
end

local saveFavoriteRemoteEvent = emoteRemotesFolder:FindFirstChild("SaveFavorite")
if saveFavoriteRemoteEvent and not saveFavoriteRemoteEvent:IsA("RemoteEvent") then
	warn("[EMOTE] Remotes.EmoteRemotes.SaveFavorite exists but is not a RemoteEvent.")
	saveFavoriteRemoteEvent = nil
end
if not saveFavoriteRemoteEvent then
	saveFavoriteRemoteEvent = Instance.new("RemoteEvent")
	saveFavoriteRemoteEvent.Name = "SaveFavorite"
	saveFavoriteRemoteEvent.Parent = emoteRemotesFolder
end

local legacyLoadFavoritesEvent = remotesFolder:FindFirstChild("LoadFavorites")
if legacyLoadFavoritesEvent and not legacyLoadFavoritesEvent:IsA("RemoteEvent") then
	legacyLoadFavoritesEvent = nil
end

local legacySaveFavoritesEvent = remotesFolder:FindFirstChild("SaveFavorites")
if legacySaveFavoritesEvent and not legacySaveFavoritesEvent:IsA("RemoteEvent") then
	legacySaveFavoritesEvent = nil
end

loadFavoritesRemoteFunction.OnServerInvoke = function(player)
	return loadFavorites(player)
end

saveFavoriteRemoteEvent.OnServerEvent:Connect(function(player, emoteName, category)
	local normalizedName = normalizeName(emoteName)
	local normalizedCategory = normalizeCategory(category)
	if not normalizedName or not normalizedCategory then
		return
	end

	local favorites = loadFavorites(player)
	toggleEntry(favorites[normalizedCategory], normalizedName)

	local success, savedFavorites = saveFavorites(player, favorites)
	if not success then
		warn(("[EMOTE] Failed to save toggled favorite for %s (%d)."):format(player.Name, player.UserId))
	end

	saveFavoriteRemoteEvent:FireClient(player, savedFavorites)
end)

if legacyLoadFavoritesEvent then
	legacyLoadFavoritesEvent.OnServerEvent:Connect(function(player)
		local favorites = loadFavorites(player)
		legacyLoadFavoritesEvent:FireClient(player, favorites)
	end)
end

if legacySaveFavoritesEvent then
	legacySaveFavoritesEvent.OnServerEvent:Connect(function(player, favorites)
		local success, savedFavorites = saveFavorites(player, favorites)
		if not success then
			warn(("[EMOTE] Failed to save legacy favorites for %s (%d)."):format(player.Name, player.UserId))
		end

		if legacyLoadFavoritesEvent then
			legacyLoadFavoritesEvent:FireClient(player, savedFavorites)
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	favoritesCache[player.UserId] = nil
end)
