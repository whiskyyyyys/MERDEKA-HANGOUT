local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local PlayerDataService = {}

local DATA_VERSION = 2
local mainStore = DataStoreService:GetDataStore("FishingPlayerData_v1")
local backupStore = DataStoreService:GetDataStore("FishingPlayerData_v1_Backup")

local MAX_RETRIES = 5
local RETRY_BASE_DELAY = 1.5
local SESSION_STALE_SECONDS = 90
local AUTOSAVE_INTERVAL = 120
local QUICK_SAVE_DEBOUNCE = 3 -- FIX: save cepat beberapa detik setelah dapat ikan, jaga-jaga disconnect mendadak
local MAX_INVENTORY_SIZE = 300

local SESSION_ID = (game.JobId ~= "" and game.JobId) or HttpService:GenerateGUID(false)
local IS_STUDIO = RunService:IsStudio()

local profiles = {}
local pendingQuickSave = {}

local function deepCopy(tbl)
	local copy = {}
	for k, v in pairs(tbl) do
		copy[k] = (type(v) == "table") and deepCopy(v) or v
	end
	return copy
end

local function defaultData()
	return {
		DataVersion = DATA_VERSION,
		Inventory = {},
		OwnedSkins = {"RodDefault"},
		EquippedSkin = "RodDefault",
		ActiveSession = nil,
	}
end

local function sanitizeData(raw)
	if typeof(raw) ~= "table" then
		return defaultData()
	end

	local clean = defaultData()

	if typeof(raw.Inventory) == "table" then
		for _, entry in raw.Inventory do
			if typeof(entry) == "table"
				and typeof(entry.name) == "string"
				and typeof(entry.rarity) == "string"
				and typeof(entry.weightKg) == "number"
				and typeof(entry.scaleFactor) == "number"
				and entry.weightKg > 0 and entry.weightKg < 1000
				and entry.scaleFactor > 0 and entry.scaleFactor < 20
			then
				if #clean.Inventory < MAX_INVENTORY_SIZE then
					table.insert(clean.Inventory, {
						name = entry.name,
						rarity = entry.rarity,
						weightKg = entry.weightKg,
						scaleFactor = entry.scaleFactor,
					})
				end
			end
		end
	end

	if typeof(raw.OwnedSkins) == "table" then
		local owned = {}
		local hasDefault = false
		for _, skinName in raw.OwnedSkins do
			if typeof(skinName) == "string" then
				table.insert(owned, skinName)
				if skinName == "RodDefault" then hasDefault = true end
			end
		end
		if not hasDefault then table.insert(owned, "RodDefault") end
		clean.OwnedSkins = owned
	end

	if typeof(raw.EquippedSkin) == "string" then
		clean.EquippedSkin = raw.EquippedSkin
	end

	if typeof(raw.ActiveSession) == "table" then
		clean.ActiveSession = raw.ActiveSession
	end

	return clean
end

local function safeCall(fn)
	local attempt = 0
	while attempt < MAX_RETRIES do
		attempt += 1
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn("[PlayerDataService] Percobaan", attempt, "gagal:", result)
		task.wait(RETRY_BASE_DELAY * attempt)
	end
	return false, nil
end

local function keyFor(userId)
	return "Player_" .. tostring(userId)
end

-- Session-lock ini HANYA menjaga proses LOAD (mencegah 2 server sama-sama
-- memuat & bermain dengan data yang sama -- itu yang menyebabkan dupe).
local function claimSession(key)
	if IS_STUDIO then
		local claimed = false
		local finalData = nil
		safeCall(function()
			return mainStore:UpdateAsync(key, function(oldData)
				local data = sanitizeData(oldData)
				data.ActiveSession = {SessionId = SESSION_ID, Timestamp = os.time()}
				claimed = true
				finalData = data
				return data
			end)
		end)
		return claimed, finalData or defaultData()
	end

	local claimed = false
	local finalData = nil

	local ok = safeCall(function()
		return mainStore:UpdateAsync(key, function(oldData)
			local data = sanitizeData(oldData)

			if data.ActiveSession
				and data.ActiveSession.SessionId ~= SESSION_ID
				and os.time() - (data.ActiveSession.Timestamp or 0) < SESSION_STALE_SECONDS
			then
				claimed = false
				return nil
			end

			data.ActiveSession = {SessionId = SESSION_ID, Timestamp = os.time()}
			claimed = true
			finalData = data
			return data
		end)
	end)

	if not ok then return false, nil end
	return claimed, finalData
end

function PlayerDataService.Load(player)
	local key = keyFor(player.UserId)
	local claimed, data = claimSession(key)

	if not claimed then
		player:Kick("Data kamu masih diproses di server lain. Coba join ulang beberapa saat lagi.")
		return
	end

	profiles[player] = {Data = data, Key = key, Loaded = true, Dirty = false}
end

function PlayerDataService.IsLoaded(player)
	local profile = profiles[player]
	return profile ~= nil and profile.Loaded == true
end

function PlayerDataService.GetInventory(player)
	local profile = profiles[player]
	if not profile then return {} end
	return deepCopy(profile.Data.Inventory)
end

