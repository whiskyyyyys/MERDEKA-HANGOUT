-- ============================================================
-- MasukanPakuClient.client.luau
-- MEKANIK BARU: Claw Machine Drop (Timing Goyangan)
-- ============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local MINIGAMES_FOLDER = ReplicatedStorage:WaitForChild("Minigames")
local MASUKANPAKU_FOLDER = MINIGAMES_FOLDER:WaitForChild("MasukanPaku")
local EVENTS_FOLDER = MASUKANPAKU_FOLDER:WaitForChild("Events")

local GameStartEvent = EVENTS_FOLDER:WaitForChild("GameStartEvent")
local GameEndEvent = EVENTS_FOLDER:WaitForChild("GameEndEvent")
local ClaimWinEvent = EVENTS_FOLDER:WaitForChild("ClaimWinEvent")

local isGameActive = false
local isPlayerInZone = false
local isPlayingMinigame = false

local gui = nil
local pendulumPivot = nil
local stringFrame = nil
local nailFrame = nil
local bottleHole = nil
local instructionText = nil
local progressText = nil
local tapButton = nil
local countdownText = nil

local renderConnection = nil
local zoneCheckConnection = nil

-- State Game
local gameState = "SWINGING" -- "SWINGING", "DROPPING", "CHECKING", "RETURNING"
local angle = 0
local score = 0
local TARGET_SCORE = 1
local currentSpeed = 3
local MAX_ANGLE = 60

local STRING_MIN_LENGTH = 0.2
local STRING_MAX_LENGTH = 0.65 -- Jarak scale jatuh sampai lubang botol

local stringScaleValue = nil
local hiddenGuis = {}

local SQUAT_ANIM_ID = "rbxassetid://81147896850705" -- GANTI DENGAN ID ANIMASI JONGKOK ANDA!
local loadedSquatAnim = nil

local function hideGuisAndFreeze()
	-- Sembunyikan tas (Backpack)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
	
	-- Sembunyikan GUI lain
	hiddenGuis = {}
	for _, child in ipairs(PlayerGui:GetChildren()) do
		if child:IsA("ScreenGui") and child.Enabled and child.Name ~= "MasukanPakuDropGui" then
			hiddenGuis[child] = true
			child.Enabled = false
		end
	end
	
	-- Bekukan pemain & Teleport ke Part "End" terdekat
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
		local hrp = char.HumanoidRootPart
		
		-- Cari part End terdekat di dalam arena
		local arena = workspace:FindFirstChild("MasukanPakuArena")
		if arena then
			local endFolder = arena:FindFirstChild("End")
			if endFolder then
				local closestPart = nil
				local closestDist = math.huge
				for _, part in ipairs(endFolder:GetChildren()) do
					if part:IsA("BasePart") then
						local dist = (part.Position - hrp.Position).Magnitude
						if dist < closestDist then
							closestDist = dist
							closestPart = part
						end
					end
				end
				
				-- Hentikan semua animasi dan physics DULU
				hrp.Anchored = true
				
				local humanoid = char:FindFirstChild("Humanoid")
				if humanoid then
					humanoid.WalkSpeed = 0
					humanoid.JumpPower = 0
					humanoid.AutoRotate = false
					
					local animateScript = char:FindFirstChild("Animate")
					if animateScript then
						animateScript.Enabled = false
					end
					
					local animator = humanoid:FindFirstChildOfClass("Animator")
					if animator then
						for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
							track:Stop()
						end
					end
				end
				
				-- Tunggu 1 frame agar sistem physics Roblox benar-benar berhenti
				task.wait(0.05)
				
				if closestPart then
					-- Ambil posisi HRP sebelum teleport (posisi botol / target zone)
					local oldPos = hrp.Position
					local newPos = closestPart.Position
					
					-- Arah menjauh dari botol (botol ke part)
					local directionAway = (newPos - oldPos)
					local lookTarget = newPos + directionAway
					
					-- Paksa karakter melihat menjauh dari botol (pantat hadap botol)
					hrp.CFrame = CFrame.lookAt(newPos, Vector3.new(lookTarget.X, newPos.Y, lookTarget.Z))
				end
			end
		end
		
		-- Mainkan animasi jongkok jika ada ID-nya
		if SQUAT_ANIM_ID ~= "rbxassetid://0" and SQUAT_ANIM_ID ~= "" then
			local animator = char.Humanoid:FindFirstChildOfClass("Animator") or char.Humanoid:WaitForChild("Animator")
			local anim = Instance.new("Animation")
			anim.AnimationId = SQUAT_ANIM_ID
			loadedSquatAnim = animator:LoadAnimation(anim)
			loadedSquatAnim:Play()
		end
	end
