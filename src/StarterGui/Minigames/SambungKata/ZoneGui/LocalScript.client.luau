-- ============================================================
-- ZoneGui.client.lua
-- LocalScript → StarterGui/ZoneGui
-- Tombol Keluar zona. Join via ProximityPrompt (tekan E).
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService     = game:GetService("SocialService")
local TweenService      = game:GetService("TweenService")
local StarterGui        = game:GetService("StarterGui")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Modules = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Modules")
local Config  = require(Modules:WaitForChild("GameConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Remotes")

local R = {}
for key, rName in pairs(Config.Remotes) do
	R[key] = Remotes:WaitForChild(rName)
end

-- ── State ────────────────────────────────────────────────────
local currentZoneName = nil
local hasJoined       = false
local joinedZoneName  = nil     -- zone yang player sudah join (duduk)
local zonePlaying     = false   -- true jika zona sedang bermain (game aktif)
local leaveDebounce   = nil     -- delay sebelum hide card saat keluar zone

-- Cache status zone (status bisa datang SEBELUM enteredZone untuk player baru join server)
local zoneStatusCache = {}  -- [zoneName] = "playing" / "countdown" / "waiting"

-- ── Hide/restore GUI saat join zona ──────────────────────────
local hiddenGuis = {}
local EXEMPT_GUIS = {
	ZoneGui = true,
	LeaveGui = true,
	GameGui = true,
	KeyboardGUI = true,
	CoinPopupGui = true,
	LeaderboardGui = true,
	NotificationWin = true,
	NotificationWinGenerated = true,
}

local function hideOtherGuis()
	hiddenGuis = {}
	for _, gui in ipairs(playerGui:GetDescendants()) do
		if gui:IsA("ScreenGui") and not EXEMPT_GUIS[gui.Name] and gui.Enabled then
			gui.Enabled = false
			table.insert(hiddenGuis, gui)
		end
	end
	
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
end

local function restoreOtherGuis()
	for _, gui in ipairs(hiddenGuis) do
		if gui and gui.Parent then gui.Enabled = true end
	end
	hiddenGuis = {}
	
	pcall(function()
		-- StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)
end

-- ── Warna ────────────────────────────────────────────────────
local C = {
	bg      = Color3.fromRGB(14, 14, 16),
	text    = Color3.fromRGB(242, 242, 244),
	sub     = Color3.fromRGB(140, 140, 146),
	btn     = Color3.fromRGB(238, 238, 240),
	btnText = Color3.fromRGB(10,  10,  12),
	leave   = Color3.fromRGB(185, 45,  45),
}

-- ── Referensi ke GUI yang sudah dibuat manual di Studio ──────
-- Script ini bisa berada:
--   (A) DI DALAM ZoneGui ScreenGui → script.Parent = ScreenGui   ← otomatis
--   (B) Di luar (langsung di StarterGui) → cari lewat PlayerGui

local function findScreenGuiByName(name)
	for _, obj in ipairs(playerGui:GetDescendants()) do
		if obj:IsA("ScreenGui") and obj.Name == name then
			return obj
		end
	end
end

local screenGui = findScreenGuiByName("LeaveGui")
if not screenGui and script.Parent:IsA("ScreenGui") and (script.Parent.Name == "LeaveGui" or script.Parent.Name == "ZoneGui") then
	screenGui = script.Parent
end
if not screenGui then
	screenGui = findScreenGuiByName("ZoneGui")
end
if not screenGui then
	screenGui = playerGui:WaitForChild("LeaveGui", 5) or playerGui:WaitForChild("ZoneGui", 10)
end
assert(screenGui, "[ZoneGui] ScreenGui LeaveGui/ZoneGui tidak ditemukan di PlayerGui!")

local card = screenGui:FindFirstChild("Frame") or screenGui:FindFirstChild("ZoneCard")
if not card then
	card = screenGui:WaitForChild("Frame", 5) or screenGui:WaitForChild("ZoneCard", 10)
end
assert(card, "[ZoneGui] Frame utama LeaveGui/ZoneCard tidak ditemukan!")

local leaveBtn = card:FindFirstChild("LeaveButton") or card:FindFirstChild("Keluar")
assert(leaveBtn, "[ZoneGui] LeaveButton/Keluar tidak ditemukan!")

local inviteBtn = card:FindFirstChild("InviteButton")

-- Posisi awal: sembunyikan card dan tombol Keluar
card.Visible = false
leaveBtn.Visible = false
if inviteBtn then
	inviteBtn.Visible = false
end


-- ── Animasi slide ────────────────────────────────────────────
-- SHOWN = posisi asli card dari Studio (tidak di-override)
-- HIDDEN = geser ke bawah layar sejauh 200px dari posisi asli
local SHOWN  = card.Position
local HIDDEN = UDim2.new(
	SHOWN.X.Scale, SHOWN.X.Offset,
	SHOWN.Y.Scale, SHOWN.Y.Offset + 200
)

-- Set posisi awal ke bawah layar agar slide-in tampak benar
card.Position = HIDDEN

local function showCard(visible)
	if visible then
		card.Visible = true
		TweenService:Create(card,
			TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{ Position = SHOWN }
		):Play()
	else
		-- Slide out, lalu sembunyikan sepenuhnya
		TweenService:Create(card,
			TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
			{ Position = HIDDEN }
		):Play()
		task.delay(0.2, function()
			card.Visible = false
			card.Position = HIDDEN  -- reset posisi agar slide-in berikutnya benar
		end)
	end
end

-- ── Helper: update visibilitas tombol Keluar ─────────────────
local function updateButtons()
	-- Keluar hanya muncul saat player sudah join dan zona belum playing
	leaveBtn.Visible = hasJoined and (not zonePlaying)
	if inviteBtn then
		inviteBtn.Visible = hasJoined and (not zonePlaying)
	end
end

local function bindGuiButton(guiObject, callback)
	if not guiObject then return false end
	if guiObject:IsA("GuiButton") then
		guiObject.MouseButton1Click:Connect(callback)
		return true
	end

	for _, desc in ipairs(guiObject:GetDescendants()) do
		if desc:IsA("GuiButton") then
			desc.MouseButton1Click:Connect(callback)
			return true
		end
	end

	if guiObject:IsA("GuiObject") then
		guiObject.Active = true
		guiObject.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				callback()
			end
		end)
		return true
	end

	return false
