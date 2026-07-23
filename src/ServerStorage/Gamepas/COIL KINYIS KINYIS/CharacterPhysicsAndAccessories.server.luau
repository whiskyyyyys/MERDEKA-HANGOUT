-- GlowStick > CharacterPhysicsAndAccessories
-- ====== SERVICES ======
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

-- ====== KONFIG ======
local GHOST_GROUP = "GhostParts"
local PLAYER_GROUP = "Players"
local FRICTION_EQUIP = 0.15
local FRICTION_WEIGHT = 0
local ELASTICITY = 0
local ELASTICITY_WEIGHT = 0

-- ====== VAR ======
local tool = script.Parent
assert(tool:IsA("Tool"), "Script ini harus diletakkan di dalam sebuah Tool.")

-- ====== UTIL ======
local function isEquippedToCharacter(t)
	local p = t.Parent
	return p and p:FindFirstChildOfClass("Humanoid") ~= nil
end

local function forEachBasePart(root, fn)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then fn(d) end
	end
end

local function ensureGhostGroup()
	pcall(function() PhysicsService:CreateCollisionGroup(GHOST_GROUP) end)
	pcall(function()
		-- PERBAIKAN: GhostParts tidak collide dengan Default (bangunan) DAN Players
		PhysicsService:CollisionGroupSetCollidable(GHOST_GROUP, "Default", false)
		PhysicsService:CollisionGroupSetCollidable(GHOST_GROUP, GHOST_GROUP, false)
		PhysicsService:CollisionGroupSetCollidable(GHOST_GROUP, PLAYER_GROUP, false)

		-- PENTING: Pastikan Players TETAP collide dengan Default (bangunan)
		PhysicsService:CollisionGroupSetCollidable(PLAYER_GROUP, "Default", true)
	end)
end
ensureGhostGroup()

-- ====== CACHE / RESTORE ======
local function cachePartProps(part)
	if part:GetAttribute("PrevCanCollide") == nil then part:SetAttribute("PrevCanCollide", part.CanCollide) end
	if part:GetAttribute("PrevMassless") == nil then part:SetAttribute("PrevMassless", part.Massless) end
	if part:GetAttribute("PrevCollisionGroupName") == nil then
		local name = "Default"
		pcall(function() name = PhysicsService:GetCollisionGroupName(part.CollisionGroupId) end)
		part:SetAttribute("PrevCollisionGroupName", name)
	end
	if part:GetAttribute("PrevHasCustomPhys") == nil then
		part:SetAttribute("PrevHasCustomPhys", part.CustomPhysicalProperties ~= nil)
	end
end

local function restorePartProps(part)
	local prevGroup = part:GetAttribute("PrevCollisionGroupName")
	if prevGroup then 
		pcall(function() part.CollisionGroup = prevGroup end) 
	else
		pcall(function() part.CollisionGroup = PLAYER_GROUP end)
	end

	local prevCollide = part:GetAttribute("PrevCanCollide")
	if prevCollide ~= nil then part.CanCollide = prevCollide end

	local prevMassless = part:GetAttribute("PrevMassless")
	if prevMassless ~= nil then part.Massless = prevMassless end

	part.CustomPhysicalProperties = nil

	part:SetAttribute("PrevCollisionGroupName", nil)
	part:SetAttribute("PrevCanCollide", nil)
	part:SetAttribute("PrevMassless", nil)
	part:SetAttribute("PrevHasCustomPhys", nil)
end

-- ====== PART WAJIB COLLIDE ======
local MUST_COLLIDE_NAMES = {
	["HumanoidRootPart"] = true,
	["LeftFoot"] = true,
	["RightFoot"] = true,
	["LeftLowerLeg"] = true,
	["RightLowerLeg"] = true,
	["LeftUpperLeg"] = true,
	["RightUpperLeg"] = true,
	["Left Leg"] = true,
	["Right Leg"] = true,
}

local FOOT_KEYWORDS = { "foot", "leg" }

local function isMustCollidePart(part)
	if MUST_COLLIDE_NAMES[part.Name] then return true end
	local lower = part.Name:lower()
	for _, kw in ipairs(FOOT_KEYWORDS) do
		if lower:find(kw, 1, true) then return true end
	end
	return false
end

local function ensureGroundContactParts(char)
	for _, name in ipairs({ "HumanoidRootPart", "LeftFoot", "RightFoot", "LeftLowerLeg", "RightLowerLeg", "LeftUpperLeg", "RightUpperLeg", "Left Leg", "Right Leg" }) do
		local part = char:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			cachePartProps(part)
			part.CanCollide = true
			part.Massless = false
			part.CustomPhysicalProperties = nil
			-- Tetap di group Players agar tetap collide dengan Default (bangunan)
			pcall(function() part.CollisionGroup = PLAYER_GROUP end)
		end
	end
