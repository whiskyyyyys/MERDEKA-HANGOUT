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

function MinigameController:_resetProgressColors()
	for _, frame in self.progressFrames do
		frame.BackgroundColor3 = FishConfig.COLOR_PENDING
	end
end

function MinigameController:_setAttempt(index)
	local stage = FishConfig.STAGES[index]
	self.hitZone.Size = UDim2.new(stage.zoneScale, 0, 1, 0)
	self.hitZone.Position = UDim2.new(0.5 - stage.zoneScale / 2, 0, 0, 0)
	self.elapsed = 0
end

function MinigameController:Start(onComplete)
	if self.isActive then return end
	self.isActive = true
	self.onComplete = onComplete
	self.attemptIndex = 1
	self.hitCount = 0

	self:_resetProgressColors()
	self:_setAttempt(self.attemptIndex)

	-- ScreenGui dinyalain, tapi HANYA BarFrame yang ditampilkan sekarang.
	-- AcquiredFrame/ResultFrame biar tetap Enabled=true di parent-nya tapi
	-- Visible mereka sendiri diatur oleh ResultController, bukan di sini.
	self.mainFish.Enabled = true
	self.barFrame.Visible = true
	self.hitZone.Visible = true
	self.cursor.Visible = true
	self.catchButton.Visible = true
	for _, frame in self.progressFrames do
		frame.Visible = true
	end

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
	local zoneMin = 0.5 - stage.zoneScale / 2
	local zoneMax = 0.5 + stage.zoneScale / 2
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