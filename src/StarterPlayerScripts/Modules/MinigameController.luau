local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishConfig = require(ReplicatedStorage.Modules.FishConfig)

local MinigameController = {}
MinigameController.__index = MinigameController

function MinigameController.new(gui)
	local self = setmetatable({}, MinigameController)

	local mainFish = gui:WaitForChild("MainFish")
	local barFrame = mainFish:WaitForChild("BarFrame")

	self.mainFish = mainFish
	self.barFrame = barFrame
	self.hitZone = barFrame:WaitForChild("HitZone")
	self.cursor = barFrame:WaitForChild("Cursor")

	local catchProgress = barFrame:WaitForChild("CatchProggres")
	self.progressFrames = {
		catchProgress:WaitForChild("1"),
		catchProgress:WaitForChild("2"),
		catchProgress:WaitForChild("3"),
	}
	self.catchButton = barFrame:WaitForChild("CatchButton")
	self.autoButton = mainFish:WaitForChild("Auto")
	self.autoText = self.autoButton:WaitForChild("Text", 5)
	
	self.catchProgressFrame = catchProgress

	self.isActive = false
	self.connection = nil
	self.attemptIndex = 1
	self.hitCount = 0
	self.elapsed = 0
	self.onComplete = nil

	self.catchButton.Activated:Connect(function()
		self:AttemptHit()
	end)

	return self
end

function MinigameController:ShowAutoIdle()
	self.mainFish.Enabled = true
	self.barFrame.Visible = false -- Matikan BarFrame karena Auto sekarang di luarnya!
	
	self.autoButton.Visible = true
	
	-- Pastikan gradient / warnanya hijau (AUTO) jika tidak sedang jalan
	local gradient = self.autoButton:FindFirstChild("UIGradient")
	if gradient then
		gradient.Color = ColorSequence.new(Color3.fromRGB(50, 200, 50), Color3.fromRGB(30, 150, 30))
	else
		self.autoButton.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
	end
	if self.autoText and self.autoText:IsA("TextLabel") then
		self.autoText.Text = "AUTO"
	end
end

function MinigameController:HideAutoIdle()
	self.autoButton.Visible = false
	self.mainFish.Enabled = false
end

function MinigameController:SetAutoModeUI(isAuto)
	if isAuto then
		self.barFrame.Visible = false -- Sembunyikan bar minigame saat Auto jalan
		
		-- Ubah gaya tombol menjadi STOP AUTO
		local gradient = self.autoButton:FindFirstChild("UIGradient")
		if gradient then
			gradient.Color = ColorSequence.new(Color3.fromRGB(200, 50, 50), Color3.fromRGB(150, 30, 30))
		else
			self.autoButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		end
		
		if self.autoText and self.autoText:IsA("TextLabel") then
			self.autoText.Text = "STOP AUTO"
		end
	else
		self:ShowAutoIdle() -- Kembali ke state awal pegang pancingan
	end
end

function MinigameController:_resetProgressColors()
	for _, frame in self.progressFrames do
		frame.BackgroundColor3 = FishConfig.COLOR_PENDING
	end
end

function MinigameController:_setAttempt(index)
	local stage = FishConfig.STAGES[index]
	self.hitZone.Size = UDim2.new(stage.zoneScale, 0, 1, 0)
	
	-- Acak posisi X (dari 0 sampai sisa ruang dikurangi skala zone)
	local maxOffset = 1 - stage.zoneScale
	local randomOffset = math.random() * maxOffset
	self.hitZone.Position = UDim2.new(randomOffset, 0, 0, 0)
	
	-- Simpan batas hit zone agar bisa dicek nanti
	self.currentZoneMin = randomOffset
	self.currentZoneMax = randomOffset + stage.zoneScale
	
	self.elapsed = 0
end

function MinigameController:Start(onComplete, isAuto)
	if self.isActive then return end
	self.isActive = true
	self.onComplete = onComplete
	self.attemptIndex = 1
	self.hitCount = 0

	self.mainFish.Enabled = true
	self.barFrame.Visible = true

	if isAuto then
		self:SetAutoModeUI(true)
		-- Otomatis selesai dengan jeda acak agar lebih natural (2 hingga 4 detik)
		local randomDelay = math.random(20, 40) / 10
		task.delay(randomDelay, function()
			if self.isActive then
				self.hitCount = 5 -- Sempurna
				self:_finish()
			end
		end)
		return
	end

	-- JIKA MANUAL CATCH: Sembunyikan tombol Auto, munculkan bar
	self.autoButton.Visible = false
	self:_resetProgressColors()
	self:_setAttempt(self.attemptIndex)

	self.hitZone.Visible = true
	self.cursor.Visible = true
	self.catchButton.Visible = true
	if self.catchProgressFrame then self.catchProgressFrame.Visible = true end

	self.connection = RunService.RenderStepped:Connect(function(dt)
		self.elapsed += dt
		local stage = FishConfig.STAGES[self.attemptIndex]
		local t = (math.sin(self.elapsed * stage.speed) + 1) / 2
		self.cursor.Position = UDim2.new(t, 0, 0.5, 0)
	end)
end

function MinigameController:_finish()
	self.isActive = false
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end

	-- FIX: JANGAN matikan mainFish.Enabled di sini!
	-- Cukup sembunyikan BarFrame aja, biar AcquiredFrame/ResultFrame
	-- (sibling di ScreenGui yang sama) masih bisa muncul setelah ini.
	self.barFrame.Visible = false

	if self.onComplete then
		self.onComplete(self.hitCount)
	end
end

function MinigameController:AttemptHit()
	if not self.isActive then return end

	local stage = FishConfig.STAGES[self.attemptIndex]
	local cursorX = self.cursor.Position.X.Scale
	local zoneMin = self.currentZoneMin or (0.5 - stage.zoneScale / 2)
	local zoneMax = self.currentZoneMax or (0.5 + stage.zoneScale / 2)
	local currentFrame = self.progressFrames[self.attemptIndex]

	local isHit = cursorX >= zoneMin and cursorX <= zoneMax
	if isHit then
		currentFrame.BackgroundColor3 = FishConfig.COLOR_SUCCESS
		self.hitCount += 1
	else
		currentFrame.BackgroundColor3 = FishConfig.COLOR_MISS
	end

	if self.attemptIndex >= FishConfig.ATTEMPTS_TOTAL then
		self:_finish()
	else
		self.attemptIndex += 1
		self:_setAttempt(self.attemptIndex)
	end
end

return MinigameController