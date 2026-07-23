local RunService = game:GetService("RunService")

local GradientRotation = {}
GradientRotation.__index = GradientRotation

function GradientRotation.new(guiObject)
	local self = setmetatable({}, GradientRotation)
	self._gradient = guiObject:FindFirstChildOfClass("UIGradient")

	if not self._gradient then
		self._gradient = Instance.new("UIGradient")
		self._gradient.Rotation = 0
		self._gradient.Parent = guiObject
	end

	self._connection = RunService.RenderStepped:Connect(function(dt)
		if self._gradient then
			self._gradient.Rotation = (self._gradient.Rotation + dt * 72) % 360
		end
	end)

	return self
end

function GradientRotation:Destroy()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
	self._gradient = nil
end

return GradientRotation
