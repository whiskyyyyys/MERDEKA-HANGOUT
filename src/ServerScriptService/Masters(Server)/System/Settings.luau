local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DataStore = DataStoreService:GetDataStore("Masters", "Settings")

local module = {}

local FLUSH_INTERVAL = 30

local Buffer = {}
local BufferStatus = {}

local DEFAULT_SETTINGS = {
	Playback = {
		Crossfade = {
			Enabled = true,
			Duration = 3
		},

		Equalizer = {
			Enabled = false,
			HighGain = 0,
			MidGain = 0,
			LowGain = 0
		},
	},

	Extras = {
		Glow = true,
		PlaybackHaptics = false,
	},

	Socials = {
		ListeningVisibility = true,
		Sharing = true,
	},
}

local function CopyTable(t)
	local copy = {}

	for k, v in t do
		if type(v) == "table" then
			copy[k] = CopyTable(v)
		else
			copy[k] = v
		end
	end

	return copy
end

local function Reconcile(source, template)
	if type(source) ~= "table" then 
		return CopyTable(template) 
	end

	for key, templateValue in template do
		local sourceValue = source[key]

		if sourceValue == nil then
			if type(templateValue) == "table" then
				source[key] = CopyTable(templateValue)
			else
				source[key] = templateValue
			end
			
		elseif type(templateValue) == "table" and type(sourceValue) == "table" then
			Reconcile(sourceValue, templateValue)
		end
	end

	return source
end

local function EnsureLoaded(UserId)
	if not Buffer[UserId] then
		local success, data = pcall(function()
			return DataStore:GetAsync(tostring(UserId))
		end)

		if success and data then
			Buffer[UserId] = Reconcile(data, DEFAULT_SETTINGS)
		else
			Buffer[UserId] = CopyTable(DEFAULT_SETTINGS)
		end

		BufferStatus[UserId] = false
	end

	return Buffer[UserId]
end

function module.FetchSettings(UserId)
	return EnsureLoaded(UserId)
end

function module.SetSettings(UserId, Data)
	local current = EnsureLoaded(UserId)

	for category, settings in pairs(Data) do
		if current[category] then
			for setting, value in pairs(settings) do
				current[category][setting] = value
			end
		end
	end

	BufferStatus[UserId] = true
end

function module.SetSetting(UserId, Category, Setting, Value)
	local current = EnsureLoaded(UserId)

	if current[Category] and current[Category][Setting] ~= nil then
		current[Category][Setting] = Value
		BufferStatus[UserId] = true
	else
		warn(string.format("Settings: Path %s.%s does not exist!", Category, Setting))
	end
end

--

function module.Flush(UserId)
	if BufferStatus[UserId] then
		local success, err = pcall(function()
			DataStore:SetAsync(tostring(UserId), Buffer[UserId])
		end)

		if success then
			BufferStatus[UserId] = false
		else
			warn("Settings: Failed to flush for " .. UserId .. ": " .. err)
		end
	end
end

function module.FlushAll()
	for userId, isDirty in pairs(BufferStatus) do
		if isDirty then
			module.Flush(userId)
		end
	end
end

-- Autosave

task.spawn(function()
	while true do
		task.wait(FLUSH_INTERVAL)
		module.FlushAll()
	end
end)

-- Cleanup

Players.PlayerRemoving:Connect(function(player)
	module.Flush(player.UserId)

	Buffer[player.UserId] = nil
	BufferStatus[player.UserId] = nil
end)

if RunService:IsServer() then
	game:BindToClose(function()
		module.FlushAll()
	end)
end

return module