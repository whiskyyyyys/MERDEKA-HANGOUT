local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishConfig = require(ReplicatedStorage.Modules.FishConfig)

local InventoryService = {}

local assetFishFolder = ServerStorage:WaitForChild("AssetFish")

function InventoryService.GetFishTemplate(rarity, fishName)
	local rarityFolder = assetFishFolder:FindFirstChild(rarity)
	if not rarityFolder then
		warn("[InventoryService] Folder rarity tidak ditemukan:", rarity)
		return nil
	end
	local template = rarityFolder:FindFirstChild(fishName)
	if not template then
		warn("[InventoryService] Fish tool tidak ditemukan:", rarity, fishName)
	end
	return template
end

local function randomInRange(minVal, maxVal)
	return minVal + math.random() * (maxVal - minVal)
end

local function scaleTool(tool, scaleFactor)
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end
	local pivot = handle:GetPivot()
	for _, part in tool:GetDescendants() do
		if part:IsA("BasePart") then
			part.Size = part.Size * scaleFactor
		end
	end
	if tool:FindFirstChildWhichIsA("Model") == nil then
		handle.CFrame = pivot
	end
end

function InventoryService.RollWeightAndSize(rarity)
	local range = FishConfig.RARITY_SIZE_RANGE[rarity]
	if not range then return 1.0, 1.0 end
	local weightKg = randomInRange(range.minKg, range.maxKg)
	local scaleFactor = randomInRange(range.minScale, range.maxScale)
	return math.floor(weightKg * 100 + 0.5) / 100, scaleFactor
end

local function addFishBillboard(tool, fishName, weightKg)
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FishInfoBillboard"
	billboard.Adornee = handle
	billboard.Size = UDim2.new(0, 160, 0, 50)
	billboard.StudsOffset = Vector3.new(0, handle.Size.Y / 2 + 0.6, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 40
	billboard.Parent = handle

	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = billboard

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "FishName"
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = fishName
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Parent = container

	local kgLabel = Instance.new("TextLabel")
	kgLabel.Name = "FishWeight"
	kgLabel.Size = UDim2.new(1, 0, 0.45, 0)
	kgLabel.Position = UDim2.new(0, 0, 0.55, 0)
	kgLabel.BackgroundTransparency = 1
	kgLabel.Text = string.format("%.2f kg", weightKg)
	kgLabel.TextScaled = true
	kgLabel.Font = Enum.Font.Gotham
	kgLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	kgLabel.TextStrokeTransparency = 0.3
	kgLabel.Parent = container
end

-- Buat instance Tool (scaled + billboard), TIDAK diparent kemanapun.
-- Dipakai baik buat tangkapan baru MAUPUN restore dari DataStore (pakai weight/scale yang SAMA persis).
function InventoryService.CreateFishTool(rarity, fishName, weightKg, scaleFactor)
	local template = InventoryService.GetFishTemplate(rarity, fishName)
	if not template then return nil end

	local clone = template:Clone()
	clone.CanBeDropped = false
	scaleTool(clone, scaleFactor)
	clone:SetAttribute("WeightKg", weightKg)
	clone:SetAttribute("SizeScale", scaleFactor)
	clone:SetAttribute("Rarity", rarity)
	addFishBillboard(clone, fishName, weightKg)

	return clone
end

-- Tangkapan baru: roll weight/size acak lalu kasih ke Backpack.
function InventoryService.GiveFish(player, rarity, fishName)
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then return false, nil, nil end

	local weightKg, scaleFactor = InventoryService.RollWeightAndSize(rarity)
	local clone = InventoryService.CreateFishTool(rarity, fishName, weightKg, scaleFactor)
	if not clone then return false, nil, nil end

	clone.Parent = backpack
	return true, weightKg, scaleFactor
end

-- Restore dari data tersimpan: weight/size PERSIS sama seperti yang disimpan (gak di-roll ulang).
function InventoryService.RestoreInventory(player, savedInventory)
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then return end

	for _, entry in savedInventory do
		local clone = InventoryService.CreateFishTool(entry.rarity, entry.name, entry.weightKg, entry.scaleFactor)
		if clone then
			clone.Parent = backpack
		end
	end
end

return InventoryService