-- FIX: sekarang otomatis jadwalkan quick-save tiap kali inventory berubah,
-- bukan cuma mengandalkan autosave 2 menit / save pas leave.
local function scheduleQuickSave(player)
	if pendingQuickSave[player] then return end
	pendingQuickSave[player] = true

	task.delay(QUICK_SAVE_DEBOUNCE, function()
		pendingQuickSave[player] = nil
		local profile = profiles[player]
		if profile and profile.Dirty then
			PlayerDataService.Save(player)
		end
	end)
end

function PlayerDataService.AddFish(player, fishName, rarity, weightKg, scaleFactor)
	local profile = profiles[player]
	if not profile then return false end

	if typeof(fishName) ~= "string" or typeof(rarity) ~= "string"
		or typeof(weightKg) ~= "number" or typeof(scaleFactor) ~= "number"
	then
		return false
	end

	if #profile.Data.Inventory >= MAX_INVENTORY_SIZE then
		table.remove(profile.Data.Inventory, 1)
	end

	table.insert(profile.Data.Inventory, {
		name = fishName,
		rarity = rarity,
		weightKg = weightKg,
		scaleFactor = scaleFactor,
	})

	profile.Dirty = true
	scheduleQuickSave(player)
	return true
end

function PlayerDataService.RemoveFish(player, fishName, rarity, weightKg, scaleFactor)
	local profile = profiles[player]
	if not profile then return false end

	for i, entry in profile.Data.Inventory do
		if entry.name == fishName
			and entry.rarity == rarity
			and math.abs(entry.weightKg - weightKg) < 0.001
			and math.abs(entry.scaleFactor - scaleFactor) < 0.001
		then
			table.remove(profile.Data.Inventory, i)
			profile.Dirty = true
			scheduleQuickSave(player)
			return true
		end
	end
	return false
end

-- ===== Skin rod =====

function PlayerDataService.GetOwnedSkins(player)
	local profile = profiles[player]
	if not profile then return {"RodDefault"} end
	return deepCopy(profile.Data.OwnedSkins)
end

function PlayerDataService.IsSkinOwned(player, skinName)
	local profile = profiles[player]
	if not profile then return skinName == "RodDefault" end
	for _, owned in profile.Data.OwnedSkins do
		if owned == skinName then return true end
	end
	return false
end

function PlayerDataService.AddOwnedSkin(player, skinName)
	local profile = profiles[player]
	if not profile then return false end
	if PlayerDataService.IsSkinOwned(player, skinName) then return true end

	table.insert(profile.Data.OwnedSkins, skinName)
	profile.Dirty = true
	scheduleQuickSave(player)
	return true
end

function PlayerDataService.GetEquippedSkin(player)
	local profile = profiles[player]
	if not profile then return "RodDefault" end
	return profile.Data.EquippedSkin
end

function PlayerDataService.SetEquippedSkin(player, skinName)
	local profile = profiles[player]
	if not profile then return false end
	profile.Data.EquippedSkin = skinName
	profile.Dirty = true
	scheduleQuickSave(player)
	return true
end

-- ===== Save/load infra =====

-- FIX UTAMA: dulu ada pengecekan ulang ActiveSession di sini yang bisa diam-diam
-- MEMBATALKAN penulisan (return nil) tapi tetap menandai Dirty=false seolah berhasil --
-- itu penyebab "kadang ke-save kadang enggak". Sekarang begitu profile berhasil di-Load
-- (yang sudah menegakkan 1-server-1-lock), proses save SELALU menulis data terbaru,
-- tanpa validasi ulang yang berisiko gagal diam-diam.
local function saveData(player, releaseSession)
	local profile = profiles[player]
	if not profile then return end

	local key = profile.Key
	local dataToSave = deepCopy(profile.Data)
	dataToSave.DataVersion = DATA_VERSION
	dataToSave.ActiveSession = releaseSession and nil or {SessionId = SESSION_ID, Timestamp = os.time()}

	local ok = safeCall(function()
		return mainStore:UpdateAsync(key, function()
			return dataToSave
		end)
	end)

	if ok then
		profile.Dirty = false
		pcall(function()
			backupStore:SetAsync(key, dataToSave)
		end)
	else
		warn("[PlayerDataService] GAGAL simpan data", player.Name, "-- akan dicoba lagi (Dirty tetap true)")
	end
end

function PlayerDataService.Save(player)
	saveData(player, false)
end

function PlayerDataService.Release(player)
	if profiles[player] then
		saveData(player, true)
		profiles[player] = nil
	end
	pendingQuickSave[player] = nil
end

function PlayerDataService.Init()
	Players.PlayerAdded:Connect(function(player)
		PlayerDataService.Load(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerDataService.Release(player)
	end)

	for _, player in Players:GetPlayers() do
		if not profiles[player] then
			PlayerDataService.Load(player)
		end
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player, profile in profiles do
				if profile.Dirty then
					PlayerDataService.Save(player)
				end
			end
		end
	end)

	game:BindToClose(function()
		if IS_STUDIO then
			task.wait(1)
			return
		end
		for _, player in Players:GetPlayers() do
			PlayerDataService.Release(player)
		end
	end)
end

return PlayerDataService