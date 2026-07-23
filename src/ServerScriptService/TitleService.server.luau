-- ============================================================
-- TitleService.server.luau
-- ServerScriptService/TitleService
-- Sistem Playtime & Title (Global), terpisah dari minigame.
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

-- -- Fallback Sistem Lama --------------------------------------
local oldRemotes = ReplicatedStorage:FindFirstChild("Remotes")
if not oldRemotes then
	oldRemotes = Instance.new("Folder")
	oldRemotes.Name = "Remotes"
	oldRemotes.Parent = ReplicatedStorage
end
if not oldRemotes:FindFirstChild("OpenUpdateLog") then
	local r = Instance.new("RemoteEvent")
	r.Name = "OpenUpdateLog"
	r.Parent = oldRemotes
end
if not ReplicatedStorage:FindFirstChild("PromoTeleportEvent") then
	local r = Instance.new("RemoteEvent")
	r.Name = "PromoTeleportEvent"
	r.Parent = ReplicatedStorage
end

-- -- Inisialisasi TitleRemotes -------------------------------
local function getOrCreate(parent, class, name)
	local obj = parent:FindFirstChild(name)
	if not obj then
		obj = Instance.new(class)
		obj.Name   = name
		obj.Parent = parent
	end
	return obj
end

local titleRemotes = getOrCreate(ReplicatedStorage, "Folder", "TitleRemotes")
local UpdateTitle  = getOrCreate(titleRemotes, "RemoteEvent", "UpdateTitle")
local ReportDevice = getOrCreate(titleRemotes, "RemoteEvent", "ReportDevice")

-- ============================================================
-- Config
-- ============================================================
local DEVELOPER_IDS = {}
local ADMIN_IDS = {}

local GROUP_ID = 152660069
local VIP_GAMEPASS_ID = 0 -- GANTI DENGAN ID GAMEPASS VIP JIKA ADA

local PlaytimeStore = DataStoreService:GetDataStore("PlayerPlaytimeData_v1")

local WIN_TITLES = {
	{ min = 200, name = "Putra Bangsa",  color = Color3.fromRGB(255, 0, 0), theme = "Merdeka" },
	{ min = 100, name = "Legenda",       color = Color3.fromRGB(255, 215, 0), theme = "Gold" },
	{ min = 50,  name = "Panglima",      color = Color3.fromRGB(255, 0, 0), theme = "Merdeka" },
	{ min = 30,  name = "Veteran",       color = Color3.fromRGB(255, 255, 255), theme = "Merdeka" },
	{ min = 15,  name = "Pahlawan",      color = Color3.fromRGB(255, 0, 0), theme = "Merdeka" },
	{ min = 5,   name = "Pejuang",       color = Color3.fromRGB(255, 255, 255), theme = "Merdeka" },
	{ min = 0,   name = "Rakyat",        color = Color3.fromRGB(200, 200, 200), theme = "Normal" },
}

-- ============================================================
-- State
-- ============================================================
local joinTime  = {}
local savedPlaytime = {} -- Menyimpan jam main sebelumnya
local titleCache = {}
local devices = {} -- [player] = "PC" or "Mobile"

ReportDevice.OnServerEvent:Connect(function(plr, devName)
	devices[plr] = devName
	-- Update semua client tentang info device baru ini
	pcall(broadcastTitle, plr)
end)

-- ============================================================
-- Fungsi
-- ============================================================
local function getGroupRole(plr)
	if GROUP_ID == 0 then return nil end
	local ok, role = pcall(function()
		return plr:GetRoleInGroup(GROUP_ID)
	end)
	if ok and role and role ~= "Guest" then
		return role
	end
	return nil
end

local function getTitleData(plr)
	if DEVELOPER_IDS[plr.UserId] then
		return { title = "Developer", color = Color3.fromRGB(255, 70, 70), special = true, theme = "Gold" }
	end

	if ADMIN_IDS[plr.UserId] then
		return { title = "Admin", color = Color3.fromRGB(255, 150, 50), special = true, theme = "Gold" }
	end

	local groupRole = getGroupRole(plr)
	if groupRole then
		local lowerRole = groupRole:lower()
		if lowerRole:match("owner") or lowerRole:match("founder") or lowerRole:match("ceo") then
			return { title = groupRole, color = Color3.fromRGB(255, 215, 0), special = true, theme = "Gold" }
		elseif lowerRole:match("admin") or lowerRole:match("mod") then
			return { title = groupRole, color = Color3.fromRGB(255, 150, 50), special = true, theme = "Gold" }
		else
			-- Member grup biasa → "Warga Merdeka"
			return { title = "Warga Merdeka", color = Color3.fromRGB(255, 255, 255), special = false, theme = "Merdeka" }
		end
	end

	-- Bukan anggota grup → "Warga Asing"
	return { title = "Warga Asing", color = Color3.fromRGB(150, 150, 150), special = false, theme = "Normal" }
end

