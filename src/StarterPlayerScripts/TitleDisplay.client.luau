-- ============================================================
-- TitleDisplay.client.luau
-- StarterPlayerScripts/TitleDisplay
-- Menampilkan title di atas kepala semua pemain (global untuk map)
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")

-- Tunggu remote event dari server
local titleRemotes = ReplicatedStorage:WaitForChild("TitleRemotes", 30)
if not titleRemotes then
	warn("[TitleDisplay] TitleRemotes tidak ditemukan!")
	return
end
local UpdateTitle = titleRemotes:WaitForChild("UpdateTitle")
local ReportDevice = titleRemotes:WaitForChild("ReportDevice")

-- Report Device Type to Server
local deviceType = "PC"
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	deviceType = "Mobile"
end
ReportDevice:FireServer(deviceType)

local cache = {} -- [player] = { bb = BillboardGui, topLbl = TextLabel, bot = {...} }

local function createTitleBillboard(character)
	local head = character:WaitForChild("Head", 5)
	if not head then return end

	local old = head:FindFirstChild("GlobalTitleBillboard")
	if old then old:Destroy() end
	
	-- Matikan nama default bawaan Roblox
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	local bb = Instance.new("BillboardGui")
	bb.Name            = "GlobalTitleBillboard"
	bb.Adornee         = head
	-- Menggunakan SCALE (studs) agar UI membesar/mengecil bersama karakter saat zoom
	bb.Size            = UDim2.new(5, 0, 1.8, 0) -- Dikecilkan secara keseluruhan
	bb.StudsOffset     = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop     = true
	bb.ResetOnSpawn    = false
	bb.LightInfluence  = 0
	bb.MaxDistance     = 100 -- Sembunyikan jika terlalu jauh agar tidak lag/numplek
	bb.Parent          = head

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = bb

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0.02, 0)
	layout.Parent = frame

	-- 1. Label: Title (Atas) - 25% height, LayoutOrder 1
	local topLbl = Instance.new("TextLabel")
	topLbl.Name = "TitleLabel"
	topLbl.Size = UDim2.new(1, 0, 0.25, 0)
	topLbl.BackgroundTransparency = 1
	topLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	topLbl.TextScaled = true
	topLbl.RichText = true
	topLbl.Font = Enum.Font.GothamBlack -- Font disamakan semua menjadi GothamBlack
	topLbl.Text = "Loading..."
	topLbl.LayoutOrder = 1
	topLbl.Parent = frame
	
	local strokeTop = Instance.new("UIStroke")
	strokeTop.Name = "Stroke"
	strokeTop.Color = Color3.fromRGB(0, 0, 0)
	strokeTop.Thickness = 2.5
	strokeTop.Transparency = 0.2
	strokeTop.Parent = topLbl
	
	local gradTop = Instance.new("UIGradient")
	gradTop.Name = "Gradient"
	gradTop.Parent = topLbl

	-- 2. Icon Area (Tengah) - 40% height, LayoutOrder 2
	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "IconFrame"
	iconFrame.Size = UDim2.new(1, 0, 0.4, 0)
	iconFrame.BackgroundTransparency = 1
	iconFrame.LayoutOrder = 2
	iconFrame.Parent = frame
	
	local ICON_SIZE = UDim2.new(0.85, 0, 0.85, 0)
	
	-- ========== CENTER: Avatar Headshot (SELALU tepat di tengah) ==========
	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Name = "AvatarHeadshot"
	avatarImg.AnchorPoint = Vector2.new(0.5, 0.5)
	avatarImg.Position = UDim2.new(0.5, 0, 0.5, 0)
	avatarImg.SizeConstraint = Enum.SizeConstraint.RelativeYY
	avatarImg.Size = UDim2.new(1.1, 0, 1.1, 0) -- Sedikit lebih besar biar jadi pusat
	avatarImg.BackgroundTransparency = 1
	avatarImg.Image = ""
	avatarImg.ZIndex = 2
	avatarImg.Parent = iconFrame
	
	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatarImg
	
	-- ========== LEFT: Icon di kiri avatar (VIP, Member) ==========
	local leftIcons = Instance.new("Frame")
	leftIcons.Name = "LeftIcons"
	leftIcons.AnchorPoint = Vector2.new(1, 0.5)
	leftIcons.Position = UDim2.new(0.44, 0, 0.5, 0) -- Mepet ke sisi kiri avatar (tidak nabrak)
	leftIcons.Size = UDim2.new(0.35, 0, 1, 0)
	leftIcons.BackgroundTransparency = 1
	leftIcons.Parent = iconFrame
	
	local leftLayout = Instance.new("UIListLayout")
	leftLayout.FillDirection = Enum.FillDirection.Horizontal
	leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	leftLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
	leftLayout.Padding = UDim.new(0, 1) -- Jarak sangat rapat
	leftLayout.Parent = leftIcons
	
	-- ========== RIGHT: Icon di kanan avatar (Level, Flag, Device) ==========
	local rightIcons = Instance.new("Frame")
	rightIcons.Name = "RightIcons"
	rightIcons.AnchorPoint = Vector2.new(0, 0.5)
	rightIcons.Position = UDim2.new(0.53, 0, 0.5, 0)
	rightIcons.Size = UDim2.new(0.45, 0, 1, 0)
	rightIcons.BackgroundTransparency = 1
	rightIcons.Parent = iconFrame
	-- TIDAK pakai UIListLayout supaya posisi bisa diatur manual per ikon
	
	-- Helper untuk buat icon
	local function createIcon(name, order, parent)
		local img = Instance.new("ImageLabel")
		img.Name = name
		img.SizeConstraint = Enum.SizeConstraint.RelativeYY
		img.Size = ICON_SIZE
		img.BackgroundTransparency = 1
		img.LayoutOrder = order
		img.Visible = false
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = parent
		return img
	end
	
	-- Kiri: VIP → Member (merapat ke avatar dari kanan)
	local vipImg = createIcon("VipIcon", 1, leftIcons)
	vipImg.Size = UDim2.new(0.85, 0, 0.85, 0) 
	
	local memberImg = createIcon("MemberIcon", 2, leftIcons)
	memberImg.Size = UDim2.new(0.85, 0, 0.85, 0)
	
	-- Kanan: Level → Flag → Device (posisi manual, mepet satu sama lain)
	local levelImg = createIcon("LevelIcon", 1, rightIcons)
	levelImg.Size = UDim2.new(1.3, 0, 1.3, 0)
	levelImg.AnchorPoint = Vector2.new(0, 0.5)
	levelImg.Position = UDim2.new(0, 0, 0.5, 0)
	
	local flagImg = createIcon("FlagIcon", 2, rightIcons)
	flagImg.Size = UDim2.new(0.85, 0, 0.85, 0)
	flagImg.AnchorPoint = Vector2.new(0, 0.5)
	flagImg.Position = UDim2.new(0.30, 0, 0.5, 0) -- Sedikit jarak dari level icon
	
	local deviceImg = createIcon("DeviceIcon", 3, rightIcons)
	deviceImg.Size = UDim2.new(0.85, 0, 0.85, 0)
	deviceImg.AnchorPoint = Vector2.new(0, 0.5)
	deviceImg.Position = UDim2.new(0.53, 0, 0.5, 0) -- Agak kananan dikit

	-- 3. Label: Name (Bawah) - 20% height, LayoutOrder 3
	local nameLbl = Instance.new("TextLabel")
	nameLbl.Name = "NameLabel"
	nameLbl.Size = UDim2.new(1, 0, 0.20, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.TextScaled = true
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.Text = "..."
	nameLbl.LayoutOrder = 3
	nameLbl.Parent = frame
	
	local strokeName = Instance.new("UIStroke")
	strokeName.Color = Color3.fromRGB(0, 0, 0)
	strokeName.Thickness = 1.5
	strokeName.Parent = nameLbl

	-- 4. Label: Username (Paling Bawah) - 12% height, LayoutOrder 4
	local userLbl = Instance.new("TextLabel")
	userLbl.Name = "UserLabel"
	userLbl.Size = UDim2.new(1, 0, 0.12, 0)
	userLbl.BackgroundTransparency = 1
	userLbl.TextColor3 = Color3.fromRGB(100, 180, 255) -- Warna Biru Terang
	userLbl.TextScaled = true
	userLbl.Font = Enum.Font.GothamBlack
	userLbl.Text = "@..."
	userLbl.LayoutOrder = 4
	userLbl.Parent = frame
	
	local strokeUser = Instance.new("UIStroke")
	strokeUser.Color = Color3.fromRGB(0, 0, 50)
	strokeUser.Thickness = 1
	strokeUser.Parent = userLbl

	return bb, topLbl, {
		levelImg = levelImg,
		vipImg = vipImg,
		memberImg = memberImg,
		flagImg = flagImg,
		deviceImg = deviceImg,
		avatarImg = avatarImg,
		nameLbl = nameLbl,
		userLbl = userLbl
	}
end

local function onCharacterAdded(plr, character)
	local bb, topLbl, bot = createTitleBillboard(character)
	if bb and topLbl and bot then
		cache[plr] = { bb = bb, topLbl = topLbl, bot = bot }
	end
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr.Character then
		onCharacterAdded(plr, plr.Character)
	end
	plr.CharacterAdded:Connect(function(char)
		onCharacterAdded(plr, char)
	end)
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		onCharacterAdded(plr, char)
	end)
