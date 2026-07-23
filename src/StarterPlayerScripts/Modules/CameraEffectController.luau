local TweenService = game:GetService("TweenService")

local CameraEffectController = {}
CameraEffectController.__index = CameraEffectController

local ZOOM_IN_FOV = 55   -- FOV pas zoom in (default biasanya 70)
local ZOOM_OUT_FOV = 75  -- FOV pas zoom out
local CYCLE_TIME = 0.8   -- detik per satu arah zoom

function CameraEffectController.new()
	local self = setmetatable({}, CameraEffectController)
	self.camera = workspace.CurrentCamera
	self.defaultFOV = self.camera.FieldOfView
	self.isRunning = false
	self.currentTween = nil
	self.resetTween = nil
	return self
end

function CameraEffectController:Play(duration, onComplete)
	if self.isRunning then return end
	self.isRunning = true
	self.stopSignal = false
	self.wasStopped = false

	local elapsed = 0
	local zoomingIn = true

	task.spawn(function()
		while elapsed < duration and not self.stopSignal do
			local targetFOV = zoomingIn and ZOOM_IN_FOV or ZOOM_OUT_FOV
			self.currentTween = TweenService:Create(
				self.camera,
				TweenInfo.new(CYCLE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{FieldOfView = targetFOV}
			)
			self.currentTween:Play()
			self.currentTween.Completed:Wait()

			elapsed += CYCLE_TIME
			zoomingIn = not zoomingIn
		end

		-- kembalikan FOV normal
		self.resetTween = TweenService:Create(
			self.camera,
			TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{FieldOfView = self.defaultFOV}
		)
		self.resetTween:Play()
		self.resetTween.Completed:Wait()

		self.isRunning = false
		if onComplete and not self.wasStopped then
			onComplete()
		end
	end)
end

function CameraEffectController:Stop()
	self.stopSignal = true
	self.wasStopped = true
	if self.currentTween then
		self.currentTween:Cancel()
	end
	if self.resetTween then
		self.resetTween:Cancel()
	end
	
	-- Pastikan FOV kembali normal secepatnya tanpa nunggu tween selesai
	self.camera.FieldOfView = self.defaultFOV
	self.isRunning = false
end

return CameraEffectController