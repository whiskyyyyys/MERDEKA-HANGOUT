-- ============================================================
-- SpinWheelServer.server.luau
-- Mengelola logika Spin Wheel (RNG) dan pemberian hadiah
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local SpinWheelEvent = ReplicatedStorage:FindFirstChild("SpinWheelEvent")
if not SpinWheelEvent then
	SpinWheelEvent = Instance.new("RemoteEvent")
	SpinWheelEvent.Name = "SpinWheelEvent"
	SpinWheelEvent.Parent = ReplicatedStorage
end

-- Ambil BindableFunctions untuk Cash & MHCoin
local addCash = ReplicatedStorage:WaitForChild("_AddCash")
local addMHCoin = ReplicatedStorage:WaitForChild("_AddMHCoin")
local addSpins = ReplicatedStorage:WaitForChild("_AddSpins")
local getSpins = ReplicatedStorage:WaitForChild("_GetSpins")

-- Daftar Hadiah dan Peluangnya
local REWARDS = {
	{ id = 1, type = "MHCoin", amount = 4,     chance = 0.1,  angle = 0   }, -- Top
	{ id = 2, type = "Cash",   amount = 25000, chance = 55.5, angle = 300 }, -- Top-Right
	{ id = 3, type = "Cash",   amount = 50000, chance = 34.0, angle = 240 }, -- Bottom-Right
	{ id = 4, type = "MHCoin", amount = 2,     chance = 0.9,  angle = 180 }, -- Bottom (6% di gambar tapi 0.9% teks?) Anggap 0.9% untuk seimbang
	{ id = 5, type = "Cash",   amount = 75000, chance = 7.5,  angle = 120 }, -- Bottom-Left
	{ id = 6, type = "Cash",   amount = 100000,chance = 2.0,  angle = 60  }, -- Top-Left
}

-- Pastikan total chance = 100%
local totalChance = 0
for _, r in ipairs(REWARDS) do
	totalChance = totalChance + r.chance
end

local function getRandomReward()
	local rng = math.random() * totalChance
	local current = 0
	
	for _, reward in ipairs(REWARDS) do
		current = current + reward.chance
		if rng <= current then
			return reward
		end
	end
	return REWARDS[2] -- Fallback ke Rp 25.000
end

SpinWheelEvent.OnServerEvent:Connect(function(player)
	-- Cek jumlah spin player
	local currentSpins = getSpins:Invoke(player) or 0
	if currentSpins <= 0 then
		SpinWheelEvent:FireClient(player, false, "Spin Ticket tidak cukup! (Sisa 0)")
		return
	end
	
	-- Kurangi 1 spin ticket
	addSpins:Invoke(player, -1)
	
	-- Tentukan hadiah
	local wonReward = getRandomReward()
	
	-- Kirim hasilnya ke client untuk dianimasikan terlebih dahulu
	SpinWheelEvent:FireClient(player, true, wonReward.id, wonReward.angle)
	
	-- Beri jeda agar client selesai memutar animasi (misal 5 detik animasi)
	task.delay(6.0, function()
		if not player.Parent then return end -- Player udah keluar
		
		if wonReward.type == "Cash" then
			addCash:Invoke(player, wonReward.amount, "Spin Wheel Reward")
		elseif wonReward.type == "MHCoin" then
			addMHCoin:Invoke(player, wonReward.amount)
		end
		
		-- Notifikasi global jika menang besar (opsional)
		if wonReward.amount >= 75000 or wonReward.type == "MHCoin" then
			print("[SpinWheel] " .. player.Name .. " mendapatkan hadiah spesial: " .. wonReward.amount .. " " .. wonReward.type)
		end
	end)
end)

print("[SpinWheelServer] Berhasil dimuat.")