end

-- ── Terima info dari server ───────────────────────────────────
R.UpdateZoneInfo.OnClientEvent:Connect(function(data)
	if data.enteredZone ~= nil then
		if data.enteredZone ~= "" then
			-- Batalkan debounce leave jika re-enter
			if leaveDebounce then
				task.cancel(leaveDebounce)
				leaveDebounce = nil
			end

			local freshEnter = (currentZoneName ~= data.enteredZone)
			currentZoneName = data.enteredZone

			-- Cek cache: kalau zone sudah playing sebelum kita masuk,
			-- jangan tampilkan card sama sekali
			local cachedStatus = zoneStatusCache[data.enteredZone]
			if cachedStatus == "playing" then
				zonePlaying = true
				updateButtons()
				return
			end

			zonePlaying = false
			updateButtons()
			-- Card TIDAK ditampilkan saat masuk area zona.
			-- Card hanya muncul setelah player tekan E (joinedZone).
		else
			-- Player keluar area zona
			if not hasJoined then
				if leaveDebounce then
					task.cancel(leaveDebounce)
				end
				local savedZone = currentZoneName
				leaveDebounce = task.delay(0.8, function()
					leaveDebounce = nil
					if currentZoneName == savedZone then
						currentZoneName = nil
						showCard(false)
						restoreOtherGuis()
					end
				end)
			end
		end
		-- Cek sinyal join sukses dari server (setelah ProximityPrompt triggered)
	elseif data.joinedZone ~= nil then
		-- Server mengkonfirmasi player bergabung ke zona ini
		hasJoined      = true
		joinedZoneName = data.joinedZone
		-- Pastikan currentZoneName ter-set (mungkin Touch belum fire sebelum ProximityPrompt)
		if not currentZoneName then
			currentZoneName = data.joinedZone
		end
		updateButtons()
		hideOtherGuis()
		showCard(true)
		-- Sembunyikan ProximityPrompt secara lokal agar tidak muncul lagi untuk pemain ini
		local zonesFolder = workspace:FindFirstChild("Zones")
		if zonesFolder then
			local zonePart = zonesFolder:FindFirstChild(data.joinedZone)
			if zonePart then
				local pp = zonePart:FindFirstChildWhichIsA("ProximityPrompt")
				if pp then pp.Enabled = false end
			end
		end
	else
		for _, zInfo in ipairs(data) do
			if zInfo.status == "playing" then
				zoneStatusCache[zInfo.name] = "playing"
			elseif zInfo.status == "countdown" then
				zoneStatusCache[zInfo.name] = "countdown"
			else
				zoneStatusCache[zInfo.name] = "waiting"
			end

			if zInfo.name == currentZoneName then
				local wasPlaying = zonePlaying
				if zInfo.status == "playing" then
					zonePlaying = true
					if not wasPlaying then showCard(false) end
				else
					zonePlaying = false
					updateButtons()
					-- Tidak perlu showCard di sini; card muncul hanya via joinedZone
				end
				break
			end
		end
	end
end)

