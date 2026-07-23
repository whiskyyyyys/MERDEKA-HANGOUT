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
	{ id = 1, type = "MHCoin", amount = 2,      chance = 4.0,  angle = 0   }, -- Top (2 MH)
	{ id = 2, type = "Cash",   amount = 25000,  chance = 40.0, angle = 300 }, -- Top-Right (Rp 25.000)
	{ id = 3, type = "Cash",   amount = 10000,  chance = 40.0, angle = 240 }, -- Bottom-Right (Rp 10.000)
	{ id = 4, type = "MHCoin", amount = 1,      chance = 10.0, angle = 180 }, -- Bottom (1 MH)
	{ id = 5, type = "Cash",   amount = 150000, chance = 5.0,  angle = 120 }, -- Bottom-Left (Rp 150.000)
	{ id = 6, type = "Cash",   amount = 250000, chance = 1.0,  angle = 60  }, -- Top-Left (Rp 250.000)
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