end)

Players.PlayerRemoving:Connect(function(plr)
	cache[plr] = nil
end)

UpdateTitle.OnClientEvent:Connect(function(data)
	local plr = Players:FindFirstChild(data.playerName)
	if not plr then
		for _, p in ipairs(Players:GetPlayers()) do
			if p.DisplayName == data.playerName or p.Name == data.playerName then
				plr = p
				break
			end
		end
	end
	
	if not plr then return end
	
	local c = cache[plr]
	if c and c.topLbl and c.bot then
		c.topLbl.Text = data.title
		
		local lowerTitle = data.title:lower()
		if lowerTitle:match("founder") or lowerTitle:match("member") or lowerTitle:match("owner") or lowerTitle:match("admin") or lowerTitle:match("developer") or lowerTitle:match("mod") then
			c.topLbl.Font = Enum.Font.Fantasy
		else
			c.topLbl.Font = Enum.Font.Fantasy
		end
		
		local stroke = c.topLbl:FindFirstChild("Stroke")
		local grad = c.topLbl:FindFirstChild("Gradient")
		
		grad:SetAttribute("Theme", data.theme)
		
		if data.theme == "Gold" then
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 100)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 215, 0)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 0))
			})
			stroke.Color = Color3.fromRGB(80, 40, 0)
			stroke.Thickness = 3
		elseif data.theme == "Merdeka" then
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 20, 20)),
				ColorSequenceKeypoint.new(0.48, Color3.fromRGB(220, 10, 10)),
				ColorSequenceKeypoint.new(0.52, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
			})
			stroke.Color = Color3.fromRGB(20, 0, 0)
			stroke.Thickness = 2.5
		else
			grad.Color = ColorSequence.new(Color3.fromRGB(220, 220, 220))
			stroke.Color = Color3.fromRGB(0, 0, 0)
			stroke.Thickness = 2
		end
		
		-- Update Bot Icons & Name
		local b = c.bot
		
		-- Cek apakah dia berhak mendapat Verified Badge
		local isVerified = lowerTitle:match("owner") or lowerTitle:match("ceo") or lowerTitle:match("admin") or lowerTitle:match("mod") or lowerTitle:match("founder")
		
		if isVerified then
			b.nameLbl.Text = plr.DisplayName .. " " .. utf8.char(0xE000)
		else
			b.nameLbl.Text = plr.DisplayName
		end
		
		b.nameLbl.TextColor3 = Color3.new(data.titleColor[1], data.titleColor[2], data.titleColor[3])
		
		b.userLbl.Text = "@" .. plr.Name
		
		if data.levelIcon then b.levelImg.Image = data.levelIcon; b.levelImg.Visible = true else b.levelImg.Visible = false end
		if data.vipIcon then b.vipImg.Image = data.vipIcon; b.vipImg.Visible = true else b.vipImg.Visible = false end
		if data.memberIcon then b.memberImg.Image = data.memberIcon; b.memberImg.Visible = true else b.memberImg.Visible = false end
		if data.flagIcon then b.flagImg.Image = data.flagIcon; b.flagImg.Visible = true else b.flagImg.Visible = false end
		if data.deviceIcon then b.deviceImg.Image = data.deviceIcon; b.deviceImg.Visible = true else b.deviceImg.Visible = false end
		
		-- Load Avatar Headshot (gambar muka avatar bundar)
		if data.userId and b.avatarImg then
			task.spawn(function()
				local ok, content = pcall(function()
					return Players:GetUserThumbnailAsync(data.userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
				end)
				if ok and content then
					b.avatarImg.Image = content
				end
			end)
		end
	end
end)

-- Animasi RGB / Gradient
RunService.RenderStepped:Connect(function()
	local t = tick()
	local goldRot = (t * 50) % 360
	local merdekaOffset = math.sin(t * 2.5) * 0.35

	for _, c in pairs(cache) do
		if c.topLbl then
			local grad = c.topLbl:FindFirstChild("Gradient")
			if grad then
				local theme = grad:GetAttribute("Theme")
				if theme == "Gold" then
					grad.Rotation = goldRot
					grad.Offset = Vector2.new(0, 0)
				elseif theme == "Merdeka" then
					grad.Offset = Vector2.new(merdekaOffset, 0)
					grad.Rotation = 0
				else
					grad.Offset = Vector2.new(0, 0)
					grad.Rotation = 0
				end
			end
		end
	end
end)