end

local function restoreGuisAndUnfreeze()
	-- Tampilkan tas (Backpack) - DIHAPUS AGAR TIDAK MERUSAK CUSTOM INVENTORY
	-- Custom inventory biasanya akan rusak/tertimpa jika Backpack CoreGui bawaan Roblox diaktifkan kembali.
	pcall(function()
		-- StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)
	
	-- Kembalikan GUI lain
	for guiToRestore, _ in pairs(hiddenGuis) do
		if guiToRestore and guiToRestore.Parent then
			guiToRestore.Enabled = true
		end
	end
	hiddenGuis = {}
	
	-- Bebaskan pemain
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.Anchored = false
		local humanoid = char:FindFirstChild("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
		end
		
		local animateScript = char:FindFirstChild("Animate")
		if animateScript then
			animateScript.Enabled = true
		end
	end
	
	if loadedSquatAnim then
		loadedSquatAnim:Stop()
		loadedSquatAnim = nil
	end
end

-- ============================================================
-- MEMBANGUN UI (Tampilan Claw Machine)
-- ============================================================
local function createUI()
	-- Cari GUI yang sudah dibuat oleh user di StarterGui (yang sekarang ada di PlayerGui)
	gui = PlayerGui:WaitForChild("MasukanPakuDropGui", 5)
	if not gui then
		warn("[MasukanPaku] MasukanPakuDropGui tidak ditemukan di PlayerGui! Pastikan sudah ditaruh di StarterGui.")
		return
	end
	
	gui.Enabled = true
	gui.IgnoreGuiInset = true -- Paksa abaikan topbar
	
	-- Cari Container dan paksa ukurannya agar responsive & di tengah
	local container = gui:WaitForChild("Container")
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
	container.Size = UDim2.new(0.4, 0, 0.7, 0) -- Pakai Scale (40% lebar, 70% tinggi layar)
	
	-- Tambahkan UIAspectRatioConstraint via script kalau belum ada
	if not container:FindFirstChildOfClass("UIAspectRatioConstraint") then
		local ratio = Instance.new("UIAspectRatioConstraint")
		ratio.AspectRatio = 0.6 -- Tinggi lebih dominan dari lebar
		ratio.Parent = container
	end
	
	container.Visible = true
	
	-- Map variabel UI
	tapButton = gui:WaitForChild("TapButton")
	tapButton.Visible = true
	
	instructionText = container:WaitForChild("InstructionLabel")
	progressText = container:WaitForChild("ProgressLabel")
	bottleHole = container:WaitForChild("BottleHole")
	
	pendulumPivot = container:WaitForChild("Pivot")
	stringFrame = pendulumPivot:WaitForChild("String")
	stringScaleValue = stringFrame:WaitForChild("ScaleValue")
	nailFrame = stringFrame:WaitForChild("Nail")
end

-- ============================================================
-- GAME LOGIC (DROP & CHECK)
-- ============================================================
local function stopMinigameUI()
	isPlayingMinigame = false
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	if gui then
		local container = gui:FindFirstChild("Container")
		if container then container.Visible = false end
		
		local tapBtn = gui:FindFirstChild("TapButton")
		if tapBtn then tapBtn.Visible = false end
		
		gui.Enabled = false
	end
	restoreGuisAndUnfreeze()
end

local function handleTap()
	if not isPlayingMinigame then return end
	if gameState ~= "SWINGING" then return end
	
	-- Ubah state menjadi DROPPING
	gameState = "DROPPING"
	instructionText.Text = "Turun..."
	
	-- Animasi tali memanjang
	local dropTween = TweenService:Create(stringScaleValue, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
		Value = STRING_MAX_LENGTH
	})
	
	dropTween:Play()
	dropTween.Completed:Wait()
	
	if not isPlayingMinigame then return end
	
	gameState = "CHECKING"
	
	-- Kalkulasi jarak hit dalam pixel karena layar bisa beda ukuran
	local container = gui and gui:FindFirstChild("Container")
	local isHit = false
	if container then
		local dropDistancePixels = container.AbsoluteSize.Y * STRING_MAX_LENGTH
		local tipXOffsetPixels = math.sin(math.rad(angle)) * dropDistancePixels
		
		local holeRadiusPixels = (container.AbsoluteSize.X * 0.18) / 2
		isHit = math.abs(tipXOffsetPixels) <= (holeRadiusPixels + 5) -- Toleransi 5px
	end
	
	if isHit then
		score = score + 1
		progressText.Text = "Masuk: " .. score .. " / " .. TARGET_SCORE
		bottleHole.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
		instructionText.Text = "TEPAT SASARAN!"
		instructionText.TextColor3 = Color3.fromRGB(50, 255, 50)
		
		if score >= TARGET_SCORE then
			task.wait(0.5)
			isGameActive = false
			stopMinigameUI()
			ClaimWinEvent:FireServer()
			return
		end
	else
		bottleHole.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
		instructionText.Text = "MELESET!"
		instructionText.TextColor3 = Color3.fromRGB(255, 50, 50)
	end
	
	task.wait(0.7)
	if not isPlayingMinigame then return end
	
	-- Kembalikan tali ke atas
	gameState = "RETURNING"
	bottleHole.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	instructionText.Text = "Menarik kembali..."
	instructionText.TextColor3 = Color3.fromRGB(200, 200, 200)
	
	local returnTween = TweenService:Create(stringScaleValue, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Value = STRING_MIN_LENGTH
	})
	returnTween:Play()
	returnTween.Completed:Wait()
	
	if not isPlayingMinigame then return end
	
	-- Lanjut goyang, tambah kecepatan sedikit biar makin susah
	currentSpeed = currentSpeed + 0.5
	gameState = "SWINGING"
	instructionText.Text = "Tekan SPACE atau TAP layar saat paku lurus!"
