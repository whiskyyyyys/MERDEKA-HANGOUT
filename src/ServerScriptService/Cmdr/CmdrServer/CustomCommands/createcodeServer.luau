local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local AuthorizedUsers = require(ServerStorage.Data.AuthorizedUsers)

return function(context, code, rewardType, amount, limit, expiryDays)
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
	
	-- Gabung Coin dan MHCoin
	if rewardType == "Coin" then rewardType = "MHCoin" end
	
	-- Validasi reward type
	local validTypes = { Cash = true, MHCoin = true, Spins = true }
	if not validTypes[rewardType] then
		return "❌ Reward type harus: Cash, MHCoin, atau Spins. Kamu ketik: " .. tostring(rewardType)
	end
	
	local createFunc = ReplicatedStorage:FindFirstChild("_CreateRedeemCode")
	if not createFunc then
		return "❌ Error: RedeemService belum dimuat di server."
	end
	
	local success, msg = createFunc:Invoke(code, rewardType, amount, limit, expiryDays)
	if success then
		return "✅ " .. msg
	else
		return "❌ " .. msg
	end
end
