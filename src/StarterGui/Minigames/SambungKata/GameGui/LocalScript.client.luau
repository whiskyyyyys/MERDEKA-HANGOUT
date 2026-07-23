-- GameGui.client.lua  ->  LocalScript -> StarterGui/GameGui
-- Menggunakan GUI yang sudah dibuat manual di Roblox Studio:
--   * GameGui (ScreenGui) = HUD permainan (huruf, salah, nyawa, timer)
--   * KeyboardGUI (ScreenGui) = keyboard untuk mobile
-- TIDAK ada lagi pembuatan GUI secara Instance.new di script ini.

local Players              = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local UserInputService     = game:GetService("UserInputService")
local TweenService         = game:GetService("TweenService")
local RunService           = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local Modules = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Modules")
local Config  = require(Modules:WaitForChild("GameConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Minigames"):WaitForChild("SambungKata"):WaitForChild("Remotes")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")
local camera      = workspace.CurrentCamera

local R = {}
for k, v in pairs(Config.Remotes) do R[k] = Remotes:WaitForChild(v) end

local MAX_HP    = Config.MaxHP           or 2
local MAX_WRONG = Config.MaxWrongPerTurn or 5

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
-- Studio emulator sering report keyboard sebagai non-mobile.
-- Tetap izinkan keyboard UI muncul saat testing di Studio.
local allowKeyboardUI = isMobile or RunService:IsStudio()

-- Fallback keyboard refs (dipakai jika KeyboardGui.client.lua tidak aktif)
local fallbackKbGui = nil
local fallbackKbHolder = nil
local fallbackKbButtonsBound = false

-- =================================================================
-- HELPER: cari ScreenGui berdasarkan nama (hindari conflict dgn LocalScript)
-- =================================================================
local function waitForScreenGui(parent, name, timeout)
	local elapsed = 0
	while true do
		for _, child in ipairs(parent:GetDescendants()) do
			if child:IsA("ScreenGui") and child.Name == name then
				return child
			end
		end
		task.wait(0.1)
		elapsed = elapsed + 0.1
		if timeout and elapsed >= timeout then return nil end
	end
end

local function findKeyboardGuiAndHolder()
	-- Cari ScreenGui keyboard by name
	local kbGui = waitForScreenGui(playerGui, "KeyboardGUI", 1)
		or waitForScreenGui(playerGui, "MobileKeyboard", 1)
		or waitForScreenGui(playerGui, "KeyboardGui", 1)

	-- Fallback: scan semua ScreenGui di PlayerGui
	if not kbGui then
		for _, child in ipairs(playerGui:GetDescendants()) do
			if child:IsA("ScreenGui") then
				if child:FindFirstChild("MobileKeyboard")
					or child:FindFirstChild("MobileKeyborad")
					or child:FindFirstChild("KeyboardFrame") then
					kbGui = child
					break
				end
			end
		end
	end

	if not kbGui then return nil, nil end

	local holder = kbGui:FindFirstChild("MobileKeyboard")
		or kbGui:FindFirstChild("MobileKeyborad")
		or kbGui:FindFirstChild("KeyboardFrame")
		or kbGui

	return kbGui, holder
end

-- =================================================================
-- REFERENSI GUI MANUAL: GameGui ScreenGui
-- =================================================================
local screenGui = waitForScreenGui(playerGui, "GameGui", 10)
assert(screenGui, "[GameGui] ScreenGui 'GameGui' tidak ditemukan di PlayerGui!")
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function disableAutoLocalize(inst)
	if not inst then return end
	pcall(function()
		inst.AutoLocalize = false
	end)
end

disableAutoLocalize(screenGui)
for _, d in ipairs(screenGui:GetDescendants()) do
	disableAutoLocalize(d)
end
screenGui.DescendantAdded:Connect(disableAutoLocalize)

-- Forward declare (diisi nanti setelah WaitForChild)
local nyawaFrame = nil
local wrongDots  = {}   -- forward declare, diisi nanti oleh loop Salah1..5

-- Kumpulkan SEMUA Frame langsung di bawah GameGui ScreenGui
-- (ada 2 Frame: satu untuk hint, satu untuk salah/timer)
local hudFrames = {}
local hudOriginalPositions = {}   -- simpan posisi asli agar bisa dikembalikan
for _, child in ipairs(screenGui:GetChildren()) do
	if child:IsA("Frame") then
		table.insert(hudFrames, child)
		hudOriginalPositions[child] = child.Position
		child.Visible = false
	end
end

-- Fungsi untuk show/hide SEMUA HUD frames sekaligus
local function setHudVisible(visible)
	for _, frame in ipairs(hudFrames) do
		frame.Visible = visible
	end
	-- Nyawa dan Salah tidak ada di hudFrames (dihapus utk anti double-shift)
	-- jadi toggle manual di sini
	if nyawaFrame then
		nyawaFrame.Visible = visible
	end
	for i = 1, MAX_WRONG do
		local entry = wrongDots[i]
		if entry and entry.salah then
			entry.salah.Visible = visible
		end
	end
end

-- Mobile: geser HUD ke atas ketika keyboard tampil supaya tidak tertutup
local HUD_SHIFT_Y = -0.38  -- geser naik 38% layar agar tidak tertutup keyboard
local hudShifted = false
local nyawaOrigPos = nil  -- disimpan saat pertama kali shift

-- Elemen-elemen tambahan di luar hudFrames yang perlu digeser (Salah, Nyawa)
local extraShiftElements = {}  -- { element = originalPosition }

local function shiftHudForKeyboard(up)
	if not allowKeyboardUI then return end
	if up and not hudShifted then
		hudShifted = true
		for _, frame in ipairs(hudFrames) do
			local orig = hudOriginalPositions[frame]
			if orig then
				frame.Position = UDim2.new(
					orig.X.Scale, orig.X.Offset,
					orig.Y.Scale + HUD_SHIFT_Y, orig.Y.Offset
				)
			end
		end
		-- Geser juga Nyawa jika ada
		if nyawaFrame then
			if not nyawaOrigPos then
				nyawaOrigPos = nyawaFrame.Position
			end
			nyawaFrame.Position = UDim2.new(
				nyawaOrigPos.X.Scale, nyawaOrigPos.X.Offset,
				nyawaOrigPos.Y.Scale + HUD_SHIFT_Y, nyawaOrigPos.Y.Offset
			)
		end
		-- Geser Salah1-5 dan elemen ekstra lainnya
		for elem, orig in pairs(extraShiftElements) do
			elem.Position = UDim2.new(
				orig.X.Scale, orig.X.Offset,
				orig.Y.Scale + HUD_SHIFT_Y, orig.Y.Offset
			)
		end
	elseif not up and hudShifted then
		hudShifted = false
		for _, frame in ipairs(hudFrames) do
			local orig = hudOriginalPositions[frame]
			if orig then
				frame.Position = orig
			end
		end
		if nyawaFrame and nyawaOrigPos then
			nyawaFrame.Position = nyawaOrigPos
		end
		for elem, orig in pairs(extraShiftElements) do
			elem.Position = orig
		end
	end
end

-- Cari elemen-elemen di semua Frame (tidak tahu mana yang di Frame mana)
local function findInHudFrames(name)
	for _, frame in ipairs(hudFrames) do
		local found = frame:FindFirstChild(name, true)
		if found then return found end
	end
	return nil
end

local function findDirectInHudFrames(name)
	for _, frame in ipairs(hudFrames) do
		local found = frame:FindFirstChild(name)
		if found then return found end
	end
	return nil
end

-- Huruf hint: elemen bernama "?"
local wordBox = findDirectInHudFrames("?")
local wordLbl
if wordBox then
	if wordBox:IsA("TextLabel") or wordBox:IsA("TextButton") then
		wordLbl = wordBox
	else
		wordLbl = wordBox:FindFirstChildWhichIsA("TextLabel", true)
	end
end

-- Label "Hurufnya adalah:"
local hintLbl = findDirectInHudFrames("TextLabel")

-- Timer: cari di semua frames
local timerNum = findInHudFrames("Timer")

-- Wrong indicators: Salah1..Salah5 langsung di bawah ScreenGui (bukan di Frame)
-- wrongDots sudah forward-declare di atas
local wrongFound = 0
for i = 1, MAX_WRONG do
	-- Cari langsung di screenGui dulu, baru fallback ke dalam frames
	local salah = screenGui:FindFirstChild("Salah" .. i) or findInHudFrames("Salah" .. i)
	if not salah then
		warn("[GameGui] Salah" .. i .. " TIDAK ditemukan!")
		continue
	end

	-- Cari child "X" (case-insensitive) atau TextLabel/ImageLabel apapun di dalam
	local x = salah:FindFirstChild("X") or salah:FindFirstChild("x")
	if not x then
		-- Fallback: cari TextLabel atau ImageLabel pertama (bukan constraint/corner/stroke)
		for _, ch in ipairs(salah:GetChildren()) do
			if ch:IsA("TextLabel") or ch:IsA("ImageLabel") or ch:IsA("TextButton") then
				x = ch
				break
			end
		end
	end

	if x then
		x.Visible = false
		wrongDots[i] = { x = x, salah = salah }
		wrongFound = wrongFound + 1
	else
		-- Fallback terakhir: gunakan Salah frame sendiri (ubah transparansi)
		wrongDots[i] = { x = nil, salah = salah }
		salah.BackgroundTransparency = 0.7
		wrongFound = wrongFound + 1
		warn("[GameGui] Salah" .. i .. " ditemukan tapi TIDAK punya child 'X'. Pakai fallback.")
	end
end

-- Register Salah frames ke extraShiftElements agar ikut geser saat keyboard tampil
for i = 1, MAX_WRONG do
	local entry = wrongDots[i]
	if entry and entry.salah then
		extraShiftElements[entry.salah] = entry.salah.Position
	end
end

-- Nyawa (hearts): Nyawa ada langsung di bawah GameGui ScreenGui, bukan di Frame
nyawaFrame = screenGui:WaitForChild("Nyawa", 5)
local heartElements = {}
if nyawaFrame then
	for i = 1, MAX_HP do
		heartElements[i] = nyawaFrame:FindFirstChild("Nyawa" .. i)
	end
else
	warn("[GameGui] 'Nyawa' tidak ditemukan di GameGui. Heart display tidak aktif.")
end

-- Fix: Hapus elemen yang punya shift-handler sendiri dari hudFrames
-- agar tidak terjadi double-shift saat keyboard muncul di mobile
if nyawaFrame then
	for i = #hudFrames, 1, -1 do
		if hudFrames[i] == nyawaFrame then
			table.remove(hudFrames, i)
			hudOriginalPositions[nyawaFrame] = nil
			break
		end
	end
end
for elem, _ in pairs(extraShiftElements) do
	for i = #hudFrames, 1, -1 do
		if hudFrames[i] == elem then
			table.remove(hudFrames, i)
			hudOriginalPositions[elem] = nil
			break
		end
	end
end

-- =================================================================
-- KEYBOARD VISIBILITY: dikelola via Attribute "_KB_Show"
-- KeyboardGui.client.lua (script terpisah) mendengarkan attribute ini.
-- =================================================================
local function setKeyboardVisible(show)
	screenGui:SetAttribute("_KB_Show", show)
	if fallbackKbGui then
		fallbackKbGui.Enabled = true
	end
	if fallbackKbHolder then
		fallbackKbHolder.Visible = show
	end
	shiftHudForKeyboard(show)   -- geser HUD saat keyboard muncul/hilang
end
setKeyboardVisible(false)

-- Setup fallback keyboard finder supaya keyboard tetap muncul walau script KeyboardGui mati.
task.spawn(function()
	local deadline = tick() + 8
	while tick() < deadline do
		local kbGui, kbHolder = findKeyboardGuiAndHolder()
		if kbGui and kbHolder then
			fallbackKbGui = kbGui
			fallbackKbHolder = kbHolder
			fallbackKbGui.Enabled = true
			fallbackKbGui.IgnoreGuiInset = true
			fallbackKbHolder.Visible = (screenGui:GetAttribute("_KB_Show") == true)
			return
		end
		task.wait(0.5)
	end
	warn("[GameGui] Fallback keyboard tidak ditemukan di PlayerGui setelah retry")
end)

-- =================================================================
-- NOTIFIKASI (satu-satunya label yang masih dibuat programatik)
-- =================================================================
local notifLbl = Instance.new("TextLabel")
notifLbl.Name                   = "NotifLabel"
notifLbl.BackgroundTransparency = 1
notifLbl.Font                   = Enum.Font.GothamMedium
notifLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
notifLbl.TextXAlignment         = Enum.TextXAlignment.Center
notifLbl.TextStrokeColor3       = Color3.fromRGB(0, 0, 0)
notifLbl.TextStrokeTransparency = 0.4
notifLbl.Text                   = ""
notifLbl.ZIndex                 = 100
if isMobile then
	notifLbl.Size     = UDim2.new(0, 300, 0, 24)
	notifLbl.Position = UDim2.new(0.5, -150, 0, 20)
	notifLbl.TextSize = 13
else
	notifLbl.Size     = UDim2.new(0, 400, 0, 32)
	notifLbl.Position = UDim2.new(0.5, -200, 1, -240)
	notifLbl.TextSize = 15
end
notifLbl.Parent = screenGui

-- =================================================================
-- SOUND EFFECTS: correct / incorrect
-- Buat Sound di Frame agar mudah dikelola dari Studio juga
-- =================================================================
local soundFrame = Instance.new("Frame")
soundFrame.Name = "SoundFrame"
soundFrame.Size = UDim2.new(0, 0, 0, 0)
soundFrame.BackgroundTransparency = 1
soundFrame.Visible = false
soundFrame.Parent = screenGui

local correctSound = Instance.new("Sound")
correctSound.Name = "correct"
correctSound.SoundId = "rbxassetid://104021426926736"  -- ← ganti dengan SoundId yang kamu mau
correctSound.Volume = 0.5
correctSound.Parent = soundFrame

local incorrectSound = Instance.new("Sound")
incorrectSound.Name = "incorrect"
incorrectSound.SoundId = "rbxassetid://121770852526270"  -- ← ganti dengan SoundId yang kamu mau
incorrectSound.Volume = 0.5
incorrectSound.Parent = soundFrame

-- =================================================================
-- HIDE / RESTORE OTHER GUIs → dikelola oleh ZoneGui.client.lua
-- GameGui tidak lagi menyembunyikan/mengembalikan GUI lain.
-- =================================================================

-- =================================================================
-- SINK ALL ROBLOX KEYBINDS SAAT GAME (no zoom/move/chat)
-- =================================================================
local inGame = false
local SINK_ACTION = "SinkAllKeys"
local gameInputHandler   -- forward declare
local HAPTIC_ENABLED = false
local lastCountdownHaptic = -1

local function stopHaptic()
	-- Haptic dinonaktifkan total sesuai request.
end

local function pulseHaptic(strength, duration, largeStrength)
	if not HAPTIC_ENABLED then
		return
	end
end

local function lockAllKeys()
	local keysToBlock = {}
	for _, kc in pairs(Enum.KeyCode:GetEnumItems()) do
		table.insert(keysToBlock, kc)
	end
	ContextActionService:BindActionAtPriority(
		SINK_ACTION, gameInputHandler, false, 3000, unpack(keysToBlock)
	)
end

local function unlockAllKeys()
	ContextActionService:UnbindAction(SINK_ACTION)
	stopHaptic()
end

-- =================================================================
-- CAMERA SYSTEM: follow active turn player
-- =================================================================
local cameraTarget     = nil
local cameraConnection = nil
local originalCameraType = nil

local function startCameraFollow(targetPlayer)
	cameraTarget = targetPlayer
	if cameraConnection then cameraConnection:Disconnect() end

	originalCameraType = camera.CameraType
	camera.CameraType  = Enum.CameraType.Scriptable

	cameraConnection = RunService.RenderStepped:Connect(function()
		if not cameraTarget then return end
		local char = cameraTarget.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		local pos    = hrp.Position + hrp.CFrame.LookVector * 8 + Vector3.new(0, 2, 0)
		local goalCF = CFrame.lookAt(pos, hrp.Position + Vector3.new(0, 1.5, 0))
		camera.CFrame = camera.CFrame:Lerp(goalCF, 0.08)
	end)
end

local function stopCameraFollow()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end
	cameraTarget = nil
	originalCameraType = nil

	-- ── (1) STOP VIBRATION ───────────────────────────────────
	-- Matikan semua motor haptic agar HP tidak getar
	stopHaptic()

	-- ── (2) RESTORE CAMERA + FIX MOBILE THUMBSTICK ────────────────
	-- Di mobile, kita perlu paksa Custom DULU, tunggu beberapa frame,
	-- BARU set CameraSubject — agar thumbstick kiri tidak terbaca sebagai
	-- camera pan (bug bawaan engine saat transisi dari Scriptable ke Custom)
	local function restoreCameraSubject()
		local char = localPlayer.Character
		if not char then return false end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return false end
		camera.CameraType    = Enum.CameraType.Custom
		camera.CameraSubject = hum
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local behindPos = hrp.Position - hrp.CFrame.LookVector * 10 + Vector3.new(0, 5, 0)
			camera.CFrame = CFrame.lookAt(behindPos, hrp.Position + Vector3.new(0, 1.5, 0))
		end
		return true
	end

	-- Langkah 1: paksa Custom segera
	camera.CameraType = Enum.CameraType.Custom

	-- Langkah 2: tunggu 3 frame agar engine mobile reset thumbstick
	task.spawn(function()
		for _ = 1, 3 do RunService.Heartbeat:Wait() end
		if not restoreCameraSubject() then
			task.delay(0.3, restoreCameraSubject)
		end
	end)

	-- Safety net 1
	task.delay(0.6, function()
		camera.CameraType = Enum.CameraType.Custom
		restoreCameraSubject()
	end)

	-- Safety net 2 (untuk kasus sangat lambat)
	task.delay(1.8, function()
		camera.CameraType = Enum.CameraType.Custom
		restoreCameraSubject()
	end)
end

-- =================================================================
-- STATE
-- =================================================================
local myTurn          = false
local currentTurnName = ""
local wrongCount      = 0
local notifThread     = nil
local typedText       = ""
local lockedPrefix    = ""
local isSpectating    = false  -- true jika pemain tersingkir tapi game belum selesai
local isParticipant   = false  -- true hanya jika pemain ini IKUT main di game ini
local activeZoneName  = nil    -- nama zone tempat kita sedang main
local activeSessionId = nil    -- sessionId unik, mencegah event dari game lain mengganggu
local lastKbBackspaceAt = 0
local lastKbSubmitAt    = 0
local lastSubmitAt      = 0
local lastSubmitWord    = ""
local function normalizeClientWord(rawText)
	if type(rawText) ~= "string" then
		return ""
	end
	local word = (rawText:lower():match("^%s*(.-)%s*$") or "")
	word = word:gsub("%s+", "")
	word = word:gsub("[^a-z]", "")
	return word
end

-- =================================================================
-- UTILITY FUNCTIONS
-- =================================================================
local function showNotif(msg, t)
	notifLbl.Text = msg; notifLbl.TextTransparency = 0
	if notifThread then task.cancel(notifThread) end
	notifThread = task.delay(t or 2.5, function()
		TweenService:Create(notifLbl, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
	end)
end

local function updateHP(hp)
	for i = 1, MAX_HP do
		local elem = heartElements[i]
		if not elem then continue end
		local alive = i <= hp

		-- Cek tipe elemen dan sesuaikan visual
		if elem:IsA("ImageLabel") or elem:IsA("ImageButton") then
			elem.ImageTransparency = alive and 0 or 0.7
		elseif elem:IsA("TextLabel") or elem:IsA("TextButton") then
			elem.TextColor3 = alive
				and Color3.fromRGB(210, 40, 40) or Color3.fromRGB(60, 50, 55)
		else
			-- Frame / container -> cari child ImageLabel atau TextLabel
			local img = elem:FindFirstChildWhichIsA("ImageLabel")
			if img then
				img.ImageTransparency = alive and 0 or 0.7
			end
			local txt = elem:FindFirstChildWhichIsA("TextLabel")
			if txt then
				txt.TextColor3 = alive
					and Color3.fromRGB(210, 40, 40) or Color3.fromRGB(60, 50, 55)
			end
		end
	end
end

local function updateWrong(count)
	wrongCount = count
	for i = 1, MAX_WRONG do
		local entry = wrongDots[i]
		if not entry then continue end
		local active = (i <= count)

		if entry.x then
			-- Punya child X → toggle Visible
			entry.x.Visible = active
		elseif entry.salah then
			-- Fallback: ubah transparansi Salah frame
			entry.salah.BackgroundTransparency = active and 0 or 0.7
		end
	end
end

local function setWordBox(word)
	if wordLbl then
		wordLbl.Text = word and word:upper() or word
	end
end

local function updateOwnBillboard(txt, _retryCount)
	local char = localPlayer.Character
	if not char then return end
	local head = char:FindFirstChild("Head")
	if not head then return end
	local bb = head:FindFirstChild("WordBillboard")
	if not bb then
		-- Billboard belum replicate dari server, coba lagi setelah delay (maks 3x)
		local retry = (_retryCount or 0) + 1
		if retry <= 3 then
			task.delay(0.3, function() updateOwnBillboard(txt, retry) end)
		end
		return
	end
	local container = bb:FindFirstChild("Container")
	if not container then return end
	
	local textStr = txt ~= "" and txt:upper() or "..."
	
	-- Hapus isi container lama
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("Frame") then
			child:Destroy()
		end
	end
	
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
	else
		for i = 1, #textStr do
			local char = textStr:sub(i, i)
			local box = Instance.new("TextLabel")
			box.Size = UDim2.new(0, 30, 0, 36)
			
			box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			box.TextColor3 = Color3.fromRGB(20, 20, 20)
			
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

	-- Ukuran billboard sesuai device (mobile lebih kecil)
	local charW = isMobile and 14 or 22
	local baseW = isMobile and 40 or 64
	local maxW  = isMobile and 200 or 320
	local baseH = isMobile and 40 or 64
	local cw = math.clamp(#textStr * charW + 20 + (#textStr * 30), baseW, maxW * 2)
	bb.Size    = UDim2.new(0, cw, 0, baseH)
	bb.Enabled = true
end

local function refreshDisplay()
	local full = normalizeClientWord(lockedPrefix .. typedText)
	updateOwnBillboard(full)
	R.LiveTyping:FireServer(full)
end

local function addLetter(ch)
	if not myTurn then return end
	local safe = normalizeClientWord(ch or "")
	if safe == "" then return end
	typedText = typedText .. safe:sub(1, 1)
	refreshDisplay()
end

local function removeLetter()
	if not myTurn then return end
	if #typedText <= 0 then return end
	typedText = typedText:sub(1, -2)
	refreshDisplay()
end

local function submitWord()
	if not myTurn then return end
	local full = normalizeClientWord(lockedPrefix .. typedText)
	if full == "" or full == lockedPrefix then return end

	-- Guard: cegah submit dobel dalam waktu sangat dekat
	local now = tick()
	if (now - lastSubmitAt) < 0.35 and full == lastSubmitWord then
		return
	end

	lastSubmitAt = now
	lastSubmitWord = full
	R.SubmitWord:FireServer(full)
	-- JANGAN hapus typedText -- biarkan player hapus sendiri
	-- Text tetap di billboard sampai player delete atau giliran berganti
end

-- =================================================================
-- PC INPUT: ContextAction sinks everything, process A-Z/Enter/BS
-- =================================================================
gameInputHandler = function(_actionName, inputState, inputObj)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Sink
	end
	if not myTurn then
		return Enum.ContextActionResult.Sink
	end

	local kc = inputObj.KeyCode
	if kc == Enum.KeyCode.Return then
		submitWord()
	elseif kc == Enum.KeyCode.Backspace then
		removeLetter()
	else
		local name = kc.Name
		if #name == 1 and name:match("[A-Z]") then
			addLetter(name:lower())
		end
	end
	return Enum.ContextActionResult.Sink
end

-- =================================================================
-- KONEKSI MOBILE KEYBOARD (via Attributes dari KeyboardGui.client.lua)
-- KeyboardGui script terpisah mengirim input lewat Attribute di screenGui.
-- =================================================================
screenGui:GetAttributeChangedSignal("_KB_Letter"):Connect(function()
	local ch = screenGui:GetAttribute("_KB_Letter")
	if ch and ch ~= "" then
		addLetter(ch)
	end
end)

screenGui:GetAttributeChangedSignal("_KB_Backspace"):Connect(function()
	local now = tick()
	if (now - lastKbBackspaceAt) < 0.06 then
		return
	end
	lastKbBackspaceAt = now
	removeLetter()
end)

screenGui:GetAttributeChangedSignal("_KB_Submit"):Connect(function()
	local now = tick()
	if (now - lastKbSubmitAt) < 0.15 then
		return
	end
	lastKbSubmitAt = now
	submitWord()
end)

-- Fallback binder: jika KeyboardGui.client.lua tidak berjalan, tombol tetap berfungsi.
task.spawn(function()
	-- Tunggu beberapa detik untuk memberi kesempatan script KeyboardGui utama set _KB_Ready.
	local readyDeadline = tick() + 8
	while tick() < readyDeadline do
		if screenGui:GetAttribute("_KB_Ready") == true then
			return
		end
		task.wait(0.25)
	end
	if not fallbackKbHolder then
		local kbGui, kbHolder = findKeyboardGuiAndHolder()
		fallbackKbGui = kbGui
		fallbackKbHolder = kbHolder
	end
	if not fallbackKbHolder or fallbackKbButtonsBound then return end

	local function isDeleteButton(btn)
		local name = btn.Name:lower()
		if name == "backspace" or name == "delete" or name == "del" or name == "hapus" or name == "back" then
			return true
		end
		local text = (btn:IsA("TextButton") and btn.Text or ""):gsub("%s+", "")
		local lower = text:lower()
		return lower == "del" or lower == "hapus" or lower == "backspace" or lower == "back" or lower == "delete"
	end

	local function isSubmitButton(btn)
		local name = btn.Name:lower()
		if name == "enter" or name == "submit" or name == "send" or name == "kirim" or name == "ok" then
			return true
		end
		local text = (btn:IsA("TextButton") and btn.Text or ""):gsub("%s+", "")
		local lower = text:lower()
		return lower == "kirim" or lower == "enter" or lower == "send" or lower == "submit" or lower == "ok"
	end

	local function getButtonCharacter(btn)
		if btn:IsA("TextButton") then
			local text = (btn.Text or ""):gsub("%s+", "")
			if #text == 1 and text:match("[A-Za-z]") then
				return text:lower()
			end
		end
		if #btn.Name == 1 and btn.Name:match("[A-Za-z]") then
			return btn.Name:lower()
		end
		return nil
	end

	for _, btn in ipairs(fallbackKbHolder:GetDescendants()) do
		if btn:IsA("TextButton") or btn:IsA("ImageButton") then
			if btn:GetAttribute("_KB_FallbackBound") then
				continue
			end
			btn:SetAttribute("_KB_FallbackBound", true)

			local ch = getButtonCharacter(btn)
			if ch then
				btn.MouseButton1Click:Connect(function()
					screenGui:SetAttribute("_KB_Letter", ch)
					task.defer(function()
						screenGui:SetAttribute("_KB_Letter", "")
					end)
				end)
			elseif isDeleteButton(btn) then
				btn.MouseButton1Click:Connect(function()
					screenGui:SetAttribute("_KB_Backspace", tick())
				end)
			elseif isSubmitButton(btn) then
				btn.MouseButton1Click:Connect(function()
					screenGui:SetAttribute("_KB_Submit", tick())
				end)
			end
		end
	end

	fallbackKbButtonsBound = true
	warn("[GameGui] Keyboard fallback binding aktif (KeyboardGui.client.lua tidak terdeteksi)")
end)

-- =================================================================
-- HELPER
-- =================================================================
local function getPlayerByName(name)
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name == name then return p end
	end
	return nil
end

-- =================================================================
-- REMOTE HANDLERS
-- =================================================================
R.GameStarted.OnClientEvent:Connect(function(data)
	-- Jika sudah ikut main di zone lain, abaikan
	if isParticipant then return end

	-- Cek apakah kita termasuk pemain yang main
	isParticipant = false
	if data and data.players then
		for _, name in ipairs(data.players) do
			if name == localPlayer.Name then
				isParticipant = true
				break
			end
		end
	end

	-- Kalau bukan pemain, abaikan (cukup lihat billboard dari luar)
	if not isParticipant then return end

	activeZoneName  = data.zoneName
	activeSessionId = data.sessionId  -- simpan session ID untuk filter event

	inGame = true
	myTurn = false; typedText = ""; lockedPrefix = ""
	isSpectating = false
	lastCountdownHaptic = -1
	updateHP(MAX_HP); updateWrong(0)
	local seed = (data and data.startWord) or "?"
	setWordBox(seed)
	if timerNum and timerNum:IsA("TextLabel") then
		timerNum.Text       = tostring(Config.TurnTime or 10)
		timerNum.TextColor3 = Color3.fromRGB(80, 220, 80)
	end
	lockAllKeys()
	showNotif("Permainan dimulai! Huruf: " .. seed:upper(), 3)
end)

R.NewTurn.OnClientEvent:Connect(function(zn, sid, turnName, word)
	if not isParticipant then return end
	if zn ~= activeZoneName then return end
	if sid ~= activeSessionId then return end  -- filter: bukan game session kita
	currentTurnName = turnName
	lastCountdownHaptic = -1
	setWordBox(word)
	updateWrong(0)

	-- Camera: focus on active player (hanya pemain aktif, bukan spectator)
	if inGame then
		local turnPlayer = getPlayerByName(turnName)
		if turnPlayer then
			startCameraFollow(turnPlayer)
		end
	end

	if turnName == localPlayer.Name then
		myTurn       = true
		lockedPrefix = normalizeClientWord(word or "")
		typedText    = ""
		setHudVisible(true)
		if allowKeyboardUI then setKeyboardVisible(true) end
		-- Defer ke frame berikutnya agar billboard sudah siap dan event lain selesai
		task.defer(function()
			refreshDisplay()
		end)
		pulseHaptic(0.95, 0.11, 0.55)
		task.delay(0.16, function()
			if myTurn and inGame then
				pulseHaptic(0.55, 0.07, 0.25)
			end
		end)
		showNotif("Giliran kamu! Lanjutkan: " .. word:upper(), 2)
	else
		myTurn       = false
		lockedPrefix = ""; typedText = ""
		setHudVisible(true)  -- tetap tampilkan HUD (bisa lihat timer/salah lawan)
		if allowKeyboardUI then setKeyboardVisible(false) end
		showNotif("Giliran: " .. turnName, 2)
	end
end)

R.TimerTick.OnClientEvent:Connect(function(zn, sid, t)
	if not isParticipant then return end
	if zn ~= activeZoneName then return end
	if sid ~= activeSessionId then return end
	if timerNum and timerNum:IsA("TextLabel") then
		timerNum.Text = tostring(t)
		if t <= 3 then
			timerNum.TextColor3 = Color3.fromRGB(230, 60, 60)
		elseif t <= 6 then
			timerNum.TextColor3 = Color3.fromRGB(230, 170, 30)
		else
			timerNum.TextColor3 = Color3.fromRGB(80, 220, 80)
		end
	end
	if myTurn and t <= 3 and t ~= lastCountdownHaptic then
		lastCountdownHaptic = t
		pulseHaptic(1, 0.08, 0.6)
	elseif t > 3 then
		lastCountdownHaptic = -1
	end
end)

R.WordAccepted.OnClientEvent:Connect(function(zn, senderName, word)
	if not isParticipant then return end
	if zn ~= activeZoneName then return end
	updateWrong(0)

	if senderName == localPlayer.Name then
		typedText = ""
		lockedPrefix = ""
		updateOwnBillboard(word or "")
		pulseHaptic(0.45, 0.06, 0.2)
	end

	-- Play correct sound
	if correctSound then correctSound:Play() end
end)

R.WordRejected.OnClientEvent:Connect(function(reason, newWrongCount)
	if not isParticipant then return end
	if newWrongCount then updateWrong(newWrongCount) end
	pulseHaptic(1, 0.18, 0.85)
	showNotif("Ditolak: " .. (reason or ""), 2)
	-- Play incorrect sound
	if incorrectSound then incorrectSound:Play() end
end)

-- Opponent salah: notif + update X indicators jika sedang melihat giliran lawan
R.OpponentWrong.OnClientEvent:Connect(function(zn, playerName, wrongNum)
	if not isParticipant then return end
	if zn ~= activeZoneName then return end
	if playerName == localPlayer.Name then return end  -- skip, sudah dapat dari WordRejected
	showNotif(playerName .. " salah! (" .. (wrongNum or "?") .. "/" .. MAX_WRONG .. ")", 1.5)
	-- Update Salah/X visual jika ini giliran lawan yang sedang ditampilkan
	if currentTurnName == playerName and not myTurn then
		updateWrong(wrongNum or 0)
	end
end)

R.UpdateHP.OnClientEvent:Connect(function(hp)
	if not isParticipant then return end
	if type(hp) == "number" then
		updateHP(hp)
	end
end)

R.PlayerEliminated.OnClientEvent:Connect(function(zn, sid, name)
	if not isParticipant then return end
	if zn ~= activeZoneName then return end
	if sid ~= activeSessionId then return end  -- filter: bukan game session kita
	showNotif(name .. " tersingkir!", 3)
	if name == localPlayer.Name then
		myTurn = false; typedText = ""; lockedPrefix = ""
		inGame = false
		isParticipant = false
		activeZoneName  = nil
		activeSessionId = nil   -- hapus session ID saat disingkirkan
		lastCountdownHaptic = -1
		setHudVisible(false)
		if allowKeyboardUI then setKeyboardVisible(false) end
		unlockAllKeys()
		stopCameraFollow()  -- kamera kembali normal, bebas gerak
		showNotif("Kamu tersingkir!", 3)
		-- Sinyal ke ZoneGui agar restore GUI lain (player jadi spectator diam di zona)
		-- Gunakan playerGui (diakses bersama) agar ZoneGui bisa mendengarkan
		playerGui:SetAttribute("_PlayerEliminated", tick())
	end
end)

R.GameEnded.OnClientEvent:Connect(function(zn, sid, winnerName)
	if not isParticipant then return end
	if zn ~= activeZoneName then return end
	if sid ~= activeSessionId then return end  -- filter: bukan game session kita!
	inGame = false
	isParticipant   = false
	activeZoneName  = nil
	activeSessionId = nil   -- hapus session ID saat game berakhir
	myTurn = false; typedText = ""; lockedPrefix = ""
	isSpectating = false
	lastCountdownHaptic = -1
	setHudVisible(false)
	if allowKeyboardUI then setKeyboardVisible(false) end
	unlockAllKeys()
	stopCameraFollow()
	setWordBox("?")
	if winnerName then
		showNotif(winnerName == localPlayer.Name
			and "Kamu menang!" or winnerName .. " menang!", 5)
	end
end)

R.ZoneCountdown.OnClientEvent:Connect(function(t)
	if t > 0 then showNotif("Mulai dalam " .. t .. " detik...", 1.2) end
end)
