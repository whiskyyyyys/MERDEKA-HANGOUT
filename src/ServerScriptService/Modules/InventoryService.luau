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
	
	-- TempModel harus diparent ke Tool sebelum part dipindahkan agar Motor6D/Weld bawaan model tidak hancur!
	local tempModel = Instance.new("Model")
	tempModel.Parent = tool 
	
	local partsToMove = {}
	for _, child in tool:GetChildren() do
		if (child:IsA("BasePart") or child:IsA("Model")) and child ~= tempModel then
			table.insert(partsToMove, child)
			child.Parent = tempModel
		end
	end
	
	if #partsToMove > 0 then
		-- Cek apakah Handle jauh dari ikan (sering terjadi jika player hanya memasukkan part Handle baru)
		handle.Parent = nil -- Keluarkan sebentar agar bounding box hanya menghitung ikan
		local cf, size = tempModel:GetBoundingBox()
		handle.Parent = tempModel
		
		-- Jika handle melenceng lebih dari 2 stud dari pusat ikan, kita tarik handle ke tengah!
		if (cf.Position - handle.Position).Magnitude > 2 then
			-- Hancurkan semua weld manual yang mungkin dibuat oleh player agar ikan tidak ikut terseret saat handle digeser
			for _, desc in tool:GetDescendants() do
				if desc:IsA("JointInstance") or desc:IsA("WeldConstraint") then
					if desc.Part0 == handle or desc.Part1 == handle then
						desc:Destroy()
					end
				end
			end
			handle.CFrame = cf
		end
		
		tempModel.PrimaryPart = handle
		tempModel:ScaleTo(scaleFactor)
		
		for _, child in partsToMove do
			child.Parent = tool
		end
	end
	
	tempModel:Destroy()
end

local function autoWeld(tool)
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end
	
	-- Unanchor semua part agar physics bekerja dengan benar saat di-equip
	for _, child in tool:GetChildren() do
		if child:IsA("BasePart") then
			child.Anchored = false
			if child ~= handle then
				child.CanCollide = false
			end
		end
	end
	handle.CanCollide = false
	
	-- Paksa weld semua part ke Handle. 
	-- (Jangan gunakan GetRootPart() di sini karena physics engine tidak berjalan dengan akurat saat Tool belum masuk ke Workspace!)
	for _, child in tool:GetChildren() do
		if child:IsA("BasePart") and child ~= handle then
			local weld = Instance.new("WeldConstraint")
			weld.Name = "AutoWeld_" .. child.Name
			weld.Part0 = handle
			weld.Part1 = child
			weld.Parent = handle
		end
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
function InventoryService.CreateFishTool(rarity, fishName, weightKg, scaleFactor, isFavorited, uuid)
	local template = InventoryService.GetFishTemplate(rarity, fishName)
	if not template then return nil end

	local clone = template:Clone()
	clone.CanBeDropped = false
	scaleTool(clone, scaleFactor)
	autoWeld(clone)
	clone:SetAttribute("WeightKg", weightKg)
	clone:SetAttribute("SizeScale", scaleFactor)
	clone:SetAttribute("Rarity", rarity)
	clone:SetAttribute("IsFavorited", isFavorited == true)
	if uuid then clone:SetAttribute("UUID", uuid) end
	addFishBillboard(clone, fishName, weightKg)

	return clone
end

-- Tangkapan baru: roll weight/size acak lalu kasih ke Backpack.
function InventoryService.GiveFish(player, rarity, fishName, uuid)
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then return false, nil, nil end

	local weightKg, scaleFactor = InventoryService.RollWeightAndSize(rarity)
	local clone = InventoryService.CreateFishTool(rarity, fishName, weightKg, scaleFactor, false, uuid)
	if not clone then return false, nil, nil end

	clone.Parent = backpack
	return true, weightKg, scaleFactor
end

-- Restore dari data tersimpan: weight/size PERSIS sama seperti yang disimpan (gak di-roll ulang).
function InventoryService.RestoreInventory(player, savedInventory)
	local backpack = player:FindFirstChild("Backpack") or player:WaitForChild("Backpack", 5)
	if not backpack then return end

	for _, entry in savedInventory do
		local clone = InventoryService.CreateFishTool(entry.rarity, entry.name, entry.weightKg, entry.scaleFactor, entry.isFavorited, entry.id)
		if clone then
			clone.Parent = backpack
		end
	end
end

return InventoryService