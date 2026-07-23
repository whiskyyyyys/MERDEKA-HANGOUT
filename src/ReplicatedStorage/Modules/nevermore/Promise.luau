local Promise = {}
Promise.__index = Promise

local STATE_PENDING = "pending"
local STATE_FULFILLED = "fulfilled"
local STATE_REJECTED = "rejected"

local function packValues(...)
	return table.pack(...)
end

local function unpackValues(values)
	return table.unpack(values, 1, values.n)
end

local function isPromiseLike(value)
	return type(value) == "table" and type(value.Then) == "function"
end

function Promise._newEmpty()
	local self = setmetatable({}, Promise)
	self._state = STATE_PENDING
	self._values = nil
	self._queue = {}
	self._yieldSignal = Instance.new("BindableEvent")
	return self
end

function Promise:_finalize(state, ...)
	if self._state ~= STATE_PENDING then
		return
	end

	self._state = state
	self._values = packValues(...)
	self._yieldSignal:Fire()

	for _, entry in ipairs(self._queue) do
		task.spawn(function()
			self:_runEntry(entry)
		end)
	end

	table.clear(self._queue)
end

function Promise:_resolve(...)
	self:_finalize(STATE_FULFILLED, ...)
end

function Promise:_reject(...)
	self:_finalize(STATE_REJECTED, ...)
end

function Promise:_runEntry(entry)
	local nextPromise = entry.nextPromise
	local callback = nil

	if self._state == STATE_FULFILLED then
		callback = entry.onResolve
	else
		callback = entry.onReject
	end

	if type(callback) ~= "function" then
		if self._state == STATE_FULFILLED then
			nextPromise:_resolve(unpackValues(self._values))
		else
			nextPromise:_reject(unpackValues(self._values))
		end
		return
	end

	local ok, result1, result2, result3, result4, result5 = pcall(callback, unpackValues(self._values))
	if not ok then
		nextPromise:_reject(result1)
		return
	end

	if isPromiseLike(result1) then
		result1
			:Then(function(...)
				nextPromise:_resolve(...)
			end)
			:Catch(function(...)
				nextPromise:_reject(...)
			end)
		return
	end

	nextPromise:_resolve(result1, result2, result3, result4, result5)
end

function Promise.new(executor)
	local self = Promise._newEmpty()

	task.spawn(function()
		local ok, err = pcall(executor, function(...)
			self:_resolve(...)
		end, function(...)
			self:_reject(...)
		end)

		if not ok then
			self:_reject(err)
		end
	end)

	return self
end

function Promise.resolve(...)
	local self = Promise._newEmpty()
	self:_resolve(...)
	return self
end

function Promise.reject(...)
	local self = Promise._newEmpty()
	self:_reject(...)
	return self
end

function Promise.spawn(executor)
	return Promise.new(function(resolve, reject)
		local ok, err = pcall(executor, resolve, reject)
		if not ok then
			reject(err)
		end
	end)
end

function Promise.delay(seconds, executor)
	return Promise.new(function(resolve, reject)
		task.delay(seconds, function()
			if type(executor) ~= "function" then
				resolve()
				return
			end

			local ok, err = pcall(executor, resolve, reject)
			if not ok then
				reject(err)
			end
		end)
	end)
end

function Promise:Then(onResolve, onReject)
	local nextPromise = Promise._newEmpty()
	local entry = {
		onResolve = onResolve,
		onReject = onReject,
		nextPromise = nextPromise,
	}

	if self._state == STATE_PENDING then
		table.insert(self._queue, entry)
	else
		task.spawn(function()
			self:_runEntry(entry)
		end)
	end

	return nextPromise
end

function Promise:Catch(onReject)
	return self:Then(nil, onReject)
end

function Promise:Finally(onFinally)
	return self:Then(function(...)
		if type(onFinally) == "function" then
			onFinally()
		end
		return ...
	end, function(...)
		local rejection = packValues(...)
		if type(onFinally) == "function" then
			onFinally()
		end
		return Promise.reject(unpackValues(rejection))
	end)
end

function Promise:Yield()
	if self._state == STATE_PENDING then
		self._yieldSignal.Event:Wait()
	end

	if self._state == STATE_FULFILLED then
		return unpackValues(self._values)
	end

	return false, unpackValues(self._values)
end

function Promise:Destroy()
	if self._yieldSignal then
		self._yieldSignal:Destroy()
		self._yieldSignal = nil
	end
	table.clear(self._queue)
end

return Promise
