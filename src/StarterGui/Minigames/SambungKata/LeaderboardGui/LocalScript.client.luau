-- ============================================================
-- LeaderboardGui.client.lua
-- Renders wins board + fake losses board
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Remotes")
local LeaderboardUpdate = Remotes:WaitForChild("LeaderboardUpdate")
local LossLeaderboardUpdate = Remotes:WaitForChild("LossLeaderboardUpdate")

local MAX_DISPLAY = 10
local REFRESH_INTERVAL = 30  -- harus sama dengan LeaderboardService

local BG = Color3.fromRGB(18, 14, 10)
local BG_SOFT = Color3.fromRGB(31, 25, 17)
local PANEL = Color3.fromRGB(42, 34, 25)
local PANEL_ALT = Color3.fromRGB(36, 30, 22)
local PANEL_SUB = Color3.fromRGB(58, 47, 33)
local MAROON = Color3.fromRGB(77, 22, 20)
local MAROON_DARK = Color3.fromRGB(42, 13, 12)
local STEEL = Color3.fromRGB(64, 62, 55)
local STEEL_DARK = Color3.fromRGB(29, 29, 28)
local PARCHMENT = Color3.fromRGB(229, 205, 151)
local WHITE = Color3.fromRGB(252, 241, 210)
local MUTED = Color3.fromRGB(186, 166, 124)
local FAINT = Color3.fromRGB(126, 103, 67)
local GOLD = Color3.fromRGB(255, 211, 101)
local GOLD_LIGHT = Color3.fromRGB(255, 237, 172)
local GOLD_SOFT = Color3.fromRGB(98, 67, 21)
local SILVER = Color3.fromRGB(213, 218, 216)
local SILVER_SOFT = Color3.fromRGB(69, 72, 70)
local BRONZE = Color3.fromRGB(211, 133, 70)
local BRONZE_SOFT = Color3.fromRGB(88, 48, 24)
local BLUE = Color3.fromRGB(95, 138, 192)
local GREEN = Color3.fromRGB(101, 211, 134)
local GREEN_SOFT = Color3.fromRGB(25, 73, 45)
local RED = Color3.fromRGB(207, 67, 58)
local RED_SOFT = Color3.fromRGB(92, 28, 27)
local PINK = Color3.fromRGB(185, 81, 119)
local DIVIDER = Color3.fromRGB(120, 87, 39)
local SHADOW = Color3.fromRGB(0, 0, 0)

local function getFont(name, fallback)
	local ok, value = pcall(function()
		return Enum.Font[name]
	end)
	if ok and value then
		return value
	end
	return fallback
end

local FONT_TITLE = getFont("GrenzeGotisch", Enum.Font.GothamBlack)
local FONT_ACCENT = getFont("Fondamento", Enum.Font.GothamBold)
local FONT_BODY = Enum.Font.GothamMedium
local FONT_BODY_BOLD = Enum.Font.GothamBold

local BOARDS = {
	wins = {
		partName = "LeaderboardPart",
		surfaceName = "LeaderboardSurfaceGui",
		title = "TAKHTA JAWARA",
		subtitle = "Para kesatria dengan kemenangan terbanyak",
		valueHeader = "WINS",
		valueKey = "wins",
		accentA = GOLD,
		accentB = GOLD_LIGHT,
		accentC = BLUE,
		selfColor = GREEN,
		selfSoft = GREEN_SOFT,
	},
	losses = {
		partName = "LeaderboardJawaPalsuPart",
		surfaceName = "LeaderboardJawaPalsuSurfaceGui",
		title = "AULA JAWA PALSU",
		subtitle = "Catatan kekalahan para penantang",
		valueHeader = "LOSS",
		valueKey = "losses",
		accentA = RED,
		accentB = GOLD,
		accentC = BRONZE,
		selfColor = GREEN,
		selfSoft = GREEN_SOFT,
	},
}

