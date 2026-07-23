local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Target Waktu: 17 Agustus 2026 00:00:00 WIB
-- WIB adalah UTC+7, maka dalam UTC adalah 16 Agustus 2026 jam 17:00:00
local TARGET_TIME = os.time({
	year = 2026,
	month = 8,
	day = 16,
	hour = 17,
	min = 0,
	sec = 0
})

-- Setup Folder Remotes
local RSMinigames = ReplicatedStorage:FindFirstChild("Minigames")
if not RSMinigames then
	RSMinigames = Instance.new("Folder")
	RSMinigames.Name = "Minigames"
	RSMinigames.Parent = ReplicatedStorage
end

local RSPanjat = RSMinigames:FindFirstChild("PanjatPinang")
if not RSPanjat then
	RSPanjat = Instance.new("Folder")
	RSPanjat.Name = "PanjatPinang"
	RSPanjat.Parent = RSMinigames
end

local Remotes = RSPanjat:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = RSPanjat
end

local EarlyAccessEvent = Remotes:FindFirstChild("EarlyAccessAttempt")
if not EarlyAccessEvent then
	EarlyAccessEvent = Instance.new("RemoteEvent")
	EarlyAccessEvent.Name = "EarlyAccessAttempt"
EarlyAccessEvent.Parent = Remotes
end

-- Tunggu Map / Zone Panjat Pinang
local PanjatPinangMap = workspace:WaitForChild("PanjatPinang")
local Zone = PanjatPinangMap:WaitForChild("Zone")
local TimerPart = PanjatPinangMap:WaitForChild("Timer")

-- ── 1. BUAT TIMER (DI SERVER AGAR SEMUA BISA LIHAT TANPA ERROR) ──
local timerGui = TimerPart:FindFirstChild("PanjatPinangTimerGui")
if not timerGui then
	timerGui = Instance.new("BillboardGui")
	timerGui.Name = "PanjatPinangTimerGui"
	timerGui.Size = UDim2.new(40, 0, 12, 0) -- Sangat besar (40 stud lebar, 12 stud tinggi)
	timerGui.StudsOffset = Vector3.new(0, 8, 0) -- Melayang lebih tinggi
	timerGui.MaxDistance = 1000 -- Terlihat dari sangat jauh
	timerGui.LightInfluence = 0 -- Agar teks selalu bersinar terang dan tidak terpengaruh bayangan
	timerGui.Parent = TimerPart

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1 -- PASTIKAN BENAR-BENAR TIDAK ADA BACKGROUND
	container.Parent = timerGui

	local timerTitle = Instance.new("TextLabel")
	timerTitle.Size = UDim2.new(1, 0, 0.4, 0)
	timerTitle.Position = UDim2.new(0, 0, 0, 0)
	timerTitle.BackgroundTransparency = 1
	timerTitle.Text = "LOMBA PANJAT PINANG"
	timerTitle.TextColor3 = Color3.fromRGB(255, 0, 0)
	timerTitle.TextStrokeTransparency = 0 -- Outline bawaan (anti-blob/background)
	timerTitle.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	timerTitle.TextScaled = true
	timerTitle.Font = Enum.Font.FredokaOne
	timerTitle.Parent = container

	local timerText = Instance.new("TextLabel")
	timerText.Name = "TimerText"
	timerText.Size = UDim2.new(1, 0, 0.5, 0)
	timerText.Position = UDim2.new(0, 0, 0.5, 0)
	timerText.BackgroundTransparency = 1
	timerText.Text = "MENGHITUNG WAKTU..."
	timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerText.TextStrokeTransparency = 0 -- Outline bawaan (anti-blob/background)
	timerText.TextStrokeColor3 = Color3.fromRGB(255, 0, 0)
	timerText.TextScaled = true
	timerText.Font = Enum.Font.GothamBlack
	timerText.Parent = container
end

local timerTextLabel = timerGui:FindFirstChild("Frame"):FindFirstChild("TimerText")

-- Update Timer dari Server
task.spawn(function()
	while true do
		local now = os.time()
		local diff = TARGET_TIME - now
		
		if diff > 0 then
			-- Waktu belum tiba: Kunci Zone menjadi tembok (solid)
			Zone.CanCollide = true
			
			local days = math.floor(diff / 86400)
			local hours = math.floor((diff % 86400) / 3600)
			local mins = math.floor((diff % 3600) / 60)
			local secs = diff % 60
			
			if timerTextLabel then
				timerTextLabel.Text = string.format("BUKA DALAM:\n%02d HARI %02d JAM %02d MENIT %02d DETIK", days, hours, mins, secs)
				timerTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		else
			-- Waktu sudah tiba: Buka Zone agar bisa ditembus!
			Zone.CanCollide = false
			
			if timerTextLabel then
				timerTextLabel.Text = "SUDAH DIBUKA!\nAYO PANJAT PINANGNYA!"
				timerTextLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
			end
		end
		task.wait(1)
	end
end)

-- ── 2. PENGUNCIAN AREA (POPUP UI SAJA) ──
local debounce = {}

Zone.Touched:Connect(function(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	
	if humanoid then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			if os.time() < TARGET_TIME then
				-- BELUM WAKTUNYA! (Pemain akan menabrak tembok secara otomatis)
				-- Kita hanya perlu memunculkan peringatan UI Pop-up
				if not debounce[player.UserId] then
					debounce[player.UserId] = true
					
					-- Beri peringatan via UI ScreenGui
					EarlyAccessEvent:FireClient(player)
					
					task.delay(2, function()
						debounce[player.UserId] = false
					end)
				end
			end
		end
	end
end)

print("[PanjatPinang] ZoneManager aktif! Terkunci hingga 17 Agustus 2026 00:00 WIB.")
