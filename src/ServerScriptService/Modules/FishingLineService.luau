local Players = game:GetService("Players")

local FishingLineService = {}

local activeLines = {} -- [player] = {bobber = Part, beam = Beam}

local function findRodTool(player)
	local character = player.Character
	if not character then return nil end
	for _, tool in character:GetChildren() do
		if tool:IsA("Tool") and tool:GetAttribute("IsFishingRod") then
			return tool
		end
	end
	return nil
end

local function getOrCreateLineAttachment(handle)
	local attachment = handle:FindFirstChild("LineAttachment")
	if not attachment then
		attachment = Instance.new("Attachment")
		attachment.Name = "LineAttachment"
		attachment.Parent = handle
	end
	return attachment
end

-- Dipanggil server pas cast sukses kena air. Bikin bobber + beam di Workspace,
-- otomatis ke-replicate ke SEMUA client karena dibuat dari server.
function FishingLineService.ShowLine(player, targetPosition)
	FishingLineService.HideLine(player) -- bersihin sisa line lama kalau ada

	local rodTool = findRodTool(player)
	if not rodTool then return end

	local handle = rodTool:FindFirstChild("Handle")
	if not handle then return end

	local rodAttachment = getOrCreateLineAttachment(handle)

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
	beam.Attachment0 = rodAttachment
	beam.Attachment1 = bobberAttachment
	beam.Width0 = 0.05
	beam.Width1 = 0.05
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	beam.Transparency = NumberSequence.new(0.3)
	beam.FaceCamera = true
	beam.Parent = handle

	activeLines[player] = {bobber = bobber, beam = beam}
end

function FishingLineService.HideLine(player)
	local entry = activeLines[player]
	if not entry then return end

	if entry.beam then entry.beam:Destroy() end
	if entry.bobber then entry.bobber:Destroy() end

	activeLines[player] = nil
end

function FishingLineService.Init()
	Players.PlayerRemoving:Connect(function(player)
		FishingLineService.HideLine(player)
	end)
end

return FishingLineService