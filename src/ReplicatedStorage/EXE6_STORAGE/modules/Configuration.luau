local run_service = game:GetService("RunService")
local serverscript_service = game:GetService("ServerScriptService")
local replicated_storage = game:GetService("ReplicatedStorage")

local LoadedConfigs

function GetConfigurations()	
	if run_service:IsServer() then
		if LoadedConfigs then return LoadedConfigs end
		
		--
		
		local EXE6_SERVER = serverscript_service:FindFirstChild("EXE6_SERVER")
		if not EXE6_SERVER then return end

		local Auth = require(EXE6_SERVER.Auth)
		
		LoadedConfigs = Auth.GetConfigurations()
		
		return LoadedConfigs
		
	elseif run_service:IsClient() then		
		local Storage = replicated_storage:WaitForChild("EXE6_STORAGE")
		local Configs = Storage:WaitForChild("Configuration")
		local Index = {}

		for i, Set in pairs(Configs:GetChildren()) do		
			if Set:IsA("Folder") then
				local collection = {}

				for i, item in pairs(Set:GetChildren()) do
					table.insert(collection, item.Value)
				end

				Index[Set.Name] = collection
			elseif Set:IsA("Configuration") then
				local collection = {}

				for i, item in pairs(Set:GetAttributes()) do
					if i == "AccessKey" then
						local success, result = pcall(function()
							return Enum.KeyCode[item]
						end)

						if success then
							collection[i] = result
						else
							collection[i] = Enum.KeyCode.F2
						end
					else
						collection[i] = item
					end
				end

				Index[Set.Name] = collection
			end
		end

		return Index
	end
	
	return {}
end

local Result = GetConfigurations()

return Result