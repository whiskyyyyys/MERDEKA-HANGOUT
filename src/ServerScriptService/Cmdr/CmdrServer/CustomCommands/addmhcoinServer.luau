local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local AuthorizedUsers = require(ServerStorage.Data.AuthorizedUsers)

return function(context, players, amount)
	local plr = context.Executor
	
	local isOwner = false
	if AuthorizedUsers[plr.UserId] == "superadmin" then isOwner = true end
	
	local GROUP_ID = 152660069
	local ok, role = pcall(function() return plr:GetRoleInGroup(GROUP_ID) end)
	if ok and role and role ~= "Guest" then
		local lowerRole = string.lower(role)
		if lowerRole:match("owner") or lowerRole:match("founder") or lowerRole:match("ceo") then
			isOwner = true
		end
	end
	
	if game:GetService("RunService"):IsStudio() then isOwner = true end
	
	if not isOwner then
		return "⛔ Akses Ditolak! Command ini KHUSUS untuk Owner dan Co-Owner."
	end
	
	local addFunc = ReplicatedStorage:FindFirstChild("_AddMHCoin")
	if not addFunc then return "❌ Error: Sistem MHCoin belum dimuat." end
	
	local count = 0
	for _, target in ipairs(players) do
		pcall(function()
			addFunc:Invoke(target, amount)
			count = count + 1
		end)
	end
	
	return "✅ Berhasil memberikan " .. amount .. " MHCoin ke " .. count .. " pemain!"
end