function broadcastTitle(plr)
	local data = getTitleData(plr)
	local sessionTime = tick() - (joinTime[plr] or tick())
	local totalTime = (savedPlaytime[plr] or 0) + sessionTime
	local hrs = totalTime / 3600
	
	-- Skala Level (berdasarkan Jam/Hari atau Custom Discord)
	local customLevel = plr:GetAttribute("CustomLevel")
	local levelIcon = "rbxassetid://115246452219328" -- Lvl 1 (Default)
	
	if customLevel then
		local cl = tonumber(customLevel)
		if cl == 6 then levelIcon = "rbxassetid://72809645992227"
		elseif cl == 5 then levelIcon = "rbxassetid://104752087392313"
		elseif cl == 4 then levelIcon = "rbxassetid://116803873835063"
		elseif cl == 3 then levelIcon = "rbxassetid://77485178014318"
		elseif cl == 2 then levelIcon = "rbxassetid://97467805034177"
		end
	else
		if hrs >= 336 then
			levelIcon = "rbxassetid://72809645992227" -- Lvl 6 (14 Hari)
		elseif hrs >= 168 then
			levelIcon = "rbxassetid://104752087392313" -- Lvl 5 (7 Hari)
		elseif hrs >= 72 then
			levelIcon = "rbxassetid://116803873835063" -- Lvl 4 (3 Hari)
		elseif hrs >= 24 then
			levelIcon = "rbxassetid://77485178014318" -- Lvl 3 (1 Hari)
		elseif hrs >= 2 then
			levelIcon = "rbxassetid://97467805034177" -- Lvl 2 (2 Jam)
		end
	end
	
	-- Cek Status (VIP/Member)
	local vipIcon = nil
	local memberIcon = nil
	local groupRole = getGroupRole(plr)
	
	local isOwner = groupRole and (groupRole:lower():match("owner") or groupRole:lower():match("founder") or groupRole:lower():match("ceo"))
	local hasVIPGamepass = plr:GetAttribute("HasFreeVIP") or false
	if not hasVIPGamepass and VIP_GAMEPASS_ID ~= 0 then
		pcall(function()
			hasVIPGamepass = MarketplaceService:UserOwnsGamePassAsync(plr.UserId, VIP_GAMEPASS_ID)
		end)
	end
	
	if isOwner or hasVIPGamepass then
		vipIcon = "rbxassetid://111447814794478" -- VIP
	end
	
	if groupRole then
		memberIcon = "rbxassetid://10371969784835" -- Member
	end
	
	-- Device Icon
	local dev = devices[plr]
	local deviceIcon = nil
	if dev == "Mobile" then
		deviceIcon = "rbxassetid://120282252418181"
	elseif dev == "PC" then
		deviceIcon = "rbxassetid://89047858392586"
	end
	
	-- Bendera Indo
	local flagIcon = "rbxassetid://73486462085662"

	UpdateTitle:FireAllClients({
		playerName = plr.DisplayName,
		userId     = plr.UserId,
		title      = data.title,
		titleColor = { data.color.R, data.color.G, data.color.B },
		theme      = data.theme,
		
		levelIcon  = levelIcon,
		vipIcon    = vipIcon,
		memberIcon = memberIcon,
		flagIcon   = flagIcon,
		deviceIcon = deviceIcon
	})

	titleCache[plr] = data
end

-- ============================================================
-- Player Join / Leave
-- ============================================================
Players.PlayerAdded:Connect(function(plr)
	joinTime[plr] = tick()
	savedPlaytime[plr] = 0
	
	-- Load Saved Playtime
	task.spawn(function()
		local ok, saved = pcall(function()
			return PlaytimeStore:GetAsync(tostring(plr.UserId))
		end)
		if ok and saved then
			savedPlaytime[plr] = saved
		end
		-- Update title setelah playtime diload
		pcall(broadcastTitle, plr)
	end)
	
	-- Cek apakah player punya Free VIP dari Discord
	task.spawn(function()
		local vipStore = DataStoreService:GetDataStore("FreeVIPUsers")
		local hasFree = false
		pcall(function() hasFree = vipStore:GetAsync(tostring(plr.UserId)) end)
		if hasFree then
			plr:SetAttribute("HasFreeVIP", true)
			pcall(broadcastTitle, plr)
		end
	end)
	
	-- Listener jika VIP diberikan mendadak saat player sedang main
	plr:GetAttributeChangedSignal("HasFreeVIP"):Connect(function()
		if plr:GetAttribute("HasFreeVIP") then
			pcall(broadcastTitle, plr)
		end
	end)
	
	-- Listener jika CustomLevel diubah lewat Discord
	plr:GetAttributeChangedSignal("CustomLevel"):Connect(function()
		pcall(broadcastTitle, plr)
	end)
	
	-- Late Joiner Fix: Beri tahu pemain baru ini tentang title semua orang
	task.spawn(function()
		task.wait(2)
		for _, p in ipairs(Players:GetPlayers()) do
			pcall(broadcastTitle, p)
		end
	end)

	task.spawn(function()
		local ls = plr:WaitForChild("StatsData", 10)
		if ls then
			local wins = ls:WaitForChild("Wins", 5)
			if wins then
				wins.Changed:Connect(function()
					task.wait(0.1)
					broadcastTitle(plr)
				end)
			end
		end
		task.wait(2)
		broadcastTitle(plr)
	end)

	plr.CharacterAdded:Connect(function()
		task.wait(1)
		broadcastTitle(plr)
	end)
end)

Players.PlayerRemoving:Connect(function(plr)
	if joinTime[plr] and savedPlaytime[plr] then
		local sessionTime = tick() - joinTime[plr]
		local totalTime = savedPlaytime[plr] + sessionTime
		pcall(function()
			PlaytimeStore:SetAsync(tostring(plr.UserId), totalTime)
		end)
	end

	joinTime[plr]   = nil
	savedPlaytime[plr] = nil
	titleCache[plr] = nil
	devices[plr] = nil
end)

task.spawn(function()
	while true do
		task.wait(60)
		for _, plr in ipairs(Players:GetPlayers()) do
			pcall(broadcastTitle, plr)
			
			-- Auto-save tiap 1 menit untuk jaga-jaga
			if joinTime[plr] and savedPlaytime[plr] then
				local sessionTime = tick() - joinTime[plr]
				local totalTime = savedPlaytime[plr] + sessionTime
				pcall(function()
					PlaytimeStore:SetAsync(tostring(plr.UserId), totalTime)
				end)
			end
		end
	end
end)

print("[TitleService] Aktif - Sistem title VIP/Member & Level Icon siap!")