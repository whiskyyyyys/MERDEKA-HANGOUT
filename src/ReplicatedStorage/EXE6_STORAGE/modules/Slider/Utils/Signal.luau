-- Connection Class --

--[=[
    @class Connection

    Connection Class
]=]
local Connection = {}
Connection.__index = Connection

--[=[
    @within Connection
    @type callback (...any) -> any

    callback type
    is exportet
]=]
export type callback = (...any) -> ...any

--[=[
    Creates a new connection

    not usable

    @param callback (...any) -> ...any

    @return Connection Object
]=]
function Connection.new(callback)
	return setmetatable({
		Connected = true,
		_callback = callback,
	}, Connection)
end

--[=[
    Disconnects the connection

    ```lua
    Connection:Disconnect()
    ```
]=]
function Connection:Disconnect()
	self.Connected = false
end

-- Make the connection class strict

setmetatable(Connection, {
	__index = function(_, key)
		error(string.format("Attempt to get connection::%s (not a valid member)", tostring(key)))
	end,

	__newIndex = function(_, key)
		error(string.format("Attempt to set connection::%s (not a valid member)", tostring(key)))
	end
})

-- Signal Class --

--[=[
    @class Signal

    Signal by baum (@baum1000000)

    Basicly a RBXScriptConnection but for custom use.
]=]
local Signal = {}
Signal.__index = Signal

--[=[
    Creates a new Signal

    ```lua
    local signal = Signal.new()
    ```
]=]
function Signal.new()
	return setmetatable({
		_listeners = {},
	}, Signal)
end

--[=[
    Checks if the Obj is a Signal

    @return boolean

    ```lua
    Signal.Is(RandomSignal)
    ```
]=]
function Signal.Is(obj: {any})
	return getmetatable(obj) == Signal
end

--[=[
    Connects a function to the signal

    @param callback (...any) -> ...any

    @return Connection Object

    ```lua
    local Connection = signal:Connect(function(...: any)
        print(...)
    end)
    ```
]=]
function Signal:Connect(callback: callback)
	assert(typeof(callback) == "function", string.format("Invalid argument #1 (function expected got %s)", typeof(callback)))

	local _connection = Connection.new(callback)

	table.insert(self._listeners, _connection)

	return _connection
end

--[=[
    Connects a function to the signal in parallel

    @param callback (...any) -> ...any

    @return Connection Object

    ```lua
    local Connection = signal:ConnectParallel(function(...: any)
        print(...)
    end)
    ```
]=]
function Signal:ConnectParallel(callback: callback)
	assert(typeof(callback) == "function", string.format("Invalid argument #1 (function expected got %s)", typeof(callback)))

	task.desynchronize()

	self:Connect(callback)

	task.synchronize()
end

--[=[
    Connects a function to the signal once

    @param callback (...any) -> ...any

    @return Connection Object

    ```lua
    local Connection = signal:Once(function(...: any)
        print(...)
    end)
    ```
]=]
function Signal:Once(callback: callback)
	local _connection = nil

	_connection = self:Connect(function(...)
		_connection:Disconnect()

		callback(...)
	end)

	return _connection
end

--[=[
    Waits until the signal is fired

    @return ... any

    ```lua
    local arg1 = signal:Wait()
    ```
]=]
function Signal:Wait()
	local waitCoroutine = coroutine.running()

	self:Once(function(...)
		task.spawn(waitCoroutine, ...)
	end)

	return coroutine.yield()
end

--[=[
    Fires the signal

    @param ... any

    ```lua
    signal:Fire("Hello", "World!")
    ```
]=]
function Signal:Fire(...: any) -- Call the callbacks from every listener
	for i, v in ipairs(self._listeners) do
		if v.Connected then
			task.spawn(function(...)
				v._callback(...)
			end, ...)
		else
			table.remove(self._listeners, i)
		end
	end
end

--[=[
    Fires the signal in parallel

    @param ... any

    ```lua
    signal:FireParallel("Hello", "World!")
    ```
]=]
function Signal:FireParallel(...: any) -- Call the callbacks from every listener in Parallel
	task.desynchronize()

	self:Fire(...)

	task.synchronize()
end

--[=[
    Disconnects all listeners

    ```lua
    signal:DisconnectAll()
    ```
]=]
function Signal:Destroy()
	for i, v in ipairs(self._listeners) do
		v:Disconnect()
	end

	table.clear(self._listeners)
end

--[=[
    @within Signal
    @method Destroy

    Disconnects all listeners

    ```lua
    signal:Destroy()
    ```
]=]
Signal.Destroy = Signal.DisconnectAll

-- Make the signal class strict

setmetatable(Signal, {
	__index = function(_, key)
		error(string.format("Attempt to get signal::%s (not a valid member)", tostring(key)))
	end,

	__newIndex = function(_, key)
		error(string.format("Attempt to set signal::%s (not a valid member)", tostring(key)))
	end
})

return Signal