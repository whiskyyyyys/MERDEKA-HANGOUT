
-- GlowStick Speed Boost
local BOOST = 35 -- seberapa cepat tambahannya

local tool = script.Parent
local humanoid
local defaultSpeed

-- Saat di-equip
tool.Equipped:Connect(function()
	local character = tool.Parent
	humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		defaultSpeed = humanoid.WalkSpeed
		humanoid.WalkSpeed = defaultSpeed + BOOST
	end
end)

-- Saat di-unequip
tool.Unequipped:Connect(function()
	if humanoid and defaultSpeed then
		humanoid.WalkSpeed = defaultSpeed
	end
end)
