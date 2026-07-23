-- WordDisplay.client.luau
-- Hanya menangani: billboard kata di atas kepala pemain + Depth of Field
-- Title/rank/badge system sudah dihapus dari sini

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService      = game:GetService("TweenService")
local Lighting          = game:GetService("Lighting")

local Modules = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Modules")
local Config  = require(Modules:WaitForChild("GameConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Remotes")

local R = {}
for k, v in pairs(Config.Remotes) do R[k] = Remotes:WaitForChild(v) end

-- ============================================================
-- Billboard kata (muncul di atas kepala pemain saat giliran)
-- ============================================================
local BB_BASE_W   = 120
local BB_MAX_W    = 320
local BB_TYPING_MAX = 260
local BB_BASE_H   = 40
local BB_CHAR_W   = 14
local BB_OFFSET   = Vector3.new(0, 2.8, 0)

-- cache[player] = { bb = BillboardGui, container = Frame }
local cache = {}

local function createWordBillboard(character)
	local head = character:WaitForChild("Head", 5)
	if not head then return end

	-- Hapus yang lama kalau ada
	local old = head:FindFirstChild("WordBillboard")
	if old then old:Destroy() end

	local bb = Instance.new("BillboardGui")
	bb.Name            = "WordBillboard"
	bb.Adornee         = head
	bb.Size            = UDim2.new(0, BB_BASE_W, 0, BB_BASE_H)
	bb.StudsOffset     = BB_OFFSET
	bb.AlwaysOnTop     = true
	bb.ResetOnSpawn    = false
	bb.Enabled         = false
	bb.MaxDistance     = 30 -- MaxDistance ditambahkan sesuai permintaan
	bb.Parent          = head

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.Parent = bb
	
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 4)
	layout.Parent = container

	return bb, container
end

local function onCharacterAdded(plr, character)
	local bb, container = createWordBillboard(character)
	if bb and container then
		cache[plr] = { bb = bb, container = container }
	end
end

-- Setup untuk semua player yang sudah ada
for _, plr in ipairs(Players:GetPlayers()) do
	if plr.Character then
		onCharacterAdded(plr, plr.Character)
	end
	plr.CharacterAdded:Connect(function(char)
		onCharacterAdded(plr, char)
	end)
end

-- Setup untuk player yang baru join
Players.PlayerAdded:Connect(function(plr)
	if plr.Character then
		onCharacterAdded(plr, plr.Character)
	end
	plr.CharacterAdded:Connect(function(char)
		onCharacterAdded(plr, char)
	end)
end)

Players.PlayerRemoving:Connect(function(plr)
	cache[plr] = nil
end)

-- ============================================================
-- Depth of Field (blur background saat bukan giliran kita)
-- ============================================================
local dofEffect = nil

local function startDoF(targetCharacter)
	-- Blur dihapus sesuai permintaan
end

local function stopDoF()
	-- Blur dihapus sesuai permintaan
end

-- ============================================================
-- State zone
-- ============================================================
local activeZones       = {}   -- [zoneName] = { players = {[name]=true} }
local playerZoneMap     = {}   -- [playerName] = zoneName
local isLocalParticipant = false
local localActiveZone   = nil
local gameActive        = false

-- ============================================================
-- Fungsi update box huruf (Kotak-kotak Merah Putih)
-- ============================================================
local function updateWordBoxes(container, text, overrideBgColor)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	local textStr = (text and text ~= "") and text:upper() or "..."
	if textStr == "..." then
		local box = Instance.new("TextLabel")
		box.Size = UDim2.new(0, 40, 0, 36)
		box.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
		box.TextColor3 = Color3.fromRGB(20, 20, 20)
		box.Text = "..."
		box.Font = Enum.Font.GothamBold
		box.TextScaled = true
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = box
		
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Parent = box
		
		box.Parent = container
		return
	end
	
	for i = 1, #textStr do
		local char = textStr:sub(i, i)
		local box = Instance.new("TextLabel")
		box.Size = UDim2.new(0, 30, 0, 36)
		
		-- Putih dengan teks Hitam
		box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		box.TextColor3 = Color3.fromRGB(20, 20, 20)
		
		if overrideBgColor then
			box.BackgroundColor3 = overrideBgColor
			box.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
		
		box.Text = char
		box.Font = Enum.Font.GothamBold
		box.TextScaled = true
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = box
		
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Parent = box
		
		box.Parent = container
	end
end

-- ============================================================
-- Fungsi tampil / sembunyi billboard
-- ============================================================
local function hideZoneBillboards(zoneName)
	local zoneInfo = activeZones[zoneName]
	if not zoneInfo then return end
	for plr, d in pairs(cache) do
		if zoneInfo.players[plr.Name] and d.bb then
			d.bb.Enabled = false
		end
	end
end