end

local function startMinigameUI()
	if isPlayingMinigame then return end
	isPlayingMinigame = true
	score = 0
	currentSpeed = 3
	gameState = "SWINGING"
	
	hideGuisAndFreeze()
	createUI()
	
	tapButton.MouseButton1Click:Connect(handleTap)
	
	renderConnection = RunService.RenderStepped:Connect(function(dt)
		if not isPlayingMinigame then return end
		
		-- Selalu update ukuran string berdasarkan persentase container (Responsive!)
		local container = gui and gui:FindFirstChild("Container")
		if container and stringFrame and stringScaleValue then
			local stringLengthPixels = container.AbsoluteSize.Y * stringScaleValue.Value
			stringFrame.Size = UDim2.new(0, 2, 0, stringLengthPixels)
		end
		
		if gameState == "SWINGING" then
			-- Paku bergoyang ke kiri dan kanan dengan mulus menggunakan sine wave
			angle = math.sin(os.clock() * currentSpeed) * MAX_ANGLE
			if pendulumPivot then
				pendulumPivot.Rotation = angle
			end
		end
	end)
end

-- ============================================================
-- ZONE DETECTOR (Lari ke botol)
-- ============================================================
local function getArenaAndZone()
	local arena = nil
	for _, child in ipairs(workspace:GetDescendants()) do
		if (child.Name == "MasukanPakuArena" or child.Name == "MasukanPaku Arena") and child:IsA("Model") then
			if child:FindFirstChild("TargetZone") then
				arena = child
				break
			end
		end
	end
	
	if not arena then
		arena = workspace:FindFirstChild("MasukanPakuArena") or workspace:FindFirstChild("MasukanPaku Arena")
	end
	
	if arena then
		return arena:FindFirstChild("TargetZone")
	end
	return nil