local boardStates = {}

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function createGradient(parent, rotation, colors)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation or 0
	gradient.Color = ColorSequence.new(colors)
	gradient.Parent = parent
	return gradient
end

local function addDecorLine(parent, position, size, color, transparency, zIndex)
	local line = Instance.new("Frame")
	line.Position = position
	line.Size = size
	line.BackgroundColor3 = color
	line.BackgroundTransparency = transparency or 0
	line.BorderSizePixel = 0
	line.ZIndex = zIndex or 1
	line.Parent = parent
	return line
end

local function addRivet(parent, position, size, color, zIndex)
	local rivet = Instance.new("Frame")
	rivet.Size = UDim2.new(0, size, 0, size)
	rivet.Position = position
	rivet.BackgroundColor3 = color
	rivet.BorderSizePixel = 0
	rivet.ZIndex = zIndex or 4
	rivet.Parent = parent
	createCorner(rivet, math.floor(size / 2))
	createStroke(rivet, GOLD_LIGHT, 1, 0.35)
	createGradient(rivet, 90, {
		ColorSequenceKeypoint.new(0, GOLD_LIGHT),
		ColorSequenceKeypoint.new(1, GOLD_SOFT),
	})
	return rivet
end

local function addCornerPlate(parent, xScale, xOffset, yScale, yOffset, anchorX, anchorY)
	local plate = Instance.new("Frame")
	plate.Size = UDim2.new(0, 34, 0, 34)
	plate.Position = UDim2.new(xScale, xOffset, yScale, yOffset)
	plate.AnchorPoint = Vector2.new(anchorX, anchorY)
	plate.BackgroundColor3 = STEEL_DARK
	plate.BorderSizePixel = 0
	plate.ZIndex = 3
	plate.Parent = parent
	createCorner(plate, 8)
	createStroke(plate, GOLD_SOFT, 1.4, 0.24)
	createGradient(plate, 45, {
		ColorSequenceKeypoint.new(0, STEEL),
		ColorSequenceKeypoint.new(0.5, STEEL_DARK),
		ColorSequenceKeypoint.new(1, GOLD_SOFT),
	})

	addDecorLine(plate, UDim2.new(0, 7, 0, 8), UDim2.new(1, -14, 0, 2), GOLD, 0.28, 4)
	addDecorLine(plate, UDim2.new(0, 8, 0, 7), UDim2.new(0, 2, 1, -14), GOLD, 0.28, 4)
	addRivet(plate, UDim2.new(0.5, -4, 0.5, -4), 8, GOLD_SOFT, 5)
	return plate
end

local function getRankText(rank)
	if rank == 1 then
		return "I"
	end
	if rank == 2 then
		return "II"
	end
	if rank == 3 then
		return "III"
	end
	return "#" .. tostring(rank)
end

local function findPart(name)
	for _ = 1, 20 do
		local part = workspace:FindFirstChild(name, true)
		if part then
			return part
		end
		task.wait(1)
	end
end

local function getRankPalette(rank)
	if rank == 1 then
		return GOLD, GOLD_SOFT
	end
	if rank == 2 then
		return SILVER, SILVER_SOFT
	end
	if rank == 3 then
		return BRONZE, BRONZE_SOFT
	end
	return MUTED, PANEL_SUB
end

local function getRowHeight(rank)
	if rank <= 3 then
		return 42
	end
	return 31
end

local function getEntryValue(entry, boardConfig)
	local direct = entry[boardConfig.valueKey]
	if direct ~= nil then
		return direct
	end
	return entry.value or 0
end