local function showAbove(targetName, word, zoneName)
	for plr, d in pairs(cache) do
		if d.bb then
			if plr.Name == targetName then
				updateWordBoxes(d.container, word)
				local w = math.clamp(#(word or "...") * BB_CHAR_W + 20 + (#(word or "...") * 30), BB_BASE_W, BB_MAX_W * 2)
				d.bb.Size        = UDim2.new(0, w, 0, BB_BASE_H)
				d.bb.Enabled     = true
			elseif zoneName and playerZoneMap[plr.Name] == zoneName then
				d.bb.Enabled = false
			end
		end
	end
end

local function shakeBillboard(d)
	if not (d and d.bb and d.container) then return end
	
	-- Jadikan kotak-kotak merah tanpa mengubah huruf aslinya
	for _, child in ipairs(d.container:GetChildren()) do
		if child:IsA("TextLabel") then
			child.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
			child.TextColor3 = Color3.fromRGB(255, 255, 255)
		end
	end
	
	local bb = d.bb
	local origOffset = bb.StudsOffset
	task.spawn(function()
		for i = 1, 6 do
			local shakeX = (i % 2 == 0) and 0.5 or -0.5
			bb.StudsOffset = origOffset + Vector3.new(shakeX, 0, 0)
			task.wait(0.04)
		end
		bb.StudsOffset = origOffset
	end)
end

local function toggleTitle(plr, visible)
	if not plr or not plr.Character then return end
	local head = plr.Character:FindFirstChild("Head")
	if head then
		local titleBb = head:FindFirstChild("GlobalTitleBillboard")
		if titleBb then titleBb.Enabled = visible end
	end
end

-- ============================================================
-- Game Events
-- ============================================================
R.GameStarted.OnClientEvent:Connect(function(data)
	local zn = data and data.zoneName or "unknown"
	gameActive = true

	local playerNames = (data and data.players) or {}
	activeZones[zn] = { players = {} }
	for _, n in ipairs(playerNames) do
		activeZones[zn].players[n] = true
		playerZoneMap[n] = zn
		
		-- Sembunyikan title saat mulai main
		local plr = Players:FindFirstChild(n)
		if plr then toggleTitle(plr, false) end
	end

	if not isLocalParticipant then
		for _, n in ipairs(playerNames) do
			if n == Players.LocalPlayer.Name then
				isLocalParticipant = true
				localActiveZone    = zn
				break
			end
		end
	end

	hideZoneBillboards(zn)
end)

R.NewTurn.OnClientEvent:Connect(function(zn, _sid, turnName, word)
	if not activeZones[zn] then return end
	showAbove(turnName, word, zn)

	if isLocalParticipant and localActiveZone == zn and turnName ~= Players.LocalPlayer.Name then
		local turnPlr = Players:FindFirstChild(turnName)
		if turnPlr and turnPlr.Character then
			startDoF(turnPlr.Character)
		else
			stopDoF()
		end
	else
		stopDoF()
	end
end)

R.WordAccepted.OnClientEvent:Connect(function(zn, senderName, word)
	if not activeZones[zn] then return end
	for plr, d in pairs(cache) do
		if plr.Name == senderName and d.bb then
			updateWordBoxes(d.container, word, Color3.fromRGB(40, 200, 70))
			local w = math.clamp(#(word or "") * BB_CHAR_W + 20 + (#(word or "") * 30), BB_BASE_W, BB_MAX_W * 2)
			d.bb.Size        = UDim2.new(0, w, 0, BB_BASE_H)
			d.bb.Enabled     = true
			break
		end
	end
end)

R.WordRejected.OnClientEvent:Connect(function()
	shakeBillboard(cache[Players.LocalPlayer])
end)

R.OpponentWrong.OnClientEvent:Connect(function(zn, playerName)
	if not activeZones[zn] then return end
	if playerName == Players.LocalPlayer.Name then return end
	for plr, d in pairs(cache) do
		if plr.Name == playerName then
			shakeBillboard(d)
			break
		end
	end
end)

R.PlayerEliminated.OnClientEvent:Connect(function(zn, _sid, name)
	for plr, d in pairs(cache) do
		if plr.Name == name and d.bb then
			d.bb.Enabled = false
			break
		end
	end
	
	local targetPlr = Players:FindFirstChild(name)
	if targetPlr then
		toggleTitle(targetPlr, true) -- Munculkan title kembali
	end
	
	local playerZone = playerZoneMap[name]
	if playerZone and activeZones[playerZone] then
		activeZones[playerZone].players[name] = nil
	end
	playerZoneMap[name] = nil
	if name == Players.LocalPlayer.Name then
		isLocalParticipant = false
		localActiveZone    = nil
		stopDoF()
	end
end)

R.GameEnded.OnClientEvent:Connect(function(zn, _sid, _winnerName)
	if activeZones[zn] then
		hideZoneBillboards(zn)
		for name in pairs(activeZones[zn].players) do
			playerZoneMap[name] = nil
			local targetPlr = Players:FindFirstChild(name)
			if targetPlr then
				toggleTitle(targetPlr, true) -- Munculkan title kembali
			end
		end
		activeZones[zn] = nil
	end

	gameActive = (next(activeZones) ~= nil)

	if localActiveZone == zn then
		isLocalParticipant = false
		localActiveZone    = nil
		stopDoF()
	end
end)

R.LiveTyping.OnClientEvent:Connect(function(senderName, text)
	if not gameActive then return end
	for plr, d in pairs(cache) do
		if plr.Name == senderName and d.bb then
			updateWordBoxes(d.container, text)
			local display = (text and text ~= "") and text or "..."
			local w = math.clamp(#display * BB_CHAR_W + 20 + (#display * 30), BB_BASE_W, BB_MAX_W * 2)
			d.bb.Size        = UDim2.new(0, w, 0, BB_BASE_H)
			d.bb.Enabled     = true
			break
		end
	end
end)