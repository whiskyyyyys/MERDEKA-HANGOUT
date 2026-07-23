local FishingLineController = {}
FishingLineController.__index = FishingLineController

function FishingLineController.new(tool)
	local self = setmetatable({}, FishingLineController)

	self.tool = tool
	self.handle = tool:FindFirstChild("Handle")
	self.rodAttachment = self.handle and self.handle:FindFirstChild("LineAttachment")

	self.bobberPart = nil
	self.bobberAttachment = nil
	self.beam = nil

	return self
end

function FishingLineController:ShowLine(targetPosition)
	if not self.rodAttachment then return end
	self:HideLine()

	local bobber = Instance.new("Part")
	bobber.Name = "FishingBobber"
	bobber.Size = Vector3.new(0.4, 0.4, 0.4)
	bobber.Shape = Enum.PartType.Ball
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.CanQuery = false
	bobber.Color = Color3.fromRGB(255, 60, 60)
	bobber.Position = targetPosition
	bobber.Parent = workspace

	local bobberAttachment = Instance.new("Attachment")
	bobberAttachment.Parent = bobber

	local beam = Instance.new("Beam")
	beam.Attachment0 = self.rodAttachment
	beam.Attachment1 = bobberAttachment
	beam.Width0 = 0.05
	beam.Width1 = 0.05
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	beam.Transparency = NumberSequence.new(0.3)
	beam.FaceCamera = true
	beam.Parent = self.handle

	self.bobberPart = bobber
	self.bobberAttachment = bobberAttachment
	self.beam = beam
end

function FishingLineController:HideLine()
	if self.beam then
		self.beam:Destroy()
		self.beam = nil
	end
	if self.bobberPart then
		self.bobberPart:Destroy()
		self.bobberPart = nil
	end
	self.bobberAttachment = nil
end

return FishingLineController