-- ── Leave ─────────────────────────────────────────────────────
-- (Join sekarang via ProximityPrompt di server, tidak perlu handler di sini)
bindGuiButton(leaveBtn, function()
	-- Gunakan joinedZoneName sebagai fallback kalau currentZoneName nil
	local targetZone = currentZoneName or joinedZoneName
	if not targetZone then return end

	R.RequestLeaveZone:FireServer(targetZone)

	-- Restore ProximityPrompt secara lokal agar bisa tekan E lagi
	local zonesFolder = workspace:FindFirstChild("Zones")
	if zonesFolder then
		local zonePart = zonesFolder:FindFirstChild(targetZone)
		if zonePart then
			local pp = zonePart:FindFirstChildWhichIsA("ProximityPrompt")
			if pp then pp.Enabled = true end
		end
	end

	hasJoined       = false
	joinedZoneName  = nil
	currentZoneName = nil
	updateButtons()
	showCard(false)
	restoreOtherGuis()
end)

if inviteBtn then
	bindGuiButton(inviteBtn, function()
		local canInvite = false
		local ok, result = pcall(function()
			return SocialService:CanSendGameInviteAsync(player)
		end)
		if ok then
			canInvite = result == true
		end
		if not canInvite then
			return
		end

		pcall(function()
			SocialService:PromptGameInvite(player)
		end)
	end)
end

-- ── Game mulai ────────────────────────────────────────────────
R.GameStarted.OnClientEvent:Connect(function(data)
	local zn = data and data.zoneName
	-- Hanya proses jika ini zone milik player
	local isMyGame = false
	if data and data.players then
		for _, n in ipairs(data.players) do
			if n == player.Name then isMyGame = true; break end
		end
	end
	if not isMyGame then return end
	-- Update cache dan state
	if zn then zoneStatusCache[zn] = "playing" end
	hasJoined   = false
	zonePlaying = true
	updateButtons()
	showCard(false)
end)

-- ── Game selesai ──────────────────────────────────────────────
R.GameEnded.OnClientEvent:Connect(function(zn)
	-- Hanya proses jika ini zone yang player ikuti
	if joinedZoneName and zn ~= joinedZoneName then return end
	hasJoined      = false
	joinedZoneName = nil
	zonePlaying    = false
	updateButtons()
	restoreOtherGuis()
	-- Card tidak ditampilkan ulang setelah game selesai;
	-- player bebas jalan pergi, bisa tekan E lagi kapanpun.
end)

-- ZoneCountdown tidak lagi ditampilkan di card (label dihapus)

-- ── Terima sinyal dari GameGui: player tersingkir jadi spectator ──────────────
-- Saat player gugur tapi masih fisik ada di zona (jadi penonton),
-- GUI yang tersembunyi harus dikembalikan dan card zona harus muncul lagi.
playerGui:GetAttributeChangedSignal("_PlayerEliminated"):Connect(function()
	restoreOtherGuis()
	hasJoined      = false
	joinedZoneName = nil
	updateButtons()
	showCard(false)  -- sembunyikan card karena player sudah gugur
end)