local function createAvatar(parent, userId, size, borderColor)
	local avatarRing = Instance.new("Frame")
	avatarRing.Size = UDim2.new(0, size, 0, size)
	avatarRing.BackgroundColor3 = PANEL_SUB
	avatarRing.BorderSizePixel = 0
	avatarRing.ZIndex = 10
	avatarRing.Parent = parent
	createCorner(avatarRing, math.floor(size / 2))
	createStroke(avatarRing, borderColor, 1.4, 0.25)

	local avatar = Instance.new("ImageLabel")
	avatar.Size = UDim2.new(1, -4, 1, -4)
	avatar.Position = UDim2.new(0, 2, 0, 2)
	avatar.BackgroundTransparency = 1
	avatar.ScaleType = Enum.ScaleType.Crop
	avatar.ZIndex = 11
	avatar.Parent = avatarRing
	createCorner(avatar, math.floor((size - 4) / 2))

	task.spawn(function()
		local ok, url = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
		end)
		if ok and url and avatar.Parent then
			avatar.Image = url
		end
	end)

	return avatarRing
end

local function buildBoard(boardKey)
	local boardConfig = BOARDS[boardKey]
	local part = findPart(boardConfig.partName)
	if not part then
		return
	end

	local old = part:FindFirstChild(boardConfig.surfaceName)
	if old then
		old:Destroy()
	end

	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = boardConfig.surfaceName
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.LightInfluence = 0
	surfaceGui.Brightness = 1
	surfaceGui.ClipsDescendants = true
	surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	surfaceGui.Parent = part

	local root = Instance.new("Frame")
	root.Size = UDim2.new(1, 0, 1, 0)
	root.BackgroundColor3 = BG
	root.BorderSizePixel = 0
	root.ClipsDescendants = true
	root.Parent = surfaceGui
	createCorner(root, 10)
	createStroke(root, GOLD_SOFT, 3, 0.05)
	createGradient(root, 90, {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 32, 20)),
		ColorSequenceKeypoint.new(0.45, BG),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 8, 7)),
	})

	local innerFrame = Instance.new("Frame")
	innerFrame.Size = UDim2.new(1, -16, 1, -16)
	innerFrame.Position = UDim2.new(0, 8, 0, 8)
	innerFrame.BackgroundTransparency = 1
	innerFrame.BorderSizePixel = 0
	innerFrame.ZIndex = 2
	innerFrame.Parent = root
	createCorner(innerFrame, 8)
	createStroke(innerFrame, GOLD, 1.2, 0.42)

	addDecorLine(root, UDim2.new(0, 8, 0, 12), UDim2.new(0, 4, 1, -24), GOLD_SOFT, 0.12, 2)
	addDecorLine(root, UDim2.new(1, -12, 0, 12), UDim2.new(0, 4, 1, -24), GOLD_SOFT, 0.12, 2)
	addDecorLine(root, UDim2.new(0, 18, 0, 72), UDim2.new(1, -36, 0, 1), GOLD, 0.42, 3)
	addDecorLine(root, UDim2.new(0, 18, 1, -14), UDim2.new(1, -36, 0, 1), GOLD, 0.48, 3)

	addCornerPlate(root, 0, 10, 0, 10, 0, 0)
	addCornerPlate(root, 1, -10, 0, 10, 1, 0)
	addCornerPlate(root, 0, 10, 1, -10, 0, 1)
	addCornerPlate(root, 1, -10, 1, -10, 1, 1)

	local shadow = Instance.new("Frame")
	shadow.Size = UDim2.new(1, -16, 1, -16)
	shadow.Position = UDim2.new(0, 8, 0, 10)
	shadow.BackgroundColor3 = SHADOW
	shadow.BackgroundTransparency = 0.82
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 0
	shadow.Parent = root
	createCorner(shadow, 10)

	local topGlow = Instance.new("Frame")
	topGlow.Size = UDim2.new(1, 0, 0, 52)
	topGlow.BackgroundColor3 = boardConfig.accentA
	topGlow.BackgroundTransparency = 0.82
	topGlow.BorderSizePixel = 0
	topGlow.Parent = root
	createGradient(topGlow, 0, {
		ColorSequenceKeypoint.new(0, boardConfig.accentA),
		ColorSequenceKeypoint.new(0.48, boardConfig.accentB),
		ColorSequenceKeypoint.new(1, boardConfig.accentC),
	})

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(1, 0, 0, 8)
	accentBar.BackgroundColor3 = boardConfig.accentB
	accentBar.BorderSizePixel = 0
	accentBar.Parent = root

	createGradient(accentBar, 0, {
		ColorSequenceKeypoint.new(0, boardConfig.accentA),
		ColorSequenceKeypoint.new(0.5, boardConfig.accentB),
		ColorSequenceKeypoint.new(1, boardConfig.accentC),
	})

	addRivet(root, UDim2.new(0, 18, 0, 18), 12, GOLD_SOFT, 5)
	addRivet(root, UDim2.new(1, -30, 0, 18), 12, GOLD_SOFT, 5)

	local titlePlate = Instance.new("Frame")
	titlePlate.Size = UDim2.new(1, -72, 0, 54)
	titlePlate.Position = UDim2.new(0, 36, 0, 13)
	titlePlate.BackgroundColor3 = MAROON
	titlePlate.BorderSizePixel = 0
	titlePlate.ZIndex = 4
	titlePlate.Parent = root
	createCorner(titlePlate, 10)
	createStroke(titlePlate, GOLD, 1.6, 0.16)
	createGradient(titlePlate, 0, {
		ColorSequenceKeypoint.new(0, MAROON_DARK),
		ColorSequenceKeypoint.new(0.5, MAROON),
		ColorSequenceKeypoint.new(1, MAROON_DARK),
	})

	addDecorLine(titlePlate, UDim2.new(0, 12, 0, 6), UDim2.new(1, -24, 0, 1), GOLD_LIGHT, 0.44, 5)
	addDecorLine(titlePlate, UDim2.new(0, 12, 1, -7), UDim2.new(1, -24, 0, 1), GOLD_LIGHT, 0.52, 5)
	addRivet(titlePlate, UDim2.new(0, 9, 0.5, -4), 8, GOLD_SOFT, 6)
	addRivet(titlePlate, UDim2.new(1, -17, 0.5, -4), 8, GOLD_SOFT, 6)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -28, 0, 30)
	title.Position = UDim2.new(0, 14, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = boardConfig.title
	title.TextColor3 = GOLD_LIGHT
	title.TextScaled = true
	title.TextStrokeColor3 = SHADOW
	title.TextStrokeTransparency = 0.28
	title.Font = FONT_TITLE
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.ZIndex = 6
	title.Parent = titlePlate

	local subtitle = Instance.new("TextLabel")
	subtitle.Size = UDim2.new(1, -28, 0, 14)
	subtitle.Position = UDim2.new(0, 14, 0, 34)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = boardConfig.subtitle
	subtitle.TextColor3 = PARCHMENT
	subtitle.TextScaled = true
	subtitle.Font = FONT_ACCENT
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.ZIndex = 6
	subtitle.Parent = titlePlate

	local tableWell = Instance.new("Frame")
	tableWell.Size = UDim2.new(1, -16, 1, -104)
	tableWell.Position = UDim2.new(0, 8, 0, 98)
	tableWell.BackgroundColor3 = BG_SOFT
	tableWell.BackgroundTransparency = 0.32
	tableWell.BorderSizePixel = 0
	tableWell.ZIndex = 1
	tableWell.Parent = root
	createCorner(tableWell, 8)
	createStroke(tableWell, DIVIDER, 1, 0.66)
	createGradient(tableWell, 90, {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(38, 29, 18)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 12, 10)),
	})

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, -20, 0, 26)
	header.Position = UDim2.new(0, 10, 0, 74)
	header.BackgroundColor3 = BG_SOFT
	header.BorderSizePixel = 0
	header.ZIndex = 5
	header.Parent = root
	createCorner(header, 8)
	createStroke(header, GOLD_SOFT, 1.2, 0.32)
	createGradient(header, 0, {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(54, 40, 24)),
		ColorSequenceKeypoint.new(0.5, BG_SOFT),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(54, 40, 24)),
	})

	local hRank = Instance.new("TextLabel")
	hRank.Size = UDim2.new(0, 34, 1, 0)
	hRank.Position = UDim2.new(0, 8, 0, 0)
	hRank.BackgroundTransparency = 1
	hRank.Text = "RANK"
	hRank.TextColor3 = FAINT
	hRank.TextScaled = true
	hRank.Font = FONT_BODY_BOLD
	hRank.ZIndex = 6
	hRank.Parent = header

	local hPlayer = Instance.new("TextLabel")
	hPlayer.Size = UDim2.new(0.55, 0, 1, 0)
	hPlayer.Position = UDim2.new(0, 62, 0, 0)
	hPlayer.BackgroundTransparency = 1
	hPlayer.Text = "PEMAIN"
	hPlayer.TextColor3 = FAINT
	hPlayer.TextScaled = true
	hPlayer.Font = FONT_BODY_BOLD
	hPlayer.TextXAlignment = Enum.TextXAlignment.Left
	hPlayer.ZIndex = 6
	hPlayer.Parent = header

	local hValue = Instance.new("TextLabel")
	hValue.Size = UDim2.new(0, 82, 1, 0)
	hValue.Position = UDim2.new(1, -90, 0, 0)
	hValue.BackgroundTransparency = 1
	hValue.Text = boardConfig.valueHeader
	hValue.TextColor3 = FAINT
	hValue.TextScaled = true
	hValue.Font = FONT_BODY_BOLD
	hValue.TextXAlignment = Enum.TextXAlignment.Right
	hValue.ZIndex = 6
	hValue.Parent = header

	local rowContainer = Instance.new("Frame")
	rowContainer.Size = UDim2.new(1, -20, 1, -112)
	rowContainer.Position = UDim2.new(0, 10, 0, 106)
	rowContainer.BackgroundTransparency = 1
	rowContainer.ClipsDescendants = true
	rowContainer.ZIndex = 5
	rowContainer.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = rowContainer

	boardStates[boardKey] = {
		config = boardConfig,
		rowContainer = rowContainer,
	}

	-- ── Footer: digital clock countdown ────────────────────
	local footerBar = Instance.new("Frame")
	footerBar.Size = UDim2.new(1, -20, 0, 20)
	footerBar.Position = UDim2.new(0, 10, 1, -26)
	footerBar.BackgroundColor3 = Color3.fromRGB(15, 12, 8)
	footerBar.BorderSizePixel = 0
	footerBar.ZIndex = 6
	footerBar.Parent = root
	createCorner(footerBar, 5)
	createStroke(footerBar, GOLD_SOFT, 1, 0.65)

	-- Progress track (tipis di bawah)
	local progTrack = Instance.new("Frame")
	progTrack.Size = UDim2.new(1, -6, 0, 2)
	progTrack.Position = UDim2.new(0, 3, 1, -3)
	progTrack.BackgroundColor3 = Color3.fromRGB(35, 28, 16)
	progTrack.BorderSizePixel = 0
	progTrack.ZIndex = 7
	progTrack.Parent = footerBar
	createCorner(progTrack, 1)

	local progFill = Instance.new("Frame")
	progFill.Size = UDim2.new(0, 0, 1, 0)
	progFill.BackgroundColor3 = boardConfig.accentA
	progFill.BorderSizePixel = 0
	progFill.ZIndex = 8
	progFill.Parent = progTrack
	createCorner(progFill, 1)
	createGradient(progFill, 0, {
		ColorSequenceKeypoint.new(0, boardConfig.accentA),
		ColorSequenceKeypoint.new(1, boardConfig.accentB),
	})

	-- Digital clock label — hanya angka MM:SS
	local clockLabel = Instance.new("TextLabel")
	clockLabel.Size = UDim2.new(1, 0, 1, -3)
	clockLabel.Position = UDim2.new(0, 0, 0, 0)
	clockLabel.BackgroundTransparency = 1
	clockLabel.Text = "00:" .. string.format("%02d", REFRESH_INTERVAL)
	clockLabel.TextColor3 = FAINT
	clockLabel.TextScaled = true
	clockLabel.Font = Enum.Font.Code  -- font monospace biar rapi
	clockLabel.TextXAlignment = Enum.TextXAlignment.Center
	clockLabel.ZIndex = 8
	clockLabel.Parent = footerBar

	boardStates[boardKey].clockLabel  = clockLabel
	boardStates[boardKey].progFill    = progFill
	boardStates[boardKey].lastRefresh = tick()

	-- Countdown loop (update tiap detik)
	task.spawn(function()
		while true do
			local state = boardStates[boardKey]
			if not state or not state.clockLabel or not state.clockLabel.Parent then break end

			local elapsed   = tick() - (state.lastRefresh or tick())
			local remaining = math.max(0, REFRESH_INTERVAL - math.floor(elapsed))
			local progress  = math.clamp(elapsed / REFRESH_INTERVAL, 0, 1)

			if state.clockLabel.Parent then
				state.clockLabel.Text = string.format("00:%02d", remaining)
			end
			if state.progFill and state.progFill.Parent then
				TweenService:Create(state.progFill,
					TweenInfo.new(0.9, Enum.EasingStyle.Linear),
					{Size = UDim2.new(progress, 0, 1, 0)}
				):Play()
			end

			task.wait(1)
		end
	end)
