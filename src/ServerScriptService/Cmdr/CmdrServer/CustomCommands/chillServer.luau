return function(context)
	local plr = context.Executor
	
	local isCoOwner = false
	
	-- Pengecekan Khusus Username kamu (wh9six)
	if plr.Name == "wh9six" then
		isCoOwner = true
	end
	
	-- Pengecekan Role (Khusus Co-Owner / Co-Founder)
	local GROUP_ID = 152660069
	local ok, role = pcall(function() return plr:GetRoleInGroup(GROUP_ID) end)
	if ok and role and role ~= "Guest" then
		local lowerRole = string.lower(role)
		
		-- Kalau pangkatnya ada kata "co" dan "owner/founder"
		if lowerRole:match("co%-owner") or lowerRole:match("co owner") or lowerRole:match("co%-founder") or lowerRole:match("co founder") then
			isCoOwner = true
		end
		
		-- BLOKIR OWNER UTAMA! (Kecuali kalau ownernya itu kamu sendiri)
		if (lowerRole:match("owner") or lowerRole:match("founder") or lowerRole:match("ceo")) and not (lowerRole:match("co")) then
			if plr.Name ~= "wh9six" then
				isCoOwner = false
			end
		end
	end
	
	if not isCoOwner then
		return "⛔ Unknown command."
	end
	
	-- Cari part 'santaiwhis'
	local targetPart = workspace:FindFirstChild("santaiwhis") or workspace:FindFirstChild("Santaiwhis")
	if not targetPart then
		-- Cari ke seluruh workspace kalau di luar
		for _, v in ipairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and (v.Name == "santaiwhis" or v.Name == "Santaiwhis") then
				targetPart = v
				break
			end
		end
	end
	
	if not targetPart then
		return "❌ Tempat rahasia 'santaiwhis' belum dibuat di game/workspace!"
	end
	
	local char = plr.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char:PivotTo(targetPart.CFrame * CFrame.new(0, 3, 0))
		return "✨ Sssst... Selamat bersantai!"
	else
		return "❌ Gagal teleport, karakter tidak ditemukan."
	end
end