end

local function startZoneChecker()
	isGameActive = true
	
	if zoneCheckConnection then zoneCheckConnection:Disconnect() end
	zoneCheckConnection = RunService.Heartbeat:Connect(function()
		if not isGameActive then
			if zoneCheckConnection then zoneCheckConnection:Disconnect() end
			return
		end
		
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local targetZone = getArenaAndZone()
		
		if root and targetZone then
			local relPos = targetZone.CFrame:ToObjectSpace(root.CFrame)
			local size = targetZone.Size
			local isInside = math.abs(relPos.X) <= size.X/2 and math.abs(relPos.Y) <= size.Y/2 and math.abs(relPos.Z) <= size.Z/2
			
			if isInside and not isPlayerInZone then
				isPlayerInZone = true
				startMinigameUI()
			elseif not isInside and isPlayerInZone then
				isPlayerInZone = false
				stopMinigameUI()
			end
		end
	end)
end

-- ============================================================
-- INPUT LISTENER (KEYBOARD SPACE)
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not isPlayingMinigame then return end
	if input.KeyCode == Enum.KeyCode.Space then
		handleTap()
	end
end)

-- ============================================================
-- EVENT LISTENERS
-- ============================================================
GameStartEvent.OnClientEvent:Connect(function()
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.Anchored = true
	end
	
	-- Buat GUI Countdown Global
	local countdownGui = Instance.new("ScreenGui")
	countdownGui.Name = "MasukanPakuGlobalCountdown"
	countdownGui.IgnoreGuiInset = true
	countdownGui.Parent = PlayerGui
	
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "BERSIAP!"
	textLabel.Font = Enum.Font.GothamBlack
	textLabel.TextSize = 100
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextStrokeTransparency = 0
	textLabel.Parent = countdownGui
	
	for i = 5, 1, -1 do
		textLabel.Text = tostring(i)
		textLabel.TextSize = 50
		TweenService:Create(textLabel, TweenInfo.new(0.5, Enum.EasingStyle.Bounce), {
			TextSize = 120
		}):Play()
		task.wait(1)
	end
	
	textLabel.Text = "LARI!"
	textLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
	task.wait(1)
	
	countdownGui:Destroy()
	
	if char and char:FindFirstChild("HumanoidRootPart") then
		char.HumanoidRootPart.Anchored = false
	end
	
	print("[MasukanPaku] Game dimulai! Silakan lari ke TargetZone!")
	isPlayerInZone = false
	startZoneChecker()
end)

