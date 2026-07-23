local Signal = {}
Signal.__index = Signal
Signal.ClassName = "Signal"

function Signal.new()
	local self = setmetatable({
		_bindable = Instance.new("BindableEvent"),
		_args = nil,
		_argCount = nil,
		_connections = {}, -- store all connections
	}, Signal)

	return self
end

function Signal:Fire(...)
	self._args = {...}
	self._argCount = select("#", ...)

	self._bindable:Fire()
end

function Signal:fire(...)
	return self:Fire(...)
end

function Signal:Connect(handler)
	if not (type(handler) == "function") then
		error(("connect(%s)"):format(typeof(handler)), 2)
	end

	local conn = self._bindable.Event:Connect(function()
		handler(unpack(self._args, 1, self._argCount))
	end)

	table.insert(self._connections, conn)
	return conn
end

function Signal:connect(...)
	return self:Connect(...)
end

function Signal:Wait()
	self._bindable.Event:Wait()
	return unpack(self._args, 1, self._argCount)
end

function Signal:wait()
	return self:Wait()
end

function Signal:Disconnect()
	for _, conn in ipairs(self._connections) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	self._connections = {}
end

function Signal:Destroy()
	self:Disconnect()

	if self._bindable then
		self._bindable:Destroy()
		self._bindable = nil
	end

	self._args = nil
	self._argCount = nil
	setmetatable(self, nil)
end

function Signal:destroy()
	return self:Destroy()
end

return Signal