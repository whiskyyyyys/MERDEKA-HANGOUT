local Signal = {}
Signal.__index = Signal

function Signal.new()
	local self = setmetatable({}, Signal)
	self._event = Instance.new("BindableEvent")
	return self
end

function Signal:Connect(callback)
	return self._event.Event:Connect(callback)
end

function Signal:Once(callback)
	return self._event.Event:Once(callback)
end

function Signal:Fire(...)
	self._event:Fire(...)
end

function Signal:Wait()
	return self._event.Event:Wait()
end

function Signal:Destroy()
	if self._event then
		self._event:Destroy()
		self._event = nil
	end
end

return Signal
