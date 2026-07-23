local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("Masters", "Onboarding")

local module = {}

-- Configuration

local DEFAULT_CONFIGURATION = {
	Access = {
		PermitEveryone = true,
		LinkPasses = {},
		LinkGroups = {},
		LinkPlayers = {}
	},
	
	CustomSections = {
		[1773512632.7605128] = {
			Name = "To Start With",
			Songs = {
				134442774405724, 
				123771703997621, 
				73653663125040,
				96276775850169,
				111258397063326,
				97437703752614,
				93549332244711,
				76848507102304,
				124170270472638,
				109424772693906,
				74745519248340,
				119972225294781,
				115503424120572,
				1846933032,
				134630098665537,
			}
		}
	},
	
	Stations = {
		AutoStart = "",
		OnlineStations = true,
	}
}

local CurrentConfig

local function Reconcile(target, template)
	local skipKeys = {
		CustomSections = true,
		LinkGroups = true,
		LinkPlayers = true,
		LinkPasses = true
	}

	for key, value in template do
		if skipKeys[key] then 
			if target[key] == nil then
				target[key] = value
			end
			
			continue 
		end

		if type(value) == "table" then
			if type(target[key]) ~= "table" then
				target[key] = {}
			end

			Reconcile(target[key], value)
		else
			if target[key] == nil then
				target[key] = value
			end
		end
	end

	return target
end

local function DeepCopy(original)
	local copy = {}
	
	for k, v in original do
		if type(v) == "table" then
			v = DeepCopy(v)
		end
		
		copy[k] = v
	end
	
	return copy
end

function module.GetConfigurationAsync()	
	if CurrentConfig then return DeepCopy(CurrentConfig) end

	local success, savedData = pcall(function()
		return DataStore:GetAsync("Configuration")
	end)

	if success and savedData then
		CurrentConfig = Reconcile(savedData, DEFAULT_CONFIGURATION)
	else
		CurrentConfig = table.clone(DEFAULT_CONFIGURATION)
	end
	
	return DeepCopy(CurrentConfig)
end

-- Stations

local CurrentStations

function module.GetStationsAsync()	
	if CurrentStations then return DeepCopy(CurrentStations) end

	local success, savedData = pcall(function()
		return DataStore:GetAsync("Stations")
	end)

	if success and savedData then
		CurrentStations = savedData
	else
		CurrentStations = {}
	end

	return DeepCopy(CurrentStations)
end

return module