end

local function createRow(entry, index, boardConfig)
	local rank = entry.rank or index
	local isSelf = entry.userId == LocalPlayer.UserId
	local isTop3 = rank <= 3
	local accent, accentSoft = getRankPalette(rank)
	local rowHeight = getRowHeight(rank)
	local value = getEntryValue(entry, boardConfig)

	local row = Instance.new("Frame")
	row.Name = "R" .. rank
	row.Size = UDim2.new(1, 0, 0, rowHeight)
	row.LayoutOrder = rank
	row.BackgroundTransparency = 1

	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 1, 0)
	card.BackgroundColor3 = isSelf and boardConfig.selfSoft or ((rank % 2 == 0) and PANEL or PANEL_ALT)
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.ZIndex = 5
	card.Parent = row
	createCorner(card, isTop3 and 10 or 8)
	createStroke(card, isSelf and boardConfig.selfColor or accent, isTop3 and 1.8 or 1.1, isTop3 and 0.22 or 0.58)
	createGradient(card, 0, {
		ColorSequenceKeypoint.new(0, isSelf and boardConfig.selfSoft or PANEL_SUB),
		ColorSequenceKeypoint.new(0.08, isSelf and boardConfig.selfSoft or ((rank % 2 == 0) and PANEL or PANEL_ALT)),
		ColorSequenceKeypoint.new(1, isSelf and boardConfig.selfSoft or BG_SOFT),
	})

	if isTop3 then
		local crownSheen = Instance.new("Frame")
		crownSheen.Size = UDim2.new(1, -10, 1, -8)
		crownSheen.Position = UDim2.new(0, 5, 0, 4)
		crownSheen.BackgroundColor3 = accent
		crownSheen.BackgroundTransparency = 0.9
		crownSheen.BorderSizePixel = 0
		crownSheen.ZIndex = 5
		crownSheen.Parent = card
		createCorner(crownSheen, 8)
		createGradient(crownSheen, 0, {
			ColorSequenceKeypoint.new(0, GOLD_LIGHT),
			ColorSequenceKeypoint.new(0.35, accent),
			ColorSequenceKeypoint.new(1, MAROON_DARK),
		})
	end

	addDecorLine(card, UDim2.new(0, 10, 0, 1), UDim2.new(1, -20, 0, 1), GOLD_LIGHT, isTop3 and 0.55 or 0.78, 8)
	addDecorLine(card, UDim2.new(0, 10, 1, -2), UDim2.new(1, -20, 0, 1), GOLD_SOFT, isTop3 and 0.5 or 0.8, 8)

	local leftStrip = Instance.new("Frame")
	leftStrip.Size = UDim2.new(0, 5, 1, 0)
	leftStrip.BackgroundColor3 = isSelf and boardConfig.selfColor or accent
	leftStrip.BorderSizePixel = 0
	leftStrip.ZIndex = 9
	leftStrip.Parent = card
	createCorner(leftStrip, isTop3 and 10 or 8)
	createGradient(leftStrip, 90, {
		ColorSequenceKeypoint.new(0, GOLD_LIGHT),
		ColorSequenceKeypoint.new(0.5, isSelf and boardConfig.selfColor or accent),
		ColorSequenceKeypoint.new(1, BRONZE),
	})

	local rankBadge = Instance.new("Frame")
	rankBadge.Size = UDim2.new(0, isTop3 and 40 or 28, 0, isTop3 and 28 or 22)
	rankBadge.Position = UDim2.new(0, 12, 0.5, isTop3 and -14 or -11)
	rankBadge.BackgroundColor3 = isSelf and boardConfig.selfSoft or accentSoft
	rankBadge.BorderSizePixel = 0
	rankBadge.ZIndex = 10
	rankBadge.Parent = card
	createCorner(rankBadge, isTop3 and 10 or 7)
	createStroke(rankBadge, isSelf and boardConfig.selfColor or accent, 1, 0.2)
	createGradient(rankBadge, 90, {
		ColorSequenceKeypoint.new(0, isTop3 and GOLD_SOFT or accentSoft),
		ColorSequenceKeypoint.new(1, isSelf and boardConfig.selfSoft or BG_SOFT),
	})

	local rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(1, 0, 1, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = getRankText(rank)
	rankLabel.TextColor3 = isSelf and boardConfig.selfColor or (isTop3 and GOLD_LIGHT or accent)
	rankLabel.TextScaled = true
	rankLabel.TextStrokeColor3 = SHADOW
	rankLabel.TextStrokeTransparency = isTop3 and 0.5 or 1
	rankLabel.Font = FONT_BODY_BOLD
	rankLabel.ZIndex = 11
	rankLabel.Parent = rankBadge

	local avatarSize = isTop3 and 28 or 22
	local avatar = createAvatar(card, entry.userId, avatarSize, isSelf and boardConfig.selfColor or accent)
	avatar.Position = UDim2.new(0, isTop3 and 58 or 48, 0.5, -math.floor(avatarSize / 2))
	avatar.ZIndex = 10

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, isTop3 and -210 or -178, 1, 0)
	nameLabel.Position = UDim2.new(0, isTop3 and 96 or 78, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = entry.name or "Player"
	nameLabel.TextColor3 = isSelf and boardConfig.selfColor or (isTop3 and GOLD_LIGHT or WHITE)
	nameLabel.TextScaled = true
	nameLabel.TextStrokeColor3 = SHADOW
	nameLabel.TextStrokeTransparency = isTop3 and 0.65 or 1
	nameLabel.Font = isTop3 and FONT_ACCENT or FONT_BODY_BOLD
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 10
	nameLabel.Parent = card

	local valueDivider = Instance.new("Frame")
	valueDivider.Size = UDim2.new(0, 1, 1, -12)
	valueDivider.Position = UDim2.new(1, isTop3 and -112 or -100, 0, 6)
	valueDivider.BackgroundColor3 = GOLD_SOFT
	valueDivider.BackgroundTransparency = isTop3 and 0.35 or 0.68
	valueDivider.BorderSizePixel = 0
	valueDivider.ZIndex = 9
	valueDivider.Parent = card

	local valuePill = Instance.new("Frame")
	valuePill.Size = UDim2.new(0, isTop3 and 88 or 78, 0, isTop3 and 28 or 22)
	valuePill.Position = UDim2.new(1, -(isTop3 and 98 or 88), 0.5, isTop3 and -14 or -11)
	valuePill.BackgroundColor3 = isSelf and boardConfig.selfSoft or BG_SOFT
	valuePill.BorderSizePixel = 0
	valuePill.ZIndex = 10
	valuePill.Parent = card
	createCorner(valuePill, isTop3 and 10 or 7)
	createStroke(valuePill, isSelf and boardConfig.selfColor or accent, 1, 0.45)
	createGradient(valuePill, 0, {
		ColorSequenceKeypoint.new(0, isTop3 and GOLD_SOFT or BG_SOFT),
		ColorSequenceKeypoint.new(1, isSelf and boardConfig.selfSoft or Color3.fromRGB(22, 18, 13)),
	})

	local valueLabel = Instance.new("TextLabel")
	valueLabel.Size = UDim2.new(1, -8, 1, 0)
	valueLabel.Position = UDim2.new(0, 4, 0, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = tostring(value or 0)
	valueLabel.TextColor3 = isSelf and boardConfig.selfColor or (isTop3 and GOLD_LIGHT or WHITE)
	valueLabel.TextScaled = true
	valueLabel.TextStrokeColor3 = SHADOW
	valueLabel.TextStrokeTransparency = isTop3 and 0.6 or 1
	valueLabel.Font = FONT_BODY_BOLD
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.ZIndex = 11
	valueLabel.Parent = valuePill

	if isSelf then
		local youTag = Instance.new("TextLabel")
		youTag.Size = UDim2.new(0, 38, 0, 14)
		youTag.Position = UDim2.new(1, -140, 0, 4)
		youTag.BackgroundTransparency = 1
		youTag.Text = "YOU"
		youTag.TextColor3 = boardConfig.selfColor
		youTag.TextScaled = true
		youTag.Font = FONT_BODY_BOLD
		youTag.ZIndex = 12
		youTag.Parent = card
	end

	card.BackgroundTransparency = 1
	TweenService:Create(card, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	}):Play()

	return row
end

local function updateDisplay(boardKey, topData)
	local boardState = boardStates[boardKey]
	if not boardState then
		return
	end

	-- Flash progress bar saat data baru masuk
	local fill = boardState.progFill
	local clk  = boardState.clockLabel
	if fill and fill.Parent then
		fill.Size = UDim2.new(1, 0, 1, 0)
		task.delay(0.35, function()
			if fill.Parent then fill.Size = UDim2.new(0, 0, 1, 0) end
		end)
	end
	-- Kedipkan jam sesaat (terang → normal)
	if clk and clk.Parent then
		clk.TextColor3 = boardState.config.accentA
		task.delay(0.5, function()
			if clk and clk.Parent then clk.TextColor3 = FAINT end
		end)
	end

	local rowContainer = boardState.rowContainer
	for _, child in ipairs(rowContainer:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextLabel") then
			child:Destroy()
		end
	end

	if not topData or #topData == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 46)
		empty.BackgroundTransparency = 1
		empty.Text = "Belum ada data leaderboard"
		empty.TextColor3 = MUTED
		empty.TextScaled = true
		empty.Font = FONT_ACCENT
		empty.Parent = rowContainer
	else
		for i = 1, math.min(#topData, MAX_DISPLAY) do
			local row = createRow(topData[i], i, boardState.config)
			row.Parent = rowContainer
		end
	end

	-- Reset countdown timer
	boardState.lastRefresh = tick()
end

for boardKey in pairs(BOARDS) do
	task.spawn(function()
		buildBoard(boardKey)
	end)
end

LeaderboardUpdate.OnClientEvent:Connect(function(topData)
	if type(topData) == "table" then
		updateDisplay("wins", topData)
	end
end)

LossLeaderboardUpdate.OnClientEvent:Connect(function(topData)
	if type(topData) == "table" then
		updateDisplay("losses", topData)
	end
end)
