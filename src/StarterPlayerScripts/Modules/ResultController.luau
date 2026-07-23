local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishConfig = require(ReplicatedStorage.Modules.FishConfig)

local ResultController = {}
ResultController.__index = ResultController

function ResultController.new(gui)
	local self = setmetatable({}, ResultController)

	local mainFish = gui:WaitForChild("MainFish")
	self.mainFish = mainFish

	self.acquiredFrame = mainFish:WaitForChild("AcquiredFrame")
	self.acquiredTitle = self.acquiredFrame:WaitForChild("Title")

	local acquiredOuterFrame = self.acquiredFrame:WaitForChild("Frame")
	self.continueFrame = acquiredOuterFrame:WaitForChild("Continue")
	self.continueButton = self.continueFrame:WaitForChild("Button")

	self.resultFrame = mainFish:WaitForChild("ResultFrame")
	self.getFishImage = self.resultFrame:WaitForChild("GetFishImage")

	self.rarityLabel = nil
	self.nameFishLabel = nil
	for _, child in self.resultFrame:GetChildren() do
		if child:IsA("Frame") then
			local rarityLabel = child:FindFirstChild("Rarity")
			if rarityLabel then self.rarityLabel = rarityLabel end
			local nameLabel = child:FindFirstChild("NameFish")
			if nameLabel then self.nameFishLabel = nameLabel end
		end
	end

	self.acquiredFrame.Visible = false
	self.resultFrame.Visible = false

	self.continueButton.Activated:Connect(function()
		self:_dismiss()
	end)

	self._onDismiss = nil

	return self
end

function ResultController:_applyRarityColor(rarity)
	local color = FishConfig.RARITY_COLORS[rarity]
	if not color then return end

	-- warna Title di AcquiredFrame ikut rarity (teks/isinya sendiri tetap gak diubah)
	if self.acquiredTitle then
		self.acquiredTitle.TextColor3 = color
	end
	if self.rarityLabel then
		self.rarityLabel.TextColor3 = color
	end
end

function ResultController:_showResult(fishName, rarity, iconId)
	if self.nameFishLabel then
		self.nameFishLabel.Text = fishName
	end
	if self.rarityLabel then
		self.rarityLabel.Text = rarity
	end
	if self.getFishImage and iconId and iconId ~= "" then
		self.getFishImage.Image = iconId
	end
	self.resultFrame.Visible = true
end

function ResultController:_dismiss()
	self.acquiredFrame.Visible = false
	self.resultFrame.Visible = false
	self.mainFish.Enabled = false

	if self._onDismiss then
		local callback = self._onDismiss
		self._onDismiss = nil
		callback()
	end
end

function ResultController:HandleCatch(payload, onDismiss)
	self._onDismiss = onDismiss
	self.mainFish.Enabled = true

	self:_applyRarityColor(payload.rarity)
	self.acquiredFrame.Visible = true
	self:_showResult(payload.fishName, payload.rarity, payload.iconId)
end

return ResultController