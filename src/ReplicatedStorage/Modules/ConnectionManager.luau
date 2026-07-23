local Promise = require(script.Parent.nevermore.Promise)

local ConnectionManager = {}
local providers = {}

local function isPromiseLike(value)
	return type(value) == "table" and type(value.Then) == "function"
end

function ConnectionManager.addProvider(providerName, provider)
	providers[providerName] = provider
	return provider
end

ConnectionManager.registerProvider = ConnectionManager.addProvider
ConnectionManager.setProvider = ConnectionManager.addProvider

function ConnectionManager.getProvider(providerName)
	return providers[providerName]
end

function ConnectionManager.callProvider(providerName, methodName, ...)
	local provider = providers[providerName]
	if not provider then
		return Promise.resolve(false, string.format("Provider '%s' not found", tostring(providerName)))
	end

	local method = provider[methodName]
	if type(method) ~= "function" then
		return Promise.resolve(false, string.format("Method '%s' not found on provider '%s'", tostring(methodName), tostring(providerName)))
	end

	local ok, result1, result2, result3, result4, result5 = pcall(method, provider, ...)
	if not ok then
		return Promise.resolve(false, result1)
	end

	if isPromiseLike(result1) then
		return result1
	end

	return Promise.resolve(true, result1, result2, result3, result4, result5)
end

return ConnectionManager
