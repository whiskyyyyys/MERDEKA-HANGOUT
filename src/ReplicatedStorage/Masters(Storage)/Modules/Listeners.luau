local RunService = game:GetService("RunService")

local module = {}
local Listeners = {}

function module.AddListener(UserId)
	if not RunService:IsServer() then return end
	
	Listeners[UserId] = {
		CurrentSoundId = 0,
		ContinuePlaying = {},
		Queue = {}
	}
end

function module.RemoveListener(UserId)
	if not RunService:IsServer() then return end
	
	Listeners[UserId] = nil
end

function module.UpdateListener(UserId, Data)
	if not RunService:IsServer() then return end
	
	Listeners[UserId] = Data
end

function module.GetListeners()
	return Listeners
end

function module.GetListener(UserId)
	return Listeners[UserId]
end

return module