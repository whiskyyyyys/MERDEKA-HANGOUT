local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local storage = ReplicatedStorage:WaitForChild("Masters(Storage)")
local events = storage.Events

local module = {}

function module.GetOnlineStations()
	if RunService:IsServer() then
		local StationsIndex = events.Modules.OnlineStations.GetStations:Invoke()
		if not StationsIndex then return end

		return StationsIndex
		
	elseif RunService:IsClient() then 
		local StationsIndex = events.Modules.OnlineStations.GetStationsIndex:InvokeServer()
		if not StationsIndex then return end

		return StationsIndex
	end
end

function module.GetOnlineStationByStationId(StationId)
	local StationsIndex = module.GetOnlineStations()
	if not StationsIndex then return end
	
	return StationsIndex[StationId]
end

return module