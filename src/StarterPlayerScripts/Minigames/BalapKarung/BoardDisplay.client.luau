local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RSMinigames = ReplicatedStorage:WaitForChild("Minigames")
local BalapKarungFolder = RSMinigames:WaitForChild("BalapKarung")
local Events = BalapKarungFolder:WaitForChild("Events")
local LeaderboardUpdate = Events:WaitForChild("LeaderboardUpdate")
local LossLeaderboardUpdate = Events:WaitForChild("LossLeaderboardUpdate")

local function updateBoard(modelName, dataList)
	
	
	local arenaModel = workspace:FindFirstChild("BalapKarungArena")
	local model = nil
	
	-- Fungsi pencarian nama yang fleksibel (case-insensitive & handle missing 's')
	local function findModelFlexibly(parent, targetName)
		local function isValidLeaderboard(obj)
			-- Pastikan objek ini atau anak-anaknya punya SurfaceGui, jadi kita tidak salah ambil part kosong
			return obj:FindFirstChildWhichIsA("SurfaceGui", true) ~= nil
		end

		for _, child in ipairs(parent:GetDescendants()) do
			if string.lower(child.Name) == string.lower(targetName) and isValidLeaderboard(child) then
				return child
			end
		end
		
		-- Jika tidak ketemu, coba variasi nama lain
		local variations = {}
		if targetName == "LeaderboardWins" then
			variations = {"LeaderboardWin", "LeaderBoardWins", "LeaderBoardWin"}
		elseif targetName == "LeaderboardLose" then
			variations = {"LeaderBoardLose", "LeaderboardLoss", "LeaderboardLosses"}
		end
		
		for _, child in ipairs(parent:GetDescendants()) do
			for _, var in ipairs(variations) do
				if string.lower(child.Name) == string.lower(var) and isValidLeaderboard(child) then
					return child
				end
			end
		end
		return nil
	end

	if arenaModel then model = findModelFlexibly(arenaModel, modelName) end
	if not model then model = findModelFlexibly(workspace, modelName) end
	
	if not model then 
		
		return 
	end
	
	local surfaceGui = nil
	local screen = model:FindFirstChild("Screen", true) or model:FindFirstChild("Screen")
	
	if screen then
		surfaceGui = screen:FindFirstChildWhichIsA("SurfaceGui")
	else
		-- Kalau part 'Screen' ga ada, coba cari SurfaceGui langsung di dalam model secara rekursif
		surfaceGui = model:FindFirstChildWhichIsA("SurfaceGui", true)
	end
	
	if not surfaceGui then
		warn("[BalapKarungBoard] GAGAL: SurfaceGui tidak ditemukan di dalam model", model.Name)
		return 
	end
	
	local mainFrame = surfaceGui:FindFirstChild("Frame") or surfaceGui:FindFirstChildWhichIsA("Frame")
	if not mainFrame then
		warn("[BalapKarungBoard] GAGAL: Frame utama tidak ditemukan di dalam SurfaceGui milik", model.Name)
		return 
	end
	
	local playersContainer = mainFrame:FindFirstChild("Players")
	if not playersContainer then
		warn("[BalapKarungBoard] GAGAL: Frame/ScrollingFrame bernama 'Players' tidak ditemukan di dalam", model.Name)
		return 
	end
	
	-- Ambil sampel Header dari buatan user
	local sampleName = playersContainer:FindFirstChild("Name")
	local sampleRank = playersContainer:FindFirstChild("Rank")
	local sampleAmount = playersContainer:FindFirstChild("Amount")
	
	if not (sampleName and sampleRank and sampleAmount) then
		warn("[BalapKarungBoard] Gagal menemukan label Name, Rank, Amount di dalam Players.")
		return
	end
	
	-- Buat wadah khusus untuk daftar pemain agar rapi ke bawah (TIDAK numpuk)
	local rowsContainer = playersContainer:FindFirstChild("RowsContainer")
	if not rowsContainer then
		rowsContainer = Instance.new("Frame")
		rowsContainer.Name = "RowsContainer"
		
		-- Posisikan wadah ini TEPAT DI BAWAH teks Header "Rank, Player, Amount" kamu!
		-- Kita ambil Y dari sampleName lalu kita tambah sedikit agar ada jarak
		local startYScale = sampleName.Position.Y.Scale + (sampleName.Size.Y.Scale > 0 and sampleName.Size.Y.Scale or 0.1)
		local startYOffset = sampleName.Position.Y.Offset + sampleName.Size.Y.Offset + 15
		
		rowsContainer.Position = UDim2.new(0, 0, startYScale, startYOffset)
		
		-- PERBAIKAN SCROLLING:
		-- Kita set ukurannya agar membesar otomatis ke bawah (AutomaticSize)
		rowsContainer.Size = UDim2.new(1, 0, 0, 0)
		rowsContainer.AutomaticSize = Enum.AutomaticSize.Y
		rowsContainer.BackgroundTransparency = 1
		rowsContainer.Parent = playersContainer
		
		-- Jika Players adalah ScrollingFrame, pastikan otomatis menambah area scroll!
		if playersContainer:IsA("ScrollingFrame") then
			playersContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
			playersContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
			playersContainer.ScrollBarThickness = 8
		end
		
		-- Gunakan UIListLayout agar baris pemain otomatis tersusun rapi ke bawah
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 10) -- Jarak antar pemain
		layout.Parent = rowsContainer
	end
	
	-- Cek Template
	local template = rowsContainer:FindFirstChild("Template")
	if not template then
		template = Instance.new("Frame")
		template.Name = "Template"
		template.Size = UDim2.new(1, 0, 0.12, 0) -- Tinggi tiap baris pemain
		template.BackgroundTransparency = 1
		template.Visible = false
		template.Parent = rowsContainer
		
		local cloneRank = sampleRank:Clone()
		local cloneName = sampleName:Clone()
		local cloneAmount = sampleAmount:Clone()
		
		cloneRank.Parent = template
		cloneName.Parent = template
		cloneAmount.Parent = template
		
		-- Samakan posisi X-nya dengan posisi header aslimu, tapi posisikan Y di tengah/atas (0)
		cloneRank.Position = UDim2.new(sampleRank.Position.X.Scale, sampleRank.Position.X.Offset, 0, 0)
		cloneName.Position = UDim2.new(sampleName.Position.X.Scale, sampleName.Position.X.Offset, 0, 0)
		cloneAmount.Position = UDim2.new(sampleAmount.Position.X.Scale, sampleAmount.Position.X.Offset, 0, 0)
		
		-- PERBAIKAN UKURAN: Buat tinggi label menjadi 100% dari tinggi baris (Template)
		-- Agar tulisannya tidak mengecil drastis ketika dimasukkan ke dalam wadah baru!
		cloneRank.Size = UDim2.new(sampleRank.Size.X.Scale, sampleRank.Size.X.Offset, 1, 0)
		cloneName.Size = UDim2.new(sampleName.Size.X.Scale, sampleName.Size.X.Offset, 1, 0)
		cloneAmount.Size = UDim2.new(sampleAmount.Size.X.Scale, sampleAmount.Size.X.Offset, 1, 0)

		if cloneRank:IsA("TextLabel") then cloneRank.TextScaled = true end
		if cloneName:IsA("TextLabel") then cloneName.TextScaled = true end
		if cloneAmount:IsA("TextLabel") then cloneAmount.TextScaled = true end
	end
	
	-- Bersihkan pemain lama
	for _, child in ipairs(rowsContainer:GetChildren()) do
		if child.Name:match("^Player_") then
			child:Destroy()
		end
	end
	
	if type(dataList) ~= "table" then return end
	
	-- Munculkan pemain (MAKSIMAL 10 BESAR SAJA)
	local maxPlayers = math.min(#dataList, 10)
	for i = 1, maxPlayers do
		local playerData = dataList[i]
		if type(playerData) ~= "table" then continue end
		
		local row = template:Clone()
		if not row then continue end
		
		row.Name = "Player_" .. tostring(playerData.rank or 0)
		row.LayoutOrder = i
		row.Visible = true
		
		-- PAKSA TINGGI BARIS SECARA MANUAL: 45 pixel
		row.Size = UDim2.new(1, 0, 0, 45)
		
		local rankLbl = row:FindFirstChild("Rank")
		local nameLbl = row:FindFirstChild("Name")
		local amtLbl = row:FindFirstChild("Amount")
		
		local function applyForcedScale(lbl)
			if lbl and lbl:IsA("TextLabel") then
				lbl.TextScaled = true
				-- Paksa tinggi label mengikuti tinggi baris (100% atau 1 Scale)
				lbl.Size = UDim2.new(lbl.Size.X.Scale, lbl.Size.X.Offset, 1, 0)
				-- Hapus batas maksimal ukuran font bawaan (kalau ada)
				local constraint = lbl:FindFirstChildWhichIsA("UITextSizeConstraint")
				if constraint then constraint:Destroy() end
			end
		end
		
		if rankLbl and rankLbl:IsA("TextLabel") then 
			rankLbl.Text = "#" .. tostring(playerData.rank or 0)
			applyForcedScale(rankLbl)
		end
		if nameLbl and nameLbl:IsA("TextLabel") then 
			nameLbl.Text = tostring(playerData.name or "Unknown")
			applyForcedScale(nameLbl)
		end
		if amtLbl and amtLbl:IsA("TextLabel") then 
			amtLbl.Text = tostring(playerData.value or 0)
			applyForcedScale(amtLbl)
		end
		
		row.Parent = rowsContainer
	end
	
	-- PERBAIKAN SCROLLING TAMBAHAN (Paksa update CanvasSize)
	if playersContainer:IsA("ScrollingFrame") then
		local layout = rowsContainer:FindFirstChildWhichIsA("UIListLayout")
		if layout then
			task.spawn(function()
				task.wait(0.1) -- Tunggu UI ter-render
				playersContainer.CanvasSize = UDim2.new(0, 0, 0, rowsContainer.Position.Y.Offset + layout.AbsoluteContentSize.Y + 50)
			end)
		end
	end
end

LeaderboardUpdate.OnClientEvent:Connect(function(data)
	updateBoard("LeaderboardWins", data)
end)

LossLeaderboardUpdate.OnClientEvent:Connect(function(data)
	updateBoard("LeaderboardLose", data)
end)

updateBoard("LeaderboardWins", {})
updateBoard("LeaderboardLose", {})
