-- ============================================================
-- RedeemService.server.luau
-- ServerScriptService/RedeemService
-- Sistem Redeem Code DINAMIS — kode dibuat dari admin command
-- Disimpan di DataStore, 1 orang 1x redeem per kode
-- Reward: Cash, Coin, MHCoin, Spins
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService  = game:GetService("DataStoreService")

local CodeStore    = DataStoreService:GetDataStore("RedeemCodesDB_v1")   -- Menyimpan daftar kode + reward
local RedeemedStore = DataStoreService:GetDataStore("RedeemUsedDB_v1")  -- Menyimpan siapa saja yg sudah redeem

-- ============================================================
-- Remotes
-- ============================================================
local redeemFolder = Instance.new("Folder")
redeemFolder.Name = "RedeemRemotes"
redeemFolder.Parent = ReplicatedStorage

local RedeemCode = Instance.new("RemoteFunction")
RedeemCode.Name = "RedeemCode"
RedeemCode.Parent = redeemFolder

-- ============================================================
-- Cache kode aktif (di-load saat server start)
-- Format: activeCodesCache[KODE] = { reward = "Cash", amount = 500 }
-- ============================================================
local activeCodesCache = {}

-- Load semua kode aktif dari DataStore saat server mulai
task.spawn(function()
	local ok, codeList = pcall(function()
		return CodeStore:GetAsync("_code_index") -- Menyimpan daftar nama kode
	end)
	if ok and type(codeList) == "table" then
		for _, codeName in ipairs(codeList) do
			local ok2, codeData = pcall(function()
				return CodeStore:GetAsync("code_" .. codeName)
			end)
			if ok2 and type(codeData) == "table" then
				activeCodesCache[codeName] = codeData
			end
		end
		print("[RedeemService] Loaded", #codeList, "kode dari DataStore")
	else
		print("[RedeemService] Belum ada kode redeem")
	end
end)

-- ============================================================
-- FUNGSI: Buat kode baru (dipanggil dari admin command)
-- Format: createcode NAMAKODE RewardType Amount
-- Contoh: createcode MERDEKA17 Cash 500
-- Contoh: createcode GARUDA MHCoin 100
-- Contoh: createcode NUSANTARA Spins 3
-- ============================================================
local function createCode(codeName, rewardType, amount, limit, expiryDays)
	codeName = codeName:upper():gsub("%s+", "")
	
	-- Gabungkan Coin dan MHCoin menjadi satu
	if rewardType == "Coin" then rewardType = "MHCoin" end
	
	-- Validasi reward type
	local validRewards = { Cash = true, MHCoin = true, Spins = true }
	if not validRewards[rewardType] then
		return false, "Reward type harus: Cash, MHCoin, atau Spins"
	end
	
	local amt = tonumber(amount)
	if not amt or amt <= 0 then
		return false, "Amount harus angka positif!"
	end
	
	limit = tonumber(limit)
	if limit and limit <= 0 then limit = nil end
	
	expiryDays = tonumber(expiryDays)
	local expiryTime = nil
	if expiryDays and expiryDays > 0 then
		expiryTime = os.time() + (expiryDays * 86400)
	end
	
	-- Simpan data kode
	local codeData = { 
		reward = rewardType, 
		amount = amt,
		limit = limit,
		expiryTime = expiryTime,
		uses = 0
	}
	
	local ok, err = pcall(function()
		CodeStore:SetAsync("code_" .. codeName, codeData)
	end)
	if not ok then return false, "Gagal simpan kode: " .. tostring(err) end
	
	-- Update index
	local codeIndex = {}
	pcall(function()
		local existing = CodeStore:GetAsync("_code_index")
		if type(existing) == "table" then
			codeIndex = existing
		end
	end)
	
	-- Cek apakah sudah ada
	local found = false
	for _, v in ipairs(codeIndex) do
		if v == codeName then found = true; break end
	end
	if not found then
		table.insert(codeIndex, codeName)
		pcall(function()
			CodeStore:SetAsync("_code_index", codeIndex)
		end)
	end
	
	-- Update cache
	activeCodesCache[codeName] = codeData
	
	return true, "Kode " .. codeName .. " berhasil dibuat! (" .. rewardType .. " x" .. amt .. ")"
end

-- ============================================================
-- FUNGSI: Hapus kode
-- ============================================================
local function deleteCode(codeName)
	codeName = codeName:upper():gsub("%s+", "")
	
	-- Hapus dari DataStore
	pcall(function()
		CodeStore:RemoveAsync("code_" .. codeName)
	end)
	
	-- Update index
	local codeIndex = {}
	pcall(function()
		local existing = CodeStore:GetAsync("_code_index")
		if type(existing) == "table" then
			codeIndex = existing
		end
	end)
	
	local newIndex = {}
	for _, v in ipairs(codeIndex) do
		if v ~= codeName then
			table.insert(newIndex, v)
		end
	end
	pcall(function()
		CodeStore:SetAsync("_code_index", newIndex)
	end)
	
	-- Hapus dari cache
	activeCodesCache[codeName] = nil
	
	return true, "Kode " .. codeName .. " berhasil dihapus!"
end

-- ============================================================
-- FUNGSI: List semua kode aktif
-- ============================================================
local function listCodes()
	local result = {}
	for code, data in pairs(activeCodesCache) do
		table.insert(result, code .. " = " .. data.reward .. " x" .. data.amount)
	end
	if #result == 0 then
		return "Belum ada kode redeem aktif."
	end
	return "Kode aktif: " .. table.concat(result, ", ")
end

-- ============================================================
-- Helper: Beri reward ke pemain
-- ============================================================
local function giveReward(plr, rewardType, amount)
	if rewardType == "Cash" then
		local statsData = plr:FindFirstChild("StatsData")
		if statsData then
			local cashVal = statsData:FindFirstChild("Cash")
			if cashVal then
				cashVal.Value = cashVal.Value + amount
				return true
			end
		end
		
	elseif rewardType == "MHCoin" then
		-- Pakai BindableFunction dari MHCoinService
		local addMHCoinFunc = ReplicatedStorage:FindFirstChild("_AddMHCoin")
		if addMHCoinFunc then
			local ok = addMHCoinFunc:Invoke(plr, amount)
			return ok
		end
		
	elseif rewardType == "Spins" then
		-- Pakai BindableFunction dari MHCoinService
		local addSpinsFunc = ReplicatedStorage:FindFirstChild("_AddSpins")
		if addSpinsFunc then
			local ok = addSpinsFunc:Invoke(plr, amount)
			return ok
		end
	end
	
	return false
end

-- ============================================================
-- REWARD LABEL (untuk tampilan di GUI)
-- ============================================================
local REWARD_LABELS = {
	Cash   = "Cash",
	MHCoin = "MH Coin",
	Spins  = "Spin Ticket",
}

-- ============================================================
-- Handler Redeem
-- ============================================================
RedeemCode.OnServerInvoke = function(plr, code)
	if type(code) ~= "string" then
		return { success = false, message = "Kode tidak valid!" }
	end

	-- Normalisasi: uppercase, trim spasi
	code = code:upper():gsub("%s+", "")

	-- Cek apakah kode ada di cache
	local codeData = activeCodesCache[code]
	if not codeData then
		return { success = false, message = "Kode tidak ditemukan!" }
	end

	-- Cek kadaluarsa awal
	if codeData.expiryTime and os.time() > codeData.expiryTime then
		return { success = false, message = "Kode ini sudah kedaluwarsa!" }
	end

	-- Cek apakah sudah pernah redeem (1 orang 1x per kode)
	local key = "redeemed_" .. tostring(plr.UserId)
	local alreadyRedeemed = {}
	local ok, saved = pcall(function()
		return RedeemedStore:GetAsync(key)
	end)
	if ok and type(saved) == "table" then
		alreadyRedeemed = saved
	end

	if alreadyRedeemed[code] then
		return { success = false, message = "Kode sudah pernah kamu gunakan!" }
	end

	-- Tunggu StatsData siap
	local statsData = plr:FindFirstChild("StatsData")
	if not statsData then
		statsData = plr:WaitForChild("StatsData", 5)
	end

	-- Validasi Limit dan update penggunaan via UpdateAsync
	local actualCodeData = nil
	local limitReached = false
	
	local ok2, err2 = pcall(function()
		CodeStore:UpdateAsync("code_" .. code, function(currentData)
			if not currentData then return nil end
			actualCodeData = currentData
			
			-- Cek ulang limit di datastore real-time
			if currentData.limit then
				if (currentData.uses or 0) >= currentData.limit then
					limitReached = true
					return nil -- Jangan ubah apa-apa
				end
				currentData.uses = (currentData.uses or 0) + 1
			end
			
			return currentData
		end)
	end)
	
	if limitReached then
		return { success = false, message = "Batas penggunaan kode ini sudah habis!" }
	end
	
	if not actualCodeData then
		return { success = false, message = "Kode gagal diverifikasi (mungkin ditarik)!" }
	end
	
	-- Update cache lokal
	activeCodesCache[code] = actualCodeData

	-- Beri reward
	local rewarded = giveReward(plr, actualCodeData.reward, actualCodeData.amount)
	if not rewarded then
		return { success = false, message = "Gagal memberikan reward! Coba lagi nanti." }
	end

	-- Simpan ke DataStore (sudah redeem)
	alreadyRedeemed[code] = true
	pcall(function()
		RedeemedStore:SetAsync(key, alreadyRedeemed)
	end)

	local label = REWARD_LABELS[codeData.reward] or codeData.reward

	return {
		success = true,
		message = "Berhasil! +" .. codeData.amount .. " " .. label .. "!",
		reward  = codeData.reward,
		amount  = codeData.amount
	}
end

-- ============================================================
-- EXPOSE ke DiscordAdmin (lewat BindableFunction)
-- ============================================================
local createCodeFunc = Instance.new("BindableFunction")
createCodeFunc.Name = "_CreateRedeemCode"
createCodeFunc.Parent = ReplicatedStorage
createCodeFunc.OnInvoke = function(codeName, rewardType, amount, limit, expiryDays)
	return createCode(codeName, rewardType, amount, limit, expiryDays)
end

local deleteCodeFunc = Instance.new("BindableFunction")
deleteCodeFunc.Name = "_DeleteRedeemCode"
deleteCodeFunc.Parent = ReplicatedStorage
deleteCodeFunc.OnInvoke = function(codeName)
	return deleteCode(codeName)
end

local listCodesFunc = Instance.new("BindableFunction")
listCodesFunc.Name = "_ListRedeemCodes"
listCodesFunc.Parent = ReplicatedStorage
listCodesFunc.OnInvoke = function()
	return listCodes()
end

print("[RedeemService] Aktif - Sistem Redeem Code Dinamis siap!")
