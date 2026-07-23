-- ============================================================
-- BanService.server.luau
-- ServerScriptService/BanService
-- Sistem Ban berbasis DataStore (dengan durasi)
-- ============================================================

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BanStore = DataStoreService:GetDataStore("BanDB_v1")

-- Fungsi Cek Ban saat join
Players.PlayerAdded:Connect(function(player)
	local userId = tostring(player.UserId)
	local success, banData = pcall(function()
		return BanStore:GetAsync(userId)
	end)
	
	if success and banData then
		-- banData format: { Reason = string, Expiry = number (os.time), Admin = string }
		local currentTime = os.time()
		
		if banData.Expiry == -1 or currentTime < banData.Expiry then
			-- Masih di-ban
			local expiryStr = "Selamanya (Permanen)"
			if banData.Expiry ~= -1 then
				local sisaDetik = banData.Expiry - currentTime
				local sisaHari = math.ceil(sisaDetik / 86400)
				expiryStr = sisaHari .. " hari lagi"
			end
			
			local kickMsg = "⛔ KAMU DI-BAN DARI SERVER INI ⛔\n" ..
							"Alasan: " .. (banData.Reason or "Pelanggaran Aturan") .. "\n" ..
							"Durasi Hukuman: " .. expiryStr .. "\n" ..
							"Di-ban oleh: " .. (banData.Admin or "Admin")
							
			player:Kick(kickMsg)
		else
			-- Waktu ban sudah habis, hapus dari datastore
			pcall(function()
				BanStore:RemoveAsync(userId)
			end)
		end
	end
end)

-- Bindable untuk Ban
local banFunc = Instance.new("BindableFunction")
banFunc.Name = "_BanPlayer"
banFunc.Parent = ReplicatedStorage
banFunc.OnInvoke = function(userId, reason, durationDays, adminName)
	local expiry = -1
	if durationDays and durationDays > 0 then
		expiry = os.time() + (durationDays * 86400)
	end
	
	local banData = {
		Reason = reason,
		Expiry = expiry,
		Admin = adminName
	}
	
	local success, err = pcall(function()
		BanStore:SetAsync(tostring(userId), banData)
	end)
	
	-- Jika online, kick langsung
	for _, p in ipairs(Players:GetPlayers()) do
		if p.UserId == tonumber(userId) then
			p:Kick("⛔ KAMU DI-BAN OLEH ADMIN ⛔\nAlasan: " .. reason)
		end
	end
	
	return success, err
end

-- Bindable untuk Unban
local unbanFunc = Instance.new("BindableFunction")
unbanFunc.Name = "_UnbanPlayer"
unbanFunc.Parent = ReplicatedStorage
unbanFunc.OnInvoke = function(userId)
	local success, err = pcall(function()
		BanStore:RemoveAsync(tostring(userId))
	end)
	return success, err
end

print("[BanService] Loaded dan Siap!")