GameEndEvent.OnClientEvent:Connect(function(winner)
	print("[MasukanPaku] Game selesai! Pemenang: ", winner)
	isGameActive = false
	isPlayerInZone = false
	
	stopMinigameUI()
	
	if zoneCheckConnection then
		zoneCheckConnection:Disconnect()
		zoneCheckConnection = nil
	end
	
	gui = Instance.new("ScreenGui")
	gui.Name = "MasukanPakuResultGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = PlayerGui
	
	-- Latar belakang gelap (Overlay)
	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.Parent = gui
	
	-- Kotak Utama (Responsive dengan Scale)
	local mainBox = Instance.new("Frame")
	mainBox.Name = "ResultBox"
	mainBox.Size = UDim2.new(0.8, 0, 0.4, 0) -- Lebar 80% layar
	mainBox.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainBox.AnchorPoint = Vector2.new(0.5, 0.5)
	mainBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255) -- Putih
	mainBox.BorderSizePixel = 0
	mainBox.Parent = overlay
	
	-- Jaga rasio agar tidak gepeng di layar HP
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 2 -- Lebar = 2x Tinggi
	aspect.Parent = mainBox
	
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0.1, 0)
	boxCorner.Parent = mainBox
	
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Thickness = 6
	uiStroke.Color = Color3.fromRGB(220, 20, 30) -- Merah
	uiStroke.Parent = mainBox
	
	-- Header Merah
	local headerBox = Instance.new("Frame")
	headerBox.Size = UDim2.new(1, 0, 0.35, 0)
	headerBox.BackgroundColor3 = Color3.fromRGB(220, 20, 30) -- Merah
	headerBox.BorderSizePixel = 0
	headerBox.Parent = mainBox
	
	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0.3, 0)
	headerCorner.Parent = headerBox
	
	local headerCover = Instance.new("Frame")
	headerCover.Size = UDim2.new(1, 0, 0.5, 0)
	headerCover.Position = UDim2.new(0, 0, 0.5, 0)
	headerCover.BackgroundColor3 = Color3.fromRGB(220, 20, 30)
	headerCover.BorderSizePixel = 0
	headerCover.Parent = headerBox
	
	local titleText = Instance.new("TextLabel")
	titleText.Size = UDim2.new(1, 0, 0.8, 0)
	titleText.Position = UDim2.new(0, 0, 0.1, 0)
	titleText.BackgroundTransparency = 1
	titleText.Font = Enum.Font.GothamBlack
	titleText.TextScaled = true
	titleText.TextColor3 = Color3.fromRGB(255, 255, 255) -- Putih
	titleText.TextStrokeTransparency = 0.5
	titleText.TextStrokeColor3 = Color3.fromRGB(100, 0, 0)
	titleText.Parent = headerBox
	
	local subtitleText = Instance.new("TextLabel")
	subtitleText.Size = UDim2.new(1, 0, 0.15, 0)
	subtitleText.Position = UDim2.new(0, 0, 0.45, 0)
	subtitleText.BackgroundTransparency = 1
	subtitleText.Text = "LOMBA MASUKKAN PAKU"
	subtitleText.Font = Enum.Font.GothamBold
	subtitleText.TextScaled = true
	subtitleText.TextColor3 = Color3.fromRGB(120, 120, 120)
	subtitleText.Parent = mainBox
	
	local nameText = Instance.new("TextLabel")
	nameText.Size = UDim2.new(1, 0, 0.25, 0)
	nameText.Position = UDim2.new(0, 0, 0.65, 0)
	nameText.BackgroundTransparency = 1
	nameText.Font = Enum.Font.GothamBlack
	nameText.TextScaled = true
	nameText.TextColor3 = Color3.fromRGB(220, 20, 30) -- Merah
	nameText.Parent = mainBox
	
	if winner == player then
		uiStroke.Color = Color3.fromRGB(220, 20, 30)
		headerBox.BackgroundColor3 = Color3.fromRGB(220, 20, 30)
		headerCover.BackgroundColor3 = Color3.fromRGB(220, 20, 30)
		titleText.Text = "DIRGAHAYU!"
		nameText.Text = "KAMU JUARA 1"
		nameText.TextColor3 = Color3.fromRGB(220, 20, 30)
	elseif winner == nil then
		uiStroke.Color = Color3.fromRGB(100, 100, 100)
		headerBox.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		headerCover.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		titleText.Text = "WAKTU HABIS"
		subtitleText.Text = "Tidak ada pemenang"
		nameText.Text = "SERI"
		nameText.TextColor3 = Color3.fromRGB(100, 100, 100)
	else
		uiStroke.Color = Color3.fromRGB(220, 20, 30)
		headerBox.BackgroundColor3 = Color3.fromRGB(220, 20, 30)
		headerCover.BackgroundColor3 = Color3.fromRGB(220, 20, 30)
		titleText.Text = "PERMAINAN SELESAI"
		nameText.Text = winner.Name .. " JUARA 1"
	end
	
	-- Animasi Muncul
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.6}):Play()
	
	mainBox.Size = UDim2.new(0, 0, 0, 0)
	local popupTween = TweenService:Create(mainBox, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = UDim2.new(0.8, 0, 0.4, 0)
	})
	popupTween:Play()
	
	task.wait(4)
	
	-- Animasi Hilang
	TweenService:Create(overlay, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	TweenService:Create(mainBox, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0)
	}):Play()
	
	task.wait(0.5)
	if gui then
		gui:Destroy()
		gui = nil
	end
end)
