local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local storage = ReplicatedStorage:WaitForChild("Masters(Storage)")
local events = storage.Events

local module = {}

function module.GetConfiguration()
	if RunService:IsClient() then
		local ConfigurationIndex = events.Modules.Configuration.GetConfiguration:InvokeServer()
		if not ConfigurationIndex then return end

		return ConfigurationIndex
		
	elseif RunService:IsServer() then
		local ConfigurationIndex = events.Modules.Configuration.GetConfigurationServer:Invoke()
		if not ConfigurationIndex then return end

		return ConfigurationIndex

	end
end

function module.GetLocalStations()
	if RunService:IsClient() then
		local ConfigurationIndex = events.Modules.Configuration.GetLocalStations:InvokeServer()
		if not ConfigurationIndex then return end

		return ConfigurationIndex

	elseif RunService:IsServer() then
		local ConfigurationIndex = events.Modules.Configuration.GetLocalStationsServer:Invoke()
		if not ConfigurationIndex then return end

		return ConfigurationIndex

	end
end

function module.GetLocalStationByStationId(StationId)
	if RunService:IsClient() then
		local ConfigurationIndex = events.Modules.Configuration.GetLocalStations:InvokeServer()
		if not ConfigurationIndex then return end
		
		local Station
		
		for i, v in ConfigurationIndex do
			if v.StationId == StationId then
				Station = v
			end
		end

		return Station

	elseif RunService:IsServer() then
		local ConfigurationIndex = events.Modules.Configuration.GetLocalStationsServer:Invoke()
		if not ConfigurationIndex then return end

		local Station

		for i, v in ConfigurationIndex do
			if v.StationId == StationId then
				Station = v
			end
		end

		return Station
	end
end

return module