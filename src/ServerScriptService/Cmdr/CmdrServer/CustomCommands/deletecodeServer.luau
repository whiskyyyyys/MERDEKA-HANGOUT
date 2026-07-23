local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local AuthorizedUsers = require(ServerStorage.Data.AuthorizedUsers)

return function(context, code)
	local plr = context.Executor
	
	-- Pengecekan: Hanya Owner & Co-Owner
	local isOwner = false
	
	if AuthorizedUsers[plr.UserId] == "superadmin" then
		isOwner = true
	end
	
	local GROUP_ID = 152660069
	local ok, role = pcall(function() return plr:GetRoleInGroup(GROUP_ID) end)
	if ok and role and role ~= "Guest" then
		local lowerRole = string.lower(role)
		if lowerRole:match("owner") or lowerRole:match("founder") or lowerRole:match("ceo") then
			isOwner = true
		end
	end
	
	if game:GetService("RunService"):IsStudio() then
		isOwner = true
	end
	
	if not isOwner then
		return "⛔ Akses Ditolak! Command ini KHUSUS untuk Owner dan Co-Owner."
	end
	
	local deleteFunc = ReplicatedStorage:FindFirstChild("_DeleteRedeemCode")
	if not deleteFunc then
		return "❌ Error: RedeemService belum dimuat di server."
	end
	
	local success, msg = deleteFunc:Invoke(code)
	if success then
		return "✅ " .. msg
	else
		return "❌ " .. msg
	end
end
