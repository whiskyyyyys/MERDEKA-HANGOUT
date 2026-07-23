local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local PlayerStatsDS = DataStoreService:GetDataStore("PlayerStats_v1")

local function setupLeaderstats(player)
	-- Buat folder leaderstats
	local leaderstats = Instance.new("Folder")
	local oldStats = player:FindFirstChild("leaderstats")
	if oldStats then oldStats:Destroy() end
	
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	-- Value Cash
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = 0
	cash.Parent = leaderstats
	
	-- Fungsi format waktu
	local function formatTime(totalMinutes)
		local days = math.floor(totalMinutes / 1440)
		local hours = math.floor((totalMinutes % 1440) / 60)
		local minutes = totalMinutes % 60
		
		if days > 0 then
			return string.format("%d Day(s) %dh %dm", days, hours, minutes)
		elseif hours > 0 then
			return string.format("%dh %dm", hours, minutes)
		else
			return string.format("%dm", minutes)
		end
	end
	
	-- Value Waktu Main (Format Teks)
	local playTime = Instance.new("StringValue")
	playTime.Name = "Time"
	playTime.Value = "0m"
	playTime.Parent = leaderstats
	
	-- Coba sinkronisasi dengan StatsData (dikelola oleh CashService)
	local function syncWithStatsData()
		local statsData = player:WaitForChild("StatsData", 60)
		if statsData then
			local statCash = statsData:WaitForChild("Cash", 60)
			if statCash then
				-- Set nilai awal
				cash.Value = statCash.Value
				
				-- Dengarkan perubahan dari StatsData
				statCash:GetPropertyChangedSignal("Value"):Connect(function()
					cash.Value = statCash.Value
				end)
			end
		end
	end
	
	task.spawn(syncWithStatsData)
	
	-- Load PlayTime Data
	local success, data = pcall(function()
		return PlayerStatsDS:GetAsync(tostring(player.UserId))
	end)
	
	local rawMinutes = 0
	if success and data then
		rawMinutes = data.PlayTime or 0
	end
	
	player:SetAttribute("PlayTimeMinutes", rawMinutes)
	playTime.Value = formatTime(rawMinutes)
	
	-- Loop untuk menambah waktu main setiap 60 detik (1 menit)
	task.spawn(function()
		while player.Parent do
			task.wait(60)
			if player.Parent then
				local currentMins = (player:GetAttribute("PlayTimeMinutes") or 0) + 1
				player:SetAttribute("PlayTimeMinutes", currentMins)
				playTime.Value = formatTime(currentMins)
			end
		end
	end)
end

Players.PlayerAdded:Connect(setupLeaderstats)

-- Untuk pemain yang sudah masuk di Studio sebelum script ini jalan
for _, player in ipairs(Players:GetPlayers()) do
	setupLeaderstats(player)
end

-- Save Data saat pemain keluar
Players.PlayerRemoving:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local playTime = leaderstats:FindFirstChild("Time")
		
		if playTime then
			local rawMins = player:GetAttribute("PlayTimeMinutes") or 0
			local data = {
				PlayTime = rawMins
			}
			
			local success, err = pcall(function()
				PlayerStatsDS:SetAsync(tostring(player.UserId), data)
			end)
			
			if not success then
				warn("[Leaderstats] Gagal menyimpan PlayTime untuk", player.Name, "-", err)
			end
		end
	end
end)

-- Save Data saat server mati
game:BindToClose(function()
	if RunService:IsStudio() then
		task.wait(2) -- Jangan kelamaan kalau di Studio
		return
	end
	
	for _, player in ipairs(Players:GetPlayers()) do
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local playTime = leaderstats:FindFirstChild("Time")
			
			if playTime then
				pcall(function()
					local rawMins = player:GetAttribute("PlayTimeMinutes") or 0
					PlayerStatsDS:SetAsync(tostring(player.UserId), {
						PlayTime = rawMins
					})
				end)
			end
		end
	end
end)
