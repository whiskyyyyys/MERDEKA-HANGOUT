if game:GetService("RunService"):IsClient() then return function() end end
local ServerStorage = game:GetService("ServerStorage")

local AuthorizedUsers = require(ServerStorage.Data.AuthorizedUsers)
local AfterRole       = require(ServerStorage.Data.AfterRole)

return function(registry)
	registry:RegisterHook("BeforeRun", function(context)
		local group = context.Group
		if group == "DefaultOpen" then return end

		local plr = context.Executor
		local GROUP_ID = 152660069
		local isAuth = false

		-- Cek Role di Grup Komunitas Roblox
		local ok, role = pcall(function() return plr:GetRoleInGroup(GROUP_ID) end)
		if ok and role and role ~= "Guest" then
			local lowerRole = string.lower(role)
			if lowerRole:match("owner") or lowerRole:match("founder") or lowerRole:match("ceo") or lowerRole:match("admin") or lowerRole:match("mod") or lowerRole:match("dev") then
				isAuth = true
			end
		end
		
		-- Cek ID langsung (Fallback bawaan)
		if not isAuth then
			local userId = plr.UserId
			local userRole = AuthorizedUsers[userId]
			if userRole then
				local allowedGroups = AfterRole[userRole]
				if allowedGroups then
					for _, allowedGroup in ipairs(allowedGroups) do
						if allowedGroup == group then
							isAuth = true
							break
						end
					end
				end
			end
		end

		if not isAuth then
			return "⛔ Akses Ditolak! Kamu harus menjadi Staff di Grup Roblox untuk menggunakan Cmdr."
		end
	end)
end