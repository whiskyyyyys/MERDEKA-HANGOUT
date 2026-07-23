local DataStoreService = game:GetService("DataStoreService")
local DataStore = DataStoreService:GetDataStore("Exe6", "Variables")

local module = {}

function module.SaveVariable(VariableName, Value)
	local success, result = pcall(function()
		DataStore:SetAsync(VariableName, Value)
	end)

	if not success then
		warn("Failed to save variable:", result)
	end
end

function module.GetVariable(VariableName)
	local success, result = pcall(function()
		return DataStore:GetAsync(VariableName)
	end)

	if success then
		return result
	else
		warn("Failed to retrieve variable:", result)
		return nil
	end
end

function module.IncreaseVariable(VariableName, Interval)
	local success, result = pcall(function()
		local currentValue = DataStore:GetAsync(VariableName)

		if not currentValue then
			currentValue = 0
		end

		local newValue = currentValue + Interval

		DataStore:SetAsync(VariableName, newValue)
		return newValue
	end)

	if success then
		return result
	else
		warn("Failed to increase variable:", result)
		return nil
	end
end

function module.RemoveVariable(VariableName)
	local success, result = pcall(function()
		DataStore:RemoveAsync(VariableName)
	end)

	if not success then
		warn("Failed to remove variable:", result)
	end
end

return module