end

-- ====== TOOL COLLISION ======
local function applyToolCollisionState(isEquipped)
	if isEquipped then
		forEachBasePart(tool, function(p)
			cachePartProps(p)
			p.CanCollide = false
			p.CanTouch = true
			p.CanQuery = true
			p.Massless = true
			pcall(function() p.CollisionGroup = GHOST_GROUP end)
			p.CustomPhysicalProperties = PhysicalProperties.new(
				p.CustomPhysicalProperties and p.CustomPhysicalProperties.Density or 1,
				FRICTION_EQUIP, ELASTICITY, FRICTION_WEIGHT, ELASTICITY_WEIGHT
			)
		end)
	else
		forEachBasePart(tool, restorePartProps)
	end
end

-- ====== GHOSTING KARAKTER ======
local function ghostCharacter(char)
	forEachBasePart(char, function(p)
		cachePartProps(p)
		if isMustCollidePart(p) then
			-- Bagian kaki tetap di Players group (collide dengan bangunan)
			p.CanCollide = true
			p.Massless = false
			p.CustomPhysicalProperties = nil
			pcall(function() p.CollisionGroup = PLAYER_GROUP end)
		else
			-- Bagian tubuh lain (kepala, tangan) tembus semua
			p.CanCollide = false
			p.CanTouch = true
			p.CanQuery = true
			p.Massless = true
			pcall(function() p.CollisionGroup = GHOST_GROUP end)
			p.CustomPhysicalProperties = PhysicalProperties.new(
				p.CustomPhysicalProperties and p.CustomPhysicalProperties.Density or 1,
				FRICTION_EQUIP, ELASTICITY, FRICTION_WEIGHT, ELASTICITY_WEIGHT
			)
		end
	end)
	ensureGroundContactParts(char)
end

local function unghostCharacter(char)
	forEachBasePart(char, function(p)
		restorePartProps(p)
		-- Pastikan kembali ke Players group
		if not isMustCollidePart(p) then
			pcall(function() p.CollisionGroup = PLAYER_GROUP end)
		end
	end)
end

local function onCharacterDescendantAdded(d, char)
	if not d:IsA("BasePart") then return end
	if not isEquippedToCharacter(tool) then return end

	task.wait()

	cachePartProps(d)
	if isMustCollidePart(d) then
		d.CanCollide = true
		d.Massless = false
		d.CustomPhysicalProperties = nil
		pcall(function() d.CollisionGroup = PLAYER_GROUP end)
	else
		d.CanCollide = false
		d.CanTouch = true
		d.CanQuery = true
		d.Massless = true
		pcall(function() d.CollisionGroup = GHOST_GROUP end)
		d.CustomPhysicalProperties = PhysicalProperties.new(
			d.CustomPhysicalProperties and d.CustomPhysicalProperties.Density or 1,
			FRICTION_EQUIP, ELASTICITY, FRICTION_WEIGHT, ELASTICITY_WEIGHT
		)
	end
end

local function onToolDescendantAdded(d)
	if d:IsA("BasePart") and isEquippedToCharacter(tool) then
		cachePartProps(d)
		d.CanCollide = false
		d.CanTouch = true
		d.CanQuery = true
		d.Massless = true
		pcall(function() d.CollisionGroup = GHOST_GROUP end)
		d.CustomPhysicalProperties = PhysicalProperties.new(
			d.CustomPhysicalProperties and d.CustomPhysicalProperties.Density or 1,
			FRICTION_EQUIP, ELASTICITY, FRICTION_WEIGHT, ELASTICITY_WEIGHT
		)
	end
end
tool.DescendantAdded:Connect(onToolDescendantAdded)

-- ====== TRANSISI STATE ======
applyToolCollisionState(isEquippedToCharacter(tool))
if tool:FindFirstChild("Handle") then
	tool.Handle.CanCollide = isEquippedToCharacter(tool) and false or true
end

tool.Equipped:Connect(function()
	applyToolCollisionState(true)
	local char = tool.Parent
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and char then
		task.wait(0.05)
		ghostCharacter(char)
		char.DescendantAdded:Connect(function(d) onCharacterDescendantAdded(d, char) end)
	end
end)

tool.Unequipped:Connect(function()
	applyToolCollisionState(false)
	local char = tool.Parent
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and char then
		unghostCharacter(char)
	end
end)

tool.AncestryChanged:Connect(function()
	applyToolCollisionState(isEquippedToCharacter(tool))
end)
