local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local AuthorizedUsers = require(ServerStorage.Data.AuthorizedUsers)

return function(context, players, amount)
	local plr = context.Executor
	
	-- Pengecekan Ekstra Khusus Owner & Co-Owner
	local isOwner = false
	
	-- Cek apakah dia Superadmin di AuthorizedUsers
	if AuthorizedUsers[plr.UserId] == "superadmin" then
		isOwner = true
	end
	
	-- Cek Role Grup (Jika pakai grup)
	local GROUP_ID = 152660069
	local ok, role = pcall(function() return plr:GetRoleInGroup(GROUP_ID) end)
	if ok and role and role ~= "Guest" then
		local lowerRole = string.lower(role)
		-- Sesuaikan kata kunci dengan nama Role Owner/Co-Owner di grup Anda
		if lowerRole:match("owner") or lowerRole:match("founder") or lowerRole:match("ceo") then
			isOwner = true
		end
	end
	
	-- Kalau dia developer studio, kasih juga
	if game:GetService("RunService"):IsStudio() then
		isOwner = true
	end
	
	if not isOwner then
		return "⛔ Akses Ditolak! Command ini KHUSUS untuk Owner dan Co-Owner."
	end
	
	local addSpins = ReplicatedStorage:FindFirstChild("_AddSpins")
	if not addSpins then
		return "❌ Error: Sistem Spin Ticket belum dimuat di server."
	end
	
	local count = 0
	for _, target in ipairs(players) do
		pcall(function()
			addSpins:Invoke(target, amount)
			count = count + 1
		end)
	end
	
	return "✅ Berhasil memberikan " .. amount .. " Spin Ticket ke " .. count .. " pemain!"
end
